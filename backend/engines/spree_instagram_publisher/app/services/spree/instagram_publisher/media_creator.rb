# frozen_string_literal: true

module Spree
  module InstagramPublisher
    class MediaCreator
      def initialize(config)
        @config = config
        @client = Client.new(config)
      end

      # Create a media container for publishing
      # POST /{ig-user-id}/media
      #
      # @param image_url [String] Publicly accessible image URL
      # @param caption [String] Post caption
      # @return [String] Container ID for publishing
      def create_container(image_url:, caption:)
        ig_user_id = @config.ig_business_account_id

        if ig_user_id.blank?
          Rails.logger.error("[InstagramPublisher::MediaCreator] ✘ ig_business_account_id is blank")
          raise Spree::InstagramPublisher::PublishingError, 'Instagram Business Account ID is not configured'
        end

        Rails.logger.info("[InstagramPublisher::MediaCreator] POST /#{ig_user_id}/media — " \
          "image_url: #{image_url[0..100]}, caption_length: #{caption.length}")

        response = @client.post("/#{ig_user_id}/media", {
          image_url: image_url,
          caption: caption
        })

        Rails.logger.info("[InstagramPublisher::MediaCreator] create_container response: #{response.inspect[0..500]}")

        container_id = response['id']

        if container_id.blank?
          error_msg = response.dig('error', 'message') || response.inspect
          Rails.logger.error("[InstagramPublisher::MediaCreator] ✘ no container_id: #{error_msg}")
          raise Spree::InstagramPublisher::PublishingError, "Failed to create media container: #{error_msg}"
        end

        Rails.logger.info("[InstagramPublisher::MediaCreator] ✔ container created: #{container_id}")
        container_id
      end

      # Check the status of a media container
      # GET /{media-id}?fields=status_code,status
      def container_status(container_id)
        response = @client.get("/#{container_id}", fields: 'status_code,status')

        {
          status_code: response['status_code'],
          status: response['status']
        }
      end

      # Wait for a container to be ready (FINISHED status)
      # Polls with exponential backoff
      def wait_for_ready(container_id, max_attempts: 10, initial_delay: 2)
        attempt = 0
        delay = initial_delay

        while attempt < max_attempts
          status = container_status(container_id)
          attempt += 1
          Rails.logger.info("[InstagramPublisher::MediaCreator] poll #{attempt}/#{max_attempts} — " \
            "container: #{container_id}, status_code: #{status[:status_code]}, status: #{status[:status].inspect[0..200]}")

          case status[:status_code]
          when 'FINISHED'
            Rails.logger.info("[InstagramPublisher::MediaCreator] ✔ container #{container_id} is ready (attempt #{attempt})")
            return true
          when 'ERROR'
            error_msg = status[:status].is_a?(Hash) ? status[:status]['message'] : 'Unknown error'
            Rails.logger.error("[InstagramPublisher::MediaCreator] ✘ container #{container_id} failed: #{error_msg}")
            raise Spree::InstagramPublisher::PublishingError, "Media container failed: #{error_msg}"
          end

          Rails.logger.info("[InstagramPublisher::MediaCreator] container not ready, sleeping #{delay}s...")
          sleep(delay)
          delay = [delay * 1.5, 30].min
        end

        Rails.logger.error("[InstagramPublisher::MediaCreator] ✘ container #{container_id} timeout after #{max_attempts} attempts")
        raise Spree::InstagramPublisher::PublishingError, "Media container #{container_id} did not become ready within #{max_attempts} attempts"
      end
    end
  end
end
