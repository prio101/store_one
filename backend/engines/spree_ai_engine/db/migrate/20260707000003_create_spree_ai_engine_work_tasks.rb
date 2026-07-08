# frozen_string_literal: true

class CreateSpreeAiEngineWorkTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_ai_engine_work_tasks do |t|
      t.references :ai_engine_config, null: false, foreign_key: { to_table: :spree_ai_engine_configs }, index: true

      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :spree_ai_engine_work_tasks, [:ai_engine_config_id, :name], unique: true
  end
end
