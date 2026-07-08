# frozen_string_literal: true

module Spree
  class AiEngineWorkTask < Spree::Base
    belongs_to :ai_engine_config, class_name: "Spree::AiEngineConfig"
    has_many :ai_engine_prompts, class_name: "Spree::AiEnginePrompt",
             dependent: :destroy, foreign_key: :ai_engine_work_task_id

    validates :name, presence: true, uniqueness: { scope: :ai_engine_config_id }
    validates :name, inclusion: { in: %w[
      product_description
      product_title
      seo_keywords
      meta_description
      product_short_description
      product_long_description
      category_description
      brand_story
      custom
    ] }

    scope :active, -> { where(active: true) }

    before_validation :normalize_name

    def label
      name.to_s.split("_").map(&:capitalize).join(" ")
    end

    private

    def normalize_name
      self.name = name.to_s.strip.downcase.gsub(/[\s-]+/, "_") if name.present?
    end
  end
end
