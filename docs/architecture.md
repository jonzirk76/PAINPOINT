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
- `DoorEntity`: `entered`

Managers translate entity signals into manager-level events:

- `ProjectileManager.projectile_hit`
- `EnemyManager.enemy_defeated`
- `EnemyManager.player_contact_requested`
- `SpawnerManager.spawn_requested`
- `ItemManager.pickup_collected`
- `UpgradeManager.upgrade_changed`
- `PlayerManager.shoot_requested`
- `RoomManager.door_entered`

The orchestrator receives those signals and decides which manager command runs next.

## Manager Responsibilities

- `InputManager`: polls controller, keyboard, and mouse fallback; emits movement, aim-state, overdrive-held, and menu events.
- `PlayerManager`: owns the player, movement commands, aim direction, weapon cooldown, parry cooldown, player health, and player-side hit invulnerability.
- `ProjectileManager`: owns projectiles, applies upgrade-derived projectile spawning, handles hostile projectile absorption, and stamps damage packets with knockback source/direction, projectile size, growth, explosion, and chain fields.
- `EnemyManager`: owns enemies, target updates, contact checks, enemy damage application, and non-damaging parry pushback.
- `SpawnerManager`: owns respawner entities and gates spawn requests by current enemy count.
- `ItemManager`: owns pickups and pickup spawn timing.
- `UpgradeManager`: owns shared overdrive ammo, stackable run-long overdrive effects, permanent attribute stacks, and combines active modifiers.
- `CombatManager`: resolves hit/contact events into damage events and chain-lightning requests.
- `EffectsManager`: owns short-lived visual effect entities such as chain-lightning arcs.
- `DungeonManager`: owns generated dungeon room graph state, room clear state, and spatial room-piece placement.
- `RoomManager`: owns generated door entities for the currently loaded dungeon room.

## Level Flow

The game starts in `LEVEL_SELECT`. `GameOrchestrator` owns the selected level index, displays levels in increasing difficulty, and starts the selected `LevelDefinition` only after player confirmation.

Level definitions configure arena bounds, arena shape, floor number, spawner positions, spawner health, spawn interval, and max active enemies. `ArenaView`, `PlayerManager`, and `SpawnerManager` consume those values through orchestrator commands.

A level is won only when `SpawnerManager.get_spawner_count()` and `EnemyManager.get_enemy_count()` both reach zero. The win state disables gameplay managers and shows a return-to-level-select prompt.

## Dungeon Prototype Flow

The level-select menu includes `Dungeon Prototype` and `Main Game Loop Test` entries beside the authored arena levels. Both modes keep the same managers and entity rules, but `DungeonManager` generates a puzzle-piece room graph from `RoomPieceDefinition` resources.

Room pieces define footprint cells, connector directions, arena geometry, internal wall rectangles, typed spawner placements, and optional boss profile data. `DungeonManager` places pieces with cell-footprint collision so pieces fit spatially, tracks which rooms are cleared, and exposes only room-state queries/commands to `GameOrchestrator`.

Dungeon layout is recipe-driven rather than a single fixed prototype. `GameOrchestrator` creates one run seed when a dungeon or main-loop run starts, preserves it across floor advances, and passes it into `DungeonManager.reset_run(floor, run_seed)`. `DungeonManager` combines the run seed and floor number into the floor generation seed, builds a guaranteed start-to-boss path, attaches guaranteed treasure and challenge branches, then fills optional side branches from the combat room-piece pool. Later floors increase the required boss-path length, total room target, active enemy budget, and extra typed spawner pressure applied to eligible room `LevelDefinition` instances. `SpawnerManager` also scales owned spawner intervals from slow floor-one timing toward faster later-floor timing so enemy pressure starts low and ramps with the run.

`RoomManager` creates `DoorEntity` instances for the current room's connected exits. `DungeonManager` includes the target room kind in door info so doors leading to treasure, challenge, and boss rooms can display special markers before the player commits. Doors are locked while the room has active enemies or spawners, then unlock after `GameOrchestrator` marks the room cleared. Door entry emits upward to `RoomManager`, and only `GameOrchestrator` commands `DungeonManager.enter_direction(...)` and reloads the next room.

The first boss is still an `EnemyEntity` using a boss `EnemyProfile`. Boss behavior branches through profile data, keeping the one-enemy-scene rule while adding boss-scale health, ranged strafing, a stronger visual body, and a hostile spread-shot request.

Boss rooms can also include typed spawner placements. Their enemy budget must allow the boss and spawned adds to coexist; otherwise spawners will be starved while the boss is alive.

The dungeon minimap is UI-only rendering of `DungeonManager` state. `DungeonManager` owns room reveal state as rooms are entered, and `GameOrchestrator` syncs that state into `DungeonMinimap`.

