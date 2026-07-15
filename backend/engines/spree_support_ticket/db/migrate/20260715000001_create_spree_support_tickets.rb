# frozen_string_literal: true

class CreateSpreeSupportTickets < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_support_tickets do |t|
      t.string :ticket_number, null: false
      t.references :user, null: false, foreign_key: { to_table: :spree_users }
      t.references :store, null: false, foreign_key: { to_table: :spree_stores }
      t.string :order_number, null: false
      t.string :title, null: false
      t.integer :subject, null: false
      t.text :body, null: false
      t.integer :status, default: 0, null: false
      t.integer :priority, default: 2, null: false
      t.references :assigned_to, foreign_key: { to_table: :spree_admin_users }
      t.datetime :resolved_at
      t.datetime :closed_at
      t.jsonb :public_metadata, default: {}
      t.jsonb :private_metadata, default: {}

      t.timestamps
    end

    add_index :spree_support_tickets, :ticket_number, unique: true
    add_index :spree_support_tickets, :order_number
    add_index :spree_support_tickets, :status
    add_index :spree_support_tickets, :priority
  end
end
