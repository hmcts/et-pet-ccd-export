require 'rails_helper'

describe EtCcdExport::MultiplesWorkerBatchJob do

  before do
    stub_const('ExampleJob', Class.new(ActiveJob::Base) do
      include EtCcdExport::JobMetadata
      include EtCcdExport::MultiplesClientBatchJob
      include EtCcdExport::MultiplesWorkerBatchJob

      retry_on StandardError, attempts: 25
      def perform
        123456 # A fake id from the worker
      end
    end)

    stub_const('ExampleException', Class.new(StandardError))

    # This worker will fail first and second times and succeed after that
    stub_const('ExampleFailingJob', Class.new(ActiveJob::Base) do
      include EtCcdExport::JobMetadata
      include EtCcdExport::MultiplesClientBatchJob
      include EtCcdExport::MultiplesWorkerBatchJob

      retry_on StandardError, attempts: 25

      def perform
        retry_count = job_metadata.fetch('retry_count', 0)
        if retry_count <= 1
          job_metadata.merge! 'retry_count' => retry_count + 1,
                              'error_message' => 'An error occurred in the worker',
                              'error_class' => ExampleException,
                              'failed_at' => Time.now.to_f,
                              'retried_at' => Time.now.to_f

          raise ExampleException, "An error occurred in the worker"
        end
        123456 # A fake id from the worker
      end
    end)

    stub_const('ExampleCompletelyFailedJob', Class.new(ActiveJob::Base) do
      include EtCcdExport::JobMetadata
      include EtCcdExport::MultiplesClientBatchJob
      include EtCcdExport::MultiplesWorkerBatchJob

      retry_on StandardError, attempts: 2

      def perform
        raise ExampleException, "An error occurred in the worker"
      end
    end)

    stub_const('ExampleSuccessCallback', Class.new(ActiveJob::Base) do
      include EtCcdExport::JobMetadata

    end)

    stub_const('ExampleFailedCallback', Class.new(ActiveJob::Base) do
      include EtCcdExport::JobMetadata
    end)

  end

  let(:example_multiple_reference) { '240000001/2021' }
  let(:example_child_reference1) { "24001001/#{Time.now.year}" }
  let(:example_child_reference2) { "24001002/#{Time.now.year}" }
  let(:batch) do
    EtCcdExport::Sidekiq::Batch.start reference: example_multiple_reference,
                                      quantity: 10,
                                      start_ref: example_child_reference1,
                                      export_id: 'fakeexportid',
                                      case_type_id: 'fakecasetypeid'
  end

  def drain_all
    perform_enqueued_jobs
  end

  def execute_job_without_removing(worker)
    enqueued_jobs_with(only: worker).first.tap do |payload|
      instantiate_job(payload, skip_deserialize_arguments: true).perform_now
    end
  rescue ExampleException
    debug = 1
    puts debug
  end
  describe '#perform' do
    context 'with a child job as part of a batch' do
      it 'moves the job to done in the batch' do
        # Arrange - call the example worker in a batch
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleJob.perform_later
          end
          batch.child_job(example_child_reference2) do
            ExampleFailingJob.perform_later # Else the batch will complete and be destroyed
          end
        end

        # Act - Drain the job (Only the good one)
        perform_enqueued_jobs only: ExampleJob

        # Assert - the done reference should include the first and todo should contain second (as it hasn't ran)
        expect(batch).to have_attributes done_references: [example_child_reference1],
                                         todo_references: [example_child_reference2],
                                         persisted?: true
      end

      it 'removes the batch when all jobs are done' do
        # Arrange - call the example worker in a batch
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleJob.perform_later
          end
        end

        # Act - Drain the job
        perform_enqueued_jobs only: ExampleJob

        # Assert - the batch will no longer be persisted (ensures it is removed from redis)
        expect(batch.persisted?).to be false
      end

      it 'moves the job to error if the worker has an error' do
        # Arrange - schedule the failing job once - then drain the queue, then schedule again
        batch.jobs do
          batch.child_job(example_child_reference2) do
            ExampleFailingJob.perform_later
          end
        end
        perform_enqueued_jobs
        # drain_all
        batch.jobs do
          batch.child_job(example_child_reference2) do
            ExampleFailingJob.perform_later
          end
        end

        # Act - Drain the job ignoring the exception
        drain_all

        # Assert
        expect(batch).to have_attributes error_references: [example_child_reference2],
                                         done_references: [],
                                         todo_references: [],
                                         persisted?: true
      end

      it 'keeps the job in error if the worker has an error for the first and second time' do
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleJob.perform_later
          end
          batch.child_job(example_child_reference2) do
            ExampleFailingJob.perform_later # Else the batch will complete and be destroyed
          end
        end

        # Act - Drain the job ignoring the exception
        begin
          perform_enqueued_jobs
        rescue ExampleException
        end

        # Assert
        expect(batch).to have_attributes error_references: [example_child_reference2],
                                         done_references: [example_child_reference1],
                                         todo_references: [],
                                         persisted?: true
      end

      it 'moves from error to done if the child job succeeds a third time' do
        batch.jobs do
          batch.child_job(example_child_reference2) do
            ExampleFailingJob.perform_later # The first one fails
          end
        end
        execute_job_without_removing(ExampleFailingJob)
        execute_job_without_removing(ExampleFailingJob)

        # Act - Drain the job ignoring the exception
        drain_all

        # Assert - the batch should have disappeared as it is done
        expect(batch.persisted?).to be false
      end

      it 'schedules the success worker when done with no failures' do
        # Arrange - call the example worker in a batch and setup callbacks
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleJob.perform_later
          end
        end
        batch.on :success,
                 ExampleSuccessCallback,
                 'example_arg'

        # Act - Drain the job
        perform_enqueued_jobs only: ExampleJob

        # Assert - the success callback must be enqueued
        expect(ExampleSuccessCallback).to have_been_enqueued.with([example_child_reference1], 'example_arg')
      end

      it 'does not enqueue the failed callback when done with no failures' do
        # Arrange - call the example worker in a batch and setup callbacks
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleJob.perform_later
          end
        end
        batch.on :success,
                 ExampleSuccessCallback,
                 'example_arg'
        batch.on :failed,
                 ExampleFailedCallback

        # Act - Drain the job
        perform_enqueued_jobs only: ExampleJob

        # Assert - the success callback must be enqueued
        expect(ExampleFailedCallback).not_to have_been_enqueued
      end

      it 'does not enqueue the success callback if the batch fails with 1 job completely failing' do
        # Arrange - call the example worker in a batch, setup callbacks and use up 1 of the retries
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleCompletelyFailedJob.perform_later
          end
        end
        batch.on :success,
                 ExampleSuccessCallback,
                 'example_arg'
        batch.on :failed,
                 ExampleFailedCallback

        execute_job_without_removing(ExampleCompletelyFailedJob)

        # Act - Use the second retry
        execute_job_without_removing(ExampleCompletelyFailedJob)

        # Assert - the success callback must be enqueued
        expect(ExampleSuccessCallback).not_to have_been_enqueued
      end

      it 'enqueues the failed callback if the batch fails with 1 job completely failing' do
        # Arrange - call the example worker in a batch, setup callbacks and use up 1 of the retries
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleCompletelyFailedJob.perform_later
          end
        end
        batch.on :success,
                 ExampleSuccessCallback,
                 'example_arg'
        batch.on :failed,
                 ExampleFailedCallback,
                 'example_failed_arg'

        execute_job_without_removing(ExampleCompletelyFailedJob)

        # Act - Use the second retry
        execute_job_without_removing(ExampleCompletelyFailedJob)

        # Assert - the success callback must be enqueued
        expect(ExampleFailedCallback).to have_been_enqueued.with([], [example_child_reference1], 'example_failed_arg')
      end
    end
  end
end
