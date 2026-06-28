extends SceneTree

const ENTITY_SCRIPT_PATHS := [
	"res://scripts/entities/player_entity.gd",
	"res://scripts/entities/enemy_entity.gd",
	"res://scripts/entities/projectile_entity.gd",
	"res://scripts/entities/enemy_spawner_entity.gd",
	"res://scripts/entities/pickup_entity.gd",
	"res://scripts/entities/chain_lightning_effect.gd",
	"res://scripts/entities/explosion_effect.gd"
]

const FORBIDDEN_ENTITY_SNIPPETS := [
	"/root",
	"Managers",
	"GameOrchestrator",
	"get_tree().root"
]

const SCRIPT_PATHS := [
	"res://scripts/arena/arena_geometry.gd",
	"res://scripts/arena/arena_view.gd",
	"res://scripts/entities/player_entity.gd",
	"res://scripts/entities/enemy_entity.gd",
	"res://scripts/entities/projectile_entity.gd",
	"res://scripts/entities/enemy_spawner_entity.gd",
	"res://scripts/entities/pickup_entity.gd",
	"res://scripts/entities/chain_lightning_effect.gd",
	"res://scripts/entities/explosion_effect.gd",
	"res://scripts/managers/input_manager.gd",
	"res://scripts/managers/player_manager.gd",
	"res://scripts/managers/projectile_manager.gd",
	"res://scripts/managers/enemy_manager.gd",
	"res://scripts/managers/spawner_manager.gd",
	"res://scripts/managers/item_manager.gd",
	"res://scripts/managers/upgrade_manager.gd",
	"res://scripts/managers/combat_manager.gd",
	"res://scripts/managers/effects_manager.gd",
	"res://scripts/orchestrators/game_orchestrator.gd",
	"res://scripts/resources/damage_packet.gd",
	"res://scripts/resources/enemy_profile.gd",
	"res://scripts/resources/upgrade_effect.gd",
	"res://scripts/resources/permanent_upgrade.gd",
	"res://scripts/resources/level_definition.gd",
	"res://scripts/resources/spawner_profile.gd",
	"res://scripts/resources/spawner_placement.gd"
]

const LEVEL_PATHS := [
	"res://resources/levels/level_01_square.tres",
	"res://resources/levels/level_02_diamond.tres",
	"res://resources/levels/level_03_hexagon.tres",
	"res://resources/levels/level_04_cross.tres",
	"res://resources/levels/level_05_circle.tres",
	"res://resources/levels/level_06_maze.tres"
]

const ENEMY_PROFILE_PATHS := [
	"res://resources/enemies/basic_enemy.tres",
	"res://resources/enemies/tank_enemy.tres",
	"res://resources/enemies/fast_enemy.tres",
	"res://resources/enemies/shooter_enemy.tres"
]

const SPAWNER_PROFILE_PATHS := [
	"res://resources/spawners/basic_spawner.tres",
	"res://resources/spawners/tank_spawner.tres",
	"res://resources/spawners/fast_spawner.tres",
	"res://resources/spawners/shooter_spawner.tres"
]


