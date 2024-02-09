require 'rails_helper'
RSpec.describe "update claim" do
  subject(:worker) { ::EtExporter::ExportClaimUpdateWorker }

  let(:test_ccd_client) { EtCcdClient::UiClient.new.tap(&:login) }

  include_context 'with stubbed ccd'
  include_context 'with mocked application event receivers'

  before do
    stub_request(:get, "http://dummy.com/examplepdf").
      to_return(status: 200, body: File.new(File.absolute_path('../fixtures/chloe_goodwin.pdf', __dir__)), headers: { 'Content-Type' => 'application/pdf' })
    stub_request(:get, "http://dummy.com/examplecsv").
      to_return(status: 200, body: File.new(File.absolute_path('../fixtures/example.csv', __dir__)), headers: { 'Content-Type' => 'text/csv' })
  end

  context 'with single claim having been previously exported' do
    let!(:existing_export_data) do
      ::EtExporter::ExportClaimWorker.perform_async(build(:export, :for_claim).as_json.to_json)
      ::EtExporter::ExportClaimWorker.drain
      application_first_export_completed_event
    end

    it 'stores the extra documents' do
      # Arrange - Produce the input JSON
      export = build(:export,
                     :for_claim,
                     :update,
                     claim_traits: [:update_only],
                     claim_attrs: { number_of_acas_files: 5 },
                     external_data: existing_export_data['external_data'])

      # Act - Call the worker in the same way the application would (minus using redis)
      worker.perform_async(export.as_json.to_json)
      worker.drain

      # Assert - Check with CCD (or fake CCD) to see what we sent - then download the file and compare size
      ccd_case = test_ccd_client.caseworker_search_latest_by_ethos_case_reference(existing_export_data.dig('external_data', 'case_reference'), case_type_id: 'Manchester')
      expect(ccd_case.dig('case_fields', 'documentCollection').length).to be 7
    end

  end

  context 'with multiple claim having been previously exported' do
    let!(:existing_export_data) do
      ::EtExporter::ExportClaimWorker.perform_async build(
        :export,
        :for_claim,
        claim_traits: [:default_multiple_claimants]
      ).as_json.to_json
      drain_all_our_sidekiq_jobs
      application_first_export_completed_event
    end

    it 'stores the extra documents' do
      # Arrange - Produce the input JSON
      export = build(:export,
                     :for_claim,
                     :update,
                     claim_traits: [:update_only],
                     claim_attrs: { number_of_acas_files: 5 },
                     external_data: existing_export_data['external_data'])

      # Act - Call the worker in the same way the application would (minus using redis)
      worker.perform_async(export.as_json.to_json)
      worker.drain

      # Assert - Check with CCD (or fake CCD) to see what we sent - then download the file and compare size
      case_data      = test_ccd_client.caseworker_search_latest_by_multiple_reference \
        existing_export_data.dig('external_data', 'case_reference'),
        case_type_id: existing_export_data.dig('external_data', 'case_type_id')
      lead_reference = case_data.dig('case_fields', 'caseIdCollection').first.dig('value', 'ethos_CaseReference')
      ccd_case       = test_ccd_client.caseworker_search_latest_by_ethos_case_reference lead_reference,
                                                                                        case_type_id: 'Manchester'
      expect(ccd_case.dig('case_fields', 'documentCollection').length).to be 8
    end
  end
end
