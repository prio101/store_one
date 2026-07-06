# frozen_string_literal: true

class CreateSpreePathaoCourierConfigs < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_pathao_courier_configs do |t|
      t.references :store, null: false, foreign_key: { to_table: :spree_stores }, index: { unique: true }

      t.string :base_url, null: false, default: 'https://courier-api-sandbox.pathao.com'
      t.string :client_id, null: false
      t.string :client_secret, null: false
      t.string :username, null: false
      t.string :password, null: false
      t.boolean :sandbox, null: false, default: true

      t.integer :pathao_store_id
      t.integer :default_delivery_type, default: 48
      t.integer :default_item_type, default: 2
      t.integer :default_weight, default: 500

      t.string :access_token
      t.string :refresh_token
      t.datetime :token_expires_at

      t.timestamps
    end
  end
end
