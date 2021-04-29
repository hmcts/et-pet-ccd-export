FactoryBot.define do
  factory :system, class: ::EtCcdExport::Test::Json::Node do
    sequence(:name) { |idx| "CCD Instance #{idx}" }
    sequence(:reference) { |idx| "ccd_instance_#{idx}" }
    office_codes { [1,2,3,4,5] }
    export_feedback_queue { 'export_feedback_queue' }
    enabled { true }
    configurations do
      [
        build(:system_configuration, key: 'case_type_id', value: 'Manchester'),
        build(:system_configuration, key: 'multiples_case_type_id', value: 'Manchester_Multiples')
      ]
    end
    trait :auto_accept_multiples do
      configurations do
        [
          build(:system_configuration, key: 'case_type_id', value: 'Manchester'),
          build(:system_configuration, key: 'multiples_case_type_id', value: 'Manchester_Multiples'),
          build(:system_configuration, key: 'multiples_auto_accept', value: 'true')
        ]
      end
    end

    trait :limited_multiples_count do
      configurations do
        [
          build(:system_configuration, key: 'case_type_id', value: 'Manchester'),
          build(:system_configuration, key: 'multiples_case_type_id', value: 'Manchester_Multiples'),
          build(:system_configuration, key: 'multiples_max_claimant_count', value: '1')
        ]
      end
    end
  end
end
