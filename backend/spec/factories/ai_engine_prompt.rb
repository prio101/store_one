# frozen_string_literal: true

FactoryBot.define do
  factory :ai_engine_prompt, class: "Spree::AiEnginePrompt" do
    association :ai_engine_work_task, factory: :ai_engine_work_task
    name { "default" }
    prompt_template { "Write a product description for {{product_name}} by {{brand}}." }
    is_default { true }
    active { true }
  end
end
