require 'rails_helper'
RSpec.describe ExportMultiplesHeaderWorker do
  subject(:worker) do
    described_class.new(application_events_service: fake_events_service, service: fake_service).tap do |w|
      # The job_hash is normally populated by ExposeJobHashMiddleware
      w.job_hash = fake_job_hash
    end
  end
  let(:fake_job_hash) { {jid: 'fakejid'} }
  let(:example_export) { build(:export, :for_claim, claim_traits: [:default_multiple_claimants]) }
  let(:fake_service) { instance_spy(ExportMultipleClaimsService, export_header: {'id' => 'fake_id', 'case_type_id' => 'fake_case_type_id', 'case_data' => { 'multipleReference' => 'fake_reference'}}) }
  let(:fake_events_service) { class_spy(ApplicationEventsService) }

  it 'should inform the application events service of the process finishing if the service did not raise exception' do
    # Act - Call the worker expecting the special error
    worker.perform('primary_reference', 'respondent_name', ['case_ref1'], 'fake_case_type_id', example_export.id)

    # Assert - Make sure the service was not called
    expect(fake_events_service).to have_received(:send_multiples_claim_exported_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash, case_id: 'fake_id', case_reference: 'fake_reference', case_type_id: 'fake_case_type_id')
  end

  it 'calls the service with the correct args' do
    # Act - Call the worker expecting the special error
    worker.perform('primary_reference', 'respondent_name', ['case_ref1'], 'fake_case_type_id', example_export.id)

    # Assert - Make sure the service was not called
    expect(fake_service).to have_received(:export_header).with('primary_reference', 'respondent_name', ['case_ref1'], 'fake_case_type_id', example_export.id, sidekiq_job_data: fake_job_hash)
  end
end
