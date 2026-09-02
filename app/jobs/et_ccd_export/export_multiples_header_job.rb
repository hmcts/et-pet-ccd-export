module EtCcdExport
  class ExportMultiplesHeaderJob < ApplicationJob
    include EtCcdExport::ActiveJobExportRetryControl

    queue_as 'external_system_ccd'

    def perform(primary_reference, respondent_name, case_references, case_type_id, export_id, send_request_id = false, extra_headers = {}) # rubocop:disable Style/OptionalBooleanParameter, Metrics/ParameterLists
      created_case = service.export_header primary_reference, respondent_name, case_references, case_type_id, export_id,
                                           sidekiq_job_data: job_hash,
                                           send_request_id: send_request_id,
                                           extra_headers: extra_headers
      events_service.send_multiples_claim_exported_event export_id: export_id,
                                                         sidekiq_job_data: job_hash,
                                                         case_id: created_case['id'],
                                                         case_reference: created_case.dig('case_data', 'multipleReference'),
                                                         case_type_id: case_type_id,
                                                         use_sidekiq: false
      logger.
        debug("Multiple header exported for export id #{export_id} with case reference #{created_case.dig('case_data',
                                                                                                          'multipleReference')} containing #{case_references.length} child cases")
    end

    def tag_sentry(scope:)
      scope.set_tags primary_reference: self['args'].first
    end

    def retries_exhausted(exception)
      _primary_reference, _respondent_name, _case_references, _case_type_id, export_id = arguments
      events_service.send_claim_failed_event(export_id: export_id, sidekiq_job_data: active_job_data(exception), use_sidekiq: false)
      raise EtCcdExport::ClaimNotExportedException
    end

    private

    def events_service
      EtCcdExport::ApplicationEventsService
    end

    def service
      @service ||= EtCcdExport::ExportMultipleClaimsService.new
    end

    def active_job_data(exception = nil)
      {
        'jid' => job_id,
        'job_id' => job_id,
        'provider_job_id' => provider_job_id,
        'queue_name' => queue_name,
        'executions' => executions,
        'error_class' => exception&.class&.name,
        'error_message' => exception&.message,
        'args' => arguments
      }.compact
    end
  end
end
