# frozen_string_literal: true

Rails.application.config.after_initialize do
  Rails.application.config.spree_admin.order_page_sidebar_partials << 'spree/pathao_courier/admin/courier/tracking_section'
end
