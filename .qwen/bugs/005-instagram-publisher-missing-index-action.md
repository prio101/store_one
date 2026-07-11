# ISSUE-005: Instagram Publisher Missing Index Action

**Status:** Closed
**Severity:** Medium
**Reported:** 2026-07-09

---

## Description

The Instagram Publisher engine routes defined `resources :instagram_publisher_configs, except: [:destroy]` which generates an `index` route, but the `ConfigsController` did not define an `index` action. Navigating to the Instagram settings page caused an "Unknown action" error.

## Steps to Reproduce

1. Start the Docker dev stack
2. Navigate to Admin → Instagram settings (sidebar link)
3. Rails raises `Unknown action` for `Spree::InstagramPublisher::Admin::ConfigsController#index`

## Expected vs Actual

- **Expected:** Page loads showing the Instagram config form (or redirects to new/edit)
- **Actual:** `Unknown action` error — `index` method was missing from controller

## Root Cause

The `resources` declaration in `config/routes.rb` generates all standard RESTful routes (index, new, create, show, edit, update), but the controller only implemented `new`, `create`, `edit`, `update`, and `publish_product`. The `index` action was omitted.

## Fix

Added `index` action to `ConfigsController`. Since Instagram config is per-store (one record per store), the action redirects to `edit` if a config exists, or `new` if none yet.

## Verification

Restart the dev stack and navigate to Admin → Instagram settings. Should redirect to the config form without error.
