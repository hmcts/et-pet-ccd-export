# A service to update the lead case once it has been exported
#
# Note that this service is generic in that it can update anything, but for now it only
# supports adding files.  This is the only use case needed at the time of writing.
#
# Also note that the data given are the changes, but when we are specifying a collection,
#   we are asking the service to ADD those to the existing collection.  It can never delete or modify
#   inside the collection.
class UpdateLeadCaseService
  include ClaimFiles
  include CcdExtraHeaders

  def self.call(export, sidekiq_job_data:, client_class: EtCcdClient::Client, disallow_file_extensions: Rails.application.config.ccd_disallowed_file_extensions)
    client_class.use do |client|
      new(export, sidekiq_job_data: sidekiq_job_data, client: client, disallow_file_extensions: disallow_file_extensions).call

    end
  end

  # @private
  def initialize(export, sidekiq_job_data:, client:, disallow_file_extensions:)
    @export                   = export
    @sidekiq_job_data         = sidekiq_job_data
    @client                   = client
    @disallow_file_extensions = disallow_file_extensions
  end

  def call
    update_case lead_case
  end

  private

  def lead_case
    extra_headers = extra_headers_for(export, sidekiq_job_data['jid'])
    case_data     = client.caseworker_case original_case_id,
                                           case_type_id: original_case_type_id,
                                           extra_headers: extra_headers
    return case_data unless case_data.dig('case_data', 'multipleReference').present?

    lead_reference = case_data.dig('case_data', 'caseIdCollection').first.dig('value', 'ethos_CaseReference')
    client.caseworker_search_latest_by_ethos_case_reference lead_reference,
                                                            case_type_id: singles_case_type_id,
                                                            extra_headers: extra_headers
  end

  def update_case(case_wrapper)
    resp        = client.caseworker_start_upload_document(ctid: singles_case_type_id, cid: case_wrapper['id'])
    event_token = resp['token']
    files       = case_wrapper.dig('case_data', 'documentCollection') + converted_files
    client.caseworker_update_case_documents case_id: case_wrapper['id'],
                                            case_type_id: singles_case_type_id,
                                            event_token: event_token,
                                            files: files
  end

  def converted_files
    files_data(client, export).map do |file|
      {
        id: nil,
        value: {
          typeOfDocument: file['document_type'],
          uploadedDocument: {
            document_url: file['document_url'],
            document_binary_url: file['document_binary_url'],
            document_filename: file['document_filename']
          }
        }
      }
    end
  end

  def original_case_type_id
    export.dig('external_data', 'case_type_id')
  end

  def original_case_id
    export.dig('external_data', 'case_id')
  end

  def singles_case_type_id
    export.dig('external_system', 'configurations').detect { |entry| entry['key'] == 'case_type_id' }['value']
  end

  attr_reader :export, :sidekiq_job_data, :client, :disallow_file_extensions
end
