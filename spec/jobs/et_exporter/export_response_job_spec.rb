require 'rails_helper'
RSpec.describe EtExporter::ExportResponseJob do
  include ActiveJob::TestHelper

  subject(:job) do
    described_class.new(example_export.as_json.to_json)
  end

  let(:fake_job_hash) { { jid: 'fakejid' } }
  let(:fake_service) { instance_spy(EtCcdExport::ExportResponseService, call: fake_case_data) }
  let(:fake_service_class) { class_spy(EtCcdExport::ExportResponseService, new: fake_service) }
  let(:fake_case_data) { { 'case_type_id' => 'fake_case_type_id', 'id' => 'fake_id', 'case_data' => { 'ethosCaseReference' => 'fake_reference', 'managingOffice' => 'Bristol' } } }
  let(:fake_events_service) { class_spy(EtCcdExport::ApplicationEventsService) }

  before do
    stub_const('EtCcdExport::ApplicationEventsService', fake_events_service)
    stub_const('EtCcdExport::ExportResponseService', fake_service_class)
  end

  describe '#perform' do
    let(:example_export) { build(:export, :for_response) }

    it 'calls the service twice if the service responds with a ::EtCcdClient::Exceptions::UnprocessableEntity' do
      # Arrange - change the fake job hash to look like sidekiq's 'job_retry' has had a previous error
      fake_job_hash['error_class'] = 'EtCcdClient::Exceptions::UnprocessableEntity'

      # Act - Call the worker expecting the special error
      job.perform_now

      # Assert - Make sure the service was called
      expect(fake_service).to have_received(:call)
    end

    it 'calls the service with the parsed json as first param and the fake job hash as sidekiq_job_data' do
      # Act - Call the worker
      job.perform_now

      # Assert - make sure the singles service was called
      expected_job_hash = { executions: 1, jid: job.job_id, job_id: job.job_id, queue_name: 'default' }.stringify_keys
      expect(fake_service).to have_received(:call).with(example_export.as_json, sidekiq_job_data: expected_job_hash)
    end

    it 'informs the application events service of the process starting' do
      # Act - Call the worker expecting the special error
      job.perform_now

      # Assert - Make sure the service was not called
      expected_job_hash = { executions: 1, jid: job.job_id, job_id: job.job_id, queue_name: 'default' }.stringify_keys
      expect(fake_events_service).to have_received(:send_response_export_started_event).with(export_id: example_export.id, sidekiq_job_data: expected_job_hash)
    end

    it 'informs the application events service of the process finishing and the found office if the service did not raise exception' do
      # Act - Call the worker expecting the special error
      example_json = example_export.as_json
      job.perform_now

      # Assert - Make sure the service not called
      expected_case_type_id = example_json.dig('external_system', 'configurations').detect { |c| c['key'] == 'case_type_id' }['value']
      expected_job_hash = { executions: 1, jid: job.job_id, job_id: job.job_id, queue_name: 'default' }.stringify_keys
      expect(fake_events_service).to have_received(:send_response_exported_event).with(export_id: example_export.id, sidekiq_job_data: expected_job_hash, case_id: 'fake_id', case_reference: example_json.dig('resource', 'case_number'), case_type_id: expected_case_type_id, office: 'Bristol')
    end

    it 'informs the application events service of the process finishing and nil office if not found' do
      fake_case_data['case_data']['managingOffice'] = nil
      # Act - Call the worker expecting the special error
      example_json = example_export.as_json
      job.perform_now

      # Assert - Make sure the service was called
      expected_case_type_id = example_json.dig('external_system', 'configurations').detect { |c| c['key'] == 'case_type_id' }['value']
      expected_job_hash = { executions: 1, jid: job.job_id, job_id: job.job_id, queue_name: 'default' }.stringify_keys
      expect(fake_events_service).to have_received(:send_response_exported_event).with(export_id: example_export.id, sidekiq_job_data: expected_job_hash, case_id: 'fake_id', case_reference: example_json.dig('resource', 'case_number'), case_type_id: expected_case_type_id, office: nil)
    end

    it 'informs the application events service of an error' do
      # Arrange - make the service raise an error
      stub_const('MyError', Class.new(RuntimeError))
      my_exception = MyError.new("Something went wrong")
      allow(fake_service).to receive(:call).and_raise(my_exception)

      # Act - Call the worker
      job.perform_now

      # Assert - Make sure the fake events service was called correctly
      expected_job_hash = { executions: 1, jid: job.job_id, job_id: job.job_id, queue_name: 'default' }.stringify_keys
      expect(fake_events_service).to have_received(:send_response_erroring_event).with(export_id: example_export.id, sidekiq_job_data: expected_job_hash, exception: my_exception)
    end

    it 're raises the error to mark it as failure and allow retrying' do
      # Arrange - make the service raise an error
      stub_const('MyError', Class.new(RuntimeError))
      allow(fake_service).to receive(:call).and_raise(MyError, "Something went wrong")

      # Assert - Make sure the fake events service was called correctly
      expect { job.perform(example_export.as_json.to_json) }.to raise_error(MyError)
    end
  end

  describe "retries exhausted" do
    let(:example_export) { build(:export, :for_response) }

    before { stub_const('ApplicationEventsService', fake_events_service) }

    it 'calls the send_response_failed_event on the events service' do
      exception_raised = false
      stub_const('MyError', Class.new(RuntimeError))
      allow(fake_service).to receive(:call).and_raise(MyError, 'Something went wrong')
      perform_enqueued_jobs do
        described_class.perform_later(example_export.as_json.to_json)
      rescue EtCcdExport::ClaimNotExportedException
        exception_raised = true
      end

      expected_job_hash = {
        executions: be >= 2,
        jid: instance_of(String),
        job_id: instance_of(String),
        queue_name: 'default',
        error_class: 'MyError',
        error_message: 'Something went wrong'
      }.stringify_keys
      aggregate_failures 'verify event and exception' do
        expect(fake_events_service).to have_received(:send_response_failed_event).with(export_id: example_export.id, sidekiq_job_data: expected_job_hash)
        expect(exception_raised).to be true
      end
    end
  end

  describe 'non retryable exception handling' do
    let(:example_export) { build(:export, :for_response) }

    it 'performs one execution if the exception is the special PreventJobRetrying exception' do
      exception_raised = false
      allow(fake_service).to receive(:call).
        and_raise(EtCcdExport::PreventJobRetryingException.new("Irrelevant message", {}))

      perform_enqueued_jobs do
        described_class.perform_later(example_export.as_json.to_json)
      rescue EtCcdExport::ClaimNotExportedException
        exception_raised = true
      end

      aggregate_failures 'ensure only called once' do
        expect(fake_service).to have_received(:call).once

        expect(fake_events_service).to have_received(:send_response_failed_event).once
        expect(fake_events_service).to have_received(:send_response_failed_event).with(
          export_id: example_export.id,
          sidekiq_job_data: hash_including('executions' => 1, 'error_class' => 'EtCcdExport::PreventJobRetryingException')
        )
        expect(exception_raised).to be true
      end
    end
  end
end
