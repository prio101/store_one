# frozen_string_literal: true

module Spree
  module PathaoCourier
    module Admin
      class ShipmentsController < Spree::Admin::BaseController
        before_action :load_shipment
        before_action :load_config

        # POST /admin/orders/:order_id/shipments/:id/ship_with_pathao
        def ship
          unless @config
            redirect_to spree.edit_admin_order_path(@shipment.order),
                        alert: 'Pathao Courier is not configured. Please set up credentials first.'
            return
          end

          creator = Spree::PathaoCourier::OrderCreator.new(
            shipment: @shipment,
            config: @config
          )

          consignment_id = creator.call

          redirect_to spree.edit_admin_order_path(@shipment.order),
                      notice: "Shipment created successfully! Tracking number: #{consignment_id}"
        rescue Spree::PathaoCourier::AuthenticationError => e
          redirect_to spree.edit_admin_order_path(@shipment.order),
                      alert: "Pathao authentication failed: #{e.message}"
        rescue Spree::PathaoCourier::ApiError => e
          redirect_to spree.edit_admin_order_path(@shipment.order),
                      alert: "Pathao API error: #{e.message}"
        rescue Spree::PathaoCourier::ShippingError => e
          redirect_to spree.edit_admin_order_path(@shipment.order),
                      alert: "Shipping error: #{e.message}"
        end

        private

        def load_shipment
          @shipment = Spree::Shipment.find(params[:id])
        end

        def load_config
          store = @shipment.order.store
          @config = Spree::PathaoCourierConfig.find_by(store: store)
        end
      end
    end
  end
end
