require 'json'
module EtCcdExport
  module Test
    module ExternalEventsMethods
      def external_events
        ExternalEvents.new
      end
    end
    class ExternalEvents
      include RSpec::Matchers
      def assert_claim_export_succeeded(export:, ccd_case:)
        jobs = Sidekiq::Worker.jobs.select { |j| j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' && j['args'].first['arguments'].first == 'ClaimExportSucceeded' }
        expect(jobs.length).to be 1
        parsed_job_data = JSON.parse(jobs.first['args'].first['arguments'][1])
        expect(parsed_job_data).to include 'export_id' => export.id
        expect(parsed_job_data['external_data']).to include 'case_id' => ccd_case['id'],
                                                            'case_reference' => ccd_case['case_fields']['ethosCaseReference'],
                                                            'case_type_id' => 'Manchester_Dev'

      end

      def assert_multiples_claim_export_succeeded(export:, ccd_case:)
        jobs = Sidekiq::Worker.jobs.select { |j| j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' && j['args'].first['arguments'].first == 'ClaimExportSucceeded' }
        expect(jobs.length).to be 1
        parsed_job_data = JSON.parse(jobs.first['args'].first['arguments'][1])
        expect(parsed_job_data).to include 'export_id' => export.id
        expect(parsed_job_data['external_data']).to include 'case_id' => ccd_case['id'],
                                                            'case_reference' => ccd_case['case_fields']['multipleReference'],
                                                            'case_type_id' => 'Manchester_Multiples_Dev'

      end

      def assert_claim_export_started(export:)
        jobs = Sidekiq::Worker.jobs.select do |j|
          j['queue'] == 'events' && j['wrapped'] == 'TriggerEventJob' &&
            j['args'].first['arguments'].first == 'ClaimExportFeedbackReceived' &&
            JSON.parse(j['args'].first['arguments'][1]) >= {'state' => 'in_progress', 'export_id' => export.id, 'percent_complete' => 0}
        end
        expect(jobs.length).to be 1
      end
    end
  end
end

RSpec.configure do |c|
  c.include ::EtCcdExport::Test::ExternalEventsMethods
end