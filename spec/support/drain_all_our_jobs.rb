module EtCcdExport
  module Test
    module DrainAllOurJobs
      def drain_all_our_jobs(suppress_exceptions: false, move_failed_jobs_to_retry: false, exclude_queues: [])
        loop do
          break if perform_enqueued_jobs(except: [EtCcdExport::TriggerEventJobProxyJob]).zero?
        end
      end
    end
  end
end
RSpec.configure do |config|
  config.include EtCcdExport::Test::DrainAllOurJobs
end
