extends SceneTree

const ENTITY_SCRIPT_PATHS := [
	"res://scripts/entities/player_entity.gd",
	"res://scripts/entities/enemy_entity.gd",
	"res://scripts/entities/projectile_entity.gd",
	"res://scripts/entities/enemy_spawner_entity.gd",
	"res://scripts/entities/pickup_entity.gd",
	"res://scripts/entities/chain_lightning_effect.gd",
	"res://scripts/entities/explosion_effect.gd",
	"res://scripts/entities/parry_absorb_effect.gd",
	"res://scripts/entities/door_entity.gd"
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
	"res://scripts/entities/parry_absorb_effect.gd",
	"res://scripts/entities/door_entity.gd",
	"res://scripts/managers/input_manager.gd",
	"res://scripts/managers/player_manager.gd",
	"res://scripts/managers/projectile_manager.gd",
	"res://scripts/managers/enemy_manager.gd",
	"res://scripts/managers/spawner_manager.gd",
	"res://scripts/managers/item_manager.gd",
	"res://scripts/managers/upgrade_manager.gd",
	"res://scripts/managers/combat_manager.gd",
	"res://scripts/managers/effects_manager.gd",
	"res://scripts/managers/audio_manager.gd",
	"res://scripts/managers/dungeon_manager.gd",
	"res://scripts/managers/room_manager.gd",
	"res://scripts/ui/dungeon_minimap.gd",
	"res://scripts/orchestrators/game_orchestrator.gd",
	"res://scripts/resources/damage_packet.gd",
	"res://scripts/resources/enemy_profile.gd",
	"res://scripts/resources/upgrade_effect.gd",
	"res://scripts/resources/permanent_upgrade.gd",
	"res://scripts/resources/level_definition.gd",
	"res://scripts/resources/spawner_profile.gd",
	"res://scripts/resources/spawner_placement.gd",
	"res://scripts/resources/room_piece_definition.gd",
	"res://scripts/resources/health_pickup.gd"
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
	"res://resources/enemies/shooter_enemy.tres",
	"res://resources/enemies/first_boss_enemy.tres"
]

const SPAWNER_PROFILE_PATHS := [
	"res://resources/spawners/basic_spawner.tres",
	"res://resources/spawners/tank_spawner.tres",
	"res://resources/spawners/fast_spawner.tres",
	"res://resources/spawners/shooter_spawner.tres"
]

const SFX_PATHS := [
	"res://audio/bullet_impact.wav",
	"res://audio/enemy_bullet_shot.wav",
	"res://audio/floor_start.wav",
	"res://audio/game_over.wav",
	"res://audio/item_pick_up.wav",
	"res://audio/parry.wav",
	"res://audio/parry_ready.wav",
	"res://audio/perfect_parry_follow_up.wav",
	"res://audio/player_bullet_shot.wav",
	"res://audio/room_entry.wav"
]

const CHARACTER_SVG_PATHS := [
	"res://art/characters/player_character.svg",
	"res://art/characters/player_upper_body_gun.svg",
	"res://art/characters/basic_enemy_chaser.svg",
	"res://art/characters/fast_enemy_runner.svg",
	"res://art/characters/tank_enemy_brute.svg",
	"res://art/characters/shooter_enemy_orbiter.svg",
	"res://art/characters/boss_enemy_overlord.svg"
]

const ROOM_PIECE_PATHS := [
	"res://resources/rooms/start_square.tres",
	"res://resources/rooms/combat_wide.tres",
	"res://resources/rooms/combat_tall.tres",
	"res://resources/rooms/combat_l_room.tres",
	"res://resources/rooms/combat_t_room.tres",
	"res://resources/rooms/combat_ring.tres",
	"res://resources/rooms/combat_hourglass.tres",
	"res://resources/rooms/combat_crossroads.tres",
	"res://resources/rooms/treasure_nook.tres",
	"res://resources/rooms/challenge_zigzag.tres",
	"res://resources/rooms/boss_chamber.tres"
]


func _init() -> void:
	paused = false
	var failures: Array[String] = []
	_test_architecture_rules(failures)
	_test_presentation_settings(failures)
	_test_character_svg_assets(failures)
	_test_character_art_applied_to_entities(failures)
	_test_scripts_instantiate(failures)
	_test_enemy_and_spawner_profiles(failures)
	_test_level_resources(failures)
	_test_arena_geometry_boundaries(failures)
	_test_arena_wall_generation(failures)
	_test_scene_loads(failures)
	_test_aim_change_logic(failures)
	_test_restart_signal(failures)
	_test_parry_input_and_cooldown(failures)
	_test_player_disable_stops_movement(failures)
	_test_pause_menu_flow(failures)
	_test_upgrade_modifiers_and_expiry(failures)
	_test_ammo_type_balance(failures)
	_test_low_ammo_warning(failures)
	_test_parry_absorbs_hostile_projectiles_for_ammo(failures)
	_test_parry_absorb_visuals_and_ammo_flash(failures)
	_test_audio_assets_and_pitch_variation(failures)
	_test_reward_driven_pickup_drops(failures)
	_test_health_pickup_and_player_healing(failures)
	_test_projectile_knockback_packet(failures)
	_test_projectile_reset_clears_visible_projectiles(failures)
	_test_parry_pushes_enemies_without_damage(failures)
	_test_tank_ignores_knockback(failures)
	_test_fast_enemy_contact_range(failures)
	_test_enemy_pathing_steers_around_walls(failures)
	_test_enemy_soft_separation_without_hard_collision(failures)
	_test_water_projectile_hits_each_enemy_once(failures)
	_test_damageable_spawner(failures)
	_test_projectile_hits_spawner(failures)
	_test_spawner_pressure_damage(failures)
	_test_typed_spawner_spawn_profile(failures)
	_test_hostile_shot_signals(failures)
	_test_hostile_shots_respect_walls(failures)
	_test_shooter_shot_tracks_target(failures)
	_test_hostile_projectile_damage_path(failures)
	_test_hostile_projectile_range_matches_player(failures)
	_test_spawner_explosion_effect(failures)
	_test_room_piece_resources(failures)
	_test_dungeon_floor_recipe(failures)
	_test_dungeon_run_seed(failures)
	_test_dungeon_layout_solver(failures)
	_test_room_manager_doors(failures)
	_test_first_boss_profile_and_spread(failures)
	_test_boss_add_replenishment(failures)
	_test_orchestrator_dungeon_start_and_boss(failures)
	_test_orchestrator_main_loop_floor_progression(failures)

	if failures.is_empty():
		print("Smoke tests passed.")
		paused = false
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		paused = false
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


func _test_character_svg_assets(failures: Array[String]) -> void:
	for path in CHARACTER_SVG_PATHS:
		if not FileAccess.file_exists(path):
			failures.append("Missing character SVG asset: %s" % path)
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			failures.append("Character SVG asset could not be opened: %s" % path)
			continue
		var source := file.get_as_text()
		if not source.contains("<svg") or not source.contains("viewBox=\"0 0 128 128\"") or not source.contains("</svg>"):
			failures.append("Character SVG should use a complete 128x128 SVG document: %s" % path)
		if path.ends_with("player_character.svg"):
			if not source.contains("id=\"bottom_half_feet\"") or not source.contains("id=\"top_half_body_and_gun\""):
				failures.append("Player SVG should keep separate top-body/gun and bottom-feet groups for animation.")
			if not source.contains("id=\"left_foot\"") or not source.contains("id=\"right_foot\""):
				failures.append("Player SVG should expose simple oval foot shapes for walking animation.")


