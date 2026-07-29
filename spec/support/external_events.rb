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

      # These deliberately mirror the existing has_published...? test vocabulary.
      # rubocop:disable Naming/PredicatePrefix
      def assert_claim_export_succeeded(export:, ccd_case:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'complete', 'export_id' => export.id } &&
            JSON.parse(j['args'].first['arguments'][1])['external_data'] >= { 'case_id' => ccd_case['id'],
                                                                              'case_reference' => ccd_case['case_fields']['ethosCaseReference'],
                                                                              'case_type_id' => 'Manchester' }
        end
        expect(jobs.length).to be 1
      end

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

      def assert_multiples_claim_export_succeeded(export:, ccd_case:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'export_id' => export.id, 'state' => 'complete', 'message' => 'Multiples claim exported' } &&
            JSON.parse(j['args'].first['arguments'][1])['external_data'] >= { 'case_id' => ccd_case['id'],
                                                                              'case_reference' => ccd_case['case_fields']['multipleReference'],
                                                                              'case_type_id' => 'Manchester_Multiples' }
        end
        expect(jobs.length).to be 1
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

      def assert_claim_export_started(export:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'in_progress', 'export_id' => export.id, 'percent_complete' => 0, 'message' => 'Claim export started' }
        end
        expect(jobs.length).to be 1
      end

      def has_published_claim_export_started?(export:)
        expect_event_to_have_been_published(
          'ClaimExportFeedbackReceived',
          description: 'Claim export started event published',
          data: { 'state' => 'in_progress', 'export_id' => export.id, 'percent_complete' => 0, 'message' => 'Claim export started' }
        )
      end

      def assert_multiples_claim_export_started(export:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'in_progress', 'export_id' => export.id, 'percent_complete' => 0, 'message' => 'Multiples claim export started' }
        end
        expect(jobs.length).to be 1
      end

      def has_published_multiples_claim_export_started?(export:)
        expect_event_to_have_been_published(
          'ClaimExportFeedbackReceived',
          description: 'Multiples claim export started event published',
          data: { 'state' => 'in_progress', 'export_id' => export.id, 'percent_complete' => 0, 'message' => 'Multiples claim export started' }
        )
      end

      def assert_claim_erroring(export:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'erroring', 'export_id' => export.id, 'percent_complete' => nil, 'message' => 'Claim erroring' }
        end
        expect(jobs.length).to be 1
      end

      def has_published_claim_erroring?(export:)
        expect_event_to_have_been_published(
          'ClaimExportFeedbackReceived',
          description: 'Claim erroring event published',
          data: { 'state' => 'erroring', 'export_id' => export.id, 'percent_complete' => nil, 'message' => 'Claim erroring' }
        )
      end

      def assert_multiples_claim_size_exceeded(export:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'failed', 'export_id' => export.id, 'percent_complete' => 0, 'message' => 'Multiples claim size exceeded' }
        end
        expect(jobs.length).to be 1
      end

      def has_published_multiples_claim_size_exceeded?(export:)
        expect_event_to_have_been_published(
          'ClaimExportFeedbackReceived',
          description: 'Multiples claim size exceeded event published',
          data: { 'state' => 'failed', 'export_id' => export.id, 'percent_complete' => 0, 'message' => 'Multiples claim size exceeded' }
        )
      end

      def assert_sub_claim_erroring(export:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'erroring', 'export_id' => export.id, 'percent_complete' => nil, 'message' => 'Claim erroring due to subclaim error' }
        end
        expect(jobs.length).to be 1
      end

      def has_published_sub_claim_erroring?(export:)
        expect_event_to_have_been_published(
          'ClaimExportFeedbackReceived',
          description: 'Sub-claim erroring event published',
          data: { 'state' => 'erroring', 'export_id' => export.id, 'percent_complete' => nil, 'message' => 'Claim erroring due to subclaim error' }
        )
      end

      def assert_all_multiples_claim_export_progress(export:, ccd_case:, sub_cases:) # rubocop:disable Lint/UnusedMethodArgument
        # If we had a claim with 9 secondary claimants, giving 10 altogether - all together we would send 12 events
        # including the header.
        # The first would be the event that queues all 10 jobs and will contain the bid (batch id)
        # Therefore each sub claim should represent a percentage complete of (100 / 12) so after the 10th one is sent
        # the final 'complete' event will mark 100%
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'export_id' => export.id } &&
            JSON.parse(j['args'].first['arguments'][1])['percent_complete'] > 0 &&
            ['Sub case exported', 'Multiples claim exported'].include?(JSON.parse(j['args'].first['arguments'][1])['message'])
        end
        jobs_data = jobs.map do |j|
          JSON.parse(j['args'].first['arguments'][1])
        end
        expected_progress_increment = 100.0 / (1 + sub_cases.length)
        expected_progresses = (1..(sub_cases.length + 1)).map do |sub_case_number|
          (sub_case_number * expected_progress_increment).to_i
        end
        expect(jobs_data.map { |d| d['percent_complete'] }).to match_array expected_progresses
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

      def assert_response_export_succeeded(export:, ccd_case:, case_reference:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ResponseExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'complete', 'export_id' => export.id } &&
            JSON.parse(j['args'].first['arguments'][1])['external_data'] >= { 'case_id' => ccd_case['id'],
                                                                              'case_reference' => case_reference,
                                                                              'case_type_id' => 'Manchester',
                                                                              'office' => 'Manchester' }
        end
        expect(jobs.length).to be 1
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

      def assert_response_export_succeeded_without_claim(export:, case_reference:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ResponseExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'complete', 'export_id' => export.id } &&
            JSON.parse(j['args'].first['arguments'][1])['external_data'] >= { 'case_id' => nil,
                                                                              'case_reference' => case_reference,
                                                                              'case_type_id' => 'Manchester',
                                                                              'office' => nil }
        end
        expect(jobs.length).to be 1
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
      # rubocop:enable Naming/PredicatePrefix

      private

      def expect_event_to_have_been_published(event, description:, data:, external_data: nil)
        satisfy_condition = satisfy(description) do |json|
          parsed = JSON.parse(json)
          expect(parsed).to include(data)
          expect(parsed.fetch('external_data')).to include(external_data) if external_data
          true
        rescue JSON::ParserError, RSpec::Expectations::ExpectationNotMetError => e
          puts e.message
          false
        end
        expect(EtCcdExport::TriggerEventJobProxyJob).to have_been_enqueued.with(event, satisfy_condition).on_queue('events').at_least(:once)
        true
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
