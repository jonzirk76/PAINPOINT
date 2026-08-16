# Repo Rules For Future Agents

This project is a Godot 4.x GDScript top-down arena shooter. Keep the architecture explicit and boring in the good way: gameplay entities signal upward, managers own entities, and the orchestrator routes between managers.

## Branch And Playable Main Workflow

- Treat `main` as the user's stable playable/test area.
- Agents should do feature work primarily on git feature branches, not directly on `main`, unless the user explicitly requests otherwise or the work is a tiny documentation-only edit.
- When a feature is requested, create a feature branch before implementation and keep that branch's commit history meaningful enough for easy tweak rollbacks.
- For broad overhaul feature sets, create one umbrella feature branch and keep related tweaks on that branch. Do not create a new branch for every small related tweak inside the same overhaul.
- When the feature is finished and ready for user testing, move the active repo checkout to that feature branch and clearly tell the user which branch contains the test build.
- If the user requests tweaks while the active checkout is a feature branch, keep working on that branch only when the tweak clearly belongs to the same feature set. Move back to `main` first when starting unrelated work, restoring the playable baseline, or when the user explicitly asks.
- Do not strand the user's active checkout on a broken or half-finished feature branch. If testing requires staying on a feature branch, say that explicitly.
- Before switching branches, check for uncommitted work and avoid overwriting user changes.
- Final summaries for feature work should include the exact git commands the user can run to merge the feature branch back into `main`.

## Agent Cost Control

- For usage-estimation, local-model delegation, and calibration rules, read `docs/usage_policy_calibration.md` before non-trivial work. After each non-trivial handoff, ask the user for optional weekly usage feedback so future estimates can improve.
- Before drafting or reviewing a local-model maintenance queue, read `docs/autonomous_maintenance_workplan.md`, plan against its current measured worker envelope, and require `run_queue.sh --dry-run` to pass. Semantic safety does not override model, context, file-size, edit-format, or timeout limits.
- Do not run tests unless the user explicitly asks for testing or grants test permission for the current task.
- When tests are allowed, prefer targeted checks first. Run the full smoke suite only before a commit/final handoff, and only when permitted.
- Avoid repeated smoke-test loops after every tiny change. If a smoke test fails, inspect the relevant failure, make one focused fix, and stop unless the user has authorized another run.
- Prefer the user-run `./smoke_test.sh` helper for full smoke coverage. Ask the user to paste only the relevant failures, not the full log.
- Avoid long Godot play-mode/editor launches. Prefer headless checks, static scene inspection, resource inspection, and small validators.
- Avoid repeated whole-repo searches. Start by reading `AGENTS.md`, `docs/architecture.md`, and targeted files; keep discoveries in the working summary instead of rediscovering them.
- Do not reason over `.import`, cache, build, export, or generated metadata unless that file is directly relevant to the user's request.
- Do not debug from huge logs. Ask for, or produce, a filtered tail of roughly 100-300 relevant lines.
- For "try things until it works" tasks, propose the likely fix, make one bounded change, and stop for user feedback.
- Split broad refactors from test-running. First refactor; then let the user test or explicitly authorize tests; then fix specific failures.
- For visual/gameplay tuning, the user is the playtester. Adjust numbers after the user describes behavior.
- If a task would be token-hungry for an agent but is straightforward for a human operator, give the user precise steps to do that part manually. The user can explicitly override this and ask the agent to do it anyway.

## Autonomous Maintenance Control Plane

- For autonomous-maintenance planning, fleet runs, candidate review, or promotion decisions, read `docs/autonomous_maintenance_workplan.md` and `tools/local_model_queue/stage.json` before acting.
- Run `./tools/local_model_queue/maintenancectl.py readiness` after a maintenance run, recorded review, integration, or verified outcome. If it reports `READY_FOR_PROMOTION_REVIEW`, inform the user that the evidence gate has been reached and summarize qualitative risks.
- Metrics trigger a promotion review only. Never change the active stage, expand worker authority, deploy a proposed work plan, or integrate a candidate without explicit user approval.
- Keep the weaker cloud planning model proposal-only until the active workplan stage explicitly grants a mediated planning role. Deterministic tooling, not a model, owns scheduling, leases, permissions, retries, and validation.
- Stage 1 candidates remain isolated branches. Agents may inspect and recommend them, but the user owns the terminal or future control-panel action that records acceptance and integrates a candidate.

