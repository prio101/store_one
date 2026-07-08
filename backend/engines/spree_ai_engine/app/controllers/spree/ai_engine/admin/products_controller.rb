# frozen_string_literal: true

module Spree
  module AiEngine
    module Admin
      class ProductsController < Spree::Admin::BaseController
        layout "spree/layouts/admin"

        def generate
          config = Spree::AiEngineConfig.active
                                       .where(store: Spree::Current.store)
                                       .first

          unless config
            render json: { success: false, message: "No AI configuration found. Please add an AI Model first." },
                   status: :unprocessable_entity
            return
          end

          variables = {
            name: params[:name].to_s.strip,
            price: params[:price].to_s.strip,
            category: params[:category].to_s.strip
          }

          prompt_text = build_prompt(variables)

          provider = SpreeAiEngine.provider_for(config)
          result = provider.generate(
            prompt: prompt_text,
            system_prompt: "You are an expert e-commerce product copywriter. Always respond with valid JSON."
          )

          parsed = parse_ai_response(result)

          render json: {
            success: true,
            title: parsed[:title],
            description: parsed[:description]
          }
        rescue => e
          Rails.logger.error "[SpreeAiEngine] Generate failed: #{e.message}"
          render json: { success: false, message: e.message },
                 status: :unprocessable_entity
        end

        private

        def build_prompt(variables)
          parts = []
          parts << "Product Name: #{variables[:name]}" if variables[:name].present?
          parts << "Price: #{variables[:price]}" if variables[:price].present?
          parts << "Category: #{variables[:category]}" if variables[:category].present?

          <<~PROMPT.strip
            Generate a compelling e-commerce product listing based on the following details:

            #{parts.join("\n")}

            Return your response as valid JSON in this exact format:
            {"title": "Product title (max 60 characters, SEO-friendly, concise)", "description": "Product description in HTML format with paragraphs, bullet points, and emphasis where appropriate. Make it persuasive and highlight key benefits. Use <p>, <ul>, <li>, <strong>, and <em> tags."}

            Only return the JSON object, no additional text or markdown code blocks.
          PROMPT
        end

        def parse_ai_response(response)
          text = response.to_s.strip

          # Strip markdown code fences if present
          text = text.gsub(/\A```(?:json)?\s*\n?/, "").gsub(/\n?```\s*\z/, "")

          parsed = JSON.parse(text)

          {
            title: parsed["title"] || "",
            description: parsed["description"] || ""
          }
        rescue JSON::ParserError
          # Fallback: try to extract title and description from plain text
          {
            title: text.lines.first.to_s.strip[0..59],
            description: text
          }
        end
      end
    end
  end
end
