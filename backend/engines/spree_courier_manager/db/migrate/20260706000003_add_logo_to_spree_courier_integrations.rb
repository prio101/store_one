# frozen_string_literal: true

class AddLogoToSpreeCourierIntegrations < ActiveRecord::Migration[8.0]
  def change
    add_column :spree_courier_integrations, :logo, :string
  end
end
