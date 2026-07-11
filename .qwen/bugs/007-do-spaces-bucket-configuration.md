# ISSUE-007: DigitalOcean Spaces Bucket Configuration Fix

**Status:** Open
**Severity:** High
**Reported:** 2026-07-09

---

## Description
DO Spaces bucket upload appears to complete but files are not accessible. The storage configuration needs to be unified for dev and prod environments using a single bucket with folder prefixes.

## Environment
- Rails 8.1 + Spree 5.5
- DigitalOcean Spaces (S3-compatible)
- ActiveStorage direct upload

## Steps to Reproduce
1. Configure storage to use DigitalOcean Spaces
2. Upload a file via admin panel
3. File upload appears successful
4. File is not accessible via expected URL

## Expected vs Actual
- **Expected:** Files uploaded to `dev/` folder in `minimeshop-bucket` are publicly accessible
- **Actual:** Upload completes but files are not accessible

## Root Cause
- Using `minimeshop-dev` bucket instead of `minimeshop-bucket` with `dev/` prefix
- Storage endpoint configuration incorrect

## Suggested Fix
1. Use single bucket `minimeshop-bucket` for both environments
2. Dev: prefix all keys with `dev/`
3. Prod: prefix all keys with `prod/` (or no prefix)
4. Update `storage.yml` to use correct endpoint: `https://minimeshop-bucket.sgp1.digitaloceanspaces.com`

## Configuration
- **Bucket:** minimeshop-bucket
- **Region:** sgp1
- **Endpoint:** https://minimeshop-bucket.sgp1.digitaloceanspaces.com
- **Credentials:** DO_SPACES_KEY / DO_SPACES_SECRET (existing)
