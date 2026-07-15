# frozen_string_literal: true

module Spree
  class SupportTicket < Spree.base_class
    belongs_to :user, class_name: Spree.user_class.to_s
    belongs_to :store, class_name: 'Spree::Store'
    belongs_to :assigned_to, class_name: Spree.admin_user_class.to_s, optional: true
    has_many :messages, class_name: 'Spree::SupportTicketMessage', dependent: :destroy
    has_one_attached :image

    enum :subject, {
      order_issue: 0,
      payment_problem: 1,
      delivery_delay: 2,
      product_defect: 3,
      refund_request: 4,
      account_issue: 5,
      other: 6
    }

    enum :status, {
      pending: 0,
      in_progress: 1,
      resolved: 2,
      ask_for_clarification: 3,
      closed: 4
    }

    enum :priority, {
      high: 0,
      medium: 1,
      low: 2
    }

    validates :ticket_number, presence: true, uniqueness: true
    validates :title, presence: true
    validates :body, presence: true
    validates :subject, presence: true
    validates :order_number, presence: true
    validate :validate_order_exists
    validate :validate_order_belongs_to_user
    validate :validate_max_active_tickets, on: :create
    validate :validate_image_type
    validate :validate_image_size

    before_validation :generate_ticket_number, on: :create

    scope :active, -> { where(status: %w[pending in_progress]) }
    scope :by_status, ->(status) { where(status: status) }
    scope :by_priority, ->(priority) { where(priority: priority) }

    def active?
      pending? || in_progress?
    end

    def order
      @order ||= Spree::Order.find_by(number: order_number)
    end

    private

    def generate_ticket_number
      return if ticket_number.present?

      date_str = Time.current.strftime('%Y%m%d')
      loop do
        self.ticket_number = "TKT-#{date_str}-#{SecureRandom.alphanumeric(4).upcase}"
        break unless self.class.exists?(ticket_number: ticket_number)
      end
    end

    def validate_order_exists
      return if order_number.blank?

      errors.add(:order_number, 'does not exist') unless order.present?
    end

    def validate_order_belongs_to_user
      return if order_number.blank? || user.blank?

      return if order.present? && order.user_id == user.id

      # Check email match for guest-to-registered conversion
      if order.present? && order.email.present? && order.email.casecmp(user.email).zero?
        # Email matches — allow ticket but don't modify order here
        return
      end

      errors.add(:order_number, 'does not belong to your account')
    end

    def validate_max_active_tickets
      return if user.blank?

      active_count = self.class.where(user: user).active.count
      errors.add(:base, 'You can have a maximum of 5 active support tickets at a time') if active_count >= 5
    end

    def validate_image_type
      return unless image.attached?

      allowed_types = %w[image/jpeg image/png image/gif image/webp]
      unless allowed_types.include?(image.content_type)
        errors.add(:image, 'must be a JPEG, PNG, GIF, or WebP image')
      end
    end

    def validate_image_size
      return unless image.attached?

      if image.byte_size > 5.megabytes
        errors.add(:image, 'must be less than 5MB')
      end
    end
  end
end
