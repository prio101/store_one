# frozen_string_literal: true

require 'spree_dev_tools/rspec/spec_helper'
require_relative '../app/services/spree/instagram_publisher/error'

Dir[File.join(__dir__, 'support/**/*.rb')].each { |f| require f }
