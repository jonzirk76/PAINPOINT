#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
RUNS_ROOT="$REPO_ROOT/.local-model-runs"
WORKTREES_ROOT="/tmp/shooty-local-model-worktrees"
OLLAMA_MODEL_NAME="${OVERNIGHT_MODEL:-qwen2.5-coder:7b}"
AIDER_MODEL_NAME="ollama_chat/$OLLAMA_MODEL_NAME"
TASK_TIMEOUT_MINUTES="${OVERNIGHT_TASK_TIMEOUT_MINUTES:-15}"
AIDER_API_TIMEOUT_SECONDS="${OVERNIGHT_AIDER_API_TIMEOUT_SECONDS:-300}"
AIDER_EDIT_FORMAT="${OVERNIGHT_EDIT_FORMAT:-udiff}"
MAX_SOURCE_BYTES="${OVERNIGHT_MAX_SOURCE_BYTES:-24000}"
REQUIRE_CANARY_PASS="${OVERNIGHT_REQUIRE_CANARY_PASS:-true}"
OLLAMA_API_BASE="${OLLAMA_API_BASE:-http://127.0.0.1:11434}"
export OLLAMA_API_BASE

DRY_RUN=false
RESUME_RUN_ID=""
REQUESTED_PLAN_ID=""
PLAN_ID="active_queue"
PLAN_ROOT="$SCRIPT_DIR"
QUEUE_FILE="$PLAN_ROOT/queue.tsv"
TASKS_ROOT="$PLAN_ROOT/tasks"

