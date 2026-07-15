# frozen_string_literal: true

module SpreeSupportTicket
  class Engine < ::Rails::Engine
    isolate_namespace SpreeSupportTicket

    initializer 'spree_support_ticket.append_migrations' do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    initializer 'spree_support_ticket.navigation' do
      Rails.application.config.after_initialize do
        Spree.admin.navigation.sidebar.add :support_tickets,
          label: 'Support Tickets',
          url: -> { Spree::Core::Engine.routes.url_helpers.admin_support_tickets_path },
          icon: 'headset',
          position: 97,
          if: -> { can?(:manage, Spree::SupportTicket) }
      end
    end
  end
end
