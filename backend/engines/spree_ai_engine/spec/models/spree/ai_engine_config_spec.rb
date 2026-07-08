# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::AiEngineConfig, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:store).class_name("Spree::Store") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_inclusion_of(:provider).in_array(%w[gemini openai]) }
    it { is_expected.to validate_presence_of(:api_key) }
    it { is_expected.to validate_presence_of(:ai_model_name) }

    it "validates temperature range" do
      config = build(:ai_engine_config)
      config.temperature = -0.1
      expect(config).not_to be_valid
      expect(config.errors[:temperature]).to include("must be greater than or equal to 0")
    end

    it "validates store uniqueness" do
      store = create(:store)
      create(:ai_engine_config, store: store)
      duplicate = build(:ai_engine_config, store: store)
      expect(duplicate).not_to be_valid
    end
  end

  describe "encryption" do
    it "encrypts api_key" do
      config = create(:ai_engine_config, api_key: "test-api-key-123")
      config.reload
      expect(config.api_key).to eq("test-api-key-123")
    end
  end

  describe "scopes" do
    it ".active returns only active configs" do
      active = create(:ai_engine_config, active: true)
      inactive = create(:ai_engine_config, active: false)
      expect(Spree::AiEngineConfig.active).to include(active)
      expect(Spree::AiEngineConfig.active).not_to include(inactive)
    end
  end

  describe "#provider_label" do
    it "returns 'Google Gemini' for gemini provider" do
      config = build(:ai_engine_config, provider: "gemini")
      expect(config.provider_label).to eq("Google Gemini")
    end

    it "returns 'OpenAI' for openai provider" do
      config = build(:ai_engine_config, provider: "openai")
      expect(config.provider_label).to eq("OpenAI")
    end
  end
end