func _test_character_art_applied_to_entities(failures: Array[String]) -> void:
	var player_source := _read_text("res://scripts/entities/player_entity.gd")
	if not player_source.contains("res://art/characters/player_upper_body_gun.svg"):
		failures.append("PlayerEntity should draw the upper-body/gun SVG asset.")
	if not player_source.contains("_draw_player_walk_feet"):
		failures.append("PlayerEntity should draw animated oval feet separately from the upper-body art.")
	if not player_source.contains("visual_scale.y = -1.0") or not player_source.contains("aim.x <"):
		failures.append("PlayerEntity should flip the upper-body sprite when aiming left so the character stays upright.")
	var enemy_source := _read_text("res://scripts/entities/enemy_entity.gd")
	for path in [
		"res://art/characters/basic_enemy_chaser.svg",
		"res://art/characters/fast_enemy_runner.svg",
		"res://art/characters/tank_enemy_brute.svg",
		"res://art/characters/shooter_enemy_orbiter.svg",
		"res://art/characters/boss_enemy_overlord.svg"
	]:
		if not enemy_source.contains(path):
			failures.append("EnemyEntity should draw character SVG asset: %s" % path)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


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
		"res://scenes/entities/explosion_effect.tscn",
		"res://scenes/entities/parry_absorb_effect.tscn",
		"res://scenes/entities/door_entity.tscn"
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
					"UI/AmmoCounterPanel",
					"UI/HUDBackground",
					"UI/ScorePanel/ScoreLabel",
					"UI/PausePanel/PauseStatsLabel",
					"UI/PausePanel/PauseConfirmPanel",
					"UI/DungeonMinimap",
					"UI/GameOverPanel/GameOverPromptLabel",
					"UI/GameOverPanel/GameOverTallyLabel",
					"UI/LevelSelectPanel/LevelListLabel",
					"UI/WinPanel/WinPromptLabel",
					"World/DoorLayer",
					"World/EffectLayer",
					"Managers/InputManager",
					"Managers/EffectsManager",
					"Managers/AudioManager",
					"Managers/DungeonManager",
					"Managers/RoomManager"
				]
				for node_path in required_nodes:
					if not instance.has_node(node_path):
						failures.append("Main scene missing HUD node: %s" % node_path)
				if instance.has_node("UI/HUDLabel"):
					var hud_label: Label = instance.get_node("UI/HUDLabel")
					if hud_label.anchor_top < 0.95:
						failures.append("HUD state info should be anchored in a lower screen corner.")
				if instance.has_node("UI/ScorePanel"):
					var score_panel: Control = instance.get_node("UI/ScorePanel")
					if score_panel.anchor_left != 0.5 or score_panel.anchor_right != 0.5 or score_panel.offset_top > 24.0:
						failures.append("Score panel should sit prominently at the upper middle of the screen.")
				if instance.has_node("UI/CombatPanel"):
					var combat_panel: Control = instance.get_node("UI/CombatPanel")
					if combat_panel.size.y > 96.0:
						failures.append("Upper-right combat panel should stay compact enough to read as health-only.")
				if instance.has_node("Managers/InputManager"):
					var input_manager_node: Node = instance.get_node("Managers/InputManager")
					if input_manager_node.process_mode != Node.PROCESS_MODE_ALWAYS:
						failures.append("InputManager should process while paused so pause controls can resume.")
				if instance.has_node("UI/PausePanel"):
					var pause_panel: Control = instance.get_node("UI/PausePanel")
					if pause_panel.process_mode != Node.PROCESS_MODE_WHEN_PAUSED:
						failures.append("Pause panel should use WhenPaused process mode.")
				if instance.has_node("UI/GameOverPanel/GameOverTallyLabel") and instance.has_node("UI/GameOverPanel/GameOverPromptLabel"):
					var game_over_tally: Control = instance.get_node("UI/GameOverPanel/GameOverTallyLabel")
					var game_over_prompt: Control = instance.get_node("UI/GameOverPanel/GameOverPromptLabel")
					if game_over_tally.offset_bottom + 24.0 > game_over_prompt.offset_top:
						failures.append("Game-over tally should leave clear space above the restart prompt.")
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
	var basic = load("res://resources/enemies/basic_enemy.tres")
	var shooter = load("res://resources/enemies/shooter_enemy.tres")
	if basic.max_health > 2:
		failures.append("Basic enemies should stay quick to kill without ammo upgrades.")
	if tank.max_health < 9 or tank.body_radius < 29.0 or tank.speed >= 82.0:
		failures.append("Tank enemy profile does not read as slower, larger, and tougher.")
	if float(tank.knockback_multiplier) > 0.0:
		failures.append("Tank enemy profile should ignore bullet knockback.")
	if fast.max_health > 1 or fast.body_radius >= 18.0 or fast.speed <= 100.0:
		failures.append("Fast enemy profile does not read as smaller, faster, and weaker.")
	if shooter.max_health > 3:
		failures.append("Shooter enemies should be less gummy without upgrades.")
	if shooter.behavior_kind != "shooter" or shooter.projectile_speed != 250.0 or shooter.projectile_damage != 1:
		failures.append("Shooter enemy profile is missing shooter behavior or slow bullet tuning.")
	for path in SPAWNER_PROFILE_PATHS:
		var profile = load(path)
		if profile == null:
			failures.append("Spawner profile failed to load: %s" % path)
			continue
		if profile.enemy_profile == null:
			failures.append("Spawner profile has no enemy profile: %s" % path)
		if not profile.shoots_projectiles:
			failures.append("Spawner profiles should all shoot as general-type units: %s" % path)
		if profile.move_speed <= 0.0:
			failures.append("Spawner profiles should move slowly as general-type units: %s" % path)
	var tank_spawner = load("res://resources/spawners/tank_spawner.tres")
	var fast_spawner = load("res://resources/spawners/fast_spawner.tres")
	var basic_spawner = load("res://resources/spawners/basic_spawner.tres")
	var shooter_spawner = load("res://resources/spawners/shooter_spawner.tres")
	if tank_spawner.max_health < 34 or tank_spawner.body_radius < 44.0:
		failures.append("Tank spawner profile should be tougher and larger.")
	if fast_spawner.max_health > 10 or fast_spawner.body_radius >= 31.0:
		failures.append("Fast spawner profile should be smaller and fragile.")
	if basic_spawner.projectile_speed != 250.0 or basic_spawner.projectile_radius != 7.0:
		failures.append("Basic spawner should fire a standard shooter-spawner style projectile.")
	if fast_spawner.projectile_speed <= basic_spawner.projectile_speed or fast_spawner.projectile_radius >= basic_spawner.projectile_radius:
		failures.append("Fast spawner should fire a smaller, faster projectile.")
	if tank_spawner.projectile_speed >= basic_spawner.projectile_speed or tank_spawner.projectile_radius <= basic_spawner.projectile_radius:
		failures.append("Tank spawner should fire a larger, slower projectile.")
	if shooter_spawner.shot_projectile_count < 3 or shooter_spawner.shot_spread_degrees <= 0.0:
		failures.append("Shooter spawner should fire a sweeping three-shot pulse.")
	if basic_spawner.spawn_interval < 3.2 or basic_spawner.spawn_interval > 3.8:
		failures.append("Basic spawner interval should be softened around its two-enemy pulse.")
	if fast_spawner.spawn_interval < 2.1 or fast_spawner.spawn_interval > 2.7:
		failures.append("Fast spawner interval should be softened around its three-enemy pulse.")
	if shooter_spawner.spawn_interval > 3.6 or tank_spawner.spawn_interval > 4.6:
		failures.append("Shooter and tank spawner intervals should keep their existing pressure roles.")
	if int(basic_spawner.spawn_batch_count) != 2:
		failures.append("Basic spawners should spawn two normal enemies per pulse.")
	if int(fast_spawner.spawn_batch_count) != 3:
		failures.append("Fast spawners should spawn three small enemies per pulse.")
	if int(tank_spawner.spawn_batch_count) != 1 or int(shooter_spawner.spawn_batch_count) != 1:
		failures.append("Tank and shooter spawners should spawn one enemy per pulse.")


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
	var pause_count := [0]
	manager.restart_requested.connect(func() -> void:
		restart_count[0] += 1
	)
	manager.pause_requested.connect(func() -> void:
		pause_count[0] += 1
	)
	var event := InputEventKey.new()
	event.keycode = KEY_R
	event.physical_keycode = KEY_R
	event.pressed = true
	manager._unhandled_input(event)
	var controller_event := InputEventJoypadButton.new()
	controller_event.button_index = JOY_BUTTON_A
	controller_event.pressed = true
	manager._unhandled_input(controller_event)
	var start_event := InputEventJoypadButton.new()
	start_event.button_index = JOY_BUTTON_START
	start_event.pressed = true
	manager._unhandled_input(start_event)
	if restart_count[0] != 2:
		failures.append("InputManager should emit restart_requested for R key and controller A.")
	if pause_count[0] != 1:
		failures.append("InputManager should emit pause_requested for controller Start.")
	manager.free()


func _test_parry_input_and_cooldown(failures: Array[String]) -> void:
	var input = load("res://scripts/managers/input_manager.gd").new()
	var parry_inputs := [0]
	input.parry_requested.connect(func() -> void:
		parry_inputs[0] += 1
	)
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_Q
	key_event.physical_keycode = KEY_Q
	key_event.pressed = true
	input._unhandled_input(key_event)
	var controller_event := InputEventJoypadButton.new()
	controller_event.button_index = JOY_BUTTON_RIGHT_SHOULDER
	controller_event.pressed = true
	input._unhandled_input(controller_event)
	if parry_inputs[0] != 2:
		failures.append("InputManager should emit parry_requested for Q and controller right shoulder.")
	input.free()

	var player_layer := Node2D.new()
	var manager = load("res://scripts/managers/player_manager.gd").new()
	var parry_count := [0]
	root.add_child(player_layer)
	root.add_child(manager)
	manager.initialize({
		"player_layer": player_layer
	})
	manager.parry_cooldown_seconds = 2.0
	manager.parry_requested.connect(func(_origin, effect_radius, perfect_radius, enemy_knockback) -> void:
		if effect_radius > perfect_radius and enemy_knockback > 0.0:
			parry_count[0] += 1
	)
	manager.reset_run()
	manager.set_enabled(true)
	if not bool(manager.player._parry_ready) or manager.player._parry_ready_flash_remaining <= 0.0:
		failures.append("Player should show a clear ready flash when parry is available.")
	manager.request_parry()
	manager.request_parry()
	if parry_count[0] != 1:
		failures.append("PlayerManager parry should fire once and then respect cooldown.")
	if bool(manager.player._parry_ready):
		failures.append("Player parry-ready indicator should clear while parry is on cooldown.")
	if manager.get_parry_cooldown_remaining() <= 0.0:
		failures.append("PlayerManager parry should start a long cooldown.")
	manager._process(2.1)
	manager.request_parry()
	if parry_count[0] != 2:
		failures.append("PlayerManager parry should become available again after cooldown.")
	manager.free()
	player_layer.free()


