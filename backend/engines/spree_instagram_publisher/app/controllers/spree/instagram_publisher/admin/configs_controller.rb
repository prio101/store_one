# frozen_string_literal: true

module Spree
  module InstagramPublisher
    module Admin
      class ConfigsController < Spree::Admin::BaseController
        before_action :load_config, only: %i[edit update publish_product]

        def index
          add_breadcrumb 'Instagram'
          @breadcrumb_icon = 'camera'

          @config = Spree::InstagramPublisherConfig.find_by(store: current_store)

          if @config
            redirect_to edit_admin_instagram_publisher_config_path(@config)
          else
            redirect_to new_admin_instagram_publisher_config_path
          end
        end

        def new
          add_breadcrumb 'Instagram', admin_instagram_publisher_configs_path
          add_breadcrumb Spree.t(:new)
          @breadcrumb_icon = 'camera'

          @config = Spree::InstagramPublisherConfig.new(
            store: current_store,
            enabled: false,
            auto_publish: false
          )
        end

        def create
          @config = Spree::InstagramPublisherConfig.new(config_params)
          @config.store = current_store

          if @config.save
            resolve_ig_account if @config.enabled?
            redirect_to edit_admin_instagram_publisher_config_path(@config),
                        notice: 'Instagram Publisher configuration saved successfully.'
          else
            render :new, status: :unprocessable_entity
          end
        end

        def edit
          add_breadcrumb 'Instagram', admin_instagram_publisher_configs_path
          add_breadcrumb @config.id
          @breadcrumb_icon = 'camera'
        end

        def update
          if @config.update(config_params)
            resolve_ig_account if @config.enabled? && !@config.resolved_ig_account?
            redirect_to edit_admin_instagram_publisher_config_path(@config),
                        notice: 'Instagram Publisher configuration updated successfully.'
          else
            render :edit, status: :unprocessable_entity
          end
        end

        def publish_product
          product = Spree::Product.find(params[:product_id])

          Rails.logger.info("[InstagramPublisher] ▶ publish_product — product_id: #{product.id}, " \
            "config_id: #{@config.id}, enabled: #{@config.enabled}, resolved: #{@config.resolved_ig_account?}, " \
            "ig_user_id: #{@config.ig_business_account_id.inspect}")

          unless @config.enabled? && @config.resolved_ig_account?
            Rails.logger.warn("[InstagramPublisher] ✘ config not ready — enabled: #{@config.enabled}, " \
              "ig_business_account_id: #{@config.ig_business_account_id.inspect}")
            redirect_to edit_admin_instagram_publisher_config_path(@config),
                        alert: 'Instagram integration is not properly configured. Please enable and configure the integration first.'
            return
          end

          publisher = Spree::InstagramPublisher::Publisher.new(@config)
          result = publisher.publish(product: product)

          Rails.logger.info("[InstagramPublisher] result — success: #{result[:success]}, " \
            "media_id: #{result[:media_id].inspect}, error: #{result[:error].inspect}")

          if result[:success]
            @config.update(last_publish_at: Time.current)
            redirect_to after_publish_redirect(product),
                        notice: "Product published to Instagram successfully. Media ID: #{result[:media_id]}"
          else
            redirect_to after_publish_redirect(product),
                        alert: "Failed to publish to Instagram: #{result[:error]}"
          end
        rescue => e
          Rails.logger.error("[InstagramPublisher] ✘ publish_product EXCEPTION: #{e.class} — #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
          redirect_to after_publish_redirect(product),
                      alert: "An error occurred while publishing to Instagram: #{e.message}"
        end

        private

        def load_config
          @config = Spree::InstagramPublisherConfig.find(params[:id])
        end

        def config_params
          permitted = params.require(:instagram_publisher_config).permit(
            :store_id, :enabled, :app_id, :app_secret,
            :page_id, :page_access_token, :ig_business_account_id,
            :default_caption_template, :auto_publish
          )

          # Strip empty values from encrypted fields so blank submits don't overwrite existing tokens
          if @config&.persisted?
            %i[app_secret page_access_token].each do |field|
              if permitted[field].blank?
                permitted.delete(field)
              end
            end
          end

          permitted
        end

        def after_publish_redirect(product)
          if params[:redirect_to_table] == 'true'
            spree.admin_products_path
          else
            spree.edit_admin_product_path(product)
          end
        end

        def resolve_ig_account
          client = Spree::InstagramPublisher::Client.new(@config)
          ig_account_id = client.resolve_ig_business_account(@config.page_id)

          if ig_account_id.present?
            update_attrs = { ig_business_account_id: ig_account_id }

            # Also fetch username and profile picture
            profile = client.verify_ig_account(ig_account_id)
            if profile.is_a?(Hash)
              update_attrs[:ig_username] = profile['username'] if profile['username'].present?
              update_attrs[:ig_profile_picture_url] = profile['profile_picture_url'] if profile['profile_picture_url'].present?
            end

            @config.update(update_attrs)
            Rails.logger.info("[InstagramPublisherConfig] resolved IG account — id: #{ig_account_id}, username: #{update_attrs[:ig_username]}")
          else
            Rails.logger.warn("[InstagramPublisherConfig] could not resolve ig_business_account_id for config ##{@config.id}")
          end
        rescue => e
          Rails.logger.error("[InstagramPublisherConfig] resolve_ig_account failed: #{e.class} — #{e.message}")
        end
      end
    end
  end
end
