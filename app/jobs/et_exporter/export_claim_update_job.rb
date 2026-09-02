module EtExporter
  # A worker to perform an update of an existing claim once exported
  class ExportClaimUpdateJob < EtCcdExport::ApplicationJob
    include EtCcdExport::ActiveJobExportRetryControl

    def perform(json)
      logger.debug "---------------------------------------------------------------------------------------------------------"
      logger.debug "- THIS IS THE UPDATE JSON THAT HAS COME FROM THE API                                                           -"
      logger.debug "-                                                                                                       -"
      logger.debug "---------------------------------------------------------------------------------------------------------"

      parsed_json = JSON.parse(json)
      logger.debug JSON.generate(parsed_json)
      perform_update(parsed_json)
    end

    def tag_sentry(scope:)
      scope.set_tags reference: JSON.parse(self['args'].first).dig('resource', 'external_data', 'case_reference')
    end

    private

    def events_service
      EtCcdExport::ApplicationEventsService
    end

    def update_case_service
      EtCcdExport::UpdateLeadCaseService
    end

    def perform_update(parsed_json)
      send_starting_event(parsed_json)
      update_case_service.call(parsed_json, sidekiq_job_data: job_hash)
      send_finished_event(parsed_json)
    rescue Exception => e # rubocop:disable Lint/RescueException
      events_service.send_claim_erroring_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash, exception: e)
      raise e
    end

    def send_finished_event(parsed_json)
      events_service.send_claim_update_exported_event export_id: parsed_json['id'],
                                                      sidekiq_job_data: job_hash,
                                                      **parsed_json['external_data'].
                                                        slice('case_id', 'case_type_id', 'case_reference').symbolize_keys
    end

    def send_starting_event(parsed_json)
      events_service.send_claim_update_export_started_event(export_id: parsed_json['id'], sidekiq_job_data: job_hash)
    end
  end
end
