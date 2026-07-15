# frozen_string_literal: true

require_relative 'error'

module Spree
  module FacebookPublisher
    class Publisher
      def initialize(config)
        @config = config
        @client = Client.new(config)
      end

      # Publish a Spree product to Facebook Page
      #
      # @param product [Spree::Product] The product to publish
      # @param image_url [String, nil] Optional explicit image URL (overrides product image)
      # @param url [String, nil] Optional product URL (defaults to generating from product)
      # @return [Hash] { success: true/false, post_id:, error: }
      def publish(product:, image_url: nil, url: nil)
        resolved_url = url || product_url(product)

        Rails.logger.info("[FacebookPublisher::Publisher] ▶ publish — product_id: #{product.id}, " \
          "product_name: #{product.name.inspect}, url: #{resolved_url}")

        # Pre-flight token validation
        token_ok = validate_token!
        unless token_ok
          return { success: false, error: "Authentication failed: #{@last_token_error}. Please re-authorize your Facebook account." }
        end

        # Collect image URL
        image_urls = if image_url.present?
                       [image_url]
                     else
                       product_image_urls(product).first(1)
                     end

        message = @config.facebook_caption_for(product: product, url: resolved_url)
        Rails.logger.info("[FacebookPublisher::Publisher] caption (#{message.length} chars): #{message[0..200].inspect}")

        if image_urls.any?
          # Post as photo with message
          post_to_facebook_photo(image_url: image_urls.first, message: message)
        else
          # Post as link (no image)
          post_to_facebook_link(link: resolved_url, message: message)
        end
      rescue Spree::FacebookPublisher::AuthenticationError => e
        Rails.logger.error("[FacebookPublisher::Publisher] ✘ authentication error: #{e.message}")
        { success: false, error: "Authentication failed: #{e.message}. Please re-authorize your Facebook account." }
      rescue Spree::FacebookPublisher::RateLimitError => e
        Rails.logger.warn("[FacebookPublisher::Publisher] ✘ rate limit: #{e.message}")
        { success: false, error: "Rate limit exceeded. Please try again later: #{e.message}" }
      rescue Spree::FacebookPublisher::PublishingError => e
        Rails.logger.error("[FacebookPublisher::Publisher] ✘ publishing error: #{e.message}")
        { success: false, error: e.message }
      rescue Spree::FacebookPublisher::ApiError => e
        Rails.logger.error("[FacebookPublisher::Publisher] ✘ api error: #{e.message}")
        { success: false, error: e.message }
      rescue => e
        Rails.logger.error("[FacebookPublisher::Publisher] ✘ unexpected: #{e.class} — #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
        { success: false, error: "An unexpected error occurred: #{e.message}" }
      end

      private

      # Post a photo to the Facebook Page
      def post_to_facebook_photo(image_url:, message:)
        Rails.logger.info("[FacebookPublisher::Publisher] Posting photo to Facebook Page #{@config.page_id}...")

        response = @client.post_photo(image_url: image_url, message: message)

        post_id = response['id']
        if post_id.blank?
          error_msg = response.dig('error', 'message') || response.inspect
          Rails.logger.error("[FacebookPublisher::Publisher] ✘ no post_id: #{error_msg}")
          return { success: false, error: "Failed to post to Facebook: #{error_msg}" }
        end

        Rails.logger.info("[FacebookPublisher::Publisher] ✔ photo posted — post_id: #{post_id}")
        { success: true, post_id: post_id }
      end

      # Post a link to the Facebook Page
      def post_to_facebook_link(link:, message:)
        Rails.logger.info("[FacebookPublisher::Publisher] Posting link to Facebook Page #{@config.page_id}...")

        response = @client.post_link(link: link, message: message)

        post_id = response['id']
        if post_id.blank?
          error_msg = response.dig('error', 'message') || response.inspect
          Rails.logger.error("[FacebookPublisher::Publisher] ✘ no post_id: #{error_msg}")
          return { success: false, error: "Failed to post to Facebook: #{error_msg}" }
        end

        Rails.logger.info("[FacebookPublisher::Publisher] ✔ link posted — post_id: #{post_id}")
        { success: true, post_id: post_id }
      end

      # Validates the current token via Graph API debug_token endpoint.
      def validate_token!
        Rails.logger.info("[FacebookPublisher::Publisher] — pre-flight token validation...")

        # Use InstagramPublisher's token manager since we share the same config
        tm = Spree::InstagramPublisher::TokenManager.new(@config)
        info = tm.expiration_info

        if info.nil?
          @last_token_error = "Token validation request failed — could not reach Graph API"
          Rails.logger.error("[FacebookPublisher::Publisher] ✘ #{@last_token_error}")
          return false
        end

        if info[:valid] != true
          @last_token_error = "Token is invalid according to Graph API (is_valid=#{info[:valid]})"
          Rails.logger.error("[FacebookPublisher::Publisher] ✘ #{@last_token_error}")
          return false
        end

        # Check expiration
        if info[:expires_at]
          remaining = info[:expires_at] - Time.current
          if remaining <= 0
            @last_token_error = "Token expired at #{info[:expires_at]} (#{(-remaining).round}s ago)"
            Rails.logger.error("[FacebookPublisher::Publisher] ✘ #{@last_token_error}")
            return false
          end
        end

        Rails.logger.info("[FacebookPublisher::Publisher] ✔ token valid")
        true
      end

      def product_url(product)
        store = @config.store
        host = store&.url || 'localhost:3000'
        "#{host}/products/#{product.slug}"
      end

      # Collect public image URLs for a product
      def product_image_urls(product)
        urls = []
        product.variants_including_master.each do |variant|
          variant.images.each do |image|
            next unless image.attachment&.attached?
            urls << blob_public_url(image.attachment.blob)
          end
        end
        urls
      end

      # Build a public URL for a blob from DigitalOcean Spaces
      def blob_public_url(blob)
        region = ENV.fetch('DO_SPACES_REGION', 'sgp1')
        bucket = ENV.fetch('DO_SPACES_BUCKET', '')
        prefix = ENV.fetch('DO_SPACES_PREFIX', '')
        endpoint = "#{bucket}.#{region}.digitaloceanspaces.com"

        path = prefix.present? ? "#{prefix}/#{blob.key}" : blob.key
        "https://#{endpoint}/#{path}"
      end
    end
  end
end
