# frozen_string_literal: true

Rails.application.config.after_initialize do
  # Sidebar partial on product edit page (right column)
  Rails.application.config.spree_admin.product_form_sidebar_partials << 'spree/instagram_publisher/admin/configs/publish_button'
  Rails.application.config.spree_admin.product_form_sidebar_partials << 'spree/instagram_publisher/admin/configs/facebook_publish_button'

  # Products table: add "Instagram" column after :status (position 20)
  Spree.admin.tables.products.insert_after :status,
                                           :instagram_publish,
                                           label: 'Instagram',
                                           type: :custom,
                                           sortable: false,
                                           filterable: false,
                                           default: true,
                                           position: 22,
                                           partial: 'spree/instagram_publisher/admin/configs/instagram_publish_column'

  # Rails console helper — call `ig_diagnose` or `ig_diagnose(store)`
  if defined?(IRB) || defined?(Pry) || Rails.const_defined?(:Console)
    unless Object.method_defined?(:ig_diagnose)
      Object.define_method(:ig_diagnose) do |store_or_id = nil|
        config = if store_or_id.is_a?(Spree::Store)
                   Spree::InstagramPublisherConfig.find_by(store: store_or_id)
                 elsif store_or_id.is_a?(Integer) || store_or_id.is_a?(String)
                   Spree::InstagramPublisherConfig.find_by(store_id: store_or_id)
                 else
                   Spree::InstagramPublisherConfig.first
                 end

        raise 'No Instagram Publisher config found' unless config

        tm = Spree::InstagramPublisher::TokenManager.new(config)
        result = tm.diagnose
        puts result.pretty_inspect
        result
      end
    end
  end
end
