# frozen_string_literal: true

module Spree
  module AiEngine
    module Admin
      class WorkTasksController < BaseController
        add_breadcrumb_icon 'cpu'
        before_action :load_config
        before_action :load_work_task, only: %i[edit update destroy]

        def index
          add_breadcrumb "AI Settings", :admin_ai_engine_configs_path
          add_breadcrumb @config.provider_label, edit_admin_ai_engine_config_path(@config)
          add_breadcrumb "Work Tasks"
          @work_tasks = @config.ai_engine_work_tasks.order(:name)
        end

        def new
          add_breadcrumb "AI Settings", :admin_ai_engine_configs_path
          add_breadcrumb @config.provider_label, edit_admin_ai_engine_config_path(@config)
          add_breadcrumb "Work Tasks", admin_ai_engine_config_ai_engine_work_tasks_path(@config)
          add_breadcrumb "New"
          @work_task = @config.ai_engine_work_tasks.new(active: true)
        end

        def create
          @work_task = @config.ai_engine_work_tasks.new(work_task_params)

          if @work_task.save
            flash[:success] = "Work task created successfully."
            redirect_to admin_ai_engine_config_ai_engine_work_tasks_path(@config)
          else
            render :new, status: :unprocessable_entity
          end
        end

        def edit
          add_breadcrumb "AI Settings", :admin_ai_engine_configs_path
          add_breadcrumb @config.provider_label, edit_admin_ai_engine_config_path(@config)
          add_breadcrumb "Work Tasks", admin_ai_engine_config_ai_engine_work_tasks_path(@config)
          add_breadcrumb @work_task.label
        end

        def update
          if @work_task.update(work_task_params)
            flash[:success] = "Work task updated successfully."
            redirect_to admin_ai_engine_config_ai_engine_work_tasks_path(@config)
          else
            render :edit, status: :unprocessable_entity
          end
        end

        def destroy
          @work_task.destroy
          flash[:success] = "Work task deleted."
          redirect_to admin_ai_engine_config_ai_engine_work_tasks_path(@config)
        end

        private

        def load_config
          @config = Spree::AiEngineConfig.find(params[:ai_engine_config_id])
        end

        def load_work_task
          @work_task = @config.ai_engine_work_tasks.find(params[:id])
        end

        def work_task_params
          params.require(:ai_engine_work_task).permit(:name, :description, :active)
        end
      end
    end
  end
end
