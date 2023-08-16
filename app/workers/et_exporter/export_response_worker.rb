module EtExporter
  class ExportResponseWorker
    include Sidekiq::Worker
    include ExportRetryControl
    self.exceptions_without_retry = [PreventJobRetryingException].freeze

    attr_accessor :job_hash

    def initialize(application_events_service: ApplicationEventsService, service: ExportResponseService.new)
      self.events_service = application_events_service
      self.service = service
    end

    def perform(json)
      before_perform
      parsed_json = JSON.parse(json)
      debug_log(parsed_json)
      send_started_event(parsed_json)
      claim = service.call(parsed_json, sidekiq_job_data: job_hash) unless ENV.fetch('ET_CCD_SIMULATION', 'false').downcase == 'true'

      send_exported_event(parsed_json, claim)
    rescue StandardError => e
      events_service.send_response_erroring_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: e)
      raise e
    end

    def tag_sentry(job, scope:)
      scope.set_tags reference: JSON.parse(job['args'].first).dig('resource', 'reference')
    end

    sidekiq_retries_exhausted do |msg, ex|
      json = JSON.parse(msg['args'][0])
      job_data = msg.except('args', 'class').merge(ex.try(:job_hash) || {})
      ApplicationEventsService.send_response_failed_event(export_id: json['id'], sidekiq_job_data: job_data)
      raise ClaimNotExportedException
    end

    private

    attr_accessor :service, :events_service

    def debug_log(parsed_json)
      logger.debug "---------------------------------------------------------------------------------------------------------"
      logger.debug "- THIS IS THE JSON THAT HAS COME FROM THE API                                                           -"
      logger.debug "-                                                                                                       -"
      logger.debug "---------------------------------------------------------------------------------------------------------"

      logger.debug JSON.generate(parsed_json)
    end

    def send_started_event(parsed_json)
      events_service.send_response_export_started_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash)
    end

    def send_exported_event(parsed_json, claim)
      case_type_id = parsed_json.dig('external_system', 'configurations').detect { |c| c['key'] == 'case_type_id' }['value']
      events_service.send_response_exported_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, case_id: claim&.fetch('id'), case_type_id: case_type_id,
                                                  case_reference: parsed_json.dig('resource', 'case_number'), office: claim&.dig('case_data', 'managingOffice'))
    end
  end
end
