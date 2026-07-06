# frozen_string_literal: true

module Spree
  module PathaoCourier
    class OrderLookup
      def initialize(config:)
        @config = config
        @client = Spree::PathaoCourier::Client.new(config)
      end

      # @param consignment_id [Integer]
      # @return [Hash] order details from Pathao
      def by_consignment_id(consignment_id)
        @client.get('/aladdin/api/v1/merchant/orders-order', {
          consignment_id: consignment_id
        })
      end

      # @param merchant_order_id [String] Spree order number
      # @return [Hash] order details from Pathao
      def by_merchant_order_id(merchant_order_id)
        @client.get('/aladdin/api/v1/merchant/orders-info', {
          merchant_order_id: merchant_order_id
        })
      end
    end
  end
end
