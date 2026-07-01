# Feature: Cash on Delivery (COD) Payment Method

## Overview
Add Cash on Delivery as a payment option at checkout, allowing customers to pay when their order is delivered. This is a common requirement for Bangladeshi e-commerce.

---

## Gem

**`spree_cod_payment` v2.1.6** — https://github.com/olympusone/spree_cod_payment

Adds `Spree::PaymentMethod::CodPayment` which inherits from `Spree::PaymentMethod`. No external payment gateway needed — it simulates successful billing responses for capture/void/cancel/credit.

### What the gem does

| File | Purpose |
|------|---------|
| `app/models/spree/payment_method/cod_payment.rb` | COD payment method model (auto-capture off, no source required) |
| `app/models/spree/payment_method_decorator.rb` | Adds `cod_payment?` and `cod_payment_available?(order)` to `Spree::PaymentMethod` |
| `db/migrate/..._add_cod_fee_to_shipping_methods.rb` | Adds `cod` boolean column to `spree_shipping_methods` |
| `app/views/spree/` | Admin and checkout views for COD |

### Key behaviors

- `source_required?` → false (no credit card needed)
- `auto_capture?` → false (manual capture after delivery)
- `can_capture?` → only when payment is pending AND order is shipped
- `cod_payment_available?(order)` → true when the order's shipping method has `cod: true`

---

## Installation Status

### ✅ Done

- [x] Gem added to `backend/Gemfile` (line 85): `gem "spree_cod_payment", "~> 2.1"`
- [x] Gem resolved in `backend/Gemfile.lock` (v2.1.6)
- [x] Migration file copied: `backend/db/migrate/20260630200529_add_cod_fee_to_shipping_methods.spree_cod_payment.rb`

### ✅ Done (local dev)

- [x] **Migration applied** to local dev database (2026-07-01)
  - `cod` boolean column (default: false, not null) added to `spree_shipping_methods`

### ❌ Pending

- [ ] **Run migration** on production server: `bin/rails db:migrate`
- [ ] **Create COD payment method** in Spree Admin → Settings → Payment Methods:
  - Name: `Cash on Delivery`
  - Method type: `cod_payment`
  - Active: Yes
  - Display on: Both (or Frontend only)
- [ ] **Enable COD on shipping methods** in Spree Admin → Settings → Shipping Methods:
  - Edit each shipping method that should support COD
  - Check the `COD` checkbox (this is the new `cod` column)
- [ ] **Deploy** — gem + migration + payment method config must all be present on production

---

## Setup Steps (on server)

```bash
# 1. Run the pending migration
bin/rails db:migrate

# 2. Create the COD payment method via Rails console
bin/rails console
Spree::PaymentMethod::CodPayment.create!(
  name: 'Cash on Delivery',
  display_on: 'both',
  active: true,
  store: Spree::Store.default
)

# 3. Enable COD on shipping methods (example)
Spree::ShippingMethod.find_by(name: 'Home Delivery').update!(cod: true)
```

---

## Verification

1. Visit storefront checkout as a guest
2. Add a product, proceed to payment step
3. Confirm "Cash on Delivery" appears as a payment option
4. Complete the order with COD selected
5. Verify order is placed with `payment_state: 'pending'`
6. In Spree Admin, confirm the COD payment can be captured after shipment
