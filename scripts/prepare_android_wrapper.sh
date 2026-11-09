#!/usr/bin/env bash
set -euo pipefail

wrapper_jar="android/gradle/wrapper/gradle-wrapper.jar"
wrapper_properties="android/gradle/wrapper/gradle-wrapper.properties"
wrapper_script="android/gradlew"

if [[ ! -s "$wrapper_jar" || ! -s "$wrapper_properties" || ! -s "$wrapper_script" ]]; then
  echo "Android Gradle wrapper files are missing. Commit gradlew and the files under android/gradle/wrapper/." >&2
  exit 1
fi

chmod +x "$wrapper_script"
