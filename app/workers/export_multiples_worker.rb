class ExportMultiplesWorker
  include Sidekiq::Worker
  include AsyncApplicationEvents
  include ExportRetryControl
  self.exceptions_without_retry = [EtCcdClient::Exceptions::UnprocessableEntity].freeze

  attr_accessor :job_hash

  sidekiq_options queue: 'external_system_ccd_multiples'

  def perform(ccd_data, case_type_id, export_id, claimant_count, primary = false, service: ExportMultipleClaimsService.new)
    before_perform
    Sidekiq.redis do |r|
      data = service.export(ccd_data, case_type_id, sidekiq_job_data: job_hash, bid: bid, export_id: export_id, claimant_count: claimant_count)
      if primary
        r.lpush("BID-#{bid}-references", data.dig('case_data', 'ethosCaseReference'))
      else
        r.rpush("BID-#{bid}-references", data.dig('case_data', 'ethosCaseReference'))
      end
    end
  rescue Exception => ex
    send_subclaim_erroring_event(export_id: export_id, sidekiq_job_data: job_hash.except('class', 'args', 'queue'), exception: ex) unless ex.is_a?(PreventJobRetryingException)
    raise ex
  end

  sidekiq_retries_exhausted do |msg, ex|
    job_data = msg.except('args', 'class').merge(ex&.job_hash || {})
    new.send_subclaim_failed_event(export_id: msg['args'][2], sidekiq_job_data: job_data)
    raise ClaimNotExportedException
  end

end
