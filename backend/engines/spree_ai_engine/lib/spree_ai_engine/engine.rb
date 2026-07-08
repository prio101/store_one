# frozen_string_literal: true

module SpreeAiEngine
  class Engine < ::Rails::Engine
    isolate_namespace SpreeAiEngine

    config.autoload_paths += %W[
      #{config.root}/app/services
    ]

    initializer :append_migrations do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths["db/migrate"].expanded.each do |p|
          app.config.paths["db/migrate"] << p
        end
      end
    end

    initializer "spree_ai_engine.navigation" do
      Rails.application.config.after_initialize do
        Spree.admin.navigation.sidebar.add :ai_settings,
          label: "AI Settings",
          url: -> { Spree::Core::Engine.routes.url_helpers.admin_ai_engine_configs_path },
          icon: "cpu",
          position: 90
      end
    end
  end
end
