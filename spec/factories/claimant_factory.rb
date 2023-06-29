FactoryBot.define do
  factory :claimant, class: '::EtCcdExport::Test::Json::Node' do
    trait(:default) do
      title { "Mr" }
      first_name { "First" }
      last_name { "Last" }
      address { build(:address) }
      address_telephone_number { "01234 567890" }
      mobile_number { "01234 098765" }
      email_address { "test@digital.justice.gov.uk" }
      contact_preference { "email" }
      gender { "N/K" }
      date_of_birth { "1982-11-21" }
      fax_number { nil }
      special_needs { "My special needs are as follows" }
    end

    trait(:from_csv) do
      title { "Mrs" }
      sequence(:first_name) { |idx| "First#{idx}" }
      sequence(:last_name) { |idx| "Last#{idx}" }
      address { build(:address) }
      date_of_birth { "1982-11-21" }
    end

    trait :csv_tamara_swift do
      title { "Mrs" }
      first_name { "tamara" }
      last_name { "swift" }
      association :address,
                  building: '71088',
                  street: 'nova loaf',
                  locality: 'keelingborough',
                  county: 'hawaii',
                  post_code: 'yy9a 2la'
      date_of_birth { "1957-07-06" }
    end

    trait :csv_diana_flatley do
      title { "Mr" }
      first_name { "diana" }
      last_name { "flatley" }
      association :address,
                  building: '66262',
                  street: 'feeney station',
                  locality: 'west jewelstad',
                  county: 'montana',
                  post_code: 'r8p 0jb'
      date_of_birth { "1986-09-24" }
    end

    trait :csv_mariana_mccullough do
      title { "Ms" }
      first_name { "mariana" }
      last_name { "mccullough" }
      association :address,
                  building: '819',
                  street: 'mitchell glen',
                  locality: 'east oliverton',
                  county: 'south carolina',
                  post_code: 'uh2 4na'
      date_of_birth { "1992-08-10" }
    end

    trait :csv_eden_upton do
      title { "Mr" }
      first_name { "eden" }
      last_name { "upton" }
      association :address,
                  building: '272',
                  street: 'hoeger lodge',
                  locality: 'west roxane',
                  county: 'new mexico',
                  post_code: 'pd3p 8ns'
      date_of_birth { "1965-01-09" }
    end

    trait :csv_annie_schulist do
      title { "Miss" }
      first_name { "annie" }
      last_name { "schulist" }
      association :address,
                  building: '3216',
                  street: 'franecki turnpike',
                  locality: 'amaliahaven',
                  county: 'washington',
                  post_code: 'f3 6nl'
      date_of_birth { "1988-07-19" }
    end

    trait :csv_thad_johns do
      title { "Mrs" }
      first_name { "thad" }
      last_name { "johns" }
      association :address,
                  building: '66462',
                  street: 'austyn trafficway',
                  locality: 'lake valentin',
                  county: 'new jersey',
                  post_code: 'rt49 2qa'
      date_of_birth { "1993-06-14" }
    end

    trait :csv_coleman_kreiger do
      title { "Miss" }
      first_name { "coleman" }
      last_name { "kreiger" }
      association :address,
                  building: '934',
                  street: 'whitney burgs',
                  locality: 'emmanuelhaven',
                  county: 'alaska',
                  post_code: 'td6b 6jj'
      date_of_birth { "1960-05-12" }
    end

    trait :csv_jenson_deckow do
      title { "Ms" }
      first_name { "jensen" }
      last_name { "deckow" }
      association :address,
                  building: '1230',
                  street: 'guiseppe courts',
                  locality: 'south candacebury',
                  county: 'arkansas',
                  post_code: 'u0p 6al'
      date_of_birth { "1970-04-27" }
    end

    trait :csv_darien_bahringer do
      title { "Mr" }
      first_name { "darien" }
      last_name { "bahringer" }
      association :address,
                  building: '3497',
                  street: 'wilkinson junctions',
                  locality: 'kihnview',
                  county: 'hawaii',
                  post_code: 'z2e 3wl'
      date_of_birth { "1958-06-29" }
    end

    trait :csv_eulalia_hammes do
      title { "Mrs" }
      first_name { "eulalia" }
      last_name { "hammes" }
      association :address,
                  building: '376',
                  street: 'krajcik wall',
                  locality: 'south ottis',
                  county: 'idaho',
                  post_code: 'kg2 5aj'
      date_of_birth { "1998-10-04" }
    end

  end
end
