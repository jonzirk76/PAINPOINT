# Usage Policy Calibration

This document is a living guide for estimating and improving Codex task cost in this repository. Codex cannot see the user's actual weekly token percentage or selected reasoning level, so calibration depends on user-reported weekly usage changes.

## Goals

- Make task cost visible before work starts.
- Reduce pressure to spend the weekly reset early.
- Help future agents learn which repo operations are cheap, expensive, or likely to snowball.
- Route token-heavy but human-friendly work back to the user unless the user explicitly overrides.
- Keep `AGENTS.md` short while allowing this policy to grow over time.

## Handoff Reminder

After each non-trivial handoff, ask the user for optional usage feedback in a short form:

```text
Optional calibration:
Time:
Reasoning level:
Weekly usage after:
```

If the user provides the data, compare it against the agent's pre-task estimate and any known weekly before-state data to infer whether the task was cheaper, as expected, or more expensive than expected. Do not ask the user to classify the task cost manually unless more context is needed. Do not imply that Codex can see or verify the percentage.

## Before-State Gating

Before-state weekly usage is most valuable when collected before compute is spent. For potentially compute-heavy tasks, it is acceptable to pause before implementation and ask the user for the current weekly percentage if they have not provided it.

Use this gate for tasks estimated High or Very High, tasks with High snowball risk, or tasks likely to involve repeated tests, broad searches, large logs, asset iteration, scene editing, or exploratory debugging. Continue once the user provides the before-state data or explicitly asks to proceed without calibration.

## Pre-Task Estimate Format

For non-trivial work, provide a short estimate before implementation:

```text
Estimated Agent Cost: Low / Medium / High / Very High
Snowball Risk: Low / Medium / High
Suggested Mode: implement now / plan first / user gathers info / defer
Test Policy: none / targeted only / user-run smoke / full smoke with permission
```

Keep the estimate brief. The estimate is meant to guide budget decisions, not become a planning ritual for tiny edits.

## Cost Bands

- Low: documentation edits, small helper scripts, known-file changes, small tuning changes, targeted reviews, or applying a concrete user-provided plan.
- Medium: one-system gameplay changes, limited UI logic, small test updates, or a bounded bug fix with a clear failure.
- High: multi-file feature work, cross-system debugging, scene/resource wiring, new manager/entity flows, or changes that need careful architecture review.
- Very High: broad refactors, exploratory debugging, repeated test loops, large Godot scene edits, asset/SVG iteration, whole-repo audits, or tasks where the correct approach is not yet known.

## Snowball Risk

Mark snowball risk higher when a task may require any of the following:

- repeated Godot launches or smoke-test loops,
- uncertain scene/node ownership,
- large logs or broad searches,
- generated metadata or import churn,
- visual tuning without screenshots or user playtest feedback,
- multiple possible architecture directions,
- unclear acceptance criteria,
- user-facing feel or polish that needs iteration.

When snowball risk is high, suggest a cheaper first step: a design pass, a targeted inspection, manual user evidence gathering, or one bounded implementation attempt.

## Budget State Guidance

If the user reports the weekly budget is low, prefer:

- planning,
- code review,
- architecture notes,
- short log triage,
- manual Godot editor instructions,
- branch/status summaries,
- small isolated edits,
- asking the user to run `./smoke_test.sh`.

Be conservative with broad exploratory work when weekly usage is low unless the user overrides.

If the user is considering using the weekly reset, neutrally remind them that delaying the reset generally replenishes more total budget. Offer a smaller next step that preserves the reset.

## Human-Friendly Work

Prefer user-performed or design-tool work for tasks that are expensive for Codex but not laborious for a human operator:

- Godot inspector tuning,
- Control layout and anchors,
- portrait circular clipping,
- import settings,
- screenshots and playtest notes,
- selecting among visual mockups,
- SVG/icon exploration,
- sprite, portrait, or VFX concept iteration.

Codex should usually provide architecture, scene hierarchy, signal/data flow, exported tuning fields, scripts, validators, and exact manual steps for these tasks.

## Local Model Delegation

The user may have access to a weaker local coding model such as Qwen 2.5 Coder. Use local-model delegation to reduce Codex token spend when the task can be bounded and checked cheaply.

During handoffs for Medium, High, Very High, or high-snowball tasks, include delegation suggestions when useful. Each suggestion should include a ready-to-copy prompt that the user can run locally. Do not require delegation for urgent work, tiny edits, or tasks where local-model output would be harder to verify than doing the work directly.

Good delegation targets:

