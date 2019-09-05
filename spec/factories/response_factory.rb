FactoryBot.define do
  factory :response, class: ::EtCcdExport::Test::Json::Node do
    transient do
      respondent_traits { [:full] }
      respondent_attrs { {} }
      representative_traits { [:full] }
      representative_attrs { {} }
      office_code { 24 }
    end

    trait :default do
      with_pdf_file
      sequence :reference do |n|
        "#{office_code}#{20000000 + n}00"
      end

      agree_with_claimant_notice { false }
      agree_with_claimant_pension_benefits { false }
      agree_with_claimants_description_of_job_or_title { false }
      agree_with_claimants_hours { false }
      agree_with_early_conciliation_details { false }
      agree_with_earnings_details { false }
      agree_with_employment_dates { false }
      case_number { "#{office_code}54321/2017" }
      claim_information { "lorem ipsum info" }
      claimants_name { "Oliva Medhurst" }
      continued_employment { false }
      date_of_receipt { "2019-09-03T06:17:13.584Z" }
      defend_claim { true }
      defend_claim_facts { "lorem ipsum defence" }
      disagree_claimant_notice_reason { "lorem ipsum notice reason" }
      disagree_claimant_pension_benefits_reason { "lorem ipsum claimant pension" }
      disagree_claimants_job_or_title { "lorem ipsum job title" }
      disagree_conciliation_reason { "lorem ipsum conciliation" }
      disagree_employment { "lorem ipsum employment" }
      email_receipt { "sivvoy.taing@hmcts.net" }
      employment_end { "2017-12-31" }
      employment_start { "2017-01-01" }
      make_employer_contract_claim { true }
      queried_pay_before_tax_period { "Monthly" }
      queried_take_home_pay_period { "Monthly" }
      queried_hours { 32.0 }
      queried_pay_before_tax { 1000.0 }
      queried_take_home_pay { 900.0 }
    end

    uploaded_files { [] }

    after(:build) do |response, evaluator|
      response.respondent = build(:respondent, *evaluator.respondent_traits, **evaluator.respondent_attrs) if response.respondent.blank?
      response.representative = build(:representative, *evaluator.representative_traits, **evaluator.representative_attrs) unless evaluator.representative_traits.nil?
    end

    trait :with_pdf_file do
      after(:build) do |response, _evaluator|
        response.uploaded_files << build(:uploaded_file, :example_response_pdf)
      end
    end

    trait :with_rtf_file do
      after(:build) do |response, _evaluator|
        response.uploaded_files << build(:uploaded_file, :example_response_rtf)
      end
    end

    trait :no_representative do
      representative_traits { nil }
    end
  end
end
