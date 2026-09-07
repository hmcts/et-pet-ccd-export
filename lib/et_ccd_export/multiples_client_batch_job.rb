# frozen_string_literal: true

module EtCcdExport
  module MultiplesClientBatchJob
    extend ActiveSupport::Concern

    included do
      before_enqueue :multiples_batch_job_before_enqueue
    end

    attr_reader :et_ccd_export_multiple_batch_reference, :et_ccd_export_multiple_batch_child_reference

    private

    def multiples_batch_job_before_enqueue
      return if Thread.current[:et_ccd_export_multiple_batch].nil?

      job_metadata['et_ccd_export_multiple_batch_reference'] = Thread.current[:et_ccd_export_multiple_batch].reference
      batch = EtCcdExport::Batch.find(Thread.current[:et_ccd_export_multiple_batch].reference)
      multiples_batch_job_add_to_todo(batch)
    end

    def multiples_batch_job_add_to_todo(batch)
      return if Thread.current[:et_ccd_export_multiple_batch_child_reference].nil?

      job_metadata['et_ccd_export_multiple_batch_child_reference'] = Thread.current[:et_ccd_export_multiple_batch_child_reference]
      batch.add_child_to_todo(Thread.current[:et_ccd_export_multiple_batch_child_reference])
    end
  end
end
