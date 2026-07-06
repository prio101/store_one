# Feature Request: Pathao Courier Integration Plugin for Spree Commerce

## Summary

Create a reusable Spree backend plugin (`spree_pathao_courier`) that integrates with Pathao Courier's Merchant API, enabling order shipment creation directly from the Spree Admin panel. After shipment creation, a tracking number (consignment ID) is returned and stored on the order for easy copy-over.

---

## Goals

1. **Admin Shipment Creation** — From the Spree Admin panel, create a shipment for an order using Pathao Courier as the shipping method.
2. **Tracking Number Retrieval** — After shipment creation, the Pathao consignment ID (tracking number) is displayed on the order and can be copied.
3. **Reusable Plugin** — Build as a standalone Spree backend engine (`spree_pathao_courier`) so it can be dropped into any Spree store.
4. **Token Management** — Handle OAuth 2.0 token issuance, caching, and refresh automatically.
5. **Configurable per Store** — Support sandbox/production environments via configuration.

---

## Current State

- Pathao Courier is already the default shipping method for this store.
- No Pathao API integration exists yet — orders are shipped manually outside of Spree.
- Spree backend admin panel is available at `/admin`.

---

## Pathao Courier API Reference

### Sandbox / Test Environment

| Field | Value |
|---|---|
| base_url | `https://courier-api-sandbox.pathao.com` |
| client_id | `7N1aMJQbWm` |
| client_secret | `wRcaibZkUdSNz2EI9ZyuXLlNrnAv0TdPUPXMnD39` |
| username | `test@pathao.com` |
| password | `lovePathao` |
| grant_type | `password` |

### Production / Live Environment

| Field | Value |
|---|---|
| base_url | `https://api-hermes.pathao.com` |
| client_id | (from merchant dashboard) |
| client_secret | (from merchant dashboard) |

### API Endpoints

#### 1. Issue Access Token

- **Endpoint:** `POST /aladdin/api/v1/issue-token`
- **Purpose:** Obtain an OAuth 2.0 access token for authenticating subsequent API requests.
- **Auth:** None (uses client credentials directly)
- **Request Body:**

```json
{
  "client_id": "{{client_id}}",
  "client_secret": "{{client_secret}}",
  "grant_type": "password",
  "username": "{{email}}",
  "password": "{{password}}"
}
```

- **Response (200):**

```json
{
  "token_type": "Bearer",
  "expires_in": 432000,
  "access_token": "ISSUED_ACCESS_TOKEN",
  "refresh_token": "ISSUED_REFRESH_TOKEN"
}
```

#### 2. Issue Access Token from Refresh Token

- **Endpoint:** `POST /aladdin/api/v1/issue-token`
- **Purpose:** Regenerate access token using a refresh token.
- **Request Body:**

```json
{
  "client_id": "{{client_id}}",
  "client_secret": "{{client_secret}}",
  "grant_type": "refresh_token",
  "refresh_token": "ISSUED_REFRESH_TOKEN"
}
```

#### 3. Create a New Order

- **Endpoint:** `POST /aladdin/api/v1/orders`
- **Purpose:** Create a single shipment order.
- **Auth:** Bearer token
- **Request Body:**

```json
{
  "store_id": 123,
  "merchant_order_id": "ORDER-NUMBER",
  "recipient_name": "John Doe",
  "recipient_phone": "017XXXXXXXX",
  "recipient_address": "Full delivery address, City, Bangladesh",
  "delivery_type": 48,
  "item_type": 2,
  "special_instruction": "",
  "item_quantity": 1,
  "item_weight": "0.5",
  "item_description": "Order items",
  "amount_to_collect": 0
}
```

- **Response (200):**

```json
{
  "message": "Order Created Successfully",
  "type": "success",
  "code": 200,
  "data": {
    "consignment_id": "CONSIGNMENT_ID",
    "merchant_order_id": "ORDER-NUMBER",
    "order_status": "Pending",
    "delivery_fee": 80
  }
}
```

- **Key Field:** `consignment_id` — this is the tracking number to store on the Spree order.

#### 4. Create Bulk Orders

- **Endpoint:** `POST /aladdin/api/v1/orders/bulk`
- **Purpose:** Create multiple shipment orders at once.
- **Auth:** Bearer token

#### 5. Get Order Short Info

- **Endpoint:** `GET /aladdin/api/v1/orders/{{consignment_id}}/info`
- **Purpose:** Retrieve order status using the consignment ID.
- **Response includes:** `consignment_id`, `merchant_order_id`, `order_status`, `order_status_slug`, `updated_at`.

#### 6. Get City List

- **Endpoint:** `GET /aladdin/api/v1/city-list`
- **Purpose:** Fetch available cities for delivery address resolution.

#### 7. Get Zone List (by City)

- **Endpoint:** `GET /aladdin/api/v1/cities/{{city_id}}/zone-list`
- **Purpose:** Fetch zones within a given city.

#### 8. Get Area List (by Zone)

- **Endpoint:** `GET /aladdin/api/v1/zones/{{zone_id}}/area-list`
- **Purpose:** Fetch areas within a given zone. Response includes `home_delivery_available` and `pickup_available` flags.

#### 9. Price Calculation

- **Endpoint:** `POST /aladdin/api/v1/merchant/price-plan`
- **Purpose:** Calculate shipping cost based on store, item type, delivery type, weight, and recipient zone.
- **Response includes:** `price`, `discount`, `cod_percentage`, `final_price`.

#### 10. Get Merchant Store Info

- **Endpoint:** `GET /aladdin/api/v1/stores`
- **Purpose:** List merchant stores configured in Pathao. Each store has a `store_id`, `store_name`, `store_address`, `city_id`, `zone_id`, `hub_id`.

