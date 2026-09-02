module EtCcdExport
  class TriggerEventJobProxyJob < ApplicationJob
    include EtCcdExport::ActiveJobSentryMetadata

    def serialize
      super.merge("job_class" => "TriggerEventJob")
    end
  end
end
