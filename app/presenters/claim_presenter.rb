module ClaimPresenter
  def self.present(claim, event_token:, files: [])
    ::ApplicationController.render(template: 'export_claim_service/top', formats: [:json], locals: { claim: claim, event_token: event_token, files: files })
  end
end
