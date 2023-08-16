require 'rails_helper'
RSpec.describe "create response", type: :request do
  let(:response_worker) { ::EtExporter::ExportResponseWorker }
  let(:test_ccd_client) { EtCcdClient::UiClient.new.tap(&:login) }
  let(:default_headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  end

  include_context 'with stubbed ccd'

  before do
    stub_request(:get, "http://dummy.com/examplepdf").
      to_return(status: 200, body: File.new(File.absolute_path('../fixtures/chloe_goodwin.pdf', __dir__)), headers: { 'Content-Type' => 'application/pdf' })
  end

  def create_reformed_claim_in_ccd(office_code:, case_type_id:)
    resp = test_ccd_client.caseworker_start_case_creation(case_type_id: case_type_id, extra_headers: {})
    data = {
      data: {
        receiptDate: '2023-01-01',
        caseSource: 'ET1 Online',
        feeGroupReference: "#{office_code}1234567890",
        managingOffice: "Manchester",
        claimant_TypeOfClaimant: 'Individual',
        positionType: 'Received by Auto-Import',
        claimantIndType: {
          claimant_title1: 'Mr',
          claimant_first_names: 'John',
          claimant_last_name: 'Smith',
          claimant_date_of_birth: '1980-01-01',
          claimant_gender: nil
        },
        claimantType: {
          claimant_addressUK: {
            AddressLine1: '1 High Street',
            AddressLine2: 'Bla',
            PostTown: 'London',
            County: 'London',
            Country: nil,
            PostCode: 'SW1A 1AA'
          },
          claimant_phone_number: '01234567890',
          claimant_mobile_number: '01234567890',
          claimant_email_address: 'test@test.com',
          claimant_contact_preference: 'Email'
        },
        caseType: 'Single',
        claimantWorkAddress: {
          claimant_work_address: {
            AddressLine1: '1 High Street',
            AddressLine2: 'Bla',
            PostTown: 'London',
            County: 'London',
            Country: nil,
            PostCode: 'SW1A 1AA'
          },
          claimant_work_phone_number: '01234567890'
        },
        respondentCollection: [],
        claimantOtherType: {
          claimant_disabled: 'No'
        },
        claimantRepresentedQuestion: 'No',
        documentCollection: []
      },
      event: {
        id: 'initiateCase',
        summary: '',
        description: ''
      },
      event_token: resp['token'],
      ignore_warning: false,
      draft_id: nil
    }

    test_ccd_client.caseworker_case_create(data.to_json, case_type_id: case_type_id, extra_headers: {})
  end

  it 'informs the application that it is complete with the office from the case' do
    # Arrange - Produce a claim to respond to and Produce the input JSON (Note: it doesnt matter that the case_type_id is not the special 60 or 80 office)
    ccd_claim_case = create_reformed_claim_in_ccd(office_code: '60', case_type_id: 'Manchester')
    export = build(:export, :for_response, response_attrs: { case_number: ccd_claim_case.dig('case_fields', 'ethosCaseReference') })

    # Act - Call the response worker as the application would
    response_worker.perform_async(export.as_json.to_json)
    response_worker.drain

    # Assert - Check to ensure the data has been sent back to the application
    external_events.assert_response_export_succeeded(export: export, ccd_case: ccd_claim_case, case_reference: export.resource.case_number)
  end

  it 'informs the application that it is complete with no office if the case is not found' do
    export = build(:export, :for_response)

    # Act - Call the response worker as the application would
    response_worker.perform_async(export.as_json.to_json)
    response_worker.drain

    # Assert - Check to ensure the data has been sent back to the application
    external_events.assert_response_export_succeeded_without_claim(export: export, case_reference: export.resource.case_number)
  end
end
