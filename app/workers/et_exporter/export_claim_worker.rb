module EtExporter
  class ExportClaimWorker
    include Sidekiq::Worker
    include ExportRetryControl
    self.exceptions_without_retry = [PreventJobRetryingException].freeze

    attr_accessor :job_hash

    def initialize(application_events_service: ApplicationEventsService, singles_service: ExportClaimService.new, multiples_service: ExportMultipleClaimsService.new)
      self.events_service = application_events_service
      self.singles_service = singles_service
      self.multiples_service = multiples_service
    end

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

    attr_accessor :events_service, :singles_service, :multiples_service

    def perform_multiples(parsed_json)
      events_service.send_multiples_claim_export_started_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash)
      bid = multiples_service.call(parsed_json, sidekiq_job_data: job_hash)
      events_service.send_claim_export_multiples_queued_event queued_bid: bid, sidekiq_job_data: job_hash, export_id: parsed_json['id'], percent_complete: percent_complete_for(1, claimant_count: parsed_json.dig('resource', 'secondary_claimants').length + 1)
    rescue ClaimMultipleClaimantCountExceededException => ex
      events_service.send_multiples_claim_size_exceeded_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: ex)
    rescue Exception => ex
      events_service.send_multiples_claim_erroring_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: ex)
      raise ex
    end

    def perform_single(parsed_json)
      events_service.send_claim_export_started_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash)
      created_case = singles_service.call(parsed_json, sidekiq_job_data: job_hash)
      events_service.send_claim_exported_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, case_id: created_case['id'], case_reference: created_case.dig('case_data', 'ethosCaseReference'), case_type_id: created_case['case_type_id'])

    rescue Exception => ex
      events_service.send_claim_erroring_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: ex)
      raise ex
    end

    def percent_complete_for(number, claimant_count:)
      (number * (100.0 / (claimant_count + 2))).to_i
    end
  end
end
