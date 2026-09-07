module EtCcdExport
  module ActiveJobExportRetryControl
    extend ActiveSupport::Concern

    included do
      retry_on StandardError,
               wait: wait_strategy,
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
      raise EtCcdExport::ClaimNotExportedException
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

    class_methods do
      def wait_strategy
        strategy = Rails.application.config.et_ccd_export.retry_wait_strategy
        case strategy
        when /\A\d+\z/ then strategy.to_i.minutes
        else :polynomially_longer
        end
      end
    end
  end
end
