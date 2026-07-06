# Issue: Toggle Route Helper Missing `admin_` Prefix

## Summary

In the `spree_courier_manager` engine, the toggle route helper `toggle_courier_integration_path` was undefined because the route is inside `namespace :admin`, which requires the `admin_` prefix.

---

## Error

```
NoMethodError in Spree::Admin::CourierIntegrations#index
undefined method 'toggle_courier_integration_path' for an instance of #<Class:0x00007fd46d81dfc8>
```

**File:** `backend/engines/spree_courier_manager/app/views/spree/admin/courier_integrations/index.html.erb` line 40

---

## Root Cause

The route is defined inside `namespace :admin`:

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

When Rails defines routes inside a `namespace`, it automatically prefixes all route helpers with the namespace name. So the generated helper is `toggle_admin_courier_integration_path`, not `toggle_courier_integration_path`.

The view was using the wrong helper:

```erb
<%# WRONG %>
<%= form_tag toggle_courier_integration_path(integration), method: :post, class: 'inline' do %>

<%# CORRECT %>
<%= form_tag toggle_admin_courier_integration_path(integration), method: :post, class: 'inline' do %>
```

---

## Fix

**File:** `backend/engines/spree_courier_manager/app/views/spree/admin/courier_integrations/index.html.erb`

Change line 40 from:

```erb
<%= form_tag toggle_courier_integration_path(integration), method: :post, class: 'inline' do %>
```

To:

```erb
<%= form_tag toggle_admin_courier_integration_path(integration), method: :post, class: 'inline' do %>
```

---

## Verification

After fix, verify the route exists:

```bash
cd backend && bin/rails routes | grep toggle
# Should show: toggle_admin_courier_integration POST /admin/courier_integrations/:id/toggle
```

---

## Prevention

When creating routes inside `namespace :admin` (or any namespace):
1. Always prefix route helpers with the namespace name
2. Use `bin/rails routes | grep <resource>` to verify helper names before using in views
3. Common patterns:
   - `resources :foo` inside `namespace :admin` → `admin_foo_path`, `admin_foos_path`
   - `post :toggle` member action → `toggle_admin_foo_path`

---

## Related Issues

1. **Courier Manager Engine** (003) — This engine contains the affected route and view
