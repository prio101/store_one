# frozen_string_literal: true

module Spree
  class PathaoCourierConfig < Spree.base_class
    belongs_to :store, class_name: 'Spree::Store'

    encrypts :client_secret
    encrypts :password
    encrypts :access_token
    encrypts :refresh_token

    validates :client_id, presence: true
    validates :client_secret, presence: true
    validates :username, presence: true
    validates :password, presence: true
    validates :base_url, presence: true
    validates :store, presence: true, uniqueness: true

    after_create :fetch_and_save_pathao_store_id

    scope :active, -> { where(active: true) }

    DELIVERY_TYPES = {
      48 => 'Normal',
      12 => 'On Demand'
    }.freeze

    ITEM_TYPES = {
      1 => 'Document',
      2 => 'Parcel'
    }.freeze

    def sandbox?
      sandbox
    end

    def live?
      !sandbox
    end

    def token_valid?
      access_token.present? && token_expires_at.present? && token_expires_at > Time.current
    end

    def delivery_type_name
      DELIVERY_TYPES[default_delivery_type] || 'Normal'
    end

    def item_type_name
      ITEM_TYPES[default_item_type] || 'Parcel'
    end

    private

    # After creating a config, automatically fetch and save the Pathao store_id
    def fetch_and_save_pathao_store_id
      return if pathao_store_id.present?

      client = Spree::PathaoCourier::Client.new(self)
      store_id = client.fetch_store_info

      if store_id.present?
        update_column(:pathao_store_id, store_id)
        Rails.logger.info("[PathaoCourierConfig] auto-fetched pathao_store_id: #{store_id} for config ##{id}")
      else
        Rails.logger.warn("[PathaoCourierConfig] could not auto-fetch pathao_store_id for config ##{id} — " \
          "user must set it manually in the Pathao config form")
      end
    rescue => e
      Rails.logger.error("[PathaoCourierConfig] fetch_and_save_pathao_store_id failed: #{e.class} — #{e.message}")
    end
  end
end
