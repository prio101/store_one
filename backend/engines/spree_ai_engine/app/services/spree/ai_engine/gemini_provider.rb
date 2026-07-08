# frozen_string_literal: true

require "faraday"
require "json"

module Spree
  module AiEngine
    class GeminiProvider < BaseProvider
      BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

      def generate(prompt:, system_prompt: nil, **opts)
        model = opts[:ai_model_name] || config.ai_model_name
        temperature = opts[:temperature] || config.temperature
        max_tokens = opts[:max_output_tokens] || config.max_output_tokens

        body = build_generate_body(prompt, system_prompt, temperature, max_tokens)

        response = connection.post("#{BASE_URL}/models/#{model}:generateContent?key=#{config.api_key}") do |req|
          req.headers["Content-Type"] = "application/json"
          req.body = body.to_json
        end

        data = parse_response(response)

        extract_generated_text(data)
      end

      def health_check
        response = connection.get("#{BASE_URL}/models?key=#{config.api_key}")

        response.status == 200
      rescue => e
        Rails.logger.error("[Spree::AiEngine::GeminiProvider] health_check failed: #{e.message}")
        false
      end

      private

      def build_generate_body(prompt, system_prompt, temperature, max_tokens)
        body = {
          contents: [
            { role: "user", parts: [{ text: prompt }] }
          ],
          generationConfig: {
            temperature: temperature,
            maxOutputTokens: max_tokens
          }
        }

        if system_prompt.present?
          body[:systemInstruction] = { parts: [{ text: system_prompt }] }
        end

        body
      end

      def parse_response(response)
        data = JSON.parse(response.body) rescue {}

        unless response.success?
          error_message = data.dig("error", "message") || response.body
          raise Spree::AiEngine::ApiError,
                "Gemini API error (#{response.status}): #{error_message}"
        end

        data
      end

      def extract_generated_text(data)
        candidates = data["candidates"] || []
        return "" if candidates.empty?

        parts = candidates.dig(0, "content", "parts") || []
        parts.map { |p| p["text"] }.join
      end
    end
  end
end
