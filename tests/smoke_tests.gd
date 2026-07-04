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
	"res://scripts/entities/projectile_impact_effect.gd",
	"res://scripts/entities/door_entity.gd",
	"res://scripts/entities/floor_exit_portal_entity.gd"
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
	"res://scripts/entities/projectile_impact_effect.gd",
	"res://scripts/entities/door_entity.gd",
	"res://scripts/entities/floor_exit_portal_entity.gd",
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
	"res://scripts/resources/room_interior_generator.gd",
	"res://scripts/resources/health_pickup.gd"
]

const LEVEL_PATHS := [
	"res://resources/levels/level_01_square.tres",
	"res://resources/levels/level_02_diamond.tres",
	"res://resources/levels/level_03_hexagon.tres",
	"res://resources/levels/level_04_cross.tres",
	"res://resources/levels/level_05_circle.tres",
	"res://resources/levels/level_06_maze.tres",
	"res://resources/levels/boss_test_chamber.tres"
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
	"res://audio/bullet_hits_wall.wav",
	"res://audio/bullet_impact.wav",
	"res://audio/enemy_bullet_shot.wav",
	"res://audio/floor_start.wav",
	"res://audio/game_over.wav",
	"res://audio/item_pick_up.wav",
	"res://audio/parry.wav",
	"res://audio/parry_ready.wav",
	"res://audio/perfect_parry_follow_up.wav",
	"res://audio/player_bullet_shot.wav",
	"res://audio/rocket_explosion.wav",
	"res://audio/room_entry.wav"
]

