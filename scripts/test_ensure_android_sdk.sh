#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

sdk_root="$test_root/sdk"
sdkmanager="$sdk_root/cmdline-tools/latest/bin/sdkmanager"
mkdir -p "$(dirname "$sdkmanager")"

cat > "$sdkmanager" <<'SDKMANAGER'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--licenses" ]]; then
  IFS= read -r answer
  [[ "$answer" == "y" ]] || exit 3
  exit "${FAKE_LICENSE_STATUS:-0}"
fi

for package in "$@"; do
  case "$package" in
    "platforms;android-36") path="platforms/android-36" ;;
    "build-tools;36.0.0") path="build-tools/36.0.0" ;;
    "ndk;28.2.13676358") path="ndk/28.2.13676358" ;;
    *) exit 4 ;;
  esac
  mkdir -p "$FAKE_ANDROID_SDK_ROOT/$path"
done
SDKMANAGER
chmod +x "$sdkmanager"

FAKE_ANDROID_SDK_ROOT="$sdk_root" \
  ANDROID_SDK_ROOT="$sdk_root" \
  bash "$repo_root/scripts/ensure_android_sdk.sh"

for path in \
  "platforms/android-36" \
  "build-tools/36.0.0" \
  "ndk/28.2.13676358"; do
  [[ -d "$sdk_root/$path" ]] || {
    printf 'Expected SDK package was not installed: %s\n' "$path" >&2
    exit 1
  }
done

rm -rf "$sdk_root/platforms/android-36"
if FAKE_ANDROID_SDK_ROOT="$sdk_root" \
  ANDROID_SDK_ROOT="$sdk_root" \
  FAKE_LICENSE_STATUS=7 \
  bash "$repo_root/scripts/ensure_android_sdk.sh" >/dev/null 2>&1; then
  echo "SDK preparation unexpectedly succeeded when license acceptance failed." >&2
  exit 1
fi

echo "Android SDK preparation handles early license-prompt exit and license errors."
