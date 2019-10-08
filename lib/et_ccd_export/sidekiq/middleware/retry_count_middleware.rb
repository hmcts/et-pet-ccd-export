module EtCcdExport
  module Sidekiq
    module Middleware
      class RetryCountMiddleware
        include ::Sidekiq::ExceptionHandler

        def call(worker, msg, queue_name)
          yield
        rescue => ex
          puts "*************** RetryCountMiddleware - msg is #{msg} *************************"
          if ex.is_a?(::EtCcdClient::Exceptions::UnprocessableEntity)
            msg['retry'] = false
            msg['error_class'] = ex.class.to_s
            msg['error_message'] = ex.message
            msg['failed_at'] = Time.now.to_f
            retries_exhausted(worker, msg, ex)
            kill_job(ex, msg)
          else
            raise ex
          end
        end

        private

        def retries_exhausted(worker, msg, ex)
          begin
            block = worker && worker.sidekiq_retries_exhausted_block
            block.call(msg, ex) if block
          rescue => e
            handle_exception(e, {context: "Error calling retries_exhausted", job: msg})
          end
        end

        def kill_job(ex, msg)
          ::Sidekiq::DeadSet.new.kill(::Sidekiq.dump_json(msg), notify_failure: false)
          notify_death(ex, msg)
        end

        def notify_death(ex, msg)
          ::Sidekiq.death_handlers.each do |handler|
            begin
              handler.call(msg, ex)
            rescue => e
              handle_exception(e, {context: "Error calling death handler", job: msg})
            end
          end
        end

      end
    end
  end
end