#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash scripts/prepare_android_wrapper.sh
python3 scripts/validate_project.py --production
flutter pub get
flutter analyze
flutter test --reporter expanded
bash scripts/prepare_release_signing.sh
flutter build apk --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-https://faiituujosrsthdrsefw.supabase.co}" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY:-sb_publishable_oxs3N5EAiq7zfMH7_gPbgg_F3i6oerr}"
