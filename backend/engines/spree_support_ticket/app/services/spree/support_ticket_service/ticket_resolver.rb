# frozen_string_literal: true

module Spree
  module SupportTicketService
    class TicketResolver
      attr_reader :ticket, :errors

      # @param ticket [Spree::SupportTicket]
      # @param resolved_by [Spree::AdminUser]
      # @param resolution_summary [String]
      # @param action_taken [String, nil] enum value from SupportTicketMessage
      def initialize(ticket:, resolved_by:, resolution_summary:, action_taken: nil)
        @ticket = ticket
        @resolved_by = resolved_by
        @resolution_summary = resolution_summary
        @action_taken = action_taken
        @errors = []
      end

      def call
        if @resolution_summary.blank?
          return Result.new(success: false, errors: ['Resolution summary is required'])
        end

        @ticket.status = :resolved
        @ticket.resolved_at = Time.current

        if @ticket.save
          create_resolution_message
          Result.new(success: true, ticket: @ticket)
        else
          Result.new(success: false, errors: @ticket.errors.full_messages)
        end
      end

      private

      def create_resolution_message
        @ticket.messages.create!(
          sender: @resolved_by,
          body: @resolution_summary,
          resolution_summary: @resolution_summary,
          action_taken: @action_taken,
          is_internal_note: false
        )
      end

      class Result
        attr_reader :ticket, :errors

        def initialize(success:, ticket: nil, errors: [])
          @success = success
          @ticket = ticket
          @errors = errors
        end

        def success?
          @success
        end
      end
    end
  end
end
