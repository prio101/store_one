# frozen_string_literal: true

module Spree
  module AiEngine
    module Admin
      class PromptsController < BaseController
        add_breadcrumb_icon 'cpu'
        before_action :load_config
        before_action :load_work_task
        before_action :load_prompt, only: %i[edit update destroy]

        def index
          add_breadcrumb "AI Settings", :admin_ai_engine_configs_path
          add_breadcrumb @config.provider_label, edit_admin_ai_engine_config_path(@config)
          add_breadcrumb "Work Tasks", admin_ai_engine_config_ai_engine_work_tasks_path(@config)
          add_breadcrumb @work_task.label, admin_ai_engine_config_ai_engine_work_task_ai_engine_prompts_path(@config, @work_task)
          add_breadcrumb "Prompts"
          @prompts = @work_task.ai_engine_prompts.order(:name)
        end

        def new
          add_breadcrumb "AI Settings", :admin_ai_engine_configs_path
          add_breadcrumb @config.provider_label, edit_admin_ai_engine_config_path(@config)
          add_breadcrumb "Work Tasks", admin_ai_engine_config_ai_engine_work_tasks_path(@config)
          add_breadcrumb @work_task.label, admin_ai_engine_config_ai_engine_work_task_ai_engine_prompts_path(@config, @work_task)
          add_breadcrumb "Prompts"
          add_breadcrumb "New"
          @prompt = @work_task.ai_engine_prompts.new(active: true)
        end

        def create
          @prompt = @work_task.ai_engine_prompts.new(prompt_params)

          if @prompt.save
            flash[:success] = "Prompt created successfully."
            redirect_to admin_ai_engine_config_ai_engine_work_task_ai_engine_prompts_path(@config, @work_task)
          else
            render :new, status: :unprocessable_entity
          end
        end

        def edit
          add_breadcrumb "AI Settings", :admin_ai_engine_configs_path
          add_breadcrumb @config.provider_label, edit_admin_ai_engine_config_path(@config)
          add_breadcrumb "Work Tasks", admin_ai_engine_config_ai_engine_work_tasks_path(@config)
          add_breadcrumb @work_task.label, admin_ai_engine_config_ai_engine_work_task_ai_engine_prompts_path(@config, @work_task)
          add_breadcrumb "Prompts"
          add_breadcrumb @prompt.name
        end

        def update
          if @prompt.update(prompt_params)
            flash[:success] = "Prompt updated successfully."
            redirect_to admin_ai_engine_config_ai_engine_work_task_ai_engine_prompts_path(@config, @work_task)
          else
            render :edit, status: :unprocessable_entity
          end
        end

        def destroy
          @prompt.destroy
          flash[:success] = "Prompt deleted."
          redirect_to admin_ai_engine_config_ai_engine_work_task_ai_engine_prompts_path(@config, @work_task)
        end

        private

        def load_config
          @config = Spree::AiEngineConfig.find(params[:ai_engine_config_id])
        end

        def load_work_task
          @work_task = @config.ai_engine_work_tasks.find(params[:ai_engine_work_task_id])
        end

        def load_prompt
          @prompt = @work_task.ai_engine_prompts.find(params[:id])
        end

        def prompt_params
          params.require(:ai_engine_prompt).permit(:name, :prompt_template, :is_default, :active)
        end
      end
    end
  end
end
