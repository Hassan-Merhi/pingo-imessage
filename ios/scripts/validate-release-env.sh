#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "release-env: $1" >&2
  exit 1
}

: "${DEVELOPMENT_TEAM:?DEVELOPMENT_TEAM is required}"
: "${PINGO_API_BASE_URL:?PINGO_API_BASE_URL is required}"
: "${PINGO_MESSAGE_BASE_URL:?PINGO_MESSAGE_BASE_URL is required}"
: "${MARKETING_VERSION:=1.0.0}"
: "${CURRENT_PROJECT_VERSION:=1}"

[[ "$DEVELOPMENT_TEAM" =~ ^[A-Za-z0-9]{10}$ ]] || fail "DEVELOPMENT_TEAM must be a 10-character Apple team ID"
[[ "$MARKETING_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "MARKETING_VERSION must use semantic version form such as 1.0.0"
[[ "$CURRENT_PROJECT_VERSION" =~ ^[1-9][0-9]*$ ]] || fail "CURRENT_PROJECT_VERSION must be a positive integer"

validate_https_url() {
  local name="$1"
  local value="$2"
  [[ "$value" == https://* ]] || fail "$name must use https://"
  [[ "$value" != *".invalid"* ]] || fail "$name still uses a .invalid placeholder"
  [[ "$value" != *"example.com"* ]] || fail "$name still uses example.com"
  [[ "$value" != *"localhost"* ]] || fail "$name cannot use localhost for an App Store archive"
}

validate_https_url PINGO_API_BASE_URL "$PINGO_API_BASE_URL"
validate_https_url PINGO_MESSAGE_BASE_URL "$PINGO_MESSAGE_BASE_URL"

if [[ -n "${APP_STORE_CONNECT_KEY_PATH:-}" ]]; then
  [[ -f "$APP_STORE_CONNECT_KEY_PATH" ]] || fail "APP_STORE_CONNECT_KEY_PATH does not exist"
  : "${APP_STORE_CONNECT_KEY_ID:?APP_STORE_CONNECT_KEY_ID is required when APP_STORE_CONNECT_KEY_PATH is set}"
  : "${APP_STORE_CONNECT_ISSUER_ID:?APP_STORE_CONNECT_ISSUER_ID is required when APP_STORE_CONNECT_KEY_PATH is set}"
fi

echo "release-env: production release values look valid"
