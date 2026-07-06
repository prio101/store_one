# frozen_string_literal: true

module Spree
  module PathaoCourier
    module Admin
      class CourierController < Spree::Admin::BaseController
        before_action :find_order
        before_action :find_config

        # POST /admin/orders/:order_id/courier/estimate_cost
        def estimate_cost
          delivery_type = params[:delivery_type]&.to_i || Spree::CourierDeliveryTrackingInformation::DELIVERY_TYPE_NORMAL
          item_type = params[:item_type]&.to_i || @config.default_item_type
          item_weight = params[:item_weight]&.to_i || @config.default_weight

          Rails.logger.info("[PathaoCourier] estimate_cost called — order: #{@order.number}, " \
            "delivery_type: #{delivery_type.inspect} (raw: #{params[:delivery_type].inspect}), " \
            "item_type: #{item_type.inspect} (raw: #{params[:item_type].inspect}), " \
            "item_weight: #{item_weight.inspect} (raw: #{params[:item_weight].inspect}), " \
            "config_id: #{@config.id}, store: #{@config.store.name}")

          service = Spree::PathaoCourier::CheckoutService.new(
            order: @order,
            config: @config,
            delivery_type: delivery_type,
            item_type: item_type,
            item_weight: item_weight
          )

          result = service.estimate_cost

          Rails.logger.info("[PathaoCourier] estimate_cost result — cost: #{result[:cost].inspect}, " \
            "address: #{result[:address_data].inspect}")

          render json: {
            success: true,
            cost: result[:cost],
            address: result[:address_data]
          }
        rescue Spree::PathaoCourier::AddressNotFoundError => e
          Rails.logger.error("[PathaoCourier] Address not found: #{e.message}\n  #{e.backtrace&.first(5)&.join("\n  ")}")
          render json: { success: false, error: "Address resolution failed: #{e.message}" }, status: :unprocessable_entity
        rescue StandardError => e
          Rails.logger.error("[PathaoCourier] Cost estimation failed: #{e.class} — #{e.message}\n  #{e.backtrace&.first(10)&.join("\n  ")}")
          render json: { success: false, error: "Cost estimation failed: #{e.message}" }, status: :internal_server_error
        end

        # POST /admin/orders/:order_id/courier/confirm
        def confirm
          Rails.logger.info("[PathaoCourier] confirm called — order: #{@order.number}, config_id: #{@config.id}, store: #{@config.store.name}")
          delivery_type = params[:delivery_type]&.to_i || Spree::CourierDeliveryTrackingInformation::DELIVERY_TYPE_NORMAL
          item_type = params[:item_type]&.to_i || @config.default_item_type
          item_weight = params[:item_weight]&.to_i || @config.default_weight
          note = params[:note]
          Rails.logger.info("[PathaoCourier] confirm parameters — delivery_type: #{delivery_type.inspect} (raw: #{params[:delivery_type].inspect}), " \
            "item_type: #{item_type.inspect} (raw: #{params[:item_type].inspect}), item_weight: #{item_weight.inspect} (raw: #{params[:item_weight].inspect})")
          service = Spree::PathaoCourier::CheckoutService.new(
            order: @order,
            config: @config,
            delivery_type: delivery_type,
            item_type: item_type,
            item_weight: item_weight,
            note: note
          )
          Rails.logger.info("[PathaoCourier] Calling service.confirm! for order #{@order.number}")
          tracking_info = service.confirm!

          Rails.logger.info("[PathaoCourier] Confirm succeeded — tracking_info id: #{tracking_info.id}, consignment_id: #{tracking_info.consignment_id}")
          render json: {
            success: true,
            tracking_info: {
              id: tracking_info.id,
              consignment_id: tracking_info.consignment_id,
              tracking_display: tracking_info.tracking_display,
              order_status: tracking_info.order_status
            }
          }
        rescue Spree::PathaoCourier::ShippingError => e
          handle_error(e, "Shipment creation failed")
        rescue StandardError => e
          Rails.logger.error("[PathaoCourier] Confirm failed: #{e.class} — #{e.message}\n  #{e.backtrace&.first(10)&.join("\n  ")}")
          handle_error(e, "Confirmation failed")
        end

        # GET /admin/orders/:order_id/courier/tracking
        def tracking
          tracking_info = Spree::CourierDeliveryTrackingInformation
                            .where(order: @order)
                            .order(created_at: :desc)
                            .first

          if tracking_info
            render json: {
              success: true,
              tracking_info: {
                id: tracking_info.id,
                consignment_id: tracking_info.consignment_id,
                tracking_display: tracking_info.tracking_display,
                recipient_name: tracking_info.recipient_name,
                recipient_phone: tracking_info.recipient_phone,
                recipient_address: tracking_info.recipient_address,
                delivery_type: tracking_info.delivery_type,
                delivery_type_name: tracking_info.delivery_type_name,
                shipping_cost: tracking_info.shipping_cost,
                cod_amount: tracking_info.cod_amount,
                total_to_collect: tracking_info.total_to_collect,
                estimated_delivery: tracking_info.estimated_delivery,
                order_status: tracking_info.order_status,
                confirmed: tracking_info.confirmed?,
                confirmed_at: tracking_info.confirmed_at
              }
            }
          else
            render json: { success: true, tracking_info: nil }
          end
        end

        private

        def find_order
          @order = Spree::Order.find_by(number: params[:order_id])
          unless @order
            render json: { success: false, error: "Order not found" }, status: :not_found
          end
        end

        def find_config
          store = @order&.store || Spree::Current.store
          @config = Spree::PathaoCourierConfig.find_by(store: store)

          unless @config
            render json: { success: false, error: "Pathao Courier not configured for this store" }, status: :unprocessable_entity
          end
        end

        def handle_error(error, message)
          if request.format.json?
            render json: { success: false, error: "#{message}: #{error.message}" }, status: :internal_server_error
          else
            flash[:error] = "#{message}: #{error.message}"
            redirect_to spree.edit_admin_order_path(@order)
          end
        end
      end
    end
  end
end
