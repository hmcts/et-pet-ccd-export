require 'sidekiq/testing'
require 'et_ccd_export/sidekiq/batch'
::Sidekiq.configure_client do |c|
  c.client_middleware do |chain|
    chain.add EtCcdExport::Sidekiq::Middleware::MultiplesClientMiddleware
  end
end
::Sidekiq::Testing.server_middleware do |chain|
  chain.add ::EtCcdExport::Sidekiq::Middleware::ExposeJobHashMiddleware
  chain.add ::EtCcdExport::Sidekiq::Middleware::MultiplesMiddleware
end

RSpec.configure do |c|
  c.before do
    ::Sidekiq.configure_client do |c|
      c.redis = ConnectionPool.new(timeout: 60, size: 1) do
        MockRedis.new
      end
    end

    ::Sidekiq::Worker.clear_all
  end
end
