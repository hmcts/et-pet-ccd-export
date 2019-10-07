module EtCcdExport
  module Sidekiq
    module Middleware
      class ExposeJobHashMiddleware

        def call(worker, msg, queue)
          worker.try(:job_hash=, msg.symbolize_keys.except(:args, :class, :queue))
          yield
        end
      end
    end
  end
end