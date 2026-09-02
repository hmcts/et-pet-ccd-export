require 'rails_helper'
RSpec.describe EtCcdExport::ExportMultiplesJob do
  subject(:job) do
    described_class.new(example_ccd_data.as_json.to_json, 'Manchester', example_export.id, 1, false, true, { 'test_header' => 'true' })
  end

  let(:fake_job_hash) { { jid: 'fakejid' } }
  let(:example_export) { build(:export, :for_claim, claim_traits: [:default_multiple_claimants]) }
  let(:fake_service) { instance_spy(EtCcdExport::ExportMultipleClaimsService, export: [{ 'case_data' => { 'ethosCaseReference' => 'exampleEthosCaseReference' } }, 1]) }
  let(:fake_service_class) { class_spy(EtCcdExport::ExportMultipleClaimsService, new: fake_service) }
  let(:fake_events_service) { class_spy(EtCcdExport::ApplicationEventsService) }

  before do
    stub_const('EtCcdExport::ExportMultipleClaimsService', fake_service_class)
    stub_const('EtCcdExport::ApplicationEventsService', fake_events_service)
  end

  describe '#perform' do
    let(:example_ccd_data) { { ethosCaseReference: "exampleEthosCaseReference" } }
    let(:example_ccd_data_primary) { { ethosCaseReference: "exampleEthosCaseReferencePrimary" } }
    let(:batch) do
      EtCcdExport::Batch.start reference: example_ccd_data[:multipleReference],
                               quantity: 10,
                               start_ref: "24000001/#{Time.now.year}",
                               export_id: example_export.id,
                               case_type_id: 'fakecasetypeid'
    end

    it 'calls export with the correct args' do

      # Act - Call the worker
      job.perform_now

      # Assert - Make sure the service was called correctly
      expect(fake_service).to have_received(:export).
        with example_ccd_data.to_json,
             'Manchester',
             sidekiq_job_data: an_instance_of(Hash),
             send_request_id: true,
             extra_headers: { 'test_header' => 'true' }

    end

    context 'with sentry configured', :sentry do
      it 'adds sentry tags for the claim reference' do
        allow(fake_service).to receive(:call).and_raise(RuntimeError, "Something went wrong")
        perform_enqueued_jobs only: described_class do
          described_class.perform_later(example_export.as_json.to_json)
        rescue EtCcdExport::ClaimNotExportedException
          nil
        end
        aggregate_failures 'verify sentry events' do
          expect(sentry_events).not_to be_empty
          expect(sentry_events).to all(have_attributes(tags: hash_including(reference: instance_of(String))))
        end
      end
    end

  end
end
