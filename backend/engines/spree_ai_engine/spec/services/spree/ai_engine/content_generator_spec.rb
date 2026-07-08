# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::AiEngine::ContentGenerator, type: :model do
  let(:config) { create(:ai_engine_config, provider: "gemini") }
  let(:work_task) { create(:ai_engine_work_task, ai_engine_config: config, name: "product_description") }
  let(:prompt) do
    create(:ai_engine_prompt,
      ai_engine_work_task: work_task,
      name: "default",
      prompt_template: "Write about {{product_name}} by {{brand}}.",
      is_default: true
    )
  end

  describe "#generate" do
    context "with a valid work task and prompt" do
      before do
        prompt # ensure it exists

        provider_instance = instance_double(Spree::AiEngine::GeminiProvider)
        allow(SpreeAiEngine).to receive(:provider_for).with(config).and_return(provider_instance)
        allow(provider_instance).to receive(:generate).with(
          prompt: "Write about Widget by Acme.",
          system_prompt: config.system_prompt
        ).and_return("A great Widget by Acme.")
      end

      it "resolves work task and prompt, renders template, and calls provider" do
        result = config.generate_content(
          task_name: "product_description",
          variables: { product_name: "Widget", brand: "Acme" }
        )

        expect(result).to eq("A great Widget by Acme.")
      end
    end

    context "when work task is not found" do
      it "returns nil and collects error" do
        generator = described_class.new(config)
        result = generator.generate(task_name: "nonexistent_task")

        expect(result).to be_nil
        expect(generator.errors).to include("Work task 'nonexistent_task' not found or inactive")
      end
    end

    context "when work task is inactive" do
      before { work_task.update!(active: false) }

      it "returns nil and collects error" do
        generator = described_class.new(config)
        result = generator.generate(task_name: "product_description")

        expect(result).to be_nil
        expect(generator.errors.first).to include("not found or inactive")
      end
    end

    context "when no prompt exists for the work task" do
      before { work_task } # create the task but no prompt

      it "returns nil and collects error" do
        generator = described_class.new(config)
        result = generator.generate(task_name: "product_description")

        expect(result).to be_nil
        expect(generator.errors.first).to include("No active prompt found")
      end
    end

    context "when using a named prompt" do
      let!(:alt_prompt) do
        create(:ai_engine_prompt,
          ai_engine_work_task: work_task,
          name: "alt",
          prompt_template: "Alt prompt for {{product_name}}",
          is_default: false
        )
      end

      before { prompt } # create default too

      it "uses the specified prompt instead of the default" do
        provider_instance = instance_double(Spree::AiEngine::GeminiProvider)
        allow(SpreeAiEngine).to receive(:provider_for).with(config).and_return(provider_instance)
        allow(provider_instance).to receive(:generate).with(
          prompt: "Alt prompt for Widget",
          system_prompt: config.system_prompt
        ).and_return("Alt response")

        result = config.generate_content(
          task_name: "product_description",
          prompt_name: "alt",
          variables: { product_name: "Widget" }
        )

        expect(result).to eq("Alt response")
      end
    end

    context "when provider raises an error" do
      before do
        prompt

        provider_instance = instance_double(Spree::AiEngine::GeminiProvider)
        allow(SpreeAiEngine).to receive(:provider_for).with(config).and_return(provider_instance)
        allow(provider_instance).to receive(:generate).and_raise(StandardError, "API limit exceeded")
      end

      it "returns nil and collects the error" do
        generator = described_class.new(config)
        result = generator.generate(
          task_name: "product_description",
          variables: { product_name: "Widget", brand: "Acme" }
        )

        expect(result).to be_nil
        expect(generator.errors).to include("API limit exceeded")
      end
    end

    context "fallback to non-default prompt" do
      let!(:non_default_prompt) do
        create(:ai_engine_prompt,
          ai_engine_work_task: work_task,
          name: "only_one",
          prompt_template: "Only prompt for {{product_name}}",
          is_default: false
        )
      end

      before { non_default_prompt }

      it "uses the first available prompt when no default exists" do
        provider_instance = instance_double(Spree::AiEngine::GeminiProvider)
        allow(SpreeAiEngine).to receive(:provider_for).with(config).and_return(provider_instance)
        allow(provider_instance).to receive(:generate).and_return("Generated content")

        result = config.generate_content(
          task_name: "product_description",
          variables: { product_name: "Widget" }
        )

        expect(result).to eq("Generated content")
      end
    end
  end
end
