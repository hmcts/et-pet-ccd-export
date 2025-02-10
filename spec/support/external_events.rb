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

      def assert_claim_export_started(export:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'in_progress', 'export_id' => export.id, 'percent_complete' => 0, 'message' => 'Claim export started' }
        end
        expect(jobs.length).to be 1
      end

      def assert_multiples_claim_export_started(export:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'in_progress', 'export_id' => export.id, 'percent_complete' => 0, 'message' => 'Multiples claim export started' }
        end
        expect(jobs.length).to be 1
      end

      def assert_claim_erroring(export:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'erroring', 'export_id' => export.id, 'percent_complete' => nil, 'message' => 'Claim erroring' }
        end
        expect(jobs.length).to be 1
      end

      def assert_multiples_claim_size_exceeded(export:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'failed', 'export_id' => export.id, 'percent_complete' => 0, 'message' => 'Multiples claim size exceeded' }
        end
        expect(jobs.length).to be 1
      end

      def assert_sub_claim_erroring(export:)
        jobs = ::Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= { 'state' => 'erroring', 'export_id' => export.id, 'percent_complete' => nil, 'message' => 'Claim erroring due to subclaim error' }
        end
        expect(jobs.length).to be 1
      end

      def assert_all_multiples_claim_export_progress(export:, ccd_case:, sub_cases:) # rubocop:disable Lint/UnusedMethodArgument, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
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
    end
  end
end

RSpec.configure do |c|
  c.include EtCcdExport::Test::ExternalEventsMethods
end
