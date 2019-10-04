module EtExporter
  class ExportClaimWorker
    include Sidekiq::Worker

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
  end
end
