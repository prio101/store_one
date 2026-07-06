# frozen_string_literal: true

class AddActiveToSpreePathaoCourierConfigs < ActiveRecord::Migration[7.2]
  def change
    add_column :spree_pathao_courier_configs, :active, :boolean, null: false, default: true
  end
end
