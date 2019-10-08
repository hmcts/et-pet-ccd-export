module EtCcdExport
  module Sidekiq
    module Middleware
      class ExposeJobHashMiddleware

        def call(worker, msg, queue)
          worker.try(:job_hash=, msg)
          yield
        end
      end
    end
  end
end