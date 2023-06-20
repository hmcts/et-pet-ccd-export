require 'rails_helper'
RSpec.describe ExportClaimService do
  subject(:service) { described_class.new(disallow_file_extensions: []) }

  describe '#call' do
    let(:export) { create(:export, :for_claim) }
    let(:sidekiq_data) { { jid: 'xyz', bid: 'abc' } }

    include_context 'with stubbed ccd'

    before do
      stub_request(:get, "http://dummy.com/examplepdf").
        to_return(status: 200, body: File.new(File.absolute_path('../fixtures/chloe_goodwin.pdf', __dir__)), headers: { 'Content-Type' => 'application/pdf' })
      stub_request(:get, "http://dummy.com/examplecsv").
        to_return(status: 200, body: File.new(File.absolute_path('../fixtures/example.csv', __dir__)), headers: { 'Content-Type' => 'text/csv' })
    end

    it 'requests a token as it doesnt have one' do
      # service.call(export.as_json)
    end

    it 'only requests a token the first time'
    it 're requests another token if a request fails with a 401' do
      url = 'http://localhost:8080/data_store/caseworkers/650692bb-cefe-466a-ba8d-687377173064/jurisdictions/EMPLOYMENT/case-types/Manchester/event-triggers/initiateCase/token'

      stub_request(:get, url).
        to_return({ status: 401 }, { body: '{"token":"eyJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJvZDRwZ3NhbDQwcTdndHI0Y2F1bmVmZGU5aSIsInN1YiI6IjIyIiwiaWF0IjoxNTYxOTY2NzM1LCJldmVudC1pZCI6ImluaXRpYXRlQ2FzZSIsImNhc2UtdHlwZS1pZCI6IkVtcFRyaWJfTVZQXzEuMF9NYW5jIiwianVyaXNkaWN0aW9uLWlkIjoiRU1QTE9ZTUVOVCIsImNhc2UtdmVyc2lvbiI6ImJmMjFhOWU4ZmJjNWEzODQ2ZmIwNWI0ZmEwODU5ZTA5MTdiMjIwMmYifQ.u-OfexKFu52uvSgTNVHJ5kUQ9KTZGClRIRnGXRPSmGY","case_details":{"id":null,"jurisdiction":"EMPLOYMENT","state":null,"case_type_id":"Manchester","created_date":null,"last_modified":null,"security_classification":null,"case_data":{},"data_classification":{},"after_submit_callback_response":null,"callback_response_status_code":null,"callback_response_status":null,"delete_draft_response_status_code":null,"delete_draft_response_status":null,"security_classifications":{}},"event_id":"initiateCase"}' })
      service.call(export.as_json, sidekiq_job_data: sidekiq_data)
    end

    it 'performs a request to create a case with a valid token'
    it 'performs a request to create a case with valid primary claim data'
    it 'performs a request to create a case with valid primary claimant data'
    it 'performs a request to create a case with valid primary respondent data'
    it 'performs a request to create a case with valid primary representative data'
    it 'performs a request to create a case with valid pdf document'
    it 'returns a success when the service responds positively'
    it 'returns a failure when the service respondes negatively'

  end
end
