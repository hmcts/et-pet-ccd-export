module EtCcdExport
  module ActiveJobSentryMetadata
    extend ActiveSupport::Concern

    included do
      around_perform do |job, block|
        return block.call unless Sentry.initialized?

        Sentry.clone_hub_to_current_thread
        scope = Sentry.get_current_scope
        if job.respond_to?(:tag_sentry)
          job.tag_sentry(scope: scope)
        end
        block.call

        # don't need to use ensure here
        # if the job failed, we need to keep the scope for error handler. and the scope will be cleared there
        scope.clear
      end
    end
  end
end
