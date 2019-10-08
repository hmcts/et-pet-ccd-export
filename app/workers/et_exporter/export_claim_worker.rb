module EtExporter
  class ExportClaimWorker
    include Sidekiq::Worker
    include AsyncApplicationEvents
    include ExportRetryControl
    self.exceptions_without_retry = [EtCcdClient::Exceptions::UnprocessableEntity, PreventJobRetryingException].freeze

    attr_accessor :job_hash

    def perform(json)
      before_perform
      logger.debug "---------------------------------------------------------------------------------------------------------"
      logger.debug "- THIS IS THE JSON THAT HAS COME FROM THE API                                                           -"
      logger.debug "-                                                                                                       -"
      logger.debug "---------------------------------------------------------------------------------------------------------"

      parsed_json = JSON.parse(json)
      logger.debug JSON.generate(parsed_json)

      if parsed_json.dig('resource', 'secondary_claimants').present?
        perform_multiples(parsed_json)
      else
        perform_single(parsed_json)
      end
    end

    private

    def perform_multiples(parsed_json)
      ExportMultipleClaimsService.new.call(parsed_json, sidekiq_job_data: job_hash)
    end

    def perform_single(parsed_json)
      ExportClaimService.new.call(parsed_json, sidekiq_job_data: job_hash)
    rescue Exception => ex
      send_claim_erroring_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash)
      raise ex
    end
  end
end
