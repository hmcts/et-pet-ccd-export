require 'rails_helper'

RSpec.describe EtExporter::ExportMultiplesWorkaroundJob do
  subject(:job) { described_class.new(uploaded_file_url, case_type_id) }

  let(:uploaded_file_url) { 'https://example.test/multiples.csv' }
  let(:case_type_id) { 'Manchester_Multiples' }
  let(:client) { instance_double(EtCcdClient::Client) }
  let(:raw_response) { instance_double(RestClient::RawResponse, file: csv_file) }
  let(:csv_file) do
    Tempfile.new.tap do |file|
      file.write <<~CSV
        First respondent,MULT/1,1800001/2026
        First respondent,MULT/1,1800002/2026
        Second respondent,MULT/2,1800003/2026
      CSV
      file.rewind
    end
  end

  before do
    allow(RestClient::Request).to receive(:execute).and_return(raw_response)
    allow(EtCcdClient::Client).to receive(:use).and_yield(client)
    allow(client).to receive(:caseworker_start_bulk_creation).
      and_return({ 'token' => 'first-token' }, { 'token' => 'second-token' })
    allow(client).to receive(:caseworker_case_create).
      and_return({ 'id' => 'first-id' }, { 'id' => 'second-id' })
  end

  after { csv_file.close! }

  describe '#perform' do
    it 'downloads the CSV without SSL verification' do
      job.perform_now

      expect(RestClient::Request).to have_received(:execute).
        with(method: :get, url: uploaded_file_url, raw_response: true, verify_ssl: false)
    end

    it 'creates one multiple case for each multiple reference in the CSV' do
      job.perform_now

      aggregate_failures 'validating each case' do
        expect(client).to have_received(:caseworker_start_bulk_creation).
          with(case_type_id: case_type_id).twice
        expect(client).to have_received(:caseworker_case_create).with(
          expected_payload(
            token: 'first-token',
            multiple_reference: 'MULT/1',
            multiple_name: 'First respondent',
            case_references: ['1800001/2026', '1800002/2026']
          ),
          case_type_id: case_type_id
        ).once
        expect(client).to have_received(:caseworker_case_create).with(
          expected_payload(
            token: 'second-token',
            multiple_reference: 'MULT/2',
            multiple_name: 'Second respondent',
            case_references: ['1800003/2026']
          ),
          case_type_id: case_type_id
        ).once
      end
    end
  end

  def expected_payload(token:, multiple_reference:, multiple_name:, case_references:)
    {
      data: {
        multipleReference: multiple_reference,
        multipleName: multiple_name,
        caseIdCollection: case_references.map do |case_reference|
          { id: nil, value: { ethos_CaseReference: case_reference } }
        end
      },
      event: { id: 'createMultiple', summary: '', description: '' },
      event_token: token,
      ignore_warning: false,
      draft_id: nil
    }.to_json
  end
end
