# frozen_string_literal: true

module Spree
  module Admin
    class CourierIntegrationsController < Spree::Admin::BaseController
      def index
        add_breadcrumb 'Couriers'

        @integrations = current_store_courier_integrations.ordered
      end

      def toggle
        integration = current_store_courier_integrations.find(params[:id])
        integration.toggle_enabled!

        redirect_to admin_courier_integrations_path,
                    notice: "#{integration.name} #{integration.enabled? ? 'enabled' : 'disabled'}."
      end

      private

      def current_store_courier_integrations
        store = try_spree_current_user&.stores&.first || Spree::Store.first
        Spree::CourierIntegration.ensure_defaults_for!(store)
        Spree::CourierIntegration.where(store: store)
      end
    end
  end
end
