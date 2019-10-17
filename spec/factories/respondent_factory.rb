FactoryBot.define do
  factory :respondent, class: ::EtCcdExport::Test::Json::Node do
    trait :basic do
      sequence(:name) { |idx| "dodgy_co #{idx}" }
      address { build(:address) }
      work_address_telephone_number { "01234 567891" }
      address_telephone_number { "01234 567890" }
      work_address { build(:address) }
      alt_phone_number { "0333 321090" }
      contact { nil }
      dx_number { nil }
      contact_preference { nil }
      email_address { nil }
      fax_number { nil }
      organisation_employ_gb { nil }
      organisation_more_than_one_site { nil }
      employment_at_site_number { nil }
      disability { nil }
      disability_information { nil }
      acas_certificate_number { "AC123456/78/90" }
      acas_exemption_code { nil }
    end

    trait :full do
      sequence(:name) { |idx| "dodgy_co #{idx}" }
      address { build(:address) }
      work_address_telephone_number { "01234 567891" }
      address_telephone_number { "01234 567890" }
      work_address { build(:address) }
      alt_phone_number { "0333 321090" }
      contact { "John Smith" }
      dx_number { "" }
      contact_preference { "email" }
      email_address { "john@dodgyco.com" }
      fax_number { "" }
      organisation_employ_gb { 10 }
      organisation_more_than_one_site { false }
      employment_at_site_number { 5 }
      disability { true }
      disability_information { "Lorem ipsum disability" }
      acas_certificate_number { "AC123456/78/90" }
      acas_exemption_code { nil }
    end
  end
end
