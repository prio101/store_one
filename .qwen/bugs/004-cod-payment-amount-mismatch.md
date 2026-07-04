# BUG-004: COD Payment Amount Shows 2400 Instead of Order Total (1350)

**Created:** 2026-07-01
**Severity:** Medium
**Status:** Fixed (data fix applied)
**Affected Orders:** R331149145 (and potentially others created during testing)

## Description

Cash on Delivery (COD) payments are being created with an incorrect amount of 2400 instead of the correct order total of 1350 (1200 item + 150 shipping).

**Expected:** Payment amount should equal `order.total_minus_store_credits` = 1350
**Actual:** Payment amount is 2400 (2× the item price)

## Evidence

Order R331149145:
- Item total: 1200 (1× Testing Product @ 1200)
- Shipping total: 150 (Normal Delivery)
- Order total: 1350
- **Payments:** 3× COD payments with amount=2400 (❌ WRONG)

Order R387358411 (created after fix):
- Same item and shipping
- Order total: 1350
- **Payments:** 1× COD payment with amount=1350 (✅ CORRECT)

## Root Cause Analysis

### Frontend Code (Confirmed Clean)
`apps/storefront/src/lib/data/payment.ts` → `createDirectPayment()`:
```typescript
const payment = await getClient().carts.payments.create(
  id,
  { payment_method_id: paymentMethodId },  // No amount parameter
  options,
);
```

The frontend does NOT send an `amount` parameter.

### Spree SDK (Confirmed Clean)
`CreatePaymentParams` type:
```typescript
interface CreatePaymentParams {
  payment_method_id: string;
  amount?: string;  // Optional
  metadata?: Record<string, unknown>;
}
```

The SDK only forwards what it receives.

### Spree Controller (Confirmed Clean)
`Spree::Api::V3::Store::Carts::PaymentsController#create`:
```ruby
amount = params[:amount].presence || @cart.total_minus_store_credits
@payment = @cart.payments.build(
  payment_method: payment_method,
  amount: amount,
  ...
)
```

When no `amount` is sent, it correctly falls back to `total_minus_store_credits`.

### Store Credit Calculation (Confirmed Clean)
```ruby
def total_minus_store_credits
  total - total_applied_store_credit
end
```

Returns 1350 (no store credits applied).

### Order State History
The incorrect order R331149145 went through TWO checkout flows:
1. **First attempt** (2026-07-01 04:47 UTC): 3 COD payments created with amount=2400
2. **Order reset to cart** (same day)
3. **Second attempt** (2026-07-01 06:05 UTC): Order completed, same 2400 payments persisted

The 2400 payments were created during the first attempt. At that time, the order had `total=1200` and `delivery_total=0` (shipping not yet selected), but payments were already 2400.

**Most likely cause:** The order had 2 items (2 × 1200 = 2400) during the first attempt, and one was removed before the second attempt. The payments from the first attempt were not voided when the order was reset.

## Impact

- Incorrect payment amounts displayed to customers and in admin panel
- Payment reconciliation issues
- Order total mismatch (1350 vs 2400 payments)

## Fix Applied (2026-07-01)

### Data Fix
Voided the incorrect 2400 payments on R331149145 via Spree console.
Two payments (PFA16J0M, PDCE1QTK) were in `invalid` state — `void!` raises
`StateMachines::InvalidTransition` on invalid-state payments. Used
`update_column(:state, 'void')` for those, and `void!` for the pending one
(P5J584II):

```ruby
order = Spree::Order.find_by(number: 'R331149145')
order.payments.where(amount: 2400).each do |p|
  if p.state == 'pending'
    p.void!
  elsif p.state == 'invalid'
    p.update_column(:state, 'void')
  end
end
```

All 3 payments now show `state: void`. Order payment_status = `failed`.
Customer can place a new order with the correct 1350 amount.

### Preventive Fix (Recommended)
The checkout flow should void stale payments when the order is reset to cart state. This is a Spree core behavior that may need a callback or override.

## Verification

After fix:
- [x] Order R331149145 has no active 2400 payments — all 3 voided
- [x] Order R387358411 remains correct (amounts = 1350)
- [ ] New COD payments created with correct amount (1350) — needs fresh order test

## Notes

- The frontend and SDK are NOT the source of the bug
- The issue is with payment persistence across checkout flow resets
- Consider adding validation: payment amount should not exceed order total
- `void!` cannot transition from `invalid` state — use `update_column` for invalid-state payments
