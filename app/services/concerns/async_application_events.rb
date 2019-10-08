module AsyncApplicationEvents
  def send_application_event(event, data, queue: 'events')
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

  def send_claim_exported_event(export_id:, sidekiq_job_data:, case_id:, case_reference:, case_type_id:)
    event_data = {
      sidekiq: sidekiq_job_data.except('class', 'args', 'queue'),
      export_id: export_id,
      external_data: {
        case_id: case_id,
        case_reference: case_reference,
        case_type_id: case_type_id
      },
      state: :complete,
      message: 'Claim exported'
    }
    send_application_event('ClaimExportFeedbackReceived', event_data)
  end

  def send_multiples_claim_exported_event(export_id:, sidekiq_job_data:, case_id:, case_reference:, case_type_id:)
    event_data = {
      sidekiq: sidekiq_job_data.except('class', 'args', 'queue'),
      export_id: export_id,
      external_data: {
        case_id: case_id,
        case_reference: case_reference,
        case_type_id: case_type_id
      },
      state: :complete,
      message: 'Multiples claim exported'
    }
    send_application_event('ClaimExportFeedbackReceived', event_data)
  end

  def send_claim_erroring_event(export_id:, sidekiq_job_data:)
    event_data = {
      sidekiq: sidekiq_job_data.except('class', 'args', 'queue'),
      export_id: export_id,
      external_data: {},
      message: 'Claim erroring',
      state: 'erroring',
      percent_complete: nil
    }
    send_application_event('ClaimExportFeedbackReceived', event_data)
  end

  def send_claim_failed_event(export_id:, sidekiq_job_data:)
    event_data = {
      sidekiq: sidekiq_job_data.except('class', 'args', 'queue'),
      export_id: export_id,
      external_data: {},
      message: 'Claim failed to export',
      state: 'failed',
      percent_complete: 0
    }
    send_application_event('ClaimExportFeedbackReceived', event_data)
  end

  def send_subclaim_failed_event(export_id:, sidekiq_job_data:)
    event_data = {
      sidekiq: sidekiq_job_data.except('class', 'args', 'queue'),
      export_id: export_id,
      external_data: {},
      message: 'Subclaim failed to export',
      state: 'failed',
      percent_complete: 0
    }
    send_application_event('ClaimExportFeedbackReceived', event_data)
  end

  def send_subclaim_erroring_event(export_id:, sidekiq_job_data:, exception:)
    event_data = {
      sidekiq: sidekiq_job_data.merge('error_message' => exception.message, 'error_class' => exception.class.to_s),
      export_id: export_id,
      external_data: {},
      message: 'Claim erroring due to subclaim error',
      state: 'erroring',
      percent_complete: nil
    }
    send_application_event('ClaimExportFeedbackReceived', event_data)
  end

  def send_claim_export_started_event(export_id:, sidekiq_job_data:)
    event_data = {
      sidekiq: sidekiq_job_data.except('class', 'args', 'queue'),
      export_id: export_id,
      external_data: {},
      state: 'in_progress',
      percent_complete: 0,
      message: 'Claim export started'
    }
    send_application_event('ClaimExportFeedbackReceived', event_data)
  end

  def send_multiples_claim_export_started_event(export_id:, sidekiq_job_data:)
    event_data = {
      sidekiq: sidekiq_job_data.except('class', 'args', 'queue'),
      export_id: export_id,
      external_data: {},
      state: 'in_progress',
      percent_complete: 0,
      message: 'Multiples claim export started'
    }
    send_application_event('ClaimExportFeedbackReceived', event_data)
  end

  def send_claim_export_multiples_queued_event(queued_bid:, export_id:, sidekiq_job_data:, percent_complete:)
    event_data = {
      sidekiq: sidekiq_job_data.except('class', 'args', 'queue').merge(queued_bid: queued_bid),
      export_id: export_id,
      external_data: {},
      state: 'in_progress',
      percent_complete: percent_complete,
      message: 'Sub cases queued for export'
    }
    send_application_event('ClaimExportFeedbackReceived', event_data)
  end

  def send_claim_export_multiples_progress_event(export_id:, sidekiq_job_data:, percent_complete:, case_id:, case_reference:, case_type_id:)
    event_data = {
      sidekiq: sidekiq_job_data.except('class', 'args', 'queue'),
      export_id: export_id,
      external_data: {
        case_id: case_id,
        case_reference: case_reference,
        case_type_id: case_type_id
      },
      state: 'in_progress',
      percent_complete: percent_complete,
      message: 'Sub case exported'
    }
    send_application_event('ClaimExportFeedbackReceived', event_data)
  end
end