# Autonomous Maintenance Workplan

Status: Stage 1 active on `Local-Model-Testing`  
Current stage: single repository, one local worker, quarantined candidates  
Promotion authority: the user only  
Machine-readable stage policy: `tools/local_model_queue/stage.json`

## Purpose

Build a reusable maintenance control plane in which:

- the user owns product vision and final authority;
- a principal cloud model owns architectural continuity, major-feature work,
  work-policy design, and exception review;
- a weaker cloud planning model organizes maintenance proposals and work plans;
- deterministic software validates, schedules, leases, and records work;
- local models produce bounded candidate artifacts during inactive periods;
- no model can deploy a work plan or integrate a candidate merely because it
  generated or approved it.

This system is separate from the game's runtime architecture. The eventual
database is an operations control plane across repositories, not a gameplay
database.

## Non-Negotiable Boundaries

1. The repository remains authoritative for code, tests, architecture documents,
   and accepted invariants.
2. Operational records distinguish observations, proposals, validations,
   reviews, integrations, and verified outcomes.
3. Models never silently convert observations into accepted facts.
4. Work executes in isolated branches and worktrees.
5. Stable branches never receive fleet changes automatically.
6. Promotion is granted to a model + task class + prompt + validator combination,
   never to a model globally.
7. Metrics may trigger a promotion review, but only the user can approve the
   next stage.
8. Idle compute is not itself a goal. Expected maintenance value must exceed
   expected compute, review, and regression costs.

## Operating Modes

### Active mode

The user and principal are developing or reviewing the repository. Fleet work
is proposal-only unless the user explicitly starts a bounded run. Workers may
inventory, classify, and prepare work orders, but must not compete with active
feature edits.

### Inactive mode

An approved work plan may execute through quarantined workers. Each task has
explicit files, limits, validation, timeout, and provenance. Results become
candidate commits or rejected artifacts; they do not enter the active branch.

### Review mode

The principal condenses results and highlights exceptions. The user records the
final accept/reject decision. Accepted candidates may be integrated only through
an explicit terminal or future control-panel action.

## Principal Session Memory Protocol

At the beginning of autonomous-maintenance planning or review, the principal
must:

1. Read this workplan and `tools/local_model_queue/stage.json`.
2. Run `./tools/local_model_queue/maintenancectl.py readiness`.
3. Continue within the current stage's authority.
4. If the command reports `READY_FOR_PROMOTION_REVIEW`, tell the user that the
   evidence threshold has been reached and summarize remaining qualitative
   risks.
5. Never edit the current stage or grant new authority without explicit user
   approval.

After a run, review, integration, or verified outcome, run the readiness command
again. This makes the escalation reminder repository-resident rather than
dependent on conversational memory.

## Measurement Vocabulary

- **Attempted task:** a task with a terminal queue result.
- **Passed candidate:** a task that satisfied all deterministic candidate gates.
- **Candidate pass rate:** passed candidates divided by attempted tasks.
- **Review coverage:** passed candidates with a recorded human review divided by
  all passed candidates.
- **Successful integration:** an accepted candidate explicitly applied to a
  non-protected branch.
- **Verified integration:** an integration later recorded as verified after
  authorized validation or user evaluation.
- **Escaped defect:** an integrated candidate later recorded as defective.
- **Revert:** an integrated candidate that had to be removed.
- **Review cost:** human minutes used to accept or reject candidates.
- **Task class:** a bounded category with a shared capability contract, such as
  `mechanical_typing`; it is not merely a descriptive label.

Raw commits, changed lines, queue depth, and GPU utilization are diagnostic
measurements, not success measurements.

## Stage 1 — Single-Repository Quarantine

Status: **active**

### Scope

- One repository.
- One local worker at a time.
- Tracked, principal-authored work orders.
- Independent branch and worktree per task.
- Deterministic file, line-budget, required-line, forbidden-line, whitespace,
  and untracked-file gates.
