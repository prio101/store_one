# frozen_string_literal: true

Rails.application.config.after_initialize do
  # Sidebar partial on product edit page (right column)
  Rails.application.config.spree_admin.product_form_sidebar_partials << 'spree/instagram_publisher/admin/configs/publish_button'

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
end
