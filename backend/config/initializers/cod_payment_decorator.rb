# frozen_string_literal: true

# Decorator for Spree::PaymentMethod::CodPayment.
# spree_cod_payment v2.1.6 was written for an older Spree that used
# ActiveMerchant::Billing::Response. Spree 5.5.0 uses Spree::PaymentResponse.
# This overrides the simulated_successful_billing_response to use the
# correct response class, and adds the missing `authorize` method.
Rails.application.config.to_prepare do
  next unless defined?(Spree::PaymentMethod::CodPayment)

  Spree::PaymentMethod::CodPayment.class_eval do
    def authorize(*)
      simulated_successful_billing_response
    end

    private

    def simulated_successful_billing_response
      Spree::PaymentResponse.new(true, '', {}, {})
    end
  end
end
