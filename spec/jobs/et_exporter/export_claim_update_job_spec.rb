require 'rails_helper'
RSpec.describe EtExporter::ExportClaimUpdateJob do
  subject(:job) do
    described_class.new(example_export.as_json.to_json)
  end

  let(:fake_job_hash) { { jid: 'fakejid' } }
  let(:fake_events_service) { class_spy(EtCcdExport::ApplicationEventsService) }
  let(:fake_update_case_service) { class_spy(EtCcdExport::UpdateLeadCaseService) }

  before do
    stub_const('EtCcdExport::UpdateLeadCaseService', fake_update_case_service)
    stub_const('EtCcdExport::ApplicationEventsService', fake_events_service)
  end

  describe '#perform' do
    context 'with a single claim' do
      let(:example_export) do
        build :export,
              :for_claim,
              :update,
              claim_traits: [:update_only],
              claim_attrs: { number_of_acas_files: 5 },
              external_data: {
                case_id: 'case id',
                case_type_id: 'Manchester',
                case_reference: 'case reference'
              }
      end

      it 'informs the application events service of the process starting' do
        # Act - Call the job expecting the special error
        job.perform_now

        # Assert - Make sure the service was not called
        expected_job_hash = { executions: 1, jid: job.job_id, job_id: job.job_id, queue_name: 'default' }.stringify_keys
        expect(fake_events_service).to have_received(:send_claim_update_export_started_event).with(export_id: example_export.id, sidekiq_job_data: expected_job_hash, use_sidekiq: false)
      end

      it 'informs the application events service of the process finishing if the service did not raise exception' do
        # Act - Call the job expecting the special error
        job.perform_now

        # Assert - Make sure the service was not called
        expected_job_hash = { executions: 1, jid: job.job_id, job_id: job.job_id, queue_name: 'default' }.stringify_keys
        expect(fake_events_service).to have_received(:send_claim_update_exported_event).with(export_id: example_export.id, sidekiq_job_data: expected_job_hash, case_id: 'case id', case_reference: 'case reference', case_type_id: 'Manchester')
      end

      it 'calls the service twice if the service responds with a ::EtCcdClient::Exceptions::UnprocessableEntity' do
        # Arrange - change the fake job hash to look like sidekiq's 'job_retry' has had a previous error
        fake_job_hash['error_class'] = 'EtCcdClient::Exceptions::UnprocessableEntity'

        # Act - Call the job expecting the special error
        job.perform_now

        # Assert - Make sure the service was called
        expect(fake_update_case_service).to have_received(:call)
      end

      it 'calls the update case service with the parsed json as first param and the fake job hash as sidekiq_job data' do
        # Act - Call the job
        job.perform_now

        # Assert - make sure the singles service was called
        expected_job_hash = { executions: 1, jid: job.job_id, job_id: job.job_id, queue_name: 'default' }.stringify_keys
        expect(fake_update_case_service).to have_received(:call).with(example_export.as_json.deep_stringify_keys, sidekiq_job_data: expected_job_hash)
      end

      it 'informs the application events service of an error' do
        # Arrange - make the service raise an error
        my_error = Class.new(RuntimeError)
        my_exception = my_error.new("Something went wrong")
        allow(fake_update_case_service).to receive(:call).and_raise(my_exception)

        # Act - Call the job
        job.perform_now

        # Assert - Make sure the fake events service was called correctly
        expected_job_hash = { executions: 1, jid: job.job_id, job_id: job.job_id, queue_name: 'default' }.stringify_keys
        expect(fake_events_service).to have_received(:send_claim_erroring_event).with(export_id: example_export.id, sidekiq_job_data: expected_job_hash, exception: my_exception, use_sidekiq: false)
      end

      it 're raises the error to mark it as failure and allow retrying' do
        # Arrange - make the service raise an error
        my_error = Class.new(RuntimeError)
        allow(fake_update_case_service).to receive(:call).and_raise(my_error, "Something went wrong")

        # Assert - Make sure the fake events service was called correctly
        expect { job.perform(example_export.as_json.to_json) }.to raise_error(my_error)
      end
    end
  end
end
