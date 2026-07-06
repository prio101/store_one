# frozen_string_literal: true

class AddAvailableToSpreeCourierIntegrations < ActiveRecord::Migration[8.0]
  def change
    add_column :spree_courier_integrations, :available, :boolean, default: false, null: false
  end
end
