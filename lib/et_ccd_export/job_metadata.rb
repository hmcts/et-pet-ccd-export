module EtCcdExport
  module JobMetadata
    extend ActiveSupport::Concern

    def job_metadata
      @job_metadata ||= {}
    end

    def serialize
      super.merge('et_ccd_export_metadata' => job_metadata)
    end

    def deserialize(job_data)
      super
      @job_metadata = job_data['et_ccd_export_metadata']
    end
  end
end
