module AsyncApplicationEvents
  def send_application_event(event, data, queue: 'default')
    serialized_job = {
      "job_class"  => 'TriggerEventJob',
      "job_id"     => SecureRandom.uuid,
      "provider_job_id" => nil,
      "queue_name" => queue,
      "priority"   => 5,
      "arguments"  => [ event, data.to_json ],
      "executions" => 0,
      "exception_executions" => 0,
      "locale"     => 'en',
      "timezone"   => Time.zone.try(:name),
      "enqueued_at" => Time.now.utc.iso8601
    }
    Sidekiq::Client.push \
          "class"   => 'ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper',
          "wrapped" => 'TriggerEventJob',
          "queue"   => queue,
          "args"    => [ serialized_job.as_json ]
  end
end