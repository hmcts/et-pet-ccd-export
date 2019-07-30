class ExportClaimService
  def initialize(client_class: EtCcdClient::Client)
    self.client_class = client_class
  end

  def call(export)
    do_export(export)
  end

  private

  attr_accessor :client_class

  def do_export(export)
    client_class.use do |client|
      case_type_id = export.dig('external_system', 'configurations').detect {|c| c['key'] == 'case_type_id'}['value']
      resp = client.caseworker_start_case_creation(case_type_id: case_type_id)
      event_token = resp['token']
      data = ClaimPresenter.present(export['resource'], event_token: event_token, files: files_data(client, export))
      client.caseworker_case_create(data, case_type_id: case_type_id)
    end
  end

  def files_data(client, export)
    files_of_interest(export).map do |f|
      json = client.upload_file_from_url(f['url'], content_type: f['content_type'])
      {
        'document_type' => application_file?(f) ? 'Application' : 'Other',
        'short_description' => short_description_for(f, export: export),
        'document_url' => json.dig('_embedded', 'documents').first.dig('_links', 'self', 'href'),
        'document_binary_url' => json.dig('_embedded', 'documents').first.dig('_links', 'binary', 'href'),
        'document_filename' => json.dig('_embedded', 'documents').first.dig('originalDocumentName')
      }
    end
  end

  def files_of_interest(export)
    export.dig('resource', 'uploaded_files').select do |file|
      file['filename'].match? /\Aet1_.*\.pdf\z|\.rtf\z|\.csv/
    end
  end

  def application_file?(file)
    file['filename'].match? /\Aet1_.*\.pdf\z/
  end

  def short_description_for(file, export:)
    claimant = export.dig('resource', 'primary_claimant')
    if application_file?(file)
      "ET1 application for #{claimant['first_name']} #{claimant['last_name']}"
    elsif claimants_file?(file)
      "Additional claimants file for #{claimant['first_name']} #{claimant['last_name']}"
    elsif additional_info_file?(file)
      "Additional information file for #{claimant['first_name']} #{claimant['last_name']}"
    else
      "Unknown"
    end
  end
end
