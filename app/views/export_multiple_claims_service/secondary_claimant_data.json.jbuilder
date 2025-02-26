json.set! 'receiptDate', optional_date(claim['date_of_receipt'])
json.set! 'caseSource', 'ET1 Online'
json.set! 'ethosCaseReference', ethos_case_reference
json.set! 'feeGroupReference', claim['reference']
json.set! 'claimant_TypeOfClaimant', 'Individual'
json.set! 'positionType', 'Received by Auto-Import'
json.set! 'claimantIndType' do
  json.set! 'claimant_title1', handle_other_titles(claimant['title'])
  json.set! 'claimant_title_other', other_title(claimant['title'])
  json.set! 'claimant_first_names', claimant['first_name']
  json.set! 'claimant_last_name', claimant['last_name']
  json.set! 'claimant_date_of_birth', claimant['date_of_birth']
  json.set! 'claimant_gender', nil
end
json.set! 'claimantType' do
  json.set! 'claimant_addressUK' do
    json.set! 'AddressLine1', claimant.dig('address', 'building')
    json.set! 'AddressLine2', claimant.dig('address', 'street')
    json.set! 'PostTown', claimant.dig('address', 'locality')
    json.set! 'County', claimant.dig('address', 'county')
    json.set! 'Country', nil
    json.set! 'PostCode', claimant.dig('address', 'post_code')
  end
  json.set! 'claimant_phone_number', nil
  json.set! 'claimant_mobile_number', nil
  json.set! 'claimant_email_address', nil
  json.set! 'claimant_contact_preference', nil

end
json.set! 'caseType', 'Multiple'
json.set! 'multipleReference', multiple_reference
json.set! 'leadClaimant', 'No'
json.set! 'claimantWorkAddress', {}
json.set! 'respondentCollection' do
  json.array!([claim['primary_respondent']] + claim['secondary_respondents']) do |respondent|
    json.set! 'value' do
      json.set! 'respondent_name', respondent['name']
      json.set! 'respondent_address' do
        json.set! 'AddressLine1', respondent.dig('address', 'building')
        json.set! 'AddressLine2', respondent.dig('address', 'street')
        json.set! 'PostTown', respondent.dig('address', 'locality')
        json.set! 'County', respondent.dig('address', 'county')
        json.set! 'Country', nil
        json.set! 'PostCode', respondent.dig('address', 'post_code')
      end
      json.set! 'respondent_phone1', respondent['address_telephone_number']
      json.set! 'respondent_ACAS', respondent['acas_certificate_number']
      json.set! 'respondent_ACAS_question', respondent['acas_certificate_number'].present? ? 'Yes' : 'No'
      json.set! 'respondent_ACAS_no', optional_acas_exemption(respondent['acas_exemption_code']) unless respondent['acas_certificate_number'].present?
    end
  end
end
json.set! 'claimantOtherType', {}
json.set! 'claimantRepresentedQuestion', claim['primary_representative'].present? ? 'Yes' : 'No'
if claim['primary_representative'].present?
  json.set! 'representativeClaimantType' do
    json.set! 'representative_occupation', claim.dig('primary_representative', 'representative_type')
    json.set! 'name_of_organisation', claim.dig('primary_representative', 'organisation_name')
    json.set! 'name_of_representative', claim.dig('primary_representative', 'name')
    json.set! 'representative_address' do
      json.set! 'AddressLine1', claim.dig('primary_representative', 'address', 'building')
      json.set! 'AddressLine2', claim.dig('primary_representative', 'address', 'street')
      json.set! 'PostTown', claim.dig('primary_representative', 'address', 'locality')
      json.set! 'County', claim.dig('primary_representative', 'address', 'county')
      json.set! 'Country', nil
      json.set! 'PostCode', claim.dig('primary_representative', 'address', 'post_code')
    end
    json.set! 'representative_phone_number', claim.dig('primary_representative', 'address_telephone_number')
    json.set! 'representative_mobile_number', claim.dig('primary_representative', 'mobile_number')
    json.set! 'representative_email_address', claim.dig('primary_representative', 'email_address')
  end
end
json.set! 'documentCollection', []
json.set!('claimantHearingPreference') do
  json.set!('claimant_hearing_panel_preference', nil)
  json.set!('claimant_hearing_panel_preference_why', '')
end
