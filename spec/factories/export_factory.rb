FactoryBot.define do
  factory :export, class: '::EtCcdExport::Test::Json::Node' do
    transient do
      claim_attrs { {} }
      claim_traits { [:default] }
      response_attrs { {} }
      response_traits { [:default] }
    end
    sequence(:id) { |idx| idx }
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

    trait :limited_multiples_count do
      external_system { build(:system, :limited_multiples_count) }
    end

    trait :update do # rubocop:disable Lint/EmptyBlock

    end
  end
end
