module EtCcdExport
  module ActiveJobExportRetryControl
    extend ActiveSupport::Concern

    included do
      retry_on StandardError,
               wait: :polynomially_longer,
               attempts: 9 do |job, exception|
        job.retries_exhausted(exception)
      end

      discard_on EtCcdExport::PreventJobRetryingException do |job, exception|
        job.retries_exhausted(exception)
      end
    end

    def job_hash
      active_job_data
    end

    def retries_exhausted(exception)
      export = JSON.parse(arguments.first)

      EtCcdExport::ApplicationEventsService.send_claim_failed_event(
        export_id: export['id'],
        sidekiq_job_data: active_job_data(exception)
      )
    end

    private

    def active_job_data(exception = nil)
      {
        'jid' => job_id,
        'job_id' => job_id,
        'provider_job_id' => provider_job_id,
        'queue_name' => queue_name,
        'executions' => executions,
        'error_class' => exception&.class&.name,
        'error_message' => exception&.message
      }.compact
    end
  end
end
