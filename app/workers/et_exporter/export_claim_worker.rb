module EtExporter
  class ExportClaimWorker
    include Sidekiq::Worker

    def perform(json)
      logger.debug "---------------------------------------------------------------------------------------------------------"
      logger.debug "- THIS IS THE JSON THAT HAS COME FROM THE API                                                           -"
      logger.debug "-                                                                                                       -"
      logger.debug "---------------------------------------------------------------------------------------------------------"

      parsed_json = JSON.parse(json)
      logger.debug JSON.generate(parsed_json)

      if parsed_json.dig('resource', 'secondary_claimants').present?
        ExportMultipleClaimsService.new.call(parsed_json, jid: jid) unless ENV.fetch('ET_CCD_SIMULATION', 'false').downcase == 'true'
      else
        ExportClaimService.new.call(parsed_json, jid: jid) unless ENV.fetch('ET_CCD_SIMULATION', 'false').downcase == 'true'
      end
    end
  end
end
