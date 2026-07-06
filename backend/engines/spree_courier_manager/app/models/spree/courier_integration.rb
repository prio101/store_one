# frozen_string_literal: true

module Spree
  class CourierIntegration < Spree.base_class
    belongs_to :store, class_name: 'Spree::Store'

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: { scope: :store_id }

    scope :enabled, -> { where(enabled: true) }
    scope :ordered, -> { order(:position) }

    AVAILABLE_SLUGS = %w[pathao].freeze

    DEFAULT_COURIERS = [
      {
        name: 'Pathao Courier',
        slug: 'pathao',
        icon: 'truck',
        logo: 'spree/courier_manager/logos/pathao.svg',
        description: 'Pathao Courier shipping integration for domestic deliveries.',
        config_url: '/admin/pathao_courier_configs',
        available: true,
        position: 0
      },
      {
        name: 'Steadfast',
        slug: 'steadfast',
        icon: 'truck',
        logo: 'spree/courier_manager/logos/steadfast.svg',
        description: 'Steadfast courier integration.',
        config_url: nil,
        available: false,
        position: 1
      },
      {
        name: 'Redx',
        slug: 'redx',
        icon: 'truck',
        logo: 'spree/courier_manager/logos/redx.svg',
        description: 'Redx courier integration.',
        config_url: nil,
        available: false,
        position: 2
      },
      {
        name: 'Sundarban',
        slug: 'sundarban',
        icon: 'truck',
        logo: 'spree/courier_manager/logos/sundarban.png',
        description: 'Sundarban courier integration.',
        config_url: nil,
        available: false,
        position: 3
      }
    ].freeze

    def self.ensure_defaults_for!(store)
      DEFAULT_COURIERS.each do |courier|
        record = find_or_initialize_by(store: store, slug: courier[:slug])
        record.assign_attributes(courier.except(:slug))
        record.save!
      end
    end

    def toggle_enabled!
      update!(enabled: !enabled)
    end
  end
end
