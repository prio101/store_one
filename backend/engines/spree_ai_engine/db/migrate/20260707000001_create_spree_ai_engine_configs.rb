# frozen_string_literal: true

class CreateSpreeAiEngineConfigs < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_ai_engine_configs do |t|
      t.references :store, null: false, foreign_key: { to_table: :spree_stores }, index: { unique: true }

      t.string :provider, null: false, default: "gemini"
      t.string :api_key
      t.string :model_name, default: "gemini-2.0-flash"
      t.float :temperature, default: 0.7
      t.integer :max_output_tokens, default: 2048
      t.text :system_prompt
      t.text :product_detail_prompt
      t.integer :rate_limit_rpm
      t.boolean :logging_enabled, default: true, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end
