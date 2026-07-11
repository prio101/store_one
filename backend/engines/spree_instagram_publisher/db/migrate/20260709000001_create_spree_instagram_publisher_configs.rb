# frozen_string_literal: true

class CreateSpreeInstagramPublisherConfigs < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_instagram_publisher_configs do |t|
      t.references :store, null: false, foreign_key: { to_table: :spree_stores }, index: { unique: true }

      t.boolean :enabled, null: false, default: false

      t.string :app_id
      t.string :app_secret
      t.string :page_id
      t.string :page_access_token
      t.string :ig_business_account_id
      t.string :ig_username
      t.string :ig_profile_picture_url

      t.text   :default_caption_template
      t.boolean :auto_publish, default: false
      t.datetime :last_publish_at

      t.timestamps
    end
  end
end
