# frozen_string_literal: true

class AlignSupportTicketSubjects < ActiveRecord::Migration[8.1]
  def up
    add_column :spree_support_tickets, :subject_new, :integer

    execute <<~SQL
      UPDATE spree_support_tickets
      SET subject_new = CASE subject
        WHEN 0 THEN 0
        WHEN 1 THEN 3
        WHEN 2 THEN 2
        WHEN 3 THEN 1
        WHEN 4 THEN 4
        WHEN 7 THEN 5
        WHEN 8 THEN 6
        ELSE 6
      END
    SQL

    remove_column :spree_support_tickets, :subject
    rename_column :spree_support_tickets, :subject_new, :subject

    change_column_default :spree_support_tickets, :subject, 0
    change_column_null :spree_support_tickets, :subject, false
  end

  def down
    add_column :spree_support_tickets, :subject_old, :integer

    execute <<~SQL
      UPDATE spree_support_tickets
      SET subject_old = CASE subject
        WHEN 0 THEN 0
        WHEN 1 THEN 3
        WHEN 2 THEN 2
        WHEN 3 THEN 1
        WHEN 4 THEN 4
        WHEN 5 THEN 7
        WHEN 6 THEN 8
        ELSE 8
      END
    SQL

    remove_column :spree_support_tickets, :subject
    rename_column :spree_support_tickets, :subject_old, :subject
    change_column_default :spree_support_tickets, :subject, 0
    change_column_null :spree_support_tickets, :subject, false
  end
end