`Main Game Loop Test` layers floor progression on top of the dungeon room flow. Boss death awards a large floor-clear score bonus, opens the floor-exit portal, spawns optional overdrive reward choices, and advances to a freshly generated floor after the portal/result flow. Run stats such as the run seed, enemies, bosses, spawners, pickups, upgrades, heals, and floors cleared are tracked by `GameOrchestrator` and displayed on the death tally screen.

## HUD And Pause Flow

The normal combat HUD stays intentionally light: top-center score, lower-corner state info, and an upper-right character resource stack with green health ticks, blue overdrive ammo, and the yellow special meter. Detailed attribute modifiers, overdrive stacks, and run stats are shown in `PausePanel` instead of occupying combat space.

Pause input flows through `InputManager.pause_requested` into `GameOrchestrator`; controller Start is the primary pause/resume button. The orchestrator disables gameplay managers, preserves the previous gameplay status, displays `PausePanel`, owns the exit-to-main-menu confirmation state before returning to `LEVEL_SELECT`, and treats Start while `DOWN` as a restart convenience. Controller A remains the direct controller confirm/restart input.

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
3. `GameOrchestrator` routes heals to `PlayerManager`, overdrive ammo pickups to `UpgradeManager.add_overdrive_ammo(...)`, and upgrade/stat pickups to `UpgradeManager.activate_pickup(effect)`.
4. `UpgradeManager` emits `upgrade_changed(modifiers, active_effects)`.
5. `GameOrchestrator` updates player weapon cooldown state and HUD text.

Overdrive:

1. `InputManager` emits `overdrive_changed(is_held)` from Left Shift or left trigger.
2. `GameOrchestrator` calls `UpgradeManager.set_overdrive_active(...)`.
3. While held and ammo is available, `UpgradeManager.get_modifiers()` applies stackable overdrive effects. With no effect stacks, overdrive doubles regular projectile size.
4. `GameOrchestrator` calls `UpgradeManager.consume_overdrive_shot()` after routing an overdrive shot; each overdrive shot spends one shared ammo.
5. Fire upgrades stamp explosion fields onto damage packets; `CombatManager` emits `explosion_requested`, and `GameOrchestrator` routes AoE damage plus `EffectsManager.play_explosion(...)`.
6. Water upgrades stamp projectile growth and pierce onto damage packets; `ProjectileEntity` grows its drawn/collision radius while traveling.

Parry:

1. `InputManager` emits `parry_requested` from keyboard/controller input.
2. `GameOrchestrator` calls `PlayerManager.request_parry()`.
3. `PlayerManager` enforces the long cooldown, plays the player pulse, and emits `parry_requested(origin, radius, perfect_radius, knockback)`.
4. `GameOrchestrator` commands `ProjectileManager.absorb_hostile_projectiles(...)`, `EnemyManager.apply_parry_pushback(...)`, and `UpgradeManager.add_overdrive_ammo(...)`.
5. Parry pushback never creates a damage packet. Absorbed hostile projectiles award 1 shared overdrive ammo each, or 20 ammo each when inside the small perfect radius.

Combat reward drops:

1. `EnemyManager.enemy_defeated` is routed by `GameOrchestrator` to `ItemManager.roll_enemy_drop(...)`.
2. `ItemManager` rolls occasional small health pickups and much rarer shared overdrive ammo pickups, keeping parry as the primary overdrive ammo source.
3. `ItemManager.pickup_collected` flows to `GameOrchestrator`, which routes heal pickups to `PlayerManager.apply_healing(...)` and upgrade pickups to `UpgradeManager.activate_pickup(...)`.
4. Challenge room and floor-end rewards spawn three optional overdrive effect choices. Treasure rooms spawn three optional permanent stat choices, including overdrive capacity.
5. `UpgradeManager` stacks run-long attributes for fire-rate cooldown reduction, movement speed, bullet damage, projectile size, and overdrive capacity.
6. `SpawnerManager.spawner_destroyed` is routed by `GameOrchestrator` to `ItemManager.drop_spawner_reward(...)`, which always drops one reward: usually an overdrive ammo cache, with a chance for a full heal instead.

Opening suppression:

1. `SpawnerManager.reset_run(...)` creates room spawners and marks an opening wave as pending.
2. When `GameOrchestrator` enables the room, `SpawnerManager` emits initial `spawn_requested` events for each spawner, respecting `max_active_enemies`.
3. `GameOrchestrator` routes those requests to `EnemyManager.spawn_enemy(...)`, so spawners never directly create enemies.

Player down/restart:

1. `PlayerEntity` emits `health_depleted`.
2. `PlayerManager` emits `player_defeated`.
3. `GameOrchestrator` enters `DOWN`, disables gameplay managers, and updates the HUD with restart text.
4. `PlayerEntity` plays its local death animation, while the centered game-over panel shows restart controls.
5. `InputManager` still emits `restart_requested` when R or controller A is pressed; controller Start emits `pause_requested`, which `GameOrchestrator` treats as restart only from `DOWN`.
6. `GameOrchestrator` calls `reset_run()` only from that restart event.