func _test_player_disable_stops_movement(failures: Array[String]) -> void:
	var player_layer := Node2D.new()
	var manager = load("res://scripts/managers/player_manager.gd").new()
	root.add_child(player_layer)
	root.add_child(manager)
	manager.initialize({
		"player_layer": player_layer
	})
	manager.reset_run()
	manager.set_enabled(true)
	manager.set_move_vector(Vector2.RIGHT)
	manager.player.velocity = Vector2.RIGHT * 300.0
	manager.set_enabled(false)
	if manager.player.move_vector != Vector2.ZERO or manager.player.velocity != Vector2.ZERO:
		failures.append("Disabling PlayerManager should stop residual player movement.")
	manager.free()
	player_layer.free()


func _test_pause_menu_flow(failures: Array[String]) -> void:
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load for pause menu test.")
		return
	var main = scene.instantiate()
	root.add_child(main)
	if main.player_manager == null:
		_prime_main_for_direct_test_calls(main)
		main._connect_manager_signals()
		main._initialize_managers()
		main._enter_level_select()
	main._selected_level_index = 0
	main._start_selected_level()
	if main._status != "RUNNING":
		failures.append("Pause test should begin from running gameplay.")
	if bool(main._tree_pause_requested):
		failures.append("Starting gameplay should clear SceneTree.paused.")
	main._on_pause_requested()
	if main._status != "PAUSED" or not main.pause_panel.visible:
		failures.append("Pause request should show the pause panel and enter PAUSED state.")
	if not bool(main._tree_pause_requested):
		failures.append("Pause request should set SceneTree.paused.")
	if main.player_manager.enabled:
		failures.append("Pause should disable gameplay managers.")
	if main.pause_stats_label.text.find("Attributes") < 0:
		failures.append("Pause menu should show run stats and attribute adjustments.")
	main._on_menu_confirm_requested()
	if main._status != "PAUSE_EXIT_CONFIRM" or not main.pause_confirm_panel.visible:
		failures.append("Pause confirm should open an exit-to-main-menu confirmation prompt.")
	if not bool(main._tree_pause_requested):
		failures.append("Exit confirmation should keep the SceneTree paused.")
	main._on_menu_back_requested()
	if main._status != "PAUSED" or main.pause_confirm_panel.visible:
		failures.append("Pause back should cancel the exit confirmation prompt.")
	if not bool(main._tree_pause_requested):
		failures.append("Returning from pause confirmation should keep the SceneTree paused.")
	main._on_pause_requested()
	if main._status != "RUNNING" or main.pause_panel.visible or not main.player_manager.enabled:
		failures.append("Pause request from PAUSED should resume gameplay.")
	if bool(main._tree_pause_requested):
		failures.append("Resuming from pause should clear SceneTree.paused.")
	main._on_pause_requested()
	main._on_menu_confirm_requested()
	main._on_menu_confirm_requested()
	if main._status != "LEVEL_SELECT" or main.pause_panel.visible:
		failures.append("Confirming pause exit should return to level select.")
	if bool(main._tree_pause_requested):
		failures.append("Returning to level select from pause should clear SceneTree.paused.")
	paused = false
	main.free()


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
	if int(modifiers["projectile_count"]) != 3:
		failures.append("Spread shot should use a tuned three-way spread.")
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
	if fire_rate.max_stacks < 16 or move_speed.max_stacks < 16 or damage.max_stacks < 14 or size.max_stacks < 14:
		failures.append("Permanent upgrade stack ceilings should be higher for longer dungeon runs.")
	manager.set_enabled(true)
	manager._process(99.0)
	if manager.get_active_effects().is_empty():
		failures.append("Ammo upgrades should not expire by timer.")
	manager.free()


func _test_ammo_type_balance(failures: Array[String]) -> void:
	var spread = load("res://resources/upgrades/spread_shot.tres")
	var pierce = load("res://resources/upgrades/piercing_shot.tres")
	var chain = load("res://resources/upgrades/chain_lightning.tres")
	var fire = load("res://resources/upgrades/fire_burst.tres")
	var water = load("res://resources/upgrades/water_swell.tres")
	var manager = load("res://scripts/managers/upgrade_manager.gd").new()
	var projectile_manager = load("res://scripts/managers/projectile_manager.gd").new()
	if int(spread.max_ammo) > 48 or int(pierce.max_ammo) > 48 or int(chain.max_ammo) > 36 or int(fire.max_ammo) > 40 or int(water.max_ammo) > 42:
		failures.append("Ammo upgrade caps should be trimmed so stacked synergies cannot sustain too long.")
	manager.activate_upgrade(pierce)
	var modifiers: Dictionary = manager.get_modifiers()
	if float(modifiers["damage_multiplier"]) < 1.5:
		failures.append("Piercing Shot should have a precision damage fallback.")
	var packet = projectile_manager._create_damage_packet(modifiers, Vector2.ZERO, Vector2.RIGHT)
	if packet.damage < 2:
		failures.append("Piercing Shot should create a 2-damage projectile with current base damage.")
	manager.activate_upgrade(spread)
	for _index in range(12):
		manager.consume_shot()
	var before_pierce: int = int(manager._active_effects["piercing_shot"]["ammo"])
	var before_spread: int = int(manager._active_effects["spread_shot"]["ammo"])
	var ammo_added: int = manager.add_ammo_to_active_upgrades(8)
	var after_pierce: int = int(manager._active_effects["piercing_shot"]["ammo"])
	var after_spread: int = int(manager._active_effects["spread_shot"]["ammo"])
	if ammo_added != 8 or after_pierce + after_spread - before_pierce - before_spread != 8:
		failures.append("Parry ammo should be a shared refill pool across active ammo upgrades.")
	if after_pierce - before_pierce > 5 or after_spread - before_spread > 5:
		failures.append("Shared parry ammo refill should not grant the full award to every stacked ammo type.")
	projectile_manager.free()
	manager.free()


func _test_low_ammo_warning(failures: Array[String]) -> void:
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load for low ammo warning test.")
		return
	var main = scene.instantiate()
	root.add_child(main)
	if main.player_manager == null:
		_prime_main_for_direct_test_calls(main)
		main._connect_manager_signals()
		main._initialize_managers()
		main._enter_level_select()
	main._selected_level_index = 0
	main._start_selected_level()
	var spread = load("res://resources/upgrades/spread_shot.tres")
	main.upgrade_manager.activate_upgrade(spread)
	for _index in range(max(int(spread.max_ammo) - 8, 0)):
		main.upgrade_manager.consume_shot()
	main._update_hud()
	if main.player_manager.player == null or not bool(main.player_manager.player._ammo_warning_active):
		failures.append("Low ammo should create a visible warning around the player.")
	elif not String(main.player_manager.player._ammo_warning_text).begins_with("SP"):
		failures.append("Low ammo warning should identify the nearly empty ammo upgrade.")
	main.free()


