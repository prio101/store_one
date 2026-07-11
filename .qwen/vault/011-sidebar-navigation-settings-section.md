# Refactor: Sidebar Navigation — Group Engine Items Under Settings Section

**Status:** Done
**Date:** 2026-07-09

---

## Problem

The three custom engine sidebar items (Couriers, AI Settings, Instagram) were registered at positions 85/90/95, which placed them **above** or **at** Spree's `:settings_section` divider (position 90). This made them appear as standalone top-level items instead of being grouped under the "Settings" section.

## Solution

Adjusted the navigation position values so all three engine items fall between the `:settings_section` divider (position 90) and the main `:settings` link (position 100):

| Engine | Old Position | New Position |
|--------|-------------|--------------|
| `spree_courier_manager` (`:couriers`) | 85 | 92 |
| `spree_ai_engine` (`:ai_settings`) | 90 | 94 |
| `spree_instagram_publisher` (`:instagram_settings`) | 95 | 96 |

## Resulting Sidebar Layout

```
... (Integrations, position 80)
──────────────────────
Settings              ← section divider (position 90)
  Couriers            ← position 92
  AI Settings         ← position 94
  Instagram           ← position 96
Settings              ← main settings link (position 100)
Admin Users           ← position 110
```

## Files Changed

- `backend/engines/spree_courier_manager/lib/spree_courier_manager/engine.rb` — position 85 → 92
- `backend/engines/spree_ai_engine/lib/spree_ai_engine/engine.rb` — position 90 → 94
- `backend/engines/spree_instagram_publisher/lib/spree_instagram_publisher/engine.rb` — position 95 → 96

## Spree Navigation Reference

Spree's sidebar navigation uses `Spree::Admin::Navigation` with `section_label` items as visual dividers. Items are sorted by `position` value. The `:settings_section` item (position 90) renders as a `<li class="nav-section-header">` with a top border, creating the visual grouping. Any items with positions between 90 and 100 appear under this section header.
