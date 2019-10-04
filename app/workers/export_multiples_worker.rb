class ExportMultiplesWorker
  include Sidekiq::Worker

  attr_accessor :job_hash

  sidekiq_options queue: 'external_system_ccd_multiples'

  def perform(ccd_data, case_type_id, export_id, claimant_count, primary = false, service: ExportMultipleClaimsService.new)
    Sidekiq.redis do |r|
      data = service.export(ccd_data, case_type_id, sidekiq_job_data: job_hash, bid: bid, export_id: export_id, claimant_count: claimant_count)
      if primary
        r.lpush("BID-#{bid}-references", data.dig('case_data', 'ethosCaseReference'))
      else
        r.rpush("BID-#{bid}-references", data.dig('case_data', 'ethosCaseReference'))
      end
    end
  end
end
