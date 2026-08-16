# test_rehabilitation_01

Status: proposed, report-only reconnaissance

## Decision summary

Repair the smoke-test signal before interpreting broad failures or changing
gameplay. The preserved full-suite attempt completed 60 of 70 registered tests
in about 900 seconds: 49 ended `PASS`, 11 ended `FAIL`, and the supplied run
evidence reported 66 explicit failure lines (the preserved log itself has 47
top-level `SCRIPT ERROR:`/`ERROR:` headers). Some errored tests were nevertheless
reported `PASS`, so the current pass count is not a reliable quality measure.

This campaign is diagnosis and test-contract repair first. A production defect
is only eligible for a separate, explicitly approved fix after a minimal valid
fixture reproduces it.

## Evidence baseline

| Evidence | Static observation | Interpretation |
| --- | --- | --- |
| Harness | `_run_smoke_test` calls a test and derives status only from appended `failures`. | Godot runtime errors can escape the failure array and produce false passes. |
| UI/orchestrator fixtures | `character_hud_visibility`, `low_ammo_bar_warning`, and other UI tests instantiate `main` then call orchestration paths; the log repeatedly reports nil-manager and detached-SceneTree errors. | First classify as fixture lifecycle/harness debt, not a gameplay regression. |
| Stale fields | The log records writes to `LevelDefinition.wall_rects`, reads of `EnemyProfile.knockback_multiplier`, and `EnemySpawnerEntity` access to `enemy_profile`. | APIs/resources have evolved; determine expected current contract before restoring fields. |
| Room geometry/interiors | `room_piece_resources` adds 11 failures; interior determinism/budget adds 24; validation adds 1. Yet `dungeon_room_interiors_persist` passes. | Separate stale geometry expectations from a possible generator/domain defect. |
| Runtime cost | Floor recipe: 146213 ms; run seed: 33587 ms; interior determinism/budget: 20754 ms; interiors persist: 13359 ms. Layout solver has a 5 floors × 60 seeds sweep after other checks and did not complete before timeout. | Bounded deterministic samples and dedicated extended coverage are required. |

Source anchors: `tests/smoke_tests.gd:290-337`, `:3120`, `:3231`, `:3313`,
`:4063`. Preserved run evidence: `.smoke-test-runtime/smoke.log`.

## Guardrails and non-goals

- Do not change gameplay, dungeon generation behavior, resources, scene layouts,
  tuning, manager ownership, or architecture to make a smoke assertion pass.
- Do not restore a removed field or compatibility alias until an approved
  contract decision identifies it as required production behavior.
- Do not make a broad layout-solver, interior-generator, or UI rewrite in this
  campaign.
- Do not treat an appended assertion failure and a Godot runtime error as the
  same class of evidence.
- Keep any future runtime execution targeted and human-approved; this packet
  neither runs Godot nor authorizes a smoke run.

## Work items

### TR01-W1 — Harness truthfulness gate

Classification: harness correctness. Priority: P0. Cost: small. Risk: low.

Scope: inspect the smoke runner's treatment of script/runtime errors and the
fixture attachment assumptions around `SceneTree`, without changing test intent.

Evidence: `cat_fauna_behavior`, `enemy_and_spawner_profiles`,
`character_hud_visibility`, `low_ammo_bar_warning`, and
`hostile_rocket_detonation_damage` log errors while some end `PASS`.

Acceptance criteria: an approved implementation makes any runtime error
unambiguously visible as an invalid test result; a minimal fixture test can
attach/detach safely; reports distinguish assertion failures, harness errors,
and unexecuted tests. Dependencies: none. Prohibition: no production guards to
mask nil fixtures.

### TR01-W2 — Fixture lifecycle and UI test contract inventory

Classification: stale fixtures/harness correctness. Priority: P0. Cost:
medium. Risk: medium.

Scope: inventory each test that instantiates `main` or calls orchestrator methods
outside normal scene lifecycle. Specify the minimum required node tree and frame
boundary for each, then replace only invalid test setup after review.

