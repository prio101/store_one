# frozen_string_literal: true

module Spree
  module PathaoCourier
    class OrderCreator
      ORDER_API_PATH = '/aladdin/api/v1/orders'

      # @param shipment [Spree::Shipment]
      # @param config [Spree::PathaoCourierConfig]
      # @param address_data [Hash, nil] Pre-resolved address data from AddressResolver
      def initialize(shipment:, config:, address_data: nil)
        @shipment = shipment
        @order = shipment.order
        @config = config
        @client = Spree::PathaoCourier::Client.new(config)
        @address_data = address_data
      end

      # Creates a Pathao shipment and returns the consignment_id.
      # Stores the consignment_id in shipment#tracking.
      #
      # @return [String] consignment_id
      # @raise [Spree::PathaoCourier::ApiError] on API failure
      def call
        store_id = ensure_store_id
        payload = build_payload(store_id)
        Rails.logger.info("[PathaoCourier::OrderCreator] POST #{ORDER_API_PATH} — payload: #{payload.inspect}")

        response = @client.post(ORDER_API_PATH, payload)

        # Pathao returns double-nested: { "data": { "data": { "consignment_id": ... } } }
        data = unwrap_data(response['data'], response)
        consignment_id = data['consignment_id']

        if consignment_id.blank?
          raise Spree::PathaoCourier::ShippingError,
                "Pathao did not return a consignment_id: #{response.to_json}"
        end

        @shipment.update_columns(tracking: consignment_id.to_s)
        Rails.logger.warn("[PathaoCourier::OrderCreator] Shipment #{@shipment.number} tracking updated with consignment_id: #{consignment_id}")
        consignment_id.to_s
      end

      private

      def build_payload(store_id)
        recipient = @order.shipping_address

        {
          store_id: store_id,
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
          item_weight: calculate_weight_kg,
          item_description: item_description,
          amount_to_collect: order_total_to_collect,
          special_instruction: order_note
        }
      end

      # Ensure we have a valid pathao_store_id — fetch from API if missing
      def ensure_store_id
        store_id = @config.pathao_store_id
        return store_id if store_id.present? && store_id.to_i > 0

        Rails.logger.info("[PathaoCourier::OrderCreator] pathao_store_id is nil — attempting to fetch from API")
        fetched = @client.fetch_store_info

        if fetched.present? && fetched.to_i > 0
          @config.update_column(:pathao_store_id, fetched)
          Rails.logger.info("[PathaoCourier::OrderCreator] fetched and saved pathao_store_id: #{fetched}")
          return fetched
        end

        raise Spree::PathaoCourier::ApiError,
              "Pathao store ID could not be determined. Please set it in Courier Config, " \
              "or verify your Pathao credentials are correct."
      end

      # Pathao API returns double-nested responses like { "data": { "data": {...} } }
      def unwrap_data(data, fallback)
        return fallback if data.nil?
        return data if data.is_a?(Hash) && data.key?('consignment_id')
        return data['data'] || fallback if data.is_a?(Hash) && data.key?('data')
        data
      end

      def lookup_city_id
        resolved_address[:city_id] || 1
      end

      def lookup_zone_id
        resolved_address[:zone_id] || 1
      end

      def lookup_area_id
        resolved_address[:area_id] || 1
      end

      def resolved_address
        @resolved_address ||= if @address_data
                                 @address_data
                               else
                                 resolve_address_from_order
                               end
      end

      def resolve_address_from_order
        recipient = @order.shipping_address
        return {} unless recipient

        resolver = Spree::PathaoCourier::AddressResolver.new(
          config: @config,
          shipping_address: recipient
        )
        resolver.call
      rescue Spree::PathaoCourier::AddressNotFoundError => e
        Rails.logger.warn("[PathaoCourier] Address resolution failed: #{e.message}, using defaults")
        {}
      end

      def item_quantity
        @shipment.inventory_units.size
      end

      # Pathao API expects weight in kg (0.5–10 range). Config stores grams.
      def calculate_weight_kg
        grams = (@config.default_weight || 500).to_f
        weight_kg = (grams / 1000).round(2)
        [weight_kg, 0.5].max
      end

      def item_description
        items = @shipment.inventory_units.map { |iu| iu.variant.name }.uniq
        items.join(', ').truncate(255)
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
