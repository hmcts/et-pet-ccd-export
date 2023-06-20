FactoryBot.define do
  factory :representative, class: '::EtCcdExport::Test::Json::Node' do
    trait :full do
      name { "Rep Name" }
      organisation_name { "Org name" }
      address { build(:address) }
      address_telephone_number { "01234 565899" }
      mobile_number { "07771 666555" }
      email_address { "test@email.com" }
      representative_type { "Solicitor" }
      dx_number { "dx1234567890" }
      reference { "rep ref" }
      contact_preference { "email" }
      fax_number { "01234 555666" }
    end

    trait :basic do
      name { "Rep Name" }
      organisation_name { "Org name" }
      address { build(:address) }
      address_telephone_number { "01234 565899" }
      mobile_number { "07771 666555" }
      email_address { "test@email.com" }
      representative_type { "Solicitor" }
      dx_number { "dx1234567890" }
      reference { nil }
      contact_preference { nil }
      fax_number { nil }
    end
  end
end
