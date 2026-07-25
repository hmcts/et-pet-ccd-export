# frozen_string_literal: true

module EtCcdExport
  module MultiplesWorkerBatchJob
    extend ActiveSupport::Concern

    included do
      around_perform :multiples_worker_batch_job_around_perform
      after_discard do |job, exception|
        multiples_worker_batch_after_discard(job, exception)
      end
    end

    def batch
      @batch ||= multiples_worker_batch_job_find_batch
    end

    private

    def multiples_worker_batch_job_around_perform(*_args, **_kw_args, &)
      lifecycle = EtCcdExport::ActiveJob::MultiplesBatchLifecycle.new(job: self)
      lifecycle.call(&)
    end

    def multiples_worker_batch_job_find_batch(batch: EtCcdExport::Sidekiq::Batch)
      return nil unless job_metadata['et_ccd_export_multiple_batch_reference'].present?

      batch.find(job_metadata['et_ccd_export_multiple_batch_reference'])
    end

    def multiples_worker_batch_after_discard(job, _exception)
      lifecycle = EtCcdExport::ActiveJob::MultiplesBatchLifecycle.new(job:)
      lifecycle.job_discarded!
    end
  end
end
