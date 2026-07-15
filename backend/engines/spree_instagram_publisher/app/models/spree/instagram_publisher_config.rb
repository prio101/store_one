# frozen_string_literal: true

module Spree
  class InstagramPublisherConfig < Spree.base_class
    belongs_to :store, class_name: 'Spree::Store'

    encrypts :app_secret
    encrypts :page_access_token
    encrypts :long_lived_token

    validates :store, presence: true, uniqueness: true
    validates :app_id, presence: true, if: :enabled?
    validates :app_secret, presence: true, if: :enabled?
    validates :page_id, presence: true, if: :enabled?
    validates :page_access_token, presence: true, if: :enabled?

    scope :active, -> { where(enabled: true) }

    GRAPH_API_VERSION = 'v25.0'.freeze
    GRAPH_API_BASE_URL = "https://graph.facebook.com/#{GRAPH_API_VERSION}".freeze

    def graph_api_url
      GRAPH_API_BASE_URL
    end

    # Returns the best available token: long-lived preferred, fallback to short-lived.
    def active_token
      long_lived_token.presence || page_access_token
    end

    def resolved_ig_account?
      ig_business_account_id.present?
    end

    def caption_for(product:, url: nil)
      template = default_caption_template.presence ||
        "{product_name}\n\n{description}\n\n💰 Price: {price} | Last Updated at: {updated_at}\n(Check the Website for latest Price)\n\n🛒 Shop now: {url}"

      description = product.description.to_s
      # Strip HTML tags if present (TinyMCE output)
      description = ActionController::Base.helpers.strip_tags(description).strip if description.include?('<')
      # Truncate to 500 chars for Instagram
      description = "#{description[0..497]}..." if description.length > 500

      caption = template
        .gsub('{product_name}', product.name.to_s)
        .gsub('{description}', description)
        .gsub('{price}', format_price(product))
        .gsub('{updated_at}', Time.current.strftime('%b %d, %Y %I:%M %p'))
        .gsub('{url}', url.to_s)

      caption.strip
    end

    # Facebook caption template (similar to Instagram but with Facebook-specific formatting)
    def facebook_caption_for(product:, url: nil)
      template = facebook_caption_template.presence ||
        "{product_name}\n\n{description}\n\n💰 Price: {price} | Last Updated at: {updated_at}\n\n🛒 Shop now: {url}"

      description = product.description.to_s
      # Strip HTML tags if present (TinyMCE output)
      description = ActionController::Base.helpers.strip_tags(description).strip if description.include?('<')
      # Truncate to 1000 chars for Facebook (higher limit than Instagram)
      description = "#{description[0..997]}..." if description.length > 1000

      caption = template
        .gsub('{product_name}', product.name.to_s)
        .gsub('{description}', description)
        .gsub('{price}', format_price(product))
        .gsub('{updated_at}', Time.current.strftime('%b %d, %Y %I:%M %p'))
        .gsub('{url}', url.to_s)

      caption.strip
    end

    private

    def format_price(product)
      price = product.price
      return 'N/A' if price.blank?

      if price.respond_to?(:money)
        "৳#{'%.2f' % price.money.amount}"
      else
        "৳#{'%.2f' % price.to_f}"
      end
    end
  end
end
