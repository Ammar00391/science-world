#!/usr/bin/env bash
set -euo pipefail

apk="build/app/outputs/flutter-apk/app-release.apk"
aab="build/app/outputs/bundle/release/app-release.aab"
sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
apksigner="${sdk_root}/build-tools/36.0.0/apksigner"

for artifact in "$apk" "$aab"; do
  if [[ ! -s "$artifact" ]]; then
    echo "Expected signed Release artifact is missing or empty: $artifact" >&2
    exit 1
  fi
done

if [[ ! -x "$apksigner" ]]; then
  echo "Android apksigner was not found in Build Tools 36.0.0." >&2
  exit 1
fi

"$apksigner" verify "$apk"
echo "APK signature verified."

if ! command -v jarsigner >/dev/null 2>&1; then
  echo "Java jarsigner is required to verify the Android App Bundle." >&2
  exit 1
fi

bundle_verification="$(jarsigner -verify "$aab" 2>&1)" || {
  echo "App Bundle signature verification failed." >&2
  exit 1
}
if ! grep -Fq 'jar verified.' <<< "$bundle_verification"; then
  echo "App Bundle is not signed with a verifiable certificate." >&2
  exit 1
fi

echo "App Bundle signature verified."
