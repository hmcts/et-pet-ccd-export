module EtExporter
  # A worker to perform an update of an existing claim once exported
  class ExportClaimUpdateWorker
    include Sidekiq::Worker
    include ExportRetryControl
    self.exceptions_without_retry = [PreventJobRetryingException].freeze

    attr_accessor :job_hash

    def initialize(application_events_service: ApplicationEventsService, update_case_service: UpdateLeadCaseService)
      self.events_service = application_events_service
      self.update_case_service = update_case_service
    end

    def perform(json)
      before_perform
      logger.debug "---------------------------------------------------------------------------------------------------------"
      logger.debug "- THIS IS THE UPDATE JSON THAT HAS COME FROM THE API                                                           -"
      logger.debug "-                                                                                                       -"
      logger.debug "---------------------------------------------------------------------------------------------------------"

      parsed_json = JSON.parse(json)
      logger.debug JSON.generate(parsed_json)
      Sentry.with_scope do |scope|
        scope.set_tags reference: parsed_json.dig('resource', 'external_data', 'case_reference')
        perform_update(parsed_json)
      end
    end

    private

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

    attr_accessor :events_service, :update_case_service
  end
end
