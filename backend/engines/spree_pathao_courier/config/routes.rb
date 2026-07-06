# frozen_string_literal: true

Spree::Core::Engine.add_routes do
  namespace :admin, path: Spree.admin_path do
    resources :pathao_courier_configs,
              controller: '/spree/pathao_courier/admin/configs',
              except: [:destroy]

    resources :orders, only: [] do
      resources :shipments, only: [] do
        post :ship_with_pathao, on: :member,
             controller: '/spree/pathao_courier/admin/shipments'
      end

      # Courier tracking endpoints
      scope 'courier',
            controller: '/spree/pathao_courier/admin/courier',
            as: 'courier' do
        post 'estimate_cost'
        post 'confirm'
        get  'tracking'
      end
    end
  end
end
