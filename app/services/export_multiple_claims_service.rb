class ExportMultipleClaimsService
  include ClaimFiles

  def initialize(client_class: EtCcdClient::Client, presenter: MultipleClaimsPresenter,
                 header_presenter: MultipleClaimsHeaderPresenter, envelope_presenter: MultipleClaimsEnvelopePresenter,
                 reference_generator: EthosReferenceGeneratorService,
                 disallow_file_extensions: Rails.application.config.ccd_disallowed_file_extensions)
    self.presenter = presenter
    self.header_presenter = header_presenter
    self.envelope_presenter = envelope_presenter
    self.client_class = client_class
    self.disallow_file_extensions = disallow_file_extensions
    self.reference_generator = reference_generator
  end

  # Schedules a worker to send the pre compiled data (as the ccd data is smaller than the export data for each multiples case)
  # @param [Hash] export - The export hash containing the claim as well as export data
  def call(export, worker: ExportMultiplesWorker, header_worker: ExportMultiplesHeaderWorker, batch: Sidekiq::Batch.new, sidekiq_job_data:)
    case_type_id = export.dig('external_system', 'configurations').detect { |config| config['key'] == 'case_type_id' }['value']
    multiples_case_type_id = export.dig('external_system', 'configurations').detect { |config| config['key'] == 'multiples_case_type_id' }['value']
    claimant_count = export.dig('resource', 'secondary_claimants').length + 1#

    client_class.use do |client|
      start_multiple_result = client.start_multiple(case_type_id: case_type_id, quantity: claimant_count)
      multiple_ref = start_multiple_result['multipleRefNumber']
      batch.description = "Batch of multiple cases for reference #{export.dig('resource', 'reference')}"
      batch.callback_queue = 'external_system_ccd_callbacks'
      batch.on :complete,
               Callback,
               primary_reference: multiple_ref,
               respondent_name: export.dig('resource', 'primary_respondent', 'name'),
               header_worker: header_worker.name,
               multiples_case_type_id: multiples_case_type_id,
               export_id: export['id']
      batch.jobs do
        next_ref = start_multiple_result['startCaseRefNumber']
        worker.perform_async presenter.present(export['resource'], claimant: export.dig('resource', 'primary_claimant'), files: files_data(client, export), lead_claimant: true, multiple_reference: multiple_ref, ethos_case_reference: next_ref), case_type_id, export['id'], claimant_count, true
        export.dig('resource', 'secondary_claimants').each do |claimant|
          next_ref = reference_generator.call(next_ref)
          worker.perform_async presenter.present(export['resource'], claimant: claimant, lead_claimant: false, multiple_reference: multiple_ref, ethos_case_reference: next_ref), case_type_id, export['id'], claimant_count
        end
      end
      batch.bid
    end
  end

  # @param [String] data The JSON data to send to ccd as the details part of the payload
  def export(data, case_type_id, sidekiq_job_data:, bid:, export_id:, claimant_count:)
    client_class.use do |client|
      resp = client.caseworker_start_case_creation(case_type_id: case_type_id)
      event_token = resp['token']
      data = envelope_presenter.present(data, event_token: event_token)
      created_case = client.caseworker_case_create(data, case_type_id: case_type_id)
      number = Sidekiq.redis do |r|
        r.incr("BID-#{bid}-references-count")
      end
      [created_case, number]
    end
  end

  # Export the header record (multiples case) to ccd
  # @param [String] primary_reference
  # @param [String] respondent_name
  # @param [Array<String>] case_references
  # @param [String] case_type_id
  # @param [String] export_id
  # @param [Hash] sidekiq_job_data
  def export_header(primary_reference, respondent_name, case_references, case_type_id, export_id, sidekiq_job_data:)
    client_class.use do |client|
      resp = client.caseworker_start_bulk_creation(case_type_id: case_type_id)
      event_token = resp['token']
      data = header_presenter.present(primary_reference: primary_reference, respondent_name: respondent_name, case_references: case_references, event_token: event_token)
      client.caseworker_case_create(data, case_type_id: case_type_id)
    end
  end

  private

  attr_accessor :presenter, :header_presenter, :envelope_presenter, :client_class, :reference_generator, :disallow_file_extensions

  def percent_complete_for(number, claimant_count:)
    (number * (100.0 / (claimant_count + 2))).to_i
  end

  class Callback
    include Sidekiq::Worker

    def on_complete(batch_status, options)
      if batch_status.failures != 0
        unmark_event_complete(batch_status)
        return
      end
      case_references = Sidekiq.redis { |r| r.lrange("BID-#{batch_status.bid}-references", 0, -1) }

      options['header_worker'].safe_constantize.perform_async options['primary_reference'], options['respondent_name'], case_references, options['multiples_case_type_id'], options['export_id']
    end

    private

    # Required as as workaround otherwise once something has failed, the batch will never complete after the retries have succeeded
    def unmark_event_complete(batch_status)
      batch_key = "BID-#{batch_status.bid}"
      ::Sidekiq.redis do |r|
        r.hset(batch_key, :complete, false)
      end
    end
  end
end
