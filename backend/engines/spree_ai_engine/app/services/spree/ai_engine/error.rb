# frozen_string_literal: true

module Spree
  module AiEngine
    class Error < StandardError; end
    class AuthenticationError < Error; end
    class ApiError < Error; end
    class ConfigurationError < Error; end
  end
end
