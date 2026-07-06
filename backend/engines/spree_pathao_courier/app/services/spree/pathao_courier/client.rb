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

      private

      def request(method, path, payload = {})
        token = @token_manager.access_token

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

        parse_response(response)
      end

      def parse_response(response)
        data = JSON.parse(response.body)

        unless response.success?
          raise Spree::PathaoCourier::ApiError,
                "Pathao API error (#{response.status}): #{data['message'] || data['error'] || response.body}"
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
