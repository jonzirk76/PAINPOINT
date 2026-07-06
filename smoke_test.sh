#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SMOKE_LOG_FILE:-/tmp/shooty-smoke.log}"
MAX_LINES="${SMOKE_MAX_LINES:-200}"
FILTERED_LOG="${TMPDIR:-/tmp}/shooty-smoke-filtered.$$"

cleanup() {
	rm -f "$FILTERED_LOG"
}
trap cleanup EXIT

echo "Running Godot smoke tests..."
echo "Full log: $LOG_FILE"

godot4 --headless --path "$ROOT_DIR" --script "$ROOT_DIR/tests/smoke_tests.gd" >"$LOG_FILE" 2>&1
status=$?

if [ "$status" -eq 0 ]; then
	echo "Smoke tests passed."
	exit 0
fi

echo "Smoke tests failed with exit code $status."
echo "Full log: $LOG_FILE"
echo "---- Relevant failure lines (last $MAX_LINES) ----"

grep -E "ERROR:|SCRIPT ERROR:|FAILED|FAIL|Failure|failure|Smoke tests|GDScript backtrace|res://" "$LOG_FILE" >"$FILTERED_LOG" || true

if [ -s "$FILTERED_LOG" ]; then
	tail -n "$MAX_LINES" "$FILTERED_LOG"
else
	tail -n "$MAX_LINES" "$LOG_FILE"
fi

exit "$status"
