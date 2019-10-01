module EtCcdExport
  module Test
    module DrainAllOurSidekiqJobs
      def drain_all_our_sidekiq_jobs
        while ::Sidekiq::Worker.jobs.select { |j| j['queue'] != 'events'}.any?
          worker_classes = ::Sidekiq::Worker.jobs.select { |j| j['queue'] != 'events'}.map { |job| job["class"] }.uniq

          worker_classes.each do |worker_class|
            ::Sidekiq::Testing.constantize(worker_class).drain
          end
        end
      end
    end
  end
end
RSpec.configure do |config|
  config.include ::EtCcdExport::Test::DrainAllOurSidekiqJobs
end