func _test_parry_absorbs_hostile_projectiles_for_ammo(failures: Array[String]) -> void:
	var projectile_layer := Node2D.new()
	var projectile_manager = load("res://scripts/managers/projectile_manager.gd").new()
	var upgrade_manager = load("res://scripts/managers/upgrade_manager.gd").new()
	root.add_child(projectile_layer)
	root.add_child(projectile_manager)
	projectile_manager.initialize({
		"projectile_layer": projectile_layer
	})
	projectile_manager.set_enabled(true)
	upgrade_manager.activate_upgrade(load("res://resources/upgrades/spread_shot.tres"))
	var spread_max_ammo := int(load("res://resources/upgrades/spread_shot.tres").max_ammo)
	for _index in range(20):
		upgrade_manager.consume_shot()
	projectile_manager.fire_hostile(Vector2(12.0, 0.0), Vector2.RIGHT, {"speed": 250.0, "damage": 1, "radius": 7.0})
	projectile_manager.fire_hostile(Vector2(82.0, 0.0), Vector2.RIGHT, {"speed": 250.0, "damage": 1, "radius": 7.0})
	projectile_manager.fire_hostile(Vector2(220.0, 0.0), Vector2.RIGHT, {"speed": 250.0, "damage": 1, "radius": 7.0})
	projectile_manager.fire(Vector2(12.0, 12.0), Vector2.RIGHT, {})
	var absorbed: Dictionary = projectile_manager.absorb_hostile_projectiles(Vector2.ZERO, 100.0, 24.0)
	if int(absorbed["absorbed_count"]) != 2:
		failures.append("Parry should erase hostile projectiles inside the effect radius only.")
	if int(absorbed["perfect_count"]) != 1 or int(absorbed["ammo_awarded"]) != 11:
		failures.append("Parry should award 10 ammo for close bullets and 1 ammo for other absorbed bullets.")
	var absorb_infos: Array = absorbed.get("absorbed_projectiles", [])
	var absorb_visual_perfect_count := 0
	for info in absorb_infos:
		if not (info is Dictionary) or not info.has("position"):
			failures.append("Parry absorbed projectile metadata should include visual positions.")
		elif bool(info.get("perfect", false)):
			absorb_visual_perfect_count += 1
	if absorb_infos.size() != 2 or absorb_visual_perfect_count != 1:
		failures.append("Parry absorption should report one visual entry per erased hostile projectile and mark perfect parries.")
	if projectile_manager._projectiles.size() != 2:
		failures.append("Parry should leave outside hostile bullets and player bullets alive.")
	var ammo_added: int = upgrade_manager.add_ammo_to_active_upgrades(int(absorbed["ammo_awarded"]))
	var active_effects: Array = upgrade_manager.get_active_effects()
	if ammo_added != 11 or active_effects.is_empty() or int(active_effects[0]["ammo"]) != spread_max_ammo - 9:
		failures.append("Parry ammo should refill currently active ammo upgrades.")
	projectile_manager.free()
	projectile_layer.free()
	upgrade_manager.free()


func _test_parry_absorb_visuals_and_ammo_flash(failures: Array[String]) -> void:
	var effect_layer := Node2D.new()
	var effects_manager = load("res://scripts/managers/effects_manager.gd").new()
	root.add_child(effect_layer)
	root.add_child(effects_manager)
	effects_manager.initialize({
		"effect_layer": effect_layer
	})
	effects_manager.set_enabled(true)
	effects_manager.play_parry_absorbs([
		{"position": Vector2(24.0, 0.0), "perfect": true, "radius": 7.0},
		{"position": Vector2(86.0, 0.0), "perfect": false, "radius": 7.0}
	], Vector2.ZERO)
	if effect_layer.get_child_count() != 2:
		failures.append("EffectsManager should create one swoop effect for each absorbed hostile projectile.")
	var perfect_visual_found := false
	for child in effect_layer.get_children():
		if bool(child.get("is_perfect")):
			perfect_visual_found = true
	if not perfect_visual_found:
		failures.append("Perfect parried bullets should create a distinct shine-capable absorb effect.")
	effects_manager.free()
	effect_layer.free()

	var scene = load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load for parry absorb HUD flash test.")
		return
	var main = scene.instantiate()
	root.add_child(main)
	if main.player_manager == null:
		_prime_main_for_direct_test_calls(main)
		main._connect_manager_signals()
		main._initialize_managers()
		main._enter_level_select()
	main._selected_level_index = 0
	main._start_selected_level()
	var spread = load("res://resources/upgrades/spread_shot.tres")
	main.upgrade_manager.activate_upgrade(spread)
	for _index in range(8):
		main.upgrade_manager.consume_shot()
	main.projectile_manager.fire_hostile(Vector2(18.0, 0.0), Vector2.RIGHT, {"speed": 250.0, "damage": 1, "radius": 7.0})
	main._on_player_parry_requested(Vector2.ZERO, 100.0, 24.0, 430.0)
	if main._ammo_refill_flash_remaining <= 0.0:
		failures.append("Parry ammo refill should trigger a short HUD flash timer.")
	if main._ammo_refill_perfect_flash_remaining <= 0.0:
		failures.append("Perfect parry ammo refill should trigger a stronger HUD flash timer.")
	if Engine.time_scale >= 1.0:
		failures.append("Perfect parry should briefly slow down time.")
	if main.player_manager.player == null or main.player_manager.player._perfect_parry_flash_remaining <= 0.0:
		failures.append("Perfect parry should create a bright player flash.")
	if main.get_node("World/EffectLayer").get_child_count() <= 0:
		failures.append("Parry absorption should create a visible swoop effect in the effect layer.")
	else:
		var absorb_effect = main.get_node("World/EffectLayer").get_child(0)
		var absorb_target: Vector2 = absorb_effect.get("end_position")
		if absorb_target.distance_squared_to(Vector2.ZERO) <= 1.0:
			failures.append("Parry absorb effects should fly toward ammo counters instead of ending on the player.")
	main._process(0.12)
	if main.ammo_counter_panel.get_child_count() <= 0:
		failures.append("Active ammo upgrades should render ammo counter squares.")
	else:
		var row: Control = main.ammo_counter_panel.get_child(0)
		if row.get_node_or_null("RefillFlash") == null:
			failures.append("Ammo counter squares should flash while parry ammo fills them.")
		if row.get_node_or_null("PerfectRefillFlash") == null:
			failures.append("Perfect parry ammo counter squares should flash white.")
		if row.position.y >= -10.0:
			failures.append("Perfect parry ammo counter squares should visibly jump higher during refill feedback.")
	main._stop_perfect_parry_slowmo()
	main.free()


func _test_audio_assets_and_pitch_variation(failures: Array[String]) -> void:
	for path in SFX_PATHS:
		if not FileAccess.file_exists(path):
			failures.append("Sound effect should live in the shared audio folder: %s" % path)
			continue
		if load(path) == null:
			failures.append("Sound effect failed to load: %s" % path)
	var manager = load("res://scripts/managers/audio_manager.gd").new()
	root.add_child(manager)
	manager.set_enabled(true)
	manager._rng.seed = 12345
	manager.play_player_shot()
	manager.play_player_shot()
	manager.play_parry_ready()
	manager.play_perfect_parry()
	if manager._active_players.size() != 4:
		failures.append("AudioManager should create short-lived AudioStreamPlayers for overlapping SFX.")
	else:
		var first_player: AudioStreamPlayer = manager._active_players[0]
		var second_player: AudioStreamPlayer = manager._active_players[1]
		var ready_player: AudioStreamPlayer = manager._active_players[2]
		var perfect_player: AudioStreamPlayer = manager._active_players[3]
		if first_player.stream == null or perfect_player.stream == null:
			failures.append("AudioManager should assign streams before playback.")
		if first_player.pitch_scale == second_player.pitch_scale:
			failures.append("Repeated SFX should receive pitch variation from AudioStreamPlayer controls.")
		if first_player.pitch_scale < 0.88 or first_player.pitch_scale > 1.12:
			failures.append("Player shot pitch variation is outside its expected range.")
		if ready_player.pitch_scale < 0.96 or ready_player.pitch_scale > 1.08:
			failures.append("Parry-ready pitch variation is outside its expected range.")
		if perfect_player.pitch_scale < 0.96 or perfect_player.pitch_scale > 1.04:
			failures.append("Perfect parry follow-up pitch variation is outside its expected range.")
	manager.set_enabled(false)
	if manager._active_players.size() != 0:
		failures.append("AudioManager should clear active SFX players when disabled.")
	manager.play_game_over()
	if manager._active_players.size() != 1:
		failures.append("Game-over SFX should be allowed to play after gameplay audio is disabled.")
	else:
		var game_over_player: AudioStreamPlayer = manager._active_players[0]
		if game_over_player.stream == null:
			failures.append("Game-over SFX should assign a stream before playback.")
		if game_over_player.pitch_scale < 0.97 or game_over_player.pitch_scale > 1.03:
			failures.append("Game-over pitch variation is outside its expected range.")
	manager.reset_run()
	manager.free()


