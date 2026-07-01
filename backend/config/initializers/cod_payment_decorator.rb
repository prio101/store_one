# frozen_string_literal: true

# Decorator for Spree::PaymentMethod::CodPayment.
# spree_cod_payment v2.1.6 does not define `authorize`, but Spree 5.5.0
# calls it during checkout when auto_capture? is false. This adds the
# missing method so COD checkouts don't crash.
Rails.application.config.to_prepare do
  next unless defined?(Spree::PaymentMethod::CodPayment)

  Spree::PaymentMethod::CodPayment.class_eval do
    def authorize(*)
      simulated_successful_billing_response
    end
  end
end