## Shared Reasoning Budget Policy

- Treat reasoning level as a shared cost-control responsibility between the user and the agent. Start with the lowest reasoning level that can safely handle the task, then escalate only when the task justifies it.
- Use low or medium reasoning for small number changes, documentation edits, helper scripts, known-file fixes, UI smoke-test updates, exported tuning variables, and user-provided implementation plans.
- Use high reasoning for multi-file gameplay changes, bounded cross-system debugging, refactors inside established ownership boundaries, new signal/data-flow design, and architecture-rule reviews.
- Use max or extra-high reasoning only for major architecture redesigns, unclear ownership across managers, high-risk migrations, core combat/run-state/dungeon changes, repeated blockers after targeted inspection, or planning refactor waves.
- If the agent thinks max reasoning is needed, it should first explain why and offer a cheaper path when possible: targeted high-reasoning inspection, a narrow user-provided log/failure/screenshot, one bounded fix, or a refactor proposal.
- If routine tasks appear to require max reasoning, treat that as a possible repository-organization smell. Suggest refactor waves or stronger responsibility boundaries such as smaller scripts, clearer manager/entity ownership, Resource tuning profiles, scene validators, architecture notes, stronger signal naming, or separating combat logic from presentation.
- Prefer other tools or the human operator when they fit the task better than agentic coding at max reasoning. SVG/icon exploration, portrait art, VFX concepts, HUD mockups, sprite/texture generation, import setup, visual polish, clipping masks, and feel-tuning should usually be done by the user or a design/image-focused AI, with Codex providing architecture, scripting, wiring, validators, and inspector-exposed controls.

## Weekly Budget Strategy

- Treat the weekly reset as a scarce replenishment tool. When possible, avoid encouraging the user to spend it early just to finish a compute-heavy agent task.
- When the weekly token budget is low, prefer low-cost work: planning, code review, architecture notes, branch/status summaries, test-log triage from short pasted excerpts, writing manual editor instructions, documenting TODOs, and making small isolated edits.
- Defer token-heavy work when the weekly budget is low unless it is urgent. Heavy work includes broad feature implementation, exploratory debugging, repeated test loops, large scene edits, SVG or visual-asset iteration, whole-repo audits, and major refactors.
- Offer the user a split plan for large tasks near a low weekly budget: do a lightweight design pass now, ask the user to playtest or collect focused evidence, then implement after the weekly budget recovers or after the user explicitly chooses to use the weekly reset.
- Prefer tasks that help the user make progress without agent compute when the weekly budget is low: inspector tuning, Godot editor layout, playtesting, taking screenshots, running `./smoke_test.sh`, trimming logs, or choosing between visual mockups.
- If the user appears likely to use the weekly reset early, remind them of the tradeoff in neutral terms and suggest a cheaper next step. The user can always override and request the heavier agent work immediately.

## Godot Editor And Human Operator Boundary

- Prefer handing editor-native work to the user with exact instructions instead of scripting around the editor.
- Editor-native work includes Control layout, anchors, clipping masks, texture/import setup, portrait circular clipping, visual polish, inspector-only scene tuning, and similar node-system tasks.
- For editor-native work, propose the node architecture, scene hierarchy, key inspector values, and signal/data flow. Do not churn through script-heavy substitutes unless the user asks.
- Only script or directly edit `.tscn` scene layout when the user explicitly asks, or when the change is small, low-risk, and easier to review as text.
- Gameplay or visual values likely to need user feel-tuning should be exposed through Godot `@export` variables or Resource fields so the user can adjust them in the inspector.
- When adding or changing inspector-tunable exported properties, put a Godot doc comment immediately above the property starting with `## [Description]` so the inspector tooltip explains what the property modifies. Example:
  ```gdscript
  ## Controls how quickly the ready prompt glow pulses in the loading screen.
  @export var ready_glow_speed: float = 1.8
  ```

