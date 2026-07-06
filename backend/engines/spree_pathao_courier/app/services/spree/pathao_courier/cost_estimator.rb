# frozen_string_literal: true

module Spree
  module PathaoCourier
    class CostEstimator
      def initialize(config:)
        @config = config
        @client = Spree::PathaoCourier::Client.new(config)
      end

      # Calculate shipping cost from Pathao price plan API
      # @param delivery_type [Integer] 48=Normal, 12=Express
      # @param item_type [Integer] 1=Document, 2=Parcel
      # @param item_weight [Numeric] Weight in grams
      # @param recipient_zone [Integer] Pathao zone ID
      # @param recipient_city [Integer] Pathao city ID (e.g. 1 for DHAKA)
      # @return [Hash] { price:, discount:, cod_percentage:, final_price:, estimated_delivery: }
      def call(delivery_type:, item_type:, item_weight:, recipient_zone:, recipient_city:)
        # Pathao API expects weight in kg with 0.1–200 range; config stores grams
        weight_kg = (item_weight.to_f / 1000).round(2)
        weight_kg = [weight_kg, 0.1].max

        # Ensure pathao_store_id is set for price-plan API
        store_id = ensure_store_id

        payload = {
          store_id: store_id,
          item_type: item_type,
          delivery_type: delivery_type,
          item_weight: weight_kg,
          recipient_zone: recipient_zone,
          recipient_city: recipient_city
        }

        Rails.logger.info("[PathaoCourier::CostEstimator] calling price-plan — payload: #{payload.inspect} " \
          "(types: delivery_type=#{delivery_type.class}, item_type=#{item_type.class}, " \
          "item_weight=#{item_weight.class}, recipient_zone=#{recipient_zone.class})")

        response = @client.post('/aladdin/api/v1/merchant/price-plan', payload)

        Rails.logger.info("[PathaoCourier::CostEstimator] API response — keys: #{response.keys.inspect}")

        price_data = unwrap_data(response['data'], response)

        Rails.logger.info("[PathaoCourier::CostEstimator] price_data — keys: #{price_data.keys.inspect}, " \
          "price: #{price_data['price'].inspect}")

        result = {
          price: price_data['price'].to_i,
          discount: price_data['discount'].to_i,
          cod_percentage: price_data['cod_percentage'].to_i,
          final_price: price_data['final_price'].to_i,
          estimated_delivery: estimate_delivery(delivery_type)
        }

        Rails.logger.info("[PathaoCourier::CostEstimator] result — #{result.inspect}")
        result
      end

      private

      # Ensure we have a valid pathao_store_id — fetch from API if missing
      def ensure_store_id
        store_id = @config.pathao_store_id
        return store_id if store_id.present? && store_id.to_i > 0

        Rails.logger.info("[PathaoCourier::CostEstimator] pathao_store_id is nil — attempting to fetch from API")
        fetched = @client.fetch_store_info

        if fetched.present? && fetched.to_i > 0
          @config.update_column(:pathao_store_id, fetched)
          Rails.logger.info("[PathaoCourier::CostEstimator] fetched and saved pathao_store_id: #{fetched}")
          return fetched
        end

        Rails.logger.error("[PathaoCourier::CostEstimator] pathao_store_id not available — " \
          "API fetch did not return a valid store_id")
        raise Spree::PathaoCourier::ApiError,
              "Pathao store ID could not be determined. Please set it in Courier Config, " \
              "or verify your Pathao credentials are correct."
      end

      # Pathao API returns double-nested responses like { "data": { "data": {...} } }
      def unwrap_data(data, fallback)
        return fallback if data.nil?
        return data if data.is_a?(Hash) && data.key?('price')
        return data['data'] || fallback if data.is_a?(Hash) && data.key?('data')
        data
      end

      def estimate_delivery(delivery_type)
        case delivery_type
        when Spree::CourierDeliveryTrackingInformation::DELIVERY_TYPE_EXPRESS
          '1-2 business days'
        when Spree::CourierDeliveryTrackingInformation::DELIVERY_TYPE_NORMAL
          '3-5 business days'
        else
          'Unknown'
        end
      end
    end
  end
end
