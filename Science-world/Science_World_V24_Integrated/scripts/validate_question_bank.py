#!/usr/bin/env python3
"""Validate Science World question-bank JSON before teacher approval/publication.

Examples:
  python scripts/validate_question_bank.py content_seed/question_banks/arabic_unit1_lesson1_free_draft.json
  python scripts/validate_question_bank.py path/to/bank.json --release

The validator never approves a question. It reports structural quality only.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

ALLOWED_TYPES = {
    "mcq", "single_choice", "true_false", "fill_blank", "short_answer",
    "ordering", "matching", "drag_drop", "multi_select", "calculation",
    "numeric", "calculation_steps", "diagram_label", "label_diagram",
    "explain", "compare", "short_text", "long_answer", "classify",
    "error_correction", "reasoning",
}
APPROVED_STATES = {"approved", "published"}
VALID_STATES = {"draft", "draft_needs_teacher_review", "needs_review", "approved", "published", "rejected"}


def normalize(text: str) -> str:
    value = unicodedata.normalize("NFKC", text or "").casefold()
    value = "".join(ch for ch in value if unicodedata.category(ch) != "Mn")
    value = re.sub(r"[\s\u0640:،؛,.!?؟()\[\]{}\-–—_]+", "", value)
    return value


def load(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("Top-level JSON must be an object")
    return data


def validate(path: Path, release: bool) -> tuple[list[str], list[str], dict[str, Any]]:
    errors: list[str] = []
    warnings: list[str] = []
    data = load(path)
    questions = data.get("questions")
    if not isinstance(questions, list):
        return ["questions must be an array"], warnings, data
    if data.get("question_count") != len(questions):
        errors.append(f"question_count={data.get('question_count')} but actual={len(questions)}")

    seen_ids: set[str] = set()
    seen_text: dict[str, str] = {}
    grouped: dict[tuple[str, str, str], list[dict[str, Any]]] = defaultdict(list)
    for index, item in enumerate(questions, 1):
        prefix = f"question[{index}]"
        if not isinstance(item, dict):
            errors.append(f"{prefix}: must be an object")
            continue
        qid = str(item.get("id", "")).strip()
        if not qid:
            errors.append(f"{prefix}: missing id")
        elif qid in seen_ids:
            errors.append(f"{prefix}: duplicate id {qid}")
        seen_ids.add(qid)

        for field in ("question_text", "correct_answer", "solution", "explanation", "grade", "subject", "chapter", "lesson", "school_year", "source_title", "source_url", "source_pages", "source_edition"):
            if not str(item.get(field, "")).strip():
                errors.append(f"{prefix}: missing {field}")

        if item.get("type") not in ALLOWED_TYPES:
            errors.append(f"{prefix}: unsupported type {item.get('type')!r}")
        if item.get("review_status") not in VALID_STATES:
            errors.append(f"{prefix}: invalid review_status {item.get('review_status')!r}")
        elif release and item.get("review_status") not in APPROVED_STATES:
            errors.append(f"{prefix}: release blocked; review_status is not approved/published")
        elif item.get("review_status") not in APPROVED_STATES:
            warnings.append(f"{prefix}: still a draft and must not be visible to students")

        if not isinstance(item.get("is_paid"), bool):
            errors.append(f"{prefix}: is_paid must be boolean")
        if item.get("type") in {"mcq", "single_choice"}:
            options = item.get("options")
            if not isinstance(options, list) or len(options) < 2:
                errors.append(f"{prefix}: MCQ needs at least two options")
            else:
                normalized_options = [normalize(str(x)) for x in options]
                if len(normalized_options) != len(set(normalized_options)):
                    errors.append(f"{prefix}: duplicate options")
                if normalize(str(item.get("correct_answer", ""))) not in normalized_options:
                    errors.append(f"{prefix}: correct_answer must exactly match one option")
        if item.get("type") == "true_false" and normalize(str(item.get("correct_answer", ""))) not in {"صح", "خطأ", "صحيح", "خاطئ", "true", "false"}:
            errors.append(f"{prefix}: true_false answer must be صح/خطأ or true/false")
        source_url = str(item.get("source_url", "")).strip()
        if source_url and not source_url.startswith("https://"):
            warnings.append(f"{prefix}: source_url is not HTTPS; verify the source")

        normalized_question = normalize(str(item.get("question_text", "")))
        if normalized_question:
            if normalized_question in seen_text:
                errors.append(f"{prefix}: duplicate question text already used by {seen_text[normalized_question]}")
            else:
                seen_text[normalized_question] = qid or prefix

        group = (
            str(item.get("subject", "")),
            str(item.get("chapter", "")),
            str(item.get("lesson", "")),
        )
        grouped[group].append(item)

    for (subject, chapter, lesson), items in grouped.items():
        total = len(items)
        free = sum(1 for x in items if x.get("is_paid") is False)
        paid = total - free
        target = int(data.get("target_total_per_lesson", 32) or 32)
        if total < target:
            warnings.append(f"{subject} / {lesson}: {total}/{target} questions only; do not fill the gap with repeated or unverified items")
        if total >= target and free != 6:
            errors.append(f"{subject} / {lesson}: expected 6 free questions when target is reached; found {free}")
        if total >= target and paid < 26:
            errors.append(f"{subject} / {lesson}: expected at least 26 premium questions at 32 total; found {paid}")

    if not questions:
        warnings.append("No question records are present; this is valid for an empty student bundle but not a publishable bank.")
    return errors, warnings, data


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bank", type=Path, help="Question-bank JSON to validate")
    parser.add_argument("--release", action="store_true", help="Fail if any item is not approved/published")
    args = parser.parse_args()

    try:
        errors, warnings, data = validate(args.bank, args.release)
    except Exception as exc:  # malformed JSON / missing file
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    print(f"Bank: {args.bank}")
    print(f"Questions: {len(data.get('questions', []))}")
    print(f"Status: {data.get('status', 'not set')}")
    for warning in warnings:
        print(f"WARNING: {warning}")
    for error in errors:
        print(f"ERROR: {error}")
    if errors:
        print(f"FAILED: {len(errors)} error(s), {len(warnings)} warning(s)")
        return 1
    print(f"STRUCTURE OK: {len(warnings)} warning(s). This tool does not replace teacher review.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
