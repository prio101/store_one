# BUG-002: DigitalOcean Spaces storage not configured — env var names mismatch

**Status:** Fixed
**Severity:** High — Active Storage cannot reach DigitalOcean Spaces in production
**Reported:** 2026-07-01
**URL:** https://minimeshop.net

---

## Description

Rails Active Storage is configured to use DigitalOcean Spaces (S3-compatible) as the production storage backend, but the environment variables in the server's `.env` file use `DO_SPACES_*` naming while `storage.yml` expects `AWS_*` naming. As a result, Active Storage cannot authenticate or locate the bucket.

## Root Cause

**Server `.env`** (`/opt/store_one/.env`):

```
DO_SPACES_KEY=DO003T6NG8QQJV78BU4A
DO_SPACES_SECRET=LeCeTmGHCSkJVtzsq/omYdrgz0H+ttPZyozRy4JsbMs
DO_SPACES_BUCKET=minimeshop
DO_SPACES_REGION=sgp1
```

**`backend/config/storage.yml`** expects:

```yaml
amazon:
  service: S3
  endpoint: <%= ENV.fetch("AWS_ENDPOINT", "") %>
  access_key_id: <%= ENV.fetch("AWS_ACCESS_KEY_ID", "") %>
  secret_access_key: <%= ENV.fetch("AWS_SECRET_ACCESS_KEY", "") %>
  region: <%= ENV.fetch("AWS_REGION", "") %>
  bucket: <%= ENV.fetch("AWS_BUCKET", "spree-#{Rails.env}") %>
  public: true
```

**`docker-compose.prod.yml`** sets `ACTIVE_STORAGE_SERVICE: amazon`, which triggers the `amazon` service — but all `ENV.fetch` calls return empty strings because `DO_SPACES_*` ≠ `AWS_*`.

### Additional issue: Bucket name mismatch

- Server `.env`: `DO_SPACES_BUCKET=minimeshop`
- Local `.env`: `AWS_BUCKET=minimeshop-bucket`

The correct bucket name needs to be confirmed with the user.

## Evidence

```bash
# Server container env check:
$ docker compose exec web printenv | grep -E 'AWS_|ACTIVE_STORAGE'
ACTIVE_STORAGE_SERVICE=amazon
# (no AWS_* vars — all empty)

# Server .env:
$ cat /opt/store_one/.env | grep DO_SPACES
DO_SPACES_KEY=DO003T6NG8QQJV78BU4A
DO_SPACES_SECRET=LeCeTmGHCSkJVtzsq/omYdrgz0H+ttPZyozRy4JsbMs
DO_SPACES_BUCKET=minimeshop
DO_SPACES_REGION=sgp1
```

## Impact

- Active Storage falls back to local disk storage (or fails silently)
- Product images uploaded via the admin panel are not persisted to DigitalOcean Spaces
- New image uploads may work locally but won't be accessible from the CDN
- Existing images that were previously uploaded to DO Spaces may still work if they were uploaded before the env var mismatch

## Note

DigitalOcean Spaces is **S3-compatible** — the `service: S3` config in `storage.yml` is correct. The issue is purely the environment variable naming mismatch.

## Fix

### Option A: Update `storage.yml` to match server env vars (recommended)

Change `storage.yml` to read from the actual env var names:

```yaml
amazon:
  service: S3
  endpoint: "https://<%= ENV.fetch("DO_SPACES_REGION", "sgp1") %>.digitaloceanspaces.com"
  access_key_id: <%= ENV.fetch("DO_SPACES_KEY", "") %>
  secret_access_key: <%= ENV.fetch("DO_SPACES_SECRET", "") %>
  region: <%= ENV.fetch("DO_SPACES_REGION", "sgp1") %>
  bucket: <%= ENV.fetch("DO_SPACES_BUCKET", "minimeshop") %>
  public: true
```

### Option B: Rename env vars on the server to match `storage.yml`

Add `AWS_*` aliases to the server's `.env`:

```
AWS_ACCESS_KEY_ID=DO003T6NG8QQJV78BU4A
AWS_SECRET_ACCESS_KEY=LeCeTmGHCSkJVtzsq/omYdrgz0H+ttPZyozRy4JsbMs
AWS_BUCKET=minimeshop
AWS_REGION=sgp1
AWS_ENDPOINT=https://sgp1.digitaloceanspaces.com
```

### Required: Confirm bucket name

The server has `minimeshop` but local has `minimeshop-bucket`. Need to confirm which is correct.

## Verification

1. Apply the fix
2. Restart the web container
3. Run in Rails console: `ActiveStorage::Blob.service.url_for_direct_upload(...)`
4. Verify the returned URL points to the correct DO Spaces bucket
5. Upload a test image via admin and confirm it's accessible from the storefront

## Related

- BUG-001: Product images not loading (Next.js remotePatterns — fixed)
- `backend/config/storage.yml`
- `backend/config/environments/production.rb`
- `/opt/store_one/.env` (server)
- `docker-compose.prod.yml`

---

## Fix Applied (2026-07-01)

### Changes

1. **`backend/config/storage.yml`** — Changed env var names from `AWS_*` to `DO_SPACES_*`:
   ```yaml
   amazon:
     service: S3
     endpoint: "https://<%= ENV.fetch('DO_SPACES_REGION', 'sgp1') %>.digitaloceanspaces.com"
     access_key_id: <%= ENV.fetch("DO_SPACES_KEY", "") %>
     secret_access_key: <%= ENV.fetch("DO_SPACES_SECRET", "") %>
     region: <%= ENV.fetch("DO_SPACES_REGION", "sgp1") %>
     bucket: <%= ENV.fetch("DO_SPACES_BUCKET", "minimeshop-bucket") %>
     public: true
   ```

2. **`backend/config/environments/production.rb`** — Added `DO_SPACES_*` check before `AWS_*` fallback:
   ```ruby
   if ENV["DO_SPACES_KEY"].present? && ENV["DO_SPACES_SECRET"].present?
     config.active_storage.service = :amazon
   elsif ENV["AWS_ACCESS_KEY_ID"].present? && ENV["AWS_SECRET_ACCESS_KEY"].present?
     config.active_storage.service = :amazon
   # ...
   ```

3. **Server `.env`** (`/opt/store_one/.env`) — Fixed bucket name: `minimeshop` → `minimeshop-bucket`

### Verification

```ruby
# Rails console on production:
ActiveStorage::Blob.service.class  #=> ActiveStorage::Service::S3Service
ActiveStorage::Blob.service.bucket.name  #=> "minimeshop-bucket"
```
