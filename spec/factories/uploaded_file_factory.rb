FactoryBot.define do
  factory :uploaded_file, class: '::EtCcdExport::Test::Json::Node' do
    filename { nil }
    url { nil }
    content_type { nil }

    trait :example_pdf do
      filename { "et1_chloe_goodwin_trimmed.pdf" }
      url { "http://dummy.com/examplepdf" }
      content_type { "application/pdf" }
    end

    trait :example_acas_pdf do
      filename { "acas_naughty_boy.pdf" }
      url { "http://dummy.com/examplepdf" }
      content_type { "application/pdf" }
    end

    trait :example_response_pdf do
      filename { "et3_atos_export.pdf" }
      url { "http://dummy.com/examplepdf" }
      content_type { "application/pdf" }
    end

    trait :example_claim_claimants_csv do
      filename { 'et1a_first_last.csv' }
      url { "http://dummy.com/examplecsv" }
      content_type { "text/csv" }
    end

    trait :unwanted_claim_file do
      filename { 'et1_First_Last.txt' }
      url { "http://dummy.com/first_last.txt" }
      content_type { "text/plain" }
    end

    trait :example_claim_details do
      filename { 'et1_attachment_First_Last.pdf' }
      url { "http://dummy.com/examplepdf" }
      content_type { "application/pdf" }
    end
  end
end
