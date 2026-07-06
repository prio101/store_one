# frozen_string_literal: true

module Spree
  module PathaoCourier
    class TokenManager
      TOKEN_LIFETIME = 3600 # 1 hour

      def initialize(config)
        @config = config
      end

      def access_token
        Rails.logger.info("[PathaoCourier::TokenManager] access_token — valid: #{@config.token_valid?}, " \
          "token present: #{@config.access_token.present?}, " \
          "expires_at: #{@config.token_expires_at.inspect}, " \
          "refresh_token present: #{@config.refresh_token.present?}")

        return @config.access_token if @config.token_valid?

        Rails.logger.info("[PathaoCourier::TokenManager] token invalid/expired — issuing or refreshing")
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
        Rails.logger.info("[PathaoCourier::TokenManager] issuing new token")
        response = connection.post('/aladdin/api/v1/issue-token') do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = {
            grant_type: 'password',
            client_id: @config.client_id,
            client_secret: @config.client_secret,
            username: @config.username,
            password: @config.password
          }.to_json
        end

        Rails.logger.info("[PathaoCourier::TokenManager] issue-token response — status: #{response.status}, " \
          "body: #{response.body&.truncate(300)}")
        handle_token_response(response)
      end

      def refresh
        Rails.logger.info("[PathaoCourier::TokenManager] refreshing token")
        response = connection.post('/aladdin/api/v1/refresh-token') do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = {
            refresh_token: @config.refresh_token
          }.to_json
        end

        Rails.logger.info("[PathaoCourier::TokenManager] refresh-token response — status: #{response.status}, " \
          "body: #{response.body&.truncate(300)}")
        handle_token_response(response)
      rescue StandardError => e
        Rails.logger.warn("[PathaoCourier::TokenManager] refresh failed: #{e.message} — falling back to issue")
        issue
      end

      def handle_token_response(response)
        data = JSON.parse(response.body)

        if response.success? && data['access_token'].present?
          Rails.logger.info("[PathaoCourier::TokenManager] token acquired successfully")
          @config.update!(
            access_token: data['access_token'],
            refresh_token: data['refresh_token'],
            token_expires_at: Time.current + TOKEN_LIFETIME
          )
          @config.access_token
        else
          Rails.logger.error("[PathaoCourier::TokenManager] token acquisition failed — #{data.inspect}")
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
