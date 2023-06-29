module EtCcdExport
  module Sidekiq
    module Middleware
      class SentryMiddleware
        def call(worker, job, _queue)
          return yield unless Sentry.initialized?

          Sentry.clone_hub_to_current_thread
          scope = Sentry.get_current_scope
          if worker.respond_to?(:tag_sentry)
            worker.tag_sentry(job, scope: scope)
          end
          yield

          # don't need to use ensure here
          # if the job failed, we need to keep the scope for error handler. and the scope will be cleared there
          scope.clear
        end
      end
    end
  end
end
