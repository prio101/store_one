# BUG-001: Product images not loading — Next.js blocks DigitalOcean Spaces URLs

**Status:** Fixed
**Severity:** High — storefront shows placeholder images for all products
**Reported:** 2026-07-01
**URL:** https://minimeshop.net/bd/en

---

## Description

All product images on the storefront display as gray placeholder icons instead of actual images. The Spree backend stores images on DigitalOcean Spaces (S3-compatible), but the Next.js storefront's `Image` component refuses to load them because the CDN domain is not in the allowed `images.remotePatterns` list.

## Root Cause

`apps/storefront/next.config.ts` — `images.remotePatterns` does not include the DigitalOcean Spaces domain (`*.digitaloceanspaces.com`).

Current allowed origins:

| Pattern | Purpose |
|---------|---------|
| `localhost` | Local dev |
| `**.vendo.dev` | Spree Cloud dev |
| `**.spree.sh` | Spree Cloud |
| `**.trycloudflare.com` | Dev tunnels |

**Missing:** `*.digitaloceanspaces.com` (production image storage)

The Spree API returns product image URLs pointing to:

```
https://minimeshop-bucket.sgp1.digitaloceanspaces.com/...
```

Next.js `<Image>` silently blocks the load, the `ProductImage` component catches the error, and the fallback `<ImageIcon>` placeholder is rendered.

## Evidence

- **Storage config:** `backend/.env` sets `AWS_ENDPOINT=https://sgp1.digitaloceanspaces.com`, `AWS_BUCKET=minimeshop-bucket`
- **Active Storage:** `backend/config/storage.yml` uses `service: S3` with no explicit `endpoint` key — the AWS SDK reads `AWS_ENDPOINT` from the environment
- **Production:** `docker-compose.prod.yml` sets `ACTIVE_STORAGE_SERVICE: amazon`
- **nginx:** `/rails/active_storage` is proxied to Rails, but Active Storage with S3 service generates direct cloud URLs, not proxied paths

## Impact

- All product images are broken across the entire storefront (home page, product pages, search, cart, order history)
- Category images may also be affected
- Degrades user experience and store credibility

## Fix

### 1. Add DigitalOcean Spaces AND minimeshop.net to `next.config.ts` `remotePatterns`

Two patterns are needed:
- `**.digitaloceanspaces.com` — for direct DO Spaces URLs
- `minimeshop.net` — for Active Storage proxied URLs (the API returns `https://minimeshop.net/rails/active_storage/blobs/proxy/...`)

```ts
// apps/storefront/next.config.ts
images: {
  remotePatterns: [
    // ... existing patterns ...
    {
      protocol: "https",
      hostname: "minimeshop.net",
      pathname: "/rails/active_storage/**",
    },
    {
      protocol: "https",
      hostname: "**.digitaloceanspaces.com",
      pathname: "/**",
    },
  ],
},
```

**Note:** The Active Storage URLs use the proxied format (`minimeshop.net/rails/active_storage/blobs/proxy/...`), NOT direct DO Spaces URLs. Without `minimeshop.net` in the list, Next.js Image Optimization rejects the URLs with `"url" parameter is not allowed` (HTTP 400).

### 2. (Recommended) Also add `endpoint` to `backend/config/storage.yml`

The `amazon` service lacks an `endpoint` key. While the AWS SDK reads `AWS_ENDPOINT` from the environment, being explicit prevents URL format surprises:

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

Adding `public: true` ensures Active Storage generates direct public URLs (not signed/redirect URLs), which is what you want for a public-facing storefront.

### 3. (Optional) Add a proxy rewrite in `next.config.ts`

As a defense-in-depth measure, proxy images through the storefront to avoid exposing the CDN directly and to allow future domain changes without client-side rebuilds:

```ts
images: {
  remotePatterns: [
    // ... existing patterns ...
    {
      protocol: "https",
      hostname: "minimeshop.net",
      pathname: "/rails/active_storage/**",
    },
    {
      protocol: "https",
      hostname: "**.digitaloceanspaces.com",
      pathname: "/**",
    },
  ],
},
```

## Verification

1. Apply the `remotePatterns` change to `next.config.ts`
2. Redeploy the storefront
3. Visit https://minimeshop.net/bd/en
4. Confirm product images load instead of placeholders
5. Check browser DevTools Network tab — image requests should return 200, not be blocked

## Notes

- The DigitalOcean Spaces endpoint is `sgp1.digitaloceanspaces.com` (Singapore region)
- The bucket is `minimeshop-bucket`
- The `ProductImage` component (`apps/storefront/src/components/ui/product-image.tsx`) handles the error gracefully by showing a placeholder — this is working as designed, but masks the underlying configuration issue
