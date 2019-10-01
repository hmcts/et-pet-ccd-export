=begin
{
  "resource_type": "Claim",
  "external_system": {
    "name": "ATOS Primary",
    "reference": "atos",
    "office_codes": [
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      22,
      23,
      24,
      25,
      26,
      27,
      31,
      32,
      33,
      34,
      41,
      50,
      51
    ],
    "enabled": true,
    "configurations": [
      {
        "key": "username",
        "value": "atos",
        "can_read": true,
        "can_write": true
      },
      {
        "key": "password",
        "value": "password",
        "can_read": false,
        "can_write": true
      }
    ]
  },
  "resource": {
    "reference": "221000",
    "submission_reference": "J704-ZK5E",
    "claimant_count": 1,
    "submission_channel": "Web",
    "case_type": "Single",
    "jurisdiction": 2,
    "office_code": 22,
    "date_of_receipt": "2019-06-12T07:28:58.000Z",
    "administrator": null,
    "other_known_claimant_names": "",
    "discrimination_claims": [],
    "pay_claims": [],
    "desired_outcomes": [],
    "other_claim_details": "",
    "claim_details": "",
    "other_outcome": "",
    "send_claim_to_whistleblowing_entity": false,
    "miscellaneous_information": "",
    "employment_details": {
      "net_pay": 2000,
      "end_date": null,
      "gross_pay": 3000,
      "job_title": "agriculturist",
      "start_date": "2009-11-18",
      "found_new_job": null,
      "benefit_details": "Company car, private health care",
      "new_job_gross_pay": null,
      "new_job_start_date": null,
      "net_pay_period_type": "monthly",
      "gross_pay_period_type": "monthly",
      "notice_pay_period_type": null,
      "notice_period_end_date": null,
      "notice_pay_period_count": null,
      "enrolled_in_pension_scheme": true,
      "average_hours_worked_per_week": 38.0,
      "worked_notice_period_or_paid_in_lieu": null
    },
    "is_unfair_dismissal": false,
    "pdf_template_reference": "et1-v1-en",
    "secondary_claimants": [],
    "secondary_respondents": [],
    "primary_claimant": {
      "title": "Mr",
      "first_name": "First",
      "last_name": "Last",
      "address": {
        "building": "1",
        "street": "street",
        "locality": "locality",
        "county": "county",
        "post_code": "DE21 6ND"
      },
      "address_telephone_number": "01234 567890",
      "mobile_number": "01234 098765",
      "email_address": "test@digital.justice.gov.uk",
      "contact_preference": "Email",
      "gender": "Male",
      "date_of_birth": "1982-11-21",
      "fax_number": null,
      "special_needs": null
    },
    "primary_respondent": {
      "name": "dodgy_co",
      "address": {
        "building": "1",
        "street": "street",
        "locality": "locality",
        "county": "county",
        "post_code": "DE21 6ND"
      },
      "work_address_telephone_number": "",
      "address_telephone_number": "",
      "acas_number": null,
      "work_address": {
        "building": "1",
        "street": "street",
        "locality": "locality",
        "county": "county",
        "post_code": "DE21 6ND"
      },
      "alt_phone_number": "",
      "contact": "John Smith",
      "dx_number": "",
      "contact_preference": "email",
      "email_address": "john@dodgyco.com",
      "fax_number": "",
      "organisation_employ_gb": 10,
      "organisation_more_than_one_site": false,
      "employment_at_site_number": 5,
      "disability": true,
      "disability_information": "Lorem ipsum disability",
      "acas_certificate_number": "AC123456/78/90",
      "acas_exemption_code": null
    },
    "uploaded_files": [
      {
        "filename": "et1_first_last.pdf",
        "checksum": "ee2714b8b731a8c1e95dffaa33f89728",
        "url": "http://localhost:10000/devstoreaccount1/et-api-test-container/2Qnar7HebG8wtU7HrUqxjLPP?sp=r&sv=2016-05-31&se=2019-06-12T07%3A46%3A47Z&rscd=inline%3B+filename%3D%22et1_first_last.pdf%22%3B+filename*%3DUTF-8%27%27et1_first_last.pdf&rsct=application%2Fpdf&sr=b&sig=qcUQ4gonbWKjaUXsNQmRdSnR8wAsN%2FvpVwLgM%2FJFaIU%3D"
      },
      {
        "id": 22,
        "filename": "et1_First_Last.txt",
        "checksum": null,
        "url": "http://localhost:10000/devstoreaccount1/et-api-test-container/2Qnar7HebG8wtU7HrUqxjLPP?sp=r&sv=2016-05-31&se=2019-06-12T07%3A46%3A47Z&rscd=inline%3B+filename%3D%22et1_first_last.pdf%22%3B+filename*%3DUTF-8%27%27et1_first_last.pdf&rsct=application%2Fpdf&sr=b&sig=qcUQ4gonbWKjaUXsNQmRdSnR8wAsN%2FvpVwLgM%2FJFaIU%3D"
      }
    ]
  }
}

=end
FactoryBot.define do
  factory :export, class: ::EtCcdExport::Test::Json::Node do
    transient do
      claim_attrs { {} }
      claim_traits { [:default] }
      response_attrs { {} }
      response_traits { [:default] }
    end
    sequence(:id) {|idx| idx}
    external_system { build(:system) }
    resource { nil }

    trait :for_claim do
      resource { build(:claim, *claim_traits, **claim_attrs) }
      resource_type { 'Claim' }
    end

    trait :for_response do
      resource { build(:response, *response_traits, **response_attrs) }
      resource_type { 'Response' }
    end
  end
end
