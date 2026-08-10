module EtCcdExport
  class Engine < ::Rails::Engine
    isolate_namespace EtCcdExport
    config.generators.api_only = true
    config.generators.test_framework = :rspec

    config.autoload_paths << root.join('lib')
    config.eager_load_paths << root.join('lib')

    # Disable initializers when used not as a standalone application for now
    initializer "et_ccd_export.disable_embedded_initializers",
                before: :load_config_initializers do |app|
      unless app.class.name == "EtCcdExport::Application"
        config.paths["config/initializers"] = []
      end
    end
  end
end
