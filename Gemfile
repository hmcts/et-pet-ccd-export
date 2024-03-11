source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
ruby '~> 3.2.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '7.1.3.2'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Sidekiq - Used to receive the jobs from the API service
gem 'sidekiq', '< 7'
gem 'sidekiq_alive', '~> 2.0'
gem 'sidekiq-failures', '~> 1.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Azure deployment so we need this
gem 'azure_env_secrets', git: 'https://github.com/hmcts/azure_env_secrets.git', tag: 'v1.0.1'

gem 'addressable', '~> 2.6'
gem 'rest-client', '~> 2.1'
gem 'jbuilder', '~> 2.10'
gem 'et_ccd_client', git: 'https://github.com/hmcts/et-ccd-client-ruby.git', tag: 'v0.6.1'
gem 'dotenv-rails', '~> 2.7'

group :development, :test do
  gem 'bundler-audit', '~> 0.9.1'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'et_full_system_control', git: 'https://github.com/hmcts/et-full-system-control.git', branch: 'main'
end

group :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'rspec_junit_formatter', '~> 0.6.0'
  gem 'factory_bot', '~> 6.1'
  gem 'jsonpath', '~> 1.1'
  gem 'et_fake_ccd', git: 'https://github.com/hmcts/et-fake-ccd.git', tag: 'v3.1.4'
  gem 'json_matchers', '~> 0.11.0'
  gem 'ice_nine', '~> 0.11.2'
  gem 'mock_redis', '~> 0.28'
  gem 'rspec-sidekiq', '~> 4.0'
  gem 'simplecov', '~> 0.22.0'
end

group :development do
  gem 'listen', '~> 3.5'
  gem 'rubocop', '~> 1.14'
  gem 'rubocop-rails', '~> 2.10', '>= 2.10.1'
  gem 'rubocop-rspec', '~> 2.3'
end


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "sentry-ruby", "~> 5.7"
gem "sentry-rails", "~> 5.7"
gem "sentry-sidekiq", "~> 5.7"
gem 'et_azure_insights', '0.3.2', git: 'https://github.com/hmcts/et-azure-insights.git', tag: 'v0.3.2'
gem 'application_insights', git: 'https://github.com/microsoft/ApplicationInsights-Ruby.git', ref: '5db6b4'
