# frozen_string_literal: true

module Spree
  module AiEngine
    class BaseProvider
      attr_reader :config

      def initialize(config)
        @config = config
      end

      # Generate text from a prompt
      # @param prompt [String] the user prompt
      # @param system_prompt [String, nil] optional system instruction
      # @param opts [Hash] provider-specific options
      # @return [String] generated text
      def generate(prompt:, system_prompt: nil, **opts)
        raise NotImplementedError, "#{self.class}#generate must be implemented"
      end

      # Verify API key is valid
      # @return [Boolean]
      def health_check
        raise NotImplementedError, "#{self.class}#health_check must be implemented"
      end

      private

      def connection
        @connection ||= Faraday.new do |f|
          f.request :url_encoded
          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end
