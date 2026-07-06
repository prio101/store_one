# frozen_string_literal: true

Spree::Core::Engine.add_routes do
  namespace :admin, path: Spree.admin_path do
    resources :courier_integrations, only: [:index] do
      member do
        post :toggle
      end
    end
  end
end