## Smoke Test Policy

- Smoke tests should protect architecture, required nodes, data flow, crash resistance, and core invariants.
- Avoid rigid assertions for manually tuned values such as colors, positions, dimensions, spawn rates, cooldowns, damage values, and visual timing unless the user explicitly locks those values.
- When numeric checks are needed, read configured/exported values or use broad sanity ranges instead of hard-coded tuning constants.
- Prefer small targeted validators for new behavior. Keep full smoke coverage as a final confidence check, not the default inner loop.

## Hard Architecture Rules

- Generated gameplay entities never call managers, the orchestrator, siblings, or `/root`.
- Entities communicate upward only with past-tense Godot signals such as `hit_detected`, `expired`, `collected`, `spawn_ready`, and `health_depleted`.
- Managers may call methods only on entities they own and on injected plain dependencies from `initialize(context)`.
- Managers never call other managers directly.
- `GameOrchestrator` is the only cross-manager router. It receives manager-level signals and calls manager command methods.
- Do not add gameplay Autoload singletons for the MVP. Use regular scene nodes unless a later isolated global service truly needs one.

## Project Style

- Use GDScript for gameplay.
- Use `snake_case` for files and folders.
- Use PascalCase for scene node names.
- Prefer one scene per gameplay concept.
- Prefer Resource files for tuning profiles and temporary upgrade data.
- Keep greybox visuals code-driven until real art exists.
- The game opens in level select. Do not auto-start gameplay from `_ready()`.

## Gameplay Intent

