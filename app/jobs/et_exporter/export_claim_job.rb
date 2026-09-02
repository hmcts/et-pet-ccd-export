module EtExporter
  class ExportClaimJob < EtCcdExport::ApplicationJob
    include EtCcdExport::ActiveJobExportRetryControl
    include EtCcdExport::ActiveJobSentryMetadata

    def perform(json)
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

    def tag_sentry(scope:)
      scope.set_tags reference: JSON.parse(arguments.first).dig('resource', 'reference')
    end

    private

    def events_service
      EtCcdExport::ApplicationEventsService
    end

    def singles_service
      @singles_service ||= EtCcdExport::ExportClaimService.new
    end

    def multiples_service
      @multiples_service ||= EtCcdExport::ExportMultipleClaimsService.new(use_sidekiq: false)
    end

    def perform_multiples(parsed_json)
      send_multiples_claim_export_started_event(parsed_json)
      bid = multiples_service.call(parsed_json, sidekiq_job_data: job_hash)
      send_claim_export_multiples_queued_event parsed_json, bid
    rescue EtCcdExport::ClaimMultipleClaimantCountExceededException => e
      events_service.send_multiples_claim_size_exceeded_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: e, use_sidekiq: false)
    rescue Exception => e # rubocop:disable Lint/RescueException
      events_service.send_multiples_claim_erroring_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: e, use_sidekiq: false)
      raise e
    end

    def perform_single(parsed_json)
      send_claim_export_started_event(parsed_json)
      created_case = singles_service.call(parsed_json, sidekiq_job_data: job_hash)
      send_claim_exported_event(parsed_json, created_case)
    rescue Exception => e # rubocop:disable Lint/RescueException
      events_service.send_claim_erroring_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: e, use_sidekiq: false)
      raise e
    end

    def percent_complete_for(number, claimant_count:)
      (number * (100.0 / (claimant_count + 2))).to_i
    end

    def send_claim_export_started_event(parsed_json)
      events_service.send_claim_export_started_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, use_sidekiq: false)
    end

    def send_claim_exported_event(parsed_json, created_case)
      events_service.send_claim_exported_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, case_id: created_case['id'],
                                               case_reference: created_case.dig('case_data', 'ethosCaseReference'), case_type_id: created_case['case_type_id'],
                                               use_sidekiq: false)
    end

    def send_multiples_claim_export_started_event(parsed_json)
      events_service.send_multiples_claim_export_started_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, use_sidekiq: false)
    end

    def send_claim_export_multiples_queued_event(parsed_json, bid)
      events_service.send_claim_export_multiples_queued_event queued_bid: bid, sidekiq_job_data: job_hash, export_id: parsed_json['id'], percent_complete: 0, use_sidekiq: false
    end
  end
end
