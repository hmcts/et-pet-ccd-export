module MultipleClaimsPresenter
  def self.present(claim, claimant:, multiple_reference:, ethos_case_reference:, files: [], lead_claimant: false)
    if lead_claimant
      ::ApplicationController.render(template: 'export_multiple_claims_service/lead_claimant_data', formats: [:json],
                                     locals: { claim: claim, claimant: claimant, files: files, lead_claimant: lead_claimant,
                                               multiple_reference: multiple_reference, ethos_case_reference: ethos_case_reference })
    else
      ::ApplicationController.render(template: 'export_multiple_claims_service/secondary_claimant_data', formats: [:json],
                                     locals: { claim: claim, claimant: claimant, files: files, lead_claimant: lead_claimant,
                                               multiple_reference: multiple_reference, ethos_case_reference: ethos_case_reference })
    end
  end
end
