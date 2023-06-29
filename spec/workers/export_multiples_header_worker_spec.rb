require 'rails_helper'
RSpec.describe ExportMultiplesHeaderWorker do
  subject(:worker) do
    described_class.new(application_events_service: fake_events_service, service: fake_service).tap do |w|
      # The job_hash is normally populated by ExposeJobHashMiddleware
      w.job_hash = fake_job_hash
    end
  end

  let(:fake_job_hash) { { 'jid' => 'fakejid', 'args' => fake_job_args } }
  let(:fake_job_args) { ['primary_reference', 'respondent_name', ['case_ref1'], 'fake_case_type_id', example_export.id, true, { 'test_header' => 'true' }] }
  let(:example_export) { build(:export, :for_claim, claim_traits: [:default_multiple_claimants]) }
  let(:fake_service) { instance_spy(ExportMultipleClaimsService, export_header: { 'id' => 'fake_id', 'case_type_id' => 'fake_case_type_id', 'case_data' => { 'multipleReference' => 'fake_reference' } }) }
  let(:fake_events_service) { class_spy(ApplicationEventsService) }

  it 'informs the application events service of the process finishing if the service did not raise exception' do
    # Act - Call the worker expecting the special error
    worker.perform(*fake_job_args)

    # Assert - Make sure the service was not called
    expect(fake_events_service).to have_received(:send_multiples_claim_exported_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash, case_id: 'fake_id', case_reference: 'fake_reference', case_type_id: 'fake_case_type_id')
  end

  it 'calls the service with the correct args' do
    # Act - Call the worker expecting the special error
    worker.perform(*fake_job_args)

    # Assert - Make sure the service was not called
    expect(fake_service).to have_received(:export_header).
      with 'primary_reference',
           'respondent_name',
           ['case_ref1'],
           'fake_case_type_id',
           example_export.id,
           sidekiq_job_data: fake_job_hash,
           send_request_id: true,
           extra_headers: { 'test_header' => 'true' }
  end

  it 'sends a failure to the events system when retries exhausted' do
    # Act - Call the retries exhausted block
    exception = RuntimeError.new('It is broken')
    block = worker&.sidekiq_retries_exhausted_block
    begin
      block&.call(fake_job_hash, exception, application_events_service: fake_events_service)
    rescue StandardError
      ClaimNotExportedException
    end

    # Assert - Make sure the service was called
    expect(fake_events_service).to have_received(:send_claim_failed_event).with(export_id: example_export.id, sidekiq_job_data: { 'jid' => 'fakejid' })
  end

  it 'raises a ClaimNotExportedException when retries exhausted' do
    exception = RuntimeError.new('It is broken')
    block = worker&.sidekiq_retries_exhausted_block

    # Assert - ensure the exception is raised
    expect { block&.call(fake_job_hash, exception, application_events_service: fake_events_service) }.to raise_exception ClaimNotExportedException
  end
end
