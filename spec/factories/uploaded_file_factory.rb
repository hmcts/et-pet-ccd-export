FactoryBot.define do
  factory :uploaded_file, class: ::EtCcdExport::Test::Json::Node do
    filename { nil }
    url { nil }
    content_type { nil }

    trait :example_pdf do
      filename { "et1_chloe_goodwin.pdf" }
      url { "http://dummy.com/et1_chloe_goodwin.pdf" }
      content_type { "application/pdf" }
    end

    trait :example_claim_claimants_csv do
      filename { 'et1a_first_last.csv' }
      url { "http://dummy.com/et1_chloe_goodwin.csv" }
      content_type { "text/csv" }
    end

    trait :unwanted_claim_file do
      filename { 'unwanted.txt' }
      url { "http://dummy.com/unwanted.txt" }
      content_type { "text/plain" }
    end
  end
end
