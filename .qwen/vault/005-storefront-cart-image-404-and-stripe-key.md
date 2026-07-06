# Issue 005: Storefront Cart - Image 404 & Stripe API Key Error

## Reported
2026-07-06

## Summary
Two issues observed in the storefront cart page:

### Issue 1: Active Storage Image 404
- **Error**: `upstream image response failed for https://minimeshop.net/rails/active_storage/blobs/proxy/...png 404`
- **Affected**: Product images (e.g., `Arcade_decay_red.png`)
- **Likely Cause**: DigitalOcean Spaces configuration mismatch between backend and production server. The Active Storage blobs are pointing to an inaccessible storage endpoint.
- **Related**: See vault/001 (Pathao integration) and .qwen/bugs/001-002 (image loading issues)

### Issue 2: Stripe API Key Invalid
- **Error**: `Invalid API Key provided: pk_test_***********************_key`
- **Status**: 401 Unauthorized
- **Likely Cause**: The Stripe publishable key in the storefront environment is either a placeholder or incorrect for the production environment.
- **Note**: Live Stripe.js integrations must use HTTPS.

## Hypothesis: Asset Prebuild Connection
User suspects issues are related to asset precompilation. Possible causes:
- Active Storage service not properly configured in production environment
- Stripe publishable key not set or overridden in storefront env
- CDN/proxy configuration not routing Active Storage URLs correctly

## Investigation Steps
1. Verify `ACTIVE_STORAGE_SERVICE` in production backend env
2. Confirm DigitalOcean Spaces bucket exists and is accessible
3. Check `STRIPE_PUBLISHABLE_KEY` in storefront env
4. Verify Rails `config.active_storage.service` matches actual storage service
5. Check if `rails/active_storage/blobs/proxy/` path is being proxied correctly in Next.js

## Related Issues
- .qwen/bugs/001-images-not-loading-digitalocean-spaces.md
- .qwen/bugs/002-digitalocean-storage-env-var-mismatch.md
- vault/002-spree-dev-compose-engine-loading.md (local dev vs production differences)

## Priority
High - Cart functionality is broken for image display; Stripe integration non-functional.
