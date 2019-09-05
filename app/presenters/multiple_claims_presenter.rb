module MultipleClaimsPresenter
  def self.present(claim, claimant:, files: [], lead_claimant: false, ethos_case_reference: nil)
    if lead_claimant
      ::ApplicationController.render(template: 'export_multiple_claims_service/lead_claimant_data.json.jbuilder', locals: { claim: claim, claimant: claimant, files: files, lead_claimant: lead_claimant, ethos_case_reference: ethos_case_reference })
    else
      ::ApplicationController.render(template: 'export_multiple_claims_service/secondary_claimant_data.json.jbuilder', locals: { claim: claim, claimant: claimant, files: files, lead_claimant: lead_claimant, ethos_case_reference: ethos_case_reference })
    end
  end
end
