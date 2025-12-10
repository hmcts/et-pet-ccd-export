require 'csv'
module EtExporter
  class ExportMultiplesWorkaroundWorker
    include Sidekiq::Worker

    def perform(uploaded_file_url, case_type_id)
      ::EtCcdClient::Client.use do |client|
        cases(uploaded_file_url).each_pair do |_multiple_ref, case_data|
          resp = client.caseworker_start_bulk_creation(case_type_id: case_type_id)
          event_token = resp['token']
          data = {
            data: case_data,
            event: { id: 'createMultiple', summary: '', description: '' },
            event_token: event_token,
            ignore_warning: false,
            draft_id: nil
          }
          result = client.caseworker_case_create(data.to_json, case_type_id: case_type_id)
          puts result
        end
      end
    end

    private

    def cases(uploaded_file_url)
      raw = RestClient::Request.execute method: :get, url: uploaded_file_url, raw_response: true, verify_ssl: false
      cases = {}
      CSV.foreach(raw.file.path, headers: false) do |row|

        respondent, multiple_ref, case_ref = row
        cases[multiple_ref] ||= { multipleReference: multiple_ref, multipleName: respondent, caseIdCollection: [] }
        cases[multiple_ref][:caseIdCollection] << {
          id: nil,
          value: {
            ethos_CaseReference: case_ref
          }
        }
      end
    end
  end
end
