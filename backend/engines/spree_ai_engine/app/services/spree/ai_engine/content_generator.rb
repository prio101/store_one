# frozen_string_literal: true

module Spree
  module AiEngine
    class ContentGenerator
      attr_reader :config, :errors

      def initialize(config)
        @config = config
        @errors = []
      end

      # Generate content for a given work task
      #
      # @param task_name [String] the work task name (e.g. "product_description")
      # @param variables [Hash] template variables (e.g. { product_name: "Widget", brand: "Acme" })
      # @param prompt_name [String, nil] optional specific prompt name; falls back to default
      # @return [String, nil] generated content, or nil on failure
      def generate(task_name:, variables: {}, prompt_name: nil)
        work_task = find_work_task(task_name)
        return nil unless work_task

        prompt = find_prompt(work_task, prompt_name)
        return nil unless prompt

        rendered = prompt.render_template(**variables)

        provider = SpreeAiEngine.provider_for(config)
        provider.generate(
          prompt: rendered,
          system_prompt: config.system_prompt
        )
      rescue => e
        @errors << e.message
        Rails.logger.error("[Spree::AiEngine::ContentGenerator] Error: #{e.message}")
        nil
      end

      private

      def find_work_task(task_name)
        work_task = config.ai_engine_work_tasks.active.find_by(name: task_name)

        unless work_task
          @errors << "Work task '#{task_name}' not found or inactive"
          return nil
        end

        work_task
      end

      def find_prompt(work_task, prompt_name = nil)
        prompts = work_task.ai_engine_prompts.active

        prompt = if prompt_name.present?
                   prompts.find_by(name: prompt_name)
                 else
                   prompts.defaults.first || prompts.first
                 end

        unless prompt
          @errors << "No active prompt found for work task '#{work_task.name}'"
          return nil
        end

        prompt
      end
    end
  end
end
