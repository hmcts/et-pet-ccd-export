class ExportMultipleClaimsService
  include ClaimFiles
  include CcdExtraHeaders

  def initialize(client_class: EtCcdClient::Client,
                 presenter: MultipleClaimsPresenter,
                 header_presenter: MultipleClaimsHeaderPresenter,
                 envelope_presenter: MultipleClaimsEnvelopePresenter,
                 reference_generator: EthosReferenceGeneratorService,
                 application_events_service: ApplicationEventsService,
                 disallow_file_extensions: Rails.application.config.ccd_disallowed_file_extensions)
    self.presenter                = presenter
    self.header_presenter         = header_presenter
    self.envelope_presenter       = envelope_presenter
    self.client_class             = client_class
    self.disallow_file_extensions = disallow_file_extensions
    self.reference_generator      = reference_generator
    self.events_service           = application_events_service
  end

  # Schedules a worker to send the pre compiled data (as the ccd data is smaller than the export data for each multiples case)
  # @param [Hash] export - The export hash containing the claim as well as export data
  # @param [Hash] sidekiq_job_data
  def call(export,
           sidekiq_job_data:,
           worker: ExportMultiplesWorker,
           header_worker: ExportMultiplesHeaderWorker)
    case_type_id           = export.dig('external_system', 'configurations').detect { |config| config['key'] == 'case_type_id' }['value']
    multiples_case_type_id = export.dig('external_system', 'configurations').detect { |config| config['key'] == 'multiples_case_type_id' }['value']
    multiples_max_count    = export.dig('external_system', 'configurations').detect { |config| config['key'] == 'multiples_max_claimant_count' }&.fetch('value')
    claimant_count         = export.dig('resource', 'secondary_claimants').length + 1 #
    if multiples_max_count.present? && multiples_max_count =~ /\A\d+\z/ && claimant_count > multiples_max_count.to_i
      raise ClaimMultipleClaimantCountExceededException, "Maximum claimant count of #{multiples_max_count} exceeded.  This must be dealt with manually"
    end

    client_class.use do |client|
      extra_headers         = extra_headers_for(export, sidekiq_job_data['jid'])
      start_multiple_result = client.start_multiple case_type_id:  case_type_id,
                                                    quantity:      claimant_count,
                                                    extra_headers: extra_headers
      multiple_ref          = start_multiple_result.dig('data', 'multipleRefNumber')
      next_ref              = start_multiple_result.dig('data', 'startCaseRefNumber')
      send_request_id       = send_request_id?(export)
      events_service.send_multiples_claim_references_allocated_event export_id:        export['id'],
                                                                     sidekiq_job_data: sidekiq_job_data,
                                                                     start_reference:  next_ref,
                                                                     quantity:         claimant_count,
                                                                     case_type_id:     case_type_id
      batch = EtCcdExport::Sidekiq::Batch.start reference:      multiple_ref,
                                                quantity:       claimant_count,
                                                start_ref:      next_ref,
                                                export_id:      export['id'],
                                                case_type_id:   case_type_id
      batch.on :success,
               SuccessCallback,
               primary_reference:      multiple_ref,
               respondent_name:        export.dig('resource', 'primary_respondent', 'name'),
               header_worker:          header_worker.name,
               multiples_case_type_id: multiples_case_type_id,
               export_id:              export['id'],
               send_request_id:        send_request_id,
               extra_headers:          extra_headers.except('request_id')
      batch.jobs do
        extra_headers = extra_headers_for(export)
        batch.child_job(next_ref) do
          worker.perform_async presenter.present(export['resource'],
                                                 claimant:             export.dig('resource', 'primary_claimant'),
                                                 files:                files_data(client, export),
                                                 lead_claimant:        true,
                                                 multiple_reference:   multiple_ref,
                                                 ethos_case_reference: next_ref),
                               case_type_id,
                               export['id'],
                               claimant_count,
                               true,
                               send_request_id,
                               extra_headers
        end
        export.dig('resource', 'secondary_claimants').each do |claimant|
          next_ref = reference_generator.call(next_ref)
          batch.child_job(next_ref) do
            worker.perform_async presenter.present(export['resource'],
                                                   claimant:             claimant,
                                                   lead_claimant:        false,
                                                   multiple_reference:   multiple_ref,
                                                   ethos_case_reference: next_ref),
                                 case_type_id,
                                 export['id'],
                                 claimant_count,
                                 false,
                                 send_request_id,
                                 extra_headers
          end
        end
      end
      batch.reference
    end
  end

  # @param [String] data The JSON data to send to ccd as the details part of the payload
  # @return [String] The unique id of the case created in ccd
  # @param [String] case_type_id The case type id to direct the case to the correct office in ccd
  # @param [Hash] sidekiq_job_data The sidekiq data - only used for the 'jid'
  def export(data, case_type_id, sidekiq_job_data:, export_id:, claimant_count:, send_request_id: false, extra_headers: {})
    extra_headers = extra_headers.merge('request_id' => sidekiq_job_data['jid']) if send_request_id
    client_class.use do |client|
      resp         = client.caseworker_start_case_creation(case_type_id: case_type_id, extra_headers: extra_headers)
      event_token  = resp['token']
      data         = envelope_presenter.present(data, event_token: event_token)
      created_case = client.caseworker_case_create(data, case_type_id: case_type_id, extra_headers: extra_headers)
      created_case['id']
    end
  end

  # Export the header record (multiples case) to ccd
  # @param [String] primary_reference
  # @param [String] respondent_name
  # @param [Array<String>] case_references
  # @param [String] case_type_id
  # @param [String] export_id
  # @param [Hash] sidekiq_job_data
  def export_header(primary_reference, respondent_name, case_references, case_type_id, export_id, sidekiq_job_data:, send_request_id: false, extra_headers: {})
    extra_headers = extra_headers.merge('request_id' => sidekiq_job_data['jid']) if send_request_id
    client_class.use do |client|
      resp        = client.caseworker_start_bulk_creation(case_type_id: case_type_id, extra_headers: extra_headers)
      event_token = resp['token']
      data        = header_presenter.present(primary_reference: primary_reference, respondent_name: respondent_name, case_references: case_references, event_token: event_token)
      client.caseworker_case_create(data, case_type_id: case_type_id, extra_headers: extra_headers)
    end
  end

  private

  attr_accessor :presenter, :header_presenter, :envelope_presenter,
                :client_class, :reference_generator, :disallow_file_extensions,
                :events_service

  def percent_complete_for(number, claimant_count:)
    (number * (100.0 / (claimant_count + 2))).to_i
  end

  class SuccessCallback
    include Sidekiq::Worker

    sidekiq_options queue: 'external_system_ccd_callbacks'
    def perform(case_references, options)
      options['header_worker'].safe_constantize.perform_async options['primary_reference'],
                                                              options['respondent_name'],
                                                              case_references,
                                                              options['multiples_case_type_id'],
                                                              options['export_id'],
                                                              options['send_request_id'],
                                                              options['extra_headers']
    end
  end
end
