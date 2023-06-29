FactoryBot.define do
  factory :employment_details, class: '::EtCcdExport::Test::Json::Node' do
    trait :employed do
      net_pay { 2000 }
      end_date { nil }
      gross_pay { 3000 }
      job_title { "agriculturist" }
      start_date { "2009-11-18" }
      found_new_job { nil }
      benefit_details { "Company car, private health care" }
      new_job_gross_pay { nil }
      new_job_start_date { nil }
      net_pay_period_type { "monthly" }
      gross_pay_period_type { "monthly" }
      notice_pay_period_type { nil }
      notice_period_end_date { nil }
      notice_pay_period_count { nil }
      enrolled_in_pension_scheme { true }
      average_hours_worked_per_week { 38.0 }
      worked_notice_period_or_paid_in_lieu { nil }
    end

    trait :no_longer_employed do
      employed
      end_date { '2011-11-18' }
    end

    trait :working_notice_period do
      employed
      end_date { (Date.today + 10).strftime('%Y-%m-%d') }
    end

    trait :blank do

    end
  end
end
