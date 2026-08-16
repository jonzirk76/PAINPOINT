# Stage 1 Run 3 proposal

This revision contains seven tasks that fit the provisional Qwen 2.5 Coder 7B
worker envelope: one file per task, no source larger than 24,000 bytes, streamed
`udiff`, a 300-second API timeout, and a 15-minute outer timeout.
The 3,556-byte destructible-manager task runs first as the worker-envelope
canary. The queue stops if it does not pass; otherwise, the remaining tasks
proceed in generally increasing source-size order.

The first deployment attempt (`20260816T203657Z`) used the earlier 12-task
snapshot and was stopped during task 1. Aider's whole-file format sent the full
1,053-line `enemy_manager.gd`, required the model to reproduce it, reached a
23,812-token context, and timed out inside LiteLLM after 600 seconds before
retrying the same request. The run snapshot remains the authoritative record of
that attempt.

The following proposal tasks were removed from the deployable queue because
their editable sources exceed the new ceiling:

| Former task | Source bytes | Disposition |
| --- | ---: | --- |
| `01_type_enemy_collection` | 46,155 | Deterministic replacement or smaller worker scope |
| `05_type_wall_top_overlay` | 27,060 | Reconsider after measured ceiling calibration |
| `07_type_current_room_level` | 87,527 | Deterministic replacement or decomposition |
| `08_type_room_interior_generate` | 62,615 | Deterministic replacement or decomposition |
| `12_type_weighted_encounter_entry` | 244,194 | Principal/decomposition lane only |

Removing a task from this queue does not reject the maintenance idea. It rejects
the mismatch between that task representation and this worker profile.
