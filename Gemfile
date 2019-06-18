# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Sidekiq - Used to receive the jobs from the API service
gem 'sidekiq', '~> 5.2', '>= 5.2.7'
gem 'sidekiq_alive', '~> 1.1'
gem 'sidekiq-failures', '~> 1.0'

gem 'activesupport', '~> 5.2', '>= 5.2.3'
gem 'actionview', '~> 5.2', '>= 5.2.3'

# Azure deployment so we need this
gem 'azure_env_secrets', git: 'https://github.com/ministryofjustice/azure_env_secrets.git', tag: 'v0.1.3'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'

gem 'addressable', '~> 2.6'
gem 'rest-client', '~> 2.0', '>= 2.0.2'
gem 'jbuilder', '~> 2.9', '>= 2.9.1'
gem 'et_ccd_client', git: 'https://github.com/hmcts/et-ccd-client-ruby.git', tag: 'v0.1.1'

group :test do
  gem 'rspec', '~> 3.8'
  gem 'factory_bot', '~> 5.0', '>= 5.0.2'
  gem 'jsonpath', '~> 0.5.8'
end

group :develop do
  gem 'rubocop', '~> 0.71.0'
  gem 'rubocop-rspec', '~> 1.33'
end
