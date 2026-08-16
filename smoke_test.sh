#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="${SMOKE_RUNTIME_DIR:-$ROOT_DIR/.smoke-test-runtime}"
LOG_FILE="${SMOKE_LOG_FILE:-$RUNTIME_DIR/smoke.log}"
PROGRESS_FILE="${SMOKE_PROGRESS_FILE:-$RUNTIME_DIR/progress.log}"
CONSOLE_LOG="${SMOKE_CONSOLE_LOG_FILE:-$RUNTIME_DIR/console.log}"
MAX_LINES="${SMOKE_MAX_LINES:-200}"
FILTERED_LOG="${TMPDIR:-/tmp}/shooty-smoke-filtered.$$"
GODOT_BIN="${GODOT_BIN:-godot4}"
SMOKE_SUITE="${SMOKE_SUITE:-full}"
SMOKE_TEST_FILTER="${SMOKE_TEST_FILTER:-}"
HEARTBEAT_SECONDS="${SMOKE_HEARTBEAT_SECONDS:-30}"
HEARTBEAT_PID=""

case "$SMOKE_SUITE" in
	fast)
		DEFAULT_TIMEOUT_SECONDS=180
		;;
	full)
		DEFAULT_TIMEOUT_SECONDS=900
		;;
	*)
		echo "error: SMOKE_SUITE must be 'fast' or 'full'" >&2
		exit 2
		;;
esac

TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-$DEFAULT_TIMEOUT_SECONDS}"

if ! command -v timeout >/dev/null 2>&1; then
	echo "error: GNU timeout is required for bounded smoke-test execution" >&2
	exit 1
fi

if [[ ! "$TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
	echo "error: SMOKE_TIMEOUT_SECONDS must be a positive integer" >&2
	exit 2
fi

if [[ ! "$HEARTBEAT_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
	echo "error: SMOKE_HEARTBEAT_SECONDS must be a positive integer" >&2
	exit 2
fi

if [[ "$LOG_FILE" == "$PROGRESS_FILE" || "$LOG_FILE" == "$CONSOLE_LOG" || "$PROGRESS_FILE" == "$CONSOLE_LOG" ]]; then
	echo "error: smoke log, progress log, and console log paths must be different" >&2
	exit 2
fi

if ! mkdir -p "$RUNTIME_DIR"; then
	echo "error: could not create smoke runtime directory: $RUNTIME_DIR" >&2
	exit 1
fi

cleanup() {
	if [ -n "$HEARTBEAT_PID" ]; then
		kill "$HEARTBEAT_PID" 2>/dev/null || true
		wait "$HEARTBEAT_PID" 2>/dev/null || true
	fi
	rm -f "$FILTERED_LOG"
}
trap cleanup EXIT

heartbeat() {
	local started_epoch
	local current_epoch
	local elapsed_seconds
	local last_progress
	started_epoch="$(date +%s)"
	while true; do
		sleep "$HEARTBEAT_SECONDS"
		current_epoch="$(date +%s)"
		elapsed_seconds="$((current_epoch - started_epoch))"
		last_progress="$(tail -n 1 "$PROGRESS_FILE" 2>/dev/null || true)"
		if [ -z "$last_progress" ]; then
			last_progress="waiting for Godot test initialization"
		fi
		echo "Smoke tests still running (${elapsed_seconds}s/${TIMEOUT_SECONDS}s): $last_progress"
	done
}

: >"$LOG_FILE"
: >"$PROGRESS_FILE"
: >"$CONSOLE_LOG"
export SHOOTY_SMOKE_SUITE="$SMOKE_SUITE"
export SHOOTY_SMOKE_TEST_FILTER="$SMOKE_TEST_FILTER"
export SHOOTY_SMOKE_PROGRESS_FILE="$PROGRESS_FILE"

echo "Running Godot smoke tests ($SMOKE_SUITE suite)..."
echo "Godot binary: $GODOT_BIN"
echo "Full log: $LOG_FILE"
echo "Progress log: $PROGRESS_FILE"
echo "Launcher log: $CONSOLE_LOG"
echo "Timeout: ${TIMEOUT_SECONDS}s"
if [ -n "$SMOKE_TEST_FILTER" ]; then
	echo "Test filter: $SMOKE_TEST_FILTER"
fi

heartbeat &
HEARTBEAT_PID="$!"

timeout --foreground --signal=TERM --kill-after=10s "${TIMEOUT_SECONDS}s" \
	"$GODOT_BIN" --headless --path "$ROOT_DIR" --log-file "$LOG_FILE" \
	--script "$ROOT_DIR/tests/smoke_tests.gd" >"$CONSOLE_LOG" 2>&1
status=$?

kill "$HEARTBEAT_PID" 2>/dev/null || true
wait "$HEARTBEAT_PID" 2>/dev/null || true
HEARTBEAT_PID=""

if [ "$status" -eq 0 ]; then
	echo "Smoke tests passed."
	exit 0
fi

if [ "$status" -eq 124 ]; then
	echo "Smoke tests timed out after ${TIMEOUT_SECONDS}s."
else
	echo "Smoke tests failed with exit code $status."
fi

echo "Last recorded progress:"
tail -n 20 "$PROGRESS_FILE" 2>/dev/null || true
echo "Full log: $LOG_FILE"
echo "Progress log: $PROGRESS_FILE"
echo "Launcher log: $CONSOLE_LOG"
echo "---- Relevant failure lines (last $MAX_LINES) ----"

grep -E "ERROR:|SCRIPT ERROR:|FAILED|FAIL|Failure|failure|Smoke tests|SMOKE TEST|SMOKE SUITE|GDScript backtrace|res://" \
	"$LOG_FILE" "$CONSOLE_LOG" >"$FILTERED_LOG" || true

if [ -s "$FILTERED_LOG" ]; then
	tail -n "$MAX_LINES" "$FILTERED_LOG"
else
	tail -n "$MAX_LINES" "$LOG_FILE" "$CONSOLE_LOG"
fi

exit "$status"
