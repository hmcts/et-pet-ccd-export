require 'json'
module EtCcdExport
  module Test
    module ExternalEventsMethods
      def external_events
        ExternalEvents.new
      end
    end

    class ExternalEvents # rubocop:disable Metrics/ClassLength
      include RSpec::Matchers
      include RSpec::Rails::Matchers
      include RSpec::Mocks::ArgumentMatchers

      def has_published_claim_export_succeeded?(export:, ccd_case:)
        expect_event_to_have_been_published(
          'ClaimExportFeedbackReceived',
          description: 'Claim export succeeded event published',
          data: { 'state' => 'complete', 'export_id' => export.id },
          external_data: {
            'case_id' => ccd_case['id'],
            'case_reference' => ccd_case['case_fields']['ethosCaseReference'],
            'case_type_id' => 'Manchester'
          }
        )
      end

      def has_published_multiples_claim_export_succeeded?(export:, ccd_case:)
        expect_event_to_have_been_published(
          'ClaimExportFeedbackReceived',
          description: 'Multiples claim export succeeded event published',
          data: { 'export_id' => export.id, 'state' => 'complete', 'message' => 'Multiples claim exported' },
          external_data: {
            'case_id' => ccd_case['id'],
            'case_reference' => ccd_case['case_fields']['multipleReference'],
            'case_type_id' => 'Manchester_Multiples'
          }
        )
      end

      def has_published_claim_export_started?(export:)
        expect_event_to_have_been_published(
          'ClaimExportFeedbackReceived',
          description: 'Claim export started event published',
          data: { 'state' => 'in_progress', 'export_id' => export.id, 'percent_complete' => 0, 'message' => 'Claim export started' }
        )
      end

      def has_published_multiples_claim_export_started?(export:)
        expect_event_to_have_been_published(
          'ClaimExportFeedbackReceived',
          description: 'Multiples claim export started event published',
          data: { 'state' => 'in_progress', 'export_id' => export.id, 'percent_complete' => 0, 'message' => 'Multiples claim export started' }
        )
      end

      def has_published_claim_erroring?(export:)
        expect_event_to_have_been_published(
          'ClaimExportFeedbackReceived',
          description: 'Claim erroring event published',
          data: { 'state' => 'erroring', 'export_id' => export.id, 'percent_complete' => nil, 'message' => 'Claim erroring' }
        )
      end

      def has_published_multiples_claim_size_exceeded?(export:)
        expect_event_to_have_been_published(
          'ClaimExportFeedbackReceived',
          description: 'Multiples claim size exceeded event published',
          data: { 'state' => 'failed', 'export_id' => export.id, 'percent_complete' => 0, 'message' => 'Multiples claim size exceeded' }
        )
      end

      def has_published_sub_claim_erroring?(export:)
        expect_event_to_have_been_published(
          'ClaimExportFeedbackReceived',
          description: 'Sub-claim erroring event published',
          data: { 'state' => 'erroring', 'export_id' => export.id, 'percent_complete' => nil, 'message' => 'Claim erroring due to subclaim error' }
        )
      end

      def has_published_all_multiples_claim_export_progress?(export:, ccd_case:, sub_cases:) # rubocop:disable Lint/UnusedMethodArgument
        published_progresses = published_event_data('ClaimExportFeedbackReceived').filter_map do |data|
          next unless data['export_id'] == export.id
          next unless data['percent_complete'].to_i.positive?
          next unless ['Sub case exported', 'Multiples claim exported'].include?(data['message'])

          data['percent_complete']
        end
        expected_progress_increment = 100.0 / (1 + sub_cases.length)
        expected_progresses = (1..(sub_cases.length + 1)).map do |sub_case_number|
          (sub_case_number * expected_progress_increment).to_i
        end
        expect(published_progresses).to match_array expected_progresses
      end

      def has_published_response_export_succeeded?(export:, ccd_case:, case_reference:)
        expect_event_to_have_been_published(
          'ResponseExportFeedbackReceived',
          description: 'Response export succeeded event published',
          data: { 'state' => 'complete', 'export_id' => export.id },
          external_data: {
            'case_id' => ccd_case['id'],
            'case_reference' => case_reference,
            'case_type_id' => 'Manchester',
            'office' => 'Manchester'
          }
        )
      end

      def has_published_response_export_succeeded_without_claim?(export:, case_reference:)
        expect_event_to_have_been_published(
          'ResponseExportFeedbackReceived',
          description: 'Response export without claim succeeded event published',
          data: { 'state' => 'complete', 'export_id' => export.id },
          external_data: {
            'case_id' => nil,
            'case_reference' => case_reference,
            'case_type_id' => 'Manchester',
            'office' => nil
          }
        )
      end

      private

      def expect_event_to_have_been_published(event, description:, data:, external_data: nil)
        satisfy_condition = satisfy(description) do |json|
          parsed = JSON.parse(json)
          expect(parsed).to include(data)
          expect(parsed.fetch('external_data')).to include(external_data) if external_data
          true
        rescue JSON::ParserError, RSpec::Expectations::ExpectationNotMetError
          false
        end
        expect(EtCcdExport::TriggerEventJobProxyJob).to have_been_enqueued.with(event, satisfy_condition).on_queue('events').at_least(:once)
      end

      def published_event_data(event)
        ::ActiveJob::Base.queue_adapter.enqueued_jobs.filter_map do |job|
          next unless job[:job] == EtCcdExport::TriggerEventJobProxyJob
          next unless job[:queue] == 'events'
          next unless job[:args].first == event

          JSON.parse(job[:args].second)
        rescue JSON::ParserError
          nil
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include EtCcdExport::Test::ExternalEventsMethods
end