- Candidate commits only after gates pass.
- Terminal-based human review and integration.
- File-backed run evidence, ready for later database import.
- Versioned proposal directories selected only by an explicit user terminal
  command.

The weaker cloud planner has no execution authority in this stage. It may
organize proposed `queue.tsv` rows and bounded task-definition files on the
maintenance branch. The principal reviews novel task classes and validators,
and the user deploys the reviewed plan with
`run_queue.sh --plan <plan-id>`. Merely selecting `--dry-run` performs structural
and exact-line preflight without starting a worker. The user starts execution by
running the same command without `--dry-run`.
Merely writing or committing plan data never starts a worker.

### Stage 1 promotion gate

Promotion target: Stage 2, persistent control-plane database.

| Metric | Required |
| --- | ---: |
| Completed unattended runs | at least 3 |
| Attempted tasks | at least 15 |
| Distinct task classes | at least 2 |
| Candidate pass rate | at least 75% |
| Passed-candidate human review coverage | at least 90% |
| Integrated candidates with recorded outcomes | 100% |
| Verified integrations | at least 8 |
| Median review time | at most 5 minutes per reviewed task |
| Escaped defects plus reverts | 0 |

These thresholds are mirrored in `stage.json` and evaluated by
`maintenancectl.py readiness`.

### Stage 1 baseline

Run `20260816T112013Z` attempted five `mechanical_typing` tasks. Four passed
exact candidate validation and one was rejected for an unrelated behavioral
change in an 809-line file. Candidate pass rate was 80%, total elapsed time was
about 26 minutes, and the validator prevented the unsafe change from becoming a
candidate commit. Human reviews and verified integrations were not yet recorded
through the Stage 1 control surface.

### Escalation message

When all Stage 1 metrics pass, the principal should tell the user:

> Stage 1 has enough measured evidence for a Stage 2 design review. The fleet
> remains quarantined until you explicitly approve database implementation and
> migration.

## Stage 2 — Persistent Evidence Database

### Scope

- Introduce SQLite as the single-host control-plane database.
- Import file-backed Stage 1 runs without deleting their original artifacts.
- Store repositories, snapshots, work items, work orders, runs, artifacts,
  validations, reviews, integrations, outcomes, models, and policy versions.
- Use append-only events for historical decisions; corrections supersede rather
  than erase records.
- Expose mediated write operations instead of unrestricted model SQL.

The principal may record friction observations and proposed decisions. Only
explicit human actions may mark policy or deployment records as approved.

### Promotion metrics to Stage 3

| Metric | Required |
| --- | ---: |
| Stage 1 artifact import coverage | 100% |
| New runs with complete provenance | 100% across at least 10 runs |
| Database/artifact reconciliation mismatches | 0 |
| Successful backup-and-restore drills | at least 2 |
| Invalid or unauthorized write requests rejected | 100% in policy checks |
| Median run-report query latency on one host | under 1 second |
| Lost review or outcome records | 0 |

Escalate when the database has become a trustworthy evidence store, not merely
when its schema exists.

## Stage 3 — Deterministic Scheduler And Plan Approval

### Scope

- Add structured proposed work plans.
- Add explicit human `approve-plan` and `reject-plan` terminal commands.
- Add task dependencies, leases, timeouts, resource budgets, and stale-commit
  rejection.
- Keep scheduling, permissions, and retries deterministic.
- Permit the weaker cloud planner to organize proposals, never to approve its
  own plan.

### Promotion metrics to Stage 4

| Metric | Required |
| --- | ---: |
| Approved plans executed | at least 10 |
| Duplicate task execution caused by lease failure | 0 |
| Tasks executed from stale or unapproved plans | 0 |
| Interrupted-worker recovery drills | at least 3 successful |
| Policy-limit enforcement | 100% |
| Median human plan-deployment time | under 5 minutes |
| Scheduler-created repository conflicts | 0 |

