shared_context 'with mocked application event receivers' do
  def application_first_export_completed_event(use_sidekiq: true)
    if use_sidekiq
      job = Sidekiq::Queues.jobs_by_queue['events'].detect do |j|
        arguments = j['args'].first['arguments']
        arguments.first == 'ClaimExportFeedbackReceived' && JSON.parse(arguments.second)['state'] == 'complete'
      end
      JSON.parse(job['args'].first['arguments'].second)
    else
      job = ActiveJob::Base.queue_adapter.enqueued_jobs.detect do |j|
        j[:queue] == 'events' && j[:job] == EtCcdExport::TriggerEventJobProxyJob && j[:args].first == 'ClaimExportFeedbackReceived' && JSON.parse(j[:args].second)['state'] == 'complete'
      end
      JSON.parse(job[:args].second)
    end
  end
end
