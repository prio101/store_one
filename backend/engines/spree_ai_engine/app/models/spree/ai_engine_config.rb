# frozen_string_literal: true

module Spree
  class AiEngineConfig < Spree::Base
    belongs_to :store, class_name: "Spree::Store"
    has_many :ai_engine_work_tasks, class_name: "Spree::AiEngineWorkTask",
             dependent: :destroy, foreign_key: :ai_engine_config_id

    encrypts :api_key

    validates :provider, presence: true, inclusion: { in: %w[gemini openai] }
    validates :api_key, presence: true
    validates :ai_model_name, presence: true
    validates :temperature, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 2.0 }, allow_nil: true
    validates :max_output_tokens, numericality: { greater_than: 0 }, allow_nil: true
    validates :store_id, uniqueness: { message: "already has an AI engine configuration" }

    scope :active, -> { where(active: true) }

    def provider_label
      case provider
      when "gemini" then "Google Gemini"
      when "openai" then "OpenAI"
      else provider&.titleize
      end
    end

    # Generate content using a work task and prompt template
    #
    # @param task_name [String] work task name (e.g. "product_description")
    # @param variables [Hash] template variables
    # @param prompt_name [String, nil] optional specific prompt name
    # @return [String, nil] generated content
    def generate_content(task_name:, variables: {}, prompt_name: nil)
      Spree::AiEngine::ContentGenerator.new(self).generate(
        task_name: task_name,
        variables: variables,
        prompt_name: prompt_name
      )
    end
  end
end
