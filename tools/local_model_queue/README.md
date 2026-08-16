# Local Model Maintenance Queue — Stage 1

This is the Stage 1 implementation of the
[`autonomous maintenance workplan`](../../docs/autonomous_maintenance_workplan.md).
It gives Aider and a local Ollama model independent, narrowly specified edits.
It never edits or merges `main`. Every task starts from the same base commit in
its own Git branch and worktree.

The runner accepts a candidate only when all static gates pass:

- Aider exits successfully.
- The editable source is within the configured worker-size ceiling.
- Exactly the permitted file changed.
- The required replacement line exists exactly.
- The original line is gone.
- The diff contains no whitespace errors.
- The total inserted-plus-deleted line count stays within the task budget.

Accepted candidates are committed to `local-model/<run-id>/<task-id>` branches.
Nothing is merged automatically. Failed and interrupted worktrees are also
left intact for review.

Each new run snapshots its queue, task definitions, edit format, request and
task timeouts, and source-size ceiling under the ignored run directory. This
preserves the exact plan and worker envelope used even after the tracked queue
or defaults change for a later run.

## Worker feasibility gate

The current GTX 1080 / Qwen 2.5 Coder 7B worker uses streamed `udiff` edits and
accepts source files no larger than 24,000 bytes by default. Aider includes the
entire editable file in model context even when the repository map is disabled.
Whole-file edit mode also requires the model to regenerate that complete file,
which caused a 1,053-line task to exceed LiteLLM's 600-second request timeout.

Planning managers must treat the worker envelope as an input constraint, not a
post-run optimization. Before proposing a task, they must verify the source size
at the intended base commit. Oversized work belongs in one of these lanes:

- a deterministic exact-replacement tool when no model judgment is required;
- a refactor proposal that first establishes a smaller ownership boundary;
- a stronger worker profile with its own measured file/context ceiling; or
- principal review when the change cannot be bounded cheaply.

Do not raise the ceiling merely to make a proposal pass. Change it only after a
measured calibration run establishes acceptable latency, candidate quality, and
review cost for that model, hardware, edit format, and task class.

## Before leaving it unattended

From the repository root, confirm that Ollama can see the model and preview the
queue without changing anything:

```bash
ollama show qwen2.5-coder:7b
./tools/local_model_queue/run_queue.sh --dry-run
```

The runner requires a clean tracked worktree so every candidate has an
unambiguous base commit. Ignored run artifacts do not count as changes.

## Versioned planner proposals

A weaker planning model may organize a proposed plan under:

```text
tools/local_model_queue/proposals/<plan-id>/queue.tsv
tools/local_model_queue/proposals/<plan-id>/tasks/<task-id>/prompt.md
tools/local_model_queue/proposals/<plan-id>/tasks/<task-id>/required_lines.txt
tools/local_model_queue/proposals/<plan-id>/tasks/<task-id>/forbidden_lines.txt
```

Writing or committing a proposal never starts a worker. Preview a selected plan
with:

```bash
./tools/local_model_queue/run_queue.sh --plan <plan-id> --dry-run
```

The dry run validates task IDs, unique queue entries, repository-relative source
paths, source files at the base commit, complete task-definition files, exact
forbidden-line occurrence, absence of required replacement lines, and matching
replacement/diff budgets. Both a normal TSV header and the original commented
header are accepted.

Only the user deploys a reviewed plan by omitting `--dry-run`:

```bash
./tools/local_model_queue/run_queue.sh --plan <plan-id>
```

The selected plan ID and complete plan snapshot are recorded with the run.
Resuming a run always uses that snapshot, even if the tracked proposal changes.

## Run in tmux

Use `tmux` so closing the terminal or losing the desktop session does not stop
the queue:

```bash
tmux new-session -s shooty-qwen
./tools/local_model_queue/run_queue.sh --plan <plan-id>
```

Detach with `Ctrl-b`, then `d`. Reattach later with:

```bash
tmux attach-session -t shooty-qwen
```

The default model is `qwen2.5-coder:7b`. Override it without editing files:

```bash
OVERNIGHT_MODEL=qwen2.5-coder:7b-instruct-q5_K_M \
  ./tools/local_model_queue/run_queue.sh
```

The default per-task timeout is 15 minutes. It can also be overridden:

```bash
OVERNIGHT_TASK_TIMEOUT_MINUTES=20 \
  ./tools/local_model_queue/run_queue.sh
```

The streamed edit format, API-request timeout, and source-size ceiling are also
explicit worker settings:

```bash
OVERNIGHT_EDIT_FORMAT=udiff \
OVERNIGHT_AIDER_API_TIMEOUT_SECONDS=300 \
OVERNIGHT_MAX_SOURCE_BYTES=24000 \
OVERNIGHT_REQUIRE_CANARY_PASS=true \
  ./tools/local_model_queue/run_queue.sh --plan <plan-id> --dry-run
```

The outer task timeout remains the final unattended bound if Aider retries a
failed API request. Streaming keeps an active response observable, while
`udiff` avoids requiring the local model to reproduce an entire source file.
The first queued task is a canary by default: if it does not pass every gate,
the queue stops before starting larger tasks.

## Resume after an interruption

Each run prints its run ID and stores records under `.local-model-runs/<run-id>`.
To continue the unstarted portion of an interrupted queue:

```bash
./tools/local_model_queue/run_queue.sh --resume <run-id>
```

Completed tasks are skipped. If a task had started but did not record a final
result, its existing worktree is preserved and marked `INTERRUPTED`; the runner
continues with the remaining tasks instead of overwriting uncertain work. New
runs also snapshot their worker settings, and resumes reuse those settings.
Historical runs created before worker-setting snapshots use current defaults and
may be rejected by newer safety gates; start a revised plan rather than weakening
the gate.

## Morning review

List runs and produce a metric report:

```bash
./tools/local_model_queue/maintenancectl.py runs
./tools/local_model_queue/maintenancectl.py report <run-id>
```

Inspect one candidate and its validation output:

```bash
./tools/local_model_queue/maintenancectl.py show <run-id> <task-id>
```

Record the user's final review decision and review time:

```bash
./tools/local_model_queue/maintenancectl.py review \
  <run-id> <task-id> accept \
  --minutes 2.5 \
  --reason "Exact bounded refactor"
```

Rejecting a candidate is equally explicit:

```bash
./tools/local_model_queue/maintenancectl.py review \
  <run-id> <task-id> reject \
  --minutes 1.0 \
  --reason "Unrelated behavioral edit"
```

An accepted candidate can be integrated only from a clean non-`main` branch.
The user must supply both `--apply` and the exact full candidate commit:

```bash
./tools/local_model_queue/maintenancectl.py integrate \
  <run-id> <task-id> \
  --confirm <full-candidate-commit> \
  --apply
```

The command verifies the human accept record, run base, candidate parent,
stored diff, current branch, and clean patch application before cherry-picking.
It refuses direct Stage 1 integration into `main` or `master`.

After separately authorized validation or user evaluation, record the outcome:

```bash
./tools/local_model_queue/maintenancectl.py outcome \
  <run-id> <task-id> verified \
  --reason "Targeted validation and review passed"
```

Check whether measured evidence is sufficient for a stage-promotion review:

```bash
./tools/local_model_queue/maintenancectl.py readiness
```

Do not merge candidate branches wholesale: tasks share a base and are intended
to be reviewed and integrated independently. The queue and control CLI never
run Godot or smoke tests automatically.
