#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/supabase_login.sh <SUPABASE_ACCESS_TOKEN>
# Or set env var SUPABASE_ACCESS_TOKEN

TOKEN="${1:-${SUPABASE_ACCESS_TOKEN:-}}"
if [ -z "${TOKEN}" ]; then
  echo "Supabase access token not provided. Pass as arg or SUPABASE_ACCESS_TOKEN env." >&2
  exit 1
fi

if ! command -v supabase >/dev/null 2>&1; then
  echo "Installing Supabase CLI via Homebrew (macOS)..." >&2
  if command -v brew >/dev/null 2>&1; then
    brew install supabase/tap/supabase
  else
    echo "Homebrew not found. Install supabase CLI manually: https://supabase.com/docs/guides/cli" >&2
    exit 1
  fi
fi

# Non-interactive login
SUPABASE_ACCESS_TOKEN="${TOKEN}" supabase login --no-open

echo "Supabase CLI logged in." >&2
