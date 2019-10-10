module EtExporter
  class ExportResponseWorker
    include Sidekiq::Worker
    include ExportRetryControl
    self.exceptions_without_retry = [EtCcdClient::Exceptions::UnprocessableEntity, PreventJobRetryingException].freeze

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

      events_service.send_response_export_started_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash)
      updated_case = service.call(parsed_json, sidekiq_job_data: job_hash) unless ENV.fetch('ET_CCD_SIMULATION', 'false').downcase == 'true'
      events_service.send_response_exported_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, case_id: updated_case['id'], case_reference: updated_case.dig('case_data', 'ethosCaseReference'), case_type_id: updated_case['case_type_id'])
    rescue Exception => ex
      events_service.send_response_erroring_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash)
      raise ex
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
