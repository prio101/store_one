# Instagram Publisher Setup Guide

> Complete step-by-step guide for setting up Instagram content publishing via the Meta Graph API in Spree Commerce.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Create a Facebook App](#step-1-create-a-facebook-app)
3. [Configure App Permissions](#step-2-configure-app-permissions)
4. [Link Instagram Business Account to Facebook Page](#step-3-link-instagram-business-account-to-facebook-page)
5. [Get Access Tokens](#step-4-get-access-tokens)
6. [Configure Spree Instagram Publisher](#step-5-configure-spree-instagram-publisher)
7. [Exchange for Long-Lived Token](#step-6-exchange-for-long-lived-token)
8. [Test the Integration](#step-7-test-the-integration)
9. [Troubleshooting](#troubleshooting)
10. [API Reference](#api-reference)

---

## Prerequisites

- Facebook Developer Account
- Instagram Business or Creator Account
- Facebook Page (linked to the Instagram account)
- Spree Commerce 5.5+ with `spree_instagram_publisher` engine installed

---

## Step 1: Create a Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click **My Apps** → **Create App**
3. Select **Business** as the app type
4. Enter app details:
   - **App Name**: Your store name (e.g., "MinimeShop Instagram")
   - **App Contact Email**: Your email
   - **Business Account**: Select your business account (or create one)
5. Click **Create App**

### Note Your App Credentials

After creation, go to **Settings → Basic** and note:
- **App ID** (e.g., `2133193717229996`)
- **App Secret** (click "Show" to reveal)

---

## Step 2: Configure App Permissions

### Required Permissions

For Instagram content publishing, you need these permissions:

| Permission | Purpose |
|------------|---------|
| `instagram_content_publish` | Publish photos/videos to Instagram |
| `pages_show_list` | List Facebook Pages |
| `pages_read_engagement` | Read Page engagement data |
| `business_management` | Manage business assets |

### How to Add Permissions

1. Go to **App Review → Permissions and Features**
2. Search for each permission
3. Click **"Request"** for each one
4. Follow the review process

**Note**: `instagram_content_publish` is a sensitive permission that may require App Review for production use.

---

## Step 3: Link Instagram Business Account to Facebook Page

This is the **most common cause** of "Instagram Business Account not found" errors.

### Check if Already Linked

Use Graph API Explorer to verify:

```bash
curl -X GET "https://graph.facebook.com/v25.0/{PAGE_ID}?fields=instagram_business_account&access_token={ACCESS_TOKEN}"
```

**If linked**, you'll see:
```json
{
  "instagram_business_account": {
    "id": "17841400XXXXXXX"
  },
  "name": "Your Page Name",
  "id": "114841321690577"
}
```

**If NOT linked**, you'll see:
```json
{
  "name": "Your Page Name",
  "id": "114841321690577"
}
```

(Notice the missing `instagram_business_account` field)

### Link the Accounts

1. Go to your **Facebook Page**
2. Click **Settings** (gear icon)
3. Navigate to **Instagram** in the left sidebar
4. Click **"Connect Account"**
5. Log in with your Instagram Business Account credentials
6. Authorize the connection

### Verify Instagram Account Type

Your Instagram account must be a **Business** or **Creator** account:

1. Open Instagram app
2. Go to **Settings → Account**
3. Check if you see "Switch to Professional Account" or "Account Type"
4. If it says "Personal Account", you need to switch to Business/Creator

---

## Step 4: Get Access Tokens

### Using Graph API Explorer

1. Go to [Graph API Explorer](https://developers.facebook.com/tools/explorer/)
2. Select your app from the dropdown (top-right)
3. Click **"Generate Access Token"**
4. Select these permissions:
   - `instagram_content_publish`
   - `pages_show_list`
   - `pages_read_engagement`
   - `business_management`
5. Select the Facebook Page linked to your Instagram account
6. Click **"Generate Access Token"**

### Important: Use the PAGE Access Token

The response from `/me/accounts` contains both User and Page Access Tokens:

```json
{
  "data": [
    {
      "access_token": "EAAeUIN3AqawBR...",  // ← THIS IS THE PAGE ACCESS TOKEN
      "name": "Your Page Name",
      "id": "114841321690577"
    }
  ]
}
```

**Use the token from `data[0].access_token`**, not the user token used to make the request.

---

## Step 5: Configure Spree Instagram Publisher

1. Log in to Spree Admin
2. Go to **Instagram Publisher** in the sidebar
3. Fill in the configuration:

| Field | Value |
|-------|-------|
| Enable Instagram Integration | ✅ Checked |
| Facebook App ID | Your App ID (e.g., `2133193717229996`) |
| Facebook App Secret | Your App Secret |
| Facebook Page ID | Page ID (e.g., `114841321690577`) |
| Short-Lived Page Access Token | Page Access Token from Step 4 |

4. Click **"Save Configuration"**

The system will automatically resolve the Instagram Business Account ID from the Page ID.

---

## Step 6: Exchange for Long-Lived Token

Short-lived tokens expire in ~1-2 hours. Exchange for a long-lived token (~60 days):

1. On the Instagram Publisher config page, find **"Exchange for Long-Lived Token"**
2. Click **"Exchange Token"**
3. Confirm the exchange

**What happens:**
- System calls `GET /oauth/access_token` with your short-lived token
- Returns a long-lived token valid for ~60 days
- Token is stored securely (encrypted in database)

**After exchange:**
- The form will show the long-lived token field with an "Active" badge
- Future API calls will use the long-lived token automatically

---

## Step 7: Test the Integration

### Verify Configuration

Run this in Rails console:

```bash
cd backend && bundle exec rails runner "
config = Spree::InstagramPublisherConfig.first
puts 'App ID: ' + config.app_id.to_s
puts 'Page ID: ' + config.page_id.to_s
puts 'IG Business Account ID: ' + config.ig_business_account_id.to_s
puts 'IG Username: ' + config.ig_username.to_s
puts 'Long Lived Token Present: ' + config.long_lived_token.present?.to_s
puts 'Page Access Token Present: ' + config.page_access_token.present?.to_s
"
```

### Publish a Test Product

1. Go to **Products** in Spree Admin
2. Click **"Publish to Instagram"** on any product with an image
3. Check the logs for success/failure

---

## Troubleshooting

### Error: "Instagram API error (400): Unsupported post request. Object with ID 'XXX' does not exist"

**Cause**: The IG Business Account ID is incorrect or the Page is not linked to Instagram.

**Fix**:
1. Verify the Page is linked to Instagram (see Step 3)
2. The system will automatically re-resolve the IG account ID

### Error: "Instagram Business Account not found"

**Cause**: The Facebook Page has no Instagram account connected.

**Fix**:
1. Go to Facebook Page → Settings → Instagram
2. Click "Connect Account"
3. Log in with Instagram credentials

### Error: "Authentication failed (401)"

**Cause**: The access token is invalid or expired.

**Fix**:
1. Generate a new token in Graph API Explorer
2. Update the config with the new token
3. Exchange for a long-lived token

### Error: "Token is invalid according to Graph API"

**Cause**: The token was exchanged from the wrong app or has incorrect permissions.

**Fix**:
1. Clear the long-lived token in Rails console:
   ```bash
   cd backend && bundle exec rails runner "
   config = Spree::InstagramPublisherConfig.first
   config.update!(long_lived_token: nil)
   "
   ```
2. Paste a new Page Access Token from the correct app
3. Exchange for a long-lived token

### "No long-lived token yet" Message

**Cause**: The `long_lived_token` column doesn't exist or the exchange hasn't been done.

**Fix**:
1. Run the migration:
   ```bash
   docker compose exec web bin/rails db:migrate
   ```
2. Click "Exchange Token" in the admin panel

### Token Missing `instagram_content_publish` Permission

**Cause**: The app doesn't have the required permission.

**Fix**:
1. Go to Facebook App Dashboard → App Review → Permissions and Features
2. Search for `instagram_content_publish`
3. Request the permission
4. Wait for App Review approval (or use in Development mode)

---

## API Reference

### Graph API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/me/accounts` | GET | List Facebook Pages and their tokens |
| `/{page-id}?fields=instagram_business_account` | GET | Resolve IG Business Account ID |
| `/{ig-user-id}?fields=username,profile_picture_url` | GET | Verify IG account info |
| `/{ig-user-id}/media` | POST | Create media container |
| `/{media-id}?fields=status_code,status` | GET | Check container status |
| `/{ig-user-id}/media_publish` | POST | Publish the container |
| `/debug_token` | GET | Validate access token |
| `/oauth/access_token` | GET | Exchange for long-lived token |

### Required Scopes

- `instagram_content_publish` — Publish content to Instagram
- `pages_show_list` — List Facebook Pages
- `pages_read_engagement` — Read Page data
- `business_management` — Manage business assets

---

## Token Lifecycle

```
User Access Token (short-lived, ~1 hour)
    ↓
Page Access Token (from /me/accounts)
    ↓
Long-Lived Token (via /oauth/access_token, ~60 days)
    ↓
Used by Instagram Publisher for API calls
```

### Token Refresh

- Long-lived tokens last ~60 days
- Exchange again before expiration
- The system automatically prefers long-lived tokens

---

## Security Notes

- Access tokens are encrypted in the database (`encrypts :page_access_token`, `encrypts :long_lived_token`)
- Never expose tokens in logs or error messages
- Rotate tokens regularly
- Use the minimum required permissions

---

## Quick Reference Commands

```bash
# Run migrations
docker compose exec web bin/rails db:migrate

# Check config
docker compose exec web bin/rails runner "
config = Spree::InstagramPublisherConfig.first
puts config.as_json(only: [:app_id, :page_id, :ig_business_account_id, :ig_username])
"

# Clear stale long-lived token
docker compose exec web bin/rails runner "
Spree::InstagramPublisherConfig.first.update!(long_lived_token: nil)
"

# Re-resolve IG account
docker compose exec web bin/rails runner "
config = Spree::InstagramPublisherConfig.first
client = Spree::InstagramPublisher::Client.new(config)
ig_id = client.resolve_ig_business_account(config.page_id)
puts 'Resolved IG ID: ' + ig_id.to_s
"

# Verify IG account
docker compose exec web bin/rails runner "
config = Spree::InstagramPublisherConfig.first
client = Spree::InstagramPublisher::Client.new(config)
puts client.verify_ig_account(config.ig_business_account_id).inspect
"
```

---

*Last updated: July 13, 2026*
