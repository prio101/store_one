# frozen_string_literal: true

require_relative 'error'

module Spree
  module InstagramPublisher
    class Publisher
      def initialize(config)
        @config = config
        @client = Client.new(config)
        @media_creator = MediaCreator.new(config)
      end

      # Publish a Spree product to Instagram
      #
      # @param product [Spree::Product] The product to publish
      # @param image_url [String, nil] Optional explicit image URL (overrides product image)
      # @param url [String, nil] Optional product URL (defaults to generating from product)
      # @return [Hash] { success: true/false, media_id:, error: }
      def publish(product:, image_url: nil, url: nil)
        resolved_url = url || product_url(product)
        resolved_image_url = image_url || product_image_url(product)

        Rails.logger.info("[InstagramPublisher::Publisher] ▶ publish — product_id: #{product.id}, " \
          "product_name: #{product.name.inspect}, url: #{resolved_url}")

        if resolved_image_url.blank?
          Rails.logger.error("[InstagramPublisher::Publisher] ✘ no product image — product_id: #{product.id}")
          return { success: false, error: 'No product image available for publishing' }
        end

        Rails.logger.info("[InstagramPublisher::Publisher] image_url: #{resolved_image_url}")

        caption = @config.caption_for(product: product, url: resolved_url)
        Rails.logger.info("[InstagramPublisher::Publisher] caption (#{caption.length} chars): #{caption[0..200].inspect}")

        # Step 1: Create media container
        Rails.logger.info("[InstagramPublisher::Publisher] Step 1/3 — creating media container...")
        container_id = @media_creator.create_container(
          image_url: resolved_image_url,
          caption: caption
        )
        Rails.logger.info("[InstagramPublisher::Publisher] Step 1/3 — container created: #{container_id}")

        # Step 2: Wait for container to be ready
        Rails.logger.info("[InstagramPublisher::Publisher] Step 2/3 — waiting for container to be ready...")
        @media_creator.wait_for_ready(container_id)
        Rails.logger.info("[InstagramPublisher::Publisher] Step 2/3 — container ready")

        # Step 3: Publish the container
        Rails.logger.info("[InstagramPublisher::Publisher] Step 3/3 — publishing container #{container_id} to IG user #{@config.ig_business_account_id}...")
        publish_response = @client.post("/#{@config.ig_business_account_id}/media_publish", {
          creation_id: container_id
        })
        Rails.logger.info("[InstagramPublisher::Publisher] Step 3/3 — publish response: #{publish_response.inspect[0..500]}")

        media_id = publish_response['id']

        if media_id.blank?
          error_msg = publish_response.dig('error', 'message') || publish_response.inspect
          Rails.logger.error("[InstagramPublisher::Publisher] ✘ publish returned no media_id: #{error_msg}")
          return { success: false, error: error_msg }
        end

        Rails.logger.info("[InstagramPublisher::Publisher] ✔ published product ##{product.id} — media_id: #{media_id}")
        { success: true, media_id: media_id }
      rescue Spree::InstagramPublisher::AuthenticationError => e
        Rails.logger.error("[InstagramPublisher::Publisher] ✘ authentication error: #{e.message}")
        { success: false, error: "Authentication failed: #{e.message}. Please re-authorize your Instagram account." }
      rescue Spree::InstagramPublisher::RateLimitError => e
        Rails.logger.warn("[InstagramPublisher::Publisher] ✘ rate limit: #{e.message}")
        { success: false, error: "Rate limit exceeded. Please try again later: #{e.message}" }
      rescue Spree::InstagramPublisher::PublishingError => e
        Rails.logger.error("[InstagramPublisher::Publisher] ✘ publishing error: #{e.message}")
        { success: false, error: e.message }
      rescue Spree::InstagramPublisher::ApiError => e
        Rails.logger.error("[InstagramPublisher::Publisher] ✘ api error: #{e.message}")
        { success: false, error: e.message }
      rescue => e
        Rails.logger.error("[InstagramPublisher::Publisher] ✘ unexpected: #{e.class} — #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
        { success: false, error: "An unexpected error occurred: #{e.message}" }
      end

      private

      def product_url(product)
        store = @config.store
        host = store&.url || 'minimeshop.net'
        protocol = 'https'
        "#{protocol}://#{host}/products/#{product.slug}"
      end

      def product_image_url(product)
        media = product.primary_media
        return nil unless media&.attachment&.attached?

        blob = media.attachment.blob

        # Build a public URL directly from the S3 key.
        # ActiveStorage's attachment.url generates a signed URL (required for
        # direct-upload compatibility with DigitalOcean Spaces), but Meta's
        # servers need an unsigned, publicly-accessible URL.
        region = ENV.fetch('DO_SPACES_REGION', 'sgp1')
        bucket = ENV.fetch('DO_SPACES_BUCKET', '')
        endpoint = "#{bucket}.#{region}.digitaloceanspaces.com"

        "https://#{endpoint}/#{blob.key}"
      end
    end
  end
end
