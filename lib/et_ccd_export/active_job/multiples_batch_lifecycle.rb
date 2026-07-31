module EtCcdExport
  module ActiveJob
    class MultiplesBatchLifecycle
      def initialize(job:)
        @job = job
        @batch = job.batch
      end

      def call(events_service: ApplicationEventsService)
        return yield unless batch_child_job?

        batch.move_child_to_in_progress(job.job_metadata['et_ccd_export_multiple_batch_child_reference'])
        begin
          yield.tap do |id|
            done(id, job, batch, events_service: events_service)
          end
        rescue StandardError => e
          tidy_up(batch, job, e, events_service: events_service)
          raise e
        end
      end

      def job_discarded!
        child_ref = job.job_metadata['et_ccd_export_multiple_batch_child_reference']
        return if child_ref.nil? || batch.nil?

        batch.move_child_to_failed(child_ref)
        schedule_failed_callbacks(batch) unless batch.more_work_to_be_done?
      end

      private

      attr_reader :batch, :job

      def done(id, job, batch, events_service: ApplicationEventsService)
        child_ref = job.job_metadata['et_ccd_export_multiple_batch_child_reference']
        batch.move_child_to_done(child_ref)
        events_service.send_claim_export_multiples_progress_event sidekiq_job_data: job.serialize,
                                                                  export_id: batch.export_id,
                                                                  percent_complete: batch.percent_complete,
                                                                  case_id: id,
                                                                  case_reference: child_ref,
                                                                  case_type_id: batch.case_type_id,
                                                                  use_sidekiq: false
        on_done(batch)
      end

      def tidy_up(batch, job, exception, events_service: ApplicationEventsService)
        child_ref = job.job_metadata['et_ccd_export_multiple_batch_child_reference']
        batch.move_child_to_error(child_ref)
        unless exception.is_a?(PreventJobRetryingException)
          events_service.send_subclaim_erroring_event(export_id: batch.export_id, sidekiq_job_data: job.serialize.except('class', 'args', 'queue'),
                                                      exception: exception, use_sidekiq: false)
        end
        schedule_failed_callbacks(batch) unless batch.more_work_to_be_done?
      end

      def on_done(batch)
        return if batch.more_work_to_be_done?
        return schedule_failed_callbacks(batch) if batch.failed?

        schedule_success_callbacks(batch)
        batch.destroy
      end

      def schedule_success_callbacks(batch)
        batch.callbacks.each do |cb|
          next unless cb['event'] == 'success'

          cb['class_name'].safe_constantize.perform_later(batch.done_references, *cb['args'])
        end
      end

      def batch_child_job?
        job.job_metadata.key?('et_ccd_export_multiple_batch_reference') && job.job_metadata.key?('et_ccd_export_multiple_batch_child_reference')
      end

      def find_batch(job, batch: EtCcdExport::Sidekiq::Batch)
        batch.find(job.job_metadata['et_ccd_export_multiple_batch_reference'])
      end

      def schedule_failed_callbacks(batch)
        batch.callbacks.each do |cb|
          next unless cb['event'] == 'failed'

          cb['class_name'].safe_constantize.perform_later(batch.done_references, batch.failed_references, *cb['args'])
        end
      end
    end
  end
end
