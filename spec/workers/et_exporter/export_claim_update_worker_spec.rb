require 'rails_helper'
RSpec.describe ::EtExporter::ExportClaimUpdateWorker do
  subject(:worker) do
    described_class.new(application_events_service: fake_events_service, update_case_service: fake_update_case_service).tap do |w|
      w.job_hash = fake_job_hash
    end
  end

  let(:fake_job_hash) { { jid: 'fakejid' } }
  let(:fake_events_service) { class_spy(ApplicationEventsService) }
  let(:fake_update_case_service) { class_spy(UpdateLeadCaseService) }

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
        # Act - Call the worker expecting the special error
        worker.perform(example_export.as_json.to_json)

        # Assert - Make sure the service was not called
        expect(fake_events_service).to have_received(:send_claim_update_export_started_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash)
      end

      it 'informs the application events service of the process finishing if the service did not raise exception' do
        # Act - Call the worker expecting the special error
        worker.perform(example_export.as_json.to_json)

        # Assert - Make sure the service was not called
        expect(fake_events_service).to have_received(:send_claim_update_exported_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash, case_id: 'case id', case_reference: 'case reference', case_type_id: 'Manchester')
      end

      it 'calls the service twice if the service responds with a ::EtCcdClient::Exceptions::UnprocessableEntity' do
        # Arrange - change the fake job hash to look like sidekiq's 'job_retry' has had a previous error
        fake_job_hash['error_class'] = 'EtCcdClient::Exceptions::UnprocessableEntity'

        # Act - Call the worker expecting the special error
        begin
          worker.perform(example_export.as_json.to_json)
        rescue PreventJobRetryingException
          # Do nothing
        end

        # Assert - Make sure the service was called
        expect(fake_update_case_service).to have_received(:call)
      end

      it 'calls the update case service with the parsed json as first param and the fake job hash as sidekiq_job data' do
        # Act - Call the worker
        worker.perform(example_export.as_json.to_json)

        # Assert - make sure the singles service was called
        expect(fake_update_case_service).to have_received(:call).with(example_export.as_json.deep_stringify_keys, sidekiq_job_data: fake_job_hash)
      end

      it 'informs the application events service of an error' do
        # Arrange - make the service raise an error
        my_error = Class.new(RuntimeError)
        my_exception = my_error.new("Something went wrong")
        allow(fake_update_case_service).to receive(:call).and_raise(my_exception)

        # Act - Call the worker
        begin
          worker.perform(example_export.as_json.to_json)
        rescue my_error
          # Do nothing
        end

        # Assert - Make sure the fake events service was called correctly
        expect(fake_events_service).to have_received(:send_claim_erroring_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash, exception: my_exception)
      end

      it 're raises the error to mark it as failure and allow retrying' do
        # Arrange - make the service raise an error
        my_error = Class.new(RuntimeError)
        allow(fake_update_case_service).to receive(:call).and_raise(my_error, "Something went wrong")

        # Act - Call the worker
        work = -> { worker.perform(example_export.as_json.to_json) }

        # Assert - Make sure the fake events service was called correctly
        expect(work).to raise_error(my_error)
      end
    end
  end
end
