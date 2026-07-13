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
        debug_data['is_valid'] == true
      rescue => e
        Rails.logger.error("[InstagramPublisher::TokenManager] valid? check failed: #{e.class} — #{e.message}")
        false
      end

      # Get the token expiration info
      def expiration_info
        data = debug_data
        {
          valid: data['is_valid'],
          expires_at: data['expires_at'] ? Time.at(data['expires_at']) : nil,
          scopes: data['scopes'] || []
        }
      rescue => e
        Rails.logger.error("[InstagramPublisher::TokenManager] expiration_info failed: #{e.class} — #{e.message}")
        nil
      end

      # Detailed diagnostic hash for logging and rails console inspection.
      # Returns a Hash with every useful detail about the current token.
      def diagnose
        token = @config.page_access_token
        raw = debug_token_raw
        data = raw['data'] || {}
        api_error = raw['error']

        expires_at = data['expires_at'] ? Time.at(data['expires_at']) : nil
        scopes = data['scopes'] || []

        {
          config_id:          @config.id,
          store_id:           @config.store_id,
          app_id:             @config.app_id,
          app_secret_present: @config.app_secret.present?,
          token_present:      token.present?,
          token_length:       token&.length,
          token_preview:      token.present? ? "#{token[0..5]}…#{token[-4..]}" : nil,
          is_valid:           data['is_valid'],
          expires_at:         expires_at,
          expires_in_seconds: data['expires_at'] ? (data['expires_at'] - Time.now.to_i) : nil,
          scopes:             scopes,
          missing_scopes:     required_scopes - scopes,
          ig_account_id:      @config.ig_business_account_id,
          ig_username:        @config.ig_username,
          enabled:            @config.enabled,
          resolved:           @config.resolved_ig_account?,
          api_error:          api_error,
          raw_debug_data:     data
        }
      rescue => e
        {
          config_id: @config.id,
          error: "#{e.class}: #{e.message}",
          token_present: @config.page_access_token.present?,
          app_secret_present: @config.app_secret.present?
        }
      end

      # Extract the Instagram Business Account ID from the token's granular_scopes.
      # This is the most reliable way to discover the IG account in Development Mode,
      # where the instagram_business_account field on the Page is not accessible.
      #
      # @return [String, nil] the IG Business Account ID or nil
      def extract_ig_account_from_scopes
        data = debug_data
        granular = data['granular_scopes'] || []

        granular.each do |scope_entry|
          if scope_entry['scope'] == 'instagram_content_publish' && scope_entry['target_ids']&.any?
            ig_id = scope_entry['target_ids'].first
            Rails.logger.info("[InstagramPublisher::TokenManager] extracted IG Business Account ID from granular_scopes: #{ig_id}")
            return ig_id
          end
        end

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

      private

      REQUIRED_SCOPES = %w[instagram_content_publish pages_show_list pages_read_engagement].freeze

      def required_scopes
        REQUIRED_SCOPES
      end

      # Calls debug_token and returns the full response hash.
      # Returns {} on missing credentials or connection errors.
      def debug_token_raw
        return {} unless @config.page_access_token.present?
        return {} unless @config.app_id.present? && @config.app_secret.present?

        @client.get('/debug_token',
                    input_token: @config.page_access_token,
                    access_token: "#{@config.app_id}|#{@config.app_secret}")
      rescue => e
        Rails.logger.error("[InstagramPublisher::TokenManager] debug_token call failed: #{e.class} — #{e.message}")
        { 'error' => { 'message' => "#{e.class}: #{e.message}" } }
      end

      # Calls debug_token and returns the nested 'data' hash (or empty hash).
      def debug_data
        response = debug_token_raw
        response['data'] || {}
      end
    end
  end
end
