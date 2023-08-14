module ExportRetryControl
  extend ActiveSupport::Concern

  included do
    class_attribute :exceptions_without_retry

    # As we cant stop the retry chain dynamically, if the exception is one of those that
    # should not retry then lets just set the delay to 1 second so it blasts through all
    # the retries until they are exhausted - without calling the underlying service
    sidekiq_retry_in do |count, ex|
      next 1 if ex.is_a?(PreventJobRetryingException) || exceptions_without_retry.include?(ex.class)

      (count**6) + 15 + (rand(30) * (count + 1))
    end

    sidekiq_retries_exhausted do |msg, ex|
      json = JSON.parse(msg['args'][0])
      job_data = msg.except('args', 'class').merge(ex.try(:job_hash) || {})
      ApplicationEventsService.send_claim_failed_event(export_id: json['id'], sidekiq_job_data: job_data)
      raise ClaimNotExportedException
    end
  end

  def before_perform
    if job_hash['error_class'] &&
       (job_hash['error_class'] == 'PreventJobRetryingException' || self.class.exceptions_without_retry.include?(job_hash['error_class'].safe_constantize))
      raise PreventJobRetryingException.new "This is a fake exception which will deliberately prevent this job from retrying", job_hash
    end
  end
end
