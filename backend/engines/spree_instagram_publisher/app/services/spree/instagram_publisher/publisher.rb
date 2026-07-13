# frozen_string_literal: true

require_relative 'error'

module Spree
  module InstagramPublisher
    class Publisher
      def initialize(config)
        @config = config
        @client = Client.new(config)
        @media_creator = MediaCreator.new(config)
        @token_manager = TokenManager.new(config)
      end

      # Publish a Spree product to Instagram
      #
      # @param product [Spree::Product] The product to publish
      # @param image_url [String, nil] Optional explicit image URL (overrides product image)
      # @param url [String, nil] Optional product URL (defaults to generating from product)
      # @return [Hash] { success: true/false, media_id:, error: }
      def publish(product:, image_url: nil, url: nil)
        resolved_url = url || product_url(product)

        Rails.logger.info("[InstagramPublisher::Publisher] ▶ publish — product_id: #{product.id}, " \
          "product_name: #{product.name.inspect}, url: #{resolved_url}")

        # Collect all product images (up to 10 for carousel)
        image_urls = if image_url.present?
                       [image_url]
                     else
                       product_image_urls(product).first(10)
                     end

        if image_urls.empty?
          Rails.logger.error("[InstagramPublisher::Publisher] ✘ no product images — product_id: #{product.id}")
          return { success: false, error: 'No product images available for publishing' }
        end

        Rails.logger.info("[InstagramPublisher::Publisher] #{image_urls.length} image(s) to publish")

        caption = @config.caption_for(product: product, url: resolved_url)
        Rails.logger.info("[InstagramPublisher::Publisher] caption (#{caption.length} chars): #{caption[0..200].inspect}")

        # Pre-flight token validation
        token_ok = validate_token!
        unless token_ok
          return { success: false, error: "Authentication failed: #{@last_token_error}. Please re-authorize your Instagram account." }
        end

        # Verify IG Business Account is accessible
        ig_account_ok = verify_ig_account!
        unless ig_account_ok
          # Attempt 1: Extract from token's granular_scopes (works in Development Mode)
          Rails.logger.info("[InstagramPublisher::Publisher] — attempting to extract IG account from token scopes...")
          ig_id_from_scopes = @token_manager.extract_ig_account_from_scopes
          if ig_id_from_scopes.present? && ig_id_from_scopes != @config.ig_business_account_id
            Rails.logger.info("[InstagramPublisher::Publisher] ✔ extracted IG account from scopes: #{ig_id_from_scopes}")
            @config.update!(ig_business_account_id: ig_id_from_scopes)
            ig_account_ok = true
          elsif ig_id_from_scopes.present?
            # Same ID, verification failed — in dev mode this may be expected
            Rails.logger.warn("[InstagramPublisher::Publisher] ⚠ IG account verification failed but ID matches scopes — proceeding (dev mode)")
            ig_account_ok = true
          end
        end

        unless ig_account_ok
          # Attempt 2: Re-resolve from Page ID
          Rails.logger.info("[InstagramPublisher::Publisher] — attempting to re-resolve IG account from page_id #{@config.page_id}...")
          re_resolved = re_resolve_ig_account!
          unless re_resolved
            return { success: false, error: "Instagram Business Account is not accessible. Please verify the account ID and permissions in the admin panel." }
          end
        end

        ig_user_id = @config.ig_business_account_id

        if image_urls.length == 1
          # Single image post
          publish_single_image(ig_user_id: ig_user_id, image_url: image_urls.first, caption: caption)
        else
          # Carousel post (2-10 images)
          publish_carousel(ig_user_id: ig_user_id, image_urls: image_urls, caption: caption)
        end
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

      # Single image post: create container → wait → publish
      def publish_single_image(ig_user_id:, image_url:, caption:)
        Rails.logger.info("[InstagramPublisher::Publisher] Single image post — #{image_url[0..80]}...")

        container_id = @media_creator.create_container(image_url: image_url, caption: caption)
        Rails.logger.info("[InstagramPublisher::Publisher] Step 2/3 — waiting for container to be ready...")
        @media_creator.wait_for_ready(container_id)

        publish_response = @client.post("/#{ig_user_id}/media_publish", {
          creation_id: container_id
        })

        media_id = publish_response['id']
        if media_id.blank?
          error_msg = publish_response.dig('error', 'message') || publish_response.inspect
          Rails.logger.error("[InstagramPublisher::Publisher] ✘ publish returned no media_id: #{error_msg}")
          return { success: false, error: error_msg }
        end

        Rails.logger.info("[InstagramPublisher::Publisher] ✔ published — media_id: #{media_id}")
        { success: true, media_id: media_id }
      end

      # Carousel post (2-10 images):
      # 1. Create individual media containers for each image
      # 2. Wait for all to be ready
      # 3. Create carousel container with the child IDs
      # 4. Wait for carousel container
      # 5. Publish the carousel
      def publish_carousel(ig_user_id:, image_urls:, caption:)
        Rails.logger.info("[InstagramPublisher::Publisher] Carousel post — #{image_urls.length} images")

        # Step 1: Create individual containers for each image (no caption on children)
        child_ids = []
        image_urls.each_with_index do |image_url, index|
          Rails.logger.info("[InstagramPublisher::Publisher] Creating child container #{index + 1}/#{image_urls.length}...")
          child_id = @media_creator.create_container(image_url: image_url, caption: nil)
          child_ids << child_id
        end

        # Step 2: Wait for all child containers
        child_ids.each_with_index do |child_id, index|
          Rails.logger.info("[InstagramPublisher::Publisher] Waiting for child #{index + 1}/#{child_ids.length}...")
          @media_creator.wait_for_ready(child_id)
        end

        # Step 3: Create carousel container
        Rails.logger.info("[InstagramPublisher::Publisher] Creating carousel container...")
        ig_user_id = @config.ig_business_account_id
        carousel_response = @client.post("/#{ig_user_id}/media", {
          media_type: 'CAROUSEL',
          children: child_ids.join(','),
          caption: caption
        })

        carousel_id = carousel_response['id']
        if carousel_id.blank?
          error_msg = carousel_response.dig('error', 'message') || carousel_response.inspect
          Rails.logger.error("[InstagramPublisher::Publisher] ✘ carousel container failed: #{error_msg}")
          return { success: false, error: "Failed to create carousel container: #{error_msg}" }
        end
        Rails.logger.info("[InstagramPublisher::Publisher] Carousel container created: #{carousel_id}")

        # Step 4: Wait for carousel container
        Rails.logger.info("[InstagramPublisher::Publisher] Waiting for carousel container...")
        @media_creator.wait_for_ready(carousel_id)

        # Step 5: Publish carousel
        Rails.logger.info("[InstagramPublisher::Publisher] Publishing carousel...")
        publish_response = @client.post("/#{ig_user_id}/media_publish", {
          creation_id: carousel_id
        })

        media_id = publish_response['id']
        if media_id.blank?
          error_msg = publish_response.dig('error', 'message') || publish_response.inspect
          Rails.logger.error("[InstagramPublisher::Publisher] ✘ carousel publish failed: #{error_msg}")
          return { success: false, error: error_msg }
        end

        Rails.logger.info("[InstagramPublisher::Publisher] ✔ carousel published — media_id: #{media_id}")
        { success: true, media_id: media_id }
      end

      # Validates the current token via Graph API debug_token endpoint.
      # Returns true if token is valid, false otherwise (and sets @last_token_error).
      def validate_token!
        Rails.logger.info("[InstagramPublisher::Publisher] — pre-flight token validation...")

        info = @token_manager.expiration_info

        if info.nil?
          @last_token_error = "Token validation request failed — could not reach Graph API"
          Rails.logger.error("[InstagramPublisher::Publisher] ✘ #{@last_token_error}")
          return false
        end

        if info[:valid] != true
          @last_token_error = "Token is invalid according to Graph API (is_valid=#{info[:valid]})"
          Rails.logger.error("[InstagramPublisher::Publisher] ✘ #{@last_token_error}")
          log_token_diagnosis
          return false
        end

        # Check expiration
        if info[:expires_at]
          remaining = info[:expires_at] - Time.current
          Rails.logger.info("[InstagramPublisher::Publisher] token expires_at: #{info[:expires_at]}, " \
            "remaining: #{remaining.round}s (#{(remaining / 3600).round(1)}h)")

          if remaining <= 0
            @last_token_error = "Token expired at #{info[:expires_at]} (#{(-remaining).round}s ago)"
            Rails.logger.error("[InstagramPublisher::Publisher] ✘ #{@last_token_error}")
            return false
          end

          if remaining < 1.hour
            Rails.logger.warn("[InstagramPublisher::Publisher] ⚠ token expires very soon — #{remaining.round}s remaining. Consider re-authorizing.")
          end
        else
          Rails.logger.warn("[InstagramPublisher::Publisher] ⚠ token has no expiration info (may be a never-expiring token or debug token)")
        end

        # Log scopes for diagnostics but don't block — the API call itself
        # will fail with a clear error if permissions are insufficient.
        required = %w[instagram_content_publish pages_show_list pages_read_engagement]
        actually_missing = required - info[:scopes]
        if actually_missing.any?
          Rails.logger.warn("[InstagramPublisher::Publisher] ⚠ token may be missing scopes: #{actually_missing.join(', ')} " \
            "(has: #{info[:scopes].join(', ')}). Proceeding — API call will confirm.")
        end

        Rails.logger.info("[InstagramPublisher::Publisher] ✔ token valid, scopes: #{info[:scopes].join(', ')}")
        true
      end

      def log_token_diagnosis
        diag = @token_manager.diagnose
        Rails.logger.error("[InstagramPublisher::Publisher] token diagnosis — #{diag.to_json}")
      end

      # Re-resolve the IG Business Account ID from the configured Page ID.
      # This is called when the stored IG account ID fails verification.
      def re_resolve_ig_account!
        return false unless @config.page_id.present?

        ig_account_id = @client.resolve_ig_business_account(@config.page_id)

        if ig_account_id.present?
          Rails.logger.info("[InstagramPublisher::Publisher] ✔ re-resolved IG account — old: #{@config.ig_business_account_id}, new: #{ig_account_id}")
          @config.update!(ig_business_account_id: ig_account_id)

          # Also fetch username and profile picture
          profile = @client.verify_ig_account(ig_account_id)
          if profile.is_a?(Hash)
            attrs = {}
            attrs[:ig_username] = profile['username'] if profile['username'].present?
            attrs[:ig_profile_picture_url] = profile['profile_picture_url'] if profile['profile_picture_url'].present?
            @config.update(attrs) if attrs.any?
          end

          # Verify the newly resolved account
          verify_ig_account!
        else
          Rails.logger.error("[InstagramPublisher::Publisher] ✘ could not re-resolve IG account from page_id #{@config.page_id}")
          false
        end
      rescue => e
        Rails.logger.error("[InstagramPublisher::Publisher] ✘ re_resolve_ig_account! failed: #{e.class} — #{e.message}")
        false
      end

      def product_url(product)
        store = @config.store
        host = store&.url || 'localhost:3000'
        "#{host}/products/#{product.slug}"
      end

      # Verify the IG Business Account ID is valid and accessible
      # This helps diagnose "Object does not exist" errors
      def verify_ig_account!
        ig_user_id = @config.ig_business_account_id
        Rails.logger.info("[InstagramPublisher::Publisher] — verifying IG account #{ig_user_id}...")

        begin
          # Try to fetch account info to verify it exists and is accessible
          # NOTE: account_type is NOT available in Development Mode — only request id + username
          response = @client.get("/#{ig_user_id}", fields: 'id,username')

          Rails.logger.info("[InstagramPublisher::Publisher] ✔ IG account verified — username: #{response['username']}")
          true
        rescue Spree::InstagramPublisher::ApiError => e
          Rails.logger.error("[InstagramPublisher::Publisher] ✘ IG account verification failed: #{e.message}")
          false
        end
      end

      # Build a public URL for a blob from DigitalOcean Spaces
      def blob_public_url(blob)
        region = ENV.fetch('DO_SPACES_REGION', 'sgp1')
        bucket = ENV.fetch('DO_SPACES_BUCKET', '')
        endpoint = "#{bucket}.#{region}.digitaloceanspaces.com"

        "https://#{endpoint}/#{blob.key}"
      end

      # Collect all public image URLs for a product (for carousel)
      # In Spree 5.5, images live on variants (polymorphic via viewable).
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
    end
  end
end
