require 'rails_helper'
RSpec.describe EtExporter::ExportClaimJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.new(example_export.as_json.to_json) }

  let(:fake_job_hash) { job.job_hash }
  let(:fake_singles_service) { instance_spy(EtCcdExport::ExportClaimService, call: fake_singles_service_response) }
  let(:fake_singles_service_class) { class_double(EtCcdExport::ExportClaimService, new: fake_singles_service) }
  let(:fake_singles_service_response) { { 'id' => 'fake_id', 'case_type_id' => 'fake_case_type_id', 'case_data' => { 'ethosCaseReference' => 'fake_reference' } } }
  let(:fake_multiples_service) { instance_spy(EtCcdExport::ExportMultipleClaimsService, call: 'fake_bid') }
  let(:fake_multiples_service_class) { class_double(EtCcdExport::ExportMultipleClaimsService, new: fake_multiples_service) }
  let(:fake_events_service) { class_spy(EtCcdExport::ApplicationEventsService) }

  before do
    stub_const('EtCcdExport::ExportClaimService', fake_singles_service_class)
    stub_const('EtCcdExport::ExportMultipleClaimsService', fake_multiples_service_class)
    stub_const('EtCcdExport::ApplicationEventsService', fake_events_service)
  end

  describe "#perform" do
    context 'with single claim' do
      let(:example_export) { build(:export, :for_claim) }

      it 'informs the application events service of the process starting' do
        # Act - Call the worker expecting the special error
        job.perform_now

        # Assert - Make sure the service was not called
        expect(fake_events_service).to have_received(:send_claim_export_started_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash, use_sidekiq: false)
      end

      it 'informs the application events service of the process finishing if the service did not raise exception' do
        # Act - Call the worker expecting the special error
        job.perform_now

        # Assert - Make sure the service was not called
        expect(fake_events_service).to have_received(:send_claim_exported_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash, case_id: 'fake_id', case_reference: 'fake_reference', case_type_id: 'fake_case_type_id', use_sidekiq: false)
      end

      it 'calls the service twice if the service responds with a ::EtCcdClient::Exceptions::UnprocessableEntity' do
        # Act - Call the worker expecting the special error
        job.perform_now

        # Assert - Make sure the service was called
        expect(fake_singles_service).to have_received(:call)
      end

      it 'calls the single service with the parsed json as first param and the fake job hash as sidekiq_job_data' do
        # Act - Call the worker
        job.perform_now

        # Assert - make sure the singles service was called
        expect(fake_singles_service).to have_received(:call).with(example_export.as_json, sidekiq_job_data: fake_job_hash)
      end

      it 'informs the application events service of an error' do
        # Arrange - make the service raise an error
        stub_const('MyError', Class.new(RuntimeError))
        my_exception = MyError.new("Something went wrong")
        allow(fake_singles_service).to receive(:call).and_raise(my_exception)

        # Act - Call the worker
        job.perform_now

        # Assert - Make sure the fake events service was called correctly
        expected_job_hash = { executions: 1, jid: job.job_id, job_id: job.job_id, queue_name: 'default' }.stringify_keys
        expect(fake_events_service).to have_received(:send_claim_erroring_event).with(export_id: example_export.id, sidekiq_job_data: expected_job_hash, exception: my_exception, use_sidekiq: false)
      end

      it 're raises the error to mark it as failure and allow retrying' do
        # Arrange - make the service raise an error
        stub_const('MyError', Class.new(RuntimeError))
        allow(fake_singles_service).to receive(:call).and_raise(MyError, "Something went wrong")

        # Assert - Make sure the fake events service was called correctly
        expect { job.perform(example_export.as_json.to_json) }.to raise_error(MyError)
      end

    end

    context 'with multiple claims' do
      let(:example_export) { build(:export, :for_claim, claim_traits: [:default_multiple_claimants]) }

      it 'informs the application events service of the process starting' do
        # Act - Call the job expecting the special error
        job.perform_now

        # Assert - Make sure the service was not called
        expect(fake_events_service).to have_received(:send_multiples_claim_export_started_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash, use_sidekiq: false)
      end

      it 'informs the application events service of the process finishing if the service did not raise exception' do
        # Act - Call the job expecting the special error
        job.perform_now

        # Assert - Make sure the service was not called
        expect(fake_events_service).to have_received(:send_claim_export_multiples_queued_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash, queued_bid: instance_of(String), percent_complete: instance_of(Integer), use_sidekiq: false)
      end

      it 'calls the multiples service with the parsed json as first param and the fake job hash as sidekiq_job_data' do
        # Act - Call the job
        job.perform_now

        # Assert - make sure the singles service was called
        expect(fake_multiples_service).to have_received(:call).with(example_export.as_json, sidekiq_job_data: fake_job_hash)
      end

      it 'informs the application events service of an error' do
        # Arrange - make the service raise an error
        stub_const('MyError', Class.new(RuntimeError))
        my_exception = MyError.new("Something went wrong")
        allow(fake_multiples_service).to receive(:call).and_raise(MyError, my_exception)

        # Act - Call the job
        job.perform_now

        # Assert - Make sure the fake events service was called correctly
        expect(fake_events_service).to have_received(:send_multiples_claim_erroring_event).with(export_id: example_export.id, sidekiq_job_data: fake_job_hash, exception: instance_of(MyError), use_sidekiq: false)
      end
    end
  end

  describe "retries exhausted" do
    context 'with single claim' do
      let(:example_export) { build(:export, :for_claim) }

      it 'calls the send_claim_failed_event on the events service' do
        stub_const('MyError', Class.new(RuntimeError))
        allow(fake_singles_service).to receive(:call).
          and_raise(MyError, "Something went wrong")

        perform_enqueued_jobs do
          described_class.perform_later(example_export.as_json.to_json)
        rescue EtCcdExport::ApplicationException
          nil
        end

        aggregate_failures 'verify all expectations' do
          expect(fake_singles_service).to have_received(:call).at_least(2).times

          expect(fake_events_service).to have_received(:send_claim_failed_event).once
          expect(fake_events_service).to have_received(:send_claim_failed_event).with(
            export_id: example_export.id,
            sidekiq_job_data: hash_including('executions' => be >= 2, 'error_class' => 'MyError')
          )
        end
      end
    end
  end

  describe 'non retryable exception handling' do
    context 'with single claim' do
      let(:example_export) { build(:export, :for_claim) }

      it 'performs one execution if the exception is the special PreventJobRetrying exception' do
        allow(fake_singles_service).to receive(:call).
          and_raise(EtCcdExport::PreventJobRetryingException.new("Irrelevant message", {}))

        perform_enqueued_jobs do
          described_class.perform_later(example_export.as_json.to_json)
        rescue EtCcdExport::ApplicationException
          nil
        end

        aggregate_failures 'ensure only called once' do
          expect(fake_singles_service).to have_received(:call).once

          expect(fake_events_service).to have_received(:send_claim_failed_event).once
          expect(fake_events_service).to have_received(:send_claim_failed_event).with(
            export_id: example_export.id,
            sidekiq_job_data: hash_including('executions' => 1, 'error_class' => 'EtCcdExport::PreventJobRetryingException')
          )
        end
      end
    end
  end
end
