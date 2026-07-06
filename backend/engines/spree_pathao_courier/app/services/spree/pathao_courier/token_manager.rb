# frozen_string_literal: true

module Spree
  module PathaoCourier
    class TokenManager
      TOKEN_LIFETIME = 3600 # 1 hour

      def initialize(config)
        @config = config
      end

      def access_token
        return @config.access_token if @config.token_valid?

        issue_or_refresh_token
      end

      private

      def issue_or_refresh_token
        if @config.refresh_token.present?
          refresh
        else
          issue
        end
      end

      def issue
        response = connection.post('/aladdin/api/v1/issue-token') do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = {
            client_id: @config.client_id,
            client_secret: @config.client_secret,
            username: @config.username,
            password: @config.password
          }.to_json
        end

        handle_token_response(response)
      end

      def refresh
        response = connection.post('/aladdin/api/v1/refresh-token') do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = {
            refresh_token: @config.refresh_token
          }.to_json
        end

        handle_token_response(response)
      rescue StandardError
        # If refresh fails, fall back to issuing a new token
        issue
      end

      def handle_token_response(response)
        data = JSON.parse(response.body)

        if response.success? && data['access_token'].present?
          @config.update!(
            access_token: data['access_token'],
            refresh_token: data['refresh_token'],
            token_expires_at: Time.current + TOKEN_LIFETIME
          )
          @config.access_token
        else
          raise Spree::PathaoCourier::AuthenticationError,
                "Pathao token error: #{data['message'] || response.body}"
        end
      end

      def connection
        @connection ||= Faraday.new(url: @config.base_url) do |f|
          f.request :url_encoded
          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end
