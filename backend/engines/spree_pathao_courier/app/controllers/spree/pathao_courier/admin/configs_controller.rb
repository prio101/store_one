# frozen_string_literal: true

module Spree
  module PathaoCourier
    module Admin
      class ConfigsController < Spree::Admin::BaseController
        before_action :load_config, only: %i[edit update]

        def index
          add_breadcrumb Spree.t(:pathao_courier), admin_pathao_courier_configs_path
          @breadcrumb_icon = 'truck'

          @configs = Spree::PathaoCourierConfig.all
        end

        def show
          redirect_to action: :edit
        end

        def new
          add_breadcrumb Spree.t(:pathao_courier), admin_pathao_courier_configs_path
          add_breadcrumb Spree.t(:new)
          @breadcrumb_icon = 'truck'

          @config = Spree::PathaoCourierConfig.new(
            store: current_store,
            sandbox: true,
            default_delivery_type: 48,
            default_item_type: 2,
            default_weight: 500
          )
        end

        def create
          @config = Spree::PathaoCourierConfig.new(config_params)
          @config.store = current_store

          if @config.save
            redirect_to edit_admin_pathao_courier_config_path(@config),
                        notice: 'Pathao Courier configuration saved successfully.'
          else
            render :new, status: :unprocessable_entity
          end
        end

        def edit
          add_breadcrumb Spree.t(:pathao_courier), admin_pathao_courier_configs_path
          add_breadcrumb @config.id
          @breadcrumb_icon = 'truck'
        end

        def update
          if @config.update(config_params)
            redirect_to edit_admin_pathao_courier_config_path(@config),
                        notice: 'Pathao Courier configuration updated successfully.'
          else
            render :edit, status: :unprocessable_entity
          end
        end

        private

        def load_config
          @config = Spree::PathaoCourierConfig.find(params[:id])
        end

        def config_params
          params.require(:pathao_courier_config).permit(
            :store_id, :base_url, :client_id, :client_secret,
            :username, :password, :sandbox, :active, :pathao_store_id,
            :default_delivery_type, :default_item_type, :default_weight
          )
        end
      end
    end
  end
end