func _init() -> void:
	var failures: Array[String] = []
	_test_architecture_rules(failures)
	_test_presentation_settings(failures)
	_test_scripts_instantiate(failures)
	_test_enemy_and_spawner_profiles(failures)
	_test_level_resources(failures)
	_test_arena_geometry_boundaries(failures)
	_test_arena_wall_generation(failures)
	_test_scene_loads(failures)
	_test_aim_change_logic(failures)
	_test_restart_signal(failures)
	_test_upgrade_modifiers_and_expiry(failures)
	_test_projectile_knockback_packet(failures)
	_test_tank_ignores_knockback(failures)
	_test_fast_enemy_contact_range(failures)
	_test_water_projectile_hits_each_enemy_once(failures)
	_test_damageable_spawner(failures)
	_test_projectile_hits_spawner(failures)
	_test_typed_spawner_spawn_profile(failures)
	_test_hostile_shot_signals(failures)
	_test_shooter_shot_tracks_target(failures)
	_test_hostile_projectile_damage_path(failures)
	_test_hostile_projectile_range_matches_player(failures)
	_test_spawner_explosion_effect(failures)

	if failures.is_empty():
		print("Smoke tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_architecture_rules(failures: Array[String]) -> void:
	for path in ENTITY_SCRIPT_PATHS:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			failures.append("Missing entity script: %s" % path)
			continue
		var source := file.get_as_text()
		for snippet in FORBIDDEN_ENTITY_SNIPPETS:
			if source.contains(snippet):
				failures.append("%s contains forbidden upward dependency snippet: %s" % [path, snippet])


func _test_presentation_settings(failures: Array[String]) -> void:
	if int(ProjectSettings.get_setting("display/window/size/viewport_width")) != 1280:
		failures.append("Logical viewport width should stay 1280 for scaled presentation.")
	if int(ProjectSettings.get_setting("display/window/size/viewport_height")) != 720:
		failures.append("Logical viewport height should stay 720 for scaled presentation.")
	if int(ProjectSettings.get_setting("display/window/size/window_width_override")) < 2560:
		failures.append("Window width override should be large enough for 4K displays.")
	if int(ProjectSettings.get_setting("display/window/size/window_height_override")) < 1440:
		failures.append("Window height override should be large enough for 4K displays.")
	if String(ProjectSettings.get_setting("display/window/stretch/mode")) != "canvas_items":
		failures.append("Stretch mode should scale canvas items for high-resolution displays.")


func _test_scripts_instantiate(failures: Array[String]) -> void:
	for path in SCRIPT_PATHS:
		var script = load(path)
		if script == null:
			failures.append("Script failed to load: %s" % path)
			continue
		if script.has_method("can_instantiate") and not script.can_instantiate():
			failures.append("Script failed to compile for instantiation: %s" % path)
			continue
		var instance = script.new()
		if instance == null:
			failures.append("Script failed to instantiate: %s" % path)
			continue
		if instance is Node:
			instance.free()


func _test_scene_loads(failures: Array[String]) -> void:
	var scene_paths := [
		"res://scenes/main.tscn",
		"res://scenes/entities/player_entity.tscn",
		"res://scenes/entities/enemy_entity.tscn",
		"res://scenes/entities/projectile_entity.tscn",
		"res://scenes/entities/enemy_spawner_entity.tscn",
		"res://scenes/entities/pickup_entity.tscn",
		"res://scenes/entities/chain_lightning_effect.tscn",
		"res://scenes/entities/explosion_effect.tscn"
	]
	for path in scene_paths:
		var scene := load(path)
		if scene == null:
			failures.append("Scene failed to load: %s" % path)
			continue
		var instance = scene.instantiate()
		if instance == null:
			failures.append("Scene failed to instantiate: %s" % path)
		elif instance is Node:
			if path.ends_with(".tscn") and instance.get_script() == null and not path.ends_with("main.tscn"):
				failures.append("Scene root script missing after instantiate: %s" % path)
			if path.ends_with("main.tscn") and instance.get_script() == null:
				failures.append("Main scene root script missing after instantiate.")
			if path.ends_with("main.tscn"):
				var required_nodes := [
					"UI/CombatPanel/HealthBarBack/HealthBarFill",
					"UI/CombatPanel/InvulnerabilityBarBack/InvulnerabilityBarFill",
					"UI/CombatPanel/AttributeLabel",
					"UI/CombatPanel/StatsLabel",
					"UI/GameOverPanel/GameOverPromptLabel",
					"UI/LevelSelectPanel/LevelListLabel",
					"UI/WinPanel/WinPromptLabel",
					"World/EffectLayer",
					"Managers/EffectsManager"
				]
				for node_path in required_nodes:
					if not instance.has_node(node_path):
						failures.append("Main scene missing HUD node: %s" % node_path)
			instance.free()


func _test_level_resources(failures: Array[String]) -> void:
	if LEVEL_PATHS.size() != 6:
		failures.append("Expected six level resources after adding circle and maze test levels.")
	for path in LEVEL_PATHS:
		var level = load(path)
		if level == null:
			failures.append("Level resource failed to load: %s" % path)
			continue
		var spawner_count: int = level.get_spawner_count()
		if spawner_count <= 0:
			failures.append("Level has no spawners: %s" % path)
		for placement in level.spawner_placements:
			if placement == null or placement.profile == null:
				failures.append("Level has a typed spawner placement without a profile: %s" % path)
				continue
			var spawner_position = placement.position
			if not ArenaGeometry.contains_point(spawner_position, level.arena_bounds, int(level.arena_shape)):
				failures.append("Level spawner position is outside the playable arena shape: %s" % path)
			for wall_rect in level.wall_rects:
				if wall_rect.has_point(spawner_position):
					failures.append("Level spawner position is inside an arena wall: %s" % path)


func _test_enemy_and_spawner_profiles(failures: Array[String]) -> void:
	for path in ENEMY_PROFILE_PATHS:
		var profile = load(path)
		if profile == null:
			failures.append("Enemy profile failed to load: %s" % path)
			continue
		if profile.max_health <= 0 or profile.body_radius <= 0.0 or profile.speed <= 0.0:
			failures.append("Enemy profile has invalid core stats: %s" % path)
	var tank = load("res://resources/enemies/tank_enemy.tres")
	var fast = load("res://resources/enemies/fast_enemy.tres")
	var shooter = load("res://resources/enemies/shooter_enemy.tres")
	if tank.max_health < 9 or tank.body_radius < 29.0 or tank.speed >= 82.0:
		failures.append("Tank enemy profile does not read as slower, larger, and tougher.")
	if float(tank.knockback_multiplier) > 0.0:
		failures.append("Tank enemy profile should ignore bullet knockback.")
	if fast.max_health > 1 or fast.body_radius >= 18.0 or fast.speed <= 100.0:
		failures.append("Fast enemy profile does not read as smaller, faster, and weaker.")
	if shooter.behavior_kind != "shooter" or shooter.projectile_speed != 250.0 or shooter.projectile_damage != 1:
		failures.append("Shooter enemy profile is missing shooter behavior or slow bullet tuning.")
	for path in SPAWNER_PROFILE_PATHS:
		var profile = load(path)
		if profile == null:
			failures.append("Spawner profile failed to load: %s" % path)
			continue
		if profile.enemy_profile == null:
			failures.append("Spawner profile has no enemy profile: %s" % path)
	var tank_spawner = load("res://resources/spawners/tank_spawner.tres")
	var fast_spawner = load("res://resources/spawners/fast_spawner.tres")
	var shooter_spawner = load("res://resources/spawners/shooter_spawner.tres")
	if tank_spawner.max_health < 34 or tank_spawner.body_radius < 44.0:
		failures.append("Tank spawner profile should be tougher and larger.")
	if fast_spawner.max_health > 10 or fast_spawner.body_radius >= 31.0:
		failures.append("Fast spawner profile should be smaller and fragile.")
	if not shooter_spawner.shoots_projectiles or shooter_spawner.shot_cooldown != 1.8:
		failures.append("Shooter spawner profile should regularly fire hostile projectiles.")


func _test_arena_geometry_boundaries(failures: Array[String]) -> void:
	var diamond_bounds := Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
	var diamond_outside := Vector2(560.0, 280.0)
	if ArenaGeometry.contains_point(diamond_outside, diamond_bounds, 1):
		failures.append("Diamond arena should reject points outside the diamond but inside the bounds rectangle.")
	var diamond_constrained := ArenaGeometry.constrain_point(diamond_outside, diamond_bounds, 1)
	if not ArenaGeometry.contains_point(diamond_constrained, diamond_bounds, 1):
		failures.append("Diamond arena did not constrain outside points back inside the polygon.")
	var cross_bounds := Rect2(Vector2(-660.0, -360.0), Vector2(1320.0, 720.0))
	var cross_cutout := Vector2(520.0, 300.0)
	if ArenaGeometry.contains_point(cross_cutout, cross_bounds, 3):
		failures.append("Cross arena should reject points in the cut-out corners.")
	var cross_constrained := ArenaGeometry.constrain_point(cross_cutout, cross_bounds, 3)
	if not ArenaGeometry.contains_point(cross_constrained, cross_bounds, 3):
		failures.append("Cross arena did not constrain cut-out corner points back inside the polygon.")
	var circle_bounds := Rect2(Vector2(-640.0, -360.0), Vector2(1280.0, 720.0))
	if ArenaGeometry.contains_point(Vector2(630.0, 350.0), circle_bounds, 4):
		failures.append("Circle arena should reject rectangular corner points.")


func _test_arena_wall_generation(failures: Array[String]) -> void:
	var level = load("res://resources/levels/level_06_maze.tres")
	if level == null:
		failures.append("Maze level failed to load.")
		return
	if level.wall_rects.is_empty():
		failures.append("Maze level should define internal wall rects.")
	var arena = load("res://scripts/arena/arena_view.gd").new()
	root.add_child(arena)
	arena.configure(level)
	var wall_count := 0
	for child in arena.get_children():
		if child.is_in_group("arena_walls"):
			wall_count += 1
			if (child.collision_layer & 32) == 0:
				failures.append("Arena wall body is not on the arena wall collision layer.")
	if wall_count != level.wall_rects.size():
		failures.append("ArenaView did not create one wall body per maze wall rect.")
	arena.free()


func _test_aim_change_logic(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/input_manager.gd").new()
	manager.stick_deadzone = 0.25
	manager.aim_change_threshold = 0.18
	if not manager.should_fire_for_aim_change(Vector2.RIGHT):
		failures.append("Initial aim state should request fire.")
	if manager.should_fire_for_aim_change(Vector2(1.0, 0.02)):
		failures.append("Tiny aim drift should not request another fire.")
	if not manager.should_fire_for_aim_change(Vector2.UP):
		failures.append("Large aim state change should request fire.")
	manager.free()


func _test_restart_signal(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/input_manager.gd").new()
	var restart_count := [0]
	manager.restart_requested.connect(func() -> void:
		restart_count[0] += 1
	)
	var event := InputEventKey.new()
	event.keycode = KEY_R
	event.physical_keycode = KEY_R
	event.pressed = true
	manager._unhandled_input(event)
	var controller_event := InputEventJoypadButton.new()
	controller_event.button_index = JOY_BUTTON_START
	controller_event.pressed = true
	manager._unhandled_input(controller_event)
	if restart_count[0] != 2:
		failures.append("InputManager did not emit restart_requested for R key.")
	manager.free()


func _test_upgrade_modifiers_and_expiry(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/upgrade_manager.gd").new()
	var spread = load("res://resources/upgrades/spread_shot.tres")
	var pierce = load("res://resources/upgrades/piercing_shot.tres")
	var fire = load("res://resources/upgrades/fire_burst.tres")
	var water = load("res://resources/upgrades/water_swell.tres")
	var fire_rate = load("res://resources/permanent_upgrades/faster_reflexes.tres")
	var move_speed = load("res://resources/permanent_upgrades/runner_legs.tres")
	var damage = load("res://resources/permanent_upgrades/heavy_tears.tres")
	var size = load("res://resources/permanent_upgrades/fat_tears.tres")
	manager.activate_upgrade(spread)
	manager.activate_upgrade(pierce)
	manager.activate_upgrade(fire)
	manager.activate_upgrade(water)
	manager.activate_permanent_upgrade(fire_rate)
	manager.activate_permanent_upgrade(move_speed)
	manager.activate_permanent_upgrade(damage)
	manager.activate_permanent_upgrade(size)
	manager.consume_shot()
	var active_effects: Array = manager.get_active_effects()
	for state in active_effects:
		if int(state["max_ammo"]) > 0 and int(state["ammo"]) >= int(state["max_ammo"]):
			failures.append("Upgrade ammo did not decrement after consume_shot.")
	var modifiers: Dictionary = manager.get_modifiers()
	if int(modifiers["projectile_count"]) < 5:
		failures.append("Spread shot did not increase projectile count.")
	if int(modifiers["pierce_count"]) < 3:
		failures.append("Piercing shot did not increase pierce count.")
	if float(modifiers["fire_cooldown_multiplier"]) >= 1.0:
		failures.append("Permanent fire-rate upgrade did not reduce cooldown multiplier.")
	if float(modifiers["move_speed_multiplier"]) <= 1.0:
		failures.append("Permanent move-speed upgrade did not increase movement multiplier.")
	if float(modifiers["damage_multiplier"]) <= 1.0:
		failures.append("Permanent damage upgrade did not increase damage multiplier.")
	if float(modifiers["projectile_size_multiplier"]) <= 1.0:
		failures.append("Permanent projectile-size upgrade did not increase projectile size.")
	if float(modifiers["explosion_radius"]) <= 0.0:
		failures.append("Fire Burst did not add explosion radius.")
	if float(modifiers["projectile_growth_per_second"]) <= 0.0:
		failures.append("Water Swell did not add projectile growth.")
	if int(modifiers["pierce_count"]) < 99:
		failures.append("Water Swell did not allow projectiles to pass through enemies.")
	if manager.get_permanent_stats().size() != 4:
		failures.append("Permanent upgrade stats were not tracked.")
	manager.set_enabled(true)
	manager._process(99.0)
	if manager.get_active_effects().is_empty():
		failures.append("Ammo upgrades should not expire by timer.")
	manager.free()


func _test_projectile_knockback_packet(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/projectile_manager.gd").new()
	var packet = manager._create_damage_packet({}, Vector2(10.0, 4.0), Vector2.RIGHT)
	if packet.knockback <= 0.0:
		failures.append("Projectile damage packet did not include knockback.")
	if packet.knockback_direction.distance_to(Vector2.RIGHT) > 0.001:
		failures.append("Projectile damage packet did not preserve knockback direction.")
	manager.free()


func _test_tank_ignores_knockback(failures: Array[String]) -> void:
	var enemy = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	var tank_profile = load("res://resources/enemies/tank_enemy.tres")
	var packet = load("res://scripts/resources/damage_packet.gd").new()
	enemy.initialize(tank_profile)
	packet.damage = 1
	packet.knockback = 500.0
	packet.knockback_direction = Vector2.RIGHT
	enemy.take_damage(packet)
	if enemy._knockback_velocity.length_squared() > 0.001:
		failures.append("Tank enemy should not receive knockback velocity from bullets.")
	enemy.free()


func _test_fast_enemy_contact_range(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/enemy_manager.gd").new()
	var enemy = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	var player = load("res://scenes/entities/player_entity.tscn").instantiate()
	var fast_profile = load("res://resources/enemies/fast_enemy.tres")
	enemy.initialize(fast_profile)
	var effective_range: float = manager._get_effective_contact_range(enemy, player)
	var body_touch_range: float = enemy.body_radius + player.body_radius + 4.0
	if effective_range < body_touch_range:
		failures.append("Fast enemy effective contact range should account for player and enemy body radii.")
	if effective_range <= enemy.contact_radius:
		failures.append("Fast enemy contact range should exceed its raw profile radius when collision bodies separate first.")
	manager.free()
	enemy.free()
	player.free()


func _test_water_projectile_hits_each_enemy_once(failures: Array[String]) -> void:
	var projectile = load("res://scenes/entities/projectile_entity.tscn").instantiate()
	var enemy = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	var packet = load("res://scripts/resources/damage_packet.gd").new()
	var hit_count := [0]
	packet.damage = 1
	packet.pierce_count = 99
	packet.projectile_kind = "water"
	packet.projectile_growth_per_second = 1.55
	packet.projectile_max_size_multiplier = 2.8
	projectile.hit_detected.connect(func(_projectile, target) -> void:
		if target == enemy:
			hit_count[0] += 1
	)
	projectile.initialize(Vector2.ZERO, Vector2.RIGHT, packet, 560.0)
	projectile._handle_target_hit(enemy)
	projectile._handle_target_hit(enemy)
	if hit_count[0] != 1:
		failures.append("Water Swell projectile should only emit one hit per enemy target.")
	if projectile.hit_targets.size() != 1:
		failures.append("Water Swell projectile should track each enemy target only once.")
	projectile.free()
	enemy.free()


func _test_damageable_spawner(failures: Array[String]) -> void:
	var spawner = load("res://scenes/entities/enemy_spawner_entity.tscn").instantiate()
	var packet = load("res://scripts/resources/damage_packet.gd").new()
	var depleted_count := [0]
	spawner.initialize(5, 3.0, 32.0)
	spawner.health_depleted.connect(func(_spawner) -> void:
		depleted_count[0] += 1
	)
	root.add_child(spawner)
	packet.damage = 5
	spawner.take_damage(packet)
	if depleted_count[0] != 1:
		failures.append("Enemy spawner did not emit health_depleted when damaged to zero.")
	if spawner.is_in_group("spawners"):
		failures.append("Destroyed spawner should leave the spawners group.")
	spawner.free()


func _test_projectile_hits_spawner(failures: Array[String]) -> void:
	var spawner = load("res://scenes/entities/enemy_spawner_entity.tscn").instantiate()
	var projectile = load("res://scenes/entities/projectile_entity.tscn").instantiate()
	var packet = load("res://scripts/resources/damage_packet.gd").new()
	var hit_count := [0]
	spawner.initialize(10, 3.0, 32.0)
	spawner.global_position = Vector2(40.0, 0.0)
	projectile.hit_detected.connect(func(_projectile, target) -> void:
		if target == spawner:
			hit_count[0] += 1
	)
	root.add_child(spawner)
	root.add_child(projectile)
	projectile.initialize(Vector2.ZERO, Vector2.RIGHT, packet, 560.0)
	if (projectile.collision_mask & 16) == 0:
		failures.append("Projectile collision mask does not include the spawner layer.")
	if (projectile.collision_mask & 32) == 0:
		failures.append("Player projectile collision mask does not include the arena wall layer.")
	projectile._handle_target_hit(spawner)
	if hit_count[0] != 1:
		failures.append("Projectile did not emit hit_detected for a spawner target.")
	if is_instance_valid(projectile):
		projectile.free()
	if is_instance_valid(spawner):
		spawner.free()


func _test_typed_spawner_spawn_profile(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/spawner_manager.gd").new()
	var level = load("res://resources/levels/level_01_square.tres")
	var requested_profiles := []
	root.add_child(manager)
	manager.spawn_requested.connect(func(_position, profile) -> void:
		requested_profiles.append(profile)
	)
	manager.initialize({})
	manager.reset_run(level)
	manager.set_enabled(true)
	if manager._spawners.is_empty():
		failures.append("SpawnerManager did not create typed spawners from level placements.")
	else:
		var spawner = manager._spawners[0]
		manager._on_spawner_spawn_ready(spawner, spawner.global_position)
		if requested_profiles.is_empty() or requested_profiles[0] != spawner.enemy_profile:
			failures.append("Typed spawner did not request its configured enemy profile.")
	manager.free()


func _test_hostile_shot_signals(failures: Array[String]) -> void:
	var enemy = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	var shooter_profile = load("res://resources/enemies/shooter_enemy.tres")
	var enemy_shots := [0]
	enemy.initialize(shooter_profile)
	enemy.shot_ready.connect(func(_enemy, _origin, direction, shot_config) -> void:
		if direction.length_squared() > 0.001 and int(shot_config["damage"]) == 1:
			enemy_shots[0] += 1
	)
	enemy._shot_cooldown_remaining = 0.0
	enemy._try_emit_shot(Vector2.RIGHT * 300.0)
	if enemy_shots[0] != 1:
		failures.append("Shooter enemy did not emit a hostile shot-ready signal.")
	enemy.free()

	var spawner = load("res://scenes/entities/enemy_spawner_entity.tscn").instantiate()
	var shooter_spawner_profile = load("res://resources/spawners/shooter_spawner.tres")
	var spawner_shots := [0]
	spawner.initialize_from_profile(shooter_spawner_profile)
	spawner.set_target_position(Vector2.RIGHT * 300.0)
	spawner.shot_ready.connect(func(_spawner, _origin, direction, shot_config) -> void:
		if direction.length_squared() > 0.001 and int(shot_config["damage"]) == 1:
			spawner_shots[0] += 1
	)
	spawner._try_emit_shot()
	if spawner_shots[0] != 1:
		failures.append("Shooter spawner did not emit a hostile shot-ready signal.")
	spawner.free()


func _test_shooter_shot_tracks_target(failures: Array[String]) -> void:
	var enemy = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	var shooter_profile = load("res://resources/enemies/shooter_enemy.tres")
	var directions: Array[Vector2] = []
	enemy.initialize(shooter_profile)
	enemy.global_position = Vector2.ZERO
	enemy.shot_ready.connect(func(_enemy, _origin, direction, _shot_config) -> void:
		directions.append(direction)
	)
	enemy._shot_cooldown_remaining = 0.0
	enemy.set_target_position(Vector2.LEFT * 300.0)
	enemy._try_emit_shot(enemy.target_position - enemy.global_position)
	enemy._shot_cooldown_remaining = 0.0
	enemy.set_target_position(Vector2.RIGHT * 300.0)
	enemy._try_emit_shot(enemy.target_position - enemy.global_position)
	if directions.size() != 2:
		failures.append("Shooter enemy did not emit shots for target tracking test.")
	elif directions[0].distance_to(Vector2.LEFT) > 0.001 or directions[1].distance_to(Vector2.RIGHT) > 0.001:
		failures.append("Shooter enemy shots should track the latest player target direction.")
	enemy.free()


func _test_hostile_projectile_damage_path(failures: Array[String]) -> void:
	var projectile = load("res://scenes/entities/projectile_entity.tscn").instantiate()
	var player = load("res://scenes/entities/player_entity.tscn").instantiate()
	var packet = load("res://scripts/resources/damage_packet.gd").new()
	var hit_count := [0]
	packet.damage = 1
	projectile.set_projectile_team("hostile")
	projectile.hit_detected.connect(func(_projectile, target) -> void:
		if target == player:
			hit_count[0] += 1
	)
	projectile.initialize(Vector2.ZERO, Vector2.RIGHT, packet, 250.0)
	if (projectile.collision_mask & 1) == 0 or (projectile.collision_mask & 32) == 0:
		failures.append("Hostile projectile should target player and arena wall layers.")
	projectile._handle_target_hit(player)
	if hit_count[0] != 1:
		failures.append("Hostile projectile did not emit hit_detected for the player.")

	var manager = load("res://scripts/managers/combat_manager.gd").new()
	var player_damage := [0]
	manager.player_damage_resolved.connect(func(amount: int) -> void:
		player_damage[0] += amount
	)
	manager.set_enabled(true)
	manager.resolve_projectile_hit(projectile, player, packet)
	if player_damage[0] != 1:
		failures.append("Hostile projectile damage did not route to player damage.")

	var wall = StaticBody2D.new()
	wall.add_to_group("arena_walls")
	var wall_projectile = load("res://scenes/entities/projectile_entity.tscn").instantiate()
	wall_projectile.set_projectile_team("hostile")
	wall_projectile.initialize(Vector2.ZERO, Vector2.RIGHT, packet, 250.0)
	wall_projectile._handle_target_hit(wall)
	if wall_projectile.monitoring:
		failures.append("Projectile should expire when it hits an arena wall.")
	manager.free()
	player.free()
	projectile.free()
	wall_projectile.free()
	wall.free()


func _test_hostile_projectile_range_matches_player(failures: Array[String]) -> void:
	var layer := Node2D.new()
	var manager = load("res://scripts/managers/projectile_manager.gd").new()
	root.add_child(layer)
	root.add_child(manager)
	manager.initialize({
		"projectile_layer": layer
	})
	manager.set_enabled(true)
	var player_reference_projectile = manager.projectile_scene.instantiate()
	var player_range: float = manager.base_projectile_speed * player_reference_projectile.lifetime_seconds
	player_reference_projectile.free()
	manager.fire_hostile(Vector2.ZERO, Vector2.RIGHT, {
		"speed": 250.0,
		"damage": 1,
		"radius": 7.0
	})
	if manager._projectiles.is_empty():
		failures.append("ProjectileManager did not create hostile projectile for range test.")
	else:
		var projectile = manager._projectiles[0]
		var hostile_range: float = projectile.speed * projectile.lifetime_seconds
		if hostile_range < player_range:
			failures.append("Hostile shooter projectile range should be at least the player projectile range.")
	manager.free()
	layer.free()


func _test_spawner_explosion_effect(failures: Array[String]) -> void:
	var effect_layer := Node2D.new()
	var manager = load("res://scripts/managers/effects_manager.gd").new()
	root.add_child(effect_layer)
	root.add_child(manager)
	manager.initialize({
		"effect_layer": effect_layer
	})
	manager.set_enabled(true)
	manager.play_spawner_explosion(Vector2.ZERO, 180.0)
	if effect_layer.get_child_count() != 1:
		failures.append("Spawner explosion did not create a visible effect.")
	else:
		var effect = effect_layer.get_child(0)
		if effect.radius < 180.0:
			failures.append("Spawner explosion effect radius was not large enough.")
		if effect.lifetime_seconds < 0.5:
			failures.append("Spawner explosion effect should last long enough to read as a death animation.")
	manager.free()
	effect_layer.free()
