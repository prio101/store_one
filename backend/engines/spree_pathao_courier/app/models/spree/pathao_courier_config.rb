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
  end
end
