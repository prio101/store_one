# frozen_string_literal: true

module Spree
  module PathaoCourier
    class Error < StandardError; end
    class AuthenticationError < Error; end
    class ApiError < Error; end
    class ShippingError < Error; end
  end
end
