#!/usr/bin/env python3
"""Stage 1 terminal control surface for quarantined local-model maintenance."""

from __future__ import annotations

import argparse
import csv
import json
import re
import statistics
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


TOKEN_RE = re.compile(
    r"Tokens:\s+([0-9.]+)([kKmM]?)\s+sent,\s+([0-9.]+)([kKmM]?)\s+received\."
)
RUN_ID_RE = re.compile(r"^[A-Za-z0-9_.-]+$")


class ControlError(RuntimeError):
    """An expected operator-facing control-plane error."""


def run_git(
    repo_root: Path,
    *args: str,
    check: bool = True,
    input_bytes: bytes | None = None,
) -> subprocess.CompletedProcess[bytes]:
    result = subprocess.run(
        ["git", "-C", str(repo_root), *args],
        input=input_bytes,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if check and result.returncode != 0:
        detail = result.stderr.decode("utf-8", errors="replace").strip()
        raise ControlError(f"git {' '.join(args)} failed: {detail}")
    return result


def git_text(repo_root: Path, *args: str) -> str:
    return run_git(repo_root, *args).stdout.decode("utf-8", errors="replace").strip()


def find_repo_root() -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        text=True,
    )
    if result.returncode != 0:
        raise ControlError("maintenancectl must be run inside a Git repository")
    return Path(result.stdout.strip()).resolve()


def queue_root(repo_root: Path) -> Path:
    return repo_root / "tools" / "local_model_queue"


def runs_root(repo_root: Path) -> Path:
    return repo_root / ".local-model-runs"


def safe_run_root(repo_root: Path, run_id: str) -> Path:
    if not RUN_ID_RE.fullmatch(run_id):
        raise ControlError(f"invalid run ID: {run_id!r}")
    root = (runs_root(repo_root) / run_id).resolve()
    expected_parent = runs_root(repo_root).resolve()
    if root.parent != expected_parent or not root.is_dir():
        raise ControlError(f"run not found: {run_id}")
    return root


