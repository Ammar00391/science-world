#!/usr/bin/env python3
"""Validate project structure, bundled data, Flutter assets, and Android CI wiring."""

from __future__ import annotations

import json
import argparse
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []
CHECKS = 0


def fail(message: str) -> None:
    ERRORS.append(message)


def require(condition: bool, message: str) -> None:
    global CHECKS
    CHECKS += 1
    if not condition:
        fail(message)


def read_text(relative_path: str) -> str:
    path = ROOT / relative_path
    if not path.is_file():
        fail(f"Required file is missing: {relative_path}")
        return ""
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError):
        fail(f"Required file cannot be read as UTF-8: {relative_path}")
        return ""


def load_json(path: Path) -> object | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        fail(f"Invalid or unreadable JSON: {path.relative_to(ROOT)}")
        return None


def check_json_files(production: bool) -> None:
    excluded = {".git", ".dart_tool", "build", "node_modules"}
    files = [
        path
        for path in ROOT.rglob("*.json")
        if not any(part in excluded for part in path.relative_to(ROOT).parts)
    ]
    require(bool(files), "No project JSON data files were found.")
    for path in files:
        load_json(path)

    curriculum_path = ROOT / "assets/data/curriculum_catalog_2027.json"
    curriculum = load_json(curriculum_path)
    if isinstance(curriculum, dict):
        subjects = curriculum.get("subjects")
        order = curriculum.get("subject_order")
        require(isinstance(subjects, list) and len(subjects) == 9,
                "Curriculum catalog must contain exactly nine subjects.")
        require(isinstance(order, list) and len(order) == 9,
                "Curriculum subject order must contain exactly nine entries.")
        if isinstance(subjects, list):
            required_stages = {"summary", "worked_example", "common_mistakes", "practice"}
            for subject in subjects:
                require(isinstance(subject, dict), "Curriculum subject entry must be an object.")
                if not isinstance(subject, dict):
                    continue
                units = subject.get("units")
                require(isinstance(units, list) and bool(units),
                        "Every curriculum subject must contain units.")
                for unit in units if isinstance(units, list) else []:
                    require(isinstance(unit, dict), "Curriculum unit entry must be an object.")
                    if not isinstance(unit, dict):
                        continue
                    lessons = unit.get("lessons")
                    require(isinstance(lessons, list) and bool(lessons),
                            "Every curriculum unit must contain lessons.")
                    for lesson in lessons if isinstance(lessons, list) else []:
                        require(isinstance(lesson, dict), "Curriculum lesson entry must be an object.")
                        if isinstance(lesson, dict):
                            components = lesson.get("learning_components")
                            require(
                                isinstance(components, dict)
                                and required_stages.issubset(components),
                                "Every curriculum lesson must expose all four learning stages.",
                            )

    bank = load_json(ROOT / "assets/data/question_bank_ar.json")
    if isinstance(bank, dict):
        questions = bank.get("questions")
        require(isinstance(questions, list), "Student question bank must contain a questions list.")
        if isinstance(questions, list):
            require(
                all(
                    isinstance(question, dict)
                    and question.get("review_status") in {"approved", "published"}
                    for question in questions
                ),
                "Student question bank contains an unreviewed question.",
            )
            require(
                bank.get("question_count") == len(questions),
                "Student question bank question_count does not match its data.",
            )

    manifest_path = ROOT / "content_seed/source_books/manifest.json"
    manifest = load_json(manifest_path)
    if isinstance(manifest, dict):
        books = manifest.get("books")
        require(isinstance(books, list), "Source-books manifest must contain a books list.")
        if isinstance(books, list):
            require(manifest.get("pdf_count") == len(books),
                    "Source-books manifest pdf_count does not match its entries.")
            for book in books:
                require(isinstance(book, dict), "Source-books manifest entry must be an object.")
                if not isinstance(book, dict):
                    continue
                relative_pdf = book.get("file")
                if not isinstance(relative_pdf, str) or not relative_pdf:
                    fail("Source-books manifest entry is missing its file path.")
                    continue
                pdf_path = ROOT / "content_seed/source_books" / relative_pdf
                require(pdf_path.is_file(), "A PDF listed in the source-books manifest is missing.")
                if pdf_path.is_file():
                    require(pdf_path.stat().st_size == book.get("size_bytes"),
                            "A source PDF size does not match its manifest.")
                    try:
                        with pdf_path.open("rb") as source_pdf:
                            is_pdf = source_pdf.read(5) == b"%PDF-"
                    except OSError:
                        is_pdf = False
                    require(is_pdf, "A source-books manifest file is not a PDF.")
    if production and isinstance(bank, dict) and isinstance(bank.get("questions"), list):
        require(
            bool(bank["questions"]),
            "Production content validation requires at least one approved offline question.",
        )


def check_declared_flutter_assets(pubspec: str) -> None:
    lines = pubspec.splitlines()
    asset_lines: list[str] = []
    in_assets = False
    for line in lines:
        if re.match(r"^  assets:\s*$", line):
            in_assets = True
            continue
        if in_assets and line and not line.startswith("    - "):
            break
        if in_assets:
            match = re.match(r"^    - (.+?)\s*$", line)
            if match:
                asset_lines.append(match.group(1).strip("\"'"))
    require(bool(asset_lines), "No Flutter assets are declared in pubspec.yaml.")
    for declared in asset_lines:
        asset_path = ROOT / declared
        require(asset_path.exists(), f"A Flutter-declared asset path is missing: {declared}")
        if asset_path.is_dir():
            require(any(asset_path.iterdir()), f"A Flutter-declared asset directory is empty: {declared}")


