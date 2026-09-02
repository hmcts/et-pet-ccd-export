module EtCcdExport
  module ActiveJobSentryMetadata
    extend ActiveSupport::Concern

    included do
      before_perform do |job|
        next unless Sentry.initialized? && job.respond_to?(:tag_sentry)

        job.tag_sentry
      end
    end
  end
end
