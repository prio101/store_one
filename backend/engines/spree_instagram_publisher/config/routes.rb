# frozen_string_literal: true

Spree::Core::Engine.add_routes do
  namespace :admin, path: Spree.admin_path do
    resources :instagram_publisher_configs,
              controller: '/spree/instagram_publisher/admin/configs',
              except: [:destroy] do
      member do
        post :publish_product
      end
    end
  end
end
