require 'rails_helper'
RSpec.describe "create response", type: :request do
  let(:response_worker) { ::EtExporter::ExportResponseWorker }
  let(:test_ccd_client) { EtCcdClient::UiClient.new.tap {|c| c.login } }
  let(:default_headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  end

  include_context 'with stubbed ccd'

  before do
    stub_request(:get, "http://dummy.com/examplepdf").
      to_return(status: 200, body: File.new(File.absolute_path('../fixtures/chloe_goodwin.pdf', __dir__)), headers: { 'Content-Type' => 'application/pdf'})
  end

  let(:test_claim_export) do
    claim_worker = ::EtExporter::ExportClaimWorker
    build(:export, :for_claim).tap do |export|
      claim_worker.perform_async(export.as_json.to_json)
      claim_worker.drain
    end
  end

  it 'updates the claim in ccd' do
    # Arrange - Produce a claim to respond to and Produce the input JSON
    claim_export = test_claim_export
    ccd_claim_case = test_ccd_client.caseworker_search_latest_by_reference(claim_export.resource.reference, case_type_id: 'Manchester')
    export = build(:export, :for_response, response_attrs: { case_number: ccd_claim_case.dig('case_fields', 'ethosCaseReference') })
    example_response = export.resource

    # Act - Call the response worker as the application would
    response_worker.perform_async(export.as_json.to_json)
    response_worker.drain


    # Assert - Check with CCD (or fake CCD) to see what we sent by finding the test claim and looking for its files
    ccd_case = test_ccd_client.caseworker_search_latest_by_reference(claim_export.resource.reference, case_type_id: 'Manchester')
    ccd_documents = ccd_case.dig('case_fields', 'documentCollection')
    expect(ccd_documents).to \
      include \
        a_hash_including 'id' => nil,
      'value' => a_hash_including(
        'typeOfDocument' => 'ET3',
        'shortDescription' => "ET3 response from #{example_response.respondent.name}",
        'uploadedDocument' => a_hash_including(
          'document_url' => an_instance_of(String),
          'document_binary_url' => an_instance_of(String),
          'document_filename' => 'et3_atos_export.pdf'
        )
      )
  end

  it 'must not remove the existing file from the claim in ccd' do
    # Arrange - Produce a claim to respond to and Produce the input JSON
    claim_export = test_claim_export
    ccd_claim_case = test_ccd_client.caseworker_search_latest_by_reference(claim_export.resource.reference, case_type_id: 'Manchester')
    export = build(:export, :for_response, response_attrs: { case_number: ccd_claim_case.dig('case_fields', 'ethosCaseReference') })
    example_claimant = claim_export.resource.primary_claimant

    # Act - Call the response worker as the application would
    response_worker.perform_async(export.as_json.to_json)
    response_worker.drain


    # Assert - Check with CCD (or fake CCD) to see what we sent by finding the test claim and looking for its files
    ccd_case = test_ccd_client.caseworker_search_latest_by_reference(claim_export.resource.reference, case_type_id: 'Manchester')
    ccd_documents = ccd_case.dig('case_fields', 'documentCollection')
    expect(ccd_documents).to \
      include \
        a_hash_including 'id' => nil,
      'value' => a_hash_including(
        'typeOfDocument' => 'ET1',
        'uploadedDocument' => a_hash_including(
          'document_url' => an_instance_of(String),
          'document_binary_url' => an_instance_of(String),
          'document_filename' => 'et1_chloe_goodwin.pdf'
        )
      )
  end

end
