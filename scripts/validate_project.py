#!/usr/bin/env python3
"""Fast source/data preflight for Science World. Does not replace Flutter tests."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001 - report malformed project data
        fail(f"Invalid JSON {path.relative_to(ROOT)}: {exc}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--production", action="store_true", help="Require at least one approved offline question")
    args = parser.parse_args()

    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    version = re.search(r"(?m)^version:\s*([^\s]+)", pubspec)
    if not version or version.group(1) != "2.2.3+25":
        fail("pubspec version must be 2.2.3+25 for V25")

    assets = re.findall(r"(?m)^\s+-\s+(assets/[^\s]+)\s*$", pubspec)
    missing_assets = [asset for asset in assets if not (ROOT / asset).exists()]
    if missing_assets:
        fail("Missing pubspec assets: " + ", ".join(missing_assets))

    catalog = load_json(ROOT / "assets/data/curriculum_catalog_2027.json")
    subjects = catalog.get("subjects", [])
    lesson_count = sum(
        len(unit.get("lessons", []))
        for subject in subjects
        for unit in subject.get("units", [])
    )
    if len(subjects) != 9 or lesson_count != 237:
        fail(f"Unexpected curriculum dimensions: subjects={len(subjects)}, lessons={lesson_count}")

    question_policy = load_json(ROOT / "assets/data/question_bank_policy.json")
    tier_access = question_policy.get("tier_access", {})
    if question_policy.get("default_target_per_lesson") != 40 or question_policy.get("free_per_lesson") != 6 or question_policy.get("premium_per_lesson") != 34 or question_policy.get("silver_paid_per_lesson") != 9 or question_policy.get("silver_total_per_lesson") != 15:
        fail("Question bank policy must be 40 target / 6 free / 34 paid / Silver 15 total")
    if tier_access.get("silver", {}).get("paid_per_lesson") != 9 or tier_access.get("silver", {}).get("total_per_lesson") != 15 or tier_access.get("free", {}).get("paid_per_lesson") != 0:
        fail("Question tier access limits do not match the V25 Silver/Free policy")

    bank = load_json(ROOT / "assets/data/question_bank_ar.json")
    questions = bank.get("questions", [])
    bad = [q.get("id", "?") for q in questions if q.get("review_status") not in {"approved", "published"}]
    if bad:
        fail(f"Unreviewed questions included in student assets: {bad[:10]}")
    if args.production and not questions:
        fail("Production release blocked: there are no approved offline questions yet")

    # Check that every relative import points to a file in the project.
    missing_imports: list[str] = []
    for source in (ROOT / "lib").rglob("*.dart"):
        text = source.read_text(encoding="utf-8")
        for target in re.findall(r"import\s+'([^']+)'", text):
            if target.startswith(("dart:", "package:")):
                continue
            if not (source.parent / target).resolve().exists():
                missing_imports.append(f"{source.relative_to(ROOT)} -> {target}")
    if missing_imports:
        fail("Broken relative imports: " + "; ".join(missing_imports))

    app_gradle = (ROOT / "android/app/build.gradle").read_text(encoding="utf-8")
    if not re.search(r"targetSdk\s+36\b", app_gradle):
        fail("Android targetSdk must be 36")
    if "verifyReleaseSigning" not in app_gradle or "ALLOW_DEBUG_SIGNED_RELEASE" not in app_gradle:
        fail("Release signing gate is missing")

    supabase_config = (ROOT / "lib/core/config/supabase_config.dart").read_text(encoding="utf-8")
    if "isInitialized" not in supabase_config or "_initialized = true" not in supabase_config:
        fail("Supabase initialization state guard is missing")
    activation_schema = (ROOT / "supabase/schema.sql").read_text(encoding="utf-8")
    activation_migration = (ROOT / "supabase/migrations/20261106_v22_subscription_duration_config.sql").read_text(encoding="utf-8")
    if "v_duration_days is null" not in activation_schema:
        fail("Subscription activation must reject missing duration values")
    if "add column if not exists duration_days integer not null default 30" in activation_migration.lower():
        fail("Migration must not assign an unapproved default subscription period")

    workflow = (ROOT / ".github/workflows/android.yml").read_text(encoding="utf-8")
    if "flutter.sdk=%s" not in workflow or "sdk.dir=%s" not in workflow:
        fail("GitHub Actions must set Android local.properties before Gradle starts")

    ai_function = (ROOT / "supabase/functions/ai-chat/index.js").read_text(encoding="utf-8")
    for required_fragment in [
        "auth/v1/user",
        "/rest/v1/subscriptions",
        'subscription?.status !== "premium"',
        'String(subscription?.tier).toLowerCase() !== "gold"',
        'subscriptionsUrl.searchParams.set("select", "tier,status,starts_at,expires_at")',
        "subscription.starts_at",
        "const allowedSubjects = new Set([",
        "المادة التي اختارها الطالب",
        "const userMessage = trimmedContext",
        "content: userMessage",
    ]:
        if required_fragment not in ai_function:
            fail(f"AI Edge Function is missing required security/context check: {required_fragment}")

    entitlement_migration = ROOT / "supabase/migrations/20261107_v24_a1_question_entitlements.sql"
    if not entitlement_migration.exists():
        fail("A1 question entitlement migration is missing")
    entitlement_sql = entitlement_migration.read_text(encoding="utf-8")
    for required_fragment in [
        "_science_world_can_access_question",
        "q.lesson_position <= 6",
        "q.lesson_position <= 2",
        "s.starts_at is null or s.starts_at <= now()",
        "get_questions",
        "get_question_by_id",
        "check_question_answer",
    ]:
        if required_fragment not in entitlement_sql:
            fail(f"A1 SQL entitlement migration is missing rule: {required_fragment}")
    if entitlement_sql.strip() not in activation_schema:
        fail("supabase/schema.sql must include the A1 entitlement migration for fresh installs")

    quota_migration = ROOT / "supabase/migrations/20261107_v25_question_quota_40_silver15.sql"
    if not quota_migration.exists():
        fail("V25 question quota migration is missing")
    quota_sql = quota_migration.read_text(encoding="utf-8")
    for required_fragment in ["q.lesson_position <= 6", "q.lesson_position <= 9", "t.tier = 'gold'", "get_questions"]:
        if required_fragment not in quota_sql:
            fail(f"V25 quota migration is missing rule: {required_fragment}")

    subscription_model = (ROOT / "lib/features/subscription/data/subscription_model.dart").read_text(encoding="utf-8")
    if "startsAt == null || !startsAt!.isAfter(now)" not in subscription_model:
        fail("Client subscription model must enforce starts_at")

    if not (ROOT / "A1_MASTER_SCOPE_AR.md").exists():
        fail("A1 master scope document is missing")

    auth_pages = [
        "signup_page.dart", "login_page.dart", "verify_page.dart",
        "reset_page.dart", "update_password_page.dart",
    ]
    for page in auth_pages:
        page_path = ROOT / "lib/features/auth/presentation" / page
        if "auth_mascot.dart" not in page_path.read_text(encoding="utf-8"):
            fail(f"A1 animated authentication mascot is missing from {page}")
    mascot_refs = list((ROOT / "lib").rglob("*.dart"))
    for source in mascot_refs:
        if "AuthMascot(" in source.read_text(encoding="utf-8") and source.parent != (ROOT / "lib/features/auth/presentation"):
            fail(f"Authentication mascot must not appear inside the signed-in app: {source.relative_to(ROOT)}")
    if "SUPABASE_SERVICE_ROLE_KEY" in ai_function or "service_role" in ai_function:
        fail("AI Edge Function must not embed or request a service-role key")

    manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
    if '@mipmap/ic_launcher' not in manifest:
        fail("Custom Android launcher icon is not configured")
    for icon in [
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
        "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml",
    ]:
        if not (ROOT / icon).exists():
            fail(f"Missing launcher icon asset: {icon}")

    print("PASS: project JSON assets and question access policy parse correctly")
    print(f"PASS: curriculum structure is {len(subjects)} subjects / {lesson_count} lessons")
    print(f"PASS: student question asset contains {len(questions)} reviewed questions and no drafts")
    if not questions:
        print("WARNING: no approved question is packaged; do not advertise offline practice as content-complete")
    print("PASS: all relative Dart imports resolve")
    print("PASS: Android target API 36 and custom launcher icons are configured")
    print("PASS: release signing requires a keystore or explicit preview-only debug signing")
    print("PASS: Supabase initialization and subscription-duration safety guards are present")
    print("PASS: GitHub Actions writes Flutter/Android SDK paths before Gradle")
    print("PASS: subject-aware AI Edge Function validates user, subscription start/expiry and Gold entitlement")
    print("PASS: V25 question policy: 40 target / 6 free / 34 paid / Silver 15 total (9 paid) / Gold all published")
    print("PASS: Animated mascot is referenced only by authentication/password pages")
    print("NOTE: Flutter analyze, Flutter tests, device tests and Supabase integration tests still need a real Flutter/Android environment.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
