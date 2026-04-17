#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found at $ENV_FILE"
  exit 1
fi

# Load .env — strip full-line comments, blank lines, and inline comments
while IFS= read -r line; do
  line="${line%%#*}"        # strip inline comments
  line="${line//[$'\t' ]}"  # strip all whitespace (tabs/spaces) around value
  [[ -z "$line" ]] && continue
  export "$line"
done < <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "Error: SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env"
  exit 1
fi

FLUTTER="/Users/shashankrajchavan/Documents/DevProjects/flutter/bin/flutter"

exec "$FLUTTER" run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=FIREBASE_API_KEY="${FIREBASE_API_KEY:-}" \
  --dart-define=FIREBASE_WEB_APP_ID="${FIREBASE_WEB_APP_ID:-}" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="${FIREBASE_MESSAGING_SENDER_ID:-}" \
  --dart-define=FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-}" \
  --dart-define=FIREBASE_AUTH_DOMAIN="${FIREBASE_AUTH_DOMAIN:-}" \
  --dart-define=FIREBASE_STORAGE_BUCKET="${FIREBASE_STORAGE_BUCKET:-}" \
  "$@"
