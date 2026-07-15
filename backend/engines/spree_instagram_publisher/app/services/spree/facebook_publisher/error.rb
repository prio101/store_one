# frozen_string_literal: true

module Spree
  module FacebookPublisher
    class Error < StandardError; end
    class AuthenticationError < Error; end
    class ApiError < Error; end
    class PublishingError < Error; end
    class RateLimitError < Error; end
  end
end
