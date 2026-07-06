# Feature: Courier Manager Engine (`spree_courier_manager`)

## Summary

Create a new Spree backend engine (`spree_courier_manager`) that provides a centralized "Couriers" sidebar section in the admin panel. The engine displays a card-based UI showing courier integrations (Pathao, Steadfast, Redx, Sundarban) with feature flag per store (Enable/Disable toggle).

---

## Goals

1. **Sidebar Navigation** — Add a "Couriers" menu item to the Spree admin sidebar at position 85.
2. **Card-Based UI** — Display courier integrations as cards with enable/disable toggles and conditional "Configure" links.
3. **Feature Flags** — Each courier has an `enabled` flag per store, toggled via the UI.
4. **Default Couriers** — Auto-create default courier records (Pathao, Steadfast, Redx, Sundarban) for each store on first access.
5. **Reusable Engine** — Build as a standalone Spree backend engine with `isolate_namespace SpreeCourierManager`.

---

## Current State

- Engine created at `backend/engines/spree_courier_manager/`
- Database migration ran successfully, table `spree_courier_integrations` exists
- Sidebar navigation adds "Couriers" menu item at position 85
- Card-based UI with enable/disable toggle and conditional "Configure" links
- Default couriers auto-created per store via `Spree::CourierIntegration.ensure_defaults_for!`
- Engine is copied into Docker container via Dockerfile `COPY engines/spree_courier_manager/`
- Toggle route helper fixed: `toggle_admin_courier_integration_path` (with `admin_` prefix)

---

## Engine Structure

```
backend/engines/spree_courier_manager/
├── app/
│   ├── controllers/spree/admin/
│   │   └── courier_integrations_controller.rb
│   └── models/spree/
│       └── courier_integration.rb
├── config/
│   └── routes.rb
├── db/migrate/
│   └── 20260706000002_create_spree_courier_integrations.rb
├── lib/
│   ├── spree_courier_manager.rb
│   └── spree_courier_manager/
│       ├── engine.rb
│       └── version.rb
├── app/views/spree/admin/courier_integrations/
│   └── index.html.erb
└── spree_courier_manager.gemspec
```

---

## Database Schema (spree_courier_integrations)

| Column | Type | Notes |
|--------|------|-------|
| `id` | bigint | Primary key |
| `store_id` | bigint | FK → `spree_stores`, unique index with `slug` |
| `name` | string | NOT NULL |
| `slug` | string | NOT NULL, unique per store |
| `description` | text | |
| `icon` | string | Tabler icon name |
| `enabled` | boolean | Default: false |
| `config_url` | string | Path to config page (e.g., `/admin/pathao_courier_configs`) |
| `position` | integer | Default: 0, for ordering |
| `settings` | jsonb | Default: `{}`, extensible config |
| `created_at` | datetime | |
| `updated_at` | datetime | |

---

## Default Couriers

```ruby
DEFAULT_COURIERS = [
  { name: 'Pathao Courier', slug: 'pathao', icon: 'truck', config_url: '/admin/pathao_courier_configs', position: 0 },
  { name: 'Steadfast', slug: 'steadfast', icon: 'truck', config_url: nil, position: 1 },
  { name: 'Redx', slug: 'redx', icon: 'truck', config_url: nil, position: 2 },
  { name: 'Sundarban', slug: 'sundarban', icon: 'truck', config_url: nil, position: 3 }
]
```

---

## Routes

```ruby
Spree::Core::Engine.add_routes do
  namespace :admin, path: Spree.admin_path do
    resources :courier_integrations, only: [:index] do
      member do
        post :toggle
      end
    end
  end
end
```

---

## Key Components

### 1. `Spree::CourierIntegration` (Model)

- `belongs_to :store`
- `validates :name, presence: true`
- `validates :slug, presence: true, uniqueness: { scope: :store_id }`
- `scope :enabled, -> { where(enabled: true) }`
- `scope :ordered, -> { order(:position) }`
- `ensure_defaults_for!(store)` — creates default couriers if none exist for the store
- `toggle_enabled!` — toggles the `enabled` flag

