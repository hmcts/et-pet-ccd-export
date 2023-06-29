FactoryBot.define do
  factory :address, class: '::EtCcdExport::Test::Json::Node' do
    building { '1' }
    street { 'street' }
    locality { 'locality' }
    county { 'county' }
    post_code { 'post code' }

    trait :with_uk_country do
      country { 'United Kingdom' }
    end

    trait :with_other_country do
      country { 'Outside United Kingdom' }
    end
  end
end
