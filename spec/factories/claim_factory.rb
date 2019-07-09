FactoryBot.define do
  factory :claim, class: ::EtCcdExport::Test::Json::Node do
    transient do
      number_of_claimants { 1 }
      number_of_respondents { 1 }
      primary_respondent_traits { [:full] }
      primary_respondent_attrs { {} }
      primary_claimant_attrs { {} }
      primary_claimant_traits { [:default] }
      secondary_claimant_traits { [:mr_first_last] }
      secondary_respondent_traits { [:basic] }
      secondary_respondent_attrs { {} }
      primary_representative_traits { [:full] }
      primary_representative_attrs { {} }
      employment_details_traits { [:employed] }
      employment_details_attrs { {} }
    end

    trait :default do
      with_pdf_file
      sequence :reference do |n|
        "#{office_code}#{20000000 + n}00"
      end

      sequence :submission_reference do |n|
        "J704-ZK5E#{n}"
      end
      claimant_count { number_of_claimants }
      submission_channel { "Web" }
      case_type { "Single" }
      jurisdiction { 2 }
      office_code { 22 }
      date_of_receipt { "2019-06-12T07:28:58.000Z" }
      other_known_claimant_names { "James Blunt, Punky Brewsters, Shirley Temple" }
      discrimination_claims { ["sex_including_equal_pay"] }
      pay_claims { ["redundancy"] }
      desired_outcomes { ["compensation_only"] }
      other_claim_details { "This is the other claim details field" }
      claim_details { "This is the claim details field" }
      other_outcome { "I would like 50,000GBP for the stress this has caused me" }
      send_claim_to_whistleblowing_entity { false }
      miscellaneous_information { nil }
      is_unfair_dismissal { false }
    end

    secondary_claimants { [] }
    secondary_respondents { [] }
    uploaded_files { [] }

    after(:build) do |claim, evaluator|
      claim.primary_claimant = build(:claimant, *evaluator.primary_claimant_traits, **evaluator.primary_claimant_attrs) if claim.primary_claimant.blank? && evaluator.number_of_claimants > 0
      claim.secondary_claimants.concat build_list(:claimant, evaluator.number_of_claimants - 1, *evaluator.secondary_claimant_traits) unless evaluator.number_of_claimants < 1
      claim.primary_respondent = build(:respondent, *evaluator.primary_respondent_traits, **evaluator.primary_respondent_attrs) if claim.primary_respondent.blank? && evaluator.number_of_respondents > 0
      claim.secondary_respondents.concat build_list(:respondent, evaluator.number_of_respondents - 1, *evaluator.secondary_respondent_traits, **evaluator.secondary_respondent_attrs) unless evaluator.number_of_respondents < 1
      claim.claimant_count = evaluator.number_of_claimants
      claim.primary_representative = build(:representative, *evaluator.primary_representative_traits, **evaluator.primary_representative_attrs) unless evaluator.primary_representative_traits.nil?
      claim.employment_details = build(:employment_details, *evaluator.employment_details_traits, **evaluator.employment_details_attrs)
    end

    trait :with_pdf_file do
      after(:build) do |claim, _evaluator|
        claim.uploaded_files << build(:uploaded_file, :example_pdf)
      end
    end

    trait :with_rtf_file do
      after(:build) do |claim, _evaluator|
        claim.uploaded_files << build(:uploaded_file, :example_claim_rtf)
      end
    end

    trait :with_claimants_csv_file do
      after(:build) do |claim, _evaluator|
        claim.uploaded_files << build(:uploaded_file, :example_claim_claimants_csv)
      end
    end

    trait :no_representative do
      primary_representative_traits { [] }
    end

    trait :default_multiple_claimants do
      default
      secondary_claimants do
        [
          build(:claimant, :tamara_swift),
          build(:claimant, :diana_flatley),
          build(:claimant, :mariana_mccullough),
          build(:claimant, :eden_upton),
          build(:claimant, :annie_schulist),
          build(:claimant, :thad_johns),
          build(:claimant, :coleman_kreiger),
          build(:claimant, :jenson_deckow),
          build(:claimant, :darien_bahringer),
          build(:claimant, :eulalia_hammes)
        ]
      end
      uploaded_files { [build(:uploaded_file, :example_data), build(:uploaded_file, :example_claim_claimants_csv)] }
    end
  end
end
