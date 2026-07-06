# frozen_string_literal: true

module Spree
  module PathaoCourier
    class Client
      attr_reader :config

      def initialize(config)
        @config = config
        @token_manager = Spree::PathaoCourier::TokenManager.new(config)
      end

      def get(path, params = {})
        request(:get, path, params)
      end

      def post(path, body = {})
        request(:post, path, body)
      end

      # Fetch store info from Pathao API and return the first store's store_id
      # GET /aladdin/api/v1/stores → { "data": { "data": [ { "store_id": 123, ... } ] } }
      def fetch_store_info
        response = get('/aladdin/api/v1/stores')

        Rails.logger.info("[PathaoCourier::Client] fetch_store_info — response keys: #{response.keys.inspect}")

        data = response['data']
        stores = data.is_a?(Hash) ? (data['data'] || []) : (data || [])

        if stores.is_a?(Array) && stores.any?
          store = stores.first
          store_id = store['store_id'] || store['id']
          Rails.logger.info("[PathaoCourier::Client] fetch_store_info — found store_id: #{store_id}, name: #{store['store_name']}")
          store_id
        else
          Rails.logger.warn("[PathaoCourier::Client] fetch_store_info — no stores found: #{response.inspect}")
          nil
        end
      rescue => e
        Rails.logger.error("[PathaoCourier::Client] fetch_store_info failed: #{e.class} — #{e.message}")
        nil
      end

      private

      def request(method, path, payload = {})
        token = @token_manager.access_token

        Rails.logger.info("[PathaoCourier::Client] #{method.upcase} #{path} — " \
          "token present: #{token.present?}, payload: #{payload.inspect}")

        response = connection.send(method) do |req|
          req.url path
          req.headers['Authorization'] = "Bearer #{token}"
          req.headers['Content-Type'] = 'application/json'

          case method
          when :get
            req.params = payload if payload.present?
          when :post
            req.body = payload.to_json if payload.present?
          end
        end

        Rails.logger.info("[PathaoCourier::Client] response — status: #{response.status}, " \
          "body length: #{response.body&.length}, body: #{response.body&.truncate(500)}")

        data = JSON.parse(response.body) rescue response.body

        unless response.success?
          message = data.is_a?(Hash) ? (data['message'] || data['error'] || response.body) : response.body
          raise Spree::PathaoCourier::ApiError,
                "Pathao API error (#{response.status}): #{message}"
        end

        data
      end

      def connection
        @connection ||= Faraday.new(url: config.base_url) do |f|
          f.request :url_encoded
          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end
