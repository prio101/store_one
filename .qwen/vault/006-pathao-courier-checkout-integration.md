# Feature 006: Pathao Courier Checkout Integration

## Status: Draft
## Created: 2026-07-06

---

## Overview

Enhance the Pathao Courier integration with full address resolution, cost estimation, and a dedicated admin panel section for managing COD shipments with tracking information.

---

## Problem Statement

Currently, the Pathao Courier integration:
- Uses hardcoded City/Zone/Area IDs (all set to `1`)
- Has no cost estimation before shipment
- Has no dedicated admin UI section for courier operations
- Does not persist delivery tracking information separately from the shipment

---

## Requirements

### 1. Address Resolution (City/Zone/Area Lookup)

**Goal:** Replace hardcoded city/zone/area IDs with actual API lookups based on the order's shipping address.

**API Endpoints:**
- `GET /aladdin/api/v1/city-list` — Fetch all cities
- `GET /aladdin/api/v1/cities/:city_id/zone-list` — Fetch zones by city
- `GET /aladdin/api/v1/zones/:zone_id/area-list` — Fetch areas by zone

**Implementation:**
- Create `Spree::PathaoCourier::AddressResolver` service
- Match shipping address city/area text against Pathao API response
- Cache results (cities rarely change)
- Store resolved IDs for the order

**Subtasks:**
- [ ] Create `AddressResolver` service class
- [ ] Implement city lookup with caching
- [ ] Implement zone lookup by city_id
- [ ] Implement area lookup by zone_id
- [ ] Add fuzzy matching for address text (handle spelling variations)
- [ ] Write unit tests with mocked API responses
- [ ] Add fallback handling when address cannot be resolved

---

### 2. Cost Estimation API

**Goal:** Calculate total COD cost before creating shipment.

**API Endpoint:**
- `POST /aladdin/api/v1/merchant/price-plan`

**Request Payload:**
```json
{
  "store_id": 123,
  "item_type": 2,
  "delivery_type": 48,
  "item_weight": 500,
  "recipient_zone": 1
}
```

**Response:**
```json
{
  "price": 80,
  "discount": 0,
  "cod_percentage": 1,
  "final_price": 80
}
```

**Implementation:**
- Create `Spree::PathaoCourier::CostEstimator` service
- Accept delivery type (48=Normal, 12=Express)
- Return cost breakdown (price, discount, COD fee, final price)

**Subtasks:**
- [ ] Create `CostEstimator` service class
- [ ] Implement price-plan API call
- [ ] Map delivery type options (Normal/Express)
- [ ] Return structured cost object
- [ ] Write unit tests

---

### 3. New Database Model: `Spree::CourierDeliveryTrackingInformation`

**Goal:** Persist courier delivery tracking information separately from Spree::Shipment.

**Table: `spree_courier_delivery_tracking_informations`**

| Column | Type | Description |
|--------|------|-------------|
| `id` | bigint | Primary key |
| `order_id` | bigint | FK to spree_orders |
| `shipment_id` | bigint | FK to spree_shipments (nullable) |
| `courier_name` | string | e.g., "pathao" |
| `consignment_id` | string | Pathao tracking number |
| `merchant_order_id` | string | Spree order number |
| `recipient_name` | string | Delivery recipient |
| `recipient_phone` | string | Contact number |
| `recipient_address` | text | Full delivery address |
| `recipient_city_id` | integer | Pathao city ID |
| `recipient_zone_id` | integer | Pathao zone ID |
| `recipient_area_id` | integer | Pathao area ID |
| `delivery_type` | integer | 48=Normal, 12=Express |
| `item_type` | integer | 1=Document, 2=Parcel |
| `item_quantity` | integer | Number of items |
| `item_weight` | decimal | Weight in grams |
| `item_description` | text | Item description |
| `shipping_cost` | decimal | Delivery fee |
| `cod_amount` | decimal | Cash to collect |
| `order_status` | string | Current status |
| `estimated_delivery` | string | Expected delivery time |
| `note` | text | Special instructions |
| `confirmed` | boolean | Admin confirmed |
| `confirmed_at` | datetime | Confirmation timestamp |
| `created_at` | datetime | Created timestamp |
| `updated_at` | datetime | Updated timestamp |

**Indexes:**
- `index_on_order_id`
- `index_on_consignment_id`
- `index_on_merchant_order_id`

**Subtasks:**
- [ ] Create migration for new table
- [ ] Create `Spree::CourierDeliveryTrackingInformation` model
- [ ] Add associations (belongs_to :order, belongs_to :shipment)
- [ ] Add validations
- [ ] Add scopes (by_status, by_courier, confirmed, pending)

---

### 4. Admin Panel UI: Courier Tracking Section