### 2. `Spree::Admin::CourierIntegrationsController`

```ruby
module Spree
  module Admin
    class CourierIntegrationsController < Spree::Admin::BaseController
      def index
        add_breadcrumb 'Couriers'
        @integrations = current_store_courier_integrations.ordered
      end

      def toggle
        integration = current_store_courier_integrations.find(params[:id])
        integration.toggle_enabled!
        redirect_to admin_courier_integrations_path,
                    notice: "#{integration.name} #{integration.enabled? ? 'enabled' : 'disabled'}."
      end

      private

      def current_store_courier_integrations
        store = try_spree_current_user&.stores&.first || Spree::Store.first
        Spree::CourierIntegration.ensure_defaults_for!(store)
        Spree::CourierIntegration.where(store: store)
      end
    end
  end
end
```

### 3. Sidebar Navigation

```ruby
# In engine.rb initializer
Spree.admin.navigation.sidebar.add :couriers,
  label: :couriers,
  url: :admin_courier_integrations_path,
  icon: 'truck',
  position: 85,
  if: -> { can?(:manage, Spree::CourierIntegration) }
```

### 4. View (Card-Based UI)

- Cards show courier name, description, and icon
- Enable/Disable toggle button via `form_tag` with POST to `toggle_admin_courier_integration_path`
- Conditional "Configure" link when enabled and `config_url` present
- Card styling: green border/bg when enabled, gray when disabled

---

## Implementation Phases

### Phase 1: Core Engine Setup
- Create gem skeleton (`spree_courier_manager`)
- Spree engine registration with `isolate_namespace`
- Migration for `spree_courier_integrations` table
- `Spree::CourierIntegration` model with defaults
- Routes for `courier_integrations#index` and `toggle`

### Phase 2: Admin UI
- Sidebar navigation at position 85
- Card-based index view with enable/disable toggles
- Conditional "Configure" links based on `config_url`
- Controller actions: `index`, `toggle`

### Phase 3: Docker Integration
- Add `COPY engines/spree_courier_manager/ engines/spree_courier_manager/` to Dockerfile
- Ensure engine loads in development containers

### Phase 4: Bug Fixes
- Fix toggle route helper: `toggle_courier_integration_path` → `toggle_admin_courier_integration_path`
- Ensure route helpers include `admin_` prefix when inside `namespace :admin`

---

## Issues Encountered

### 1. Dockerfile COPY Path
**Error:** `"not found"` during Docker build  
**Cause:** Engine directory is `spree_courier_manager`, not `courier_integration`  
**Fix:** Changed COPY to reference `engines/spree_courier_manager/`

### 2. Namespace Collision
**Error:** `TypeError (CourierIntegration is not a module)`  
**Cause:** Controller at `Spree::CourierIntegration::Admin::IntegrationsController` requires `Spree::CourierIntegration` to be a module, but it's a class (model)  
**Fix:** Moved controller to `Spree::Admin::CourierIntegrationsController`

### 3. Toggle Route Helper Missing
**Error:** `NoMethodError: undefined method 'toggle_courier_integration_path'`  
**Cause:** Route is inside `namespace :admin`, so helper must include `admin_` prefix  
**Fix:** Changed view to use `toggle_admin_courier_integration_path`

---

## Prevention

When creating Spree admin engines:
1. Controllers should be in `Spree::Admin` namespace, not engine-specific namespace (avoids collision with model class names)
2. Route helpers inside `namespace :admin` always have `admin_` prefix
3. Engine directories must be copied into Docker container via Dockerfile `COPY`
4. Use `isolate_namespace` to avoid module collisions
5. Test route helpers with `bin/rails routes | grep <resource>` before using in views

---

## Related Issues

1. **Pathao Courier Integration** (001) — The Pathao courier config page is linked from this engine's "Configure" button
2. **Spree Dev Compose Engine Loading** (002) — Engine loading in Docker was the root cause of initial issues
3. **Toggle Path Helper Fix** (004) — Specific fix for this engine's toggle route helper
