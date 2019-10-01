require 'rails_helper'
RSpec.describe "create claim" do
  subject(:worker) { ::EtExporter::ExportClaimWorker }
  let(:test_ccd_client) { EtCcdClient::UiClient.new.tap { |c| c.login } }
  include_context 'with stubbed ccd'

  before do
    stub_request(:get, "http://dummy.com/examplepdf").
      to_return(status: 200, body: File.new(File.absolute_path('../fixtures/chloe_goodwin.pdf', __dir__)), headers: {'Content-Type' => 'application/pdf'})
  end

  it 'creates a claim in ccd' do
    # Arrange - Produce the input JSON
    export = build(:export, :for_claim)

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    worker.drain

    # Assert - Check with CCD (or fake CCD) to see what we sent
    ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
    expect(ccd_case['case_fields']).to include 'feeGroupReference' => export.resource.reference
  end

  it 'creates a claim in ccd that matches the schema' do
    # Arrange - Produce the input JSON
    export = build(:export, :for_claim)

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    worker.drain

    # Assert - Check with CCD (or fake CCD) to see what we sent
    ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
    expect(ccd_case['case_fields']).to match_json_schema('case_create')
  end

  it 'raises an API event to inform of start of case creation' do
    # Arrange - Produce the input JSON
    export = build(:export, :for_claim)

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    worker.drain

    # Assert - Check for API event being received
    ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
    external_events.assert_claim_export_started(export: export)
  end

  it 'raises an API event to inform of case creation complete' do
    # Arrange - Produce the input JSON
    export = build(:export, :for_claim)

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    worker.drain

    # Assert - Check for API event being received
    ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
    external_events.assert_claim_export_succeeded(export: export, ccd_case: ccd_case)
  end

  it 'populates the claimant data correctly with an address specifying UK country' do
    # Arrange - Produce the input JSON
    claimant = build(:claimant, :default, address: build(:address, :with_uk_country))
    export = build(:export, :for_claim, resource: build(:claim, :default, primary_claimant: claimant))

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    worker.drain

    # Assert - Check with CCD (or fake CCD) to see what we sent
    ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
    ccd_claimant = ccd_case.dig('case_fields', 'claimantType')
    expect(ccd_claimant).to include "claimant_phone_number" => claimant.address_telephone_number,
                                    "claimant_mobile_number" => claimant.mobile_number,
                                    "claimant_email_address" => claimant.email_address,
                                    "claimant_contact_preference" => claimant.contact_preference.titleize,
                                    "claimant_addressUK" => {
                                      "AddressLine1" => claimant.address.building,
                                      "AddressLine2" => claimant.address.street,
                                      "PostTown" => claimant.address.locality,
                                      "County" => claimant.address.county,
                                      "PostCode" => claimant.address.post_code,
                                      "Country" => claimant.address.country
                                    }
  end

  it 'populates the claimant data correctly with an address specifying Non UK country (country should be nil)' do
    # Arrange - Produce the input JSON
    claimant = build(:claimant, :default, address: build(:address, :with_other_country))
    export = build(:export, :for_claim, resource: build(:claim, :default, primary_claimant: claimant))

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    worker.drain

    # Assert - Check with CCD (or fake CCD) to see what we sent
    ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
    ccd_claimant = ccd_case.dig('case_fields', 'claimantType')
    expect(ccd_claimant).to include "claimant_phone_number" => claimant.address_telephone_number,
                                    "claimant_mobile_number" => claimant.mobile_number,
                                    "claimant_email_address" => claimant.email_address,
                                    "claimant_contact_preference" => claimant.contact_preference.titleize,
                                    "claimant_addressUK" => {
                                      "AddressLine1" => claimant.address.building,
                                      "AddressLine2" => claimant.address.street,
                                      "PostTown" => claimant.address.locality,
                                      "County" => claimant.address.county,
                                      "PostCode" => claimant.address.post_code,
                                      "Country" => nil
                                    }
  end

  it 'populates the claimant data correctly with an address without any country in the input data (backward compatibility)' do
    # Arrange - Produce the input JSON
    claimant = build(:claimant, :default, address: build(:address))
    export = build(:export, :for_claim, resource: build(:claim, :default, primary_claimant: claimant))

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    worker.drain

    # Assert - Check with CCD (or fake CCD) to see what we sent
    ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
    ccd_claimant = ccd_case.dig('case_fields', 'claimantType')
    expect(ccd_claimant).to include "claimant_phone_number" => claimant.address_telephone_number,
                                    "claimant_mobile_number" => claimant.mobile_number,
                                    "claimant_email_address" => claimant.email_address,
                                    "claimant_contact_preference" => claimant.contact_preference.titleize,
                                    "claimant_addressUK" => {
                                      "AddressLine1" => claimant.address.building,
                                      "AddressLine2" => claimant.address.street,
                                      "PostTown" => claimant.address.locality,
                                      "County" => claimant.address.county,
                                      "PostCode" => claimant.address.post_code,
                                      "Country" => nil
                                    }
  end

  it 'populates the documents collection correctly with a single pdf file input' do
    # Arrange - Produce the input JSON
    export = build(:export, :for_claim)
    claimant = export.dig('resource', 'primary_claimant')

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    worker.drain

    # Assert - Check with CCD (or fake CCD) to see what we sent
    ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
    ccd_documents = ccd_case.dig('case_fields', 'documentCollection')
    expect(ccd_documents).to \
      contain_exactly \
        a_hash_including 'id' => nil,
                         'value' => a_hash_including(
                           'typeOfDocument' => 'Application',
                           'shortDescription' => "ET1 application for #{claimant.first_name} #{claimant.last_name}",
                           'uploadedDocument' => a_hash_including(
                             'document_url' => an_instance_of(String),
                             'document_binary_url' => an_instance_of(String),
                             'document_filename' => 'et1_chloe_goodwin.pdf'
                           )
                         )
  end

  it 'populates the documents collection correctly with some extra un wanted files in the input' do
    # Arrange - Produce the input JSON
    claim = build(:claim, :default, :with_unwanted_claim_file)
    export = build(:export, :for_claim, resource: claim)

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    worker.drain

    # Assert - Check with CCD (or fake CCD) to see what we sent
    ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
    ccd_documents = ccd_case.dig('case_fields', 'documentCollection')
    expect(ccd_documents).to \
      contain_exactly \
        a_hash_including 'id' => nil,
                         'value' => a_hash_including(
                           'typeOfDocument' => 'Application',
                           'uploadedDocument' => a_hash_including(
                             'document_filename' => 'et1_chloe_goodwin.pdf'
                           )
                         )

  end

  it 'stores the document correctly with a single pdf file input' do
    # Arrange - Produce the input JSON
    claim = build(:claim, :default, :with_unwanted_claim_file)
    export = build(:export, :for_claim, resource: claim)

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    worker.drain

    # Assert - Check with CCD (or fake CCD) to see what we sent - then download the file and compare size
    ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
    url = ccd_case.dig('case_fields', 'documentCollection').first.dig('value', 'uploadedDocument', 'document_binary_url')
    raw = RestClient::Request.execute method: :get, url: url, raw_response: true, verify_ssl: false
    expect(File.size(raw.file.path)).to eql File.size(File.absolute_path('../fixtures/chloe_goodwin.pdf', __dir__))
  end
end
