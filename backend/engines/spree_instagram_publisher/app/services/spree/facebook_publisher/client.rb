# frozen_string_literal: true

require_relative 'error'

module Spree
  module FacebookPublisher
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

      # Post a photo to the Facebook Page
      # POST /{page-id}/photos
      #
      # @param image_url [String] Publicly accessible image URL
      # @param message [String] Post message/caption
      # @return [Hash] { id: post_id }
      def post_photo(image_url:, message:)
        response = post("/#{@config.page_id}/photos", {
          url: image_url,
          message: message,
          published: true
        })
        response
      end

      # Post a link to the Facebook Page
      # POST /{page-id}/feed
      #
      # @param link [String] URL to share
      # @param message [String] Post message
      # @return [Hash] { id: post_id }
      def post_link(link:, message:)
        response = post("/#{@config.page_id}/feed", {
          link: link,
          message: message
        })
        response
      end

      private

      def request(method, path, payload = {})
        masked_payload = payload.dup
        if masked_payload.is_a?(Hash)
          masked_payload = masked_payload.transform_values { |v| v.is_a?(String) && v.length > 20 ? "#{v[0..10]}...#{v[-5..]}" : v }
        end
        Rails.logger.info("[FacebookPublisher::Client] ▶ #{method.upcase} #{path} — payload: #{masked_payload.inspect}")

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
        Rails.logger.info("[FacebookPublisher::Client] ◀ #{method.upcase} #{path} — status: #{response.status}, body: #{body_preview}")

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
          raise Spree::FacebookPublisher::AuthenticationError, "Facebook authentication failed (401): #{message}"
        when 400
          Rails.logger.error("[FacebookPublisher::Client] 400 Bad Request — " \
            "error_code: #{error_code}, error_subcode: #{error_subcode}, message: #{message}")
          raise Spree::FacebookPublisher::ApiError, "Facebook API error (400): #{message}"
        when 429
          raise Spree::FacebookPublisher::RateLimitError, "Facebook API rate limit exceeded (429): #{message}"
        else
          raise Spree::FacebookPublisher::ApiError, "Facebook API error (#{response.status}): #{message}"
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
