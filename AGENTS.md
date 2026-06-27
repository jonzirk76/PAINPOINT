# Repo Rules For Future Agents

This project is a Godot 4.x GDScript top-down arena shooter. Keep the architecture explicit and boring in the good way: gameplay entities signal upward, managers own entities, and the orchestrator routes between managers.

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
- Bullet upgrades use ammo instead of duration; do not add timers to ammo-based projectile upgrades.
- Permanent upgrades are run-long attribute stacks. Keep them small, frequent, and displayed in the combat HUD attributes area.
- Permanent attributes currently include fire rate, move speed, bullet damage, and projectile size.
- Fire projectile upgrades should create AoE explosion packets and a visible explosion effect on hit.
- Water projectile upgrades should grow along their travel path and pierce through enemies.
- Projectiles should read as flashing lemon-shaped shots, not tiny player-character copies; preserve ammo-type colors.
- Enemy drops should include common permanent stat pickups and rarer temporary shot-upgrade pickups.
- Enemies should keep local hit/death feedback and bullet knockback when combat logic changes.
- Chain lightning must show visible jump arcs through `EffectsManager`; do not route chain damage invisibly.
- Restart controls must support keyboard and controller while in the `DOWN` state.
- A level is cleared only when both enemy count and spawner count reach zero; winning should offer a return to level select.
- Preserve the 1280x720 logical viewport with 2D stretch scaling and a larger desktop window so the game remains comfortable on 3840x2160 displays.
