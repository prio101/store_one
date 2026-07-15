# frozen_string_literal: true

class AddFacebookCaptionTemplateToInstagramPublisherConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :spree_instagram_publisher_configs, :facebook_caption_template, :text
  end
end
