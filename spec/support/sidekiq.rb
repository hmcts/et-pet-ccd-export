require 'sidekiq/testing'
::Sidekiq.configure_client do |c|
  c.redis = ConnectionPool.new(:timeout => 60, :size => 1) do
    MockRedis.new
  end
end
::Sidekiq::Testing.server_middleware do |chain|
  chain.add ::Sidekiq::Batch::Middleware::ServerMiddleware
  chain.add ::EtCcdExport::Sidekiq::Middleware::ExposeJobHash
end

RSpec.configure do |c|
  c.before do
    ::Sidekiq::Worker.clear_all
  end
end