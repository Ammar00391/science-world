#!/usr/bin/env bash
set -euo pipefail

sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$sdk_root" ]]; then
  echo "ANDROID_SDK_ROOT or ANDROID_HOME must point to the Android SDK." >&2
  exit 1
fi

sdkmanager="${sdk_root}/cmdline-tools/latest/bin/sdkmanager"
if [[ ! -x "$sdkmanager" ]]; then
  sdkmanager="$(command -v sdkmanager || true)"
fi
if [[ -z "$sdkmanager" || ! -x "$sdkmanager" ]]; then
  echo "Android sdkmanager is required to verify SDK 36 and NDK 28.2.13676358." >&2
  exit 1
fi

packages=(
  "platforms;android-36"
  "build-tools;36.0.0"
  "ndk;28.2.13676358"
)
missing=()
for package in "${packages[@]}"; do
  case "$package" in
    "platforms;android-36") path="platforms/android-36" ;;
    "build-tools;36.0.0") path="build-tools/36.0.0" ;;
    "ndk;28.2.13676358") path="ndk/28.2.13676358" ;;
  esac
  if [[ ! -d "$sdk_root/$path" ]]; then
    missing+=("$package")
  fi
done

if ((${#missing[@]})); then
  echo "Installing required Android SDK packages."
  yes | "$sdkmanager" --licenses >/dev/null
  "$sdkmanager" "${missing[@]}"
fi

for package in "${packages[@]}"; do
  case "$package" in
    "platforms;android-36") path="platforms/android-36" ;;
    "build-tools;36.0.0") path="build-tools/36.0.0" ;;
    "ndk;28.2.13676358") path="ndk/28.2.13676358" ;;
  esac
  if [[ ! -d "$sdk_root/$path" ]]; then
    echo "Required Android SDK package is still unavailable: $package" >&2
    exit 1
  fi
done
