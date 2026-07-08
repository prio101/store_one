# frozen_string_literal: true

class RemoveProductDetailPromptFromSpreeAiEngineConfigs < ActiveRecord::Migration[7.2]
  def change
    remove_column :spree_ai_engine_configs, :product_detail_prompt, :text
  end
end
