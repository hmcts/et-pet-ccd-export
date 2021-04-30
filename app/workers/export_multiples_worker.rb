class ExportMultiplesWorker
  include Sidekiq::Worker
  include ExportRetryControl
  self.exceptions_without_retry = [].freeze

  attr_accessor :job_hash

  sidekiq_options queue: 'external_system_ccd_multiples'

  def initialize(application_events_service: ApplicationEventsService, multiples_service: ExportMultipleClaimsService.new)
    self.events_service = application_events_service
    self.multiples_service = multiples_service
  end


  def perform(ccd_data, case_type_id, export_id, claimant_count, primary = false, send_request_id = false, extra_headers = {})
    before_perform
    Sidekiq.redis do |r|
      data, number = multiples_service.export ccd_data,
                                              case_type_id,
                                              sidekiq_job_data: job_hash,
                                              bid: bid,
                                              export_id: export_id,
                                              claimant_count: claimant_count,
                                              send_request_id: send_request_id,
                                              extra_headers: extra_headers
      if primary
        r.lpush("BID-#{bid}-references", data.dig('case_data', 'ethosCaseReference'))
      else
        r.rpush("BID-#{bid}-references", data.dig('case_data', 'ethosCaseReference'))
      end
      events_service.send_claim_export_multiples_progress_event sidekiq_job_data: job_hash, export_id: export_id, percent_complete: percent_complete_for(1 + number, claimant_count: claimant_count), case_id: data['id'], case_reference: data.dig('case_data', 'ethosCaseReference'), case_type_id: case_type_id
    end
  rescue Exception => ex
    events_service.send_subclaim_erroring_event(export_id: export_id, sidekiq_job_data: job_hash.except('class', 'args', 'queue'), exception: ex) unless ex.is_a?(PreventJobRetryingException)
    raise ex
  end

  sidekiq_retries_exhausted do |msg, ex|
    job_data = msg.except('args', 'class').merge(ex.try(:job_hash) || {})
    ApplicationEventsService.send_subclaim_failed_event(export_id: msg['args'][2], sidekiq_job_data: job_data)
    raise ClaimNotExportedException
  end

  private

  attr_accessor :events_service, :multiples_service

  def percent_complete_for(number, claimant_count:)
    (number * (100.0 / (claimant_count + 2))).to_i
  end
end
