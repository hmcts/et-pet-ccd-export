require 'rails_helper'
RSpec.describe ExportMultiplesWorker do
  subject(:worker) do
    described_class.new(application_events_service: fake_events_service, multiples_service: fake_service).tap do |w|
      # The job_hash is normally populated by ExposeJobHashMiddleware
      w.job_hash = fake_job_hash
    end
  end
  let(:fake_job_hash) { {jid: 'fakejid'} }
  let(:example_export) { build(:export, :for_claim, claim_traits: [:default_multiple_claimants]) }
  let(:fake_service) { instance_spy(ExportMultipleClaimsService, export: [{'case_data' => {'ethosCaseReference' => 'exampleEthosCaseReference'}}, 1]) }
  let(:fake_events_service) { class_spy(ApplicationEventsService) }

  describe '#perform' do
    let(:example_ccd_data) { {"ethosCaseReference": "exampleEthosCaseReference"} }
    let(:example_ccd_data_primary) { {"ethosCaseReference": "exampleEthosCaseReferencePrimary"} }

    it 'should inform the application events service of the process finishing using a progress event if the service did not raise exception' do
      # Arrange - mock the output from the service
      batch = ::Sidekiq::Batch.new
      allow(fake_service).
        to receive(:export).
          with(example_ccd_data.to_json, anything, sidekiq_job_data: anything, bid: batch.bid, export_id: anything, claimant_count: anything).
          and_return([{'id' => 'fake_id', 'case_data' => {'ethosCaseReference' => 'exampleEthosCaseReference'}, 'case_type_id' => 'Manchester'}, 1])
      # Act - Call the worker expecting the special error
      batch.jobs do
        worker.perform(example_ccd_data.as_json.to_json, 'Manchester', example_export.id, 1)
      end

      # Assert - Make sure the service was not called
      expect(fake_events_service).to have_received(:send_claim_export_multiples_progress_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash, case_id: 'fake_id', case_reference: 'exampleEthosCaseReference', case_type_id: 'Manchester', percent_complete: instance_of(Integer))
    end

    it 'adds to the correct redis list when done' do
      # Arrange - mock the output from the service
      batch = ::Sidekiq::Batch.new
      allow(fake_service).
        to receive(:export).
          with(example_ccd_data.to_json, anything, sidekiq_job_data: anything, bid: batch.bid, export_id: example_export.id, claimant_count: anything).
          and_return([{'case_data' => {'ethosCaseReference' => 'exampleEthosCaseReference'}}, 1])

      # Act - Call the worker
      batch.jobs do
        worker.perform(example_ccd_data.to_json, 'Manchester', example_export.id, 1)
      end

      # Assert - Check in redis
      references = ::Sidekiq.redis { |r| r.lrange("BID-#{batch.bid}-references", 0, -1) }
      expect(references).to contain_exactly('exampleEthosCaseReference')
    end

    it 'stores the entry first in the list if primary flag is set' do
      # Arrange - Mock the response from the service for 1st and 2nd time - 1st is normal, second is primary
      batch = ::Sidekiq::Batch.new
      allow(fake_service).
        to receive(:export).
          with(example_ccd_data.to_json, anything, sidekiq_job_data: anything, bid: batch.bid, export_id: anything, claimant_count: anything).
          and_return([{'case_data' => {'ethosCaseReference' => 'exampleEthosCaseReference'}}, 1])
      allow(fake_service).
        to receive(:export).
          with(example_ccd_data_primary.to_json, anything, sidekiq_job_data: anything, bid: batch.bid, export_id: anything, claimant_count: anything).
          and_return([{'case_data' => {'ethosCaseReference' => 'exampleEthosCaseReferencePrimary'}}, 2])

      # Act - Call the worker
      batch.jobs do
        worker.perform(example_ccd_data.to_json, 'Manchester', example_export.id, 10)
        worker.perform(example_ccd_data_primary.to_json, 'Manchester', example_export.id, 10, true)
      end

      # Assert - Check in redis
      references = ::Sidekiq.redis { |r| r.lrange("BID-#{batch.bid}-references", 0, -1) }
      expect(references.first).to eql 'exampleEthosCaseReferencePrimary'
    end
  end
end
