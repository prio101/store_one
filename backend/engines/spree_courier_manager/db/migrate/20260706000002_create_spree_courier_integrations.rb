# frozen_string_literal: true

class CreateSpreeCourierIntegrations < ActiveRecord::Migration[8.0]
  def change
    create_table :spree_courier_integrations do |t|
      t.references :store, null: false, foreign_key: { to_table: 'spree_stores' }, index: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :icon
      t.boolean :enabled, default: false, null: false
      t.string :config_url
      t.integer :position, default: 0, null: false
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :spree_courier_integrations, [:store_id, :slug], unique: true
  end
end
