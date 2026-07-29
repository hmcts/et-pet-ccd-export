module EtCcdExport
  class TriggerEventJobProxyJob < ApplicationJob
    def serialize
      super.merge("job_class" => "TriggerEventJob")
    end
  end
end
