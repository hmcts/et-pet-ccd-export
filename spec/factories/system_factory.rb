FactoryBot.define do
  factory :system, class: ::EtCcdExport::Test::Json::Node do
    sequence(:name) { |idx| "CCD Instance #{idx}" }
    sequence(:reference) { |idx| "ccd_instance_#{idx}" }
    office_codes { [1,2,3,4,5] }
    export_feedback_queue { 'export_feedback_queue' }
    enabled { true }
    configurations do
      [
        build(:system_configuration, key: 'user_id', value: '22'),
        build(:system_configuration, key: 'user_role', value: 'caseworker,caseworker-test,caseworker-employment-tribunal-manchester,caseworker-employment,caseworker-employment-tribunal-manchester-caseofficer,caseworker-publiclaw-localAuthority'),
        build(:system_configuration, key: 'case_type_id', value: 'Manchester_Dev'),
        build(:system_configuration, key: 'multiples_case_type_id', value: 'Manchester_Multiples_Dev')
      ]
    end
    trait :auto_accept_multiples do
      configurations do
        [
          build(:system_configuration, key: 'case_type_id', value: 'Manchester_Dev'),
          build(:system_configuration, key: 'multiples_case_type_id', value: 'Manchester_Multiples_Dev'),
          build(:system_configuration, key: 'multiples_auto_accept', value: 'true')
        ]
      end
    end
  end
end
