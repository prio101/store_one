# frozen_string_literal: true

module Spree
  module SupportTicketSystem
    class UserTicketsController < Spree::Api::V3::BaseController
      before_action :require_user
      before_action :load_ticket, only: %i[show create_message]

      # GET /api/v3/store/support_tickets
      def index
        tickets = Spree::SupportTicket.where(user: current_user)
                                       .includes(:assigned_to)
                                       .order(created_at: :desc)

        render json: {
          tickets: tickets.map { |t| ticket_json(t) },
          meta: {
            active_count: tickets.active.count,
            total_count: tickets.count,
            max_active: 5
          }
        }
      end

      # GET /api/v3/store/support_tickets/:id
      def show
        render json: {
          ticket: ticket_json(@ticket, include_messages: true)
        }
      end

      # POST /api/v3/store/support_tickets
      def create
        image = params[:image]

        result = Spree::SupportTicketService::TicketCreator.new(
          user: current_user,
          params: ticket_params,
          image: image
        ).call

        if result.success?
          render json: {
            ticket: ticket_json(result.ticket),
            message: 'Support ticket created successfully. We will respond in 10-16 hours due to high traffic.'
          }, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      # POST /api/v3/store/support_tickets/:id/messages
      def create_message
        return render json: { errors: ['Message body is required'] }, status: :unprocessable_entity if params[:body].blank?

        message = @ticket.messages.build(
          sender: current_user,
          body: params[:body]
        )

        if message.save
          render json: { message: message_json(message) }, status: :created
        else
          render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def require_user
        unless current_user
          render json: { error: 'You must be logged in to access support tickets' }, status: :unauthorized
        end
      end

      def load_ticket
        @ticket = Spree::SupportTicket.find_by(id: params[:id], user: current_user)

        unless @ticket
          render json: { error: 'Support ticket not found' }, status: :not_found
        end
      end

      def ticket_params
        params.permit(:order_number, :title, :body, :subject, :priority)
      end

      def ticket_json(ticket, include_messages: false)
        data = {
          id: ticket.id,
          ticket_number: ticket.ticket_number,
          order_number: ticket.order_number,
          title: ticket.title,
          subject: ticket.subject,
          body: ticket.body,
          status: ticket.status,
          priority: ticket.priority,
          assigned_to: ticket.assigned_to&.full_name,
          has_image: ticket.image.attached?,
          created_at: ticket.created_at.iso8601,
          updated_at: ticket.updated_at.iso8601
        }

        if include_messages
          data[:messages] = ticket.messages.chronological.includes(:sender).map { |m| message_json(m) }
        end

        data
      end

      def message_json(message)
        {
          id: message.id,
          sender_type: message.sender_type == 'Spree::AdminUser' ? 'support' : 'user',
          body: message.body,
          resolution_summary: message.resolution_summary,
          action_taken: message.action_taken,
          is_internal_note: message.is_internal_note,
          created_at: message.created_at.iso8601
        }
      end
    end
  end
end
