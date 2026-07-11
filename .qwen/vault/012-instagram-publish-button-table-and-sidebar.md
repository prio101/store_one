# Feature: Publish to Instagram — Table Column & Sidebar Button

**Status:** Done
**Date:** 2026-07-09

---

## What was done

Added "Publish to Instagram" functionality in two locations:

### 1. Products Index Table — "Instagram" Column

A new custom column in the Spree admin products table that shows a "Publish" button per product.

**How it works:**
- Column is registered via `Spree.admin.tables.products.insert_after :status` in `config/initializers/spree_admin_partials.rb`
- Custom partial `_instagram_publish_column.html.erb` renders a form that POSTs to `publish_product_admin_instagram_publisher_config_path`
- When Instagram config is active + resolved: shows a "Publish" button with confirmation dialog
- When config is enabled but not resolved: shows "Not configured" badge
- When no config exists: shows a dash
- Hidden `redirect_to_table` param ensures redirect back to products index after publish

### 2. Product Edit Page — Right Sidebar Section

The existing `_publish_button.html.erb` partial (registered via `product_form_sidebar_partials`) renders in the right sidebar of the product edit form.

**How it works:**
- Shows "Instagram Publisher" card with the connected Instagram handle
- Full-width "Publish to Instagram" primary button with product name in confirmation dialog
- Shows "Last published" timestamp when available
- When config is enabled but not resolved: shows "Configure Instagram" link
- Posts to `publish_product` action with the product ID

### 3. Publish Flow (Image + Product Detail → Instagram)

The `Publisher` service handles the full Meta Content Publishing API flow:

1. **Image resolution** — Uses `product.primary_media.attachment.url` (Spree 5.5 API, not deprecated `primary_image`)
2. **Caption generation** — Uses config template with `{product_name}`, `{price}`, `{url}` placeholders
3. **Media container creation** — `POST /{ig-user-id}/media` with image_url + caption
4. **Wait for ready** — Polls container status until ready
5. **Publish** — `POST /{ig-user-id}/media_publish` with creation_id
6. **Result** — Returns success/failure with media_id or error message

### 4. Controller Redirect Logic

Updated `publish_product` action to handle two redirect paths:
- From table column (`redirect_to_table=true`): redirects to products index
- From sidebar button: redirects to product edit page

## Files Changed

| File | Change |
|------|--------|
| `config/initializers/spree_admin_partials.rb` | Added table column registration |
| `app/views/.../configs/_instagram_publish_column.html.erb` | **New** — table column partial |
| `app/views/.../configs/_publish_button.html.erb` | Improved UX (product name in confirm, last published, primary button) |
| `app/controllers/.../configs_controller.rb` | Added `after_publish_redirect` for smart redirect |
| `app/services/spree/instagram_publisher/publisher.rb` | Fixed image URL to use `primary_media` (not deprecated `primary_image`) |

## Spree Admin Extension Points Used

| Extension Point | What it does |
|----------------|-------------|
| `product_form_sidebar_partials` | Adds Instagram Publisher card to product edit page sidebar |
| `Spree.admin.tables.products.insert_after` | Adds Instagram column to products index table |
| `render_admin_partials(:product_form_sidebar_partials)` | Renders registered sidebar partials in the product form |

## Publish Flow Diagram

```
User clicks "Publish" (table or sidebar)
  → POST /admin/instagram_publisher_configs/:id/publish_product
  → ConfigsController#publish_product
    → Publisher.new(config).publish(product:)
      → Get image URL from product.primary_media
      → Generate caption from template
      → MediaCreator#create_container(image_url, caption)
      → MediaCreator#wait_for_ready(container_id)
      → Client#post(/{ig-user-id}/media_publish, creation_id: container_id)
    → Redirect with success/error message
```
