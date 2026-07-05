# Repo Rules For Future Agents

This project is a Godot 4.x GDScript top-down arena shooter. Keep the architecture explicit and boring in the good way: gameplay entities signal upward, managers own entities, and the orchestrator routes between managers.

## Branch And Playable Main Workflow

- Treat `main` as the user's stable playable/test area.
- Agents should do feature work primarily on git feature branches, not directly on `main`, unless the user explicitly requests otherwise or the work is a tiny documentation-only edit.
- When a feature is requested, create a feature branch before implementation and keep that branch's commit history meaningful enough for easy tweak rollbacks.
- When the feature is finished and ready for user testing, move the active repo checkout to that feature branch and clearly tell the user which branch contains the test build.
- If the user requests tweaks while the active checkout is a feature branch, the first action should be to move the repo back to the working `main` branch so the user's playable environment is restored before new branch work continues.
- Do not strand the user's active checkout on a broken or half-finished feature branch. If testing requires staying on a feature branch, say that explicitly.
- Before switching branches, check for uncommitted work and avoid overwriting user changes.
- Final summaries for feature work should include the exact git commands the user can run to merge the feature branch back into `main`.

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
- Enemies should keep local hit/death feedback and bullet knockback when combat logic changes.
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
