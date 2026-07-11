# frozen_string_literal: true

require_relative 'lib/spree_instagram_publisher/version'

Gem::Specification.new do |spec|
  spec.name        = 'spree_instagram_publisher'
  spec.version     = SpreeInstagramPublisher::VERSION
  spec.authors     = ['Mahabub LLC']
  spec.summary     = 'Spree Commerce Instagram Content Publishing integration'
  spec.description = 'Publish product details with images to Instagram Shop Pages via the Meta Content Publishing API.'
  spec.license     = 'MIT'

  spec.files = Dir['{app,config,lib}/**/*', 'README.md', 'LICENSE.txt']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.2'

  spec.add_dependency 'spree_core', '>= 5.5.0'
  spec.add_dependency 'spree_api', '>= 5.5.0'
  spec.add_dependency 'faraday', '~> 2.0'
end
