#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or is not on PATH." >&2
  echo "Install Flutter 3.47.0 or newer, then retry." >&2
  exit 1
fi

echo "=== Flutter version ==="
flutter --version

echo "=== Flutter doctor ==="
flutter doctor -v || echo "Flutter doctor reported optional environment issues; continuing with package checks."

echo "=== Clean old build output ==="
flutter clean

echo "=== Download dependencies ==="
flutter pub get

echo "=== Analyze source ==="
flutter analyze

echo "=== Run tests ==="
flutter test

echo
echo "Project dependency setup and source checks completed."
echo "Build APK manually with: flutter build apk --release"
