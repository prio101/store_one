#!/usr/bin/env bash
# Upload a file to DigitalOcean Spaces and print the public URL.
#
# Usage:
#   ./scripts/do_spaces_upload.sh <file> [key]
#
# Examples:
#   ./scripts/do_spaces_upload.sh photo.jpg                     # key = photo.jpg
#   ./scripts/do_spaces_upload.sh photo.jpg uploads/photo.jpg   # custom key

set -euo pipefail

# ── Load .env ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source <(grep -v '^#' "$ENV_FILE" | grep -v '^\s*$')
  set +a
fi

# ── Map DO env vars → AWS env vars ────────────────────────────────
export AWS_ACCESS_KEY_ID="${DO_SPACES_KEY:?DO_SPACES_KEY not set}"
export AWS_SECRET_ACCESS_KEY="${DO_SPACES_SECRET:?DO_SPACES_SECRET not set}"

REGION="${DO_SPACES_REGION:-sgp1}"
BUCKET="${DO_SPACES_BUCKET:?DO_SPACES_BUCKET not set}"
ENDPOINT="https://${REGION}.digitaloceanspaces.com"

# ── Args ──────────────────────────────────────────────────────────
FILE="${1:?Usage: $0 <file> [key]}"
FILE_KEY="${2:-$(basename "$FILE")}"

if [[ ! -f "$FILE" ]]; then
  echo "❌ File not found: $FILE"
  exit 1
fi

FILE_SIZE=$(stat -c%s "$FILE" 2>/dev/null || stat -f%z "$FILE")

echo "📤 Uploading: $FILE ($FILE_SIZE bytes) → s3://$BUCKET/$FILE_KEY"
echo "   Endpoint : $ENDPOINT"
echo ""

aws s3 cp "$FILE" "s3://$BUCKET/$FILE_KEY" \
  --endpoint-url "$ENDPOINT" \
  --region "$REGION"

echo ""
echo "✅ Uploaded."
echo ""

# ── Construct public URL ─────────────────────────────────────────
PUBLIC_URL="https://${BUCKET}.${REGION}.digitaloceanspaces.com/${FILE_KEY}"
echo "🔗 Public URL: $PUBLIC_URL"
echo ""

# ── Verify it's accessible ───────────────────────────────────────
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$PUBLIC_URL")
if [[ "$HTTP_CODE" == "200" ]]; then
  echo "✅ HTTP $HTTP_CODE — File is publicly accessible."
elif [[ "$HTTP_CODE" == "403" ]]; then
  echo "⚠️  HTTP $HTTP_CODE — Forbidden. File exists but is not publicly readable."
  echo "   → Enable public access in your DO Spaces bucket settings:"
  echo "     https://cloud.digitalocean.com/spaces/$BUCKET?content=permissions"
  echo "     Toggle 'File Listing' to Public, or set a bucket-level read policy."
else
  echo "⚠️  HTTP $HTTP_CODE — Unexpected response."
fi