const CHARACTER_SVG_PATHS := [
	"res://art/characters/player_character.svg",
	"res://art/characters/player_body.svg",
	"res://art/characters/player_body_back.svg",
	"res://art/characters/player_body_side.svg",
	"res://art/characters/player_arms_gun.svg",
	"res://art/characters/player_arms_gun_left.svg",
	"res://art/characters/player_resting_pistol.svg",
	"res://art/characters/player_resting_pistol_left.svg",
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

const DUNGEON_OPPOSITE_DIRECTIONS := {
	"north": "south",
	"south": "north",
	"east": "west",
	"west": "east"
}


func _init() -> void:
	paused = false
	var failures: Array[String] = []
	_test_architecture_rules(failures)
	_test_presentation_settings(failures)
	_test_character_svg_assets(failures)
	_test_character_art_applied_to_entities(failures)
	_test_player_shoot_pose_relaxes_to_movement(failures)
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
	_test_projectile_impact_visuals(failures)
	_test_audio_assets_and_pitch_variation(failures)
	_test_reward_driven_pickup_drops(failures)
	_test_health_pickup_and_player_healing(failures)
	_test_projectile_knockback_packet(failures)
	_test_charged_super_shot(failures)
	_test_projectile_reset_clears_visible_projectiles(failures)
	_test_parry_pushes_enemies_without_damage(failures)
	_test_tank_ignores_knockback(failures)
	_test_fast_enemy_contact_range(failures)
	_test_enemy_pathing_steers_around_walls(failures)
	_test_enemy_soft_separation_without_hard_collision(failures)
	_test_water_projectile_hits_each_enemy_once(failures)
	_test_damageable_spawner(failures)
	_test_projectile_hits_spawner(failures)
	_test_general_and_boss_projectile_shields(failures)
	_test_spawner_pressure_damage(failures)
	_test_typed_spawner_spawn_profile(failures)
	_test_hostile_shot_signals(failures)
	_test_spawner_special_attacks(failures)
	_test_hostile_shots_respect_walls(failures)
	_test_shooter_shot_tracks_target(failures)
	_test_hostile_projectile_damage_path(failures)
	_test_hostile_projectile_range_matches_player(failures)
	_test_hostile_rocket_detonation_damage(failures)
	_test_spawner_explosion_effect(failures)
	_test_room_piece_resources(failures)
	_test_room_interior_generator_determinism_and_budget(failures)
	_test_room_interior_generator_validation(failures)
	_test_dungeon_room_interiors_persist(failures)
	_test_void_blockers_are_movement_only(failures)
	_test_dungeon_floor_recipe(failures)
	_test_dungeon_run_seed(failures)
	_test_dungeon_layout_solver(failures)
	_test_room_manager_doors(failures)
	_test_first_boss_profile_and_spread(failures)
	_test_boss_add_replenishment(failures)
	_test_boss_test_level_select(failures)
	_test_orchestrator_dungeon_start_and_boss(failures)
	_test_boss_exit_portal_preview_and_safe_position(failures)
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
		if path.contains("/player_"):
			if source.contains("ground_shadow"):
				failures.append("Player SVG should not include a circular ground shadow or shield halo: %s" % path)
			if source.contains("id=\"mouth\""):
				failures.append("Player SVG should not include a mouth shape: %s" % path)
		if path.ends_with("player_character.svg") or path.ends_with("player_body.svg") or path.ends_with("player_upper_body_gun.svg"):
			if not source.contains("id=\"forehead_bang\""):
				failures.append("Player SVG should include a larger forehead bang shape: %s" % path)
		if path.contains("player_arms_gun"):
			if not source.contains("id=\"arms_and_gun\""):
				failures.append("Player arms/gun SVG should expose an arms_and_gun group.")
		if path.contains("player_resting_pistol"):
			if not source.contains("id=\"resting_pistol\""):
				failures.append("Player resting pistol SVG should expose a resting_pistol group.")
		if path.ends_with("player_body_back.svg"):
			if not source.contains("id=\"body_back_outfit\""):
				failures.append("Player back-facing body SVG should expose a body_back_outfit group.")
		if path.ends_with("player_body_side.svg"):
			if not source.contains("id=\"body_side_outfit\""):
				failures.append("Player side-facing body SVG should expose a body_side_outfit group.")


func _test_character_art_applied_to_entities(failures: Array[String]) -> void:
	var player_source := _read_text("res://scripts/entities/player_entity.gd")
	if not player_source.contains("res://art/characters/player_body.svg"):
		failures.append("PlayerEntity should draw the upright body SVG asset.")
	if not player_source.contains("res://art/characters/player_body_back.svg"):
		failures.append("PlayerEntity should draw a back-facing body SVG asset for upward aim.")
	if not player_source.contains("res://art/characters/player_body_side.svg"):
		failures.append("PlayerEntity should draw a side-facing body SVG asset for side aim.")
	if not player_source.contains("res://art/characters/player_arms_gun.svg"):
		failures.append("PlayerEntity should draw the separate arms/gun SVG asset.")
	if not player_source.contains("_draw_player_walk_feet"):
		failures.append("PlayerEntity should draw animated oval feet separately from the upper-body art.")
	if not player_source.contains("foot_anchor := Vector2.DOWN") or not player_source.contains("body_radius * 1.18"):
		failures.append("PlayerEntity should anchor walking feet low enough to show beneath the upright body.")
	if not player_source.contains("PLAYER_ARMS_GUN_TEXTURE") or not player_source.contains("weapon_aim.angle()"):
		failures.append("PlayerEntity should rotate the separate arms/gun sprite using the normalized aim direction.")
	if not player_source.contains("PLAYER_ARMS_GUN_LEFT_TEXTURE") or not player_source.contains("(-weapon_aim).angle()"):
		failures.append("PlayerEntity should use folded left-facing weapon art so left aim points with the shot direction.")
	if not player_source.contains("PLAYER_RESTING_PISTOL_TEXTURE") or not player_source.contains("PLAYER_RESTING_PISTOL_LEFT_TEXTURE"):
		failures.append("PlayerEntity should draw the lowered off-hand pistol as its own sprite layer.")
	if not player_source.contains("_get_side_resting_pistol_rotation"):
		failures.append("PlayerEntity should only slightly rotate the resting pistol instead of matching the active gun rotation.")
	if not player_source.contains("_draw_vertical_resting_pistols"):
		failures.append("PlayerEntity should draw mirrored resting pistols while front/back facing and not shooting.")
	if not player_source.contains("-forward_tilt + walk_swing") or player_source.contains("-forward_tilt - walk_swing"):
		failures.append("Mirrored vertical resting pistols should visibly alternate their walking swing.")
	if not player_source.contains("is_side_facing: bool = abs(facing.x) >= abs(facing.y)") or not player_source.contains("is_back_facing: bool = not is_side_facing and facing.y < 0.0"):
		failures.append("PlayerEntity should split body facing into 90-degree cardinal aim sectors.")
	if not player_source.contains("body_scale = Vector2(-1.0, 1.0) if facing.x < 0.0 else Vector2.ONE"):
		failures.append("PlayerEntity should mirror the side-facing body for left aim.")
	if not player_source.contains("play_shoot_pose") or not player_source.contains("_get_visual_facing_direction"):
		failures.append("PlayerEntity should hold a brief shooting pose, then return visual facing to movement.")
	if not player_source.contains("if is_back_facing:") or not player_source.contains("_draw_centered_texture(weapon_texture, visual_radius, weapon_rotation, tint)") or not player_source.contains("_draw_centered_texture(body_texture, visual_radius, 0.0, tint, body_scale)"):
		failures.append("PlayerEntity should draw the gun behind the back-facing body when aiming upward.")
	if not player_source.contains("body_radius + 13.0") or player_source.contains("sparkle_center"):
		failures.append("PlayerEntity should use a circular barrier effect, not a pistol glint, when parry is ready.")
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
	if not enemy_source.contains("_visual_direction") or not enemy_source.contains("_update_visual_direction(velocity)"):
		failures.append("EnemyEntity should rotate character art using the last meaningful movement direction.")
	if not enemy_source.contains("velocity.length_squared() > 1.0"):
		failures.append("EnemyEntity should redraw moving enemies so movement-facing rotation updates.")


func _test_player_shoot_pose_relaxes_to_movement(failures: Array[String]) -> void:
	var player = load("res://scenes/entities/player_entity.tscn").instantiate()
	if player._get_visual_facing_direction().distance_to(Vector2.DOWN) > 0.001:
		failures.append("Player should face the camera/front by default at floor start.")
	player.set_move_vector(Vector2.DOWN)
	player.play_shoot_pose(Vector2.UP)
	if player._get_visual_facing_direction().distance_to(Vector2.UP) > 0.001:
		failures.append("Player shooting pose should temporarily face the shot direction.")
	player._process(player.shoot_pose_hold_seconds + 0.05)
	if player._is_shoot_pose_active():
		failures.append("Player shooting pose should expire after its short hold window.")
	if player._get_visual_facing_direction().distance_to(Vector2.DOWN) > 0.001:
		failures.append("Player visual facing should return to movement after shooting pose expires.")
	player.free()


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
		"res://scenes/entities/projectile_impact_effect.tscn",
		"res://scenes/entities/door_entity.tscn",
		"res://scenes/entities/floor_exit_portal_entity.tscn"
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
				if instance.has_node("UI/WinPanel") and instance.has_node("UI/WinPanel/WinScoreLabel") and instance.has_node("UI/WinPanel/WinPromptLabel"):
					var win_panel: Control = instance.get_node("UI/WinPanel")
					var win_score: Label = instance.get_node("UI/WinPanel/WinScoreLabel")
					var win_prompt: Label = instance.get_node("UI/WinPanel/WinPromptLabel")
					if win_panel.size.y < 450.0:
						failures.append("Mission results panel should be tall enough for a full run tally.")
					if win_score.size.y < 240.0:
						failures.append("Mission results score/tally label should reserve enough vertical space.")
					if win_prompt.position.y < win_score.position.y + win_score.size.y + 20.0:
						failures.append("Mission results prompt should sit below the score/tally block without overlap.")
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
				if instance.has_node("World"):
					var world_node: Node = instance.get_node("World")
					if world_node.process_mode != Node.PROCESS_MODE_PAUSABLE:
						failures.append("World gameplay nodes should be explicitly pausable under the always-processing orchestrator.")
				if instance.has_node("Managers"):
					var managers_node: Node = instance.get_node("Managers")
					if managers_node.process_mode != Node.PROCESS_MODE_PAUSABLE:
						failures.append("Gameplay managers should be explicitly pausable under the always-processing orchestrator.")
				if instance.has_node("UI"):
					var ui_node: Node = instance.get_node("UI")
					if ui_node.process_mode != Node.PROCESS_MODE_ALWAYS:
						failures.append("UI should stay processable while gameplay is paused.")
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
	if LEVEL_PATHS.size() != 7:
		failures.append("Expected seven level resources after adding the boss test chamber.")
	for path in LEVEL_PATHS:
		var level = load(path)
		if level == null:
			failures.append("Level resource failed to load: %s" % path)
			continue
		var spawner_count: int = level.get_spawner_count()
		if spawner_count <= 0 and level.boss_profile == null:
			failures.append("Level has no spawners: %s" % path)
		if level.boss_profile != null:
			if not ArenaGeometry.contains_point(level.boss_spawn_position, level.arena_bounds, int(level.arena_shape)):
				failures.append("Level boss spawn position is outside the playable arena shape: %s" % path)
			for wall_rect in level.wall_rects:
				if wall_rect.has_point(level.boss_spawn_position):
					failures.append("Level boss spawn position is inside an arena wall: %s" % path)
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
	if tank_spawner.max_health < 51 or tank_spawner.body_radius < 44.0:
		failures.append("Tank spawner profile should be tougher and larger.")
	if fast_spawner.max_health > 15 or fast_spawner.body_radius >= 31.0:
		failures.append("Fast spawner profile should be smaller and fragile.")
	if basic_spawner.projectile_speed != 250.0 or basic_spawner.projectile_radius != 7.0:
		failures.append("Basic spawner should fire a standard shooter-spawner style projectile.")
	if fast_spawner.projectile_speed <= basic_spawner.projectile_speed or fast_spawner.projectile_radius >= basic_spawner.projectile_radius:
		failures.append("Fast spawner should fire a smaller, faster projectile.")
	if tank_spawner.projectile_speed >= basic_spawner.projectile_speed or tank_spawner.projectile_radius <= basic_spawner.projectile_radius:
		failures.append("Tank spawner should fire a larger, slower projectile.")
	if String(basic_spawner.special_attack_kind) != "spread":
		failures.append("Basic spawner should teach the boss-style three-shot spread special.")
	if String(fast_spawner.special_attack_kind) != "rapid" or fast_spawner.shot_cooldown >= basic_spawner.shot_cooldown:
		failures.append("Fast spawner should teach quick hostile shots before later boss specials.")
	if String(tank_spawner.special_attack_kind) != "rocket":
		failures.append("Tank spawner should teach the boss-style rocket special.")
	if String(shooter_spawner.special_attack_kind) != "minigun" or shooter_spawner.shot_projectile_count != 1:
		failures.append("Shooter spawner should save its pressure spike for the minigun special.")
	if basic_spawner.spawn_interval < 3.6 or basic_spawner.spawn_interval > 4.1:
		failures.append("Basic spawner interval should be softened around its two-enemy pulse.")
	if fast_spawner.spawn_interval < 2.4 or fast_spawner.spawn_interval > 2.9:
		failures.append("Fast spawner interval should be softened around its three-enemy pulse.")
	if shooter_spawner.spawn_interval > 4.0 or tank_spawner.spawn_interval > 5.2:
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
	main.projectile_manager.fire(Vector2.ZERO, Vector2.RIGHT, {})
	var live_projectile = null
	if main.get_node("World/ProjectileLayer").get_child_count() > 0:
		live_projectile = main.get_node("World/ProjectileLayer").get_child(0)
	else:
		failures.append("Pause test should be able to spawn a live projectile.")
	main.effects_manager.play_explosion(Vector2(40.0, 0.0), 80.0)
	var normal_effect = null
	if main.get_node("World/EffectLayer").get_child_count() > 0:
		normal_effect = main.get_node("World/EffectLayer").get_child(0)
	else:
		failures.append("Pause test should be able to spawn a normal gameplay effect.")
	main._on_pause_requested()
	if main._status != "PAUSED" or not main.pause_panel.visible:
		failures.append("Pause request should show the pause panel and enter PAUSED state.")
	if not bool(main._tree_pause_requested):
		failures.append("Pause request should set SceneTree.paused.")
	if main.player_manager.enabled:
		failures.append("Pause should disable gameplay managers.")
	if live_projectile != null and is_instance_valid(live_projectile) and _get_effective_process_mode(live_projectile) != Node.PROCESS_MODE_PAUSABLE:
		failures.append("Live projectiles should inherit a pausable process mode from the gameplay world.")
	if normal_effect != null and is_instance_valid(normal_effect) and _get_effective_process_mode(normal_effect) != Node.PROCESS_MODE_PAUSABLE:
		failures.append("Normal gameplay effects should use a pausable process mode.")
	var refill_remaining_before_pause_process := 0.5
	main._ammo_refill_flash_remaining = refill_remaining_before_pause_process
	main._process(0.25)
	if main._ammo_refill_flash_remaining < refill_remaining_before_pause_process:
		failures.append("Gameplay HUD feedback timers should not tick down during pause menu processing.")
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
	if live_projectile != null and is_instance_valid(live_projectile) and _get_effective_process_mode(live_projectile) != Node.PROCESS_MODE_PAUSABLE:
		failures.append("Live projectiles should remain pausable after resuming from pause.")
	main._on_pause_requested()
	main._on_menu_confirm_requested()
	main._on_menu_confirm_requested()
	if main._status != "LEVEL_SELECT" or main.pause_panel.visible:
		failures.append("Confirming pause exit should return to level select.")
	if bool(main._tree_pause_requested):
		failures.append("Returning to level select from pause should clear SceneTree.paused.")
	paused = false
	main.free()


func _get_effective_process_mode(node: Node) -> int:
	var current: Node = node
	while current != null:
		if current.process_mode != Node.PROCESS_MODE_INHERIT:
			return current.process_mode
		current = current.get_parent()
	return Node.PROCESS_MODE_PAUSABLE


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
		if child.process_mode != Node.PROCESS_MODE_PAUSABLE:
			failures.append("Normal parry absorb effects should pause with gameplay.")
	if not perfect_visual_found:
		failures.append("Perfect parried bullets should create a distinct shine-capable absorb effect.")
	effects_manager.play_explosion(Vector2(18.0, 0.0), 72.0)
	effects_manager.play_explosion(Vector2(36.0, 0.0), 92.0, 0.85, true)
	var normal_explosion = effect_layer.get_child(effect_layer.get_child_count() - 2)
	var cinematic_explosion = effect_layer.get_child(effect_layer.get_child_count() - 1)
	if normal_explosion.process_mode != Node.PROCESS_MODE_PAUSABLE:
		failures.append("Normal explosion effects should pause with gameplay.")
	if cinematic_explosion.process_mode != Node.PROCESS_MODE_ALWAYS:
		failures.append("Boss-clear cinematic effects should be able to process while the tree is paused.")
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


func _test_projectile_impact_visuals(failures: Array[String]) -> void:
	var effect_layer := Node2D.new()
	var effects_manager = load("res://scripts/managers/effects_manager.gd").new()
	root.add_child(effect_layer)
	root.add_child(effects_manager)
	effects_manager.initialize({
		"effect_layer": effect_layer
	})
	effects_manager.set_enabled(true)
	effects_manager.play_projectile_impact(Vector2(24.0, 8.0), Vector2.RIGHT, 7.0, false)
	effects_manager.play_projectile_impact(Vector2(42.0, 8.0), Vector2.LEFT, 9.0, true)
	if effect_layer.get_child_count() != 2:
		failures.append("EffectsManager should create projectile impact effects for normal and blocked hits.")
	else:
		for child in effect_layer.get_children():
			if child.process_mode != Node.PROCESS_MODE_PAUSABLE:
				failures.append("Projectile impact effects should pause with gameplay.")
		var blocked_effect = effect_layer.get_child(1)
		if not bool(blocked_effect.get("blocked")):
			failures.append("Blocked projectile impacts should use the shield-block visual variant.")
	var orchestrator_source := _read_text("res://scripts/orchestrators/game_orchestrator.gd")
	if not orchestrator_source.contains("play_projectile_impact") or not orchestrator_source.contains("_target_has_active_projectile_shield"):
		failures.append("Projectile hit routing should play impact animations and mark shield-blocked hits.")
	if not orchestrator_source.contains("projectile_expired") or not orchestrator_source.contains("reason == \"wall\"") or not orchestrator_source.contains("reason == \"bounds\""):
		failures.append("Projectile expiry routing should play impact frames for wall, boundary, and dissipating bullets.")
	effects_manager.free()
	effect_layer.free()


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
	manager.play_bullet_wall_hit()
	manager.play_rocket_explosion()
	if manager._active_players.size() != 6:
		failures.append("AudioManager should create short-lived AudioStreamPlayers for overlapping SFX.")
	else:
		var first_player: AudioStreamPlayer = manager._active_players[0]
		var second_player: AudioStreamPlayer = manager._active_players[1]
		var ready_player: AudioStreamPlayer = manager._active_players[2]
		var perfect_player: AudioStreamPlayer = manager._active_players[3]
		var wall_player: AudioStreamPlayer = manager._active_players[4]
		var rocket_player: AudioStreamPlayer = manager._active_players[5]
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
		if wall_player.pitch_scale < 0.1 or wall_player.pitch_scale > 0.9:
			failures.append("Wall-hit pitch variation is outside its expected range.")
		if rocket_player.pitch_scale < 0.92 or rocket_player.pitch_scale > 1.06:
			failures.append("Rocket explosion pitch variation is outside its expected range.")
	var orchestrator_source := _read_text("res://scripts/orchestrators/game_orchestrator.gd")
	if not orchestrator_source.contains("play_bullet_wall_hit") or not orchestrator_source.contains("reason == \"wall\"") or not orchestrator_source.contains("reason == \"bounds\""):
		failures.append("Projectile wall and room-boundary expiry should route to the dedicated wall-hit SFX.")
	if not orchestrator_source.contains("play_rocket_explosion") or not orchestrator_source.contains("_detonate_hostile_rocket"):
		failures.append("Hostile rocket detonation should route to the rocket explosion SFX.")
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
	var rocket_packet = manager._create_hostile_damage_packet({
		"kind": "rocket",
		"damage": 2,
		"knockback": 540.0,
		"explosion_radius": 72.0,
		"explosion_damage_multiplier": 1.0
	}, Vector2.ZERO, Vector2.LEFT)
	if rocket_packet.projectile_kind != "rocket" or rocket_packet.knockback < 500.0:
		failures.append("Hostile rocket packets should carry rocket kind and player knockback.")
	if rocket_packet.explosion_radius < 68.0 or rocket_packet.explosion_radius > 80.0 or rocket_packet.explosion_damage_multiplier <= 0.0:
		failures.append("Hostile rocket packets should carry explosion damage metadata.")
	var player = load("res://scenes/entities/player_entity.tscn").instantiate()
	player.apply_pushback(Vector2.LEFT, rocket_packet.knockback)
	if player._knockback_velocity.length_squared() <= 0.001:
		failures.append("Player entity should accept rocket-style pushback.")
	player.free()
	manager.free()


func _test_charged_super_shot(failures: Array[String]) -> void:
	var player_layer := Node2D.new()
	var player_manager = load("res://scripts/managers/player_manager.gd").new()
	root.add_child(player_layer)
	root.add_child(player_manager)
	player_manager.initialize({
		"player_layer": player_layer
	})
	player_manager.reset_run()
	player_manager.set_enabled(true)
	player_manager.add_super_meter(player_manager.super_meter_max)
	if not player_manager.is_super_ready():
		failures.append("Super meter should become ready when filled.")
	player_manager.request_super_charge_start()
	player_manager._process(player_manager.super_charge_seconds * 0.5)
	if player_manager.get_super_charge_ratio() <= 0.35:
		failures.append("Super charge should build while the input is held.")
	if player_manager.player == null or player_manager.player.speed >= player_manager.player._base_speed:
		failures.append("Charging the super shot should slightly slow player movement.")
	var emitted_shots: Array[Dictionary] = []
	player_manager.super_shot_requested.connect(func(_origin, direction, charge_ratio) -> void:
		emitted_shots.append({
			"direction": direction,
			"charge_ratio": charge_ratio
		})
	)
	player_manager.request_super_charge_release(Vector2.RIGHT)
	if emitted_shots.is_empty():
		failures.append("Releasing the super input should fire a charged shot.")
	else:
		var shot_info: Dictionary = emitted_shots[0]
		if float(shot_info.get("charge_ratio", 0.0)) <= 0.35:
			failures.append("Released super shot should preserve its partial charge ratio.")
		if Vector2(shot_info.get("direction", Vector2.ZERO)).distance_to(Vector2.RIGHT) > 0.001:
			failures.append("Released super shot should fire in the final aim direction.")
	if player_manager.get_super_meter() > 0.0:
		failures.append("Super meter should be spent when the charged shot fires.")
	player_manager.free()
	player_layer.free()

	var projectile_manager = load("res://scripts/managers/projectile_manager.gd").new()
	var partial_packet = projectile_manager._create_super_damage_packet(Vector2.ZERO, Vector2.RIGHT, 0.45)
	var full_packet = projectile_manager._create_super_damage_packet(Vector2.ZERO, Vector2.RIGHT, 1.0)
	if partial_packet.projectile_kind != "super" or not partial_packet.pierces_projectile_shields or not partial_packet.impact_on_strong_targets:
		failures.append("Super shot packets should carry kind, shield-pierce, and strong-impact metadata.")
	if partial_packet.explosion_radius > 0.0:
		failures.append("Partial super shots should not get the full-charge impact explosion.")
	if full_packet.explosion_radius < 100.0 or full_packet.explosion_damage_multiplier <= 0.0 or not full_packet.super_full_charge:
		failures.append("Fully charged super shots should explode on impact.")
	var projectile = load("res://scenes/entities/projectile_entity.tscn").instantiate()
	projectile.damage_packet = full_packet
	var basic_enemy = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	basic_enemy.initialize(load("res://resources/enemies/basic_enemy.tres"))
	var tank_enemy = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	tank_enemy.initialize(load("res://resources/enemies/tank_enemy.tres"))
	if projectile._should_force_impact_on_target(basic_enemy):
		failures.append("Super shots should pierce typical enemies.")
	if not projectile._should_force_impact_on_target(tank_enemy):
		failures.append("Super shots should impact tank/general-scale enemies.")
	var boss_enemy = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	boss_enemy.initialize(load("res://resources/enemies/first_boss_enemy.tres"))
	boss_enemy.activate_projectile_shield(1.0)
	var boss_health_before: int = boss_enemy.health
	if boss_enemy.blocks_projectile_damage(full_packet):
		failures.append("Super shots should pierce active projectile shields instead of being fully blocked.")
	boss_enemy.take_damage(full_packet)
	var shielded_damage: int = boss_health_before - boss_enemy.health
	if shielded_damage <= 0 or shielded_damage >= full_packet.damage:
		failures.append("Shield-piercing super shots should land reduced damage through shields.")
	projectile.free()
	basic_enemy.free()
	tank_enemy.free()
	boss_enemy.free()
	projectile_manager.free()


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
	var tank_enemy = manager.spawn_enemy(load("res://resources/enemies/tank_enemy.tres"), Vector2(60.0, 0.0))
	if manager._get_parry_pushback_size_factor(tank_enemy) >= manager._get_parry_pushback_size_factor(close_enemy):
		failures.append("Parry pushback should scale down for larger enemies.")
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


func _test_general_and_boss_projectile_shields(failures: Array[String]) -> void:
	var packet = load("res://scripts/resources/damage_packet.gd").new()
	packet.damage = 4
	packet.projectile_kind = "normal"

	var spawner = load("res://scenes/entities/enemy_spawner_entity.tscn").instantiate()
	spawner.initialize(10, 3.0, 32.0)
	var general_shield_after_spawn: float = spawner.projectile_shield_after_spawn_seconds
	spawner._timer = 0.42
	spawner._process(0.05)
	if not spawner.is_projectile_shield_active():
		failures.append("Generals should raise a projectile shield shortly before a spawn wave.")
	if bool(spawner.take_damage(packet)) or spawner.health != 10:
		failures.append("General projectile shield should block player projectile damage.")
	spawner.active = false
	spawner._process(1.2)
	if not bool(spawner.take_damage(packet)) or spawner.health != 6:
		failures.append("Generals should take projectile damage once their short shield expires.")
	spawner.free()

	var enemy_layer := Node2D.new()
	var manager = load("res://scripts/managers/enemy_manager.gd").new()
	root.add_child(enemy_layer)
	root.add_child(manager)
	manager.initialize({
		"enemy_layer": enemy_layer
	})
	manager.set_enabled(true)
	var boss = manager.spawn_enemy(load("res://resources/enemies/first_boss_enemy.tres"), Vector2.ZERO)
	manager._physics_process(0.1)
	if boss == null or not is_instance_valid(boss) or not boss.is_projectile_shield_active():
		failures.append("Boss should raise a projectile shield around add replenishment.")
	elif boss._projectile_shield_remaining <= general_shield_after_spawn:
		failures.append("Boss projectile shield should last longer than a general shield.")
	if boss != null and is_instance_valid(boss):
		var boss_health: int = boss.health
		if bool(manager.apply_damage(boss, packet)) or boss.health != boss_health:
			failures.append("Boss projectile shield should block player projectile damage.")
	manager.free()
	enemy_layer.free()


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
	var requested_positions: Array[Vector2] = []
	var player_target := Vector2.ZERO
	root.add_child(manager)
	manager.spawn_requested.connect(func(position, profile) -> void:
		requested_positions.append(position)
		requested_profiles.append(profile)
	)
	manager.initialize({
		"player_position_provider": func() -> Vector2:
			return player_target
	})
	manager.reset_run(level)
	manager.set_enabled(true)
	if manager._spawners.is_empty():
		failures.append("SpawnerManager did not create typed spawners from level placements.")
	else:
		var spawner = manager._spawners[0]
		if not requested_profiles.is_empty():
			failures.append("SpawnerManager should not emit opening enemies before its startup shield window.")
		for created_spawner in manager._spawners:
			if not created_spawner.is_projectile_shield_active():
				failures.append("SpawnerManager should start each spawner in projectile shield state before the opening wave.")
		var expected_initial_requests := 0
		for created_spawner in manager._spawners:
			expected_initial_requests += int(created_spawner.spawn_batch_count) * manager.initial_spawn_batch_multiplier
			if created_spawner._timer < manager._get_initial_spawn_shield_delay() + float(created_spawner.spawn_interval):
				failures.append("SpawnerManager should delay normal spawn timing until after the doubled opening wave.")
		manager._process(manager._get_initial_spawn_shield_delay() + 0.05)
		if requested_profiles.size() < expected_initial_requests:
			failures.append("SpawnerManager should request a doubled opening enemy batch after the startup shield window.")
		var biased_spawn_count := 0
		var checked_spawn_count := 0
		for created_spawner in manager._spawners:
			var to_player: Vector2 = (player_target - created_spawner.global_position).normalized()
			var spawn_count: int = int(manager._get_initial_spawn_batch_count(created_spawner))
			for spawn_index in range(spawn_count):
				var spawn_position: Vector2 = manager._get_initial_spawn_position(created_spawner, 0, spawn_index, spawn_count)
				checked_spawn_count += 1
				if (spawn_position - created_spawner.global_position).dot(to_player) > 0.0:
					biased_spawn_count += 1
			var normal_position: Vector2 = manager._get_spawn_position_around_spawner(created_spawner, 0, int(created_spawner.spawn_batch_count))
			checked_spawn_count += 1
			if (normal_position - created_spawner.global_position).dot(to_player) > 0.0:
				biased_spawn_count += 1
		if checked_spawn_count <= 0 or biased_spawn_count < checked_spawn_count:
			failures.append("SpawnerManager should fan spawn positions toward the player instead of evenly around the spawner.")
		var previous_request_count := requested_profiles.size()
		manager._on_spawner_spawn_ready(spawner, spawner.global_position)
		var pulse_count := requested_profiles.size() - previous_request_count
		if pulse_count != int(spawner.spawn_batch_count):
			failures.append("SpawnerManager should emit one spawn request per spawner batch count.")
		if requested_profiles.is_empty() or requested_profiles[0] != spawner.enemy_profile:
			failures.append("Typed spawner did not request its configured enemy profile.")
		if requested_positions.is_empty():
			failures.append("SpawnerManager should emit concrete spawn positions for requested enemies.")
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


func _test_spawner_special_attacks(failures: Array[String]) -> void:
	var fast_profile = load("res://resources/spawners/fast_spawner.tres")
	var basic_profile = load("res://resources/spawners/basic_spawner.tres")
	var tank_profile = load("res://resources/spawners/tank_spawner.tres")
	var shooter_profile = load("res://resources/spawners/shooter_spawner.tres")
	if String(fast_profile.special_attack_kind) != "rapid" or float(fast_profile.shot_cooldown) >= float(basic_profile.shot_cooldown):
		failures.append("Fast spawners should keep the quick-shot lesson before later boss patterns.")
	if String(basic_profile.special_attack_kind) != "spread":
		failures.append("Basic spawners should telegraph a three-shot spread special.")
	if String(tank_profile.special_attack_kind) != "rocket":
		failures.append("Tank spawners should telegraph a rocket special.")
	if String(shooter_profile.special_attack_kind) != "minigun":
		failures.append("Shooter spawners should telegraph a minigun special.")

	var basic_spawner = load("res://scenes/entities/enemy_spawner_entity.tscn").instantiate()
	var basic_shots: Array[Dictionary] = []
	basic_spawner.initialize_from_profile(basic_profile)
	basic_spawner.global_position = Vector2.ZERO
	basic_spawner.set_target_position(Vector2.RIGHT * 340.0)
	basic_spawner.shot_ready.connect(func(_spawner, _origin, _direction, shot_config) -> void:
		basic_shots.append(shot_config)
	)
	root.add_child(basic_spawner)
	basic_spawner._special_timer = 0.0
	if not basic_spawner._update_special_attack(0.05) or basic_spawner._special_telegraph_remaining <= 0.0:
		failures.append("Spawner specials should begin with a visible windup telegraph.")
	basic_spawner._update_special_attack(basic_spawner.special_telegraph_seconds + 0.05)
	var spread_config: Dictionary = basic_shots[basic_shots.size() - 1] if not basic_shots.is_empty() else {}
	if int(spread_config.get("projectile_count", 0)) != 3 or float(spread_config.get("spread_angle_degrees", 0.0)) <= 0.0:
		failures.append("Basic spawner special should emit a three-shot spread.")
	basic_spawner.free()

	var tank_spawner = load("res://scenes/entities/enemy_spawner_entity.tscn").instantiate()
	var rocket_shots: Array[Dictionary] = []
	var rocket_directions: Array[Vector2] = []
	tank_spawner.initialize_from_profile(tank_profile)
	tank_spawner.global_position = Vector2.ZERO
	tank_spawner.set_target_position(Vector2.RIGHT * 420.0)
	tank_spawner.shot_ready.connect(func(_spawner, _origin, direction, shot_config) -> void:
		rocket_directions.append(direction)
		rocket_shots.append(shot_config)
	)
	root.add_child(tank_spawner)
	tank_spawner._special_timer = 0.0
	tank_spawner._update_special_attack(0.05)
	tank_spawner._update_special_attack(tank_spawner.special_telegraph_seconds + 0.05)
	var rocket_config: Dictionary = rocket_shots[rocket_shots.size() - 1] if not rocket_shots.is_empty() else {}
	var rocket_direction: Vector2 = rocket_directions[rocket_directions.size() - 1] if not rocket_directions.is_empty() else Vector2.ZERO
	if String(rocket_config.get("kind", "")) != "rocket" or not bool(rocket_config.get("exact_lifetime", false)) or not rocket_config.has("target_position"):
		failures.append("Tank spawner special should fire a targeted rocket.")
	elif tank_spawner._recoil_velocity.length_squared() <= 0.001 or tank_spawner._recoil_velocity.dot(rocket_direction) >= 0.0:
		failures.append("Tank spawner rocket launch should push the spawner backward.")
	tank_spawner.free()

	var shooter_spawner = load("res://scenes/entities/enemy_spawner_entity.tscn").instantiate()
	var minigun_shots: Array[Dictionary] = []
	var minigun_directions: Array[Vector2] = []
	shooter_spawner.initialize_from_profile(shooter_profile)
	shooter_spawner.global_position = Vector2.ZERO
	shooter_spawner.set_target_position(Vector2.RIGHT * 360.0)
	shooter_spawner.shot_ready.connect(func(_spawner, _origin, direction, shot_config) -> void:
		minigun_directions.append(direction)
		minigun_shots.append(shot_config)
	)
	root.add_child(shooter_spawner)
	shooter_spawner._special_timer = 0.0
	shooter_spawner._update_special_attack(0.05)
	shooter_spawner._update_special_attack(shooter_spawner.special_telegraph_seconds + 0.05)
	var first_minigun_direction: Vector2 = minigun_directions[minigun_directions.size() - 1] if not minigun_directions.is_empty() else Vector2.ZERO
	var first_minigun_config: Dictionary = minigun_shots[minigun_shots.size() - 1] if not minigun_shots.is_empty() else {}
	var minigun_count: int = minigun_shots.size()
	shooter_spawner._update_special_attack(shooter_spawner.special_minigun_shot_interval + 0.02)
	var second_minigun_direction: Vector2 = minigun_directions[minigun_directions.size() - 1] if not minigun_directions.is_empty() else Vector2.ZERO
	if String(first_minigun_config.get("kind", "")) != "hostile_minigun" or minigun_shots.size() <= minigun_count:
		failures.append("Shooter spawner special should emit rapid minigun shots.")
	elif second_minigun_direction.distance_to(first_minigun_direction) <= 0.001:
		failures.append("Shooter spawner minigun should sweep between individual shots.")
	shooter_spawner.free()


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
	manager.reset_run()
	manager.fire_hostile(Vector2.ZERO, Vector2.RIGHT, {
		"speed": 640.0,
		"damage": 2,
		"radius": 11.5,
		"kind": "rocket",
		"lifetime": 0.2,
		"exact_lifetime": true,
		"explosion_radius": 72.0,
		"explosion_damage_multiplier": 1.0
	})
	if manager._projectiles.is_empty():
		failures.append("ProjectileManager did not create exact-lifetime rocket projectile.")
	else:
		var rocket = manager._projectiles[0]
		if abs(rocket.lifetime_seconds - 0.2) > 0.001:
			failures.append("Targeted rockets should keep their exact detonation lifetime.")
		var expire_info: Dictionary = manager._get_projectile_expire_info(rocket)
		var packet = expire_info.get("damage_packet", null)
		if packet == null or float(packet.explosion_radius) < 68.0 or float(packet.explosion_radius) > 80.0:
			failures.append("Rocket expiry info should retain its damage packet for detonation.")
	manager.free()
	layer.free()


func _test_hostile_rocket_detonation_damage(failures: Array[String]) -> void:
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load for rocket detonation test.")
		return
	var main = scene.instantiate()
	root.add_child(main)
	if main.dungeon_manager == null:
		_prime_main_for_direct_test_calls(main)
		main._connect_manager_signals()
		main._initialize_managers()
		main._enter_level_select()
	main._selected_level_index = 0
	main._start_selected_level()
	main.enemy_manager.reset_run()
	main.spawner_manager.clear_spawners()
	main.enemy_manager.set_enabled(true)
	var enemy_profile = load("res://resources/enemies/basic_enemy.tres")
	var enemy = main.enemy_manager.spawn_enemy(enemy_profile, Vector2(64.0, 0.0))
	if enemy == null:
		failures.append("Rocket detonation test could not spawn an enemy.")
	else:
		var health_before: int = enemy.health
		var packet = load("res://scripts/resources/damage_packet.gd").new()
		packet.damage = 1
		packet.projectile_kind = "rocket"
		packet.explosion_radius = 120.0
		packet.explosion_damage_multiplier = 1.0
		packet.knockback = 120.0
		packet.knockback_direction = Vector2.RIGHT
		main._detonate_hostile_rocket(Vector2.ZERO, 11.5, packet, false)
		if enemy.health >= health_before:
			failures.append("Hostile rocket detonation should damage nearby enemies.")
	main.free()


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


func _test_room_interior_generator_determinism_and_budget(failures: Array[String]) -> void:
	var generator = load("res://scripts/resources/room_interior_generator.gd").new()
	var combat_piece = load("res://resources/rooms/combat_wide.tres")
	var challenge_piece = load("res://resources/rooms/challenge_zigzag.tres")
	var connections := {"west": "start", "east": "boss"}
	var first = generator.generate(combat_piece, "path_1", 3, 424242, connections)
	var repeated = generator.generate(combat_piece, "path_1", 3, 424242, connections)
	if _get_level_generation_signature(first) != _get_level_generation_signature(repeated):
		failures.append("RoomInteriorGenerator should be deterministic for seed/floor/room id.")
	var different_seed = generator.generate(combat_piece, "path_1", 3, 424243, connections)
	var different_floor = generator.generate(combat_piece, "path_1", 4, 424242, connections)
	var first_signature := _get_level_generation_signature(first)
	if first_signature == _get_level_generation_signature(different_seed):
		failures.append("RoomInteriorGenerator should vary generated interiors across run seeds.")
	if first_signature == _get_level_generation_signature(different_floor):
		failures.append("RoomInteriorGenerator should vary generated interiors across floors.")

	var floor_one = generator.generate(combat_piece, "floor_one", 1, 1111, connections)
	if floor_one.get_spawner_count() < 4 or floor_one.get_spawner_count() > 6:
		failures.append("Generated combat rooms should respect the v1 spawner count bounds.")
	if int(floor_one.max_active_enemies) != clamp(24 + 1 * 4 + floor_one.get_spawner_count() * 2, 30, 52):
		failures.append("Generated combat rooms should compute floor-scaled max active enemies.")
	if _level_uses_spawner_profile(floor_one, "fast_spawner.tres") or _level_uses_spawner_profile(floor_one, "shooter_spawner.tres") or _level_uses_spawner_profile(floor_one, "tank_spawner.tres"):
		failures.append("Floor-one generated rooms should only use basic spawner profiles.")

	var floor_two = generator.generate(combat_piece, "floor_two", 2, 2222, connections)
	if _level_uses_spawner_profile(floor_two, "shooter_spawner.tres") or _level_uses_spawner_profile(floor_two, "tank_spawner.tres"):
		failures.append("Floor-two generated rooms should not use shooter or tank spawners yet.")
	var floor_three = generator.generate(combat_piece, "floor_three", 3, 3333, connections)
	if _level_uses_spawner_profile(floor_three, "tank_spawner.tres"):
		failures.append("Floor-three generated rooms should not use tank spawners yet.")

	var challenge = generator.generate(challenge_piece, "challenge_1", 5, 5555, {"north": "start", "west": "path_1"})
	if challenge.get_spawner_count() < 5 or challenge.get_spawner_count() > 7:
		failures.append("Generated challenge rooms should respect the v1 spawner count bounds.")
	if int(challenge.max_active_enemies) != clamp(24 + 5 * 4 + challenge.get_spawner_count() * 2, 30, 52):
		failures.append("Generated challenge rooms should compute floor-scaled max active enemies.")


func _test_room_interior_generator_validation(failures: Array[String]) -> void:
	var generator = load("res://scripts/resources/room_interior_generator.gd").new()
	var piece = load("res://resources/rooms/combat_wide.tres")
	var connections := {"west": "start", "east": "boss"}
	var valid_level = generator.generate(piece, "path_valid", 2, 1212, connections)
	var valid_result: Dictionary = generator.validate_level(valid_level, connections, "combat")
	if not bool(valid_result.get("ok", false)):
		failures.append("Generated combat room failed its own validation: %s" % String(valid_result.get("reason", "")))

	var blocked_spawn = generator.generate(piece, "path_blocked_spawn", 2, 1212, connections)
	blocked_spawn.wall_rects.append(Rect2(blocked_spawn.arena_bounds.get_center() - Vector2(90.0, 90.0), Vector2(180.0, 180.0)))
	if bool(generator.validate_level(blocked_spawn, connections, "combat").get("ok", false)):
		failures.append("Room validation should reject a blocked player spawn.")

	var blocked_exit = generator.generate(piece, "path_blocked_exit", 2, 1212, connections)
	var bounds: Rect2 = blocked_exit.arena_bounds
	blocked_exit.wall_rects.append(Rect2(Vector2(bounds.position.x + bounds.size.x - 210.0, bounds.get_center().y - 150.0), Vector2(210.0, 300.0)))
	if bool(generator.validate_level(blocked_exit, connections, "combat").get("ok", false)):
		failures.append("Room validation should reject a blocked connected exit approach.")

	var blocked_spawner = generator.generate(piece, "path_blocked_spawner", 2, 1212, connections)
	if blocked_spawner.spawner_placements.is_empty():
		failures.append("Generated validation test room had no spawners.")
	else:
		var spawner_position: Vector2 = blocked_spawner.spawner_placements[0].position
		blocked_spawner.void_rects.append(Rect2(spawner_position - Vector2(90.0, 90.0), Vector2(180.0, 180.0)))
		if bool(generator.validate_level(blocked_spawner, connections, "combat").get("ok", false)):
			failures.append("Room validation should reject spawners inside movement-only voids.")

	var too_closed = generator.generate(piece, "path_too_closed", 2, 1212, connections)
	var too_closed_walls: Array[Rect2] = [too_closed.arena_bounds.grow(-80.0)]
	var no_voids: Array[Rect2] = []
	too_closed.wall_rects = too_closed_walls
	too_closed.void_rects = no_voids
	if bool(generator.validate_level(too_closed, connections, "combat").get("ok", false)):
		failures.append("Room validation should reject rooms without enough navigable open area.")

	var fallback = piece.create_level_definition()
	fallback.id = "fallback_test"
	fallback.display_name = "Fallback Test"
	fallback.difficulty_label = "Floor 1 Combat"
	fallback.use_default_spawners = false
	var fallback_walls: Array[Rect2] = []
	var fallback_voids: Array[Rect2] = []
	var fallback_spawners: Array[Resource] = []
	fallback.wall_rects = fallback_walls
	fallback.void_rects = fallback_voids
	fallback.spawner_placements = fallback_spawners
	var rng := RandomNumberGenerator.new()
	rng.seed = 909090
	generator._apply_fallback_interior(fallback, "combat", 1, rng)
	var fallback_result: Dictionary = generator.validate_level(fallback, connections, "combat")
	if not bool(fallback_result.get("ok", false)):
		failures.append("Room generator fallback template should validate: %s" % String(fallback_result.get("reason", "")))


func _test_dungeon_room_interiors_persist(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/dungeon_manager.gd").new()
	root.add_child(manager)
	manager.reset_run(2, 7777)
	manager.set_enabled(true)
	if not manager.enter_direction("east"):
		failures.append("Dungeon persistence test could not enter the first combat room.")
		manager.free()
		return
	var first_level = manager.get_current_level_definition()
	var first_signature := _get_level_generation_signature(first_level)
	var room_state: Dictionary = manager.get_current_room_state()
	if not room_state.has("level_definition") or room_state["level_definition"] != first_level:
		failures.append("DungeonManager should store generated room interiors in room state.")
	if first_level.get_spawner_count() < 4:
		failures.append("Generated dungeon combat room should carry budgeted spawners.")
	if first_level.wall_rects.is_empty():
		failures.append("Generated dungeon combat room should carry procedural cover walls.")
	if _get_level_generation_signature(manager.get_current_level_definition()) != first_signature:
		failures.append("DungeonManager should return the cached generated interior on repeated reads.")

	manager.mark_current_room_cleared()
	if manager.enter_direction("west"):
		if not manager.enter_direction("east"):
			failures.append("DungeonManager should preserve a generated combat room after revisiting it.")
		elif _get_level_generation_signature(manager.get_current_level_definition()) != first_signature:
			failures.append("Revisited generated dungeon room should keep the same interior.")
	else:
		failures.append("Dungeon persistence test could not return to the start room.")

	var repeated_manager = load("res://scripts/managers/dungeon_manager.gd").new()
	root.add_child(repeated_manager)
	repeated_manager.reset_run(2, 7777)
	repeated_manager.set_enabled(true)
	repeated_manager.enter_direction("east")
	if _get_level_generation_signature(repeated_manager.get_current_level_definition()) != first_signature:
		failures.append("DungeonManager should regenerate the same room interior from the same floor seed.")
	var changed_manager = load("res://scripts/managers/dungeon_manager.gd").new()
	root.add_child(changed_manager)
	changed_manager.reset_run(2, 8888)
	changed_manager.set_enabled(true)
	changed_manager.enter_direction("east")
	if _get_level_generation_signature(changed_manager.get_current_level_definition()) == first_signature:
		failures.append("DungeonManager should vary generated room interiors for different run seeds.")
	manager.free()
	repeated_manager.free()
	changed_manager.free()


func _test_void_blockers_are_movement_only(failures: Array[String]) -> void:
	var level = load("res://scripts/resources/level_definition.gd").new()
	var wall_rects: Array[Rect2] = [Rect2(-120.0, -30.0, 240.0, 60.0)]
	var void_rects: Array[Rect2] = [Rect2(-30.0, 120.0, 60.0, 120.0)]
	level.wall_rects = wall_rects
	level.void_rects = void_rects
	var arena = load("res://scripts/arena/arena_view.gd").new()
	root.add_child(arena)
	arena.configure(level)
	var wall_count := 0
	var void_count := 0
	for child in arena.get_children():
		if child.is_in_group("arena_walls"):
			wall_count += 1
			if (int(child.collision_layer) & 32) == 0:
				failures.append("Arena wall body should use the wall collision layer.")
		if child.is_in_group("arena_voids"):
			void_count += 1
			if (int(child.collision_layer) & 64) == 0:
				failures.append("Arena void body should use the movement-only void collision layer.")
			if child.is_in_group("arena_walls"):
				failures.append("Arena void body should not be treated as a projectile-blocking wall.")
	if wall_count != 1 or void_count != 1:
		failures.append("ArenaView should create separate bodies for wall and void blockers.")

	var player = load("res://scenes/entities/player_entity.tscn").instantiate()
	var enemy = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	var spawner = load("res://scenes/entities/enemy_spawner_entity.tscn").instantiate()
	if (int(player.collision_mask) & 64) == 0:
		failures.append("Player movement should collide with generated void blockers.")
	if (int(enemy.collision_mask) & 64) == 0:
		failures.append("Enemy movement should collide with generated void blockers.")
	if (int(spawner.collision_mask) & 64) == 0:
		failures.append("Spawner movement should collide with generated void blockers.")
	var projectile = load("res://scenes/entities/projectile_entity.tscn").instantiate()
	projectile.set_projectile_team("player")
	if (int(projectile.collision_mask) & 64) != 0:
		failures.append("Player projectiles should ignore movement-only void blockers.")
	if (int(projectile.collision_mask) & 32) == 0:
		failures.append("Player projectiles should still collide with arena walls.")
	projectile.set_projectile_team("hostile")
	if (int(projectile.collision_mask) & 64) != 0:
		failures.append("Hostile projectiles should ignore movement-only void blockers.")
	if (int(projectile.collision_mask) & 32) == 0:
		failures.append("Hostile projectiles should still collide with arena walls.")
	var path_enemy = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	path_enemy.set_arena_definition(level.arena_bounds, int(level.arena_shape), [], level.void_rects)
	if not path_enemy._path_blocks_segment(Vector2(-120.0, 180.0), Vector2(120.0, 180.0), 4.0):
		failures.append("Enemy pathing should treat voids as movement blockers.")
	if path_enemy._wall_blocks_segment(Vector2(-120.0, 180.0), Vector2(120.0, 180.0)):
		failures.append("Enemy shooter line-of-sight should ignore movement-only void blockers.")
	player.free()
	enemy.free()
	spawner.free()
	projectile.free()
	path_enemy.free()
	arena.free()


func _get_level_generation_signature(level) -> String:
	if level == null:
		return "<null>"
	var wall_parts: Array[String] = []
	for rect in level.wall_rects:
		wall_parts.append(_rect_signature(rect))
	var void_parts: Array[String] = []
	for rect in level.void_rects:
		void_parts.append(_rect_signature(rect))
	var spawner_parts: Array[String] = []
	for placement in level.spawner_placements:
		var profile_path := "<none>"
		if placement != null and placement.profile != null:
			profile_path = String(placement.profile.resource_path)
		var position := Vector2.ZERO
		if placement != null:
			position = placement.position
		spawner_parts.append("%s@%d,%d" % [profile_path.get_file(), int(round(position.x)), int(round(position.y))])
	return "%s|%s|%s|%d" % [
		";".join(wall_parts),
		";".join(void_parts),
		";".join(spawner_parts),
		int(level.max_active_enemies)
	]


func _rect_signature(rect: Rect2) -> String:
	return "%d,%d,%d,%d" % [
		int(round(rect.position.x)),
		int(round(rect.position.y)),
		int(round(rect.size.x)),
		int(round(rect.size.y))
	]


func _level_uses_spawner_profile(level, file_name: String) -> bool:
	for placement in level.spawner_placements:
		if placement != null and placement.profile != null and String(placement.profile.resource_path).ends_with(file_name):
			return true
	return false


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


func _validate_dungeon_layout_integrity(manager, failures: Array[String], label: String) -> void:
	var rooms_by_id: Dictionary = {}
	for room_info in manager.get_minimap_rooms():
		rooms_by_id[String(room_info["id"])] = room_info
	if not rooms_by_id.has("start"):
		failures.append("Dungeon layout should always include a start room: %s" % label)
		return
	if _get_path_to_room_kind(manager, "boss").is_empty():
		failures.append("Dungeon layout should always include a reachable boss room: %s" % label)
	var visited := {"start": true}
	var queue := ["start"]
	while not queue.is_empty():
		var room_id := String(queue.pop_front())
		var room_info: Dictionary = rooms_by_id.get(room_id, {})
		var connections: Dictionary = room_info.get("connections", {})
		for next_room_id in connections.values():
			var next_id := String(next_room_id)
			if visited.has(next_id):
				continue
			visited[next_id] = true
			queue.append(next_id)
	if visited.size() != rooms_by_id.size():
		failures.append("Dungeon layout should keep every room reachable from start: %s" % label)
	for room_id in rooms_by_id.keys():
		var room_info: Dictionary = rooms_by_id[room_id]
		var connections: Dictionary = room_info.get("connections", {})
		for direction_key in connections.keys():
			var direction := String(direction_key)
			var target_id := String(connections[direction_key])
			var opposite := String(DUNGEON_OPPOSITE_DIRECTIONS.get(direction, ""))
			if opposite.is_empty():
				failures.append("Dungeon layout has an unknown connection direction %s: %s" % [direction, label])
				continue
			if not rooms_by_id.has(target_id):
				failures.append("Dungeon layout connection points at a missing room %s -> %s: %s" % [room_id, target_id, label])
				continue
			var target_info: Dictionary = rooms_by_id[target_id]
			var target_connections: Dictionary = target_info.get("connections", {})
			if String(target_connections.get(opposite, "")) != String(room_id):
				failures.append("Dungeon layout connection should be reciprocal %s.%s -> %s.%s: %s" % [room_id, direction, target_id, opposite, label])


func _test_dungeon_layout_solver(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/dungeon_manager.gd").new()
	root.add_child(manager)
	manager.reset_run()
	manager.set_enabled(true)
	_validate_dungeon_layout_integrity(manager, failures, "default floor")
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
	for seed in [116, 490, 887, 1115]:
		manager.reset_run(1, seed)
		_validate_dungeon_layout_integrity(manager, failures, "reported branch repro seed %d" % seed)
	for floor in range(1, 6):
		for seed in range(1, 61):
			manager.reset_run(floor, seed)
			_validate_dungeon_layout_integrity(manager, failures, "floor %d seed %d" % [floor, seed])
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
	if boss_profile.behavior_kind != "boss" or boss_profile.max_health < 120:
		failures.append("First boss profile should use boss behavior and tuned boss-scale health.")
	if boss_profile.shot_projectile_count < 3 or boss_profile.shot_spread_degrees <= 0.0:
		failures.append("First boss profile should fire a visible spread pattern.")
	var boss = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	var shot_configs: Array[Dictionary] = []
	var shot_directions: Array[Vector2] = []
	boss.initialize(boss_profile)
	boss.shot_ready.connect(func(_enemy, _origin, direction, shot_config) -> void:
		shot_configs.append(shot_config)
		shot_directions.append(direction)
	)
	boss._shot_cooldown_remaining = 0.0
	boss._try_emit_shot(Vector2.RIGHT * 360.0)
	if shot_configs.is_empty():
		failures.append("Boss enemy did not emit a hostile shot request.")
	elif int(shot_configs[0].get("projectile_count", 1)) < 3:
		failures.append("Boss hostile shot request did not include spread projectile count.")
	var normal_shot_count := shot_configs.size()
	boss._boss_special_timer = 0.0
	boss._update_boss_special(0.05, Vector2.RIGHT * 360.0)
	if boss._boss_special_telegraph_remaining <= 0.0:
		failures.append("Boss special attacks should enter a visible telegraph before firing.")
	boss._update_boss_special(boss.boss_special_telegraph_seconds + 0.05, Vector2.RIGHT * 360.0)
	var latest_special: Dictionary = shot_configs[shot_configs.size() - 1] if shot_configs.size() > 0 else {}
	if shot_configs.size() <= normal_shot_count or String(latest_special.get("kind", "")) != "hostile_minigun" or int(latest_special.get("projectile_count", 0)) != 1:
		failures.append("Boss should start a telegraphed minigun stream with individual shots.")
	var first_minigun_direction: Vector2 = shot_directions[shot_directions.size() - 1] if shot_directions.size() > 0 else Vector2.ZERO
	var minigun_count := shot_configs.size()
	boss._update_boss_special(boss.boss_minigun_shot_interval + 0.02, Vector2.RIGHT * 360.0)
	var second_minigun_direction: Vector2 = shot_directions[shot_directions.size() - 1] if shot_directions.size() > 0 else Vector2.ZERO
	if shot_configs.size() <= minigun_count or second_minigun_direction.distance_to(first_minigun_direction) <= 0.001:
		failures.append("Boss minigun should emit rapid individual shots in a sweeping motion.")
	boss._update_boss_special(boss.boss_minigun_duration + 0.1, Vector2.RIGHT * 360.0)
	minigun_count = shot_configs.size()
	boss._boss_special_timer = 0.0
	boss._update_boss_special(0.05, Vector2.RIGHT * 360.0)
	boss._update_boss_special(boss.boss_special_telegraph_seconds + 0.05, Vector2.RIGHT * 360.0)
	latest_special = shot_configs[shot_configs.size() - 1] if shot_configs.size() > 0 else {}
	if shot_configs.size() <= minigun_count or String(latest_special.get("kind", "")) != "rocket" or float(latest_special.get("knockback", 0.0)) <= 0.0:
		failures.append("Boss should alternate into a telegraphed rocket special with knockback.")
	elif not bool(latest_special.get("exact_lifetime", false)) or not latest_special.has("target_position") or float(latest_special.get("speed", 0.0)) < 600.0:
		failures.append("Boss rocket should be a fast targeted projectile that detonates at the player's launch-time position.")
	elif float(latest_special.get("explosion_radius", 0.0)) < 68.0 or float(latest_special.get("explosion_radius", 0.0)) > 80.0:
		failures.append("Boss rocket AOE should stay small enough to reward continuous movement.")
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
	var birth_adds := 0
	var faded_birth_adds := 0
	for enemy in manager._enemies:
		if is_instance_valid(enemy) and bool(enemy.get_meta("boss_add", false)) and enemy.has_method("is_birth_animation_active") and bool(enemy.is_birth_animation_active()):
			birth_adds += 1
			if enemy.has_method("_get_birth_fade_alpha") and float(enemy._get_birth_fade_alpha()) < 1.0:
				faded_birth_adds += 1
	if birth_adds != 3:
		failures.append("Boss-summoned adds should arrive with a teleport birth animation.")
	if faded_birth_adds != 3:
		failures.append("Teleporting adds should fade into existence during the birth animation.")
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


func _test_boss_test_level_select(failures: Array[String]) -> void:
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load for boss test level-select test.")
		return
	var main = scene.instantiate()
	root.add_child(main)
	if main.dungeon_manager == null:
		_prime_main_for_direct_test_calls(main)
		main._connect_manager_signals()
		main._initialize_managers()
		main._enter_level_select()
	if not main.level_list_label.text.contains("Boss Test Chamber"):
		failures.append("Level select should include the standalone boss test chamber.")
	main._selected_level_index = main.LEVELS.size() - 1
	main._start_selected_level()
	if main._status != "RUNNING" or main._is_dungeon_run:
		failures.append("Boss test chamber should start as a normal level-select arena.")
	if main.spawner_manager.get_spawner_count() != 0:
		failures.append("Boss test chamber should not spawn supporting generals.")
	var boss_found := false
	for enemy in main.enemy_manager._enemies:
		if is_instance_valid(enemy) and enemy.behavior_kind == "boss":
			boss_found = true
	if not boss_found:
		failures.append("Boss test chamber should spawn the first boss enemy.")
	main.free()


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
	main._selected_level_index = main.LEVELS.size()
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
		main.spawner_manager._process(main.spawner_manager._get_initial_spawn_shield_delay() + 0.05)
		var expected_opening_wave := 0
		for created_spawner in main.spawner_manager._spawners:
			expected_opening_wave += main.spawner_manager._get_initial_spawn_batch_count(created_spawner)
		var expected_boss_room_pressure: int = 1 + expected_opening_wave
		if main.enemy_manager.get_enemy_count() < expected_boss_room_pressure:
			failures.append("Boss room should spawn boss plus doubled opening-wave enemies after the spawner shield startup.")
	if main.spawner_manager.get_spawner_count() < 4:
		failures.append("Boss room should spawn supporting spawners.")
	if main.spawner_manager.max_active_enemies <= main.enemy_manager.get_enemy_count():
		failures.append("Boss room spawner budget should allow spawned adds while the boss is alive.")
	if main.dungeon_manager.get_revealed_room_count() < 4:
		failures.append("Dungeon minimap reveal state should advance along the traversed boss route.")
	main.free()


func _test_boss_exit_portal_preview_and_safe_position(failures: Array[String]) -> void:
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load for boss portal placement test.")
		return
	var main = scene.instantiate()
	root.add_child(main)
	if main.dungeon_manager == null:
		_prime_main_for_direct_test_calls(main)
		main._connect_manager_signals()
		main._initialize_managers()
		main._enter_level_select()
	var room_piece = load("res://resources/rooms/boss_chamber.tres")
	if room_piece == null:
		failures.append("Boss chamber room piece failed to load for portal placement test.")
		main.free()
		return
	var level = room_piece.create_level_definition()
	main._current_level = level
	main._is_main_loop_run = true
	main._show_boss_exit_portal_preview(level)
	if main._floor_exit_portal == null or not is_instance_valid(main._floor_exit_portal):
		failures.append("Main loop boss room should show an inactive floor exit portal preview.")
	else:
		var portal_position: Vector2 = main._floor_exit_portal.global_position
		if main._floor_exit_portal_active():
			failures.append("Boss exit portal preview should be inactive while the boss fight is active.")
		if not ArenaGeometry.contains_point(portal_position, level.arena_bounds, int(level.arena_shape)):
			failures.append("Boss exit portal preview should spawn inside the room bounds.")
		if not main._position_is_clear_of_room_walls(portal_position, level):
			failures.append("Boss exit portal preview should not spawn inside impassable boss-room walls.")
		main._activate_boss_exit_portal(level.boss_spawn_position, float(level.boss_profile.body_radius))
		if not main._floor_exit_portal_active():
			failures.append("Boss death should activate the existing floor exit portal preview.")
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
	main._selected_level_index = main.LEVELS.size() + 1
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
	if main._status != "DUNGEON":
		failures.append("Main loop boss kill should keep gameplay active until the exit portal is entered.")
	if main._score < 1000:
		failures.append("Main loop boss kill should award a large floor-clear score bonus.")
	if main._run_boss_kills != 1:
		failures.append("Main loop should tally boss kills immediately.")
	if not main._floor_exit_portal_active():
		failures.append("Main loop boss kill should activate an exit portal instead of instantly clearing the floor.")
	if main.win_panel.visible:
		failures.append("Main loop should wait for the portal entry before showing the next-floor panel.")
	if bool(main._tree_pause_requested):
		failures.append("Main loop boss exit portal should not pause the SceneTree before entry.")
	if not main.enemy_manager.enabled or not main.spawner_manager.enabled or not main.projectile_manager.enabled:
		failures.append("Main loop should keep gameplay managers enabled while the boss exit portal is open.")
	main._on_floor_exit_portal_entered(main._floor_exit_portal)
	if main._status != "FLOOR_CLEARED":
		failures.append("Main loop portal entry should move to floor-cleared state.")
	if main._run_floors_cleared != 1:
		failures.append("Main loop should tally cleared floors after portal entry.")
	if not main.win_panel.visible:
		failures.append("Main loop floor clear should show the mission results panel after portal entry.")
	if main.win_title_label == null or main.win_title_label.text != "MISSION RESULTS":
		failures.append("Main loop floor clear should present a mission results screen.")
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
