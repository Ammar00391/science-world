#!/usr/bin/env bash
set -euo pipefail

SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$SDK_ROOT" ]]; then
  echo "ERROR: ANDROID_SDK_ROOT/ANDROID_HOME is not set in the build environment." >&2
  exit 1
fi

SDKMANAGER="${SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"
if [[ ! -x "$SDKMANAGER" ]]; then
  SDKMANAGER="$(find "$SDK_ROOT/cmdline-tools" -maxdepth 3 -type f -name sdkmanager -perm -u+x 2>/dev/null | sort | tail -n 1 || true)"
fi
if [[ -z "$SDKMANAGER" || ! -x "$SDKMANAGER" ]]; then
  echo "ERROR: Android sdkmanager was not found under $SDK_ROOT/cmdline-tools." >&2
  exit 1
fi

# Accept required Android SDK licenses non-interactively in CI.
yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true

"$SDKMANAGER" --install \
  "platforms;android-36" \
  "build-tools;36.0.0" \
  "ndk;28.2.13676358"

echo "Android platform 36, Build Tools 36.0.0 and NDK 28.2.13676358 are ready."
