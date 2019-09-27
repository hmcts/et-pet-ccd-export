class ExportMultiplesHeaderWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'external_system_ccd'

  def perform(primary_reference, respondent_name, case_references, case_type_id, service: ExportMultipleClaimsService.new)
    service.export_header(primary_reference, respondent_name, case_references, case_type_id)
  end
end
