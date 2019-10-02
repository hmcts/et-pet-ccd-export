class ExportMultipleClaimsService
  include ClaimFiles
  include GenerateEthosCaseReference
  include AsyncApplicationEvents
  def initialize(client_class: EtCcdClient::Client, presenter: MultipleClaimsPresenter, header_presenter: MultipleClaimsHeaderPresenter, envelope_presenter: MultipleClaimsEnvelopePresenter, disallow_file_extensions: Rails.application.config.ccd_disallowed_file_extensions)
    self.presenter = presenter
    self.header_presenter = header_presenter
    self.envelope_presenter = envelope_presenter
    self.client_class = client_class
    self.disallow_file_extensions = disallow_file_extensions
  end

  # Schedules a worker to send the pre compiled data (as the ccd data is smaller than the export data for each multiples case)
  # @param [Hash] export - The export hash containing the claim as well as export data
  def call(export, worker: ExportMultiplesWorker, header_worker: ExportMultiplesHeaderWorker, batch: Sidekiq::Batch.new, jid:)
    send_claim_export_started_event(bid: batch.bid, export_id: export['id'], jid: jid)
    case_type_id = export.dig('external_system', 'configurations').detect {|config| config['key'] == 'case_type_id'}['value']
    multiples_case_type_id = export.dig('external_system', 'configurations').detect {|config| config['key'] == 'multiples_case_type_id'}['value']
    batch.description = "Batch of multiple cases for reference #{export.dig('resource', 'reference')}"
    batch.callback_queue = 'external_system_ccd_callbacks'
    batch.on :complete,
             Callback,
             primary_reference: export.dig('resource', 'reference'),
             respondent_name: export.dig('resource', 'primary_respondent', 'name'),
             header_worker: header_worker.name,
             multiples_case_type_id: multiples_case_type_id,
             export_id: export['id']
    batch.jobs do
      client_class.use do |client|
        worker.perform_async presenter.present(export['resource'], claimant: export.dig('resource', 'primary_claimant'), files: files_data(client, export), lead_claimant: true, ethos_case_reference: ethos_case_reference(export.dig('resource', 'office_code'))), case_type_id, true
      end
      export.dig('resource', 'secondary_claimants').each do |claimant|
        worker.perform_async presenter.present(export['resource'], claimant: claimant, lead_claimant: false, ethos_case_reference: ethos_case_reference(export.dig('resource', 'office_code'))), case_type_id
      end
    end
  end

  # @param [String] data The JSON data to send to ccd as the details part of the payload
  def export(data, case_type_id)
    client_class.use do |client|
      resp = client.caseworker_start_case_creation(case_type_id: case_type_id)
      event_token = resp['token']
      data = envelope_presenter.present(data, event_token: event_token)
      client.caseworker_case_create(data, case_type_id: case_type_id)
    end
  end

  # Export the header record (multiples case) to ccd
  # @param [String] primary_reference
  # @param [String] respondent_name
  # @param [Array<String>] case_references
  # @param [String] case_type_id
  # @param [String] export_id
  # @param [String] jid
  def export_header(primary_reference, respondent_name, case_references, case_type_id, export_id, jid:, bid:)
    client_class.use do |client|
      resp = client.caseworker_start_bulk_creation(case_type_id: case_type_id)
      event_token = resp['token']
      data = header_presenter.present(primary_reference: primary_reference, respondent_name: respondent_name, case_references: case_references, event_token: event_token)
      created_case = client.caseworker_case_create(data, case_type_id: case_type_id)
      send_claim_exported_event(bid: bid, export_id: export_id, jid: jid, case_id: created_case['id'], case_reference: created_case.dig('case_data', 'multipleReference'), case_type_id: case_type_id)
    end
  end

  private

  attr_accessor :presenter, :header_presenter, :envelope_presenter, :client_class, :disallow_file_extensions
  class Callback
    include Sidekiq::Worker

    def on_complete(batch_status, options)
      case_references = Sidekiq.redis { |r| r.lrange("BID-#{batch_status.bid}-references", 0, -1) }

      options['header_worker'].safe_constantize.perform_async options['primary_reference'], options['respondent_name'], case_references, options['multiples_case_type_id'], options['export_id']
    end
  end
end
