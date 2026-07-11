# frozen_string_literal: true

module Spree
  class InstagramPublisherConfig < Spree.base_class
    belongs_to :store, class_name: 'Spree::Store'

    encrypts :app_secret
    encrypts :page_access_token

    validates :store, presence: true, uniqueness: true
    validates :app_id, presence: true, if: :enabled?
    validates :app_secret, presence: true, if: :enabled?
    validates :page_id, presence: true, if: :enabled?
    validates :page_access_token, presence: true, if: :enabled?

    scope :active, -> { where(enabled: true) }

    GRAPH_API_VERSION = 'v21.0'.freeze
    GRAPH_API_BASE_URL = "https://graph.facebook.com/#{GRAPH_API_VERSION}".freeze

    def graph_api_url
      GRAPH_API_BASE_URL
    end

    def resolved_ig_account?
      ig_business_account_id.present?
    end

    def caption_for(product:, url: nil)
      template = default_caption_template.presence ||
        "{product_name}\n\nPrice: {price}\n\nShop now: {url}"

      caption = template
        .gsub('{product_name}', product.name.to_s)
        .gsub('{price}', format_price(product))
        .gsub('{url}', url.to_s)

      caption.strip
    end

    private

    def format_price(product)
      price = product.price
      return price.to_s unless price.respond_to?(:money)

      price.money.format
    end
  end
end
