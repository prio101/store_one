# frozen_string_literal: true

module Spree
  module PathaoCourier
    class CheckoutService
      # @param order [Spree::Order]
      # @param config [Spree::PathaoCourierConfig]
      # @param delivery_type [Integer] 48=Normal, 12=Express
      # @param item_type [Integer] 1=Document, 2=Parcel
      # @param item_weight [Numeric] Weight in grams
      # @param note [String, nil] Special instructions
      def initialize(order:, config:, delivery_type:, item_type: nil, item_weight: nil, note: nil)
        @order = order
        @config = config
        @delivery_type = delivery_type
        @item_type = item_type || config.default_item_type
        @item_weight = item_weight || config.default_weight
        @note = note
      end

      # Estimate cost without creating shipment
      # @return [Hash] Cost breakdown with address resolution data
      def estimate_cost
        Rails.logger.info("[PathaoCourier::CheckoutService] estimate_cost — order: #{@order.number}, " \
          "delivery_type: #{@delivery_type.inspect}, item_type: #{@item_type.inspect}, item_weight: #{@item_weight.inspect}")

        address_data = resolve_address
        Rails.logger.info("[PathaoCourier::CheckoutService] address resolved: #{address_data.inspect}")

        cost = Spree::PathaoCourier::CostEstimator.new(config: @config).call(
          delivery_type: @delivery_type,
          item_type: @item_type,
          item_weight: @item_weight,
          recipient_zone: address_data[:zone_id],
          recipient_city: address_data[:city_id]
        )
        Rails.logger.info("[PathaoCourier::CheckoutService] cost result: #{cost.inspect}")

        {
          address_data: address_data,
          cost: cost
        }
      end

      # Create shipment and persist tracking information
      # @return [Spree::CourierDeliveryTrackingInformation]
      def confirm!
        address_data = resolve_address
        cost = estimate_cost_for_address(address_data)

        shipment = @order.shipments.last
        raise Spree::PathaoCourier::ShippingError, "Order has no shipments" unless shipment

        consignment_id = create_pathao_shipment(address_data)
        Rails.logger.info("[PathaoCourier::CheckoutService] Pathao shipment created: consignment_id=#{consignment_id}")

        save_tracking_info(shipment, consignment_id, address_data, cost)
      end

      private

      def resolve_address
        recipient = @order.shipping_address
        unless recipient
          Rails.logger.error("[PathaoCourier::CheckoutService] Order has no shipping address — order: #{@order.number}")
          raise Spree::PathaoCourier::ShippingError, "Order has no shipping address"
        end

        Rails.logger.info("[PathaoCourier::CheckoutService] resolving address — " \
          "address1: #{recipient.address1.inspect}, city: #{recipient.city.inspect}, " \
          "state: #{recipient.state.inspect}, zipcode: #{recipient.zipcode.inspect}, " \
          "country: #{recipient.country.inspect}")

        Spree::PathaoCourier::AddressResolver.new(
          config: @config,
          shipping_address: recipient
        ).call
      end

      def estimate_cost_for_address(address_data)
        Spree::PathaoCourier::CostEstimator.new(config: @config).call(
          delivery_type: @delivery_type,
          item_type: @item_type,
          item_weight: @item_weight,
          recipient_zone: address_data[:zone_id],
          recipient_city: address_data[:city_id]
        )
      end

      def create_pathao_shipment(address_data)
        shipment = @order.shipments.last
        raise Spree::PathaoCourier::ShippingError, "Order has no shipments" unless shipment

        delivery_order = Spree::PathaoCourier::OrderCreator.new(
          shipment: shipment,
          config: @config,
          address_data: address_data
        ).call
        Rails.logger.info("[PathaoCourier::CheckoutService] Pathao shipment created for order #{@order.number}, shipment #{shipment.number}, tracking: #{shipment.tracking.inspect}")
        delivery_order
      end

      def save_tracking_info(shipment, consignment_id, address_data, cost)
        recipient = @order.shipping_address

        Spree::CourierDeliveryTrackingInformation.create!(
          order: @order,
          shipment: shipment,
          courier_name: 'pathao',
          consignment_id: consignment_id,
          merchant_order_id: @order.number.to_s,
          recipient_name: recipient.full_name,
          recipient_phone: recipient.phone,
          recipient_address: recipient.address1,
          recipient_city_id: address_data[:city_id],
          recipient_zone_id: address_data[:zone_id],
          recipient_area_id: address_data[:area_id],
          delivery_type: @delivery_type,
          item_type: @item_type,
          item_quantity: shipment.inventory_units.size,
          item_weight: @item_weight,
          item_description: shipment.inventory_units.map { |iu| iu.variant.name }.uniq.join(', '),
          shipping_cost: cost[:price],
          cod_amount: @order.total.to_f,
          order_status: 'pending',
          estimated_delivery: cost[:estimated_delivery],
          note: @note
        )
      end
    end
  end
end
