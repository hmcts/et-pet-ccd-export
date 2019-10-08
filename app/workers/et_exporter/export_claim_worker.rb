module EtExporter
  class ExportClaimWorker
    include Sidekiq::Worker
    include AsyncApplicationEvents

    attr_accessor :job_hash

    def perform(json)
      logger.debug "---------------------------------------------------------------------------------------------------------"
      logger.debug "- THIS IS THE JSON THAT HAS COME FROM THE API                                                           -"
      logger.debug "-                                                                                                       -"
      logger.debug "---------------------------------------------------------------------------------------------------------"

      parsed_json = JSON.parse(json)
      logger.debug JSON.generate(parsed_json)

      if parsed_json.dig('resource', 'secondary_claimants').present?
        self.service = ExportMultipleClaimsService.new
      else
        self.service = ExportClaimService.new
      end
      service.call(parsed_json, sidekiq_job_data: job_hash)
    end

    sidekiq_retries_exhausted do |msg, ex|
      json = JSON.parse(msg['args'][0])
      new.send_claim_failed_event(export_id: json['id'], sidekiq_job_data: msg.except('args', 'class'))
      raise ClaimNotExportedException
    end

    def prevent_retry?(ex)
      service.prevent_retry?(ex)
    end

    private

    attr_accessor :service
  end
end
