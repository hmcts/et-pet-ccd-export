require_relative '../../lib/ccd_client_sentry_error_middleware'
require_relative '../../lib/et_ccd_export/sidekiq/middleware/expose_job_hash_middleware'
require_relative '../../lib/et_ccd_export/sidekiq/batch'
default_redis_host = ENV.fetch('REDIS_HOST', 'localhost')
default_redis_port = ENV.fetch('REDIS_PORT', '6379')
default_redis_database = ENV.fetch('REDIS_DATABASE', '1')
default_redis_url = "redis://#{default_redis_host}:#{default_redis_port}/#{default_redis_database}"
redis_url = ENV.fetch('REDIS_URL', default_redis_url)

Sidekiq.configure_server do |config|
  redis_config = { url: redis_url }
  redis_config[:password] = ENV['REDIS_PASSWORD'] if ENV['REDIS_PASSWORD'].present?
  config.redis = redis_config
  config.error_handlers.unshift CcdClientSentryErrorMiddleware.new
  config.server_middleware do |chain|
    chain.add EtCcdExport::Sidekiq::Middleware::ExposeJobHashMiddleware
    chain.add EtCcdExport::Sidekiq::Middleware::MultiplesMiddleware
  end
  config.client_middleware do |chain|
    chain.add EtCcdExport::Sidekiq::Middleware::MultiplesClientMiddleware
  end
end

Sidekiq.configure_client do |config|
  redis_config = { url: redis_url }
  redis_config[:password] = ENV['REDIS_PASSWORD'] if ENV['REDIS_PASSWORD'].present?
  config.redis = redis_config
  config.client_middleware do |chain|
    chain.add EtCcdExport::Sidekiq::Middleware::MultiplesClientMiddleware
  end
end

Sidekiq.logger.level = ::Logger.const_get(ENV.fetch('RAILS_LOG_LEVEL', 'debug').upcase)
