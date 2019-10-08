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
        ExportMultipleClaimsService.new.call(parsed_json, sidekiq_job_data: job_hash)
      else
        ExportClaimService.new.call(parsed_json, sidekiq_job_data: job_hash)
      end
    end

    sidekiq_retries_exhausted do |msg, ex|
      sleep 0.1 # TODO Remove - this is to allow the error event to be reported, then a delay then the failure
      json = JSON.parse(msg['args'][0])
      new.send_claim_failed_event(export_id: json['id'], sidekiq_job_data: msg.except('args', 'class'))
      raise ClaimNotExportedException
    end
  end
end