At this gate, recommend enabling the weaker cloud planner for supervised daily
use, while retaining daily review.

## Stage 4 — Supervised Cloud Planning

### Scope

- The weaker cloud model inventories maintenance friction, groups work, estimates
  value and validation cost, and drafts structured plans.
- The principal reviews novel task classes and validator changes.
- The user deploys plans through the terminal.
- Daily review remains mandatory.

### Promotion metrics to Stage 5

Measure over at least four consecutive weeks:

| Metric | Required |
| --- | ---: |
| Planner-proposed tasks | at least 50 |
| Plans requiring principal structural rewrite | at most 20% |
| Executed candidate pass rate | at least 75% |
| Passed candidates accepted after review | at least 70% |
| Unauthorized executions or integrations | 0 |
| Escaped-defect rate | under 1% |
| Median daily review burden | under 15 minutes |

Escalation means considering weekly review, not immediately enabling it.

## Stage 5 — Weekly Oversight

### Scope

- Known task classes may execute during approved inactive windows.
- Daily reports are generated automatically but reviewed only when policy raises
  an exception.
- The user and principal conduct a weekly portfolio review.
- Stable-branch integration remains human-controlled.

### Promotion metrics to Stage 6

Measure over at least eight consecutive weeks and 200 attempted tasks:

| Metric | Required |
| --- | ---: |
| Weekly review burden | under 30 minutes |
| Candidate pass rate for promoted task classes | at least 85% |
| Escaped-defect rate | under 1% |
| Revert rate | under 2% |
| Tasks violating file, command, or resource policy | 0 |
| Emergency-stop drill | successful monthly |
| Principal exception-review rate | under 10% of tasks |

At this gate, recommend a multi-host design review.

## Stage 6 — Multi-Host Fleet

### Scope

- Move the coordination store to PostgreSQL only when concurrent hosts require
  it.
- Add worker registration, capabilities, heartbeats, leases, host resource
  limits, and artifact transfer.
- Allocate work by measured task compatibility and expected value per compute
  and review cost.

### Promotion metrics to Stage 7

| Metric | Required |
| --- | ---: |
| Continuous multi-host observation period | at least 30 days |
| Duplicate integrations | 0 |
| Expired leases recovered without manual data repair | 100% |
| Lost or unattributed artifacts | 0 |
| Host thermal/resource policy violations | 0 |
| Accepted value per compute-hour | no worse than single-host baseline |
| Review cost per verified integration | no worse than Stage 5 baseline |

## Stage 7 — Control Panel And Dashboard

### Scope

- Build the control panel over the same mediated APIs used by the CLI.
- Preserve CLI support as the recovery and automation surface.
- Add portfolio health, queues, leases, candidates, provenance, compute, policy,
  and promotion-readiness views.
- Include emergency stop, queue drain, worker revocation, and plan approval.

### Completion metrics

| Metric | Required |
| --- | ---: |
| Control-panel actions with CLI/API parity | 100% |
| Privileged actions requiring explicit confirmation | 100% |
| Audit records for privileged actions | 100% |
| Emergency-stop propagation | under 10 seconds on connected hosts |
| Dashboard/database reconciliation mismatches | 0 |
| Recovery possible without the dashboard | demonstrated |

The dashboard is an interface, not a new authority boundary.

## Task-Class Promotion Record

Each task class should eventually record:

- model and quantization;
- edit format and context limit;
- maximum file size and file count;
- prompt template version;
- required deterministic validators;
- allowed commands and network access;
- observed pass, acceptance, defect, and revert rates;
- review minutes and compute consumption;
- current trust tier and revocation conditions.

The first measured combination is:

```text
qwen2.5-coder:7b
+ Aider whole edit format
+ mechanical_typing
+ one explicitly supplied file
+ exact-line and two-line diff gates
```

The first pilot suggests keeping whole-file tasks below roughly 400–500 lines
until more evidence supports a higher limit.
