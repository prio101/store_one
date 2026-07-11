# frozen_string_literal: true

module Spree
  module InstagramPublisher
    class TokenManager
      def initialize(config)
        @config = config
        @client = Client.new(config)
      end

      # Validate the current page access token
      # GET /debug_token?input_token={token}&access_token={app_id}|{app_secret}
      def valid?
        return false unless @config.page_access_token.present?

        response = @client.get('/debug_token',
                               input_token: @config.page_access_token,
                               access_token: "#{@config.app_id}|#{@config.app_secret}")

        data = response['data'] || {}
        data['is_valid'] == true
      rescue => e
        Rails.logger.error("[InstagramPublisher::TokenManager] valid? check failed: #{e.class} — #{e.message}")
        false
      end

      # Get the token expiration info
      def expiration_info
        return nil unless @config.page_access_token.present?

        response = @client.get('/debug_token',
                               input_token: @config.page_access_token,
                               access_token: "#{@config.app_id}|#{@config.app_secret}")

        data = response['data'] || {}
        {
          valid: data['is_valid'],
          expires_at: data['expires_at'] ? Time.at(data['expires_at']) : nil,
          scopes: data['scopes'] || []
        }
      rescue => e
        Rails.logger.error("[InstagramPublisher::TokenManager] expiration_info failed: #{e.class} — #{e.message}")
        nil
      end

      # Exchange a short-lived token for a long-lived token
      # GET /oauth/access_token?grant_type=fb_exchange_token&client_id={app_id}&client_secret={app_secret}&fb_exchange_token={short_lived_token}
      def exchange_for_long_lived(short_lived_token)
        response = @client.get('/oauth/access_token',
                               grant_type: 'fb_exchange_token',
                               client_id: @config.app_id,
                               client_secret: @config.app_secret,
                               fb_exchange_token: short_lived_token)

        if response['access_token'].present?
          Rails.logger.info("[InstagramPublisher::TokenManager] successfully exchanged for long-lived token")
          response['access_token']
        else
          Rails.logger.warn("[InstagramPublisher::TokenManager] exchange failed: #{response.inspect}")
          nil
        end
      rescue => e
        Rails.logger.error("[InstagramPublisher::TokenManager] exchange_for_long_lived failed: #{e.class} — #{e.message}")
        nil
      end
    end
  end
end
