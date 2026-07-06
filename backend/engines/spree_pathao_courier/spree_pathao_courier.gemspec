# frozen_string_literal: true

require_relative 'lib/spree_pathao_courier/version'

Gem::Specification.new do |spec|
  spec.name        = 'spree_pathao_courier'
  spec.version     = SpreePathaoCourier::VERSION
  spec.authors     = ['Mahabub LLC']
  spec.summary     = 'Spree Commerce integration for Pathao Courier'
  spec.description = 'Create shipments via Pathao Courier from the Spree Admin panel with tracking number support.'
  spec.license     = 'MIT'

  spec.files = Dir['{app,config,lib}/**/*', 'README.md', 'LICENSE.txt']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'spree_core', '>= 5.5.0'
  spec.add_dependency 'spree_api', '>= 5.5.0'
  spec.add_dependency 'faraday', '~> 2.0'
end
