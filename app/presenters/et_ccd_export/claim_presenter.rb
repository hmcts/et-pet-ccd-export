module EtCcdExport
  module ClaimPresenter
    def self.present(claim, event_token:, files: [])
      ::EtCcdExport::ApplicationController.render(template: 'et_ccd_export/export_claim_service/top', formats: [:json],
                                                  locals: { claim: claim, event_token: event_token, files: files })
    end
  end
end
