#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
QUEUE_FILE="$SCRIPT_DIR/queue.tsv"
RUNS_ROOT="$REPO_ROOT/.local-model-runs"
WORKTREES_ROOT="/tmp/shooty-local-model-worktrees"
OLLAMA_MODEL_NAME="${OVERNIGHT_MODEL:-qwen2.5-coder:7b}"
AIDER_MODEL_NAME="ollama_chat/$OLLAMA_MODEL_NAME"
TASK_TIMEOUT_MINUTES="${OVERNIGHT_TASK_TIMEOUT_MINUTES:-45}"
OLLAMA_API_BASE="${OLLAMA_API_BASE:-http://127.0.0.1:11434}"
export OLLAMA_API_BASE

DRY_RUN=false
RESUME_RUN_ID=""

usage() {
	cat <<'EOF'
Usage:
  run_queue.sh [--dry-run]
  run_queue.sh --resume RUN_ID

Environment overrides:
  OVERNIGHT_MODEL=qwen2.5-coder:7b
  OVERNIGHT_TASK_TIMEOUT_MINUTES=45
  OLLAMA_API_BASE=http://127.0.0.1:11434
EOF
}

while (( $# > 0 )); do
	case "$1" in
		--dry-run)
			DRY_RUN=true
			shift
			;;
		--resume)
			if (( $# < 2 )); then
				echo "error: --resume requires a run ID" >&2
				exit 2
			fi
			RESUME_RUN_ID="$2"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "error: unknown argument: $1" >&2
			usage >&2
			exit 2
			;;
	esac
done

if [[ "$DRY_RUN" == true && -n "$RESUME_RUN_ID" ]]; then
	echo "error: --dry-run and --resume cannot be combined" >&2
	exit 2
fi

for command_name in git aider ollama timeout; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		echo "error: required command is unavailable: $command_name" >&2
		exit 1
	fi
done

if [[ ! "$TASK_TIMEOUT_MINUTES" =~ ^[1-9][0-9]*$ ]]; then
	echo "error: OVERNIGHT_TASK_TIMEOUT_MINUTES must be a positive integer" >&2
	exit 2
fi

if [[ -n "$(git -C "$REPO_ROOT" status --porcelain --untracked-files=no)" ]]; then
	echo "error: tracked changes exist; commit or stash them before starting the queue" >&2
	exit 1
fi

if ! ollama show "$OLLAMA_MODEL_NAME" >/dev/null 2>&1; then
	echo "error: Ollama cannot load '$OLLAMA_MODEL_NAME'; ensure the server is running and the model is pulled" >&2
	exit 1
fi

BASE_COMMIT="$(git -C "$REPO_ROOT" rev-parse HEAD)"

if [[ "$DRY_RUN" == true ]]; then
	echo "Mode: dry run"
	echo "Repository: $REPO_ROOT"
	echo "Base commit: $BASE_COMMIT"
	echo "Aider model: $AIDER_MODEL_NAME"
	echo "Per-task timeout: ${TASK_TIMEOUT_MINUTES}m"
	echo "Tasks:"
	while IFS=$'\t' read -r task_id editable_file max_changed_lines commit_message; do
		[[ -z "$task_id" || "$task_id" == \#* ]] && continue
		printf '  - %s | %s | max %s changed lines\n' "$task_id" "$editable_file" "$max_changed_lines"
	done < "$QUEUE_FILE"
	exit 0
fi

if [[ -n "$RESUME_RUN_ID" ]]; then
	RUN_ID="$RESUME_RUN_ID"
	RUN_ROOT="$RUNS_ROOT/$RUN_ID"
	if [[ ! -d "$RUN_ROOT" || ! -f "$RUN_ROOT/base_commit.txt" ]]; then
		echo "error: run records not found for '$RUN_ID'" >&2
		exit 1
	fi
	BASE_COMMIT="$(<"$RUN_ROOT/base_commit.txt")"
else
	RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
	RUN_ROOT="$RUNS_ROOT/$RUN_ID"
	mkdir -p "$RUN_ROOT"
	printf '%s\n' "$BASE_COMMIT" > "$RUN_ROOT/base_commit.txt"
	printf 'task_id\tstatus\tbranch\tcommit\tworktree\tlog\n' > "$RUN_ROOT/summary.tsv"
fi

mkdir -p "$WORKTREES_ROOT/$RUN_ID"

record_result() {
	local task_id="$1"
	local status="$2"
	local branch_name="$3"
	local commit_hash="$4"
	local worktree_path="$5"
	local log_path="$6"
	local task_run_root="$RUN_ROOT/$task_id"

	printf '%s\n' "$status" > "$task_run_root/status.txt"
	printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
		"$task_id" "$status" "$branch_name" "$commit_hash" "$worktree_path" "$log_path" \
		>> "$RUN_ROOT/summary.tsv"
}

validate_candidate() {
	local worktree_path="$1"
	local editable_file="$2"
	local max_changed_lines="$3"
	local task_definition_root="$4"
	local changed_file_count
	local changed_file
	local changed_lines
	local expected_line
	local untracked_file_count

	git -C "$worktree_path" diff HEAD --check

	untracked_file_count="$(git -C "$worktree_path" ls-files --others --exclude-standard | sed '/^$/d' | wc -l)"
	if [[ "$untracked_file_count" -ne 0 ]]; then
		echo "validation error: found $untracked_file_count unexpected untracked files" >&2
		return 1
	fi

	changed_file_count="$(git -C "$worktree_path" diff HEAD --name-only | sed '/^$/d' | wc -l)"
	if [[ "$changed_file_count" -ne 1 ]]; then
		echo "validation error: expected exactly one changed file, found $changed_file_count" >&2
		return 1
	fi

	changed_file="$(git -C "$worktree_path" diff HEAD --name-only)"
	if [[ "$changed_file" != "$editable_file" ]]; then
		echo "validation error: unexpected changed file: $changed_file" >&2
		return 1
	fi

	changed_lines="$(git -C "$worktree_path" diff HEAD --numstat -- "$editable_file" | awk '{ added += $1; deleted += $2 } END { print added + deleted + 0 }')"
	if (( changed_lines == 0 || changed_lines > max_changed_lines )); then
		echo "validation error: changed-line total $changed_lines is outside 1..$max_changed_lines" >&2
		return 1
	fi

	while IFS= read -r expected_line || [[ -n "$expected_line" ]]; do
		[[ -z "$expected_line" ]] && continue
		if ! grep -Fqx -- "$expected_line" "$worktree_path/$editable_file"; then
			echo "validation error: required exact line is absent: $expected_line" >&2
			return 1
		fi
	done < "$task_definition_root/required_lines.txt"

	while IFS= read -r expected_line || [[ -n "$expected_line" ]]; do
		[[ -z "$expected_line" ]] && continue
		if grep -Fqx -- "$expected_line" "$worktree_path/$editable_file"; then
			echo "validation error: forbidden original line remains: $expected_line" >&2
			return 1
		fi
	done < "$task_definition_root/forbidden_lines.txt"
}

echo "Run ID: $RUN_ID"
echo "Base commit: $BASE_COMMIT"
echo "Aider model: $AIDER_MODEL_NAME"
echo "Results: $RUN_ROOT"

while IFS=$'\t' read -r task_id editable_file max_changed_lines commit_message; do
	[[ -z "$task_id" || "$task_id" == \#* ]] && continue

	TASK_DEFINITION_ROOT="$SCRIPT_DIR/tasks/$task_id"
	TASK_RUN_ROOT="$RUN_ROOT/$task_id"
	WORKTREE_PATH="$WORKTREES_ROOT/$RUN_ID/$task_id"
	BRANCH_NAME="local-model/$RUN_ID/$task_id"
	LOG_PATH="$TASK_RUN_ROOT/aider.log"
	mkdir -p "$TASK_RUN_ROOT"

	if [[ -f "$TASK_RUN_ROOT/status.txt" ]]; then
		EXISTING_STATUS="$(<"$TASK_RUN_ROOT/status.txt")"
		if [[ "$EXISTING_STATUS" != "RUNNING" ]]; then
			echo "[$task_id] already recorded as $EXISTING_STATUS; skipping"
			continue
		fi
	fi

	if [[ -e "$WORKTREE_PATH" ]] || git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
		echo "[$task_id] preserving an existing incomplete branch/worktree"
		record_result "$task_id" "INTERRUPTED" "$BRANCH_NAME" "-" "$WORKTREE_PATH" "$LOG_PATH"
		continue
	fi

	if [[ ! -f "$TASK_DEFINITION_ROOT/prompt.md" || ! -f "$TASK_DEFINITION_ROOT/required_lines.txt" || ! -f "$TASK_DEFINITION_ROOT/forbidden_lines.txt" ]]; then
		echo "[$task_id] task definition is incomplete" >&2
		record_result "$task_id" "CONFIG_ERROR" "$BRANCH_NAME" "-" "$WORKTREE_PATH" "$LOG_PATH"
		continue
	fi

	if [[ ! -f "$REPO_ROOT/$editable_file" ]]; then
		echo "[$task_id] editable file does not exist: $editable_file" >&2
		record_result "$task_id" "CONFIG_ERROR" "$BRANCH_NAME" "-" "$WORKTREE_PATH" "$LOG_PATH"
		continue
	fi

	echo "[$task_id] creating isolated candidate branch"
	git -C "$REPO_ROOT" worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$BASE_COMMIT" \
		> "$TASK_RUN_ROOT/worktree.log" 2>&1
	printf 'RUNNING\n' > "$TASK_RUN_ROOT/status.txt"

	echo "[$task_id] running Aider (timeout ${TASK_TIMEOUT_MINUTES}m)"
	set +e
	(
		cd "$WORKTREE_PATH"
		timeout --signal=TERM "${TASK_TIMEOUT_MINUTES}m" \
			aider \
			--model "$AIDER_MODEL_NAME" \
			--edit-format whole \
			--map-tokens 0 \
			--no-restore-chat-history \
			--no-auto-commits \
			--no-dirty-commits \
			--no-auto-lint \
			--no-auto-test \
			--no-suggest-shell-commands \
			--no-gitignore \
			--no-check-update \
			--no-analytics \
			--no-show-model-warnings \
			--yes-always \
			--no-pretty \
			--no-stream \
			--input-history-file "$TASK_RUN_ROOT/input.history" \
			--chat-history-file "$TASK_RUN_ROOT/chat.history.md" \
			--llm-history-file "$TASK_RUN_ROOT/llm.history" \
			--message-file "$TASK_DEFINITION_ROOT/prompt.md" \
			"$editable_file"
	) \
		2>&1 | tee "$LOG_PATH"
	AIDER_EXIT_CODE="${PIPESTATUS[0]}"
	set -e
	printf '%s\n' "$AIDER_EXIT_CODE" > "$TASK_RUN_ROOT/aider_exit_code.txt"
	git -C "$WORKTREE_PATH" status --short > "$TASK_RUN_ROOT/git_status.txt"
	git -C "$WORKTREE_PATH" diff HEAD > "$TASK_RUN_ROOT/candidate.diff"

	if (( AIDER_EXIT_CODE != 0 )); then
		echo "[$task_id] Aider failed with exit code $AIDER_EXIT_CODE; preserving worktree"
		record_result "$task_id" "AIDER_FAILED" "$BRANCH_NAME" "-" "$WORKTREE_PATH" "$LOG_PATH"
		continue
	fi

	if ! validate_candidate "$WORKTREE_PATH" "$editable_file" "$max_changed_lines" "$TASK_DEFINITION_ROOT" \
		> "$TASK_RUN_ROOT/validation.log" 2>&1; then
		echo "[$task_id] static validation failed; preserving worktree"
		record_result "$task_id" "VALIDATION_FAILED" "$BRANCH_NAME" "-" "$WORKTREE_PATH" "$LOG_PATH"
		continue
	fi

	git -C "$WORKTREE_PATH" add -- "$editable_file"
	git -C "$WORKTREE_PATH" commit -m "$commit_message" > "$TASK_RUN_ROOT/commit.log" 2>&1
	CANDIDATE_COMMIT="$(git -C "$WORKTREE_PATH" rev-parse HEAD)"
	record_result "$task_id" "PASS" "$BRANCH_NAME" "$CANDIDATE_COMMIT" "$WORKTREE_PATH" "$LOG_PATH"
	echo "[$task_id] accepted as candidate commit $CANDIDATE_COMMIT"
done < "$QUEUE_FILE"

printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$RUN_ROOT/queue_finished_at.txt"
echo "Queue finished. Review: $RUN_ROOT/summary.tsv"
