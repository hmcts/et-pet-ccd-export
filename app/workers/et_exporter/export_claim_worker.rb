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

    def tag_sentry(job, scope:)
      scope.set_tags reference: JSON.parse(job['args'].first).dig('resource', 'reference')
    end

    private

    attr_accessor :events_service, :singles_service, :multiples_service

    def perform_multiples(parsed_json)
      send_multiples_claim_export_started_event(parsed_json)
      bid = multiples_service.call(parsed_json, sidekiq_job_data: job_hash)
      send_claim_export_multiples_queued_event parsed_json, bid
    rescue ClaimMultipleClaimantCountExceededException => e
      events_service.send_multiples_claim_size_exceeded_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: e)
    rescue Exception => e # rubocop:disable Lint/RescueException
      events_service.send_multiples_claim_erroring_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: e)
      raise e
    end

    def perform_single(parsed_json)
      send_claim_export_started_event(parsed_json)
      created_case = singles_service.call(parsed_json, sidekiq_job_data: job_hash)
      send_claim_exported_event(parsed_json, created_case)
    rescue Exception => e # rubocop:disable Lint/RescueException
      events_service.send_claim_erroring_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: e)
      raise e
    end

    def percent_complete_for(number, claimant_count:)
      (number * (100.0 / (claimant_count + 2))).to_i
    end

    def send_claim_export_started_event(parsed_json)
      events_service.send_claim_export_started_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash)
    end

    def send_claim_exported_event(parsed_json, created_case)
      events_service.send_claim_exported_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, case_id: created_case['id'],
                                               case_reference: created_case.dig('case_data', 'ethosCaseReference'), case_type_id: created_case['case_type_id'])
    end

    def send_multiples_claim_export_started_event(parsed_json)
      events_service.send_multiples_claim_export_started_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash)
    end

    def send_claim_export_multiples_queued_event(parsed_json, bid)
      events_service.send_claim_export_multiples_queued_event queued_bid: bid, sidekiq_job_data: job_hash, export_id: parsed_json['id'], percent_complete: 0
    end
  end
end
