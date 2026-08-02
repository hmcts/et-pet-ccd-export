module EtCcdExport
  class Engine < ::Rails::Engine
    isolate_namespace EtCcdExport
    config.generators.api_only = true
    config.generators.test_framework = :rspec
  end
end