usage() {
	cat <<'EOF'
Usage:
  run_queue.sh [--plan PLAN_ID] [--dry-run]
  run_queue.sh [--plan PLAN_ID]
  run_queue.sh --resume RUN_ID

Environment overrides:
  OVERNIGHT_MODEL=qwen2.5-coder:7b
  OVERNIGHT_TASK_TIMEOUT_MINUTES=15
  OVERNIGHT_AIDER_API_TIMEOUT_SECONDS=300
  OVERNIGHT_EDIT_FORMAT=udiff
  OVERNIGHT_MAX_SOURCE_BYTES=24000
  OVERNIGHT_REQUIRE_CANARY_PASS=true
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
		--plan)
			if (( $# < 2 )); then
				echo "error: --plan requires a plan ID" >&2
				exit 2
			fi
			REQUESTED_PLAN_ID="$2"
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

if [[ -n "$REQUESTED_PLAN_ID" && -n "$RESUME_RUN_ID" ]]; then
	echo "error: --plan and --resume cannot be combined; resume uses the run's plan snapshot" >&2
	exit 2
fi

if [[ -n "$REQUESTED_PLAN_ID" ]]; then
	if [[ ! "$REQUESTED_PLAN_ID" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
		echo "error: plan ID contains unsupported characters: $REQUESTED_PLAN_ID" >&2
		exit 2
	fi
	PLAN_ID="$REQUESTED_PLAN_ID"
	PLAN_ROOT="$SCRIPT_DIR/proposals/$PLAN_ID"
	QUEUE_FILE="$PLAN_ROOT/queue.tsv"
	TASKS_ROOT="$PLAN_ROOT/tasks"
fi

validate_plan_definition() {
	local base_commit="$1"
	local task_id
	local task_class
	local editable_file
	local max_changed_lines
	local commit_message
	local task_definition_root
	local expected_line
	local exact_count
	local definition_file
	local forbidden_count
	local required_count
	local expected_changed_lines
	local source_bytes
	local task_count=0
	declare -A seen_task_ids=()

	if [[ ! -f "$QUEUE_FILE" || ! -d "$TASKS_ROOT" ]]; then
		echo "error: plan '$PLAN_ID' is missing queue.tsv or tasks/ under $PLAN_ROOT" >&2
		return 1
	fi

	while IFS=$'\t' read -r task_id task_class editable_file max_changed_lines commit_message; do
		[[ -z "$task_id" || "$task_id" == \#* || "$task_id" == "task_id" ]] && continue
		if [[ ! "$task_id" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
			echo "error: invalid task ID in plan '$PLAN_ID': $task_id" >&2
			return 1
		fi
		if [[ -n "${seen_task_ids[$task_id]:-}" ]]; then
			echo "error: duplicate task ID in plan '$PLAN_ID': $task_id" >&2
			return 1
		fi
		seen_task_ids[$task_id]=1
		if [[ -z "$task_class" || -z "$editable_file" || -z "$commit_message" ]]; then
			echo "error: incomplete queue row for task '$task_id'" >&2
			return 1
		fi
		if [[ ! "$max_changed_lines" =~ ^[1-9][0-9]*$ ]]; then
			echo "error: invalid changed-line budget for task '$task_id': $max_changed_lines" >&2
			return 1
		fi
		if [[ "$editable_file" == /* || "$editable_file" == *".."* ]]; then
			echo "error: editable path must be repository-relative without '..': $editable_file" >&2
			return 1
		fi
		if ! git -C "$REPO_ROOT" cat-file -e "$base_commit:$editable_file" 2>/dev/null; then
			echo "error: editable file is absent from plan base $base_commit: $editable_file" >&2
			return 1
		fi
		source_bytes="$(git -C "$REPO_ROOT" cat-file -s "$base_commit:$editable_file")"
		if (( source_bytes > MAX_SOURCE_BYTES )); then
			echo "error: task '$task_id' source is ${source_bytes} bytes, above the ${MAX_SOURCE_BYTES}-byte worker ceiling: $editable_file" >&2
			return 1
		fi

		task_definition_root="$TASKS_ROOT/$task_id"
		for definition_file in prompt.md required_lines.txt forbidden_lines.txt; do
			if [[ ! -s "$task_definition_root/$definition_file" ]]; then
				echo "error: task '$task_id' is missing non-empty $definition_file" >&2
				return 1
			fi
		done

		forbidden_count=0
		while IFS= read -r expected_line || [[ -n "$expected_line" ]]; do
			[[ -z "$expected_line" ]] && continue
			forbidden_count="$((forbidden_count + 1))"
			exact_count="$(git -C "$REPO_ROOT" show "$base_commit:$editable_file" | grep -Fxc -- "$expected_line" || true)"
			if [[ "$exact_count" -ne 1 ]]; then
				echo "error: task '$task_id' forbidden line must occur once at the plan base; found $exact_count: $expected_line" >&2
				return 1
			fi
		done < "$task_definition_root/forbidden_lines.txt"

		required_count=0
		while IFS= read -r expected_line || [[ -n "$expected_line" ]]; do
			[[ -z "$expected_line" ]] && continue
			required_count="$((required_count + 1))"
			exact_count="$(git -C "$REPO_ROOT" show "$base_commit:$editable_file" | grep -Fxc -- "$expected_line" || true)"
			if [[ "$exact_count" -ne 0 ]]; then
				echo "error: task '$task_id' required line already exists at the plan base: $expected_line" >&2
				return 1
			fi
		done < "$task_definition_root/required_lines.txt"

		expected_changed_lines="$((forbidden_count + required_count))"
		if (( forbidden_count != required_count || max_changed_lines != expected_changed_lines )); then
			echo "error: task '$task_id' must pair each forbidden line with one required line and budget their total; found $forbidden_count forbidden, $required_count required, budget $max_changed_lines" >&2
			return 1
		fi
		task_count="$((task_count + 1))"
	done < "$QUEUE_FILE"

	if (( task_count == 0 )); then
		echo "error: plan '$PLAN_ID' contains no tasks" >&2
		return 1
	fi
}

for command_name in git aider ollama timeout; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		echo "error: required command is unavailable: $command_name" >&2
		exit 1
	fi
done

validate_worker_settings() {
	if [[ ! "$TASK_TIMEOUT_MINUTES" =~ ^[1-9][0-9]*$ ]]; then
		echo "error: OVERNIGHT_TASK_TIMEOUT_MINUTES must be a positive integer" >&2
		return 1
	fi
	if [[ ! "$AIDER_API_TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
		echo "error: OVERNIGHT_AIDER_API_TIMEOUT_SECONDS must be a positive integer" >&2
		return 1
	fi
	if [[ ! "$MAX_SOURCE_BYTES" =~ ^[1-9][0-9]*$ ]]; then
		echo "error: OVERNIGHT_MAX_SOURCE_BYTES must be a positive integer" >&2
		return 1
	fi
	case "$AIDER_EDIT_FORMAT" in
		diff|diff-fenced|patch|udiff|udiff-simple|whole)
			;;
		*)
			echo "error: OVERNIGHT_EDIT_FORMAT must be a bounded file-edit format (diff, diff-fenced, patch, udiff, udiff-simple, or whole)" >&2
			return 1
			;;
	esac
	if [[ "$REQUIRE_CANARY_PASS" != "true" && "$REQUIRE_CANARY_PASS" != "false" ]]; then
		echo "error: OVERNIGHT_REQUIRE_CANARY_PASS must be true or false" >&2
		return 1
	fi
}

validate_worker_settings

if [[ -n "$(git -C "$REPO_ROOT" status --porcelain --untracked-files=no)" ]]; then
	if [[ "$DRY_RUN" == true ]]; then
		echo "warning: tracked changes exist; a real queue run would refuse to start" >&2
	else
		echo "error: tracked changes exist; commit or stash them before starting the queue" >&2
		exit 1
	fi
fi

BASE_COMMIT="$(git -C "$REPO_ROOT" rev-parse HEAD)"

if [[ "$DRY_RUN" == true ]]; then
	validate_plan_definition "$BASE_COMMIT"
	if ollama show "$OLLAMA_MODEL_NAME" >/dev/null 2>&1; then
		OLLAMA_PREFLIGHT="ready"
	else
		OLLAMA_PREFLIGHT="offline or model unavailable (required for a real run)"
	fi
	echo "Mode: dry run"
	echo "Repository: $REPO_ROOT"
	echo "Base commit: $BASE_COMMIT"
	echo "Plan: $PLAN_ID"
	echo "Plan root: $PLAN_ROOT"
	echo "Aider model: $AIDER_MODEL_NAME"
	echo "Ollama preflight: $OLLAMA_PREFLIGHT"
	echo "Per-task timeout: ${TASK_TIMEOUT_MINUTES}m"
	echo "Aider API timeout: ${AIDER_API_TIMEOUT_SECONDS}s"
	echo "Edit format: $AIDER_EDIT_FORMAT (streaming)"
	echo "Maximum source size: ${MAX_SOURCE_BYTES} bytes"
	echo "Require first-task canary pass: $REQUIRE_CANARY_PASS"
	echo "Tasks:"
	total_source_bytes=0
	largest_source_bytes=0
	largest_source_file=""
	while IFS=$'\t' read -r task_id task_class editable_file max_changed_lines commit_message; do
		[[ -z "$task_id" || "$task_id" == \#* || "$task_id" == "task_id" ]] && continue
		source_bytes="$(git -C "$REPO_ROOT" cat-file -s "$BASE_COMMIT:$editable_file")"
		total_source_bytes="$((total_source_bytes + source_bytes))"
		if (( source_bytes > largest_source_bytes )); then
			largest_source_bytes="$source_bytes"
			largest_source_file="$editable_file"
		fi
		printf '  - %s | %s | %s | %s bytes | max %s changed lines\n' \
			"$task_id" "$task_class" "$editable_file" "$source_bytes" "$max_changed_lines"
	done < "$QUEUE_FILE"
	echo "Plan source total: ${total_source_bytes} bytes"
	echo "Largest source: ${largest_source_bytes} bytes | $largest_source_file"
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
	if [[ -f "$RUN_ROOT/plan/queue.tsv" && -d "$RUN_ROOT/plan/tasks" ]]; then
		PLAN_ROOT="$RUN_ROOT/plan"
		QUEUE_FILE="$RUN_ROOT/plan/queue.tsv"
		TASKS_ROOT="$RUN_ROOT/plan/tasks"
		PLAN_ID="snapshot:$RUN_ID"
		if [[ -f "$RUN_ROOT/plan_id.txt" ]]; then
			PLAN_ID="$(<"$RUN_ROOT/plan_id.txt")"
		fi
	fi
	if [[ -f "$RUN_ROOT/task_timeout_minutes.txt" ]]; then
		TASK_TIMEOUT_MINUTES="$(<"$RUN_ROOT/task_timeout_minutes.txt")"
	fi
	if [[ -f "$RUN_ROOT/model.txt" ]]; then
		AIDER_MODEL_NAME="$(<"$RUN_ROOT/model.txt")"
		if [[ "$AIDER_MODEL_NAME" != ollama_chat/* ]]; then
			echo "error: saved run model is not an Ollama chat model: $AIDER_MODEL_NAME" >&2
			exit 1
		fi
		OLLAMA_MODEL_NAME="${AIDER_MODEL_NAME#ollama_chat/}"
	fi
	if [[ -f "$RUN_ROOT/aider_api_timeout_seconds.txt" ]]; then
		AIDER_API_TIMEOUT_SECONDS="$(<"$RUN_ROOT/aider_api_timeout_seconds.txt")"
	fi
	if [[ -f "$RUN_ROOT/edit_format.txt" ]]; then
		AIDER_EDIT_FORMAT="$(<"$RUN_ROOT/edit_format.txt")"
	fi
	if [[ -f "$RUN_ROOT/max_source_bytes.txt" ]]; then
		MAX_SOURCE_BYTES="$(<"$RUN_ROOT/max_source_bytes.txt")"
	fi
	if [[ -f "$RUN_ROOT/require_canary_pass.txt" ]]; then
		REQUIRE_CANARY_PASS="$(<"$RUN_ROOT/require_canary_pass.txt")"
	fi
	validate_worker_settings
	if ! ollama show "$OLLAMA_MODEL_NAME" >/dev/null 2>&1; then
		echo "error: Ollama cannot load '$OLLAMA_MODEL_NAME'; ensure the server is running and the model is pulled" >&2
		exit 1
	fi
	validate_plan_definition "$BASE_COMMIT"
else
	if ! ollama show "$OLLAMA_MODEL_NAME" >/dev/null 2>&1; then
		echo "error: Ollama cannot load '$OLLAMA_MODEL_NAME'; ensure the server is running and the model is pulled" >&2
		exit 1
	fi
	validate_plan_definition "$BASE_COMMIT"
	RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
	RUN_ROOT="$RUNS_ROOT/$RUN_ID"
	if [[ -e "$RUN_ROOT" ]]; then
		echo "error: generated run ID already exists: $RUN_ID" >&2
		exit 1
	fi
	mkdir -p "$RUN_ROOT/plan"
	printf '%s\n' "$BASE_COMMIT" > "$RUN_ROOT/base_commit.txt"
	printf '%s\n' "$PLAN_ID" > "$RUN_ROOT/plan_id.txt"
	printf '%s\n' "$AIDER_MODEL_NAME" > "$RUN_ROOT/model.txt"
	printf '%s\n' "$TASK_TIMEOUT_MINUTES" > "$RUN_ROOT/task_timeout_minutes.txt"
	printf '%s\n' "$AIDER_API_TIMEOUT_SECONDS" > "$RUN_ROOT/aider_api_timeout_seconds.txt"
	printf '%s\n' "$AIDER_EDIT_FORMAT" > "$RUN_ROOT/edit_format.txt"
	printf '%s\n' "$MAX_SOURCE_BYTES" > "$RUN_ROOT/max_source_bytes.txt"
	printf '%s\n' "$REQUIRE_CANARY_PASS" > "$RUN_ROOT/require_canary_pass.txt"
	date -u +%Y-%m-%dT%H:%M:%SZ > "$RUN_ROOT/run_started_at.txt"
	cp "$QUEUE_FILE" "$RUN_ROOT/plan/queue.tsv"
	cp -R "$TASKS_ROOT" "$RUN_ROOT/plan/tasks"
	printf 'task_id\ttask_class\teditable_file\tstatus\tbranch\tcommit\tworktree\tlog\tstarted_at\tfinished_at\tduration_seconds\n' \
		> "$RUN_ROOT/summary.tsv"
fi

mkdir -p "$WORKTREES_ROOT/$RUN_ID"

record_result() {
	local task_id="$1"
	local task_class="$2"
	local editable_file="$3"
	local status="$4"
	local branch_name="$5"
	local commit_hash="$6"
	local worktree_path="$7"
	local log_path="$8"
	local task_run_root="$RUN_ROOT/$task_id"
	local finished_at
	local finished_epoch
	local duration_seconds

	finished_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	finished_epoch="$(date +%s)"
	duration_seconds="$((finished_epoch - TASK_STARTED_EPOCH))"

	printf '%s\n' "$status" > "$task_run_root/status.txt"
	printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
		"$task_id" "$task_class" "$editable_file" "$status" "$branch_name" "$commit_hash" \
		"$worktree_path" "$log_path" "$TASK_STARTED_AT" "$finished_at" "$duration_seconds" \
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
echo "Plan: $PLAN_ID"
echo "Aider model: $AIDER_MODEL_NAME"
echo "Worker envelope: format=$AIDER_EDIT_FORMAT streaming=true api_timeout=${AIDER_API_TIMEOUT_SECONDS}s task_timeout=${TASK_TIMEOUT_MINUTES}m max_source_bytes=$MAX_SOURCE_BYTES require_canary_pass=$REQUIRE_CANARY_PASS"
echo "Results: $RUN_ROOT"

TASK_INDEX=0
while IFS=$'\t' read -r task_id task_class editable_file max_changed_lines commit_message; do
	[[ -z "$task_id" || "$task_id" == \#* || "$task_id" == "task_id" ]] && continue
	TASK_INDEX="$((TASK_INDEX + 1))"

	TASK_DEFINITION_ROOT="$TASKS_ROOT/$task_id"
	TASK_RUN_ROOT="$RUN_ROOT/$task_id"
	WORKTREE_PATH="$WORKTREES_ROOT/$RUN_ID/$task_id"
	BRANCH_NAME="local-model/$RUN_ID/$task_id"
	LOG_PATH="$TASK_RUN_ROOT/aider.log"
	mkdir -p "$TASK_RUN_ROOT"
	TASK_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	TASK_STARTED_EPOCH="$(date +%s)"

	if [[ -f "$TASK_RUN_ROOT/status.txt" ]]; then
		EXISTING_STATUS="$(<"$TASK_RUN_ROOT/status.txt")"
		if [[ "$EXISTING_STATUS" != "RUNNING" ]]; then
			echo "[$task_id] already recorded as $EXISTING_STATUS; skipping"
			continue
		fi
	fi

	if [[ -e "$WORKTREE_PATH" ]] || git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
		echo "[$task_id] preserving an existing incomplete branch/worktree"
		record_result "$task_id" "$task_class" "$editable_file" "INTERRUPTED" "$BRANCH_NAME" "-" "$WORKTREE_PATH" "$LOG_PATH"
		if (( TASK_INDEX == 1 )) && [[ "$REQUIRE_CANARY_PASS" == "true" ]]; then
			echo "[$task_id] canary did not pass; stopping queue before larger tasks"
			break
		fi
		continue
	fi

	if [[ ! -f "$TASK_DEFINITION_ROOT/prompt.md" || ! -f "$TASK_DEFINITION_ROOT/required_lines.txt" || ! -f "$TASK_DEFINITION_ROOT/forbidden_lines.txt" ]]; then
		echo "[$task_id] task definition is incomplete" >&2
		record_result "$task_id" "$task_class" "$editable_file" "CONFIG_ERROR" "$BRANCH_NAME" "-" "$WORKTREE_PATH" "$LOG_PATH"
		if (( TASK_INDEX == 1 )) && [[ "$REQUIRE_CANARY_PASS" == "true" ]]; then
			echo "[$task_id] canary did not pass; stopping queue before larger tasks"
			break
		fi
		continue
	fi

	if [[ ! -f "$REPO_ROOT/$editable_file" ]]; then
		echo "[$task_id] editable file does not exist: $editable_file" >&2
		record_result "$task_id" "$task_class" "$editable_file" "CONFIG_ERROR" "$BRANCH_NAME" "-" "$WORKTREE_PATH" "$LOG_PATH"
		if (( TASK_INDEX == 1 )) && [[ "$REQUIRE_CANARY_PASS" == "true" ]]; then
			echo "[$task_id] canary did not pass; stopping queue before larger tasks"
			break
		fi
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
			--timeout "$AIDER_API_TIMEOUT_SECONDS" \
			--edit-format "$AIDER_EDIT_FORMAT" \
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
			--stream \
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
		record_result "$task_id" "$task_class" "$editable_file" "AIDER_FAILED" "$BRANCH_NAME" "-" "$WORKTREE_PATH" "$LOG_PATH"
		if (( TASK_INDEX == 1 )) && [[ "$REQUIRE_CANARY_PASS" == "true" ]]; then
			echo "[$task_id] canary did not pass; stopping queue before larger tasks"
			break
		fi
		continue
	fi

	if ! validate_candidate "$WORKTREE_PATH" "$editable_file" "$max_changed_lines" "$TASK_DEFINITION_ROOT" \
		> "$TASK_RUN_ROOT/validation.log" 2>&1; then
		echo "[$task_id] static validation failed; preserving worktree"
		record_result "$task_id" "$task_class" "$editable_file" "VALIDATION_FAILED" "$BRANCH_NAME" "-" "$WORKTREE_PATH" "$LOG_PATH"
		if (( TASK_INDEX == 1 )) && [[ "$REQUIRE_CANARY_PASS" == "true" ]]; then
			echo "[$task_id] canary did not pass; stopping queue before larger tasks"
			break
		fi
		continue
	fi

	git -C "$WORKTREE_PATH" add -- "$editable_file"
	git -C "$WORKTREE_PATH" commit -m "$commit_message" > "$TASK_RUN_ROOT/commit.log" 2>&1
	CANDIDATE_COMMIT="$(git -C "$WORKTREE_PATH" rev-parse HEAD)"
	record_result "$task_id" "$task_class" "$editable_file" "PASS" "$BRANCH_NAME" "$CANDIDATE_COMMIT" "$WORKTREE_PATH" "$LOG_PATH"
	echo "[$task_id] accepted as candidate commit $CANDIDATE_COMMIT"
done < "$QUEUE_FILE"

printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$RUN_ROOT/queue_finished_at.txt"
echo "Queue finished. Review: $RUN_ROOT/summary.tsv"
