# Arena Shooter Architecture

The game is organized as `Main -> GameOrchestrator -> Managers -> Entities`.

Godot scenes and scripts are treated as object-oriented units. Entity scenes encapsulate visuals, collision, and local behavior. Manager nodes own groups of entities. The orchestrator is the only place where one manager's event becomes another manager's command.

## Signal Direction

Entities emit upward:

- `PlayerEntity`: `health_changed`, `health_depleted`
- `EnemyEntity`: `health_changed`, `health_depleted`
- `ProjectileEntity`: `hit_detected`, `expired`
- General-role `EnemyEntity`: `spawn_ready`
- `PickupEntity`: `collected`, `expired`
- `DoorEntity`: `entered`

Managers translate entity signals into manager-level events:

- `ProjectileManager.projectile_hit`
- `EnemyManager.enemy_defeated`
- `EnemyManager.player_contact_requested`
- `SpawnerManager.spawn_proposed`
- `ItemManager.pickup_collected`
- `UpgradeManager.upgrade_changed`
- `PlayerManager.shoot_requested`
- `RoomManager.door_entered`

The orchestrator receives those signals and decides which manager command runs next.

## Manager Responsibilities

- `InputManager`: polls controller, keyboard, and mouse fallback; emits movement, aim-state, overdrive-held, and menu events.
- `PlayerManager`: owns the player, movement commands, aim direction, weapon cooldown, parry cooldown, player health, and player-side hit invulnerability.
- `ProjectileManager`: owns projectiles, applies upgrade-derived projectile spawning, handles hostile projectile absorption, and stamps damage packets with knockback source/direction, projectile size, growth, explosion, and chain fields.
- `EnemyManager`: owns all enemies, including generals; owns per-general `LegionTacticsController` instances; applies tactical movement intents, target updates, contact checks, enemy damage, and non-damaging parry pushback.
- `SpawnerManager`: coordinates general reinforcement timing, opening waves, and validated spawn proposals. It keeps non-owning general references during the migration away from the historical spawner subsystem; all gameplay bodies are owned by `EnemyManager`.
- `ItemManager`: owns pickups and pickup spawn timing.
- `UpgradeManager`: owns shared overdrive ammo, stackable run-long overdrive effects, permanent attribute stacks, and combines active modifiers.
- `CombatManager`: resolves hit/contact events into damage events and chain-lightning requests.
- `EffectsManager`: owns short-lived visual effect entities such as chain-lightning arcs.
- `DungeonManager`: owns generated dungeon room graph state, room clear state, and spatial room-piece placement.
- `RoomManager`: owns generated door entities for the currently loaded dungeon room.
- `FaunaManager`: owns non-combat background fauna such as cats, feeds them read-only combat danger points through injected providers, and keeps them off combat collision layers.

Enemy-to-enemy overlap uses soft separation rather than hard body collision. Each `EnemyProfile.crowd_weight` controls how much influence that enemy has in the pair: equal weights separate normally, heavier enemies displace lighter enemies more, and a zero-weight enemy yields without pushing the other enemy. Attack packets own raw knockback force; `EnemyEntity` divides that force by its weight to determine movement, with a minimum effective weight of `0.5` so zero-weight support enemies remain strongly movable rather than producing infinite response. Parry pushback follows the same rule.

Weight progression is role-driven: repair drones are weightless, runners and drones are lighter than standard infantry, cyber soldiers are slightly heavier, tanks and power armor are substantially heavier, generals are anchors, and bosses are heaviest.

## Level Flow

The game starts in `LEVEL_SELECT`. `GameOrchestrator` owns the selected level index, displays levels in increasing difficulty, and starts the selected `LevelDefinition` only after player confirmation.

Level definitions configure arena bounds, arena shape, floor number, spawner positions, opening non-spawner encounter tables, spawner health, spawn interval, and max active enemies. `ArenaView`, `PlayerManager`, `EnemyManager`, and `SpawnerManager` consume those values through orchestrator commands.

A level is won only when `EnemyManager.get_enemy_count()` reaches zero. The temporary `SpawnerManager` general count remains part of the clear check during the migration so queued reinforcement state cannot clear a room early.

## Dungeon Prototype Flow

The level-select menu keeps `Main Game Loop Test` as the first main-page choice, followed by the generated agent-intro boss test and an Archive entry. Older authored arenas, cat tests, generated encounter tests, the standalone boss chamber, and `Dungeon Prototype` live in the Archive, generally newest to oldest. Dungeon and generated-test modes keep the same managers and entity rules, but `DungeonManager` generates a puzzle-piece room graph from `RoomPieceDefinition` resources.

