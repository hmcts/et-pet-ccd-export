FactoryBot.define do
  factory :system, class: ::EtCcdExport::Test::Json::Node do
    sequence(:name) { |idx| "CCD Instance #{idx}" }
    sequence(:reference) { |idx| "ccd_instance_#{idx}" }
    office_codes { [1,2,3,4,5] }
    enabled { true }
    configurations do
      [
        build(:system_configuration, key: 'user_id', value: '22'),
        build(:system_configuration, key: 'user_role', value: 'caseworker,caseworker-test,caseworker-employment-tribunal-manchester,caseworker-employment,caseworker-employment-tribunal-manchester-caseofficer,caseworker-publiclaw-localAuthority'),
        build(:system_configuration, key: 'case_type_id', value: 'Manchester_Dev'),
        build(:system_configuration, key: 'multiples_case_type_id', value: 'Manchester_Multiples_Dev'),
      ]
    end
    # config do
    #   {
    #     url: 'http://someurl.com',
    #     idam_service_token_exchange_url: 'http://localhost:4502/testing-support/lease',
    #     idam_user_token_exchange_url: 'http://localhost:4501/testing-support/lease',
    #     create_case_url: 'http://localhost:4452/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/cases',
    #     initiate_case_url: 'http://localhost:4452/caseworkers/{uid}/jurisdictions/{jid}/case-types/{ctid}/event-triggers/{etid}/token',
    #     user_id: 22,
    #     user_role: 'caseworker,caseworker-test,caseworker-employment-tribunal-manchester,caseworker-employment,caseworker-employment-tribunal-manchester-caseofficer,caseworker-publiclaw-localAuthority',
    #     secret: 'AAAAAAAAAAAAAAAC',
    #     jurisdiction_id: 'EMPLOYMENT',
    #     case_type_id: 'Manchester_Dev',
    #     initiate_claim_event_id: 'initiateCase'
    #   }
    # end
  end
end