**Goal:** Dedicated section in Spree Admin order details page for managing Pathao shipments.

**Location:** Below existing "Tracking Info" section on order edit page

**UI Elements:**

```
┌─────────────────────────────────────────────────────────────┐
│ Courier Delivery                                           │
├─────────────────────────────────────────────────────────────┤
│                                                           │
│  ○ Courier Via Pathao    ○ Other Courier                  │
│                                                           │
│  Delivery Option:                                         │
│  [ Normal (48h) ]  [ Express (12h) ]                      │
│                                                           │
│  [ Calculate Total COD ]                                  │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ Cost Breakdown:                                     │  │
│  │   Shipping Cost: ৳80                                │  │
│  │   COD Fee: ৳8                                       │  │
│  │   Total to Collect: ৳88                             │  │
│  │   Expected Delivery: 2-3 business days              │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  Tracking Number: BD1234567890  [📋 Copy]                 │
│                                                           │
│  [ Confirm & Save ]                                       │
│                                                           │
└─────────────────────────────────────────────────────────────┘
```

**Subtasks:**
- [ ] Create partial view `spree/admin/orders/_courier_tracking_section.html.erb`
- [ ] Add controller action for cost calculation (AJAX)
- [ ] Add controller action for confirming shipment
- [ ] Integrate section into order edit page
- [ ] Implement copy-to-clipboard for tracking number
- [ ] Style with Tailwind CSS (match Spree admin aesthetic)

---

### 5. Controller Actions

**Goal:** Handle cost estimation and shipment confirmation.

**New Endpoints:**

| Method | Path | Action |
|--------|------|--------|
| `POST` | `/admin/orders/:order_id/courier/estimate_cost` | Calculate cost estimate |
| `POST` | `/admin/orders/:order_id/courier/confirm` | Confirm and save tracking info |
| `GET` | `/admin/orders/:order_id/courier/tracking` | Get tracking info (AJAX) |

**Implementation:**
- Create `Spree::PathaoCourier::Admin::CourierController`
- Add before_actions for authentication and authorization
- Return JSON for AJAX requests
- Redirect with flash for standard requests

**Subtasks:**
- [ ] Create `CourierController` with estimate_cost action
- [ ] Create confirm action
- [ ] Create tracking info retrieval action
- [ ] Add route definitions
- [ ] Add authorization (CanCanCan)
- [ ] Write controller tests

---

### 6. Service Integration

**Goal:** Wire up all services to work together.

**Flow:**
```
Admin selects "Courier Via Pathao"
  → Selects delivery type (Normal/Express)
    → Clicks "Calculate Total COD"
      → AddressResolver resolves city/zone/area
        → CostEstimator calculates cost
          → Returns cost breakdown + estimated delivery
            → Admin reviews and clicks "Confirm & Save"
              → OrderCreator creates Pathao shipment
                → CourierDeliveryTrackingInformation saved
                  → Tracking number displayed with copy button
```

**Subtasks:**
- [ ] Create `Spree::PathaoCourier::CheckoutService` orchestrator
- [ ] Integrate AddressResolver, CostEstimator, OrderCreator
- [ ] Handle partial failures (e.g., address resolution fails)
- [ ] Add logging for debugging

---

### 7. Testing

**Goal:** Comprehensive test coverage.

**Subtasks:**
- [ ] Unit tests for AddressResolver
- [ ] Unit tests for CostEstimator
- [ ] Unit tests for CheckoutService
- [ ] Unit tests for CourierDeliveryTrackingInformation model
- [ ] Controller tests for CourierController
- [ ] Integration tests for full checkout flow
- [ ] Use Webmock/VCR for API mocking

---

## Implementation Phases

### Phase 1: Data Layer (Days 1-2)
- Database migration
- Model creation
- Basic validations

### Phase 2: Services (Days 3-4)
- AddressResolver
- CostEstimator
- CheckoutService orchestrator

### Phase 3: Admin UI (Days 5-6)
- CourierController
- Admin views
- AJAX cost calculation
- Copy-to-clipboard

### Phase 4: Integration (Day 7)
- Wire up all components
- End-to-end testing
- Bug fixes

---

## Technical Notes

- Use `encrypts` for sensitive fields (phone numbers)
- Cache city/zone/area lists (use Rails.cache with 24h TTL)
- Consider rate limiting for Pathao API calls
- Log all API requests/responses for debugging
- Handle network timeouts gracefully

---

## Open Questions

1. Should cost estimation happen automatically when order is created, or only on-demand?
2. Should we support multiple couriers in the future, or Pathao-only?
3. What happens if Pathao API is down? Fallback to manual entry?
4. Should tracking info sync status updates from Pathao (webhook/polling)?
