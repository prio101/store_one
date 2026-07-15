# frozen_string_literal: true

module Spree
  class SupportTicketMessage < Spree.base_class
    belongs_to :support_ticket
    belongs_to :sender, polymorphic: true

    enum :action_taken, {
      store_credit: 0,
      flag_as_fraud: 1,
      mistaken: 2,
      miscommunication: 3,
      refund: 4,
      black_list: 5
    }

    validates :body, presence: true

    scope :chronological, -> { order(created_at: :asc) }
    scope :not_internal, -> { where(is_internal_note: false) }
  end
end
