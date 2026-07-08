# frozen_string_literal: true

FactoryBot.define do
  factory :ai_engine_work_task, class: "Spree::AiEngineWorkTask" do
    association :ai_engine_config, factory: :ai_engine_config
    name { "product_description" }
    description { "Generate product descriptions" }
    active { true }
  end
end
