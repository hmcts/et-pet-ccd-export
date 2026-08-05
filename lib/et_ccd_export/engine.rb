module EtCcdExport
  class Engine < ::Rails::Engine
    isolate_namespace EtCcdExport
    config.generators.api_only = true
    config.generators.test_framework = :rspec

    config.autoload_paths << root.join('lib')
    config.eager_load_paths << root.join('lib')
  end
end
