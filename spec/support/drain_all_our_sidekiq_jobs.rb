module EtCcdExport
  module Test
    module DrainAllOurSidekiqJobs
      def drain_all_our_sidekiq_jobs(suppress_exceptions: false, move_failed_jobs_to_retry: false, exclude_queues: []) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        while ::Sidekiq::Worker.jobs.reject { |j| j['queue'] == 'events' || exclude_queues.include?(j['queue']) }.any?
          worker_classes = ::Sidekiq::Worker.jobs.reject { |j| j['queue'] == 'events' || exclude_queues.include?(j['queue']) }.map { |job| job["class"] }.uniq

          worker_classes.each do |worker_class|
            ::Sidekiq::Testing.constantize(worker_class).tap do |worker|
              while worker.jobs.any? { |job| !exclude_queues.include?(job["queue"]) }
                next_job = worker.jobs.find { |job| !exclude_queues.include?(job['queue']) }

                ::Sidekiq::Queues.delete_for(next_job["jid"], next_job["queue"], worker.to_s)
                begin
                  worker.process_job(next_job)
                rescue Exception => e
                  raise e unless suppress_exceptions

                  if move_failed_jobs_to_retry # rubocop:disable Metrics/BlockNesting
                    next_job['queue'] = 'retry'
                    next_job['error_message'] = e.message
                    next_job['error_class'] = e.class.to_s
                    if next_job["retry_count"] # rubocop:disable Metrics/BlockNesting
                      next_job["retried_at"] = Time.now.to_f
                      next_job["retry_count"] += 1
                    else
                      next_job["failed_at"] = Time.now.to_f
                      next_job["retry_count"] = 0
                    end
                    ::Sidekiq::Queues.push(next_job["queue"], worker.to_s, next_job)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
RSpec.configure do |config|
  config.include EtCcdExport::Test::DrainAllOurSidekiqJobs
end
