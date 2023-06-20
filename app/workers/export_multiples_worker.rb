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

  def perform(ccd_data, case_type_id, export_id, claimant_count, _primary = false, send_request_id = false, extra_headers = {})
    Sentry.with_scope do |scope|
      scope.set_tags reference: JSON.parse(ccd_data)['feeGroupReference']
      before_perform
      multiples_service.export ccd_data,
                               case_type_id,
                               sidekiq_job_data: job_hash,
                               export_id: export_id,
                               claimant_count: claimant_count,
                               send_request_id: send_request_id,
                               extra_headers: extra_headers
    end
  end

  def tag_sentry(job, scope:)
    scope.set_tags reference: JSON.parse(job['args'].first)['feeGroupReference']
  end

  private

  attr_accessor :events_service, :multiples_service
end
