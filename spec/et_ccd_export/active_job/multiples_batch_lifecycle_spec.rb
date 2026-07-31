require 'rails_helper'

RSpec.describe EtCcdExport::ActiveJob::MultiplesBatchLifecycle do
  before do
    stub_const('ExampleLifecycleJob', Class.new(ActiveJob::Base) do
      include EtCcdExport::JobMetadata

      attr_accessor :batch
    end)

    stub_const('ExampleSuccessCallback', Class.new(ActiveJob::Base))
    stub_const('ExampleFailedCallback', Class.new(ActiveJob::Base))
  end

  let(:example_multiple_reference) { '240000001/2021' }
  let(:example_child_reference) { "24001001/#{Time.current.year}" }
  let(:other_child_reference) { "24001002/#{Time.current.year}" }
  let(:exported_case_id) { 123_456 }
  let(:batch) do
    EtCcdExport::Sidekiq::Batch.start reference: example_multiple_reference,
                                      quantity: 10,
                                      start_ref: example_child_reference,
                                      export_id: 'fakeexportid',
                                      case_type_id: 'fakecasetypeid'
  end

  def lifecycle_for(child_reference)
    job = ExampleLifecycleJob.new
    job.batch = batch
    job.job_metadata.merge!(
      'et_ccd_export_multiple_batch_reference' => example_multiple_reference,
      'et_ccd_export_multiple_batch_child_reference' => child_reference
    )
    described_class.new(job:)
  end

  describe '#call' do
    it 'moves the job to done in the batch' do
      batch.add_child_to_todo(example_child_reference)
      batch.add_child_to_todo(other_child_reference)
      lifecycle = lifecycle_for(example_child_reference)

      lifecycle.call { exported_case_id }

      expect(batch).to have_attributes done_references: [example_child_reference],
                                       todo_references: [other_child_reference],
                                       persisted?: true
    end

    it 'removes the batch when all jobs are done' do
      batch.add_child_to_todo(example_child_reference)
      lifecycle = lifecycle_for(example_child_reference)

      lifecycle.call { exported_case_id }

      expect(batch.persisted?).to be false
    end

    it 'moves the job to error if the job raises an error' do
      batch.add_child_to_todo(example_child_reference)
      lifecycle = lifecycle_for(example_child_reference)

      aggregate_failures 'raised error and batch state' do
        expect { lifecycle.call { raise StandardError, 'An error occurred in the job' } }.
          to raise_error(StandardError, 'An error occurred in the job')

        expect(batch).to have_attributes error_references: [example_child_reference],
                                         done_references: [],
                                         todo_references: [],
                                         persisted?: true
      end
    end

    it 'keeps the job in error if it raises an error for the first and second time' do
      batch.add_child_to_todo(example_child_reference)
      batch.add_child_to_todo(other_child_reference)
      successful_lifecycle = lifecycle_for(example_child_reference)
      failing_lifecycle = lifecycle_for(other_child_reference)
      successful_lifecycle.call { exported_case_id }

      aggregate_failures 'repeated errors and batch state' do
        2.times do
          expect { failing_lifecycle.call { raise StandardError, 'An error occurred in the job' } }.
            to raise_error(StandardError, 'An error occurred in the job')
        end

        expect(batch).to have_attributes error_references: [other_child_reference],
                                         done_references: [example_child_reference],
                                         todo_references: [],
                                         persisted?: true
      end
    end

    it 'moves from error to done if the child job succeeds a third time' do
      batch.add_child_to_todo(example_child_reference)
      lifecycle = lifecycle_for(example_child_reference)

      aggregate_failures 'failed attempts and eventual success' do
        2.times do
          expect { lifecycle.call { raise StandardError, 'An error occurred in the job' } }.
            to raise_error(StandardError, 'An error occurred in the job')
        end
        lifecycle.call { exported_case_id }

        expect(batch.persisted?).to be false
      end
    end

    it 'schedules the success job when done with no failures' do
      batch.add_child_to_todo(example_child_reference)
      lifecycle = lifecycle_for(example_child_reference)
      batch.on :success, ExampleSuccessCallback, 'example_arg'

      lifecycle.call { exported_case_id }

      expect(ExampleSuccessCallback).to have_been_enqueued.with([example_child_reference], 'example_arg')
    end

    it 'does not enqueue the failed callback when done with no failures' do
      batch.add_child_to_todo(example_child_reference)
      lifecycle = lifecycle_for(example_child_reference)
      batch.on :success, ExampleSuccessCallback, 'example_arg'
      batch.on :failed, ExampleFailedCallback

      lifecycle.call { exported_case_id }

      expect(ExampleFailedCallback).not_to have_been_enqueued
    end
  end

  describe '#job_discarded!' do
    it 'does not enqueue the success callback if one job completely fails' do
      batch.add_child_to_todo(example_child_reference)
      lifecycle = lifecycle_for(example_child_reference)
      batch.on :success, ExampleSuccessCallback, 'example_arg'
      batch.on :failed, ExampleFailedCallback

      aggregate_failures 'discard and success callback' do
        expect { lifecycle.call { raise StandardError, 'An error occurred in the job' } }.
          to raise_error(StandardError, 'An error occurred in the job')
        lifecycle.job_discarded!

        expect(ExampleSuccessCallback).not_to have_been_enqueued
      end
    end

    it 'enqueues the failed callback if one job completely fails' do
      batch.add_child_to_todo(example_child_reference)
      lifecycle = lifecycle_for(example_child_reference)
      batch.on :success, ExampleSuccessCallback, 'example_arg'
      batch.on :failed, ExampleFailedCallback, 'example_failed_arg'

      aggregate_failures 'discard and failed callback' do
        expect { lifecycle.call { raise StandardError, 'An error occurred in the job' } }.
          to raise_error(StandardError, 'An error occurred in the job')
        lifecycle.job_discarded!

        expect(ExampleFailedCallback).to have_been_enqueued.with([], [example_child_reference], 'example_failed_arg')
      end
    end
  end
end
