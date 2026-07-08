# frozen_string_literal: true

require "spree_core"
require "spree_api"
require "spree_admin"

require "spree_ai_engine/version"
require "spree_ai_engine/engine"

module Spree
  module AiEngine
    class Error < StandardError; end
    class AuthenticationError < Error; end
    class ApiError < Error; end
    class ConfigurationError < Error; end
  end
end

module SpreeAiEngine
  PROVIDERS = {
    "gemini" => "Spree::AiEngine::GeminiProvider"
  }.freeze

  def self.provider_for(config)
    klass = PROVIDERS[config.provider]
    raise ArgumentError, "Unknown provider: #{config.provider}" unless klass
    klass.constantize.new(config)
  end
end
