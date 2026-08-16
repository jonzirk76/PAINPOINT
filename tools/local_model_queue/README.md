# Local Model Maintenance Queue — Stage 1

This is the Stage 1 implementation of the
[`autonomous maintenance workplan`](../../docs/autonomous_maintenance_workplan.md).
It gives Aider and a local Ollama model independent, narrowly specified edits.
It never edits or merges `main`. Every task starts from the same base commit in
its own Git branch and worktree.

The runner accepts a candidate only when all static gates pass:

- Aider exits successfully.
- Exactly the permitted file changed.
- The required replacement line exists exactly.
- The original line is gone.
- The diff contains no whitespace errors.
- The total inserted-plus-deleted line count stays within the task budget.

Accepted candidates are committed to `local-model/<run-id>/<task-id>` branches.
Nothing is merged automatically. Failed and interrupted worktrees are also
left intact for review.

Each new run snapshots its queue and task definitions under the ignored run
directory. This preserves the exact plan used even after the tracked queue is
changed for a later run.

## Before leaving it unattended

From the repository root, confirm that Ollama can see the model and preview the
queue without changing anything:

```bash
ollama show qwen2.5-coder:7b
./tools/local_model_queue/run_queue.sh --dry-run
```

The runner requires a clean tracked worktree so every candidate has an
unambiguous base commit. Ignored run artifacts do not count as changes.

## Run in tmux

Use `tmux` so closing the terminal or losing the desktop session does not stop
the queue:

```bash
tmux new-session -s shooty-qwen
./tools/local_model_queue/run_queue.sh
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

The default per-task timeout is 45 minutes. It can also be overridden:

```bash
OVERNIGHT_TASK_TIMEOUT_MINUTES=60 \
  ./tools/local_model_queue/run_queue.sh
```

## Resume after an interruption

Each run prints its run ID and stores records under `.local-model-runs/<run-id>`.
To continue the unstarted portion of an interrupted queue:

```bash
./tools/local_model_queue/run_queue.sh --resume <run-id>
```

Completed tasks are skipped. If a task had started but did not record a final
result, its existing worktree is preserved and marked `INTERRUPTED`; the runner
continues with the remaining tasks instead of overwriting uncertain work.

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
