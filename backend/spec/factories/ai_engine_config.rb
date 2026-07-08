# frozen_string_literal: true

FactoryBot.define do
  factory :ai_engine_config, class: "Spree::AiEngineConfig" do
    store
    provider { "gemini" }
    api_key { "test-api-key-123" }
    ai_model_name { "gemini-2.0-flash" }
    temperature { 0.7 }
    max_output_tokens { 2048 }
    system_prompt { "You are a helpful assistant." }
    rate_limit_rpm { 60 }
    logging_enabled { true }
    active { true }
  end
end
