#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"
ASSET_ROOT="$IOS_DIR/Resources/Assets.xcassets"
MASTER="$ASSET_ROOT/AppIcon.appiconset/Icon-1024.png"
OUTPUT="$ASSET_ROOT/iMessage App Icon.stickersiconset"

if ! command -v sips >/dev/null 2>&1; then
  echo "error: sips is required to generate iMessage icon variants (run this on macOS)." >&2
  exit 1
fi

if [[ ! -f "$MASTER" ]]; then
  echo "error: missing master Pingo app icon: $MASTER" >&2
  exit 1
fi

mkdir -p "$OUTPUT"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
RECT_MASTER="$TMP_DIR/Pingo-iMessage-1024x768.png"

# Messages extension icons use a 4:3 canvas. Center-crop the square master so
# the Pingo mark remains consistent with the normal iOS icon.
sips --cropToHeightWidth 768 1024 "$MASTER" --out "$RECT_MASTER" >/dev/null

resize_rect() {
  local height="$1"
  local width="$2"
  local filename="$3"
  sips --resampleHeightWidth "$height" "$width" "$RECT_MASTER" --out "$OUTPUT/$filename" >/dev/null
}

resize_square() {
  local pixels="$1"
  local filename="$2"
  sips --resampleHeightWidth "$pixels" "$pixels" "$MASTER" --out "$OUTPUT/$filename" >/dev/null
}

resize_square 58 "Messages29x29@2x.png"
resize_square 87 "Messages29x29@3x.png"
resize_square 58 "Messages29x29-iPad@2x.png"
resize_rect 90 120 "Messages60x45@2x.png"
resize_rect 135 180 "Messages60x45@3x.png"
resize_rect 100 134 "Messages67x50@2x.png"
resize_rect 110 148 "Messages74x55@2x.png"
resize_rect 40 54 "Messages27x20@2x.png"
resize_rect 60 81 "Messages27x20@3x.png"
resize_rect 48 64 "Messages32x24@2x.png"
resize_rect 72 96 "Messages32x24@3x.png"
cp "$RECT_MASTER" "$OUTPUT/MessagesMarketing.png"

echo "Generated Pingo iMessage icon variants in: $OUTPUT"
