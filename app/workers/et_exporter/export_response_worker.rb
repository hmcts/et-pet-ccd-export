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
      logger.debug "---------------------------------------------------------------------------------------------------------"
      logger.debug "- THIS IS THE JSON THAT HAS COME FROM THE API                                                           -"
      logger.debug "-                                                                                                       -"
      logger.debug "---------------------------------------------------------------------------------------------------------"

      parsed_json = JSON.parse(json)
      logger.debug JSON.generate(parsed_json)

      Sentry.with_scope do |scope|
        scope.set_tags reference: parsed_json.dig('resource', 'reference')
        events_service.send_response_export_started_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash)
        claim = service.call(parsed_json, sidekiq_job_data: job_hash) unless ENV.fetch('ET_CCD_SIMULATION', 'false').downcase == 'true'

        case_type_id = parsed_json.dig('external_system', 'configurations').detect { |c| c['key'] == 'case_type_id' }['value']
        events_service.send_response_exported_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, case_id: claim&.fetch('id'),
                                                    case_reference: parsed_json.dig('resource', 'case_number'), case_type_id: case_type_id, office: claim&.dig('case_data', 'managingOffice'))
      end
    rescue StandardError => e
      events_service.send_response_erroring_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: e)
      raise e
    end

    sidekiq_retries_exhausted do |msg, ex|
      json = JSON.parse(msg['args'][0])
      job_data = msg.except('args', 'class').merge(ex.try(:job_hash) || {})
      ApplicationEventsService.send_response_failed_event(export_id: json['id'], sidekiq_job_data: job_data)
      raise ClaimNotExportedException
    end

    private

    attr_accessor :service, :events_service
  end
end
