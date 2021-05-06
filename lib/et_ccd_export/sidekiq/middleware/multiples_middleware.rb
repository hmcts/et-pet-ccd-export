module EtCcdExport
  module Sidekiq
    module Middleware
      class MultiplesMiddleware

        def call(worker, msg, queue, events_service: ApplicationEventsService)
          return yield unless batch_child_job?(msg)

          batch = find_batch(msg)
          batch.move_child_to_in_progress(msg['et_ccd_export_multiple_batch_child_reference'])
          begin
            yield.tap do |id|
              child_ref = msg['et_ccd_export_multiple_batch_child_reference']
              batch.move_child_to_done(child_ref)
              schedule_callbacks_when_done(batch)
              events_service.send_claim_export_multiples_progress_event sidekiq_job_data: msg,
                                                                        export_id: batch.export_id,
                                                                        percent_complete: batch.percent_complete,
                                                                        case_id: id,
                                                                        case_reference: child_ref,
                                                                        case_type_id: batch.case_type_id
            end
          rescue Exception => ex
            events_service.send_subclaim_erroring_event(export_id: batch.export_id, sidekiq_job_data: msg.except('class', 'args', 'queue'), exception: ex) unless ex.is_a?(PreventJobRetryingException)
            raise ex
          end
        end

        private

        def schedule_callbacks_when_done(batch)
          return if batch.todo_count.positive? ||
            batch.done_count.zero? ||
            batch.error_count.positive? ||
            batch.failed_count.positive?

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
      end
    end
  end
end
