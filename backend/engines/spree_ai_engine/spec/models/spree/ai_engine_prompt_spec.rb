# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::AiEnginePrompt, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:ai_engine_work_task).class_name("Spree::AiEngineWorkTask") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:prompt_template) }

    it "validates name uniqueness per work task" do
      task = create(:ai_engine_work_task)
      create(:ai_engine_prompt, ai_engine_work_task: task, name: "default")
      duplicate = build(:ai_engine_prompt, ai_engine_work_task: task, name: "default")
      expect(duplicate).not_to be_valid
    end

    it "allows same name for different work tasks" do
      task1 = create(:ai_engine_work_task)
      task2 = create(:ai_engine_work_task)
      create(:ai_engine_prompt, ai_engine_work_task: task1, name: "default")
      prompt = build(:ai_engine_prompt, ai_engine_work_task: task2, name: "default")
      expect(prompt).to be_valid
    end
  end

  describe "scopes" do
    it ".active returns only active prompts" do
      active = create(:ai_engine_prompt, active: true)
      inactive = create(:ai_engine_prompt, active: false)
      expect(Spree::AiEnginePrompt.active).to include(active)
      expect(Spree::AiEnginePrompt.active).not_to include(inactive)
    end

    it ".defaults returns only default prompts" do
      default = create(:ai_engine_prompt, is_default: true)
      non_default = create(:ai_engine_prompt, is_default: false)
      expect(Spree::AiEnginePrompt.defaults).to include(default)
      expect(Spree::AiEnginePrompt.defaults).not_to include(non_default)
    end
  end

  describe "#render_template" do
    it "replaces variable placeholders" do
      prompt = build(:ai_engine_prompt, prompt_template: "Write about {{product_name}} by {{brand}}")
      result = prompt.render_template(product_name: "Widget", brand: "Acme")
      expect(result).to eq("Write about Widget by Acme")
    end

    it "handles missing variables gracefully" do
      prompt = build(:ai_engine_prompt, prompt_template: "Write about {{product_name}}")
      result = prompt.render_template(product_name: "Widget")
      expect(result).to eq("Write about Widget")
    end

    it "handles multiple occurrences of the same variable" do
      prompt = build(:ai_engine_prompt, prompt_template: "{{product_name}} is great. {{product_name}} rocks.")
      result = prompt.render_template(product_name: "Widget")
      expect(result).to eq("Widget is great. Widget rocks.")
    end
  end

  describe "default prompt management" do
    it "ensures only one default prompt per work task" do
      task = create(:ai_engine_work_task)
      prompt1 = create(:ai_engine_prompt, ai_engine_work_task: task, is_default: true)
      prompt2 = create(:ai_engine_prompt, ai_engine_work_task: task, is_default: true)

      prompt1.reload
      expect(prompt1.is_default).to be false
      expect(prompt2.is_default).to be true
    end
  end
end
