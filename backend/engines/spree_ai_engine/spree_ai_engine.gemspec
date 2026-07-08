# frozen_string_literal: true

require_relative "lib/spree_ai_engine/version"

Gem::Specification.new do |spec|
  spec.name = "spree_ai_engine"
  spec.version = SpreeAiEngine::VERSION
  spec.authors = ["Mahabub LLC"]
  spec.email = ["dev@mahabubllc.com"]

  spec.summary = "AI Provider abstraction for Spree Commerce"
  spec.description = "Provides a unified interface for AI model providers (Gemini, OpenAI, etc.) " \
                     "with per-store configuration and admin settings UI."
  spec.homepage = "https://github.com/mahabubllc/spree_ai_engine"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir["{app,config,db,lib}/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "spree_core", ">= 5.5.0"
  spec.add_dependency "spree_api", ">= 5.5.0"
  spec.add_dependency "spree_admin", ">= 5.5.0"
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "rails", ">= 7.0"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "spree_dev_tools"
end
