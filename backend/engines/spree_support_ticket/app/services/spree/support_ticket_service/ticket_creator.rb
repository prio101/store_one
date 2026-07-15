# frozen_string_literal: true

module Spree
  module SupportTicketService
    class TicketCreator
      attr_reader :ticket, :errors

      # @param user [Spree::User]
      # @param params [Hash] ticket attributes
      # @param image [ActiveStorage::Attachment, nil]
      def initialize(user:, params:, image: nil)
        @user = user
        @params = params
        @image = image
        @errors = []
      end

      def call
        @ticket = Spree::SupportTicket.new(ticket_params)
        @ticket.user = @user
        @ticket.store = @user.stores.first || Spree::Current.store
        @ticket.status = :pending
        @ticket.priority ||= :low

        if @image.present?
          @ticket.image.attach(@image)
        end

        if @ticket.save
          handle_guest_order_conversion if order_needs_user_assignment?
          Result.new(success: true, ticket: @ticket)
        else
          Result.new(success: false, errors: @ticket.errors.full_messages)
        end
      end

      private

      def ticket_params
        @params.permit(:order_number, :title, :body, :subject, :priority)
      end

      def order_needs_user_assignment?
        return false unless @ticket.order.present?
        return false if @ticket.order.user_id.present?

        @ticket.order.email.present? && @ticket.order.email.casecmp(@user.email).zero?
      end

      def handle_guest_order_conversion
        order = @ticket.order
        order.update!(user: @user)
        Rails.logger.info("[SupportTicket] Guest order #{order.number} assigned to user #{@user.id} via email match")
      rescue => e
        Rails.logger.error("[SupportTicket] Failed to assign guest order: #{e.message}")
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
