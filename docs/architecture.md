# Arena Shooter Architecture

The game is organized as `Main -> GameOrchestrator -> Managers -> Entities`.

Godot scenes and scripts are treated as object-oriented units. Entity scenes encapsulate visuals, collision, and local behavior. Manager nodes own groups of entities. The orchestrator is the only place where one manager's event becomes another manager's command.

## Signal Direction

Entities emit upward:

- `PlayerEntity`: `health_changed`, `health_depleted`
- `EnemyEntity`: `health_changed`, `health_depleted`
- `ProjectileEntity`: `hit_detected`, `expired`
- `EnemySpawnerEntity`: `spawn_ready`
- `PickupEntity`: `collected`, `expired`

Managers translate entity signals into manager-level events:

- `ProjectileManager.projectile_hit`
- `EnemyManager.enemy_defeated`
- `EnemyManager.player_contact_requested`
- `SpawnerManager.spawn_requested`
- `ItemManager.pickup_collected`
- `UpgradeManager.upgrade_changed`
- `PlayerManager.shoot_requested`

The orchestrator receives those signals and decides which manager command runs next.

## Manager Responsibilities

- `InputManager`: polls controller, keyboard, and mouse fallback; emits movement and aim-state events.
- `PlayerManager`: owns the player, movement commands, aim direction, weapon cooldown, player health, and player-side hit invulnerability.
- `ProjectileManager`: owns projectiles, applies upgrade-derived projectile spawning, and stamps damage packets with knockback source/direction, projectile size, growth, explosion, and chain fields.
- `EnemyManager`: owns enemies, target updates, contact checks, and enemy damage application.
- `SpawnerManager`: owns respawner entities and gates spawn requests by current enemy count.
- `ItemManager`: owns pickups and pickup spawn timing.
- `UpgradeManager`: owns ammo-based shot upgrades, optional timed effects, permanent run-long attribute stacks, and combines active modifiers.
- `CombatManager`: resolves hit/contact events into damage events and chain-lightning requests.
- `EffectsManager`: owns short-lived visual effect entities such as chain-lightning arcs.

## Level Flow

The game starts in `LEVEL_SELECT`. `GameOrchestrator` owns the selected level index, displays levels in increasing difficulty, and starts the selected `LevelDefinition` only after player confirmation.

Level definitions configure arena bounds, arena shape, spawner positions, spawner health, spawn interval, and max active enemies. `ArenaView`, `PlayerManager`, and `SpawnerManager` consume those values through orchestrator commands.

A level is won only when `SpawnerManager.get_spawner_count()` and `EnemyManager.get_enemy_count()` both reach zero. The win state disables gameplay managers and shows a return-to-level-select prompt.

## Presentation Scale

The project uses a 1280x720 logical viewport and scales canvas items into a larger 2560x1440 desktop window. Keep this separation: gameplay distances, arena bounds, UI offsets, and hitboxes stay authored in the logical 720p space, while Godot stretch settings make the game visually comfortable on 3840x2160 displays.

## Data Flow Examples

Aim-change shooting:

1. `InputManager` sees a right-stick, arrow-key, or mouse aim state change.
2. It emits `aim_fire_requested(direction)`.
3. `GameOrchestrator` calls `PlayerManager.request_fire(direction)`.
4. `PlayerManager` enforces cooldown and emits `shoot_requested(origin, direction)`.
5. `GameOrchestrator` asks `UpgradeManager` for modifiers and calls `ProjectileManager.fire(origin, direction, modifiers)`.

Projectile hit:

1. `ProjectileEntity` emits `hit_detected(projectile, target)`.
2. `ProjectileManager` emits `projectile_hit(projectile, target, damage_packet)`.
3. `GameOrchestrator` calls `CombatManager.resolve_projectile_hit(...)`.
4. `CombatManager` emits `damage_resolved(target, packet)` and optionally `chain_requested(...)`.
5. `GameOrchestrator` calls `EnemyManager.apply_damage(...)`.
6. When a chain target is selected, `GameOrchestrator` commands `EffectsManager.play_chain_lightning(...)` before resolving the chained hit.
7. `EnemyEntity` applies local knockback, hit flash, and death animation without calling upward dependencies.

Spawner hit:

1. `ProjectileEntity` can hit bodies in the `spawners` group.
2. `GameOrchestrator` routes resolved damage to `SpawnerManager.apply_damage(...)`.
3. `EnemySpawnerEntity` emits `health_depleted` when destroyed.
4. `SpawnerManager` removes it from active spawners and emits `spawner_destroyed`.
5. `GameOrchestrator` updates score and rechecks level clear conditions.

Pickup:

1. `PickupEntity` emits `collected(pickup, collector, upgrade_effect)`.
2. `ItemManager` emits `pickup_collected(effect)`.
3. `GameOrchestrator` calls `UpgradeManager.activate_upgrade(effect)`.
4. `UpgradeManager` emits `upgrade_changed(modifiers, active_effects)`.
5. `GameOrchestrator` updates player weapon cooldown state and HUD text.

Shot upgrade ammo:

1. `UpgradeManager` tracks remaining ammo for shot upgrades; ammo-based projectile upgrades do not expire by timer.
2. `GameOrchestrator` calls `UpgradeManager.consume_shot()` after routing a player shot.
3. `UpgradeManager` emits `upgrade_changed` so the upper-right combat HUD can show current ammo, spread, pierce, chain, AoE, and projectile size.
4. Fire upgrades stamp explosion fields onto damage packets; `CombatManager` emits `explosion_requested`, and `GameOrchestrator` routes AoE damage plus `EffectsManager.play_explosion(...)`.
5. Water upgrades stamp projectile growth and high pierce onto damage packets; `ProjectileEntity` grows its drawn/collision radius while traveling.

Permanent upgrades:

1. `EnemyManager.enemy_defeated` is routed by `GameOrchestrator` to `ItemManager.roll_enemy_drop(...)`.
2. `ItemManager` drops common small permanent stat pickups and rarer temporary shot-upgrade pickups.
3. Permanent pickups flow through `ItemManager.pickup_collected` into `UpgradeManager.activate_pickup(...)`.
4. `UpgradeManager` stacks run-long attributes for fire-rate cooldown reduction, movement speed, bullet damage, and projectile size.
5. `GameOrchestrator` applies the combined modifiers to `PlayerManager` and `ProjectileManager` paths, and displays attributes under the health bar.

Player down/restart:

1. `PlayerEntity` emits `health_depleted`.
2. `PlayerManager` emits `player_defeated`.
3. `GameOrchestrator` enters `DOWN`, disables gameplay managers, and updates the HUD with restart text.
4. `PlayerEntity` plays its local death animation, while the centered game-over panel shows restart controls.
5. `InputManager` still emits `restart_requested` when R, controller Start, or controller A is pressed.
6. `GameOrchestrator` calls `reset_run()` only from that restart event.
