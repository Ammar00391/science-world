#!/usr/bin/env python3
import argparse
import json
import re
import sys
import unicodedata
from difflib import SequenceMatcher
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "content_seed/source_books/manifest.json"


def fail(message: str) -> None:
    raise ValueError(message)


def normalized(value: str) -> str:
    value = unicodedata.normalize("NFKC", value).casefold()
    value = "".join(
        char for char in value
        if unicodedata.category(char) not in {"Mn", "Cf"}
    )
    return re.sub(r"[^\w]+", "", value)


def normalized_option(value: str) -> str:
    value = unicodedata.normalize("NFKC", value).casefold().replace("−", "-")
    value = "".join(
        char for char in value
        if unicodedata.category(char) not in {"Mn", "Cf"}
    )
    return re.sub(r"[^\w.+-]+", "", value)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate source citations and quality gates in a question draft."
    )
    parser.add_argument("draft", type=Path)
    args = parser.parse_args()
    draft_path = args.draft if args.draft.is_absolute() else ROOT / args.draft

    try:
        draft = json.loads(draft_path.read_text(encoding="utf-8"))
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        expected = draft["target_total_per_lesson"]
        questions = draft["questions"]
        source_file = draft["source"]["file"]
        books = {book["file"]: book for book in manifest["books"]}

        if source_file not in books:
            fail(f"Source PDF is not registered in the source-books manifest: {source_file}")
        if len(questions) != expected:
            fail(f"Expected {expected} questions, found {len(questions)}.")

        stems: list[str] = []
        seen_ids: set[str] = set()
        free_count = 0
        answer_positions: dict[int, list[int]] = {}
        for index, question in enumerate(questions, start=1):
            label = f"question {index}"
            question_id = question.get("id")
            if not question_id or question_id in seen_ids:
                fail(f"{label} has a missing or duplicate id.")
            seen_ids.add(question_id)

            stem = normalized(question.get("question_text", ""))
            if len(stem) < 8:
                fail(f"{label} has an empty or too-short question.")
            stems.append(stem)
            if not question.get("correct_answer", "").strip():
                fail(f"{label} has no model answer.")
            if not question.get("solution", "").strip():
                fail(f"{label} has no solution.")
            if question.get("review_status") != "draft_needs_teacher_review":
                fail(f"{label} must remain a teacher-review draft.")
            if question.get("is_paid") is False:
                free_count += 1

            page_value = question.get("source_pdf_page")
            pages = page_value if isinstance(page_value, list) else [page_value]
            if not pages or any(not isinstance(page, int) for page in pages):
                fail(f"{label} must cite one or more integer PDF page numbers.")
            if any(page < 1 or page > books[source_file]["page_count"] for page in pages):
                fail(f"{label} cites a PDF page outside the source book.")

            if question.get("type") == "mcq":
                options = question.get("options")
                if not isinstance(options, list) or len(options) < 2:
                    fail(f"{label} must have at least two answer options.")
                option_keys = [normalized_option(option) for option in options]
                if len(set(option_keys)) != len(option_keys):
                    fail(f"{label} repeats an answer option.")
                if sum(
                    normalized_option(option) == normalized_option(question["correct_answer"])
                    for option in options
                ) != 1:
                    fail(f"{label} must have exactly one correct option.")
                position_counts = answer_positions.setdefault(len(options), [0] * len(options))
                correct_position = next(
                    position
                    for position, option in enumerate(options)
                    if normalized_option(option) == normalized_option(question["correct_answer"])
                )
                position_counts[correct_position] += 1

        if free_count != draft["free_count"]:
            fail(f"Expected {draft['free_count']} free questions; found {free_count}.")
        for option_count, position_counts in answer_positions.items():
            total = sum(position_counts)
            allowed_spread = max(2, (total + 2 * option_count - 1) // (2 * option_count))
            if total >= 12 and max(position_counts) - min(position_counts) > allowed_spread:
                fail(
                    f"Correct-option positions are too imbalanced for {option_count}-option "
                    f"questions: {position_counts}."
                )
        for index, stem in enumerate(stems):
            for other in stems[index + 1:]:
                if SequenceMatcher(None, stem, other).ratio() >= 0.78:
                    fail(f"Two question stems are too similar: {stem} / {other}")

        print(
            f"PASS: {len(questions)} draft questions; {free_count} free; "
            f"unique stems/options; all cite valid PDF pages; none approved."
        )
        return 0
    except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
