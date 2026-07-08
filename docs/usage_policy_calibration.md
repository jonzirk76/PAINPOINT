# Usage Policy Calibration

This document is a living guide for estimating and improving Codex task cost in this repository. Codex cannot see the user's actual 5h or weekly token percentages, the selected reasoning level, or reset timing, so calibration depends on user-reported budget state and before/after usage changes.

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
Reasoning level:
5h usage before -> after:
Weekly usage before -> after:
Task felt: cheaper / as expected / more expensive
Notes:
```

If the user provides the data, use it to adjust future estimates in the same conversation. Do not imply that Codex can see or verify those percentages.

## Before-State Gating

Before-state usage percentages are most valuable when collected before compute is spent. For potentially compute-heavy tasks, it is acceptable to pause before implementation and ask the user for current 5h and weekly percentages if they have not provided them.

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

If the user reports the 5h budget is low, prefer:

- planning,
- code review,
- architecture notes,
- short log triage,
- manual Godot editor instructions,
- branch/status summaries,
- small isolated edits,
- asking the user to run `./smoke_test.sh`.

If the user reports the weekly budget is low, be even more conservative and explicitly avoid broad exploratory work unless the user overrides.

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

## Calibration Notes

Add concrete observations here when the user reports useful before/after data.

| Task Type | Estimate | Reported Usage Change | Notes |
| --- | --- | --- | --- |
| Agent guardrail documentation edits | Low | Unknown | Doc-only changes were cheap enough to do directly; no tests needed. |
| Usage calibration documentation edits | Low | Below 1% total reported change | Done at medium reasoning; confirms small doc/schema updates are negligible-cost tasks. |
| Before-state gating documentation edit | Low | Before state: 5h 94%, weekly 3% | Weekly budget was very low, but the task was a small doc-only update and appropriate to proceed. |
| Parry chain feature overhaul | High | Unknown | Multi-system gameplay/UI/stat work; should remain high-cost unless scoped tightly. |
| SVG/visual asset iteration | High to Very High | User reported it felt token-hungry | Prefer user/design-tool iteration, then Codex wiring. |
