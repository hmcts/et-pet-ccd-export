require 'sentry/test_helper'

RSpec.configure do |config|
  config.include Sentry::TestHelper
  config.around(:each, :sentry) do |example|
    setup_sentry_test
    example.run
  ensure
    teardown_sentry_test
  end
end
