# frozen_string_literal: true

require_relative 'lib/spree_support_ticket/version'

Gem::Specification.new do |spec|
  spec.name        = 'spree_support_ticket'
  spec.version     = SpreeSupportTicket::VERSION
  spec.authors     = ['Mahabub LLC']
  spec.summary     = 'Spree Commerce Support Ticket Management System'
  spec.description = 'Support ticket management system for Spree Admin panel with customer-facing ticket creation.'
  spec.license     = 'MIT'

  spec.files = Dir['{app,config,lib}/**/*', 'README.md', 'LICENSE.txt']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'spree_core', '>= 5.5.0'
  spec.add_dependency 'spree_api', '>= 5.5.0'
end
