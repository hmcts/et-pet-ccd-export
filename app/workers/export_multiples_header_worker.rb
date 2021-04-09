class ExportMultiplesHeaderWorker
  include Sidekiq::Worker
  include ExportRetryControl
  sidekiq_options queue: 'external_system_ccd'

  self.exceptions_without_retry = [PreventJobRetryingException].freeze

  attr_accessor :job_hash

  def initialize(application_events_service: ApplicationEventsService, service: ExportMultipleClaimsService.new)
    self.events_service = application_events_service
    self.service = service
  end


  def perform(primary_reference, respondent_name, case_references, case_type_id, export_id)
    created_case = service.export_header(primary_reference, respondent_name, case_references, case_type_id, export_id, sidekiq_job_data: job_hash)
    events_service.send_multiples_claim_exported_event(export_id: export_id, sidekiq_job_data: job_hash, case_id: created_case['id'], case_reference: created_case.dig('case_data', 'multipleReference'), case_type_id: case_type_id)
    logger.debug("Multiple header exported for export id #{export_id} with case reference #{created_case.dig('case_data', 'multipleReference')}")
  end

  sidekiq_retries_exhausted do |msg, ex, application_events_service: ApplicationEventsService|
    _primary_reference, _respondent_name, _case_references, _case_type_id, export_id = msg['args']
    job_data = msg.except('args', 'class').merge(ex.try(:job_hash) || {})
    application_events_service.send_claim_failed_event(export_id: export_id, sidekiq_job_data: job_data)
    raise ClaimNotExportedException
  end

  private

  attr_accessor :events_service, :service
end
