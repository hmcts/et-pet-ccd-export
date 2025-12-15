require_relative '../../lib/ccd_client_sentry_error_middleware'
require_relative '../../lib/et_ccd_export/sidekiq/middleware/expose_job_hash_middleware'
require_relative '../../lib/et_ccd_export/sidekiq/batch'
require 'et_ccd_export/sidekiq/middleware/sentry_middleware'
config = Rails.application.config
redis_url = config.redis_url

Sidekiq.configure_server do |server_config|
  redis_config = { url: redis_url }
  redis_config[:password] = ENV['REDIS_PASSWORD'] if ENV['REDIS_PASSWORD'].present?
  server_config.redis = redis_config
  server_config.error_handlers.unshift CcdClientSentryErrorMiddleware.new
  server_config.server_middleware do |chain|
    chain.add EtCcdExport::Sidekiq::Middleware::ExposeJobHashMiddleware
    chain.add EtCcdExport::Sidekiq::Middleware::MultiplesMiddleware
    chain.add EtCcdExport::Sidekiq::Middleware::SentryMiddleware
  end
  server_config.client_middleware do |chain|
    chain.add EtCcdExport::Sidekiq::Middleware::MultiplesClientMiddleware
  end
end

Sidekiq.configure_client do |client_config|
  redis_config = { url: redis_url }
  redis_config[:password] = ENV['REDIS_PASSWORD'] if ENV['REDIS_PASSWORD'].present?
  client_config.redis = redis_config
  client_config.client_middleware do |chain|
    chain.add EtCcdExport::Sidekiq::Middleware::MultiplesClientMiddleware
  end
end

Sidekiq.logger.level = Logger.const_get(ENV.fetch('RAILS_LOG_LEVEL', 'debug').upcase)
