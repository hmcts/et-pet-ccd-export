class ExportClaimService
  include ClaimFiles

  def initialize(client_class: EtCcdClient::Client, disallow_file_extensions: Rails.application.config.ccd_disallowed_file_extensions)
    self.client_class = client_class
    self.disallow_file_extensions = disallow_file_extensions
  end

  def call(export, sidekiq_job_data:)
    do_export(export, sidekiq_job_data: sidekiq_job_data)
  end

  private

  attr_accessor :client_class, :disallow_file_extensions

  def do_export(export, sidekiq_job_data:)
    client_class.use do |client|
      case_type_id = export.dig('external_system', 'configurations').detect {|c| c['key'] == 'case_type_id'}['value']
      resp = client.caseworker_start_case_creation(case_type_id: case_type_id)
      event_token = resp['token']
      data = ClaimPresenter.present(export['resource'], event_token: event_token, files: files_data(client, export))
      client.caseworker_case_create(data, case_type_id: case_type_id)
    end
  end
end
