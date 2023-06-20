module EtCcdExport
  module Sidekiq
    module Middleware
      class ExposeJobHashMiddleware

        def call(worker, msg, _queue)
          worker.try(:job_hash=, msg)
          yield
        end
      end
    end
  end
end
