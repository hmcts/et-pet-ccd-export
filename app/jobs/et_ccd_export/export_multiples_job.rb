# This worker sends a child case for a multiple
module EtCcdExport
  class ExportMultiplesJob < ApplicationJob
    include EtCcdExport::ActiveJobExportRetryControl
    include EtCcdExport::JobMetadata
    include EtCcdExport::MultiplesClientBatchJob
    include EtCcdExport::MultiplesWorkerBatchJob
    include EtCcdExport::ActiveJobSentryMetadata

    queue_as 'external_system_ccd_multiples'

    def perform(ccd_data, case_type_id, _export_id, _claimant_count, _primary = false, send_request_id = false, extra_headers = {}) # rubocop:disable Style/OptionalBooleanParameter, Metrics/ParameterLists
      multiples_service.export ccd_data,
                               case_type_id,
                               sidekiq_job_data: job_hash,
                               send_request_id: send_request_id,
                               extra_headers: extra_headers
    end

    def tag_sentry
      Sentry.set_tags reference: JSON.parse(arguments.first).dig('resource', 'reference')
    end

    private

    def events_service
      EtCcdExport::ApplicationEventsService
    end

    def multiples_service
      @multiples_service ||= EtCcdExport::ExportMultipleClaimsService.new(use_sidekiq: false)
    end
  end
end
