# ISSUE-006: Instagram Publisher Initializer Nil Error on Startup

**Status:** Closed
**Severity:** Critical
**Reported:** 2026-07-09

---

## Description

Docker restart failed with `NoMethodError: undefined method '<<' for nil` on boot. The initializer `spree_admin_partials.rb` tried to append to `Rails.application.config.spree_admin.product_page_sidebar_partials` which was `nil`.

## Steps to Reproduce

1. Add `spree_instagram_publisher` engine to the project
2. Run `docker compose up`
3. Rails crashes during boot with `NoMethodError`

## Expected vs Actual

- **Expected:** Engine loads successfully, publish button appears in product admin sidebar
- **Actual:** `undefined method '<<' for nil (NoMethodError)` on `product_page_sidebar_partials`

## Root Cause

Two issues:
1. **Wrong config key**: Used `product_page_sidebar_partials` but the actual Spree config field is `product_form_sidebar_partials` (defined in `Spree::Admin::Engine::Environment` struct)
2. **Config not yet initialized**: Spree initializes the config arrays in its own `after_initialize` block. Our initializer must also run inside `after_initialize` to ensure the arrays exist.

## Fix

Changed the initializer to:
```ruby
Rails.application.config.after_initialize do
  Rails.application.config.spree_admin.product_form_sidebar_partials << 'spree/instagram_publisher/admin/configs/publish_button'
end
```

## Verification

Restart the dev stack. Should boot without errors. The "Publish to Instagram" button should appear in the product admin sidebar.
