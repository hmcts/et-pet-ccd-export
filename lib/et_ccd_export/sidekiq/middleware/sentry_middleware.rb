module EtCcdExport
  module Sidekiq
    module Middleware
      class SentryMiddleware
        def call(worker, job, _queue)
          return yield unless Sentry.initialized? && job.respond_to?(:tag_sentry)

          Sentry.with_scope do |_scope|
            worker.tag_sentry(job)
            yield
          end
        end
      end
    end
  end
end
