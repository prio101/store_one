# frozen_string_literal: true

module Spree
  module PathaoCourier
    class OrderCreator
      MERCHANT_API_PATH = '/aladdin/api/v1/merchant/orders'

      # @param shipment [Spree::Shipment]
      # @param config [Spree::PathaoCourierConfig]
      def initialize(shipment:, config:)
        @shipment = shipment
        @order = shipment.order
        @config = config
        @client = Spree::PathaoCourier::Client.new(config)
      end

      # Creates a Pathao shipment and returns the consignment_id.
      # Stores the consignment_id in shipment#tracking.
      #
      # @return [String] consignment_id
      # @raise [Spree::PathaoCourier::ApiError] on API failure
      def call
        payload = build_payload
        response = @client.post(MERCHANT_API_PATH, payload)

        consignment_id = response.dig('data', 'consignment_id')

        if consignment_id.blank?
          raise Spree::PathaoCourier::ShippingError,
                "Pathao did not return a consignment_id: #{response.to_json}"
        end

        @shipment.update!(tracking: consignment_id.to_s)

        consignment_id.to_s
      end

      private

      def build_payload
        recipient = @order.shipping_address

        {
          store_id: @config.pathao_store_id,
          merchant_order_id: @order.number,
          recipient_name: recipient.full_name,
          recipient_phone: recipient.phone,
          recipient_address: recipient.address1,
          recipient_city: lookup_city_id,
          recipient_zone: lookup_zone_id,
          recipient_area: lookup_area_id,
          delivery_type: @config.default_delivery_type,
          item_type: @config.default_item_type,
          item_quantity: item_quantity,
          item_weight: calculate_weight,
          item_description: item_description,
          shipping_cost: calculate_shipping_cost,
          collect_cash: order_total_to_collect,
          note: order_note
        }
      end

      def lookup_city_id
        # Pathao uses numeric city IDs; for Dhaka it's typically 1.
        # In production, this should query /aladdin/api/v1/city-list and cache.
        1
      end

      def lookup_zone_id
        # Zone lookup should query /aladdin/api/v1/zone-list?city_id=X
        # For now, use a default that works in sandbox (Dhaka zone).
        # TODO: Implement city/zone/area lookup with caching
        1
      end

      def lookup_area_id
        # Area lookup should query /aladdin/api/v1/area-list?zone_id=X
        # For now, use a default that works in sandbox.
        # TODO: Implement city/zone/area lookup with caching
        1
      end

      def item_quantity
        @shipment.inventory_units.size
      end

      def calculate_weight
        # Use default_weight from config (in grams) if available
        @config.default_weight || 500
      end

      def item_description
        items = @shipment.inventory_units.map { |iu| iu.variant.name }.uniq
        items.join(', ').truncate(255)
      end

      def calculate_shipping_cost
        @shipment.cost.to_f
      end

      def order_total_to_collect
        # Cash on delivery: collect the order total
        # For prepaid orders, this should be 0
        # TODO: Check payment method type to determine if COD
        @order.total.to_f
      end

      def order_note
        "Order ##{@order.number}"
      end
    end
  end
end
