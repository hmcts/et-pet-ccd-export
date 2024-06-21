json.set! 'receiptDate', optional_date(claim['date_of_receipt'])
json.set! 'caseSource', 'ET1 Online'
json.set! 'ethosCaseReference', ethos_case_reference
json.set! 'feeGroupReference', claim['reference']
json.set! 'claimant_TypeOfClaimant', 'Individual'
json.set! 'positionType', 'Received by Auto-Import'
json.set! 'claimantIndType' do
  json.set! 'claimant_title1', handle_other_titles(claim.dig('primary_claimant', 'title'))
  json.set! 'claimant_first_names', claim.dig('primary_claimant', 'first_name')
  json.set! 'claimant_last_name', claim.dig('primary_claimant', 'last_name')
  json.set! 'claimant_date_of_birth', claim.dig('primary_claimant', 'date_of_birth')
  json.set! 'claimant_gender', optional_gender(claim.dig('primary_claimant', 'gender'))
end
json.set! 'claimantType' do
  json.set! 'claimant_addressUK' do
    json.set! 'AddressLine1', claim.dig('primary_claimant', 'address', 'building')
    json.set! 'AddressLine2', claim.dig('primary_claimant', 'address', 'street')
    json.set! 'PostTown', claim.dig('primary_claimant', 'address', 'locality')
    json.set! 'County', claim.dig('primary_claimant', 'address', 'county')
    json.set! 'Country', optional_claimant_country(claim.dig('primary_claimant', 'address', 'country'))
    json.set! 'PostCode', claim.dig('primary_claimant', 'address', 'post_code')
  end
  json.set! 'claimant_phone_number', claim.dig('primary_claimant', 'address_telephone_number')
  json.set! 'claimant_mobile_number', claim.dig('primary_claimant', 'mobile_number')
  json.set! 'claimant_email_address', claim.dig('primary_claimant', 'email_address')
  json.set! 'claimant_contact_preference', claim.dig('primary_claimant', 'contact_preference')&.humanize
end
json.set! 'caseType', 'Multiple'
json.set! 'multipleReference', multiple_reference
json.set! 'leadClaimant', 'Yes'
json.set! 'claimantWorkAddress' do
  if claim.dig('primary_respondent', 'work_address').present?
    json.set! 'claimant_work_address' do
      json.set! 'AddressLine1', claim.dig('primary_respondent', 'work_address', 'building')
      json.set! 'AddressLine2', claim.dig('primary_respondent', 'work_address', 'street')
      json.set! 'PostTown', claim.dig('primary_respondent', 'work_address', 'locality')
      json.set! 'County', claim.dig('primary_respondent', 'work_address', 'county')
      json.set! 'Country', nil
      json.set! 'PostCode', claim.dig('primary_respondent', 'work_address', 'post_code')
    end
    json.set! 'claimant_work_phone_number', claim.dig('primary_respondent', 'work_address_telephone_number')
  else
    json.set! 'claimant_work_address' do
      json.set! 'AddressLine1', claim.dig('primary_respondent', 'address', 'building')
      json.set! 'AddressLine2', claim.dig('primary_respondent', 'address', 'street')
      json.set! 'PostTown', claim.dig('primary_respondent', 'address', 'locality')
      json.set! 'County', claim.dig('primary_respondent', 'address', 'county')
      json.set! 'Country', nil
      json.set! 'PostCode', claim.dig('primary_respondent', 'address', 'post_code')
    end
    json.set! 'claimant_work_phone_number', claim.dig('primary_respondent', 'address_telephone_number')
  end
end
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
json.set! 'claimantOtherType' do
  json.set! 'claimant_disabled', claim.dig('primary_claimant', 'special_needs').present? ? 'Yes' : 'No'
  json.set! 'claimant_disabled_details', claim.dig('primary_claimant', 'special_needs') if claim.dig('primary_claimant', 'special_needs').present?
  if claim['employment_details'].present?
    json.set! 'claimant_employed_currently', 'Yes' if claim.dig('employment_details', 'start_date').present? &&
                                                      claim.dig('employment_details', 'end_date').nil?
    json.set! 'claimant_employed_currently', 'No' if claim.dig('employment_details', 'end_date').present? &&
                                                     Date.parse(claim.dig('employment_details', 'end_date')) < Date.today
    json.set! 'claimant_employed_currently', 'Yes' if claim.dig('employment_details', 'end_date').present? &&
                                                      Date.parse(claim.dig('employment_details', 'end_date')) >= Date.today
    json.set! 'claimant_occupation', claim.dig('employment_details', 'job_title')
    json.set! 'claimant_employed_from', claim.dig('employment_details', 'start_date')
    json.set! 'claimant_employed_to', claim.dig('employment_details', 'end_date')
    json.set! 'claimant_employed_notice_period', claim.dig('employment_details', 'notice_period_end_date')
  end
end
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
json.set! "documentCollection" do
  json.array! files, partial: 'shared/file', as: :file
end
