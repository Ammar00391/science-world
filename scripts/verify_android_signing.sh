#!/usr/bin/env bash
set -euo pipefail

missing=()
[[ -n "${CM_KEYSTORE_PATH:-}" ]] || missing+=("CM_KEYSTORE_PATH")
[[ -n "${CM_KEYSTORE_PASSWORD:-}" ]] || missing+=("CM_KEYSTORE_PASSWORD")
[[ -n "${CM_KEY_ALIAS:-}" ]] || missing+=("CM_KEY_ALIAS")
[[ -n "${CM_KEY_PASSWORD:-}" ]] || missing+=("CM_KEY_PASSWORD")

if ((${#missing[@]})); then
  printf 'Missing Codemagic Android signing values: %s\n' "${missing[*]}" >&2
  exit 1
fi

if [[ ! -f "$CM_KEYSTORE_PATH" || ! -r "$CM_KEYSTORE_PATH" ]]; then
  echo "CM_KEYSTORE_PATH must reference a readable Android keystore file." >&2
  exit 1
fi

echo "Codemagic Release signing identity is available."
