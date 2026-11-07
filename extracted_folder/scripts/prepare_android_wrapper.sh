#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"

if [[ -x "$ANDROID_DIR/gradlew" && -f "$ANDROID_DIR/gradle/wrapper/gradle-wrapper.jar" ]]; then
  echo "Android Gradle Wrapper already exists."
  exit 0
fi

command -v flutter >/dev/null 2>&1 || {
  echo "ERROR: Flutter SDK is required to generate the missing Gradle wrapper." >&2
  exit 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Generate a clean Android wrapper in a temporary Flutter project, then copy
# only the wrapper launchers/JAR. Existing Science World Android files stay intact.
flutter create \
  --no-pub \
  --platforms=android \
  --project-name=science_world \
  --org=com.scienceworld \
  "$TMP_DIR/science_world"

mkdir -p "$ANDROID_DIR/gradle/wrapper"
cp "$TMP_DIR/science_world/android/gradlew" "$ANDROID_DIR/gradlew"
cp "$TMP_DIR/science_world/android/gradlew.bat" "$ANDROID_DIR/gradlew.bat"
cp "$TMP_DIR/science_world/android/gradle/wrapper/gradle-wrapper.jar" \
  "$ANDROID_DIR/gradle/wrapper/gradle-wrapper.jar"
chmod +x "$ANDROID_DIR/gradlew"

echo "Generated missing Gradle wrapper without replacing the project's Gradle configuration."
