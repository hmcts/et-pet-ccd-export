class ExportClaimService
  include ClaimFiles
  include GenerateEthosCaseReference
  include AsyncApplicationEvents
  def initialize(client_class: EtCcdClient::Client, disallow_file_extensions: Rails.application.config.ccd_disallowed_file_extensions)
    self.client_class = client_class
    self.disallow_file_extensions = disallow_file_extensions
  end

  def call(export, jid:, bid: nil)
    do_export(export, jid: jid, bid: bid)
  end

  private

  attr_accessor :client_class, :disallow_file_extensions

  def do_export(export, bid:, jid:)
    send_claim_export_started_event(bid, export, jid)
    client_class.use do |client|
      case_type_id = export.dig('external_system', 'configurations').detect {|c| c['key'] == 'case_type_id'}['value']
      resp = client.caseworker_start_case_creation(case_type_id: case_type_id)
      event_token = resp['token']
      data = ClaimPresenter.present(export['resource'], event_token: event_token, files: files_data(client, export), ethos_case_reference: ethos_case_reference(export.dig('resource', 'office_code')))
      created_case = client.caseworker_case_create(data, case_type_id: case_type_id)
      send_claim_exported_event(bid, export, jid, created_case['id'], created_case.dig('case_data', 'ethosCaseReference'), case_type_id)
    end
  end

  def send_claim_exported_event(bid, export, jid, case_id, case_reference, case_type_id)
    event_data = {
      sidekiq: {
        jid: jid,
        bid: bid,
      },
      export_id: export['id'],
      external_data: {
        case_id: case_id,
        case_reference: case_reference,
        case_type_id: case_type_id
      }
    }
    send_application_event('ClaimExportSucceeded', event_data)
  end

  def send_claim_export_started_event(bid, export, jid)
    event_data = {
      sidekiq: {
        jid: jid,
        bid: bid,
      },
      export_id: export['id'],
      external_data: {},
      state: 'in_progress',
      percent_complete: 0
    }
    send_application_event('ClaimExportFeedbackReceived', event_data)
  end

end