func _test_reward_driven_pickup_drops(failures: Array[String]) -> void:
	var pickup_layer := Node2D.new()
	var manager = load("res://scripts/managers/item_manager.gd").new()
	root.add_child(pickup_layer)
	root.add_child(manager)
	manager.initialize({
		"pickup_layer": pickup_layer
	})
	manager.reset_run()
	if manager.get_pickup_count() != 0:
		failures.append("ItemManager should not seed free map pickups at run start.")
	manager.set_enabled(true)
	manager._process(manager.pickup_spawn_interval + 1.0)
	if manager.get_pickup_count() != 0:
		failures.append("ItemManager should not spawn random timed map pickups.")
	if manager.enemy_permanent_drop_chance > 0.2 or manager.enemy_permanent_drop_chance < 0.16:
		failures.append("Enemy permanent drop chance should be reduced for larger battles.")
	if manager.enemy_temporary_drop_chance > 0.065:
		failures.append("Enemy ammo upgrade drops should be trimmed for higher enemy counts.")
	if manager.enemy_heal_drop_chance > 0.11:
		failures.append("Enemy heal drops should be trimmed for higher enemy counts.")
	if manager.enemy_temporary_drop_chance >= manager.enemy_permanent_drop_chance:
		failures.append("Enemy ammo upgrade drops should be infrequent compared to permanent drops.")
	if manager.enemy_heal_drop_chance <= manager.enemy_temporary_drop_chance:
		failures.append("Enemy heal drops should be slightly more frequent than ammo upgrade drops.")
	manager.spawner_full_heal_drop_chance = 0.0
	manager.drop_spawner_reward(Vector2.ZERO)
	if manager.get_pickup_count() != 1:
		failures.append("Spawner destruction should always create one reward pickup.")
	var pickup = manager._pickups[0]
	if pickup == null or pickup.upgrade_effect == null or (pickup.upgrade_effect.has_method("get_pickup_kind") and pickup.upgrade_effect.get_pickup_kind() == "permanent"):
		failures.append("Spawner ammo reward should be an ammo/shot upgrade, not a permanent upgrade.")
	manager.clear_pickups()
	manager.spawner_full_heal_drop_chance = 1.0
	manager.drop_spawner_reward(Vector2.ZERO)
	if manager.get_pickup_count() != 1:
		failures.append("Forced spawner full-heal reward should create one pickup.")
	else:
		var full_heal_pickup = manager._pickups[0]
		if full_heal_pickup.upgrade_effect == null or full_heal_pickup.upgrade_effect.get_pickup_kind() != "heal" or int(full_heal_pickup.upgrade_effect.heal_amount) < 99:
			failures.append("Spawner full-heal reward should use a full heal pickup resource.")
	manager.clear_pickups()
	manager.enemy_temporary_drop_chance = 0.0
	manager.enemy_permanent_drop_chance = 0.0
	manager.enemy_heal_drop_chance = 1.0
	manager.roll_enemy_drop(Vector2.ZERO)
	if manager.get_pickup_count() != 1:
		failures.append("Forced enemy heal drop should create one pickup.")
	else:
		var heal_pickup = manager._pickups[0]
		if heal_pickup.upgrade_effect == null or heal_pickup.upgrade_effect.get_pickup_kind() != "heal":
			failures.append("Enemy heal drop should use the heal pickup resource.")
	manager.free()
	pickup_layer.free()


func _test_health_pickup_and_player_healing(failures: Array[String]) -> void:
	var heal = load("res://resources/pickups/small_heal.tres")
	if heal == null:
		failures.append("Small heal pickup resource failed to load.")
		return
	if heal.get_pickup_kind() != "heal" or heal.heal_amount != 1:
		failures.append("Small heal pickup should heal exactly 1 health.")
	var full_heal = load("res://resources/pickups/full_heal.tres")
	if full_heal == null or full_heal.get_pickup_kind() != "heal" or int(full_heal.heal_amount) < 99:
		failures.append("Full heal pickup should restore enough health to cap the player.")
	var player = load("res://scenes/entities/player_entity.tscn").instantiate()
	player.health = 3
	player.heal(heal.heal_amount)
	if player.health != 4:
		failures.append("Player small heal pickup did not restore 1 health.")
	player.heal(full_heal.heal_amount)
	if player.health != player.max_health:
		failures.append("Player full heal should cap at max health.")
	player.free()


func _test_projectile_knockback_packet(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/projectile_manager.gd").new()
	var packet = manager._create_damage_packet({}, Vector2(10.0, 4.0), Vector2.RIGHT)
	if packet.knockback <= 0.0:
		failures.append("Projectile damage packet did not include knockback.")
	if packet.knockback_direction.distance_to(Vector2.RIGHT) > 0.001:
		failures.append("Projectile damage packet did not preserve knockback direction.")
	manager.free()


func _test_projectile_reset_clears_visible_projectiles(failures: Array[String]) -> void:
	var projectile_layer := Node2D.new()
	var manager = load("res://scripts/managers/projectile_manager.gd").new()
	root.add_child(projectile_layer)
	root.add_child(manager)
	manager.initialize({
		"projectile_layer": projectile_layer
	})
	manager.set_enabled(true)
	manager.fire(Vector2.ZERO, Vector2.RIGHT, {})
	var stray = load("res://scenes/entities/projectile_entity.tscn").instantiate()
	projectile_layer.add_child(stray)
	if projectile_layer.get_child_count() < 2:
		failures.append("Projectile reset test setup should include tracked and stray projectiles.")
	manager.reset_run()
	if not manager._projectiles.is_empty():
		failures.append("ProjectileManager.reset_run should clear its tracked projectile list.")
	for child in projectile_layer.get_children():
		if is_instance_valid(child) and child.visible and not child.is_queued_for_deletion():
			failures.append("ProjectileManager.reset_run should hide and queue every projectile layer child.")
	manager.free()
	projectile_layer.free()


func _test_parry_pushes_enemies_without_damage(failures: Array[String]) -> void:
	var enemy_layer := Node2D.new()
	var manager = load("res://scripts/managers/enemy_manager.gd").new()
	root.add_child(enemy_layer)
	root.add_child(manager)
	manager.initialize({
		"enemy_layer": enemy_layer
	})
	manager.set_enabled(true)
	var profile = load("res://resources/enemies/basic_enemy.tres")
	var close_enemy = manager.spawn_enemy(profile, Vector2(30.0, 0.0))
	var far_enemy = manager.spawn_enemy(profile, Vector2(300.0, 0.0))
	var close_health: int = close_enemy.health
	var pushed_count: int = manager.apply_parry_pushback(Vector2.ZERO, 100.0, 430.0)
	if pushed_count != 1:
		failures.append("Parry should push enemies inside its effect range only.")
	if close_enemy.health != close_health:
		failures.append("Parry pushback should not damage enemies.")
	if close_enemy._knockback_velocity.length_squared() <= 0.001:
		failures.append("Parried close enemy should receive pushback velocity.")
	if far_enemy._knockback_velocity.length_squared() > 0.001:
		failures.append("Parry should not push enemies outside its effect range.")
	manager.free()
	enemy_layer.free()


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


func _test_enemy_pathing_steers_around_walls(failures: Array[String]) -> void:
	var enemy = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	enemy.initialize(load("res://resources/enemies/fast_enemy.tres"))
	enemy.global_position = Vector2.ZERO
	enemy.set_arena_definition(
		Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0)),
		0,
		[Rect2(90.0, -90.0, 46.0, 180.0)]
	)
	enemy.set_target_position(Vector2.RIGHT * 320.0)
	var velocity: Vector2 = enemy._get_chaser_velocity(enemy.target_position - enemy.global_position)
	if velocity.length_squared() <= 0.001:
		failures.append("Enemy wall pathing should produce a steering velocity.")
	if abs(velocity.y) <= 1.0:
		failures.append("Enemy wall pathing should steer around an internal wall instead of pushing straight into it.")
	enemy.free()


func _test_enemy_soft_separation_without_hard_collision(failures: Array[String]) -> void:
	var enemy_layer := Node2D.new()
	var manager = load("res://scripts/managers/enemy_manager.gd").new()
	root.add_child(enemy_layer)
	root.add_child(manager)
	manager.initialize({
		"enemy_layer": enemy_layer
	})
	manager.set_enabled(true)
	var profile = load("res://resources/enemies/basic_enemy.tres")
	var first = manager.spawn_enemy(profile, Vector2.ZERO)
	var second = manager.spawn_enemy(profile, Vector2(8.0, 0.0))
	if first == null or second == null:
		failures.append("Soft separation test could not spawn enemies.")
	else:
		if (int(first.collision_mask) & 2) != 0 or (int(second.collision_mask) & 2) != 0:
			failures.append("Enemies should not hard-collide with other enemies.")
		manager._physics_process(0.016)
		if first._crowd_separation_velocity.length_squared() <= 0.001 or second._crowd_separation_velocity.length_squared() <= 0.001:
			failures.append("Nearby enemies should receive soft outward crowd separation.")
	manager.free()
	enemy_layer.free()


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


