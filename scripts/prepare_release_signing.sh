#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
APP_DIR="$ANDROID_DIR/app"

if [[ -n "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  : "${ANDROID_KEY_ALIAS:?ANDROID_KEY_ALIAS is required when a keystore is provided}"
  : "${ANDROID_KEY_PASSWORD:?ANDROID_KEY_PASSWORD is required when a keystore is provided}"
  : "${ANDROID_STORE_PASSWORD:?ANDROID_STORE_PASSWORD is required when a keystore is provided}"
  mkdir -p "$APP_DIR"
  printf '%s' "$ANDROID_KEYSTORE_BASE64" | base64 --decode > "$APP_DIR/upload-keystore.jks"
  chmod 600 "$APP_DIR/upload-keystore.jks"
  cat > "$ANDROID_DIR/key.properties" <<PROPERTIES
storeFile=app/upload-keystore.jks
storePassword=${ANDROID_STORE_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
keyPassword=${ANDROID_KEY_PASSWORD}
PROPERTIES
  echo "Release keystore configured from CI secrets."
elif [[ "${ALLOW_DEBUG_SIGNED_RELEASE:-false}" == "true" ]]; then
  echo "WARNING: Building a preview APK with the Android debug key. Do not publish this APK or use it as a permanent update key." >&2
else
  echo "ERROR: No release keystore configured. Supply ANDROID_KEYSTORE_BASE64, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD and ANDROID_STORE_PASSWORD." >&2
  exit 1
fi
