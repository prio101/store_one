# frozen_string_literal: true

module SpreeInstagramPublisher
  class Engine < ::Rails::Engine
    isolate_namespace SpreeInstagramPublisher

    initializer 'spree_instagram_publisher.append_migrations' do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    initializer 'spree_instagram_publisher.navigation' do
      Rails.application.config.after_initialize do
        Spree.admin.navigation.sidebar.add :instagram_settings,
          label: 'Instagram',
          url: -> { Spree::Core::Engine.routes.url_helpers.admin_instagram_publisher_configs_path },
          icon: 'camera',
          position: 96,
          if: -> { can?(:manage, Spree::InstagramPublisherConfig) }
      end
    end
  end
end
