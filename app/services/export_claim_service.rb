class ExportClaimService
  include ClaimFiles
  include GenerateEthosCaseReference
  include AsyncApplicationEvents
  EXCEPTIONS_WITHOUT_RETRY=[EtCcdClient::Exceptions::UnprocessableEntity].freeze

  def initialize(client_class: EtCcdClient::Client, disallow_file_extensions: Rails.application.config.ccd_disallowed_file_extensions)
    self.client_class = client_class
    self.disallow_file_extensions = disallow_file_extensions
  end

  def call(export, sidekiq_job_data:)
    do_export(export, sidekiq_job_data: sidekiq_job_data)
  end

  def prevent_retry?(ex)
    EXCEPTIONS_WITHOUT_RETRY.include?(ex.class)
  end

  private

  attr_accessor :client_class, :disallow_file_extensions

  def do_export(export, sidekiq_job_data:)
    send_claim_export_started_event(export_id: export['id'], sidekiq_job_data: sidekiq_job_data)
    client_class.use do |client|
      case_type_id = export.dig('external_system', 'configurations').detect {|c| c['key'] == 'case_type_id'}['value']
      resp = client.caseworker_start_case_creation(case_type_id: case_type_id)
      event_token = resp['token']
      data = ClaimPresenter.present(export['resource'], event_token: event_token, files: files_data(client, export), ethos_case_reference: ethos_case_reference(export.dig('resource', 'office_code')))
      created_case = client.caseworker_case_create(data, case_type_id: case_type_id)
      send_claim_exported_event(export_id: export['id'], sidekiq_job_data: sidekiq_job_data, case_id: created_case['id'], case_reference: created_case.dig('case_data', 'ethosCaseReference'), case_type_id: case_type_id)
    end
  rescue Exception => ex
    send_claim_erroring_event(export_id: export['id'], sidekiq_job_data: sidekiq_job_data) unless prevent_retry?(ex)
    raise ex
  end
end
