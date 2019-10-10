class ExportResponseService
  include ResponseFiles
  def initialize(client_class: EtCcdClient::Client, disallow_file_extensions: Rails.application.config.ccd_disallowed_file_extensions)
    self.client_class = client_class
    self.disallow_file_extensions = disallow_file_extensions
  end

  def call(export, sidekiq_job_data:)
    do_export(export)
  end

  private

  attr_accessor :client_class, :disallow_file_extensions

  def do_export(export)
    client_class.use do |client|
      case_type_id = export.dig('external_system', 'configurations').detect {|c| c['key'] == 'case_type_id'}['value']
      claim = client.caseworker_search_latest_by_ethos_case_reference(export.dig('resource', 'case_number'), case_type_id: case_type_id)
      raise ClaimNotFoundByCaseNumberException, "A response for claim with case_number #{export.dig('resource', 'case_number')} could not be processed as this case number does not exist" if claim.nil?
      resp = client.caseworker_start_upload_document(ctid: case_type_id, cid: claim['id'])
      event_token = resp['token']
      client.caseworker_update_case_documents(case_id: claim['id'], case_type_id: case_type_id, event_token: event_token, files: claim.dig('case_data', 'documentCollection') + files_data(client, export))
      claim
    end
  end
end
