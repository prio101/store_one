# frozen_string_literal: true

module Spree
  class AiEnginePrompt < Spree::Base
    belongs_to :ai_engine_work_task, class_name: "Spree::AiEngineWorkTask"

    validates :name, presence: true, uniqueness: { scope: :ai_engine_work_task_id }
    validates :prompt_template, presence: true

    scope :active, -> { where(active: true) }
    scope :defaults, -> { where(is_default: true) }

    before_save :ensure_single_default

    def render_template(**vars)
      result = prompt_template
      vars.each do |key, value|
        result = result.gsub("{{#{key}}}", value.to_s)
      end
      result
    end

    private

    def ensure_single_default
      return unless is_default?

      ai_engine_work_task.ai_engine_prompts
                         .where(is_default: true)
                         .where.not(id: id)
                         .update_all(is_default: false)
    end
  end
end