def read_tsv(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        return []
    with path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def append_tsv(path: Path, fieldnames: list[str], row: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    write_header = not path.exists() or path.stat().st_size == 0
    with path.open("a", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            delimiter="\t",
            fieldnames=fieldnames,
            lineterminator="\n",
            extrasaction="ignore",
        )
        if write_header:
            writer.writeheader()
        writer.writerow(row)


def read_queue(path: Path) -> dict[str, dict[str, str]]:
    tasks: dict[str, dict[str, str]] = {}
    if not path.is_file():
        return tasks
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if not raw_line or raw_line.startswith("#"):
            continue
        fields = raw_line.split("\t")
        if len(fields) == 5:
            task_id, task_class, editable_file, max_lines, commit_message = fields
        elif len(fields) == 4:
            task_id, editable_file, max_lines, commit_message = fields
            task_class = "legacy_unspecified"
        else:
            raise ControlError(f"invalid queue row in {path}: {raw_line!r}")
        tasks[task_id] = {
            "task_id": task_id,
            "task_class": task_class,
            "editable_file": editable_file,
            "max_changed_lines": max_lines,
            "candidate_commit_message": commit_message,
        }
    return tasks


def queue_for_run(repo_root: Path, run_root: Path) -> dict[str, dict[str, str]]:
    snapshot = run_root / "plan" / "queue.tsv"
    return read_queue(snapshot if snapshot.is_file() else queue_root(repo_root) / "queue.tsv")


def summary_rows(repo_root: Path, run_root: Path) -> list[dict[str, str]]:
    tasks = queue_for_run(repo_root, run_root)
    rows = read_tsv(run_root / "summary.tsv")
    for row in rows:
        task = tasks.get(row.get("task_id", ""), {})
        row.setdefault("task_class", task.get("task_class", "legacy_unspecified"))
        row.setdefault("editable_file", task.get("editable_file", ""))
    return rows


def task_row(repo_root: Path, run_root: Path, task_id: str) -> dict[str, str]:
    for row in summary_rows(repo_root, run_root):
        if row.get("task_id") == task_id:
            return row
    raise ControlError(f"task {task_id!r} is absent from run {run_root.name}")


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def scaled_number(number: str, suffix: str) -> int:
    multiplier = {"": 1, "k": 1_000, "m": 1_000_000}[suffix.lower()]
    return int(round(float(number) * multiplier))


def token_totals(log_path: Path) -> tuple[int, int]:
    if not log_path.is_file():
        return (0, 0)
    sent = 0
    received = 0
    for match in TOKEN_RE.finditer(log_path.read_text(encoding="utf-8", errors="replace")):
        sent += scaled_number(match.group(1), match.group(2))
        received += scaled_number(match.group(3), match.group(4))
    return (sent, received)


def latest_by_task(rows: Iterable[dict[str, str]]) -> dict[str, dict[str, str]]:
    latest: dict[str, dict[str, str]] = {}
    for row in rows:
        task_id = row.get("task_id", "")
        if task_id:
            latest[task_id] = row
    return latest


def parse_run_started(run_root: Path) -> datetime | None:
    explicit = run_root / "run_started_at.txt"
    if explicit.is_file():
        try:
            return datetime.fromisoformat(explicit.read_text(encoding="utf-8").strip().replace("Z", "+00:00"))
        except ValueError:
            return None
    try:
        return datetime.strptime(run_root.name, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc)
    except ValueError:
        return None


def parse_run_finished(run_root: Path) -> datetime | None:
    marker = run_root / "queue_finished_at.txt"
    if not marker.is_file():
        return None
    try:
        return datetime.fromisoformat(marker.read_text(encoding="utf-8").strip().replace("Z", "+00:00"))
    except ValueError:
        return None


def metrics_for_run(repo_root: Path, run_root: Path) -> dict[str, Any]:
    rows = summary_rows(repo_root, run_root)
    reviews = latest_by_task(read_tsv(run_root / "reviews.tsv"))
    integrations = [
        row for row in read_tsv(run_root / "integrations.tsv") if row.get("status") == "PASS"
    ]
    outcomes = latest_by_task(read_tsv(run_root / "outcomes.tsv"))
    statuses: dict[str, int] = {}
    sent_tokens = 0
    received_tokens = 0
    task_classes: set[str] = set()
    for row in rows:
        status = row.get("status", "UNKNOWN")
        statuses[status] = statuses.get(status, 0) + 1
        task_classes.add(row.get("task_class", "legacy_unspecified"))
        sent, received = token_totals(run_root / row.get("task_id", "") / "aider.log")
        sent_tokens += sent
        received_tokens += received
    attempted = len(rows)
    passed = statuses.get("PASS", 0)
    reviewed_passes = sum(
        1 for row in rows if row.get("status") == "PASS" and row.get("task_id") in reviews
    )
    review_minutes = [
        float(row["review_minutes"])
        for row in reviews.values()
        if row.get("review_minutes", "").strip()
    ]
    started = parse_run_started(run_root)
    finished = parse_run_finished(run_root)
    elapsed_seconds = int((finished - started).total_seconds()) if started and finished else None
    total_tokens = sent_tokens + received_tokens
    return {
        "run_id": run_root.name,
        "completed": finished is not None,
        "attempted_tasks": attempted,
        "passed_candidates": passed,
        "candidate_pass_rate": passed / attempted if attempted else 0.0,
        "statuses": statuses,
        "task_classes": sorted(task_classes),
        "passed_candidates_reviewed": reviewed_passes,
        "passed_candidate_review_coverage": reviewed_passes / passed if passed else 0.0,
        "accepted_reviews": sum(1 for row in reviews.values() if row.get("decision") == "accept"),
        "rejected_reviews": sum(1 for row in reviews.values() if row.get("decision") == "reject"),
        "successful_integrations": len(integrations),
        "recorded_integration_outcomes": len(outcomes),
        "integration_outcome_coverage": len(outcomes) / len(integrations) if integrations else 0.0,
        "verified_integrations": sum(1 for row in outcomes.values() if row.get("outcome") == "verified"),
        "defects_or_reverts": sum(
            1 for row in outcomes.values() if row.get("outcome") in {"defect", "reverted"}
        ),
        "median_review_minutes": statistics.median(review_minutes) if review_minutes else None,
        "sent_tokens": sent_tokens,
        "received_tokens": received_tokens,
        "local_tokens_per_passed_candidate": total_tokens / passed if passed else None,
        "passed_candidates_per_hour": (
            passed / (elapsed_seconds / 3600.0) if elapsed_seconds and passed else None
        ),
        "elapsed_seconds": elapsed_seconds,
    }


def all_run_roots(repo_root: Path) -> list[Path]:
    root = runs_root(repo_root)
    if not root.is_dir():
        return []
    return sorted(
        path for path in root.iterdir() if path.is_dir() and (path / "summary.tsv").is_file()
    )


def print_run_report(metrics: dict[str, Any]) -> None:
    elapsed = metrics["elapsed_seconds"]
    elapsed_text = f"{elapsed // 60}m {elapsed % 60}s" if elapsed is not None else "incomplete"
    median = metrics["median_review_minutes"]
    median_text = f"{median:.1f}" if median is not None else "not recorded"
    print(f"Run: {metrics['run_id']}")
    print(f"Completed: {'yes' if metrics['completed'] else 'no'}")
    print(f"Elapsed: {elapsed_text}")
    print(f"Tasks: {metrics['attempted_tasks']}")
    print(
        f"Candidates passed: {metrics['passed_candidates']} "
        f"({metrics['candidate_pass_rate']:.1%})"
    )
    print(f"Statuses: {json.dumps(metrics['statuses'], sort_keys=True)}")
    print(f"Task classes: {', '.join(metrics['task_classes']) or 'none'}")
    print(
        f"Passed candidates reviewed: {metrics['passed_candidates_reviewed']} "
        f"({metrics['passed_candidate_review_coverage']:.1%})"
    )
    print(
        f"Review decisions: {metrics['accepted_reviews']} accept, "
        f"{metrics['rejected_reviews']} reject"
    )
    print(f"Median review minutes: {median_text}")
    print(f"Successful integrations: {metrics['successful_integrations']}")
    print(
        f"Integration outcome coverage: {metrics['recorded_integration_outcomes']} "
        f"({metrics['integration_outcome_coverage']:.1%})"
    )
    print(f"Verified integrations: {metrics['verified_integrations']}")
    print(f"Defects or reverts: {metrics['defects_or_reverts']}")
    print(f"Local tokens: {metrics['sent_tokens']} sent, {metrics['received_tokens']} received")
    tokens_per_pass = metrics["local_tokens_per_passed_candidate"]
    candidates_per_hour = metrics["passed_candidates_per_hour"]
    print(
        "Local tokens per passed candidate: "
        f"{tokens_per_pass:.0f}" if tokens_per_pass is not None else "Local tokens per passed candidate: n/a"
    )
    print(
        "Passed candidates per wall-clock hour: "
        f"{candidates_per_hour:.2f}"
        if candidates_per_hour is not None
        else "Passed candidates per wall-clock hour: n/a"
    )


def aggregate_metrics(repo_root: Path) -> dict[str, Any]:
    run_metrics = [metrics_for_run(repo_root, root) for root in all_run_roots(repo_root)]
    attempted = sum(item["attempted_tasks"] for item in run_metrics)
    passed = sum(item["passed_candidates"] for item in run_metrics)
    reviewed = sum(item["passed_candidates_reviewed"] for item in run_metrics)
    successful_integrations = sum(item["successful_integrations"] for item in run_metrics)
    recorded_outcomes = sum(item["recorded_integration_outcomes"] for item in run_metrics)
    review_minutes: list[float] = []
    task_classes: set[str] = set()
    for root, item in zip(all_run_roots(repo_root), run_metrics):
        task_classes.update(item["task_classes"])
        latest_reviews = latest_by_task(read_tsv(root / "reviews.tsv"))
        review_minutes.extend(
            float(row["review_minutes"])
            for row in latest_reviews.values()
            if row.get("review_minutes", "").strip()
        )
    return {
        "completed_runs": sum(1 for item in run_metrics if item["completed"]),
        "attempted_tasks": attempted,
        "task_classes": len(task_classes),
        "candidate_pass_rate": passed / attempted if attempted else 0.0,
        "passed_candidate_review_coverage": reviewed / passed if passed else 0.0,
        "integration_outcome_coverage": (
            recorded_outcomes / successful_integrations if successful_integrations else 0.0
        ),
        "verified_integrations": sum(item["verified_integrations"] for item in run_metrics),
        "median_review_minutes": statistics.median(review_minutes) if review_minutes else None,
        "escaped_defects_or_reverts": sum(item["defects_or_reverts"] for item in run_metrics),
    }


def load_stage(repo_root: Path) -> dict[str, Any]:
    path = queue_root(repo_root) / "stage.json"
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ControlError(f"cannot read stage policy {path}: {error}") from error


def readiness(repo_root: Path) -> dict[str, Any]:
    stage = load_stage(repo_root)
    actual = aggregate_metrics(repo_root)
    limits = stage["thresholds"]
    checks = {
        "completed_runs": actual["completed_runs"] >= limits["completed_runs_min"],
        "attempted_tasks": actual["attempted_tasks"] >= limits["attempted_tasks_min"],
        "task_classes": actual["task_classes"] >= limits["task_classes_min"],
        "candidate_pass_rate": actual["candidate_pass_rate"] >= limits["candidate_pass_rate_min"],
        "passed_candidate_review_coverage": actual["passed_candidate_review_coverage"]
        >= limits["passed_candidate_review_coverage_min"],
        "integration_outcome_coverage": actual["integration_outcome_coverage"]
        >= limits["integration_outcome_coverage_min"],
        "verified_integrations": actual["verified_integrations"]
        >= limits["verified_integrations_min"],
        "median_review_minutes": actual["median_review_minutes"] is not None
        and actual["median_review_minutes"] <= limits["median_review_minutes_max"],
        "escaped_defects_or_reverts": actual["escaped_defects_or_reverts"]
        <= limits["escaped_defects_or_reverts_max"],
    }
    return {
        "stage": stage,
        "actual": actual,
        "checks": checks,
        "ready_for_promotion_review": all(checks.values()),
    }


def print_readiness(result: dict[str, Any]) -> None:
    stage = result["stage"]
    actual = result["actual"]
    limits = stage["thresholds"]
    rows = [
        ("Completed runs", actual["completed_runs"], f">= {limits['completed_runs_min']}", "completed_runs"),
        ("Attempted tasks", actual["attempted_tasks"], f">= {limits['attempted_tasks_min']}", "attempted_tasks"),
        ("Task classes", actual["task_classes"], f">= {limits['task_classes_min']}", "task_classes"),
        (
            "Candidate pass rate",
            f"{actual['candidate_pass_rate']:.1%}",
            f">= {limits['candidate_pass_rate_min']:.1%}",
            "candidate_pass_rate",
        ),
        (
            "Passed-candidate review coverage",
            f"{actual['passed_candidate_review_coverage']:.1%}",
            f">= {limits['passed_candidate_review_coverage_min']:.1%}",
            "passed_candidate_review_coverage",
        ),
        (
            "Integration outcome coverage",
            f"{actual['integration_outcome_coverage']:.1%}",
            f">= {limits['integration_outcome_coverage_min']:.1%}",
            "integration_outcome_coverage",
        ),
        (
            "Verified integrations",
            actual["verified_integrations"],
            f">= {limits['verified_integrations_min']}",
            "verified_integrations",
        ),
        (
            "Median review minutes",
            actual["median_review_minutes"] if actual["median_review_minutes"] is not None else "not recorded",
            f"<= {limits['median_review_minutes_max']}",
            "median_review_minutes",
        ),
        (
            "Defects or reverts",
            actual["escaped_defects_or_reverts"],
            f"<= {limits['escaped_defects_or_reverts_max']}",
            "escaped_defects_or_reverts",
        ),
    ]
    print(f"Current stage: {stage['current_stage']} ({stage['stage_name']})")
    print(f"Promotion target: Stage {stage['promotion_target']}")
    for label, value, target, key in rows:
        state = "PASS" if result["checks"][key] else "WAIT"
        print(f"[{state}] {label}: {value} (target {target})")
    if result["ready_for_promotion_review"]:
        print("READY_FOR_PROMOTION_REVIEW")
        print("The principal should inform the user; promotion still requires explicit user approval.")
    else:
        print("NOT_READY_FOR_PROMOTION")


def command_runs(repo_root: Path, _args: argparse.Namespace) -> None:
    roots = all_run_roots(repo_root)
    if not roots:
        print("No recorded runs.")
        return
    print("run_id\tcompleted\ttasks\tpassed\tpass_rate")
    for root in roots:
        metrics = metrics_for_run(repo_root, root)
        print(
            f"{root.name}\t{'yes' if metrics['completed'] else 'no'}\t"
            f"{metrics['attempted_tasks']}\t{metrics['passed_candidates']}\t"
            f"{metrics['candidate_pass_rate']:.1%}"
        )


def command_report(repo_root: Path, args: argparse.Namespace) -> None:
    metrics = metrics_for_run(repo_root, safe_run_root(repo_root, args.run_id))
    if args.json:
        print(json.dumps(metrics, indent=2, sort_keys=True))
    else:
        print_run_report(metrics)


def command_show(repo_root: Path, args: argparse.Namespace) -> None:
    root = safe_run_root(repo_root, args.run_id)
    row = task_row(repo_root, root, args.task_id)
    print(json.dumps(row, indent=2, sort_keys=True))
    validation = root / args.task_id / "validation.log"
    candidate = root / args.task_id / "candidate.diff"
    if validation.is_file() and validation.stat().st_size:
        print("\nValidation output:\n")
        print(validation.read_text(encoding="utf-8", errors="replace").rstrip())
    if candidate.is_file() and candidate.stat().st_size:
        print("\nCandidate diff:\n")
        print(candidate.read_text(encoding="utf-8", errors="replace").rstrip())


def command_review(repo_root: Path, args: argparse.Namespace) -> None:
    root = safe_run_root(repo_root, args.run_id)
    row = task_row(repo_root, root, args.task_id)
    if args.minutes < 0.0:
        raise ControlError("review minutes cannot be negative")
    if args.decision == "accept" and row.get("status") != "PASS":
        raise ControlError("only a PASS candidate can receive an accept decision")
    append_tsv(
        root / "reviews.tsv",
        [
            "task_id",
            "decision",
            "review_minutes",
            "reason",
            "reviewer",
            "candidate_commit",
            "reviewed_at",
        ],
        {
            "task_id": args.task_id,
            "decision": args.decision,
            "review_minutes": args.minutes,
            "reason": args.reason,
            "reviewer": args.reviewer,
            "candidate_commit": row.get("commit", "-"),
            "reviewed_at": utc_now(),
        },
    )
    print(f"Recorded {args.decision} review for {args.run_id}/{args.task_id}.")


def latest_integration(run_root: Path, task_id: str) -> dict[str, str] | None:
    latest = latest_by_task(read_tsv(run_root / "integrations.tsv"))
    return latest.get(task_id)


def command_integrate(repo_root: Path, args: argparse.Namespace) -> None:
    if not args.apply:
        raise ControlError("integration requires --apply as an explicit deployment acknowledgement")
    root = safe_run_root(repo_root, args.run_id)
    row = task_row(repo_root, root, args.task_id)
    if row.get("status") != "PASS":
        raise ControlError("only a PASS candidate can be integrated")
    candidate_commit = row.get("commit", "")
    if not candidate_commit or candidate_commit == "-" or args.confirm != candidate_commit:
        raise ControlError("--confirm must exactly match the full candidate commit in the run summary")
    review = latest_by_task(read_tsv(root / "reviews.tsv")).get(args.task_id)
    if review is None or review.get("decision") != "accept":
        raise ControlError("record an explicit accept review before integration")
    previous = latest_integration(root, args.task_id)
    if previous is not None and previous.get("status") == "PASS":
        raise ControlError(f"task was already integrated as {previous.get('integrated_commit', 'unknown')}")

    current_branch = git_text(repo_root, "branch", "--show-current")
    if not current_branch:
        raise ControlError("integration is refused from a detached HEAD")
    protected_branches = set(load_stage(repo_root).get("protected_branches", ["main", "master"]))
    if current_branch in protected_branches:
        raise ControlError(f"Stage 1 refuses direct integration into protected branch {current_branch!r}")
    if git_text(repo_root, "status", "--porcelain", "--untracked-files=no"):
        raise ControlError("tracked worktree changes exist; integration requires a clean checkout")

    base_commit = (root / "base_commit.txt").read_text(encoding="utf-8").strip()
    candidate_parent = git_text(repo_root, "rev-parse", f"{candidate_commit}^")
    if candidate_parent != base_commit:
        raise ControlError("candidate commit parent does not match the recorded run base")
    ancestor = run_git(repo_root, "merge-base", "--is-ancestor", base_commit, "HEAD", check=False)
    if ancestor.returncode != 0:
        raise ControlError("recorded run base is not an ancestor of the current integration branch")

    candidate_diff = run_git(repo_root, "diff", base_commit, candidate_commit).stdout
    stored_diff_path = root / args.task_id / "candidate.diff"
    if not stored_diff_path.is_file() or stored_diff_path.read_bytes() != candidate_diff:
        raise ControlError("candidate diff no longer matches the immutable run artifact")

    patch_check = run_git(repo_root, "apply", "--check", "-", check=False, input_bytes=candidate_diff)
    if patch_check.returncode != 0:
        detail = patch_check.stderr.decode("utf-8", errors="replace").strip()
        raise ControlError(f"candidate does not apply cleanly to the current branch: {detail}")

    cherry_pick = run_git(repo_root, "cherry-pick", candidate_commit, check=False)
    if cherry_pick.returncode != 0:
        run_git(repo_root, "cherry-pick", "--abort", check=False)
        append_tsv(
            root / "integrations.tsv",
            ["task_id", "status", "candidate_commit", "integrated_commit", "target_branch", "integrated_at"],
            {
                "task_id": args.task_id,
                "status": "FAILED",
                "candidate_commit": candidate_commit,
                "integrated_commit": "-",
                "target_branch": current_branch,
                "integrated_at": utc_now(),
            },
        )
        detail = cherry_pick.stderr.decode("utf-8", errors="replace").strip()
        raise ControlError(f"cherry-pick failed and was aborted: {detail}")

    integrated_commit = git_text(repo_root, "rev-parse", "HEAD")
    append_tsv(
        root / "integrations.tsv",
        ["task_id", "status", "candidate_commit", "integrated_commit", "target_branch", "integrated_at"],
        {
            "task_id": args.task_id,
            "status": "PASS",
            "candidate_commit": candidate_commit,
            "integrated_commit": integrated_commit,
            "target_branch": current_branch,
            "integrated_at": utc_now(),
        },
    )
    print(f"Integrated {candidate_commit} as {integrated_commit} on {current_branch}.")
    print("No tests were run; record a verified/defect/reverted outcome after authorized validation.")


def command_outcome(repo_root: Path, args: argparse.Namespace) -> None:
    root = safe_run_root(repo_root, args.run_id)
    task_row(repo_root, root, args.task_id)
    integration = latest_integration(root, args.task_id)
    if integration is None or integration.get("status") != "PASS":
        raise ControlError("an outcome can be recorded only after successful integration")
    append_tsv(
        root / "outcomes.tsv",
        ["task_id", "outcome", "reason", "integrated_commit", "recorded_at"],
        {
            "task_id": args.task_id,
            "outcome": args.outcome,
            "reason": args.reason,
            "integrated_commit": integration.get("integrated_commit", "-"),
            "recorded_at": utc_now(),
        },
    )
    print(f"Recorded {args.outcome} outcome for {args.run_id}/{args.task_id}.")


def command_readiness(repo_root: Path, args: argparse.Namespace) -> None:
    result = readiness(repo_root)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print_readiness(result)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Review, measure, and explicitly integrate quarantined local-model candidates."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    runs_parser = subparsers.add_parser("runs", help="list recorded queue runs")
    runs_parser.set_defaults(handler=command_runs)

    report_parser = subparsers.add_parser("report", help="show metrics for one run")
    report_parser.add_argument("run_id")
    report_parser.add_argument("--json", action="store_true")
    report_parser.set_defaults(handler=command_report)

    show_parser = subparsers.add_parser("show", help="show one task result and its diff")
    show_parser.add_argument("run_id")
    show_parser.add_argument("task_id")
    show_parser.set_defaults(handler=command_show)

    review_parser = subparsers.add_parser("review", help="record a human review decision")
    review_parser.add_argument("run_id")
    review_parser.add_argument("task_id")
    review_parser.add_argument("decision", choices=("accept", "reject"))
    review_parser.add_argument("--minutes", type=float, required=True)
    review_parser.add_argument("--reason", default="")
    review_parser.add_argument("--reviewer", default="human")
    review_parser.set_defaults(handler=command_review)

    integrate_parser = subparsers.add_parser(
        "integrate", help="human-gated cherry-pick of one accepted candidate"
    )
    integrate_parser.add_argument("run_id")
    integrate_parser.add_argument("task_id")
    integrate_parser.add_argument("--confirm", required=True)
    integrate_parser.add_argument("--apply", action="store_true")
    integrate_parser.set_defaults(handler=command_integrate)

    outcome_parser = subparsers.add_parser("outcome", help="record post-integration outcome")
    outcome_parser.add_argument("run_id")
    outcome_parser.add_argument("task_id")
    outcome_parser.add_argument("outcome", choices=("verified", "defect", "reverted"))
    outcome_parser.add_argument("--reason", default="")
    outcome_parser.set_defaults(handler=command_outcome)

    readiness_parser = subparsers.add_parser(
        "readiness", help="evaluate the current stage promotion metrics"
    )
    readiness_parser.add_argument("--json", action="store_true")
    readiness_parser.set_defaults(handler=command_readiness)
    return parser


def main() -> int:
    try:
        args = build_parser().parse_args()
        repo_root = find_repo_root()
        args.handler(repo_root, args)
        return 0
    except ControlError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
