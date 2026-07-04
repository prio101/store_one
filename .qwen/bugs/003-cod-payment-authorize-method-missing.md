# BUG-003: CodPayment missing `authorize` method — checkout crashes

**Status:** Fixed
**Severity:** High — users cannot complete checkout with COD payment
**Reported:** 2026-07-01
**Sentry:** NoMethodError: undefined method 'authorize' for Spree::PaymentMethod::CodPayment

---

## Description

When a user tries to confirm an order from the cart using the Cash on Delivery (COD) payment method, the application crashes with:

```
NoMethodError: undefined method 'authorize' for an instance of Spree::PaymentMethod::CodPayment
  active_record/attribute_methods.rb:495:in `method_missing'
  spree_core-5.5.0/app/models/spree/payment/processing.rb:137:in `gateway_action'
```

## Root Cause

The checkout flow in Spree calls `payment.process!` → `authorize!` → `gateway_action(:authorize)`.

In `Spree::Payment::Processing#gateway_action`:

```ruby
def gateway_action(source, action, success_state)
  response = payment_method.send(action, money.amount_in_cents, source, gateway_options)
  handle_response(response, success_state, :failure)
end
```

This calls `payment_method.authorize(amount, source, options)` on the `CodPayment` instance.

The `CodPayment` gem (v2.1.6) defines `capture`, `cancel`, and `credit` but **does not define `authorize`**:

```ruby
# gem: spree_cod_payment-2.1.6/app/models/spree/payment_method/cod_payment.rb
class CodPayment < Spree::PaymentMethod
  def actions
    %w[capture void]
  end

  def capture(*)
    simulated_successful_billing_response
  end

  def cancel(*)
    simulated_successful_billing_response
  end

  def credit(*)
    simulated_successful_billing_response
  end
  # ← NO authorize method!
end
```

Since `auto_capture?` returns `false`, Spree routes to `authorize!` instead of `purchase!`. The missing method causes the crash.

### Why the gem works in its own tests but not here

The gem's own checkout flow may bypass authorization or the gem was designed for an older Spree version where the flow differed. In Spree 5.5.0, `process!` always calls `authorize!` when `auto_capture?` is false.

## Fix

Add an `authorize` method to `CodPayment` via a monkey patch:

```ruby
# backend/app/models/spree/payment_method/cod_payment_decorator.rb
module Spree
  module CodPaymentDecorator
    def authorize(*)
      simulated_successful_billing_response
    end
  end

  CodPayment.prepend CodPaymentDecorator
end
```

This tells Spree "authorization succeeded, proceed to pend the payment" — which is the correct behavior for COD (no actual authorization happens until the order ships and payment is captured).

## Verification

1. Add the decorator file
2. Restart the server
3. Place an order with COD payment method
4. Confirm the order completes without the `authorize` error
5. Check that the payment is in `pending` state (not `completed`)

## Impact

- All COD checkout attempts fail
- Users cannot place orders with Cash on Delivery
- Sentry shows repeated occurrences of this error

## Related

- `spree_cod_payment` v2.1.6 gem
- `Spree::Payment::Processing#gateway_action` (spree_core 5.5.0)
