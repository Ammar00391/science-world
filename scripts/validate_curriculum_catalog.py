#!/usr/bin/env python3
"""Validate the Science World curriculum catalog structure; does not certify edition accuracy."""
from __future__ import annotations
import json
import sys
from pathlib import Path

EXPECTED_SUBJECTS = [
    "اللغة العربية وآدابها",
    "علم الأحياء والأرض",
    "التربية الإسلامية",
    "الرياضيات – الجزء الأول",
    "الرياضيات – الجزء الثاني",
    "الكيمياء",
    "الفيزياء",
    "اللغة الإنجليزية – كتاب الطالب",
    "اللغة الفرنسية",
]
REQUIRED_STAGES = {"summary", "worked_example", "common_mistakes", "practice"}


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("assets/data/curriculum_catalog_2027.json")
    try:
        catalog = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"ERROR: cannot read catalog: {exc}")
        return 2
    errors: list[str] = []
    subjects = catalog.get("subjects")
    if not isinstance(subjects, list):
        print("ERROR: subjects must be an array")
        return 2
    actual = [str(subject.get("name", "")) for subject in subjects if isinstance(subject, dict)]
    if actual != EXPECTED_SUBJECTS:
        errors.append("subject list does not match the requested nine-subject order")
    lessons_count = 0
    unit_count = 0
    for subject in subjects:
        if not isinstance(subject, dict):
            errors.append("subject entry is not an object")
            continue
        units = subject.get("units")
        if not isinstance(units, list) or not units:
            errors.append(f"{subject.get('name')}: no units")
            continue
        for unit in units:
            unit_count += 1
            lessons = unit.get("lessons") if isinstance(unit, dict) else None
            if not isinstance(lessons, list) or not lessons:
                errors.append(f"{subject.get('name')} / {unit.get('name') if isinstance(unit, dict) else '?'}: no lessons")
                continue
            for lesson in lessons:
                lessons_count += 1
                if not isinstance(lesson, dict) or not str(lesson.get("name", "")).strip():
                    errors.append(f"{subject.get('name')} / {unit.get('name')}: lesson name missing")
                    continue
                stages = lesson.get("learning_components")
                if not isinstance(stages, dict) or not REQUIRED_STAGES.issubset(stages):
                    errors.append(f"{subject.get('name')} / {unit.get('name')} / {lesson.get('name')}: learning stages missing")
    print(f"Subjects: {len(subjects)} | Units: {unit_count} | Lessons: {lessons_count}")
    print(f"School year metadata: {catalog.get('school_year')} | Status: {catalog.get('status')}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        print(f"FAILED: {len(errors)} error(s)")
        return 1
    print("STRUCTURE OK. This validates data shape only; it does not certify textbook edition or lesson accuracy.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
