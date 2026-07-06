# frozen_string_literal: true

module Spree
  class CourierDeliveryTrackingInformation < Spree.base_class
    # Delivery types
    DELIVERY_TYPE_NORMAL = 48
    DELIVERY_TYPE_EXPRESS = 12

    DELIVERY_TYPE_NAMES = {
      DELIVERY_TYPE_NORMAL => 'Normal',
      DELIVERY_TYPE_EXPRESS => 'Express'
    }.freeze

    # Item types
    ITEM_TYPE_DOCUMENT = 1
    ITEM_TYPE_PARCEL = 2

    ITEM_TYPE_NAMES = {
      ITEM_TYPE_DOCUMENT => 'Document',
      ITEM_TYPE_PARCEL => 'Parcel'
    }.freeze

    belongs_to :order, class_name: 'Spree::Order'
    belongs_to :shipment, class_name: 'Spree::Shipment', optional: true

    validates :order, presence: true
    validates :merchant_order_id, presence: true
    validates :recipient_name, presence: true
    validates :recipient_phone, presence: true
    validates :recipient_address, presence: true
    validates :delivery_type, inclusion: { in: DELIVERY_TYPE_NAMES.keys }
    validates :item_type, inclusion: { in: ITEM_TYPE_NAMES.keys }
    validates :item_quantity, numericality: { greater_than: 0 }
    validates :item_weight, numericality: { greater_than: 0 }
    validates :shipping_cost, numericality: { greater_than_or_equal_to: 0 }
    validates :cod_amount, numericality: { greater_than_or_equal_to: 0 }

    # Scopes
    scope :pending, -> { where(confirmed: false) }
    scope :confirmed, -> { where(confirmed: true) }
    scope :by_status, ->(status) { where(order_status: status) }
    scope :by_courier, ->(name) { where(courier_name: name) }
    scope :recent, -> { order(created_at: :desc) }

    # Delivery type helpers
    def delivery_type_name
      DELIVERY_TYPE_NAMES[delivery_type] || 'Unknown'
    end

    def express?
      delivery_type == DELIVERY_TYPE_EXPRESS
    end

    def normal?
      delivery_type == DELIVERY_TYPE_NORMAL
    end

    # Item type helpers
    def item_type_name
      ITEM_TYPE_NAMES[item_type] || 'Unknown'
    end

    # Confirmation
    def confirm!
      update!(confirmed: true, confirmed_at: Time.current)
    end

    def confirmed?
      confirmed
    end

    # Total COD amount (shipping + COD)
    def total_to_collect
      shipping_cost + cod_amount
    end

    # Tracking number display
    def tracking_display
      consignment_id || 'Not assigned'
    end
  end
end
