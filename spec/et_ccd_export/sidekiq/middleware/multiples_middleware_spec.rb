# frozen_string_literal: true

require 'rails_helper'

describe EtCcdExport::Sidekiq::Middleware::MultiplesMiddleware do

  before do
    stub_const('ExampleWorker', Class.new do
      include Sidekiq::Worker

      def perform
        123456 # A fake id from the worker
      end
    end)

    # This worker will fail first and second times and succeed after that
    stub_const('ExampleFailingWorker', Class.new do
      include Sidekiq::Worker
      attr_accessor :job_hash # The middleware will populate this with the current job

      def perform
        retry_count = job_hash.fetch('retry_count', 0)
        if retry_count <= 1
          job_hash.merge! 'retry_count' => retry_count + 1,
                          'error_message' => 'An error occurred in the worker',
                          'error_class' => ExampleException,
                          'failed_at' => Time.now.to_f,
                          'retried_at' => Time.now.to_f

          raise ExampleException, "An error occurred in the worker"
        end
        123456 # A fake id from the worker
      end
    end)

    stub_const('ExampleCompletelyFailedWorker', Class.new do
      include Sidekiq::Worker
      sidekiq_options retry: 2
      attr_accessor :job_hash # The middleware will populate this with the current job

      def perform
        retry_count = job_hash.fetch('retry_count', 0)
        job_hash.merge! 'retry_count' => retry_count + 1,
                        'error_message' => 'An error occurred in the worker',
                        'error_class' => ExampleException,
                        'failed_at' => Time.now.to_f,
                        'retried_at' => Time.now.to_f

        raise ExampleException, "An error occurred in the worker"
      end
    end)

    stub_const('ExampleException', Class.new(StandardError))

    stub_const('ExampleSuccessCallback', Class.new do
      include Sidekiq::Worker
    end)

    stub_const('ExampleFailedCallback', Class.new do
      include Sidekiq::Worker
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
    drain_all_our_sidekiq_jobs
  rescue Exception
  end

  def execute_job_without_removing(worker)
    worker.process_job(worker.jobs.first)
  rescue ExampleException
  end
  describe '#perform' do
    context 'with a child job as part of a batch' do
      it 'moves the job to done in the batch' do
        # Arrange - call the example worker in a batch
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleWorker.perform_async
          end
          batch.child_job(example_child_reference2) do
            ExampleFailingWorker.perform_async # Else the batch will complete and be destroyed
          end
        end

        # Act - Drain the job (Only the good one)
        ExampleWorker.drain

        # Assert - the done reference should include the first and todo should contain second (as it hasn't ran)
        expect(batch).to have_attributes done_references: [example_child_reference1],
                                         todo_references: [example_child_reference2],
                                         persisted?: true
      end

      it 'removes the batch when all jobs are done' do
        # Arrange - call the example worker in a batch
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleWorker.perform_async
          end
        end

        # Act - Drain the job
        ExampleWorker.drain

        # Assert - the batch will no longer be persisted (ensures it is removed from redis)
        expect(batch.persisted?).to be false
      end

      it 'moves the job to error if the worker has an error' do
        # Arrange - schedule the failing job once - then drain the queue, then schedule again
        batch.jobs do
          batch.child_job(example_child_reference2) do
            ExampleFailingWorker.perform_async
          end
        end
        drain_all
        batch.jobs do
          batch.child_job(example_child_reference2) do
            ExampleFailingWorker.perform_async
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
            ExampleWorker.perform_async
          end
          batch.child_job(example_child_reference2) do
            ExampleFailingWorker.perform_async # Else the batch will complete and be destroyed
          end
        end

        # Act - Drain the job ignoring the exception
        begin
          drain_all_our_sidekiq_jobs
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
            ExampleFailingWorker.perform_async # The first one fails
          end
        end
        execute_job_without_removing(ExampleFailingWorker)
        execute_job_without_removing(ExampleFailingWorker)

        # Act - Drain the job ignoring the exception
        drain_all

        # Assert - the batch should have disappeared as it is done
        expect(batch.persisted?).to be false
      end

      it 'schedules the success worker when done with no failures' do
        # Arrange - call the example worker in a batch and setup callbacks
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleWorker.perform_async
          end
        end
        batch.on :success,
                 ExampleSuccessCallback,
                 'example_arg'

        # Act - Drain the job
        ExampleWorker.drain

        # Assert - the success callback must be enqueued
        expect(ExampleSuccessCallback).to have_enqueued_sidekiq_job([example_child_reference1], 'example_arg')
      end

      it 'does not enqueue the failed callback when done with no failures' do
        # Arrange - call the example worker in a batch and setup callbacks
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleWorker.perform_async
          end
        end
        batch.on :success,
                 ExampleSuccessCallback,
                 'example_arg'
        batch.on :failed,
                 ExampleFailedCallback

        # Act - Drain the job
        ExampleWorker.drain

        # Assert - the success callback must be enqueued
        expect(ExampleFailedCallback).not_to have_enqueued_sidekiq_job
      end

      it 'does not enqueue the success callback if the batch fails with 1 job completely failing' do
        # Arrange - call the example worker in a batch, setup callbacks and use up 1 of the retries
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleCompletelyFailedWorker.perform_async
          end
        end
        batch.on :success,
                 ExampleSuccessCallback,
                 'example_arg'
        batch.on :failed,
                 ExampleFailedCallback

        execute_job_without_removing(ExampleCompletelyFailedWorker)

        # Act - Use the second retry
        execute_job_without_removing(ExampleCompletelyFailedWorker)

        # Assert - the success callback must be enqueued
        expect(ExampleSuccessCallback).not_to have_enqueued_sidekiq_job
      end

      it 'enqueues the failed callback if the batch fails with 1 job completely failing' do
        # Arrange - call the example worker in a batch, setup callbacks and use up 1 of the retries
        batch.jobs do
          batch.child_job(example_child_reference1) do
            ExampleCompletelyFailedWorker.perform_async
          end
        end
        batch.on :success,
                 ExampleSuccessCallback,
                 'example_arg'
        batch.on :failed,
                 ExampleFailedCallback,
                 'example_failed_arg'

        execute_job_without_removing(ExampleCompletelyFailedWorker)

        # Act - Use the second retry
        execute_job_without_removing(ExampleCompletelyFailedWorker)

        # Assert - the success callback must be enqueued
        expect(ExampleFailedCallback).to have_enqueued_sidekiq_job([], [example_child_reference1], 'example_failed_arg')
      end
    end
  end
end
