#!/usr/bin/env python3
"""Read-only smoke-test reconnaissance for test_rehabilitation_01."""

from __future__ import annotations

import argparse
import re
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PLAN = ROOT / "tools/local_model_recon/test_rehabilitation_01.md"
SMOKE_SOURCE = ROOT / "tests/smoke_tests.gd"
SMOKE_LOG = ROOT / ".smoke-test-runtime/smoke.log"
REQUIRED_PLAN_MARKERS = (
    "# test_rehabilitation_01",
    "## Guardrails and non-goals",
    "## Work items",
    "TR01-W1",
    "TR01-W2",
    "TR01-W3",
    "TR01-W4",
)
REQUIRED_TESTS = (
    "_test_dungeon_floor_recipe",
    "_test_dungeon_run_seed",
    "_test_dungeon_layout_solver",
    "_test_room_interior_generator_determinism_and_budget",
)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def summarize_log(text: str) -> tuple[int, Counter[str], Counter[str], int]:
    finished = re.findall(
        r"^SMOKE TEST END name=([^ ]+) status=(PASS|FAIL) duration_ms=(\d+) failures_added=(\d+)$",
        text,
        re.MULTILINE,
    )
    statuses = Counter(status for _, status, _, _ in finished)
    error_lines = sum(
        1 for line in text.splitlines()
        if line.startswith("SCRIPT ERROR:") or line.startswith("ERROR:")
    )
    failing = Counter(name for name, status, _, _ in finished if status == "FAIL")
    return len(finished), statuses, failing, error_lines


def report() -> int:
    source = read(SMOKE_SOURCE)
    print("test_rehabilitation_01 reconnaissance")
    print("mode=read-only")
    print("source=tests/smoke_tests.gd")
    print("required_test_anchors=%d/%d" % (sum(name in source for name in REQUIRED_TESTS), len(REQUIRED_TESTS)))
    if not SMOKE_LOG.exists():
        print("smoke_log=absent")
        return 0
    completed, statuses, failing, error_lines = summarize_log(read(SMOKE_LOG))
    print("smoke_log=.smoke-test-runtime/smoke.log")
    print("completed=%d pass=%d fail=%d explicit_runtime_error_lines=%d" % (
        completed, statuses["PASS"], statuses["FAIL"], error_lines
    ))
    print("failed_tests=%s" % ",".join(sorted(failing)) if failing else "failed_tests=none")
    print("known_expensive_anchors=dungeon_floor_recipe,dungeon_run_seed,dungeon_layout_solver,room_interior_generator_determinism_and_budget")
    return 0


def check() -> int:
    errors: list[str] = []
    for path in (PLAN, SMOKE_SOURCE, Path(__file__)):
        if not path.exists():
            errors.append("missing=%s" % path.relative_to(ROOT))
    if not errors:
        plan = read(PLAN)
        for marker in REQUIRED_PLAN_MARKERS:
            if marker not in plan:
                errors.append("plan_marker_missing=%s" % marker)
        source = read(SMOKE_SOURCE)
        for name in REQUIRED_TESTS:
            if name not in source:
                errors.append("source_anchor_missing=%s" % name)
    if errors:
        print("validation=FAIL")
        print("\n".join(sorted(errors)))
        return 1
    print("validation=PASS")
    print("checked=plan_markers,source_anchors,read_only_contract")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--report", action="store_true", help="print static evidence only")
    group.add_argument("--check", action="store_true", help="validate packet anchors only")
    args = parser.parse_args()
    return report() if args.report else check()


if __name__ == "__main__":
    raise SystemExit(main())