- summarize one file, script, or function,
- extract signals, exported variables, node paths, TODOs, or error locations,
- turn a plan into a checklist,
- run `./smoke_test.sh`, collect the capped output, and summarize whether it passed or failed,
- condense a short log excerpt,
- draft markdown notes, changelogs, or manual Godot editor instructions,
- compare two short snippets for obvious behavioral differences,
- inventory scene/resource references from a provided excerpt.

Avoid delegating:

- architecture decisions,
- final patches that affect core gameplay behavior,
- merge conflict resolution,
- cross-system debugging,
- scene/resource edits,
- gameplay feel tuning,
- test design for important invariants,
- tasks requiring broad repository context.

Smoke testing is a good trial delegation task when the user has a local model/operator loop available. The local model may run `./smoke_test.sh`, wait for completion, save or locate `/tmp/shooty-smoke.log`, report pass/fail, extract major errors, and summarize the relevant failure lines. It should not make fixes, rerun repeatedly, edit files, or interpret gameplay correctness. Codex should use the summarized result as input, then decide the next engineering step.

Use this prompt shape:

```text
You are helping preprocess information for a Godot 4 GDScript project.
Task:
[specific bounded task]

Constraints:
- Use only the pasted content.
- Do not invent files, APIs, or project context.
- Return concise bullets.
- If uncertain, say what is missing.

Content:
[paste file excerpt, log excerpt, or plan]
```

Example local-model prompts:

```text
Summarize responsibilities:
You are helping preprocess information for a Godot 4 GDScript project.
Task:
Summarize this script's responsibilities in 8 bullets or fewer. List emitted signals, connected signals, and exported variables separately.

Constraints:
- Use only the pasted content.
- Do not infer architecture beyond this file.
- If a responsibility is unclear, mark it as uncertain.

Content:
[paste script]
```

```text
Condense failure log:
You are helping preprocess a Godot smoke-test failure.
Task:
Extract only the relevant error lines, file paths, line numbers, and likely failing subsystem from this log excerpt.

Constraints:
- Use only the pasted log.
- Do not suggest fixes unless the cause is explicit.
- Keep the output under 20 bullets.

Content:
[paste 100-300 relevant log lines]
```

```text
Run delegated smoke test:
You are acting as a local test runner for a Godot 4 GDScript project.
Task:
Run ./smoke_test.sh from the repository root. Wait for it to finish. Report whether it passed or failed. If it failed, locate /tmp/shooty-smoke.log and summarize only the most relevant error lines, file paths, line numbers, and failing subsystem.

Constraints:
- Do not edit files.
- Do not rerun the test unless explicitly asked.
- Do not propose broad fixes.
- Do not paste the full log.
- Keep the result concise.

Return:
- Command run:
- Pass/fail:
- Exit code:
- Relevant errors:
- Log path:
```

```text
Create implementation checklist:
You are helping turn a feature plan into a checklist for a Godot 4 GDScript project.
Task:
Convert this plan into a concise implementation checklist grouped by likely file or system.

Constraints:
- Do not add new requirements.
- Mark any unclear item as a question.
- Keep the checklist actionable and short.

Content:
[paste plan]
```

## Calibration Notes

Add concrete observations here when the user reports useful before/after data.

| Task Type | Estimate | Reported Usage Change | Notes |
| --- | --- | --- | --- |
| Agent guardrail documentation edits | Low | Unknown | Doc-only changes were cheap enough to do directly; no tests needed. |
| Usage calibration documentation edits | Low | Below 1% total reported change | Done at medium reasoning; confirms small doc/schema updates are negligible-cost tasks. |
| Before-state gating documentation edit | Low | Weekly 3% | Weekly budget was very low, but the task was a small doc-only update and appropriate to proceed. |
| Legacy handoff schema edit | Low | Weekly 3% | Historical short-window reporting was removed after that limit stopped applying. |
| Legacy usage-block documentation edit | Low | Weekly 2% -> 2% | Historical short-window reporting was removed; no weekly percentage movement was observed. |
| Local-model delegation policy edit | Low | Weekly around 2%, meters unreliable | User requested handoff delegation suggestions and ready-to-copy Qwen prompts to reduce Codex token spend. |
| Legacy reset-aware schema update | Low | Time 4:03 AM, medium reasoning, weekly 99% | Historical reset fields were later removed in favor of weekly-usage-only reporting. |
| Delegated smoke-test policy edit | Low | Unknown | Added Qwen/local-model smoke-test runner guidance; local model may run and summarize tests, but not fix or rerun repeatedly. |
| Parry chain feature overhaul | High | Unknown | Multi-system gameplay/UI/stat work; should remain high-cost unless scoped tightly. |
| SVG/visual asset iteration | High to Very High | User reported it felt token-hungry | Prefer user/design-tool iteration, then Codex wiring. |
