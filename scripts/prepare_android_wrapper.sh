#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
cd "$repo_root"

wrapper_jar="android/gradle/wrapper/gradle-wrapper.jar"
wrapper_properties="android/gradle/wrapper/gradle-wrapper.properties"
wrapper_script="android/gradlew"

missing=()
for file in "$wrapper_jar" "$wrapper_properties" "$wrapper_script"; do
  if [[ ! -s "$file" ]]; then
    missing+=("$file")
  fi
done

if ((${#missing[@]})); then
  printf 'Gradle wrapper files are missing or empty from repository root %s:\n' "$repo_root" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  if git -C "$repo_root" rev-parse --short HEAD >/dev/null 2>&1; then
    printf 'Checked out commit: %s\n' "$(git -C "$repo_root" rev-parse --short HEAD)" >&2
  fi
  exit 1
fi

chmod +x "$wrapper_script"
printf 'Verified Gradle wrapper files in %s.\n' "$repo_root"
