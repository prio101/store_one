# frozen_string_literal: true

Spree::Core::Engine.add_routes do
  namespace :admin, path: Spree.admin_path do
    resources :ai_engine_configs,
              path: "ai-engine-configs",
              controller: "/spree/ai_engine/admin/configs" do
      member do
        post :test_connection
      end

      resources :ai_engine_work_tasks,
                path: "work-tasks",
                controller: "/spree/ai_engine/admin/work_tasks" do
        resources :ai_engine_prompts,
                  path: "prompts",
                  controller: "/spree/ai_engine/admin/prompts"
      end
    end

    post "ai-engine/generate",
         to: "/spree/ai_engine/admin/products#generate",
         as: :generate_ai_engine_product
  end
end
