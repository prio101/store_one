# frozen_string_literal: true

class AddLongLivedTokenToSpreeInstagramPublisherConfigs < ActiveRecord::Migration[7.2]
  def change
    add_column :spree_instagram_publisher_configs, :long_lived_token, :string
  end
end
