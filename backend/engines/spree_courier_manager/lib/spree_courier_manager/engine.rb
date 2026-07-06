# frozen_string_literal: true

module SpreeCourierManager
  class Engine < ::Rails::Engine
    isolate_namespace SpreeCourierManager

    initializer 'spree_courier_manager.assets' do |app|
      app.config.assets.paths << root.join('app/assets/images')
    end

    initializer 'spree_courier_manager.append_migrations' do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    initializer 'spree_courier_manager.navigation' do
      Rails.application.config.after_initialize do
        Spree.admin.navigation.sidebar.add :couriers,
          label: :couriers,
          url: :admin_courier_integrations_path,
          icon: 'truck',
          position: 85,
          if: -> { can?(:manage, Spree::CourierIntegration) }
      end
    end
  end
end