Room pieces define footprint cells, connector directions, arena geometry, internal wall rectangles, typed spawner placements, and optional boss profile data. `DungeonManager` places pieces with cell-footprint collision so pieces fit spatially, tracks which rooms are cleared, and exposes only room-state queries/commands to `GameOrchestrator`.

Dungeon layout is recipe-driven rather than a single fixed prototype. `GameOrchestrator` creates one run seed when a dungeon or main-loop run starts, preserves it across floor advances, and passes it into `DungeonManager.reset_run(floor, run_seed)`. `DungeonManager` combines the run seed and floor number into the floor generation seed, builds a guaranteed start-to-boss path, attaches guaranteed treasure and challenge branches, then fills optional side branches from the combat room-piece pool. Later floors increase the required boss-path length, total room target, active enemy budget, and extra typed spawner pressure applied to eligible room `LevelDefinition` instances. `SpawnerManager` also scales owned spawner intervals from slow floor-one timing toward faster later-floor timing so enemy pressure starts low and ramps with the run.

Dungeon gameplay runs inside a generated full-floor arena. `DungeonManager` builds the full floor geometry in one shared coordinate space, including fog metadata for rooms that should not be visible yet. The orchestrator uses camera bounds, fog, door gates, and manager enable/reset calls to preserve the old active-room combat feel while allowing seamless traversal through cleared rooms. Combat contents are still instantiated only for the active uncleared room; remaining destructible props from visible cleared rooms persist in the traversal environment, while inactive rooms exist as geometry under fog until the player commits through a door.

Room spatial validity is floor-derived rather than reconstructed by gameplay managers. `RoomInteriorGenerator` preserves the main reachable 40 px component produced by room validation in an immutable `RoomSpatialDomain`, together with the room footprint, static wall/void blockers, layout-reserved prop footprints, and semantic doorway transition regions. `LevelDefinition` carries that explicit runtime spatial contract; `DungeonManager` owns the room-local instance and translates it into full-floor coordinates for the active room. `EnemyManager` and `SpawnerManager` query the injected domain for spawn validation and constraint; they add only runtime gate blockers. This same walkable/reachable domain is the intended source for future tactical movement targets, so spawning and tactics cannot develop separate interpretations of the floor.

Dungeon visibility is a separate boundary from room generation and arena rendering. `DungeonManager` owns whether each room is active, visible but inactive, or hidden, and exposes fog rectangles plus inactive-room dim rectangles on generated full-floor `LevelDefinition` instances. `ArenaView` renders those overlays without deciding room state. Managers decide which entities are active and whether owned entities should render; background fauna can keep simulating inside the visible dungeon envelope while hidden outside the active room.

`RoomManager` creates `DoorEntity` instances for the relevant active boundaries: locked current-room exits during combat, or traversal triggers from visible cleared rooms into hidden uncleared rooms. `DungeonManager` includes the target room kind in door info so doors leading to treasure, challenge, and boss rooms can display special markers before the player commits. Doors are locked while the room has active enemies or spawners, then unlock after `GameOrchestrator` marks the room cleared. Door entry emits upward to `RoomManager`, and only `GameOrchestrator` commands `DungeonManager.enter_direction(...)`, `DungeonManager.enter_room(...)`, or room activation.

The first boss is still an `EnemyEntity` using a boss `EnemyProfile`. Boss behavior branches through profile data, keeping the one-enemy-scene rule while adding boss-scale health, ranged strafing, a stronger visual body, and a hostile spread-shot request.

Boss rooms can also include typed spawner placements. Their enemy budget must allow the boss and spawned adds to coexist; otherwise spawners will be starved while the boss is alive.

The dungeon minimap is UI-only rendering of `DungeonManager` state. `DungeonManager` owns room reveal state as rooms are entered, and `GameOrchestrator` syncs that state into `DungeonMinimap`.

`Main Game Loop Test` layers floor progression on top of the dungeon room flow. Boss death awards a large floor-clear score bonus, opens the floor-exit portal, spawns optional overdrive reward choices, and advances to a freshly generated floor after the player stands in the portal and confirms the exit. Run stats such as the run seed, enemies, bosses, spawners, pickups, upgrades, heals, and floors cleared are tracked by `GameOrchestrator` and displayed on the death tally screen.

Each generated dungeon floor also chooses one start or combat room as the cat room from the floor seed. `DungeonManager` stores only the chosen room and room-local spawn point; `GameOrchestrator` turns that into a full-floor position when the room is loaded and commands `FaunaManager` to spawn the single floor cat. The cat is background fauna: it avoids player/enemy/spawner danger points but does not participate in combat damage or objective counts.

### Squid As An Emergent Penetration Checker

