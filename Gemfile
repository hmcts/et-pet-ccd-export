source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.2.1'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Sidekiq - Used to receive the jobs from the API service
gem 'sidekiq', '~> 6.1'
gem 'sidekiq_alive', '~> 2.0'
gem 'sidekiq-failures', '~> 1.0'
gem 'sidekiq-batch', '~> 0.1.5'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Azure deployment so we need this
gem 'azure_env_secrets', git: 'https://github.com/ministryofjustice/azure_env_secrets.git', tag: 'v0.1.3'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'

gem 'addressable', '~> 2.6'
gem 'rest-client', '~> 2.1'
gem 'jbuilder', '~> 2.10'
gem 'et_ccd_client', '~> 0.3'
gem 'dotenv-rails', '~> 2.7'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :test do
  gem 'rspec-rails', '~> 4.0'
  gem 'factory_bot', '~> 6.1'
  gem 'jsonpath', '~> 1.1'
  gem 'et_fake_ccd', '~> 1.1'
  gem 'json_matchers', '~> 0.11.0'
  gem 'ice_nine', '~> 0.11.2'
  gem 'mock_redis', '~> 0.27'
end

group :development do
  gem 'listen', '~> 3.4'
  gem 'rubocop', '~> 1.11'
  gem 'rubocop-rspec', '~> 2.1'
end


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'sentry-raven', '~> 3.1'
gem 'et_azure_insights', '0.2.12', git: 'https://github.com/hmcts/et-azure-insights.git', tag: 'v0.2.12'
gem 'application_insights', git: 'https://github.com/microsoft/ApplicationInsights-Ruby.git', ref: '5db6b4'
