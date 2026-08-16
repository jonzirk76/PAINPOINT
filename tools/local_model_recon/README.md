# Test rehabilitation reconnaissance

This directory contains report-only planning evidence for the proposed
`test_rehabilitation_01` campaign. It is deliberately separate from production
code, scenes, resources, and `tests/` so review can decide the next maintenance
change before any test contract is edited.

## Boundary

The recon script reads `tests/smoke_tests.gd` and, when available,
`.smoke-test-runtime/smoke.log`. It never invokes Godot, local models, the smoke
runner, or any write outside this directory. Its default modes write no files.
It does not decide whether a runtime error is a production defect: it groups the
evidence so a human reviewer can make that decision.

The current packet is [test_rehabilitation_01.md](test_rehabilitation_01.md).

## Human workflow

1. Run `python3 tools/local_model_recon/recon_report.py --check` to verify the
   packet and its source anchors still agree.
2. Run `python3 tools/local_model_recon/recon_report.py --report` to obtain a
   compact, deterministic evidence summary from the current test source and any
   preserved smoke log.
3. Have a planning manager classify each item as harness, stale test contract,
   or production defect before assigning implementation work.
4. Implement one approved wave on an isolated candidate branch. Do not merge or
   promote from this reconnaissance packet.
5. A human runs the approved targeted test command and records the result in a
   future review artifact; this tool intentionally does not run it.

No generated files are required. The checked-in plan is the reviewable,
versioned record; console output is suitable for attaching to an issue or review.