Evidence: repeated `initialize`, `set_enabled`, `reset_run`, and `process_frame`
nil errors point to detached/incomplete manager trees. `pause_menu_flow` adds 12
assertion failures after the same setup errors.

Acceptance criteria: each UI/orchestrator test has one documented fixture path;
no test reports a runtime error; UI assertions execute after valid setup.
Dependencies: TR01-W1. Prohibition: no changes to orchestrator behavior, loading
flow, or HUD layout merely to accommodate tests.

### TR01-W3 — Resource and geometry contract reconciliation

Classification: stale assertions/fixtures, with production-defect escalation
only if a valid current contract is violated. Priority: P1. Cost: medium. Risk:
medium.

Scope: map the tested `wall_rects`, `knockback_multiplier`, and `enemy_profile`
uses to current Resource APIs; separately map room-piece/interior assertions to
the documented `RoomSpatialDomain` contract.

Evidence: field-access runtime errors; `room_piece_resources` (11 failures),
interior determinism/budget (24), and interior validation (1), contrasted with
passing `dungeon_room_interiors_persist`.

Acceptance criteria: every assertion is marked retain/replace/remove with a
reason and current owner; retained geometry checks validate reachable domain,
door regions, blockers, and budgets without asserting retired representation.
Dependencies: TR01-W1; TR01-W2 for scene-backed geometry tests. Prohibition: no
restoration of removed resource fields or generator behavior changes during
contract repair.

### TR01-W4 — Deterministic budget partition

Classification: test design/performance. Priority: P1. Cost: small. Risk: low.

Scope: split deterministic core checks from long seed sweeps. Preserve known
repro seeds (116, 490, 887, 1115), use a small fixed representative seed set in
smoke, and define a separately approved extended matrix.

Evidence: floor recipe sweeps 80 seeds (146 s); layout solver sweeps 300
floor/seed pairs and exceeded the 900-second suite limit; run-seed coverage is
34 s.

Acceptance criteria: regular smoke has a documented wall-clock budget and
completes deterministically; extended coverage has explicit invocation, sample
matrix, and failure reproduction format. Dependencies: TR01-W3 for semantic
assertions. Prohibition: no random sampling, weaker invariant, or changed
dungeon algorithm used solely to reduce duration.

### TR01-W5 — Production-defect triage lane

Classification: conditional production defect. Priority: P2 until a valid
fixture and current contract reproduce it. Cost: variable. Risk: high.

Scope: create one ticket per residual failure after W1–W4, containing smallest
reproduction, expected contract owner, and evidence that it persists without a
harness/staleness issue.

Candidate clusters: tank knockback; spawner pressure/profile/rate/special
assertions; room-domain validation residuals.

Acceptance criteria: each candidate is either reclassified as test debt or
approved for a narrow production-fix branch with an ownership-aware test.
Dependencies: TR01-W1 through TR01-W4. Prohibition: no bundled gameplay fixes,
balance tuning, or architecture changes.

## Suggested review order

1. TR01-W1: harness errors invalidate all later conclusions.
2. TR01-W2: one fixture family likely resolves many false signals at once.
3. TR01-W3: reconcile APIs and the room spatial-domain contract.
4. TR01-W4: make the repaired suite bounded before a full rerun.
5. TR01-W5: isolate any genuine defect on its own approved branch.

## Remaining uncertainties

- The preserved run timed out before `dungeon_layout_solver` completed, so no
  suite-end result or failures after that point are available.
- Log errors establish invalid execution, but static evidence alone cannot say
  whether every associated assertion would fail under a valid fixture.
- The authoritative replacement for each removed field requires current owner
  review; this report intentionally does not infer a compatibility policy.
- The proposed budget should be calibrated after one human-approved targeted
  execution of repaired checks, not by changing gameplay or rerunning the full
  suite from reconnaissance.