func _test_spawner_pressure_damage(failures: Array[String]) -> void:
	var spawner_layer := Node2D.new()
	var manager = load("res://scripts/managers/spawner_manager.gd").new()
	var level = load("res://resources/levels/level_01_square.tres")
	root.add_child(spawner_layer)
	root.add_child(manager)
	manager.initialize({
		"spawner_layer": spawner_layer
	})
	manager.reset_run(level)
	if manager._spawners.is_empty():
		failures.append("Pressure damage test could not create a spawner.")
	else:
		var spawner = manager._spawners[0]
		spawner.health = 10
		spawner.max_health = 10
		var close_packet = load("res://scripts/resources/damage_packet.gd").new()
		close_packet.damage = 1
		close_packet.source_position = spawner.global_position + Vector2(24.0, 0.0)
		manager.apply_damage(spawner, close_packet)
		if spawner.health != 8:
			failures.append("Close pressure shots should deal bonus damage to spawners.")
		var far_packet = load("res://scripts/resources/damage_packet.gd").new()
		far_packet.damage = 1
		far_packet.source_position = spawner.global_position + Vector2(600.0, 0.0)
		manager.apply_damage(spawner, far_packet)
		if spawner.health != 7:
			failures.append("Distant shots should not receive spawner pressure damage.")
	manager.free()
	spawner_layer.free()


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
		var expected_initial_requests := 0
		for created_spawner in manager._spawners:
			expected_initial_requests += int(created_spawner.spawn_batch_count)
		if requested_profiles.size() < expected_initial_requests:
			failures.append("SpawnerManager should request opening enemies from each spawner when enabled.")
		var previous_request_count := requested_profiles.size()
		manager._on_spawner_spawn_ready(spawner, spawner.global_position)
		var pulse_count := requested_profiles.size() - previous_request_count
		if pulse_count != int(spawner.spawn_batch_count):
			failures.append("SpawnerManager should emit one spawn request per spawner batch count.")
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

	for profile_path in SPAWNER_PROFILE_PATHS:
		var spawner = load("res://scenes/entities/enemy_spawner_entity.tscn").instantiate()
		var spawner_profile = load(profile_path)
		var spawner_shots: Array[Dictionary] = []
		spawner.initialize_from_profile(spawner_profile)
		spawner.set_target_position(Vector2.RIGHT * 300.0)
		spawner.shot_ready.connect(func(_spawner, _origin, direction, shot_config) -> void:
			if direction.length_squared() > 0.001 and int(shot_config["damage"]) == 1:
				spawner_shots.append(shot_config)
		)
		spawner._try_emit_shot()
		if spawner_shots.size() != 1:
			failures.append("Spawner did not emit a hostile shot-ready signal: %s" % profile_path)
		elif int(spawner_shots[0].get("projectile_count", 1)) != max(int(spawner_profile.shot_projectile_count), 1):
			failures.append("Spawner hostile shot request did not include its projectile count: %s" % profile_path)
		spawner.free()
	var moving_spawner = load("res://scenes/entities/enemy_spawner_entity.tscn").instantiate()
	moving_spawner.initialize_from_profile(load("res://resources/spawners/basic_spawner.tres"))
	moving_spawner.global_position = Vector2.ZERO
	moving_spawner.set_target_position(Vector2.RIGHT * 900.0)
	if moving_spawner._get_general_velocity().x <= 0.0:
		failures.append("Spawner generals should slowly move toward tactical range.")
	moving_spawner.free()


func _test_hostile_shots_respect_walls(failures: Array[String]) -> void:
	var wall_rect := Rect2(68.0, -80.0, 24.0, 160.0)
	var wall := StaticBody2D.new()
	wall.name = "ShotBlockingWall"
	wall.collision_layer = 32
	wall.collision_mask = 0
	wall.add_to_group("arena_walls")
	wall.global_position = Vector2(80.0, 0.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24.0, 160.0)
	shape.shape = rect
	wall.add_child(shape)
	root.add_child(wall)

	var enemy = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	var enemy_shots := [0]
	enemy.initialize(load("res://resources/enemies/shooter_enemy.tres"))
	enemy.global_position = Vector2.ZERO
	enemy.set_arena_definition(Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0)), 0, [wall_rect])
	enemy.set_target_position(Vector2.RIGHT * 260.0)
	enemy.shot_ready.connect(func(_enemy, _origin, _direction, _shot_config) -> void:
		enemy_shots[0] += 1
	)
	root.add_child(enemy)
	enemy._shot_cooldown_remaining = 0.0
	enemy._try_emit_shot(enemy.target_position - enemy.global_position)
	if enemy_shots[0] != 0:
		failures.append("Shooter enemies should not fire hostile projectiles through arena walls.")

	var spawner = load("res://scenes/entities/enemy_spawner_entity.tscn").instantiate()
	var spawner_shots := [0]
	spawner.initialize_from_profile(load("res://resources/spawners/basic_spawner.tres"))
	spawner.global_position = Vector2.ZERO
	spawner.set_arena_definition(Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0)), 0, [wall_rect])
	spawner.set_target_position(Vector2.RIGHT * 260.0)
	spawner.shot_ready.connect(func(_spawner, _origin, _direction, _shot_config) -> void:
		spawner_shots[0] += 1
	)
	root.add_child(spawner)
	spawner._try_emit_shot()
	if spawner_shots[0] != 0:
		failures.append("Spawner generals should not fire hostile projectiles through arena walls.")

	enemy.free()
	spawner.free()
	wall.free()


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


func _test_room_piece_resources(failures: Array[String]) -> void:
	var combat_piece_count := 0
	for path in ROOM_PIECE_PATHS:
		var piece = load(path)
		if piece == null:
			failures.append("Room piece resource failed to load: %s" % path)
			continue
		if piece.footprint_cells.is_empty():
			failures.append("Room piece has no footprint cells: %s" % path)
		if piece.connector_directions.is_empty():
			failures.append("Room piece has no connector directions: %s" % path)
		var level = piece.create_level_definition()
		if level == null:
			failures.append("Room piece could not create a level definition: %s" % path)
			continue
		for placement in level.spawner_placements:
			if placement == null or placement.profile == null:
				failures.append("Room piece has a spawner placement without a profile: %s" % path)
				continue
			if not ArenaGeometry.contains_point(placement.position, level.arena_bounds, int(level.arena_shape)):
				failures.append("Room piece spawner placement is outside its playable shape: %s" % path)
			for wall_rect in level.wall_rects:
				if wall_rect.has_point(placement.position):
					failures.append("Room piece spawner placement is inside a wall rect: %s" % path)
		if level.boss_profile != null and not ArenaGeometry.contains_point(level.boss_spawn_position, level.arena_bounds, int(level.arena_shape)):
			failures.append("Room piece boss spawn position is outside its playable shape: %s" % path)
		if piece.room_kind == "combat":
			combat_piece_count += 1
			if level.get_spawner_count() < 4:
				failures.append("Large combat room piece should carry at least four spawners: %s" % path)
			if int(level.max_active_enemies) < 30:
				failures.append("Combat room pieces should support larger battles: %s" % path)
		if piece.room_kind == "challenge" and level.get_spawner_count() < 5:
			failures.append("Challenge room piece should carry at least five spawners: %s" % path)
		if piece.room_kind == "boss":
			if level.get_spawner_count() < 4:
				failures.append("Boss room should include supporting spawners.")
			if level.max_active_enemies <= 1:
				failures.append("Boss room max active enemies should allow boss plus spawned enemies.")
	if combat_piece_count < 7:
		failures.append("Dungeon solver should have at least seven combat room pieces to vary floor shapes.")


