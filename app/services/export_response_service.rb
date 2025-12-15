class ExportResponseService
  include ResponseFiles

  def initialize(client_class: EtCcdClient::Client, disallow_file_extensions: Rails.application.config.ccd_disallowed_file_extensions)
    self.client_class = client_class
    self.disallow_file_extensions = disallow_file_extensions
  end

  def call(export, sidekiq_job_data:) # rubocop:disable Lint/UnusedMethodArgument
    do_export(export)
  end

  private

  attr_accessor :client_class, :disallow_file_extensions

  def do_export(export)
    client_class.use do |client|
      case_type_id = export.dig('external_system', 'configurations').detect { |c| c['key'] == 'case_type_id' }['value']
      client.caseworker_search_latest_by_ethos_case_reference(export.dig('resource', 'case_number'), case_type_id: case_type_id)
    end
  end
end
