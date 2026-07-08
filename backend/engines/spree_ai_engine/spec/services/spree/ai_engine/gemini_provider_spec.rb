# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spree::AiEngine::GeminiProvider do
  let(:config) do
    create(:ai_engine_config,
      provider: "gemini",
      api_key: "test-api-key",
      ai_model_name: "gemini-2.0-flash",
      temperature: 0.7,
      max_output_tokens: 2048,
      system_prompt: "You are a helpful product writer.")
  end

  let(:provider) { described_class.new(config) }

  describe "#generate" do
    let(:success_response) do
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                { "text" => "A wonderful product description." }
              ]
            }
          }
        ]
      }
    end

    context "with a simple prompt" do
      before do
        stub_request(:post, /generativelanguage.googleapis.com\/v1beta\/models\/gemini-2.0-flash:generateContent/)
          .to_return(status: 200, body: success_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "sends the prompt and returns generated text" do
        result = provider.generate(prompt: "Write about our product")

        expect(result).to eq("A wonderful product description.")
      end
    end

    context "with system prompt" do
      before do
        stub_request(:post, /generativelanguage.googleapis.com\/v1beta\/models\/gemini-2.0-flash:generateContent/)
          .with do |req|
            body = JSON.parse(req.body)
            expect(body["systemInstruction"]).to eq({ "parts" => [{ "text" => "You are a helpful product writer." }] })
          end
          .to_return(status: 200, body: success_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "includes system instruction in request" do
        result = provider.generate(
          prompt: "Write about our product",
          system_prompt: "You are a helpful product writer."
        )

        expect(result).to eq("A wonderful product description.")
      end
    end

    context "with template-rendered prompt from hierarchy" do
      let(:work_task) { create(:ai_engine_work_task, ai_engine_config: config, name: "product_description") }
      let(:prompt_record) do
        create(:ai_engine_prompt,
          ai_engine_work_task: work_task,
          prompt_template: "Write a compelling description for {{product_name}} by {{brand}}.",
          is_default: true
        )
      end

      before do
        stub_request(:post, /generativelanguage.googleapis.com\/v1beta\/models\/gemini-2.0-flash:generateContent/)
          .to_return(status: 200, body: success_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "accepts a pre-rendered template as the prompt" do
        rendered = prompt_record.render_template(product_name: "Widget", brand: "Acme")
        result = provider.generate(prompt: rendered)

        expect(result).to eq("A wonderful product description.")
        expect(rendered).to eq("Write a compelling description for Widget by Acme.")
      end
    end

    context "when API returns an error" do
      before do
        stub_request(:post, /generativelanguage.googleapis.com\/v1beta\/models\/gemini-2.0-flash:generateContent/)
          .to_return(
            status: 400,
            body: { "error" => { "message" => "Invalid request" } }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises ApiError" do
        expect {
          provider.generate(prompt: "test")
        }.to raise_error(Spree::AiEngine::ApiError, /Gemini API error \(400\)/)
      end
    end

    context "when API returns empty candidates" do
      before do
        stub_request(:post, /generativelanguage.googleapis.com\/v1beta\/models\/gemini-2.0-flash:generateContent/)
          .to_return(status: 200, body: { "candidates" => [] }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "returns an empty string" do
        result = provider.generate(prompt: "test")
        expect(result).to eq("")
      end
    end
  end

  describe "#health_check" do
    context "when API key is valid" do
      before do
        stub_request(:get, /generativelanguage.googleapis.com\/v1beta\/models/)
          .to_return(status: 200, body: '{"models": []}')
      end

      it "returns true" do
        expect(provider.health_check).to be true
      end
    end

    context "when API key is invalid" do
      before do
        stub_request(:get, /generativelanguage.googleapis.com\/v1beta\/models/)
          .to_return(status: 400, body: '{"error": {"message": "Invalid API key"}}')
      end

      it "returns false" do
        expect(provider.health_check).to be false
      end
    end
  end
end
