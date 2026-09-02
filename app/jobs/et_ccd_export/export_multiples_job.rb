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
      Sentry.with_scope do |scope|
        scope.set_tags reference: JSON.parse(ccd_data)['feeGroupReference']
        multiples_service.export ccd_data,
                                 case_type_id,
                                 sidekiq_job_data: job_hash,
                                 send_request_id: send_request_id,
                                 extra_headers: extra_headers
      end
    end

    def tag_sentry
      Sentry.set_tags reference: JSON.parse(arguments.first)['feeGroupReference']
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
