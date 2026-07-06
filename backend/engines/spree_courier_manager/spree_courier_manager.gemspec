# frozen_string_literal: true

require_relative 'lib/spree_courier_manager/version'

Gem::Specification.new do |spec|
  spec.name        = 'spree_courier_manager'
  spec.version     = SpreeCourierManager::VERSION
  spec.authors     = ['Mahabub LLC']
  spec.summary     = 'Spree Commerce courier integration manager'
  spec.description = 'Manage courier integrations (Pathao, Steadfast, Redx, Sundarban) with card-based enable/disable UI.'
  spec.license     = 'MIT'

  spec.files = Dir['{app,config,lib}/**/*', 'README.md', 'LICENSE.txt']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'spree_core', '>= 5.5.0'
  spec.add_dependency 'spree_api', '>= 5.5.0'
  spec.add_dependency 'spree_admin', '>= 5.5.0'
end