- Twin-stick movement: move with left stick/WASD, aim with right stick or fallback controls.
- Shooting is triggered when the aim state changes, not by holding a static aim vector.
- Enemies spawn from slow respawners, chase the player, and take several hits.
- Enemy spawners are damageable structures and level objectives. They should be tough, visibly physical, and show damage as health falls.
- Temporary pickups refresh active upgrade timers and can modify spread, piercing, and chain lightning behavior.
- The `DOWN` state must remain recoverable through `InputManager.restart_requested`; do not leave the player in an unrestartable frozen arena.
- Contact damage should respect player-side invulnerability frames so overlapping enemies cannot all damage the player in the same instant.
- Player damage must be visually readable: hit flash, translucent invulnerability flicker, and HUD invulnerability meter.
- Player parry is a long-cooldown defensive "get off me" command. It should push enemies without damage, erase hostile projectiles in range, and convert erased hostile projectiles into ammo for currently active ammo-based shot upgrades. Regular absorbed hostile projectiles award 1 ammo; perfect absorbed projectiles award 2 ammo and start/continue a short-cooldown parry chain.
- Parry readiness should be visually obvious on the player, including a clear flash when cooldown returns to ready.
- Parry-chain grace should be visually obvious around the player as a circular timer; letting it expire or missing the next perfect parry should start the usual long cooldown.
- Parry absorption should be visually readable: erased hostile bullets should swoop into the character portrait, perfect parries should add a special shine, and refilled ammo segments should flash white one at a time before returning blue.
- Bullet upgrades use ammo instead of duration; do not add timers to ammo-based projectile upgrades.
- Keep the upper-right combat HUD compact: health/invulnerability only. Ammo upgrades should appear as right-side buff squares with visible meters, while detailed attribute/stat readouts belong in the pause menu.
- Spread shot is intentionally capped at a 3-way spread for now; do not return it to 5-way without explicit retuning.
- Permanent upgrades are run-long attribute stacks. Keep them small, frequent, and displayed in the combat HUD attributes area.
- Permanent attributes currently include fire rate, move speed, bullet damage, and projectile size.
- Fire projectile upgrades should create AoE explosion packets and a visible explosion effect on hit.
- Water projectile upgrades should grow along their travel path and pierce through enemies.
- Projectiles should read as flashing lemon-shaped shots, not tiny player-character copies; preserve ammo-type colors.
- Upgrades should come from combat rewards, not random timer/map spawning.
- Enemies should drop ammo upgrades infrequently and permanent stat pickups sometimes, currently around a 25% permanent drop chance.
- Enemies should also drop small health pickups slightly more often than ammo upgrades; the current small heal restores 1 health and must not exceed max player health.
- Spawners should always drop one reward when destroyed: usually an ammo-based shot upgrade, with a chance to drop a full heal instead.
- Spawners should request a small opening wave of enemies when a room starts so combat begins as suppression pressure, not a pure spawner-rush race.
- Runtime reinforcement batches must be routed through `GameOrchestrator`'s room-scoped, frame-budgeted spawn queue. Loading-time inactive preloads may materialize immediately; pending runtime proposals must count against the horde cap and prevent premature room clear.
- Enemies should keep local hit/death feedback and bullet knockback when combat logic changes.
- Enemies that lose their general enter the explicit `ORPHANED` horde command state: they immediately abandon legion tactics, gain their profile-driven orphaned movement-speed multiplier, and return to their original single-minded player pursuit. Keep that fallback strategically simple, but route it through the normal obstacle-aware path resolver so enemies still navigate around validated walls and voids. Keep horde command state orthogonal to `behavior_kind` so future states can produce archetype-specific responses without duplicating base behaviors.
- The current squid-shaped fast enemy has become an emergent autonomous penetration checker for generated-floor, doorway, and movement-boundary leaks: its small body and high spawn count repeatedly exercise boundaries through ordinary enemy behavior, not bespoke testing logic. When the fast enemy receives its eventual production upgrade, preserve the existing squid identity by promoting it into `FaunaManager` as non-combat fauna similar to the cat; the upgraded fast enemy may receive a new combat visual. Preserve the squid's value as a boundary-regression canary without inventing penetration-seeking AI for it.
- Chain lightning must show visible jump arcs through `EffectsManager`; do not route chain damage invisibly.
- Restart controls must support keyboard and controller while in the `DOWN` state.
- Controller Start should primarily drive pause/resume. Controller A remains a restart/confirm input, and Start while `DOWN` may still restart through the orchestrator pause path.
- A level is cleared only when both enemy count and spawner count reach zero; winning should offer a return to level select.
- Preserve the 1280x720 logical viewport with 2D stretch scaling and a larger desktop window so the game remains comfortable on 3840x2160 displays.
- Dungeon crawling experiments should use `RoomPieceDefinition` resources, `DungeonManager` for spatial room layout state, and `RoomManager` for generated door entities.
- Dungeon floors should be generated from a run seed plus floor-number recipe: a guaranteed start-to-boss path, guaranteed treasure and challenge branches, optional side branches, and floor-scaled room count/spawner pressure. `GameOrchestrator` owns the run seed and passes it to `DungeonManager`; do not let entities or room pieces create their own gameplay seeds.
- `Main Game Loop Test` is the floor-to-floor roguelike loop entry. It should preserve the run's score/upgrades/tally across floors, regenerate a self-contained dungeon per floor, and treat boss death as the floor-clear trigger.
- Dungeon doors are generated entities too: they emit upward to `RoomManager`, and only `GameOrchestrator` may turn a door event into a room transition.
- Room transitions must not mark a room cleared while old contents are being torn down or new boss/spawner contents are still being created.
- Boss rooms may include spawners; keep their `max_active_enemies` high enough for the boss plus spawned adds.
- Dungeon minimap reveal state belongs to `DungeonManager`; UI drawing belongs to `DungeonMinimap`, with `GameOrchestrator` only syncing manager state into the UI.