---

## Proposed Architecture

### Plugin Structure

```
spree_pathao_courier/
├── lib/
│   └── spree_pathao_courier/
│       ├── engine.rb
│       └── version.rb
├── app/
│   ├── models/
│   │   └── spree/
│   │       └── pathao_courier_config.rb
│   ├── services/
│   │   └── spree/
│   │       └── pathao_courier/
│   │           ├── client.rb
│   │           ├── token_manager.rb
│   │           ├── order_creator.rb
│   │           └── order_status.rb
│   ├── controllers/
│   │   └── spree/
│   │       └── admin/
│   │           └── pathao_courier_controller.rb
│   └── views/
│       └── spree/
│           └── admin/
│               ├── pathao_courier/
│               │   ├── _shipment_form.html.erb
│               │   └── _tracking_info.html.erb
│               └── shipments/
│                   └── _pathao_details.html.erb
├── config/
│   ├── routes.rb
│   └── locales/
│       └── en.yml
├── db/
│   └── migrate/
│       └── YYYYMMDD_create_spree_pathao_courier_configs.rb
└── spree_pathao_courier.gemspec
```

### Key Components

#### 1. `Spree::PathaoCourierConfig` (Model)

Stores Pathao API credentials and store configuration per Spree store:

- `base_url` (string)
- `client_id` (string)
- `client_secret` (string)
- `username` (string)
- `password` (string)
- `store_id` (integer — Pathao merchant store ID)
- `default_delivery_type` (integer — 48=Normal, 12=On Demand)
- `default_item_type` (integer — 1=Document, 2=Parcel)
- `sandbox` (boolean)

#### 2. `Spree::PathaoCourier::TokenManager` (Service)

- Issues access tokens via `/aladdin/api/v1/issue-token`
- Caches tokens in the database (with `expires_in` handling)
- Refreshes tokens using `refresh_token` grant
- Thread-safe token acquisition

#### 3. `Spree::PathaoCourier::Client` (Service)

- HTTP client wrapper (using `Faraday` or `Net::HTTP`)
- Handles request signing with Bearer token
- Error handling and retry logic
- Base URL from config

#### 4. `Spree::PathaoCourier::OrderCreator` (Service)

- Accepts a Spree `Order` (or `Shipment`)
- Maps Spree order data to Pathao API fields:
  - `recipient_name` → `order.ship_address.full_name`
  - `recipient_phone` → `order.ship_address.phone`
  - `recipient_address` → `order.ship_address.full_address`
  - `merchant_order_id` → `order.number`
  - `item_quantity` → sum of line item quantities
  - `item_weight` → configurable default or calculated
  - `amount_to_collect` → order total (for COD) or 0
- Calls Pathao `/aladdin/api/v1/orders`
- Returns `consignment_id` (tracking number) and `delivery_fee`
- Stores tracking info on the Spree shipment

#### 5. Admin Controller & Views

- **Shipment Form** — Button to "Ship with Pathao" on the shipment edit page in Spree Admin
- **Tracking Info** — Display `consignment_id` on the order/shipment detail page with a "Copy" button
- **Status Lookup** — Optional: "Check Status" button that queries Pathao for current order status

### Data Flow

```
Admin clicks "Ship with Pathao" on order
  → OrderCreator service called
    → TokenManager fetches/refreshes access token
      → Pathao API: POST /aladdin/api/v1/orders
        → consignment_id returned
          → Stored on Spree::Shipment (tracking field)
            → Admin sees tracking number with copy button
```

---

## Implementation Phases

### Phase 1: Core Plugin Setup
- Create gem skeleton (`spree_pathao_courier`)
- Spree engine registration
- Migration for `spree_pathao_courier_configs` table
- Token management service
- HTTP client wrapper

### Phase 2: Order Creation
- Map Spree order → Pathao order payload
- OrderCreator service
- Admin controller + "Ship with Pathao" button
- Store `consignment_id` on shipment

### Phase 3: Admin UI Enhancements
- Tracking number display with copy-to-clipboard
- Delivery fee display
- Order status lookup button
- Configuration page in Spree Admin (credentials, store_id, defaults)

### Phase 4: Refinements
- Bulk order support
- Price estimation before shipment
- Webhook / polling for status updates
- Error handling & retry logic
- Logging

---

## Configuration

The plugin should be configurable via:

1. **Database** — `Spree::PathaoCourierConfig` model (admin-editable)
2. **Environment Variables** (fallback):

```env
PATHAO_COURIER_BASE_URL=https://courier-api-sandbox.pathao.com
PATHAO_COURIER_CLIENT_ID=7N1aMJQbWm
PATHAO_COURIER_CLIENT_SECRET=wRcaibZkUdSNz2EI9ZyuXLlNrnAv0TdPUPXMnD39
PATHAO_COURIER_USERNAME=test@pathao.com
PATHAO_COURIER_PASSWORD=lovePathao
PATHAO_COURIER_STORE_ID=123
PATHAO_COURIER_SANDBOX=true
```

---

## Testing Strategy

- Unit tests for `TokenManager`, `Client`, `OrderCreator`
- Use Pathao sandbox API for integration tests
- Mock responses for CI (recorded VCR cassettes)
- Admin UI manual testing checklist

---

## Notes

- The plugin must be environment-agnostic — usable by any Spree store, not just this one.
- Token storage should be encrypted at rest (use `encrypts` in Rails 7+).
- Consignment ID should be stored on `Spree::Shipment#tracking` field.
- COD amount should be configurable per order (order total vs 0).
- Default item weight should be configurable (default: 0.5 kg).
