module ClaimPresenter
  def self.present(claim, event_token:, files: [], ethos_case_reference: nil)
    ::ApplicationController.render(template: 'export_claim_service/top.json.jbuilder', locals: { claim: claim, event_token: event_token, files: files, ethos_case_reference: ethos_case_reference })
  end
end
