shared_context 'with mocked application event receivers' do
  def application_first_export_completed_event
    job = ::Sidekiq::Queues.jobs_by_queue['events'].detect do |j|
      arguments = j['args'].first['arguments']
      arguments.first == 'ClaimExportFeedbackReceived' && JSON.parse(arguments.second)['state'] == 'complete'
    end
    JSON.parse(job['args'].first['arguments'].second)
  end
end
