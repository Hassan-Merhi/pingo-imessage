#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

bash ios/scripts/validate-release-env.sh

: "${ARCHIVE_DIR:=$ROOT/build/app-store}"
: "${ARCHIVE_PATH:=$ARCHIVE_DIR/Pingo.xcarchive}"
: "${EXPORT_PATH:=$ARCHIVE_DIR/export}"

rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
mkdir -p "$ARCHIVE_DIR" "$EXPORT_PATH"

bash ios/scripts/generate-imessage-icons.sh
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install it with: brew install xcodegen" >&2
  exit 1
fi
xcodegen generate --spec ios/project.yml

auth_args=()
if [[ -n "${APP_STORE_CONNECT_KEY_PATH:-}" ]]; then
  auth_args+=(
    -authenticationKeyPath "$APP_STORE_CONNECT_KEY_PATH"
    -authenticationKeyID "$APP_STORE_CONNECT_KEY_ID"
    -authenticationKeyIssuerID "$APP_STORE_CONNECT_ISSUER_ID"
  )
fi

xcodebuild \
  -project ios/Pingo.xcodeproj \
  -scheme Pingo \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  "${auth_args[@]}" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  MARKETING_VERSION="$MARKETING_VERSION" \
  CURRENT_PROJECT_VERSION="$CURRENT_PROJECT_VERSION" \
  PINGO_API_BASE_URL="$PINGO_API_BASE_URL" \
  PINGO_MESSAGE_BASE_URL="$PINGO_MESSAGE_BASE_URL" \
  archive

export_options="$ARCHIVE_DIR/ExportOptions.plist"
cat > "$export_options" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>destination</key>
  <string>export</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${DEVELOPMENT_TEAM}</string>
  <key>manageAppVersionAndBuildNumber</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
PLIST

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$export_options" \
  -allowProvisioningUpdates \
  "${auth_args[@]}"

ipa="$(find "$EXPORT_PATH" -maxdepth 1 -name '*.ipa' -print -quit)"
[[ -n "$ipa" ]] || { echo "No IPA was produced" >&2; exit 1; }

echo "App Store archive ready: $ARCHIVE_PATH"
echo "IPA ready: $ipa"