The squid-shaped fast enemy was not assigned or scripted as a penetration checker. That role emerged because its small body and high spawn count produce many ordinary interactions with room edges and doorways; its speed, tactical movement, crowd separation, and knockback response broaden that incidental coverage. It has therefore become the project's live canary for leaks in generated-floor domains, transition lanes, facade depth handling, and movement constraints. A squid appearing outside the validated playable domain is a spatial-system defect, not an accepted fast-enemy ability.

The squid is not necessarily the fast enemy's final production presentation. When the fast enemy receives its eventual visual/gameplay upgrade, preserve the existing squid identity by promoting it into `FaunaManager` as non-combat fauna similar to the cat, while the combat role receives its upgraded presentation. The fauna squid should retain ordinary autonomous roaming, and a sandbox may use multiple instances when deliberate regression coverage is useful, but it should not gain artificial penetration-seeking behavior. Keep the fauna version off combat collision layers and out of enemy/objective counts.

## Performance Follow-Ups

If combat-room end hitches or dungeon traversal rebuild costs come up again, revisit full-floor `LevelDefinition` generation. The current implementation rebuilds a composed full-floor level when room state changes; caching stable full-floor geometry or incrementally updating room-state overlays, destructible placements, fog, doors, and active-room contents could reduce end-of-combat spikes more than timing deferrals alone.

## HUD And Pause Flow

The normal combat HUD stays intentionally light: top-center score, lower-corner state info, and an upper-right character resource stack with green health ticks, blue overdrive ammo, and the yellow special meter. Detailed attribute modifiers, overdrive stacks, and run stats are shown in `PausePanel` instead of occupying combat space.

Pause input flows through `InputManager.pause_requested` into `GameOrchestrator`; controller Start is the primary pause/resume button. The orchestrator disables gameplay managers, preserves the previous gameplay status, displays `PausePanel`, owns the exit-to-main-menu confirmation state before returning to `LEVEL_SELECT`, and treats Start while `DOWN` as a restart convenience. Controller A remains the direct controller confirm/restart input.

## Presentation Scale

The project uses a 1280x720 logical viewport and scales canvas items into a larger 2560x1440 desktop window. Keep this separation: gameplay distances, arena bounds, UI offsets, and hitboxes stay authored in the logical 720p space, while Godot stretch settings make the game visually comfortable on 3840x2160 displays.

## Developer Sandbox

The Archive contains a `Developer Sandbox` dungeon entry for testing floor-scaled systems without playing through earlier floors. `DebugSandboxPanel` owns its controls and emits commands upward; `GameOrchestrator` resolves resource IDs and routes commands to the owning managers. The panel can regenerate a selected floor and seed, freeze the world while leaving the player entity movable, enable player invincibility, keep charge shots and overdrive resources full, and deterministically set exact stack counts for overdrive effects or permanent attributes. Debug overrides are cleared whenever normal gameplay or level select is entered.

## Data Flow Examples

Aim-change shooting:

1. `InputManager` sees a right-stick, arrow-key, numpad, or mouse aim state change.
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

General hit:

1. `ProjectileEntity` hits the general through the ordinary `enemies` group.
2. `GameOrchestrator` routes resolved damage to `EnemyManager.apply_damage(...)`.
3. The general-role `EnemyEntity` emits `health_depleted` when destroyed.
4. `EnemyManager` removes it from active enemies, frees its legion controller, and emits `general_defeated`.
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
5. Fire upgrades stamp explosion and burn fields onto damage packets; `CombatManager` emits `explosion_requested`, and `GameOrchestrator` routes AoE damage plus `EffectsManager.play_explosion(...)`.
6. Water upgrades stamp projectile growth, pierce, and slow fields onto damage packets; `ProjectileEntity` grows its drawn/collision radius while traveling, while hit enemies own their slow timer.
7. Chain-lightning upgrades stamp chain and shock-charge fields onto damage packets. Repeated lightning hits on the same enemy build shock charge, then hits against a fully primed target deal doubled damage while the charge is maintained. Chain arcs remain visible through `EffectsManager`.

Parry:

1. `InputManager` emits `parry_requested` from keyboard/controller input.
2. `GameOrchestrator` calls `PlayerManager.request_parry()`.
3. `PlayerManager` enforces the current cooldown, plays the player pulse, and emits `parry_requested(origin, radius, perfect_radius, knockback)`.
4. `GameOrchestrator` commands `ProjectileManager.absorb_hostile_projectiles(...)`, routes the evaluated perfect/non-perfect result back to `PlayerManager`, commands `EnemyManager.apply_parry_pushback(...)`, and applies ammo through `UpgradeManager.add_overdrive_ammo(...)`.
5. Parry pushback never creates a damage packet. Absorbed hostile projectiles award 1 shared overdrive ammo each, or 2 ammo each when inside the small perfect radius.
6. Perfect parries reduce the next parry cooldown to 0.5 seconds and start a 4-second chain grace timer. Missing the next perfect parry or letting the grace timer expire starts the usual 8-second cooldown.

