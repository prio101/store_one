# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::AiEngineWorkTask, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:ai_engine_config).class_name("Spree::AiEngineConfig") }
    it { is_expected.to have_many(:ai_engine_prompts).class_name("Spree::AiEnginePrompt").with_foreign_key(:ai_engine_work_task_id) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "validates name inclusion" do
      task = build(:ai_engine_work_task, name: "product_description")
      expect(task).to be_valid

      task.name = "invalid_task"
      expect(task).not_to be_valid
      expect(task.errors[:name]).to include("is not included in the list")
    end

    it "validates name uniqueness per config" do
      config = create(:ai_engine_config)
      create(:ai_engine_work_task, ai_engine_config: config, name: "product_description")
      duplicate = build(:ai_engine_work_task, ai_engine_config: config, name: "product_description")
      expect(duplicate).not_to be_valid
    end

    it "allows same name for different configs" do
      config1 = create(:ai_engine_config)
      config2 = create(:ai_engine_config)
      create(:ai_engine_work_task, ai_engine_config: config1, name: "product_description")
      task = build(:ai_engine_work_task, ai_engine_config: config2, name: "product_description")
      expect(task).to be_valid
    end
  end

  describe "scopes" do
    it ".active returns only active tasks" do
      active = create(:ai_engine_work_task, active: true)
      inactive = create(:ai_engine_work_task, active: false)
      expect(Spree::AiEngineWorkTask.active).to include(active)
      expect(Spree::AiEngineWorkTask.active).not_to include(inactive)
    end
  end

  describe "#label" do
    it "converts snake_case to Title Case" do
      task = build(:ai_engine_work_task, name: "product_description")
      expect(task.label).to eq("Product Description")
    end

    it "handles single word names" do
      task = build(:ai_engine_work_task, name: "custom")
      expect(task.label).to eq("Custom")
    end
  end

  describe "name normalization" do
    it "downcases and normalizes spaces/hyphens to underscores" do
      task = create(:ai_engine_work_task, name: "Product Description")
      expect(task.name).to eq("product_description")
    end

    it "strips whitespace" do
      task = create(:ai_engine_work_task, name: "  product_description  ")
      expect(task.name).to eq("product_description")
    end
  end

  describe "dependent destroy" do
    it "destroys associated prompts" do
      config = create(:ai_engine_config)
      task = create(:ai_engine_work_task, ai_engine_config: config)
      prompt = create(:ai_engine_prompt, ai_engine_work_task: task)

      expect { task.destroy }.to change(Spree::AiEnginePrompt, :count).by(-1)
    end
  end
end