def check_dart_relative_imports() -> None:
    import_pattern = re.compile(
        r"""^\s*(?:import|export|part)\s+['"]([^'"]+)['"]""",
        re.MULTILINE,
    )
    dart_files = list((ROOT / "lib").rglob("*.dart")) + list((ROOT / "test").rglob("*.dart"))
    require(bool(dart_files), "No Dart source or test files were found.")
    for source in dart_files:
        try:
            text = source.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            fail(f"Dart source cannot be read: {source.relative_to(ROOT)}")
            continue
        for uri in import_pattern.findall(text):
            if uri.startswith((".", "..")):
                target = (source.parent / uri).resolve()
                require(
                    target.is_file(),
                    f"A relative Dart import/part target is missing in {source.relative_to(ROOT)}.",
                )


def check_android_and_workflow(pubspec: str) -> None:
    version_match = re.search(r"(?m)^version:\s*['\"]?(\d+\.\d+\.\d+)\+(\d+)['\"]?\s*$", pubspec)
    require(version_match is not None, "pubspec.yaml must define versionName+versionCode.")
    if version_match:
        version_name, version_code = version_match.groups()
        app_gradle = read_text("android/app/build.gradle")
        require(
            f"flutterVersionCode = localProperties.getProperty('flutter.versionCode') ?: '{version_code}'"
            in app_gradle,
            "Android fallback versionCode must match pubspec.yaml.",
        )
        require(
            f"flutterVersionName = localProperties.getProperty('flutter.versionName') ?: '{version_name}'"
            in app_gradle,
            "Android fallback versionName must match pubspec.yaml.",
        )
    else:
        app_gradle = read_text("android/app/build.gradle")

    require(
        "applicationId \"com.scienceworld.science_world\"" in app_gradle,
        "Android applicationId does not match the Science World package.",
    )
    require("compileSdk 36" in app_gradle, "Android compileSdk must be 36.")
    require("targetSdk 36" in app_gradle, "Android targetSdk must be 36.")
    require('ndkVersion "28.2.13676358"' in app_gradle, "Android NDK version is unexpected.")
    require("CM_KEYSTORE_PATH" in app_gradle and "CM_KEY_PASSWORD" in app_gradle,
            "Release signing must use Codemagic-provided keystore credentials.")
    require("Debug signing is never used for Release." in app_gradle,
            "Gradle must explicitly reject Release builds without the owner keystore.")
    build_types_start = app_gradle.find("buildTypes {")
    release_start = app_gradle.find("release {", build_types_start)
    release_end = app_gradle.find("minifyEnabled", release_start)
    release_block = (
        app_gradle[release_start:release_end]
        if build_types_start >= 0 and release_start >= 0 and release_end >= 0
        else ""
    )
    require(
        bool(release_block) and "signingConfigs.debug" not in release_block,
        "Release build type must never select the Debug signing configuration.",
    )

    workflow = read_text("codemagic.yaml")
    require(
        re.search(r"(?m)^\s*-\s*science_world_upload_keystore\s*$", workflow) is not None,
        "Codemagic must use the science_world_upload_keystore signing identity.",
    )
    require("flutter build apk --release" in workflow,
            "Codemagic workflow must build a Release APK.")
    require("flutter build appbundle --release" in workflow,
            "Codemagic workflow must build a Release App Bundle.")
    require("scripts/verify_release_artifacts.sh" in workflow,
            "Codemagic must verify signatures of Release artifacts.")

    script_pattern = re.compile(
        r"(?m)^\s*(?:bash|python3|node\s+--check)\s+(scripts/[^\s\\]+|supabase/[^\s\\]+)"
    )
    referenced_scripts = script_pattern.findall(workflow)
    require(bool(referenced_scripts), "No validation/build scripts were found in Codemagic.")
    for relative_path in referenced_scripts:
        require((ROOT / relative_path).is_file(),
                f"Codemagic references a missing script: {relative_path}")

    manifest = read_text("android/app/src/main/AndroidManifest.xml")
    require('android:usesCleartextTraffic="false"' in manifest,
            "Android must keep cleartext traffic disabled.")
    permission_names = re.findall(r"<uses-permission\b[^>]*android:name=\"([^\"]+)\"", manifest)
    require("android.permission.INTERNET" in permission_names,
            "Android manifest must retain the INTERNET permission.")
    require(
        all(
            permission in {"android.permission.INTERNET", "android.permission.VIBRATE"}
            for permission in permission_names
        ),
        "Android manifest contains an unexpected permission; review it before release.",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--production",
        action="store_true",
        help="require at least one approved offline question in the student bundle",
    )
    args = parser.parse_args()

    pubspec = read_text("pubspec.yaml")
    read_text("pubspec.lock")
    check_declared_flutter_assets(pubspec)
    check_json_files(args.production)
    check_dart_relative_imports()
    check_android_and_workflow(pubspec)

    if ERRORS:
        for error in ERRORS:
            print(f"ERROR: {error}", file=sys.stderr)
        print(f"Project validation failed: {len(ERRORS)} issue(s), {CHECKS} checks.", file=sys.stderr)
        return 1

    print(f"Project validation passed: {CHECKS} checks; bundled data and CI configuration are consistent.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
