# frozen_string_literal: true

class RenameModelNameToAiModelName < ActiveRecord::Migration[7.2]
  def change
    rename_column :spree_ai_engine_configs, :model_name, :ai_model_name
  end
end
