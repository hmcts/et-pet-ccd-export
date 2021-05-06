# This worker sends a child case for a multiple
class ExportMultiplesWorker
  include Sidekiq::Worker
  include ExportRetryControl
  self.exceptions_without_retry = [].freeze

  attr_accessor :job_hash

  sidekiq_options queue: 'external_system_ccd_multiples'

  def initialize(application_events_service: ApplicationEventsService, multiples_service: ExportMultipleClaimsService.new)
    self.events_service    = application_events_service
    self.multiples_service = multiples_service
  end

  def perform(ccd_data, case_type_id, export_id, claimant_count, primary = false, send_request_id = false, extra_headers = {})
    before_perform
    multiples_service.export ccd_data,
                             case_type_id,
                             sidekiq_job_data: job_hash,
                             export_id:        export_id,
                             claimant_count:   claimant_count,
                             send_request_id:  send_request_id,
                             extra_headers:    extra_headers
  end

  sidekiq_retries_exhausted do |msg, ex|
    job_data = msg.except('args', 'class').merge(ex.try(:job_hash) || {})
    ApplicationEventsService.send_subclaim_failed_event(export_id: msg['args'][2], sidekiq_job_data: job_data)
    raise ClaimNotExportedException
  end

  private

  attr_accessor :events_service, :multiples_service
end
