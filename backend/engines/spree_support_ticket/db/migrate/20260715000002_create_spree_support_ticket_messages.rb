# frozen_string_literal: true

class CreateSpreeSupportTicketMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_support_ticket_messages do |t|
      t.references :support_ticket, null: false, foreign_key: { to_table: :spree_support_tickets }
      t.string :sender_type, null: false
      t.bigint :sender_id, null: false
      t.text :body, null: false
      t.text :resolution_summary
      t.integer :action_taken
      t.boolean :is_internal_note, default: false, null: false

      t.timestamps
    end

    add_index :spree_support_ticket_messages, [:sender_type, :sender_id], name: 'index_support_ticket_messages_on_sender'
  end
end
