# frozen_string_literal: true

require_relative 'error'

module Spree
  module InstagramPublisher
    class Client
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def get(path, params = {})
        request(:get, path, params)
      end

      def post(path, body = {})
        request(:post, path, body)
      end

      # Resolve IG Business Account ID from a Facebook Page ID
      # GET /{page-id}?fields=instagram_business_account
      def resolve_ig_business_account(page_id)
        response = get("/#{page_id}", fields: 'instagram_business_account')

        ig_account = response.dig('instagram_business_account')
        ig_account.is_a?(Hash) ? ig_account['id'] : nil
      rescue => e
        Rails.logger.error("[InstagramPublisher::Client] resolve_ig_business_account failed: #{e.class} — #{e.message}")
        nil
      end

      # Verify the IG account and fetch profile info
      # GET /{ig-user-id}?fields=username,profile_picture_url
      def verify_ig_account(ig_user_id)
        get("/#{ig_user_id}", fields: 'username,profile_picture_url')
      end

      private

      def request(method, path, payload = {})
        masked_payload = payload.dup
        if masked_payload.is_a?(Hash)
          masked_payload = masked_payload.transform_values { |v| v.is_a?(String) && v.length > 20 ? "#{v[0..10]}...#{v[-5..]}" : v }
        end
        Rails.logger.info("[InstagramPublisher::Client] ▶ #{method.upcase} #{path} — payload: #{masked_payload.inspect}")

        response = connection.send(method) do |req|
          req.url path
          req.headers['Authorization'] = "Bearer #{config.active_token}"
          req.headers['Content-Type'] = 'application/json'

          case method
          when :get
            req.params = payload if payload.present?
          when :post
            req.body = payload.to_json if payload.present?
          end
        end

        body_preview = response.body&.truncate(500)
        Rails.logger.info("[InstagramPublisher::Client] ◀ #{method.upcase} #{path} — status: #{response.status}, body: #{body_preview}")

        data = JSON.parse(response.body) rescue response.body

        unless response.success?
          handle_api_error(response, data)
        end

        data
      end

      def handle_api_error(response, data)
        error_info = data.is_a?(Hash) ? data['error'] : nil
        message = error_info.is_a?(Hash) ? (error_info['message'] || response.body) : response.body
        error_subcode = error_info.is_a?(Hash) ? error_info['error_subcode'] : nil
        error_code = error_info.is_a?(Hash) ? error_info['code'] : nil

        case response.status
        when 401
          token = config.active_token
          token_type = config.long_lived_token.present? ? 'long-lived' : 'short-lived'
          Rails.logger.error("[InstagramPublisher::Client] 401 Authentication Error — " \
            "using #{token_type} token, token_present: #{token.present?}, token_length: #{token&.length}, " \
            "token_preview: #{token.present? ? "#{token[0..5]}…#{token[-4..]}" : "N/A"}, " \
            "error_subcode: #{error_subcode}, message: #{message}")

          raise Spree::InstagramPublisher::AuthenticationError, "Instagram authentication failed (401): #{message}"
        when 400
          Rails.logger.error("[InstagramPublisher::Client] 400 Bad Request — " \
            "error_code: #{error_code}, error_subcode: #{error_subcode}, message: #{message}")

          if message&.include?('Unsupported post request')
            raise Spree::InstagramPublisher::ApiError,
              "Instagram API error (400): #{message}\n" \
              "Hint: The Instagram Business Account ID may be incorrect or the account may not support content publishing. " \
              "Verify the account ID in the admin panel."
          end

          raise Spree::InstagramPublisher::ApiError, "Instagram API error (400): #{message}"
        when 429
          raise Spree::InstagramPublisher::RateLimitError, "Instagram API rate limit exceeded (429): #{message}"
        else
          raise Spree::InstagramPublisher::ApiError, "Instagram API error (#{response.status}): #{message}"
        end
      end

      def connection
        @connection ||= Faraday.new(url: config.graph_api_url) do |f|
          f.request :url_encoded
          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end
