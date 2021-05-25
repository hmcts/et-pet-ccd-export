class MultipleClaimsHeaderPresenter
  def self.present(primary_reference:, case_references:, event_token:, respondent_name:)
    ::ApplicationController.render(template: 'export_multiple_claims_service/header', formats: [:json],locals: { primary_reference: primary_reference, respondent_name: respondent_name, case_references: case_references, event_token: event_token })
  end
end
