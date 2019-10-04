class ExportMultiplesHeaderWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'external_system_ccd'

  attr_accessor :job_hash

  def perform(primary_reference, respondent_name, case_references, case_type_id, export_id, service: ExportMultipleClaimsService.new)
    service.export_header(primary_reference, respondent_name, case_references, case_type_id, export_id, sidekiq_job_data: job_hash)
  end
end
