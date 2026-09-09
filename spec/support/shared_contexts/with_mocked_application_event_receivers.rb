shared_context 'with mocked application event receivers' do
  def application_first_export_completed_event
    job = ActiveJob::Base.queue_adapter.enqueued_jobs.detect do |j|
      j[:queue] == 'events' && j[:job] == EtCcdExport::TriggerEventJobProxyJob && j[:args].first == 'ClaimExportFeedbackReceived' && JSON.parse(j[:args].second)['state'] == 'complete'
    end
    JSON.parse(job[:args].second)
  end
end
