module EtExporter
  class ExportResponseJob < EtCcdExport::ApplicationJob
    include EtCcdExport::ActiveJobExportRetryControl
    include EtCcdExport::ActiveJobSentryMetadata

    def perform(json)
      parsed_json = JSON.parse(json)
      debug_log(parsed_json)
      send_started_event(parsed_json)
      claim = service.call(parsed_json, sidekiq_job_data: job_hash) unless ENV.fetch('ET_CCD_SIMULATION', 'false').downcase == 'true'

      send_exported_event(parsed_json, claim)
    rescue StandardError => e
      events_service.send_response_erroring_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: e, use_sidekiq: false)
      raise e
    end

    def tag_sentry(scope:)
      scope.set_tags reference: JSON.parse(arguments.first).dig('resource', 'reference')
    end

    def retries_exhausted(exception)
      export = JSON.parse(arguments.first)
      EtCcdExport::ApplicationEventsService.send_response_failed_event(export_id: export['id'], sidekiq_job_data: active_job_data(exception), use_sidekiq: false)
      raise EtCcdExport::ClaimNotExportedException
    end

    private

    def events_service
      EtCcdExport::ApplicationEventsService
    end

    def service
      @service ||= EtCcdExport::ExportResponseService.new
    end

    def debug_log(parsed_json)
      logger.debug "---------------------------------------------------------------------------------------------------------"
      logger.debug "- THIS IS THE JSON THAT HAS COME FROM THE API                                                           -"
      logger.debug "-                                                                                                       -"
      logger.debug "---------------------------------------------------------------------------------------------------------"

      logger.debug JSON.generate(parsed_json)
    end

    def send_started_event(parsed_json)
      events_service.send_response_export_started_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, use_sidekiq: false)
    end

    def send_exported_event(parsed_json, claim)
      case_type_id = parsed_json.dig('external_system', 'configurations').detect { |c| c['key'] == 'case_type_id' }['value']
      events_service.send_response_exported_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, case_id: claim&.fetch('id'), case_type_id: case_type_id,
                                                  case_reference: parsed_json.dig('resource', 'case_number'), office: claim&.dig('case_data', 'managingOffice'),
                                                  use_sidekiq: false)
    end
  end
end
