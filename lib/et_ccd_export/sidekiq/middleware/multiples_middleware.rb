module EtCcdExport
  module Sidekiq
    module Middleware
      class MultiplesMiddleware
        DEFAULT_MAX_RETRY_ATTEMPTS = 25

        def call(worker, msg, queue, events_service: ApplicationEventsService)
          return yield unless batch_child_job?(msg)

          batch = find_batch(msg)
          batch.move_child_to_in_progress(msg['et_ccd_export_multiple_batch_child_reference'])
          begin
            yield.tap do |id|
              child_ref = msg['et_ccd_export_multiple_batch_child_reference']
              batch.move_child_to_done(child_ref)
              events_service.send_claim_export_multiples_progress_event sidekiq_job_data: msg,
                                                                        export_id: batch.export_id,
                                                                        percent_complete: batch.percent_complete,
                                                                        case_id: id,
                                                                        case_reference: child_ref,
                                                                        case_type_id: batch.case_type_id
              on_done(batch)
            end
          rescue Exception => ex
            child_ref = msg['et_ccd_export_multiple_batch_child_reference']
            if last_retry?(msg)
              batch.move_child_to_failed(child_ref)
            else
              batch.move_child_to_error(child_ref)
            end
            events_service.send_subclaim_erroring_event(export_id: batch.export_id, sidekiq_job_data: msg.except('class', 'args', 'queue'), exception: ex) unless ex.is_a?(PreventJobRetryingException)
            schedule_failed_callbacks(batch) unless batch.more_work_to_be_done?
            raise ex
          end
        end

        private

        def last_retry?(msg)
          max_retries = msg.fetch('retry', false)
          return true if max_retries === false

          max_retries = max_retries_config if max_retries === true
          msg.fetch('retry_count', 0) >= max_retries
        end

        def max_retries_config
          @max_retries_config ||= ::Sidekiq.options.fetch(:max_retries, DEFAULT_MAX_RETRY_ATTEMPTS)
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

            cb['class_name'].safe_constantize.perform_async(batch.done_references, *cb['args'])
          end
        end

        def batch_child_job?(msg)
          msg.key?('et_ccd_export_multiple_batch_reference') && msg.key?('et_ccd_export_multiple_batch_child_reference')
        end

        def find_batch(msg, batch: EtCcdExport::Sidekiq::Batch)
          batch.find(msg['et_ccd_export_multiple_batch_reference'])
        end

        def schedule_failed_callbacks(batch)
          batch.callbacks.each do |cb|
            next unless cb['event'] == 'failed'

            cb['class_name'].safe_constantize.perform_async(batch.done_references, batch.failed_references, *cb['args'])
          end
        end
      end
    end
  end
end
