# 008: Pathao Courier Cost Estimation — Multi-Bug Fix

## Reported
2026-07-06

## Summary
Clicking "Calculate Total COD" on the admin order edit page triggered a cascade of errors (404 → 500 → 422) across multiple bugs in the `spree_pathao_courier` engine.

---

## Bug 1: Route Mismatch — 404

**Symptom:** `POST /admin/orders/R462343273/courier/estimate_cost` → 404

**Root cause:** JavaScript fetch URLs had `/admin/orders/:id/courier/estimate_cost` but Rails routes define `/admin/courier/orders/:id/estimate_cost`.

**Fix:** Updated `_tracking_section.html.erb` fetch URLs:
```diff
- fetch('/admin/orders/' + ORDER_ID + '/courier/estimate_cost', {
+ fetch('/admin/courier/orders/' + ORDER_ID + '/estimate_cost', {
```

---

## Bug 2: Missing `AddressNotFoundError` — 500

**Symptom:** `NameError (uninitialized constant Spree::PathaoCourier::AddressNotFoundError)`

**Root cause:** Controller rescues `AddressNotFoundError` but class was never defined in `error.rb`. When the real error occurred, resolving the undefined constant raised `NameError`, masking the original error.

**Fix:** Added to `error.rb`:
```ruby
class AddressNotFoundError < Error; end
```

---

## Bug 3: TypeError from String IDs — 500

**Symptom:** `TypeError (no implicit conversion of String into Integer)`

**Root cause:** Pathao API returns IDs as strings (`city_id: "123"`). These flowed to `CostEstimator` which expected integers.

**Fix:** Added `.to_i` conversions in `address_resolver.rb`:
```ruby
{ city_id: city['city_id'].to_i, city_name: city['city_name'] }
{ zone_id: zone['zone_id'].to_i, zone_name: zone['zone_name'] }
{ area_id: area['area_id']&.to_i, area_name: area['area_name'] }
```

---

## Bug 4: Wrong Zone Candidate — 500

**Symptom:** `Could not resolve zone '1230' in city 1` then `Could not resolve zone 'Madhobilota' in city 1`

**Root cause:** `address_location_parts` extracted parts from `address1` directly. For "Madhobilota, Sector 18, Uttara, Dhaka, 1230", candidates were ["Madhobilota", "Sector 18", "Uttara", "Dhaka", "1230"]. First candidate "Madhobilota" is a local landmark, not a zone. "1230" is a postal code, not a zone.

**Fix:** Added filtering to skip pure numeric parts and city name, then iterate remaining candidates against zone list:
```ruby
def address_location_parts(address)
  parts = split_address(address.address1)
  city_name = address.city&.downcase
  parts.reject { |part|
    part.match?(/\A\d+\z/) || (city_name && part.downcase == city_name)
  }
end
```

---

## Bug 5: Missing `recipient_city` — 422

**Symptom:** `{"recipient_city":["The recipient city field is required."]}`

**Root cause:** `CostEstimator#call` never included `recipient_city` in the price-plan payload.

**Fix:** Added `recipient_city:` parameter to `CostEstimator#call` and payload:
```ruby
def call(delivery_type:, item_type:, item_weight:, recipient_zone:, recipient_city:)
  payload = {
    ...
    recipient_zone: recipient_zone,
    recipient_city: recipient_city
  }
end
```

Passed from `CheckoutService`:
```ruby
cost = CostEstimator.new(config: @config).call(
  ...
  recipient_zone: address_data[:zone_id],
  recipient_city: address_data[:city_id]
)
```

---

## Bug 6: Wrong `item_weight` Unit — 422

**Symptom:** `{"item_weight":["The item weight must be between 0.1 and 200."]}`

**Root cause:** Config stores weight in grams (default 500g). Pathao API expects kilograms (0.1–200 range). Sending 500 grams directly exceeded the 200 limit.

**Fix:** Added grams→kg conversion in `CostEstimator#call`:
```ruby
weight_kg = (item_weight.to_f / 1000).round(2)
weight_kg = [weight_kg, 0.1].max
```

---

## Bug 7: TypeError from Hash items in find_best_match — 500

**Symptom:** `TypeError: no implicit conversion of String into Integer` at `address_resolver.rb:177` in `find_best_match`

**Root cause:** The Pathao API city-list response `{"data": [...]}` was being passed through `unwrap_data`, but in some cases the Hash structure persisted (possibly from stale cache). When `find_best_match` tried to iterate with `items.find do |item|`, it called `Hash#each` instead of `Array#each`, and `item[field_name]` tried to access a Hash key with a String, causing the TypeError.

**Fix:** Two changes:
1. Added detailed debug logging to `unwrap_data` to trace input/output types
2. Added safety net in `find_best_match` — if `items` is a Hash, auto-unwrap it:
```ruby
def find_best_match(items, search_term, field_name)
  if items.is_a?(Hash)
    items = items.key?('data') ? (items['data'] || []) : items.values
  end
  # ... rest of method
end
```

---

## Bug 8: recipient_city Wrong Type — 422

**Symptom:** `{"recipient_city":["The recipient city must be an integer."]}`

**Root cause:** `CheckoutService` passed `address_data[:city_name]` (a String like "Dhaka") to `CostEstimator`, but the Pathao price-plan API expects `recipient_city` to be the integer city ID.

**Fix:** Changed `CheckoutService` to pass `address_data[:city_id]` (Integer) instead of `address_data[:city_name]`:
```diff
- recipient_city: address_data[:city_name]
+ recipient_city: address_data[:city_id]
```

Updated `CostEstimator` comment: `@param recipient_city [Integer] Pathao city ID`

---

## Files Changed

| File | Change |
|------|--------|
| `spree_pathao_courier/app/services/spree/pathao_courier/error.rb` | Added `AddressNotFoundError` |
| `spree_pathao_courier/app/services/spree/pathao_courier/address_resolver.rb` | `.to_i` conversions, `address_location_parts` filtering |
| `spree_pathao_courier/app/services/spree/pathao_courier/cost_estimator.rb` | Added `recipient_city`, grams→kg conversion |
| `spree_pathao_courier/app/services/spree/pathao_courier/checkout_service.rb` | Pass `recipient_city` to CostEstimator |
| `spree_pathao_courier/app/views/.../_tracking_section.html.erb` | Fixed fetch URLs |

## Related
- Vault: `001-pathao-courier-integration.md` (API docs)
- Vault: `007-admin-courier-estimate-cost-404.md` (prior fix)
