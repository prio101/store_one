# frozen_string_literal: true

module Spree
  module SupportTicketSystem
    module Admin
      class TicketsController < Spree::Admin::BaseController
        add_breadcrumb_icon 'headset'
        before_action :load_ticket, only: %i[show update assign resolve update_status create_message]

        def index
          add_breadcrumb 'Support Tickets'

          @tickets = Spree::SupportTicket.includes(:user, :assigned_to, :store)

          # Filters
          @tickets = @tickets.by_status(params[:status]) if params[:status].present?
          @tickets = @tickets.by_priority(params[:priority]) if params[:priority].present?

          # Search
          if params[:search].present?
            search_term = "%#{params[:search]}%"
            @tickets = @tickets.joins(:user).where(
              'spree_support_tickets.ticket_number ILIKE :term OR ' \
              'spree_support_tickets.title ILIKE :term OR ' \
              'spree_support_tickets.order_number ILIKE :term OR ' \
              'spree_users.email ILIKE :term',
              term: search_term
            )
          end

          @tickets = @tickets.order(created_at: :desc)
        end

        def show
          add_breadcrumb 'Support Tickets', admin_support_tickets_path
          add_breadcrumb @ticket.ticket_number

          @messages = @ticket.messages.chronological.includes(:sender)
          @message = Spree::SupportTicketMessage.new
        end

        def update
          if @ticket.update(ticket_params)
            redirect_to admin_support_ticket_path(@ticket),
                        notice: 'Ticket updated successfully.'
          else
            redirect_to admin_support_ticket_path(@ticket),
                        alert: @ticket.errors.full_messages.join(', ')
          end
        end

        def create_message
          message = @ticket.messages.build(
            sender: try_spree_current_user,
            body: params[:support_ticket][:body],
            is_internal_note: params[:support_ticket][:is_internal_note] == '1'
          )

          if message.save
            redirect_to admin_support_ticket_path(@ticket),
                        notice: 'Message added successfully.'
          else
            redirect_to admin_support_ticket_path(@ticket),
                        alert: message.errors.full_messages.join(', ')
          end
        end

        def assign
          result = Spree::SupportTicketService::TicketAssigner.new(
            ticket: @ticket,
            assigned_to: params[:assigned_to_id].present? ? Spree::AdminUser.find(params[:assigned_to_id]) : nil
          ).call

          if result.success?
            redirect_to admin_support_ticket_path(@ticket),
                        notice: 'Ticket assigned successfully.'
          else
            redirect_to admin_support_ticket_path(@ticket),
                        alert: result.errors.join(', ')
          end
        end

        def resolve
          result = Spree::SupportTicketService::TicketResolver.new(
            ticket: @ticket,
            resolved_by: try_spree_current_user,
            resolution_summary: params[:resolution_summary],
            action_taken: params[:action_taken]
          ).call

          if result.success?
            redirect_to admin_support_ticket_path(@ticket),
                        notice: 'Ticket resolved successfully.'
          else
            redirect_to admin_support_ticket_path(@ticket),
                        alert: result.errors.join(', ')
          end
        end

        def update_status
          new_status = params[:status]

          unless Spree::SupportTicket.statuses.key?(new_status)
            redirect_to admin_support_ticket_path(@ticket),
                        alert: 'Invalid status'
            return
          end

          @ticket.status = new_status
          @ticket.closed_at = Time.current if new_status == 'closed'

          if @ticket.save
            create_status_change_message(new_status)
            redirect_to admin_support_ticket_path(@ticket),
                        notice: "Ticket status updated to #{new_status.humanize}."
          else
            redirect_to admin_support_ticket_path(@ticket),
                        alert: @ticket.errors.full_messages.join(', ')
          end
        end

        private

        def load_ticket
          @ticket = Spree::SupportTicket.find(params[:id])
        end

        def ticket_params
          params.require(:support_ticket).permit(:priority, :assigned_to_id)
        end

        def create_status_change_message(status)
          @ticket.messages.create!(
            sender: try_spree_current_user,
            body: "Ticket status changed to #{status.humanize}.",
            is_internal_note: false
          )
        end
      end
    end
  end
end
