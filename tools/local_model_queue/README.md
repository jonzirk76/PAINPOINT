# Local Model Overnight Queue

This pilot gives Aider and a local Ollama model five independent, narrowly
specified edits. It never edits or merges `main`. Every task starts from the
same base commit in its own Git branch and worktree.

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

Read the run summary:

```bash
column -ts $'\t' .local-model-runs/<run-id>/summary.tsv
```

Inspect an accepted candidate:

```bash
git show --stat local-model/<run-id>/<task-id>
git show local-model/<run-id>/<task-id>
```

After review, bring an accepted candidate onto the experiment branch with its
commit hash:

```bash
git cherry-pick <candidate-commit>
```

Do not merge the candidate branches wholesale: all five branches share the
same base and are intended to be reviewed and cherry-picked independently.
No Godot or smoke tests are run by this pilot.
