require 'rails_helper'

RSpec.describe EtCcdExport::MultiplesWorkerBatchJob do
  before do
    stub_const('ExampleSuccessfulJob', Class.new(ActiveJob::Base) do
      include EtCcdExport::JobMetadata
      include EtCcdExport::MultiplesClientBatchJob
      include EtCcdExport::MultiplesWorkerBatchJob

      def perform(exported_case_id)
        exported_case_id
      end
    end)

    stub_const('ExampleFailedJob', Class.new(ActiveJob::Base) do
      include EtCcdExport::JobMetadata
      include EtCcdExport::MultiplesClientBatchJob
      include EtCcdExport::MultiplesWorkerBatchJob

      retry_on StandardError, attempts: 1

      def perform
        raise StandardError, 'An error occurred in the job'
      end
    end)
  end

  let(:example_multiple_reference) { '240000001/2021' }
  let(:example_child_reference) { "24001001/#{Time.current.year}" }
  let(:exported_case_id) { 123_456 }
  let(:batch) do
    EtCcdExport::Batch.start reference: example_multiple_reference,
                             quantity: 10,
                             start_ref: example_child_reference,
                             export_id: 'fakeexportid',
                             case_type_id: 'fakecasetypeid'
  end

  it 'runs the batch lifecycle around a successful job' do
    batch.jobs do
      batch.child_job(example_child_reference) do
        ExampleSuccessfulJob.perform_later(exported_case_id)
      end
    end

    perform_enqueued_jobs only: ExampleSuccessfulJob

    expect(EtCcdExport::Batch.exists?(batch.id)).to be false
  end

  it 'runs the discarded lifecycle after a job exhausts its attempts' do
    batch.jobs do
      batch.child_job(example_child_reference) do
        ExampleFailedJob.perform_later
      end
    end

    aggregate_failures 'verify exception is raised and batch reports failed reference' do
      expect { perform_enqueued_jobs only: ExampleFailedJob }.
        to raise_error(StandardError, 'An error occurred in the job')

      expect(batch).to have_attributes failed_references: [example_child_reference],
                                       persisted?: true
    end
  end
end
