require 'rails_helper'
RSpec.describe ::EtExporter::ExportResponseWorker do
  let(:fake_job_hash) { {  jid: 'fakejid' } }
  let(:fake_service) { instance_spy(ExportResponseService, call: fake_case_data) }
  let(:fake_case_data) { {'case_type_id' => 'fake_case_type_id', 'id' => 'fake_id', 'case_data' => { 'ethosCaseReference' => 'fake_reference' }}  }
  let(:fake_events_service) { class_spy(ApplicationEventsService) }
  subject(:worker) do
    described_class.new(application_events_service: fake_events_service, service: fake_service).tap do |w|
      w.job_hash = fake_job_hash
    end
  end

  describe '#perform' do
    let(:example_export) { build(:export, :for_response) }

    it 'should not call the service twice if the service responds with a ::EtCcdClient::Exceptions::UnprocessableEntity' do
      # Arrange - change the fake job hash to look like sidekiq's 'job_retry' has had a previous error
      fake_job_hash['error_class'] = 'EtCcdClient::Exceptions::UnprocessableEntity'

      # Act - Call the worker expecting the special error
      worker.perform(example_export.as_json.to_json) rescue PreventJobRetryingException

      # Assert - Make sure the service was not called
      expect(fake_service).not_to have_received(:call)
    end

    it 'should call the service with the parsed json as first param and the fake job hash as sidekiq_job_data' do
      # Act - Call the worker
      worker.perform(example_export.as_json.to_json)

      # Assert - make sure the singles service was called
      expect(fake_service).to have_received(:call).with(example_export.as_json, sidekiq_job_data: fake_job_hash)
    end

    it 'should inform the application events service of the process starting' do
      # Act - Call the worker expecting the special error
      worker.perform(example_export.as_json.to_json)

      # Assert - Make sure the service was not called
      expect(fake_events_service).to have_received(:send_response_export_started_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash)
    end

    it 'should inform the application events service of the process finishing if the service did not raise exception' do
      # Act - Call the worker expecting the special error
      worker.perform(example_export.as_json.to_json)

      # Assert - Make sure the service was not called
      expect(fake_events_service).to have_received(:send_response_exported_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash, case_id: 'fake_id', case_reference: 'fake_reference', case_type_id: 'fake_case_type_id')
    end

    it 'informs the application events service of an error' do
      # Arrange - make the service raise an error
      MyError = Class.new(RuntimeError)
      expect(fake_service).to receive(:call).and_raise(MyError, "Something went wrong")

      # Act - Call the worker
      worker.perform(example_export.as_json.to_json) rescue MyError

      # Assert - Make sure the fake events service was called correctly
      expect(fake_events_service).to have_received(:send_response_erroring_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash)
    end

    it 're raises the error to mark it as failure and allow retrying' do
      # Arrange - make the service raise an error
      MyError = Class.new(RuntimeError)
      expect(fake_service).to receive(:call).and_raise(MyError, "Something went wrong")

      # Act - Call the worker
      work = -> { worker.perform(example_export.as_json.to_json) }

      # Assert - Make sure the fake events service was called correctly
      expect(work).to raise_error(MyError)
    end

  end

  describe "#sidekiq_retries_exhausted_block" do
    let(:example_export) { build(:export, :for_response) }
    before { stub_const('ApplicationEventsService', fake_events_service) }

    it 'calls the send_response_failed_event on the events service' do
      MyError = Class.new(RuntimeError)
      fake_job_hash['args'] = [example_export.as_json.to_json]
      worker.sidekiq_retries_exhausted_block.call(fake_job_hash, MyError.new('Something went wrong')) rescue ClaimNotExportedException

      expect(fake_events_service).to have_received(:send_response_failed_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash.except('args'))
    end
  end

  describe '#sidekiq_retry_in_block' do
    it 'returns 1 if the exception is the special PreventJobRetrying exception' do
      ex = PreventJobRetryingException.new "Irrelevant message", {}
      result = worker.sidekiq_retry_in_block.call(3, ex)
      expect(result).to be 1
    end
  end
end