Combat reward drops:

1. `EnemyManager.enemy_defeated` is routed by `GameOrchestrator` to `ItemManager.roll_enemy_drop(...)`.
2. `ItemManager` rolls occasional small health pickups and much rarer shared overdrive ammo pickups, keeping parry as the primary overdrive ammo source.
3. `ItemManager.pickup_collected` flows to `GameOrchestrator`, which routes heal pickups to `PlayerManager.apply_healing(...)` and upgrade pickups to `UpgradeManager.activate_pickup(...)`.
4. Challenge room and floor-end rewards spawn three optional overdrive effect choices. Non-spread overdrive effects can also raise the shared overdrive capacity. Treasure rooms spawn three optional rolled permanent stat choices, including overdrive capacity.
5. `UpgradeManager` stacks run-long attributes for fire-rate cooldown reduction, movement speed, bullet damage, projectile size, and overdrive capacity. Permanent upgrade state sums rolled `total_amount` values by stack key so small chest variants can contribute to the same run-long stat as treasure-room variants.
6. `EnemyManager.general_defeated` is routed by `GameOrchestrator` to `ItemManager.drop_spawner_reward(...)`, which always drops one reward: usually an overdrive ammo cache, with a chance for a full heal instead.

Opening suppression:

1. `SpawnerManager.reset_run(...)` requests room generals through `GameOrchestrator`; `EnemyManager` creates and owns them as ordinary `EnemyEntity` instances with an `EnemySpawnProfile`.
2. When `GameOrchestrator` enables the room, `SpawnerManager` emits initial `spawn_requested` events for each spawner, respecting `max_active_enemies`.
3. `GameOrchestrator` routes those requests to `EnemyManager.spawn_enemy(...)`, so spawners never directly create enemies.
4. Generated combat and challenge rooms can also carry an `EncounterEntry` table. `GameOrchestrator` rolls that table from the run seed, floor number, and room id, then spawns one-time non-spawner enemies through `EnemyManager`.

Legion tactics:

1. A general's `EnemySpawnProfile` selects a tactics kind and the general receives a stable legion identity from `EnemyManager`.
2. `EnemyManager` creates one `LegionTacticsController` for the general and connects the general's upward `spawn_ready` signal.
3. Spawn proposals stamp the legion and general identities onto every reinforcement.
4. `EnemyManager` gives each controller a shared battlefield snapshot containing its members, player position, arena center, and the legion's position in the active-legion ordering.
5. Controllers return advisory movement positions. `EnemyManager` applies them to owned enemies while their normal player target remains unchanged for aiming and attacks.
6. Controllers coordinate fan-out sectors through the shared active-legion ordering; they never call one another.
7. Horde command is an explicit state independent of enemy archetype: `INDEPENDENT`, `COORDINATED`, or `ORPHANED`. When a general dies or otherwise disappears, `EnemyManager` removes its controller and commands every surviving member into `ORPHANED`, which clears legion identity and tactical destinations and invalidates tactical path caches. Orphans pursue the player through the shared obstacle-aware path resolver without formations, interception orders, or reassignment to another general. They also gain the movement multiplier configured by `EnemyProfile.orphaned_speed_multiplier` (1.25 by default), making general death a transition from coordinated pressure to faster aggression. Keeping command state orthogonal to `behavior_kind` allows future states to produce different responses in different horde archetypes without duplicating their base behavior implementations.
8. General doctrines adapt by role: stationary players invite a fan-out, active movement draws a concentrated push, and sufficiently fast outward movement near the arena edge triggers interception. Basic infantry use balanced thresholds, fast legions intercept early and switch quickly, shooter legions favor concentrated pressure, and tank legions change slowly and intercept only decisive escapes. Thresholds live in each general's `EnemySpawnProfile`.
9. Basic melee infantry use higher movement speed than their original zombie-pressure tuning so they can reach and maintain tactical formation targets.

Player down/restart:

1. `PlayerEntity` emits `health_depleted`.
2. `PlayerManager` emits `player_defeated`.
3. `GameOrchestrator` enters `DOWN`, disables gameplay managers, and updates the HUD with restart text.
4. `PlayerEntity` plays its local death animation, while the centered game-over panel shows restart controls.
5. `InputManager` still emits `restart_requested` when R or controller A is pressed; controller Start emits `pause_requested`, which `GameOrchestrator` treats as restart only from `DOWN`.
6. `GameOrchestrator` calls `reset_run()` only from that restart event.