func _test_dungeon_floor_recipe(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/dungeon_manager.gd").new()
	root.add_child(manager)
	manager.reset_run(1)
	var floor_one_count: int = manager.get_room_count()
	var floor_one_boss_path: Array[String] = _get_path_to_room_kind(manager, "boss")
	if floor_one_boss_path.is_empty():
		failures.append("Dungeon floor recipe should always create a reachable boss room.")
	var floor_one_kinds: Dictionary = _get_dungeon_room_kind_counts(manager)
	if int(floor_one_kinds.get("treasure", 0)) < 1:
		failures.append("Dungeon floor recipe should place a guaranteed treasure branch.")
	if int(floor_one_kinds.get("challenge", 0)) < 1:
		failures.append("Dungeon floor recipe should place a guaranteed challenge branch.")
	if int(floor_one_kinds.get("combat", 0)) < 2:
		failures.append("Dungeon floor recipe should include multiple combat rooms before the boss.")

	manager.reset_run(5)
	var floor_five_boss_path: Array[String] = _get_path_to_room_kind(manager, "boss")
	if manager.get_room_count() <= floor_one_count:
		failures.append("Later dungeon floors should generate more rooms than floor one.")
	if floor_five_boss_path.size() <= floor_one_boss_path.size():
		failures.append("Later dungeon floors should grow the required boss path.")

	var wide_piece = load("res://resources/rooms/combat_wide.tres")
	var floor_one_level = wide_piece.create_level_definition()
	manager.floor_number = 1
	manager._apply_floor_scaling(floor_one_level, "combat")
	var floor_five_level = wide_piece.create_level_definition()
	manager.floor_number = 5
	manager._apply_floor_scaling(floor_five_level, "combat")
	if floor_five_level.get_spawner_count() <= floor_one_level.get_spawner_count():
		failures.append("Later dungeon floors should add extra typed spawners to combat rooms.")
	if int(floor_five_level.max_active_enemies) <= int(floor_one_level.max_active_enemies):
		failures.append("Later dungeon floors should increase room enemy budgets.")
	manager.free()


func _test_dungeon_run_seed(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/dungeon_manager.gd").new()
	root.add_child(manager)
	manager.reset_run(3, 246813)
	var first_signature := _get_dungeon_layout_signature(manager)
	var first_floor_seed: int = manager.get_floor_generation_seed()
	manager.reset_run(3, 246813)
	var repeated_signature := _get_dungeon_layout_signature(manager)
	if first_signature != repeated_signature:
		failures.append("DungeonManager should generate the same layout for the same run seed and floor.")
	if manager.get_run_seed() != 246813:
		failures.append("DungeonManager should store the active run seed.")
	manager.reset_run(3, 13579)
	if manager.get_floor_generation_seed() == first_floor_seed:
		failures.append("Different run seeds should create different floor generation seeds.")
	manager.reset_run(4, 246813)
	if manager.get_floor_generation_seed() == first_floor_seed:
		failures.append("Different floors in the same run should create different floor generation seeds.")
	manager.free()


func _get_dungeon_layout_signature(manager) -> String:
	var parts: Array[String] = []
	for room_info in manager.get_minimap_rooms():
		var connections: Dictionary = room_info["connections"]
		var connection_keys: Array = connections.keys()
		connection_keys.sort()
		var connection_parts: Array[String] = []
		for key in connection_keys:
			connection_parts.append("%s:%s" % [String(key), String(connections[key])])
		parts.append("%s|%s|%s|%s" % [
			String(room_info["id"]),
			String(room_info["kind"]),
			str(room_info["anchor"]),
			",".join(connection_parts)
		])
	return "\n".join(parts)


func _get_dungeon_room_kind_counts(manager) -> Dictionary:
	var counts: Dictionary = {}
	for room_info in manager.get_minimap_rooms():
		var kind := String(room_info["kind"])
		counts[kind] = int(counts.get(kind, 0)) + 1
	return counts


func _get_path_to_room_kind(manager, target_kind: String) -> Array[String]:
	var rooms_by_id: Dictionary = {}
	for room_info in manager.get_minimap_rooms():
		rooms_by_id[String(room_info["id"])] = room_info
	var queue: Array = [["start"]]
	var visited: Dictionary = {"start": true}
	while not queue.is_empty():
		var path: Array = queue.pop_front()
		var room_id := String(path[path.size() - 1])
		var room_info: Dictionary = rooms_by_id.get(room_id, {})
		if String(room_info.get("kind", "")) == target_kind:
			var typed_path: Array[String] = []
			for path_room_id in path:
				typed_path.append(String(path_room_id))
			return typed_path
		var connections: Dictionary = room_info.get("connections", {})
		for next_room_id in connections.values():
			var next_id := String(next_room_id)
			if visited.has(next_id):
				continue
			visited[next_id] = true
			var next_path: Array = path.duplicate()
			next_path.append(next_id)
			queue.append(next_path)
	return []


func _test_dungeon_layout_solver(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/dungeon_manager.gd").new()
	root.add_child(manager)
	manager.reset_run()
	manager.set_enabled(true)
	if manager.get_room_count() < 8:
		failures.append("DungeonManager should place the full prototype set of room pieces.")
	if manager.get_revealed_room_count() != 1:
		failures.append("DungeonManager should reveal only the start room at run start.")
	var footprint_total := 0
	for room_id in manager.get_room_ids():
		var state: Dictionary = manager._rooms[room_id]
		footprint_total += state["piece"].footprint_cells.size()
	if manager.get_occupied_cell_count() != footprint_total:
		failures.append("DungeonManager placed overlapping room footprints.")
	if manager.current_room_id != "start":
		failures.append("DungeonManager should start in the start room.")
	if not manager.enter_direction("east"):
		failures.append("DungeonManager should allow leaving the cleared start room through the east connector.")
	if manager.get_revealed_room_count() < 2:
		failures.append("DungeonManager should reveal rooms as the player traverses them.")
	manager.mark_current_room_cleared()
	if not manager.enter_direction("east"):
		failures.append("DungeonManager should connect the wide room to the junction.")
	manager.mark_current_room_cleared()
	if not manager.enter_direction("east"):
		failures.append("DungeonManager should connect the junction to the boss room.")
	if not manager.is_current_boss_room():
		failures.append("DungeonManager east branch should lead to the boss room.")
	manager.free()


func _test_room_manager_doors(failures: Array[String]) -> void:
	var door_layer := Node2D.new()
	var dungeon = load("res://scripts/managers/dungeon_manager.gd").new()
	var manager = load("res://scripts/managers/room_manager.gd").new()
	root.add_child(door_layer)
	root.add_child(dungeon)
	root.add_child(manager)
	dungeon.reset_run()
	manager.initialize({
		"door_layer": door_layer
	})
	manager.set_enabled(true)
	manager.load_room(dungeon.get_current_level_definition(), dungeon.get_current_door_infos(), true)
	if manager.get_door_count() < 2:
		failures.append("RoomManager should create doors for the start room's connected exits.")
	if door_layer.get_child_count() != manager.get_door_count():
		failures.append("RoomManager should add door entities to the injected door layer.")
	for child in door_layer.get_children():
		if not child.is_in_group("dungeon_doors"):
			failures.append("Door entity is missing the dungeon_doors group.")
		if not child.unlocked:
			failures.append("RoomManager should unlock doors for an already-cleared room.")
		if (child.collision_mask & 1) == 0:
			failures.append("Door entity should watch the player collision layer.")
	manager.free()
	dungeon.free()
	door_layer.free()


func _test_first_boss_profile_and_spread(failures: Array[String]) -> void:
	var boss_profile = load("res://resources/enemies/first_boss_enemy.tres")
	if boss_profile == null:
		failures.append("First boss profile failed to load.")
		return
	if boss_profile.behavior_kind != "boss" or boss_profile.max_health < 60:
		failures.append("First boss profile should use boss behavior and boss-scale health.")
	if boss_profile.shot_projectile_count < 3 or boss_profile.shot_spread_degrees <= 0.0:
		failures.append("First boss profile should fire a visible spread pattern.")
	var boss = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	var shot_configs: Array[Dictionary] = []
	boss.initialize(boss_profile)
	boss.shot_ready.connect(func(_enemy, _origin, _direction, shot_config) -> void:
		shot_configs.append(shot_config)
	)
	boss._shot_cooldown_remaining = 0.0
	boss._try_emit_shot(Vector2.RIGHT * 360.0)
	if shot_configs.is_empty():
		failures.append("Boss enemy did not emit a hostile shot request.")
	elif int(shot_configs[0].get("projectile_count", 1)) < 3:
		failures.append("Boss hostile shot request did not include spread projectile count.")
	boss.free()

	var projectile_layer := Node2D.new()
	var projectile_manager = load("res://scripts/managers/projectile_manager.gd").new()
	root.add_child(projectile_layer)
	root.add_child(projectile_manager)
	projectile_manager.initialize({
		"projectile_layer": projectile_layer
	})
	projectile_manager.set_enabled(true)
	projectile_manager.fire_hostile(Vector2.ZERO, Vector2.RIGHT, {
		"speed": boss_profile.projectile_speed,
		"damage": boss_profile.projectile_damage,
		"radius": boss_profile.projectile_radius,
		"projectile_count": boss_profile.shot_projectile_count,
		"spread_angle_degrees": boss_profile.shot_spread_degrees
	})
	if projectile_manager._projectiles.size() != boss_profile.shot_projectile_count:
		failures.append("ProjectileManager did not expand boss hostile spread into multiple projectiles.")
	projectile_manager.free()
	projectile_layer.free()


func _test_boss_add_replenishment(failures: Array[String]) -> void:
	var enemy_layer := Node2D.new()
	var manager = load("res://scripts/managers/enemy_manager.gd").new()
	root.add_child(enemy_layer)
	root.add_child(manager)
	manager.initialize({
		"enemy_layer": enemy_layer
	})
	manager.set_enabled(true)
	manager.spawn_enemy(load("res://resources/enemies/first_boss_enemy.tres"), Vector2.ZERO)
	manager._physics_process(0.1)
	if manager._get_boss_add_count() != 3:
		failures.append("Boss should summon three shooter adds when it has none.")
	var removed_add = null
	for enemy in manager._enemies:
		if is_instance_valid(enemy) and bool(enemy.get_meta("boss_add", false)):
			removed_add = enemy
			break
	if removed_add != null:
		manager._on_enemy_health_depleted(removed_add)
		removed_add.queue_free()
	manager._physics_process(manager.boss_add_replenish_interval + 0.1)
	if manager._get_boss_add_count() != 3:
		failures.append("Boss should replenish shooter adds back to three.")
	manager.free()
	enemy_layer.free()


func _test_orchestrator_dungeon_start_and_boss(failures: Array[String]) -> void:
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load for dungeon orchestrator test.")
		return
	var main = scene.instantiate()
	root.add_child(main)
	if main.dungeon_manager == null:
		_prime_main_for_direct_test_calls(main)
		main._connect_manager_signals()
		main._initialize_managers()
		main._enter_level_select()
	main._selected_level_index = 6
	main._start_selected_level()
	if main._status != "DUNGEON":
		failures.append("GameOrchestrator did not enter dungeon mode from the level-select dungeon option.")
	if main.dungeon_manager.current_room_id != "start":
		failures.append("Dungeon run should begin in the start room.")
	if main.room_manager.get_door_count() < 2:
		failures.append("Dungeon start room should expose connected doors.")
	if main.player_manager.player == null:
		failures.append("Dungeon start did not spawn the player.")
	if not main.dungeon_minimap.visible:
		failures.append("Dungeon minimap should be visible during dungeon runs.")

	main.dungeon_manager.enter_direction("east")
	main._load_dungeon_current_room("east", false)
	main.spawner_manager.clear_spawners()
	main.enemy_manager.reset_run()
	main.dungeon_manager.mark_current_room_cleared()
	main.dungeon_manager.enter_direction("east")
	main._load_dungeon_current_room("east", false)
	main.spawner_manager.clear_spawners()
	main.enemy_manager.reset_run()
	main.dungeon_manager.mark_current_room_cleared()
	main.dungeon_manager.enter_direction("east")
	main._load_dungeon_current_room("east", false)
	if not main.dungeon_manager.is_current_boss_room():
		failures.append("Dungeon orchestrator route did not arrive at the boss room.")
	else:
		var boss_found := false
		for enemy in main.enemy_manager._enemies:
			if is_instance_valid(enemy) and enemy.behavior_kind == "boss":
				boss_found = true
		if not boss_found:
			failures.append("Boss room should spawn the first boss enemy.")
		var expected_boss_room_pressure: int = 1 + main.spawner_manager.get_spawner_count() * main.spawner_manager.initial_enemies_per_spawner
		if main.enemy_manager.get_enemy_count() < expected_boss_room_pressure:
			failures.append("Boss room should spawn boss plus opening-wave enemies.")
	if main.spawner_manager.get_spawner_count() < 4:
		failures.append("Boss room should spawn supporting spawners.")
	if main.spawner_manager.max_active_enemies <= main.enemy_manager.get_enemy_count():
		failures.append("Boss room spawner budget should allow spawned adds while the boss is alive.")
	if main.dungeon_manager.get_revealed_room_count() < 4:
		failures.append("Dungeon minimap reveal state should advance along the traversed boss route.")
	main.free()


func _test_orchestrator_main_loop_floor_progression(failures: Array[String]) -> void:
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load for main-loop orchestrator test.")
		return
	var main = scene.instantiate()
	root.add_child(main)
	if main.dungeon_manager == null:
		_prime_main_for_direct_test_calls(main)
		main._connect_manager_signals()
		main._initialize_managers()
		main._enter_level_select()
	main._selected_level_index = 7
	main._start_selected_level()
	if not main._is_main_loop_run or main._status != "DUNGEON":
		failures.append("Main Game Loop Test should enter dungeon main-loop mode.")
	if main._main_loop_floor != 1:
		failures.append("Main loop should start on floor 1.")
	var run_seed: int = main._run_seed
	if run_seed <= 0:
		failures.append("Main loop should create a positive run seed.")
	if main.dungeon_manager.get_run_seed() != run_seed:
		failures.append("Main loop should pass its run seed into DungeonManager.")
	main._score = 0
	var boss = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	boss.initialize(load("res://resources/enemies/first_boss_enemy.tres"))
	main._on_enemy_defeated(boss, boss.score_value)
	if main._status != "BOSS_CLEARING":
		failures.append("Main loop boss kill should enter a short boss-clear explosion transition.")
	if main._score < 1000:
		failures.append("Main loop boss kill should award a large floor-clear score bonus.")
	if main._run_boss_kills != 1:
		failures.append("Main loop should tally boss kills immediately.")
	if main.win_panel.visible:
		failures.append("Main loop should wait for the boss explosion before showing the next-floor panel.")
	if not bool(main._tree_pause_requested):
		failures.append("Main loop boss-clear transition should pause the SceneTree so enemies stop moving.")
	if main.enemy_manager.enabled or main.spawner_manager.enabled or main.projectile_manager.enabled:
		failures.append("Main loop boss-clear transition should disable gameplay managers while the explosion plays.")
	main._process(main.BOSS_CLEAR_DELAY_SECONDS + 0.1)
	if main._status != "FLOOR_CLEARED":
		failures.append("Main loop boss clear should move to floor-cleared state after the explosion.")
	if main._run_floors_cleared != 1:
		failures.append("Main loop should tally cleared floors after the boss explosion resolves.")
	if not main.win_panel.visible:
		failures.append("Main loop floor clear should show the next-floor panel after the boss explosion.")
	main._on_menu_confirm_requested()
	if main._main_loop_floor != 2 or main._status != "DUNGEON":
		failures.append("Main loop confirm should advance to the next generated floor.")
	if bool(main._tree_pause_requested):
		failures.append("Advancing to the next floor should unpause the SceneTree.")
	if main._run_seed != run_seed or main.dungeon_manager.get_run_seed() != run_seed:
		failures.append("Main loop should preserve the same run seed when advancing floors.")
	main._on_player_defeated(main.player_manager.player)
	if main._status != "DOWN":
		failures.append("Main loop death should enter DOWN state.")
	if main.game_over_tally_label == null or not main.game_over_tally_label.text.contains("Floors cleared"):
		failures.append("Main loop death should display a run tally.")
	if main.game_over_tally_label == null or not main.game_over_tally_label.text.contains("Seed:"):
		failures.append("Main loop death tally should display the run seed.")
	boss.free()
	main.free()


func _prime_main_for_direct_test_calls(main) -> void:
	main.input_manager = main.get_node("Managers/InputManager")
	main.player_manager = main.get_node("Managers/PlayerManager")
	main.projectile_manager = main.get_node("Managers/ProjectileManager")
	main.enemy_manager = main.get_node("Managers/EnemyManager")
	main.spawner_manager = main.get_node("Managers/SpawnerManager")
	main.item_manager = main.get_node("Managers/ItemManager")
	main.upgrade_manager = main.get_node("Managers/UpgradeManager")
	main.combat_manager = main.get_node("Managers/CombatManager")
	main.effects_manager = main.get_node("Managers/EffectsManager")
	main.dungeon_manager = main.get_node("Managers/DungeonManager")
	main.room_manager = main.get_node("Managers/RoomManager")
	main.audio_manager = main.get_node("Managers/AudioManager")
	main.arena_view = main.get_node("World/Arena")
	main.gameplay_camera = main.get_node("Camera2D")
	main.hud_background = main.get_node("UI/HUDBackground")
	main.hud_label = main.get_node("UI/HUDLabel")
	main.score_panel = main.get_node("UI/ScorePanel")
	main.score_label = main.get_node("UI/ScorePanel/ScoreLabel")
	main.dungeon_minimap = main.get_node("UI/DungeonMinimap")
	main.combat_panel = main.get_node("UI/CombatPanel")
	main.health_fill = main.get_node("UI/CombatPanel/HealthBarBack/HealthBarFill")
	main.health_label = main.get_node("UI/CombatPanel/HealthLabel")
	main.invulnerability_fill = main.get_node("UI/CombatPanel/InvulnerabilityBarBack/InvulnerabilityBarFill")
	main.attribute_label = main.get_node("UI/CombatPanel/AttributeLabel")
	main.stats_label = main.get_node("UI/CombatPanel/StatsLabel")
	main.ammo_counter_panel = main.get_node("UI/AmmoCounterPanel")
	main.pause_panel = main.get_node("UI/PausePanel")
	main.pause_stats_label = main.get_node("UI/PausePanel/PauseStatsLabel")
	main.pause_prompt_label = main.get_node("UI/PausePanel/PausePromptLabel")
	main.pause_confirm_panel = main.get_node("UI/PausePanel/PauseConfirmPanel")
	main.game_over_panel = main.get_node("UI/GameOverPanel")
	main.game_over_title_label = main.get_node("UI/GameOverPanel/GameOverTitle")
	main.game_over_score_label = main.get_node("UI/GameOverPanel/GameOverScoreLabel")
	main.game_over_tally_label = main.get_node("UI/GameOverPanel/GameOverTallyLabel")
	main.game_over_prompt_label = main.get_node("UI/GameOverPanel/GameOverPromptLabel")
	main.level_select_panel = main.get_node("UI/LevelSelectPanel")
	main.level_list_label = main.get_node("UI/LevelSelectPanel/LevelListLabel")
	main.win_panel = main.get_node("UI/WinPanel")
	main.win_title_label = main.get_node("UI/WinPanel/WinTitle")
	main.win_score_label = main.get_node("UI/WinPanel/WinScoreLabel")
	main.win_prompt_label = main.get_node("UI/WinPanel/WinPromptLabel")
