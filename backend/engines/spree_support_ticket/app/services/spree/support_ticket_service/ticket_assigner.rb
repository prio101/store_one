# frozen_string_literal: true

module Spree
  module SupportTicketService
    class TicketAssigner
      attr_reader :ticket, :errors

      # @param ticket [Spree::SupportTicket]
      # @param assigned_to [Spree::AdminUser, nil] specific agent to assign, or nil for auto-assign
      def initialize(ticket:, assigned_to: nil)
        @ticket = ticket
        @assigned_to = assigned_to
        @errors = []
      end

      def call
        agent = @assigned_to || find_available_agent

        if agent.nil?
          return Result.new(success: false, errors: ['No available customer support agents'])
        end

        @ticket.assigned_to = agent
        @ticket.status = :in_progress

        if @ticket.save
          create_assignment_message(agent)
          Result.new(success: true, ticket: @ticket)
        else
          Result.new(success: false, errors: @ticket.errors.full_messages)
        end
      end

      private

      def find_available_agent
        # Get all customer_support role users
        support_role = Spree::Role.find_by(name: 'customer_support')
        return nil unless support_role

        agent_ids = Spree::AdminUser.joins(:spree_roles)
                                     .where(spree_roles: { id: support_role.id })
                                     .pluck(:id)

        return nil if agent_ids.empty?

        # Find agent with least active assigned tickets
        ticket_counts = Spree::SupportTicket.active
                                            .where(assigned_to_id: agent_ids)
                                            .group(:assigned_to_id)
                                            .count

        # Include agents with zero tickets
        agent_ids.each do |id|
          ticket_counts[id] ||= 0
        end

        least_loaded_id = ticket_counts.min_by { |_id, count| count }&.first
        Spree::AdminUser.find_by(id: least_loaded_id)
      end

      def create_assignment_message(agent)
        @ticket.messages.create!(
          sender: agent,
          body: "This ticket has been assigned to #{agent.full_name}. We will respond shortly.",
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
