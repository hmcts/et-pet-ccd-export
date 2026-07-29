require 'rails_helper'
RSpec.describe EtCcdExport::ExportMultiplesHeaderJob do
  include ActiveJob::TestHelper

  subject(:job) do
    described_class.new(*fake_job_args)
  end

  let(:fake_job_hash) { { 'jid' => 'fakejid', 'args' => fake_job_args } }
  let(:fake_job_args) { ['primary_reference', 'respondent_name', ['case_ref1'], 'fake_case_type_id', example_export.id, true, { 'test_header' => 'true' }] }
  let(:example_export) { build(:export, :for_claim, claim_traits: [:default_multiple_claimants]) }
  let(:fake_service) { instance_spy(EtCcdExport::ExportMultipleClaimsService, export_header: { 'id' => 'fake_id', 'case_type_id' => 'fake_case_type_id', 'case_data' => { 'multipleReference' => 'fake_reference' } }) }
  let(:fake_service_class) { class_spy(EtCcdExport::ExportMultipleClaimsService, new: fake_service) }
  let(:fake_events_service) { class_spy(EtCcdExport::ApplicationEventsService) }

  before do
    stub_const 'EtCcdExport::ExportMultipleClaimsService', fake_service_class
    stub_const 'EtCcdExport::ApplicationEventsService', fake_events_service
  end

  it 'informs the application events service of the process finishing if the service did not raise exception' do
    # Act - Call the worker expecting the special error
    job.perform_now

    # Assert - Make sure the service was not called
    expected_job_hash = {
      executions: 1,
      jid: job.job_id,
      job_id: job.job_id,
      queue_name: 'external_system_ccd',
      args: fake_job_args
    }.stringify_keys
    expect(fake_events_service).to have_received(:send_multiples_claim_exported_event).with(export_id: example_export.id, sidekiq_job_data: expected_job_hash, case_id: 'fake_id', case_reference: 'fake_reference', case_type_id: 'fake_case_type_id', use_sidekiq: false)
  end

  it 'calls the service with the correct args' do
    # Act - Call the worker expecting the special error
    job.perform_now

    # Assert - Make sure the service was not called
    expected_job_hash = {
      executions: 1,
      jid: job.job_id,
      job_id: job.job_id,
      queue_name: 'external_system_ccd',
      args: fake_job_args
    }.stringify_keys
    expect(fake_service).to have_received(:export_header).
      with 'primary_reference',
           'respondent_name',
           ['case_ref1'],
           'fake_case_type_id',
           example_export.id,
           sidekiq_job_data: expected_job_hash,
           send_request_id: true,
           extra_headers: { 'test_header' => 'true' }
  end

  it 'sends a failure to the events system when retries exhausted' do
    exception_raised = false
    # Act - Call the retries exhausted block
    exception = RuntimeError.new('It is broken')
    allow(fake_service).to receive(:export_header).and_raise(exception)
    perform_enqueued_jobs do
      described_class.perform_later(*fake_job_args)
    rescue EtCcdExport::ClaimNotExportedException
      exception_raised = true
    end

    # Assert - Make sure the service was called
    expected_job_hash = {
      executions: be >= 2,
      jid: instance_of(String),
      job_id: instance_of(String),
      queue_name: 'external_system_ccd',
      args: fake_job_args,
      error_class: 'RuntimeError',
      error_message: 'It is broken'
    }.stringify_keys
    aggregate_failures 'validate event and exception raised' do
      expect(fake_events_service).to have_received(:send_claim_failed_event).with(export_id: example_export.id, sidekiq_job_data: expected_job_hash, use_sidekiq: false)
      expect(exception_raised).to be true
    end
  end
end
