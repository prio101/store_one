# frozen_string_literal: true

module SpreePathaoCourier
  class Engine < ::Rails::Engine
    isolate_namespace SpreePathaoCourier

    initializer 'spree_pathao_courier.eager_load_error_classes' do
      require_dependency 'spree/pathao_courier/error'
    end

    initializer 'spree_pathao_courier.append_migrations' do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    initializer 'spree_pathao_courier.importmap' do |app|
      app.importmap.pin_all_from root.join('app/javascript/controllers'), under: 'controllers'
    end
  end
end
