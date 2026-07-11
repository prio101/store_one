# Feature: Instagram Publisher Engine

## Overview

A Spree Commerce engine (`spree_instagram_publisher`) that enables publishing product details — including thumbnails, images, and captions — to a selected Instagram Shop Page via the Meta Content Publishing API. Configuration is managed through the Spree Admin sidebar under **Settings > Social Settings > Instagram**.

---

## Requirements

- **Admin Settings Page** — A settings form under the admin sidebar (Settings → Social Settings → Instagram) that allows store admins to:
  - Enable/disable the Instagram integration (toggle)
  - When enabled: enter Facebook App credentials (App ID, App Secret) and Page Access Token
  - Enter the target Facebook Page ID and Instagram Business Account ID
  - Save per-store configuration (encrypted sensitive fields)
- **Product Publishing** — Publish a Spree product to Instagram as a carousel or single image post:
  - Use the product's primary image (or selected images) as the post media
  - Include product name, description, price, and a link back to the product page in the caption
  - Support publishing to the configured Instagram Business Account
- **Publishing Service** — A service object that handles the Meta Graph API interaction:
  - Obtain/use a valid Page Access Token
  - Create a media container (`POST /{ig-user-id}/media`)
  - Publish the container (`POST /{ig-user-id}/media_publish`)
  - Track publishing status
- **Admin UI for Publishing** — A button/action on the Spree Admin product page to publish a product to Instagram
- **Error Handling** — Graceful handling of API errors, token expiration, rate limits, and failed publishes
- **Per-Store Config** — Each Spree store maintains its own Instagram configuration (following the multi-tenant pattern)

## Implementation Notes

- Follow the exact same engine structure as `spree_pathao_courier`
- Use `Faraday` for HTTP requests (already a project dependency)
- Use `encrypts` for sensitive fields (App Secret, Page Access Token)
- Register admin sidebar navigation via `Spree.admin.navigation.sidebar.add`
- Position the sidebar item under a "Social Settings" parent group (position ~95, after AI Settings at 90)
- Use Spree 5.5 conventions: `Spree.base_class`, `Spree::Admin::BaseController`, `current_store`
- Add the engine to `backend/Gemfile` as: `gem 'spree_instagram_publisher', path: 'engines/spree_instagram_publisher'`

### Meta Instagram Content Publishing API Flow

1. **Prerequisites**: Instagram Professional (Business/Creator) account linked to a Facebook Page
2. **Get Page Access Token**: From Facebook App → Pages → Long-lived token
3. **Get IG Business Account ID**: `GET /{page-id}?fields=instagram_business_account`
4. **Create Media Container**: `POST /{ig-user-id}/media` with image_url, caption, product tags (optional)
5. **Publish**: `POST /{ig-user-id}/media_publish` with the container ID from step 4
6. **Check Status**: `GET /{media-id}?fields=status_code` (FINISHED, ERROR, IN_PROGRESS)

### API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/{page-id}?fields=instagram_business_account` | GET | Resolve IG Business Account ID from Page ID |
| `/{ig-user-id}/media` | POST | Create media container (image + caption) |
| `/{ig-user-id}/media_publish` | POST | Publish the media container |
| `/{media-id}?fields=status_code` | POST | Check publishing status |
| `/{ig-user-id}?fields=profile_picture_url,username` | GET | Verify account connection |

### Fields for Settings Model (`spree_instagram_publisher_configs`)

| Column | Type | Notes |
|--------|------|-------|
| `store_id` | FK (unique) | Links to `spree_stores` |
| `enabled` | boolean | Default: false |
| `app_id` | string | Facebook App ID |
| `app_secret` | string (encrypted) | Facebook App Secret |
| `page_id` | string | Facebook Page ID |
| `page_access_token` | string (encrypted) | Long-lived Page Access Token |
| `ig_business_account_id` | string | Auto-resolved from page_id or manually entered |
| `ig_username` | string | Cached IG username for display |
| `ig_profile_picture_url` | string | Cached profile picture URL |
| `default_caption_template` | text | Optional caption template with placeholders like `{product_name}`, `{price}`, `{url}` |
| `auto_publish` | boolean | Default: false — auto-publish on product creation/update |
| `last_publish_at` | datetime | Timestamp of last successful publish |

## Acceptance Criteria

- [ ] Engine creates successfully with proper directory structure
- [ ] Admin sidebar shows "Instagram" under Settings → Social Settings
- [ ] When integration is **disabled**: blank page with no form fields visible
- [ ] When integration is **enabled**: form with all credential fields visible
- [ ] Facebook credentials are encrypted in the database
- [ ] IG Business Account ID is auto-resolved from Page ID on save
- [ ] Products can be published to Instagram from the admin product page
- [ ] Publishing uses correct Meta Content Publishing API flow
- [ ] Error messages from API are displayed to the admin user
- [ ] Token expiration is handled gracefully
- [ ] Configuration is per-store (multi-tenant)
