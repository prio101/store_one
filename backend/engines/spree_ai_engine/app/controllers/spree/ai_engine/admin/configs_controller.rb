# frozen_string_literal: true

module Spree
  module AiEngine
    module Admin
      class ConfigsController < BaseController
        add_breadcrumb_icon 'cpu'
        before_action :load_config, only: %i[edit update destroy]

        def index
          add_breadcrumb "AI Settings"
          @configs = Spree::AiEngineConfig.includes(:store).order(created_at: :desc)
        end

        def new
          add_breadcrumb "AI Settings", :admin_ai_engine_configs_path
          add_breadcrumb "New"
          @config = Spree::AiEngineConfig.new(
            provider: "gemini",
            ai_model_name: "gemini-2.0-flash",
            temperature: 0.7,
            max_output_tokens: 2048,
            logging_enabled: true,
            active: true
          )
        end

        def create
          @config = Spree::AiEngineConfig.new(config_params)

          if @config.save
            flash[:success] = "AI Engine configuration created successfully."
            redirect_to edit_admin_ai_engine_config_path(@config)
          else
            render :new, status: :unprocessable_entity
          end
        end

        def edit
          add_breadcrumb "AI Settings", :admin_ai_engine_configs_path
          add_breadcrumb @config.provider_label
        end

        def update
          params_to_update = config_params
          # If api_key is blank on update, remove it from params to keep existing
          if params_to_update[:api_key].blank?
            params_to_update = params_to_update.except(:api_key)
          end

          if @config.update(params_to_update)
            flash[:success] = "AI Engine configuration updated successfully."
            redirect_to edit_admin_ai_engine_config_path(@config)
          else
            render :edit, status: :unprocessable_entity
          end
        end

        def destroy
          @config.destroy
          flash[:success] = "AI Engine configuration deleted."
          redirect_to admin_ai_engine_configs_path
        end

        def test_connection
          config = Spree::AiEngineConfig.find(params[:id])
          provider = SpreeAiEngine.provider_for(config)

          if provider.health_check
            render json: { success: true, message: "Connection successful! API key is valid." }
          else
            render json: { success: false, message: "Connection failed. Please check your API key." }
          end
        rescue => e
          render json: { success: false, message: "Error: #{e.message}" }
        end

        private

        def load_config
          @config = Spree::AiEngineConfig.find(params[:id])
        end

        def config_params
          params.require(:ai_engine_config).permit(
            :store_id, :provider, :api_key, :ai_model_name,
            :temperature, :max_output_tokens, :system_prompt,
            :rate_limit_rpm, :logging_enabled, :active
          )
        end
      end
    end
  end
end
