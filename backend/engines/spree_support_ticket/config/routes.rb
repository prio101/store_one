# frozen_string_literal: true

Spree::Core::Engine.add_routes do
  # Admin routes
  namespace :admin, path: Spree.admin_path do
    resources :support_tickets,
              controller: '/spree/support_ticket_system/admin/tickets',
              only: [:index, :show, :update] do
      member do
        post :assign
        post :resolve
        post :update_status
        post :create_message
      end
    end
  end

  # User-facing API routes
  namespace :api do
    namespace :v3 do
      namespace :store do
        resources :support_tickets,
                  controller: '/spree/support_ticket_system/user_tickets',
                  only: [:index, :show, :create] do
          post :messages, on: :member, action: :create_message
        end
      end
    end
  end
end
