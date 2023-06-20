FactoryBot.define do
  factory :system_configuration, class: '::EtCcdExport::Test::Json::Node' do
    key { 'key' }
    value { 'value' }
  end
end
