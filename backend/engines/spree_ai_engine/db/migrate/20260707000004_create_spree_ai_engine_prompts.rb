# frozen_string_literal: true

class CreateSpreeAiEnginePrompts < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_ai_engine_prompts do |t|
      t.references :ai_engine_work_task, null: false, foreign_key: { to_table: :spree_ai_engine_work_tasks }, index: true

      t.string :name, null: false
      t.text :prompt_template, null: false
      t.boolean :is_default, default: false, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :spree_ai_engine_prompts, [:ai_engine_work_task_id, :name], unique: true
  end
end
