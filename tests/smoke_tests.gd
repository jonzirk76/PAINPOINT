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
	"res://scripts/entities/muzzle_flash_effect.gd",
	"res://scripts/entities/door_entity.gd",
	"res://scripts/entities/door_gate_top_visual.gd",
	"res://scripts/entities/destructible_prop_entity.gd",
	"res://scripts/entities/floor_exit_portal_entity.gd",
	"res://scripts/entities/cat_entity.gd"
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
	"res://scripts/arena/arena_wall_body_visual.gd",
	"res://scripts/arena/arena_wall_top_overlay.gd",
	"res://scripts/entities/player_entity.gd",
	"res://scripts/entities/enemy_entity.gd",
	"res://scripts/entities/projectile_entity.gd",
	"res://scripts/entities/enemy_spawner_entity.gd",
	"res://scripts/entities/pickup_entity.gd",
	"res://scripts/entities/chain_lightning_effect.gd",
	"res://scripts/entities/explosion_effect.gd",
	"res://scripts/entities/parry_absorb_effect.gd",
	"res://scripts/entities/projectile_impact_effect.gd",
	"res://scripts/entities/muzzle_flash_effect.gd",
	"res://scripts/entities/door_entity.gd",
	"res://scripts/entities/door_gate_top_visual.gd",
	"res://scripts/entities/destructible_prop_entity.gd",
	"res://scripts/entities/floor_exit_portal_entity.gd",
	"res://scripts/entities/cat_entity.gd",
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
	"res://scripts/managers/destructible_manager.gd",
	"res://scripts/managers/fauna_manager.gd",
	"res://scripts/ui/dungeon_minimap.gd",
	"res://scripts/ui/loading_screen.gd",
	"res://scripts/ui/circular_portrait.gd",
	"res://scripts/orchestrators/game_orchestrator.gd",
	"res://scripts/resources/agent_boss_program.gd",
	"res://scripts/resources/agent_boss_generator.gd",
	"res://scripts/resources/damage_packet.gd",
	"res://scripts/resources/enemy_profile.gd",
	"res://scripts/resources/upgrade_effect.gd",
	"res://scripts/resources/permanent_upgrade.gd",
	"res://scripts/resources/overdrive_ammo_pickup.gd",
	"res://scripts/resources/level_definition.gd",
	"res://scripts/resources/spawner_profile.gd",
	"res://scripts/resources/spawner_placement.gd",
	"res://scripts/resources/encounter_entry.gd",
	"res://scripts/resources/destructible_prop_placement.gd",
	"res://scripts/resources/room_piece_definition.gd",
	"res://scripts/resources/room_interior_generator.gd",
	"res://scripts/resources/room_geometry_builder.gd",
	"res://scripts/resources/health_pickup.gd"
]

const LEVEL_PATHS := [
	"res://resources/levels/level_01_square.tres",
	"res://resources/levels/level_02_diamond.tres",
	"res://resources/levels/level_03_hexagon.tres",
	"res://resources/levels/level_04_cross.tres",
	"res://resources/levels/level_05_circle.tres",
	"res://resources/levels/level_06_maze.tres",
	"res://resources/levels/cat_behavior_test.tres",
	"res://resources/levels/cat_peaceful_test.tres",
	"res://resources/levels/boss_test_chamber.tres"
]

const ENEMY_PROFILE_PATHS := [
	"res://resources/enemies/basic_enemy.tres",
	"res://resources/enemies/tank_enemy.tres",
	"res://resources/enemies/fast_enemy.tres",
	"res://resources/enemies/shooter_enemy.tres",
	"res://resources/enemies/first_boss_enemy.tres",
	"res://resources/enemies/repair_drone.tres",
	"res://resources/enemies/shield_drone.tres",
	"res://resources/enemies/power_armor_rocket.tres",
	"res://resources/enemies/power_armor_grenade.tres",
	"res://resources/enemies/cyber_soldier.tres",
	"res://resources/enemies/cyber_soldier_teleport.tres"
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
	"res://audio/meow.mp3",
	"res://audio/parry.wav",
	"res://audio/parry_ready.wav",
	"res://audio/perfect_parry_follow_up.wav",
	"res://audio/player_bullet_shot.wav",
	"res://audio/player_damage.wav",
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
	"res://resources/rooms/combat_cell.tres",
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

const DUNGEON_DIRECTION_OFFSETS := {
	"north": Vector2i(0, -1),
	"south": Vector2i(0, 1),
	"east": Vector2i(1, 0),
	"west": Vector2i(-1, 0)
}


func _init() -> void:
	paused = false
	var failures: Array[String] = []
	_test_architecture_rules(failures)
	_test_presentation_settings(failures)
	_test_character_svg_assets(failures)
	_test_character_art_applied_to_entities(failures)
	_test_cat_fauna_behavior(failures)
	_test_player_shoot_pose_relaxes_to_movement(failures)
	_test_scripts_instantiate(failures)
	_test_enemy_and_spawner_profiles(failures)
	_test_level_resources(failures)
	_test_arena_geometry_boundaries(failures)
	_test_arena_wall_generation(failures)
	_test_scene_loads(failures)
	_test_character_hud_visibility(failures)
	_test_character_hud_feedback_and_manual_layout(failures)
	_test_aim_change_logic(failures)
	_test_restart_signal(failures)
	_test_parry_input_and_cooldown(failures)
	_test_player_disable_stops_movement(failures)
	_test_pause_menu_flow(failures)
	_test_upgrade_modifiers_and_expiry(failures)
	_test_ammo_type_balance(failures)
	_test_low_ammo_bar_warning(failures)
	_test_parry_absorbs_hostile_projectiles_for_ammo(failures)
	_test_parry_absorb_visuals_and_ammo_flash(failures)
	_test_projectile_impact_visuals(failures)
	_test_audio_assets_and_pitch_variation(failures)
	_test_reward_driven_pickup_drops(failures)
	_test_health_pickup_and_player_healing(failures)
	_test_projectile_knockback_packet(failures)
	_test_charged_super_shot(failures)
	_test_projectile_reset_clears_visible_projectiles(failures)
	_test_destructible_props(failures)
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
	_test_floor_scaled_spawner_rates(failures)
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
	_test_agent_boss_generation_and_behavior(failures)
	_test_boss_add_replenishment(failures)
	_test_boss_test_level_select(failures)
	_test_generated_encounter_test_level_select(failures)
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


func _test_cat_fauna_behavior(failures: Array[String]) -> void:
	if not FileAccess.file_exists("res://art/characters/white_0.png"):
		failures.append("Cat fauna should keep the default white cat spritesheet asset.")
	if not FileAccess.file_exists("res://art/characters/Cats Download/calico_0.png"):
		failures.append("Cat fauna should include randomly selectable cat color spritesheets.")
	var cat_source := _read_text("res://scripts/entities/cat_entity.gd")
	if not cat_source.contains("white_0.png") or not cat_source.contains("set_danger_points"):
		failures.append("CatEntity should animate from the white cat spritesheet and accept danger points.")
	if not cat_source.contains("SIT_COLUMN_START") or not cat_source.contains("LOOK_COLUMN_START") or not cat_source.contains("LAY_COLUMN_START"):
		failures.append("CatEntity should wire sitting, looking, and laying idle animations from the cat spritesheet.")
	if not cat_source.contains("IDLE_STATE_SITTING") or not cat_source.contains("IDLE_STATE_GLANCING") or not cat_source.contains("IDLE_STATE_SCANNING") or not cat_source.contains("IDLE_STATE_LAYING"):
		failures.append("CatEntity should choose between distinct idle animation states, including glance and scan look modes.")
	if not cat_source.contains("LOOK_NEUTRAL_FRAME_INDEX") or not cat_source.contains("_look_frame_index") or not cat_source.contains("_update_look_idle"):
		failures.append("CatEntity should drive seated look idles through neutral-centered head movement.")
	if not cat_source.contains("_begin_look_exit") or not cat_source.contains("_finish_look_exit") or not cat_source.contains("_look_exit_state"):
		failures.append("CatEntity should return look idles to neutral before standing or laying transitions.")
	if not cat_source.contains("SIT_TRANSITION_UP") or not cat_source.contains("_update_sit_transition"):
		failures.append("CatEntity should play sit-down transitions into seated idles and reverse them before standing.")
	if not cat_source.contains("LAY_TRANSITION_UP") or not cat_source.contains("_update_lay_transition") or not cat_source.contains("_pending_seated_idle_state") or not cat_source.contains("_stand_after_lay_up"):
		failures.append("CatEntity should enter laying as an option from sitting and reverse through sitting before standing.")
	if not cat_source.contains("MOTION_STATE_JUMPING") or not cat_source.contains("_begin_startle_jump") or not cat_source.contains("_update_startle_jump"):
		failures.append("CatEntity should use a reusable jumping movement state for startled movement.")
	if not cat_source.contains("STARTLE_JUMP_FRAME_COUNT := 4") or not cat_source.contains("_get_startle_jump_visual_y_offset"):
		failures.append("CatEntity startled jumps should use the first four running frames with a visual y-offset arc.")
	if not cat_source.contains("get_state_snapshot") or not cat_source.contains("_movement_state_label"):
		failures.append("CatEntity should expose a current state snapshot for cat-room debug logs.")
	if not cat_source.contains("_is_fleeing = startle_avoidance.length_squared()") or not cat_source.contains("\"personal_space\""):
		failures.append("CatEntity should treat player personal-space movement as walking, not startled running or jumping.")
	if not cat_source.contains("_sit_transition_mode != SIT_TRANSITION_UP") or not cat_source.contains("_lay_transition_mode != LAY_TRANSITION_UP"):
		failures.append("CatEntity should not restart get-up animations every frame while a startle is queued.")
	if not cat_source.contains("_get_slippery_escape_direction") or not cat_source.contains("_get_direct_escape_target") or not cat_source.contains("_find_escape_target"):
		failures.append("CatEntity should route startled flee movement along clear wall-parallel escape directions.")
	if not cat_source.contains("flee_retarget_seconds") or not cat_source.contains("_should_refresh_flee_target"):
		failures.append("CatEntity should throttle startled flee route probing to avoid wall collision performance spikes.")
	if not cat_source.contains("set_player_context") or not cat_source.contains("_pick_curiosity_biased_position"):
		failures.append("CatEntity should build curiosity from player movement context and bias wander targets closer as it grows.")
	if not cat_source.contains("_has_line_of_sight_to_player") or not cat_source.contains("curiosity_line_of_sight_margin"):
		failures.append("CatEntity should only build curiosity while it has line of sight to the player.")
	if not cat_source.contains("curiosity_line_of_sight_check_seconds") or not cat_source.contains("_has_cached_line_of_sight_to_player") or not cat_source.contains("_blocker_rects"):
		failures.append("CatEntity should cache expensive line-of-sight and blocker checks during curiosity updates.")
	if not cat_source.contains("large_roam_area_threshold") or not cat_source.contains("_constrain_to_playable_if_needed") or not cat_source.contains("_get_effective_path_search_cell_limit"):
		failures.append("CatEntity should use cheaper movement safety and pathing on larger cleared-floor roam bounds.")
	if not cat_source.contains("_build_path_to") or not cat_source.contains("path_grid_size"):
		failures.append("CatEntity should path toward curiosity-biased wander targets when walls block direct movement.")
	if not cat_source.contains("set_player_projectile_points") or not cat_source.contains("shot_curiosity_reset_radius"):
		failures.append("CatEntity should reset curiosity when player shots pass nearby.")
	if not cat_source.contains("signal meowed") or not cat_source.contains("curiosity_meow_threshold") or not cat_source.contains("_pick_meow_pitch_center") or not cat_source.contains("_update_curiosity_meow"):
		failures.append("CatEntity should periodically emit varied-pitch meows after curiosity gets high.")
	if not cat_source.contains("set_cat_texture"):
		failures.append("CatEntity should accept a selected cat color texture from FaunaManager.")
	if cat_source.contains("add_to_group(\"enemies\")") or cat_source.contains("take_damage"):
		failures.append("CatEntity should stay out of combat groups and damage handling.")
	var manager_source := _read_text("res://scripts/managers/fauna_manager.gd")
	if not manager_source.contains("enemy_positions_provider") or not manager_source.contains("spawner_positions_provider"):
		failures.append("FaunaManager should receive combat danger through injected provider callables.")
	if not manager_source.contains("CAT_TEXTURES") or not manager_source.contains("set_cat_texture"):
		failures.append("FaunaManager should randomly select a cat color spritesheet when spawning cats.")
	if not manager_source.contains("_cat_texture_rng.randomize()"):
		failures.append("FaunaManager cat color selection should vary between room spawns instead of using only the movement seed.")
	if not manager_source.contains("set_player_context") or not manager_source.contains("_get_player_velocity"):
		failures.append("FaunaManager should feed player position and velocity context to cats.")
	if not manager_source.contains("player_projectile_positions_provider") or not manager_source.contains("set_player_projectile_points"):
		failures.append("FaunaManager should feed nearby player projectile positions to cats.")
	if not manager_source.contains("get_cat_state_snapshot") or not manager_source.contains("has_active_cat"):
		failures.append("FaunaManager should expose active cat state for cat-room debug logs.")
	if not manager_source.contains("set_cat_activity_bounds") or not manager_source.contains("_cat_is_inside_activity_bounds") or not manager_source.contains("_sync_cat_simulation_state"):
		failures.append("FaunaManager should keep cat simulation scoped to the current dungeon activity envelope.")
	if not manager_source.contains("set_cat_visibility_bounds") or not manager_source.contains("_cat_is_inside_visibility_bounds") or not manager_source.contains("_apply_cat_visibility_state"):
		failures.append("FaunaManager should hide cats outside the active visibility bounds without pausing simulation.")
	if not manager_source.contains("_filter_rects_for_cat_activity") or not manager_source.contains("_get_cat_playable_rects"):
		failures.append("FaunaManager should filter full-floor geometry before syncing active cats.")
	if not manager_source.contains("signal cat_meowed") or not manager_source.contains("_on_cat_meowed") or not manager_source.contains("meowed"):
		failures.append("FaunaManager should relay cat meow requests upward.")
	var fauna_manager = load("res://scripts/managers/fauna_manager.gd").new()
	root.add_child(fauna_manager)
	var builder = load("res://scripts/resources/room_geometry_builder.gd")
	var full_floor_cells: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0)]
	var full_floor_level = load("res://scripts/resources/level_definition.gd").new()
	full_floor_level.arena_bounds = builder.get_bounds(full_floor_cells)
	full_floor_level.arena_shape = 0
	full_floor_level.wall_rects = []
	full_floor_level.void_rects = []
	full_floor_level.set_meta("full_floor", true)
	full_floor_level.set_meta("footprint_cells", full_floor_cells)
	var left_floor_cell_rect: Rect2 = builder.get_cell_rect(full_floor_cells, Vector2i.ZERO)
	var right_floor_cell_rect: Rect2 = builder.get_cell_rect(full_floor_cells, Vector2i(1, 0))
	full_floor_level.set_meta("active_room_playable_rects", [right_floor_cell_rect])
	fauna_manager.set_cat_activity_bounds(full_floor_level.arena_bounds)
	fauna_manager.set_roam_bounds(full_floor_level.arena_bounds)
	fauna_manager.set_arena_definition(full_floor_level)
	var cat_floor_spawn_position: Vector2 = left_floor_cell_rect.get_center()
	fauna_manager.spawn_cat(cat_floor_spawn_position, 321)
	if fauna_manager.get_cat_position().distance_squared_to(cat_floor_spawn_position) > 1.0:
		failures.append("Dungeon cats should not be constrained into the active combat room by active_room_playable_rects.")
	fauna_manager.free()
	var projectile_manager_source := _read_text("res://scripts/managers/projectile_manager.gd")
	if not projectile_manager_source.contains("get_player_projectile_positions"):
		failures.append("ProjectileManager should expose active player projectile positions for background fauna awareness.")
	var orchestrator_source := _read_text("res://scripts/orchestrators/game_orchestrator.gd")
	if not orchestrator_source.contains("CatDebugPanel") or not orchestrator_source.contains("_update_cat_debug_panel") or not orchestrator_source.contains("get_cat_state_snapshot"):
		failures.append("GameOrchestrator should show a cat state log in cat test rooms.")
	if not orchestrator_source.contains("CAT_DEBUG_LEVEL_IDS") or not orchestrator_source.contains("cat_behavior_test") or not orchestrator_source.contains("cat_peaceful_test") or not orchestrator_source.contains("CAT_DEBUG_LEVEL_IDS.has"):
		failures.append("GameOrchestrator should scope the cat state log to authored cat test rooms only.")
	if not orchestrator_source.contains("_sync_fauna_roam_bounds(level_definition, room_is_cleared)") or not orchestrator_source.contains("set_cat_activity_bounds") or not orchestrator_source.contains("set_cat_visibility_bounds"):
		failures.append("GameOrchestrator should separate dungeon cat simulation bounds from active-room visibility bounds.")
	if not orchestrator_source.contains("cat_meowed") or not orchestrator_source.contains("play_cat_meow"):
		failures.append("GameOrchestrator should route curious cat meows to AudioManager.")
	var audio_source := _read_text("res://scripts/managers/audio_manager.gd")
	if not audio_source.contains("CAT_MEOW") or not audio_source.contains("play_cat_meow") or not audio_source.contains("cat_meow_volume_db"):
		failures.append("AudioManager should play the cat meow sound with routed pitch variation.")
	var cat_scene = load("res://scenes/entities/cat_entity.tscn")
	if cat_scene == null:
		failures.append("Cat scene failed to load.")
	else:
		var cat = cat_scene.instantiate()
		root.add_child(cat)
		cat.initialize(Vector2.ZERO, 123)
		if int(cat.collision_layer) != 0 or int(cat.collision_mask) != 96:
			failures.append("Cat should collide with walls/voids but not expose a combat collision layer.")
		cat.free()
	var test_level = load("res://resources/levels/cat_behavior_test.tres")
	if test_level == null or not bool(test_level.get("cat_spawn_enabled")):
		failures.append("Cat behavior test room should load and explicitly enable cat spawning.")
	var peaceful_level = load("res://resources/levels/cat_peaceful_test.tres")
	if peaceful_level == null:
		failures.append("Peaceful cat test room should load.")
	elif not bool(peaceful_level.get("cat_spawn_enabled")) or peaceful_level.get_spawner_count() != 0:
		failures.append("Peaceful cat test room should enable cat spawning without combat spawners.")
	var dungeon = load("res://scripts/managers/dungeon_manager.gd").new()
	dungeon.reset_run(1, 1907)
	var dungeon_source := _read_text("res://scripts/managers/dungeon_manager.gd")
	if not dungeon_source.contains("CAT_START_ROOM_SPAWN_CHANCE") or not dungeon_source.contains("floor_cat_room_id = \"start\""):
		failures.append("DungeonManager should usually place generated cats in the intro room for debugging.")
	var cat_info: Dictionary = dungeon.get_floor_cat_spawn_info()
	if not bool(cat_info.get("ok", false)):
		failures.append("DungeonManager should choose one cat spawn room per floor.")
	var cat_room_id := String(cat_info.get("room_id", ""))
	if not cat_room_id.is_empty():
		var room_kind := ""
		for room in dungeon.get_minimap_rooms():
			if String(room.get("id", "")) == cat_room_id:
				room_kind = String(room.get("kind", ""))
				break
		if room_kind != "start" and room_kind != "combat":
			failures.append("Dungeon floor cat should spawn only in the start room or a combat room.")
	dungeon.free()


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


func _get_meter_segments(layer: Node, meta_name: String) -> Array:
	var segments: Array = []
	for child in layer.get_children():
		if bool(child.get_meta(meta_name, false)):
			segments.append(child)
	return segments


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
		"res://scenes/entities/destructible_prop_entity.tscn",
		"res://scenes/entities/floor_exit_portal_entity.tscn",
		"res://scenes/entities/cat_entity.tscn"
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
					"UI/CombatPanel/HealthBarBack/HealthTickLayer",
					"UI/CombatPanel/InvulnerabilityBarBack/InvulnerabilityBarFill",
					"UI/CombatPanel/CircularPortraitMask/CharacterPortrait",
					"UI/CharacterUi/CharacterNameLabel",
					"UI/CombatPanel/OverdriveBarBack/OverdriveBarFill",
					"UI/CombatPanel/OverdriveBarBack/OverdriveTickLayer",
					"UI/CombatPanel/SuperBarBack/SuperBarFill",
					"UI/CombatPanel/AttributeLabel",
					"UI/CombatPanel/StatsLabel",
					"UI/AmmoCounterPanel",
					"UI/CharacterUi",
					"UI/HUDBackground",
					"UI/ScorePanel/ScoreLabel",
					"UI/PausePanel/PauseStatsLabel",
					"UI/PausePanel/PauseConfirmPanel",
					"UI/DungeonMinimap",
					"UI/GameOverPanel/GameOverPromptLabel",
					"UI/GameOverPanel/GameOverTallyLabel",
					"UI/LevelSelectPanel/LevelListLabel",
					"UI/WinPanel/WinPromptLabel",
					"World/DepthSortLayer",
					"World/DoorLayer",
					"World/DestructibleLayer",
					"World/FaunaLayer",
					"World/EffectLayer",
					"Managers/InputManager",
					"Managers/EffectsManager",
					"Managers/AudioManager",
					"Managers/DungeonManager",
					"Managers/RoomManager",
					"Managers/DestructibleManager",
					"Managers/FaunaManager"
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
					if score_panel.anchor_left != 1.0 or score_panel.anchor_right != 1.0 or score_panel.offset_right < -28.0 or score_panel.offset_right > -8.0 or score_panel.offset_top > 20.0:
						failures.append("Score panel should sit compactly above the upper-right minimap.")
				if instance.has_node("UI/ScorePanel/ScoreLabel"):
					var score_label: Label = instance.get_node("UI/ScorePanel/ScoreLabel")
					if score_label.get_theme_font_size("font_size") > 22:
						failures.append("Score label should be small enough to group with the minimap.")
				if instance.has_node("UI/CombatPanel"):
					var combat_panel: Control = instance.get_node("UI/CombatPanel")
					if combat_panel.size.y > 120.0:
						failures.append("Character combat panel should stay compact while showing portrait, health, overdrive, and special.")
					if combat_panel.anchor_left != 0.0 or combat_panel.anchor_right != 0.0 or combat_panel.offset_left > 24.0:
						failures.append("Character combat panel should sit in the upper-left corner.")
					if not instance.has_node("UI/CombatPanel/OverdriveBarBack/OverdriveBarFill") or not instance.has_node("UI/CombatPanel/SuperBarBack/SuperBarFill"):
						failures.append("Combat panel should render blue overdrive and yellow special resource bars.")
				if instance.has_node("UI/CombatPanel/HealthLabel") and instance.has_node("UI/CombatPanel/OverdriveLabel") and instance.has_node("UI/CombatPanel/SuperLabel"):
					var health_label: Label = instance.get_node("UI/CombatPanel/HealthLabel")
					var overdrive_label: Label = instance.get_node("UI/CombatPanel/OverdriveLabel")
					var super_label: Label = instance.get_node("UI/CombatPanel/SuperLabel")
					if health_label.visible or overdrive_label.visible or super_label.visible:
						failures.append("Combat resource bars should not need visible Life/Overdrive/Special text labels.")
				if instance.has_node("UI/CombatPanel/CircularPortraitMask/CharacterPortrait"):
					var character_portrait: Control = instance.get_node("UI/CombatPanel/CircularPortraitMask/CharacterPortrait")
					if character_portrait.get_script() == null:
						failures.append("Character portrait should use the circular portrait drawing script.")
					elif character_portrait.get("texture") == null:
						failures.append("Character combat panel should use the canon sheet portrait texture.")
					var portrait_mask: Control = instance.get_node("UI/CombatPanel/CircularPortraitMask")
					if abs(portrait_mask.size.x - portrait_mask.size.y) > 0.01:
						failures.append("Character portrait should draw into a square circular mask area.")
				if instance.has_node("UI/DungeonMinimap"):
					var dungeon_minimap_node: Control = instance.get_node("UI/DungeonMinimap")
					if dungeon_minimap_node.anchor_left != 1.0 or dungeon_minimap_node.anchor_right != 1.0 or dungeon_minimap_node.offset_right < -24.0 or dungeon_minimap_node.offset_top < 48.0:
						failures.append("Dungeon minimap should sit in the upper-right corner.")
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
	if LEVEL_PATHS.size() != 9:
		failures.append("Expected nine level resources after adding both cat test rooms.")
	for path in LEVEL_PATHS:
		var level = load(path)
		if level == null:
			failures.append("Level resource failed to load: %s" % path)
			continue
		var spawner_count: int = level.get_spawner_count()
		if spawner_count <= 0 and level.boss_profile == null and not bool(level.get("cat_spawn_enabled")):
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
	if tank_spawner.max_health < 40 or tank_spawner.body_radius < 44.0:
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
	var room_piece = load("res://resources/rooms/combat_cell.tres")
	var generated_level = room_piece.create_level_definition()
	var depth_sort_layer := Node2D.new()
	depth_sort_layer.name = "DepthSortLayer"
	depth_sort_layer.y_sort_enabled = true
	root.add_child(depth_sort_layer)
	var generated_arena = load("res://scripts/arena/arena_view.gd").new()
	root.add_child(generated_arena)
	generated_arena.configure(generated_level)
	var wall_top_overlay = generated_arena.get_node_or_null("WallTopOverlay")
	if wall_top_overlay == null or int(wall_top_overlay.z_index) <= 0:
		failures.append("Generated room wall tops should render through a positive-z overlay above gameplay entities.")
	var arena_view_source := _read_text("res://scripts/arena/arena_view.gd")
	var wall_top_overlay_source := _read_text("res://scripts/arena/arena_wall_top_overlay.gd")
	if not arena_view_source.contains("inactive_room_dim_rects") or not wall_top_overlay_source.contains("_draw_dim"):
		failures.append("ArenaView should render dim overlays for visible inactive dungeon rooms through the wall-top overlay.")
	var wall_body_visual_script = load("res://scripts/arena/arena_wall_body_visual.gd")
	var wall_body_visual_count := 0
	for child in depth_sort_layer.get_children():
		if child.get_script() == wall_body_visual_script:
			wall_body_visual_count += 1
	if wall_body_visual_count <= 0:
		failures.append("Generated room wall bodies should render as y-sorted depth visuals.")
	generated_arena.free()
	depth_sort_layer.free()


func _test_character_hud_visibility(failures: Array[String]) -> void:
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load for character HUD visibility test.")
		return
	var main = scene.instantiate()
	root.add_child(main)
	if main.player_manager == null:
		_prime_main_for_direct_test_calls(main)
		main._connect_manager_signals()
		main._initialize_managers()
		main._enter_level_select()
	var character_ui: CanvasItem = main.get_node("UI/CharacterUi")
	if character_ui.visible or main.combat_panel.visible:
		failures.append("Character HUD should be hidden on level select.")
	main._selected_level_index = 0
	main._start_selected_level()
	if not character_ui.visible or not main.combat_panel.visible:
		failures.append("Character HUD should be visible during gameplay.")
	main.free()


func _test_character_hud_feedback_and_manual_layout(failures: Array[String]) -> void:
	var portrait_source := _read_text("res://scenes/character_portrait.gd")
	if portrait_source.contains("stretch_mode") or portrait_source.contains("expand_mode"):
		failures.append("Character portrait script should not override manually authored TextureRect sizing.")
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load for character HUD feedback test.")
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
	var health_rect: Rect2 = main._get_meter_full_rect(main.health_fill, main.health_bar_back, main.health_bar_back.size.x)
	main._last_max_health = 5
	main._last_health = 3
	main._update_combat_panel([])
	var expected_meter_skew: float = main.METER_SEGMENT_SKEW_DEGREES
	if main.health_fill.size.x > health_rect.size.x * 0.61 or main.health_fill.size.x < health_rect.size.x * 0.59:
		failures.append("Health depletion should use the manually authored fill width as its full meter.")
	var health_segments := _get_meter_segments(main.health_tick_layer, "meter_active_segment")
	if health_segments.size() != main._last_health:
		failures.append("Health meter should draw one visible segment per current health point.")
	if health_segments.size() > 0:
		var first_health_segment: Polygon2D = health_segments[0] as Polygon2D
		var last_health_segment: Polygon2D = health_segments[health_segments.size() - 1] as Polygon2D
		var last_health_segment_size: Vector2 = last_health_segment.get_meta("meter_size", Vector2.ZERO)
		if abs(first_health_segment.position.y - health_rect.position.y) > 0.01 or first_health_segment.position.x < health_rect.position.x - 1.0:
			failures.append("Health segments should align to the manually authored fill rect.")
		if last_health_segment.position.x + last_health_segment_size.x > health_rect.position.x + health_rect.size.x + 0.01:
			failures.append("Health segments should stay inside the manually authored fill rect.")
		if abs(float(first_health_segment.get_meta("skew_degrees", 0.0)) - expected_meter_skew) > 0.01:
			failures.append("Health segments should use the orchestrator's configured meter skew.")
	main._last_health = 1
	main._update_combat_panel([])
	health_segments = _get_meter_segments(main.health_tick_layer, "meter_active_segment")
	if health_segments.size() > 0:
		var low_health_segment: Polygon2D = health_segments[0] as Polygon2D
		if low_health_segment.color.r <= low_health_segment.color.g:
			failures.append("Health meter should shift toward red as health is depleted.")
	var name_label: Label = main.get_node("UI/CharacterUi/CharacterNameLabel")
	if name_label.text.strip_edges().to_lower() != "volette":
		failures.append("Character HUD should label the player as Volette.")
	var base_panel_position: Vector2 = main.combat_panel.position
	main._on_player_health_changed(5, 4)
	if main._character_hud_damage_flash_remaining <= 0.0 or main._character_hud_shake_remaining <= 0.0:
		failures.append("Character HUD should start flash and shake feedback when health drops.")
	if main.combat_panel.modulate == Color.WHITE and main.combat_panel.position == base_panel_position:
		failures.append("Character HUD damage feedback should visibly affect the HUD.")
	main._process(0.5)
	if main.combat_panel.position != base_panel_position:
		failures.append("Character HUD shake should return the panel to its authored position.")
	main._last_super_meter_max = 100.0
	main._last_super_meter = 100.0
	main._last_super_is_charging = false
	main._super_ready_pulse_time = 0.25
	main._super_crackle_remaining = 0.1
	var super_rect: Rect2 = main._get_meter_full_rect(main.super_fill, main.super_bar_back, main.super_bar_back.size.x)
	main._update_super_bar(super_rect)
	if main.super_bar_back.get_node_or_null("SuperCrackle") == null:
		failures.append("Ready special meter should draw a white crackle overlay.")
	main.free()


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
	if not manager.should_fire_for_aim_change(Vector2.ZERO):
		failures.append("Right-stick neutral return should request a flick release fire.")
	elif manager._consume_pending_aim_fire_direction().distance_to(Vector2.UP) > 0.001:
		failures.append("Right-stick neutral return should fire in the previous aim direction.")
	if manager.should_fire_for_aim_change(Vector2.ZERO):
		failures.append("Right-stick neutral return should not repeatedly request release fire.")
	manager.reset_run()
	if not manager.should_fire_for_aim_change(Vector2.RIGHT, InputManager.AIM_SOURCE_DIGITAL):
		failures.append("Initial digital aim state should still request fire.")
	if manager.should_fire_for_aim_change(Vector2.ZERO, InputManager.AIM_SOURCE_NONE):
		failures.append("Digital aim release should not use the right-stick flick fire rule.")
	var input_source := _read_text("res://scripts/managers/input_manager.gd")
	if not input_source.contains("JOY_AXIS_TRIGGER_LEFT") or not input_source.contains("KEY_SHIFT") or not input_source.contains("overdrive_changed"):
		failures.append("InputManager should expose Left Shift / left-trigger overdrive without replacing right-trigger super charge.")
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
	manager.resolve_parry_result(true)
	if manager.get_parry_chain_count() != 1 or manager.get_longest_parry_chain() != 1:
		failures.append("Perfect parry should start a tracked parry chain.")
	if manager.get_parry_cooldown_remaining() > manager.parry_chain_cooldown_seconds + 0.01:
		failures.append("Perfect parry should reduce the next parry cooldown for chaining.")
	if manager.player._parry_chain_grace_remaining <= 0.0:
		failures.append("Player should show a parry-chain grace meter after a perfect parry.")
	manager._process(manager.parry_chain_cooldown_seconds + 0.1)
	manager.request_parry()
	manager.resolve_parry_result(true)
	if manager.get_parry_chain_count() != 2 or manager.get_longest_parry_chain() != 2:
		failures.append("Consecutive perfect parries should advance the parry chain.")
	manager._process(manager.parry_chain_grace_seconds + 0.1)
	if manager.get_parry_chain_count() != 0 or manager.get_parry_cooldown_remaining() <= manager.parry_chain_cooldown_seconds:
		failures.append("Letting the perfect-parry chain grace expire should start the long cooldown.")
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
	if live_projectile == null:
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
	var capacity = load("res://resources/permanent_upgrades/overdrive_capacity.tres")
	manager.reset_run()
	if manager.get_overdrive_max_ammo() != 40 or manager.get_overdrive_ammo() != 40:
		failures.append("Overdrive should start full with 40 max ammo.")
	var idle_modifiers: Dictionary = manager.get_modifiers()
	if bool(idle_modifiers["overdrive_active"]) or float(idle_modifiers["projectile_size_multiplier"]) != 1.0:
		failures.append("Overdrive modifiers should not apply until overdrive is held.")
	manager.set_overdrive_active(true)
	var no_stack_modifiers: Dictionary = manager.get_modifiers()
	if not bool(no_stack_modifiers["overdrive_active"]) or float(no_stack_modifiers["projectile_size_multiplier"]) < 2.0:
		failures.append("No-stack overdrive should spend ammo for a doubled regular bullet.")
	if not manager.consume_overdrive_shot() or manager.get_overdrive_ammo() != 39:
		failures.append("Each overdrive shot should consume exactly one shared ammo.")
	manager.activate_upgrade(spread)
	manager.activate_upgrade(spread)
	manager.activate_upgrade(pierce)
	manager.activate_upgrade(fire)
	manager.activate_upgrade(water)
	manager.activate_permanent_upgrade(fire_rate)
	manager.activate_permanent_upgrade(move_speed)
	manager.activate_permanent_upgrade(damage)
	manager.activate_permanent_upgrade(size)
	manager.activate_permanent_upgrade(capacity)
	var active_effects: Array = manager.get_active_effects()
	if active_effects.size() != 4:
		failures.append("Overdrive effects should stack by effect type.")
	var modifiers: Dictionary = manager.get_modifiers()
	if int(modifiers["projectile_count"]) != 3:
		failures.append("Two Spread overdrive stacks should add two extra projectiles.")
	if int(modifiers["pierce_count"]) < 2:
		failures.append("Pierce and Water overdrive stacks should add stack-based pierce.")
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
	if float(modifiers["burn_damage_per_second"]) <= 0.0 or float(modifiers["burn_duration_seconds"]) <= 0.0:
		failures.append("Fire Burst should add a burn status to overdrive hits.")
	if float(modifiers["projectile_growth_per_second"]) <= 0.0:
		failures.append("Water Swell did not add projectile growth.")
	if float(modifiers["slow_multiplier"]) >= 1.0 or float(modifiers["slow_duration_seconds"]) <= 0.0:
		failures.append("Water Swell should add a slow status to overdrive hits.")
	if manager.get_permanent_stats().size() != 5:
		failures.append("Permanent upgrade stats were not tracked.")
	if manager.get_overdrive_max_ammo() != 64:
		failures.append("Overdrive effect and treasure capacity upgrades should both add max ammo.")
	if manager.get_overdrive_ammo() != 63:
		failures.append("Capacity-bearing overdrive rewards should immediately refill their added shared ammo capacity.")
	if fire_rate.max_stacks < 16 or move_speed.max_stacks < 16 or damage.max_stacks < 14 or size.max_stacks < 14:
		failures.append("Permanent upgrade stack ceilings should be higher for longer dungeon runs.")
	manager.set_enabled(true)
	manager._process(99.0)
	if manager.get_active_effects().is_empty():
		failures.append("Overdrive upgrades should be permanent run-long stacks.")
	manager.set_overdrive_active(false)
	var inactive_modifiers: Dictionary = manager.get_modifiers()
	if int(inactive_modifiers["projectile_count"]) != 1 or int(inactive_modifiers["chain_count"]) != 0:
		failures.append("Overdrive effect stacks should not affect regular shots while overdrive is released.")
	manager.free()


func _test_ammo_type_balance(failures: Array[String]) -> void:
	var spread = load("res://resources/upgrades/spread_shot.tres")
	var pierce = load("res://resources/upgrades/piercing_shot.tres")
	var chain = load("res://resources/upgrades/chain_lightning.tres")
	var fire = load("res://resources/upgrades/fire_burst.tres")
	var water = load("res://resources/upgrades/water_swell.tres")
	var manager = load("res://scripts/managers/upgrade_manager.gd").new()
	var projectile_manager = load("res://scripts/managers/projectile_manager.gd").new()
	if int(spread.max_ammo) != 0:
		failures.append("Spread Shot should not increase shared overdrive capacity.")
	if int(pierce.max_ammo) < 5 or int(chain.max_ammo) <= 0 or int(fire.max_ammo) <= 0 or int(water.max_ammo) <= 0:
		failures.append("Non-spread overdrive rewards should increase shared overdrive capacity.")
	manager.activate_upgrade(pierce)
	manager.set_overdrive_active(true)
	var modifiers: Dictionary = manager.get_modifiers()
	if float(modifiers["damage_multiplier"]) > 1.01:
		failures.append("Piercing overdrive should no longer increase direct projectile damage.")
	if float(modifiers["knockback_multiplier"]) <= 1.0:
		failures.append("Piercing overdrive should increase projectile knockback.")
	var packet = projectile_manager._create_damage_packet(modifiers, Vector2.ZERO, Vector2.RIGHT)
	if packet.damage < 1 or packet.pierce_count < 2 or packet.knockback <= projectile_manager.base_knockback:
		failures.append("Piercing overdrive should create a piercing knockback projectile while held.")
	manager.activate_upgrade(chain)
	modifiers = manager.get_modifiers()
	packet = projectile_manager._create_damage_packet(modifiers, Vector2.ZERO, Vector2.RIGHT)
	var chain_charge_valid := packet.lightning_charge_damage_multiplier >= 2.0
	chain_charge_valid = chain_charge_valid and packet.lightning_charge_required_stacks >= 2
	chain_charge_valid = chain_charge_valid and packet.lightning_charge_max_stacks >= packet.lightning_charge_required_stacks
	chain_charge_valid = chain_charge_valid and packet.lightning_charge_duration_seconds > 0.0
	if packet.chain_count < 1 or not chain_charge_valid:
		failures.append("Chain Lightning should stamp chain and repeat-hit charge threshold metadata.")
	manager.activate_upgrade(spread)
	for _index in range(10):
		manager.consume_overdrive_shot()
	var before_ammo: int = manager.get_overdrive_ammo()
	var ammo_added: int = manager.add_ammo_to_active_upgrades(8)
	if ammo_added != 8 or manager.get_overdrive_ammo() - before_ammo != 8:
		failures.append("Parry ammo should refill the shared overdrive ammo pool.")
	projectile_manager.free()
	manager.free()


func _test_low_ammo_bar_warning(failures: Array[String]) -> void:
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load for low ammo bar warning test.")
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
	main.upgrade_manager.set_overdrive_active(true)
	for _index in range(34):
		main.upgrade_manager.consume_overdrive_shot()
	main._update_hud()
	if main.overdrive_fill == null or main.overdrive_bar_back == null:
		failures.append("Low ammo should be represented by the overdrive bar.")
	else:
		var fill_color: Color = main.overdrive_fill.color
		var back_color: Color = main.overdrive_bar_back.color
		if fill_color.b <= fill_color.r or fill_color.b < 0.9:
			failures.append("Low ammo should keep the overdrive fill blue.")
		if back_color.r > 0.03 or back_color.g > 0.03 or back_color.b > 0.04:
			failures.append("Low ammo should keep a black overdrive backplate for depletion readability.")
	if main.overdrive_tick_layer == null:
		failures.append("Overdrive bar should expose a tick layer.")
	else:
		var expected_meter_skew: float = main.METER_SEGMENT_SKEW_DEGREES
		var expected_segments: int = main.upgrade_manager.get_overdrive_ammo()
		var overdrive_segments := _get_meter_segments(main.overdrive_tick_layer, "meter_active_segment")
		if overdrive_segments.size() != expected_segments:
			failures.append("Overdrive meter should draw one visible segment per current ammo unit.")
		var default_segment_width := 0.0
		if overdrive_segments.size() > 0:
			var first_tick: Polygon2D = overdrive_segments[0] as Polygon2D
			var first_tick_size: Vector2 = first_tick.get_meta("meter_size", Vector2.ZERO)
			default_segment_width = first_tick_size.x
			var fill_rect: Rect2 = main._get_meter_full_rect(main.overdrive_fill, main.overdrive_bar_back, main.overdrive_bar_back.size.x)
			if abs(first_tick.position.y - fill_rect.position.y) > 0.01 or first_tick.position.x < fill_rect.position.x - 1.0:
				failures.append("Overdrive segments should align to the manually authored fill rect.")
			var last_tick: Polygon2D = overdrive_segments[overdrive_segments.size() - 1] as Polygon2D
			var last_tick_size: Vector2 = last_tick.get_meta("meter_size", Vector2.ZERO)
			if last_tick.position.x + last_tick_size.x > fill_rect.position.x + fill_rect.size.x + 0.01:
				failures.append("Overdrive segments should stay inside the manually authored fill rect.")
			if first_tick.color.b <= first_tick.color.r:
				failures.append("Overdrive segments should stay blue at low ammo.")
			if abs(float(first_tick.get_meta("skew_degrees", 0.0)) - expected_meter_skew) > 0.01:
				failures.append("Overdrive segments should use the orchestrator's configured meter skew.")
		main._last_overdrive_max_ammo = 8
		main._last_overdrive_ammo = 8
		var fill_rect: Rect2 = main._get_meter_full_rect(main.overdrive_fill, main.overdrive_bar_back, main.overdrive_bar_back.size.x)
		main._update_overdrive_bar(fill_rect)
		main._last_overdrive_ammo = 5
		main._update_overdrive_bar(fill_rect)
		var ejected_segments := _get_meter_segments(main.overdrive_tick_layer, "meter_ejected_segment")
		if ejected_segments.is_empty():
			failures.append("Spent overdrive ammo should create short-lived ejected segment animations.")
		main._last_overdrive_max_ammo = 50
		main._last_overdrive_ammo = 50
		main._update_overdrive_bar(main._get_meter_full_rect(main.overdrive_fill, main.overdrive_bar_back, main.overdrive_bar_back.size.x))
		overdrive_segments = _get_meter_segments(main.overdrive_tick_layer, "meter_active_segment")
		if overdrive_segments.size() != 50:
			failures.append("Overdrive capacity increases should add denser filled segments.")
		elif default_segment_width > 0.0:
			var denser_segment: Polygon2D = overdrive_segments[0] as Polygon2D
			var denser_segment_size: Vector2 = denser_segment.get_meta("meter_size", Vector2.ZERO)
			if denser_segment_size.x >= default_segment_width:
				failures.append("Overdrive capacity increases should make segments denser instead of wider.")
	if main.player_manager.player != null and main.player_manager.player.has_method("set_ammo_warning_state"):
		failures.append("Low ammo should no longer create a warning around the player.")
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
	upgrade_manager.reset_run()
	upgrade_manager.set_overdrive_active(true)
	for _index in range(30):
		upgrade_manager.consume_overdrive_shot()
	if projectile_manager.perfect_parry_projectile_ammo_award != 2:
		failures.append("Perfect parry bullets should award 2 overdrive ammo each for chain balance.")
	projectile_manager.fire_hostile(Vector2(12.0, 0.0), Vector2.RIGHT, {"speed": 250.0, "damage": 1, "radius": 7.0})
	projectile_manager.fire_hostile(Vector2(82.0, 0.0), Vector2.RIGHT, {"speed": 250.0, "damage": 1, "radius": 7.0})
	projectile_manager.fire_hostile(Vector2(220.0, 0.0), Vector2.RIGHT, {"speed": 250.0, "damage": 1, "radius": 7.0})
	projectile_manager.fire(Vector2(12.0, 12.0), Vector2.RIGHT, {})
	var absorbed: Dictionary = projectile_manager.absorb_hostile_projectiles(Vector2.ZERO, 100.0, 24.0)
	if int(absorbed["absorbed_count"]) != 2:
		failures.append("Parry should erase hostile projectiles inside the effect radius only.")
	if int(absorbed["perfect_count"]) != 1 or int(absorbed["ammo_awarded"]) != 3:
		failures.append("Parry should award 2 ammo for close bullets and 1 ammo for other absorbed bullets.")
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
	if ammo_added != 3 or upgrade_manager.get_overdrive_ammo() != 13:
		failures.append("Parry ammo should refill the shared overdrive pool.")
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
	main.upgrade_manager.set_overdrive_active(true)
	for _index in range(8):
		main.upgrade_manager.consume_overdrive_shot()
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
	if main._last_parry_chain_count != 1 or main._run_longest_parry_chain != 1:
		failures.append("Perfect parry should update the current and longest parry-chain counters.")
	if main.get_node("World/EffectLayer").get_child_count() <= 0:
		failures.append("Parry absorption should create a visible swoop effect in the effect layer.")
	else:
		var absorb_effect = main.get_node("World/EffectLayer").get_child(0)
		var absorb_target: Vector2 = absorb_effect.get("end_position")
		var portrait_targets: Array[Vector2] = main._get_character_portrait_world_targets()
		if portrait_targets.is_empty() or absorb_target.distance_squared_to(portrait_targets[0]) > 36.0 * 36.0:
			failures.append("Parry absorb effects should fly toward the character portrait.")
	main._process(0.12)
	if main.overdrive_fill == null or main._ammo_refill_flash_remaining <= 0.0:
		failures.append("Overdrive bar should flash while parry ammo fills it.")
	var flashed_segment_found := false
	for segment in _get_meter_segments(main.overdrive_tick_layer, "meter_active_segment"):
		if float(segment.get_meta("refill_flash_strength", 0.0)) > 0.0:
			flashed_segment_found = true
	if not flashed_segment_found:
		failures.append("Parry ammo refill should flash newly filled overdrive segments one at a time.")
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
	manager.play_cat_meow(1.23, 0.04)
	if manager._active_players.size() != 7:
		failures.append("AudioManager should create short-lived AudioStreamPlayers for overlapping SFX.")
	else:
		var first_player: AudioStreamPlayer = manager._active_players[0]
		var second_player: AudioStreamPlayer = manager._active_players[1]
		var ready_player: AudioStreamPlayer = manager._active_players[2]
		var perfect_player: AudioStreamPlayer = manager._active_players[3]
		var wall_player: AudioStreamPlayer = manager._active_players[4]
		var rocket_player: AudioStreamPlayer = manager._active_players[5]
		var cat_player: AudioStreamPlayer = manager._active_players[6]
		if first_player.stream == null or perfect_player.stream == null or cat_player.stream == null:
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
		if cat_player.pitch_scale < 1.19 or cat_player.pitch_scale > 1.27:
			failures.append("Cat meow pitch variation should stay around the cat's generated center pitch.")
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
	if manager.enemy_permanent_drop_chance != 0.0 or manager.enemy_temporary_drop_chance != 0.0:
		failures.append("Enemies should no longer drop permanent stats or overdrive effect upgrades.")
	if manager.enemy_overdrive_ammo_drop_chance <= 0.0 or manager.enemy_overdrive_ammo_drop_chance >= manager.enemy_heal_drop_chance:
		failures.append("Enemies should drop mostly health, with rarer overdrive ammo cells.")
	if manager.enemy_heal_drop_chance > 0.08 or manager.enemy_overdrive_ammo_drop_chance > 0.03:
		failures.append("Enemy health and overdrive ammo drops should be toned down after the overdrive economy rework.")
	if manager.enemy_overdrive_ammo_drop_chance * 2.0 > manager.enemy_heal_drop_chance:
		failures.append("Enemy overdrive ammo drops should be much rarer than health so parry remains the primary ammo source.")
	manager.spawner_full_heal_drop_chance = 0.0
	manager.drop_spawner_reward(Vector2.ZERO)
	if manager.get_pickup_count() != 1:
		failures.append("Spawner destruction should always create one reward pickup.")
	var pickup = manager._pickups[0]
	if pickup == null or pickup.upgrade_effect == null or pickup.upgrade_effect.get_pickup_kind() != "overdrive_ammo" or int(pickup.upgrade_effect.amount) < 6:
		failures.append("Spawner non-heal reward should be an overdrive ammo cache.")
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
	manager.enemy_overdrive_ammo_drop_chance = 0.0
	manager.enemy_heal_drop_chance = 1.0
	manager.roll_enemy_drop(Vector2.ZERO)
	if manager.get_pickup_count() != 1:
		failures.append("Forced enemy heal drop should create one pickup.")
	else:
		var heal_pickup = manager._pickups[0]
		if heal_pickup.upgrade_effect == null or heal_pickup.upgrade_effect.get_pickup_kind() != "heal":
			failures.append("Enemy heal drop should use the heal pickup resource.")
		heal_pickup._process(heal_pickup.lifetime_seconds + 0.1)
		if manager.get_pickup_count() != 0:
			failures.append("Enemy heal drops should still despawn after their normal lifetime.")
	manager.clear_pickups()
	manager.enemy_heal_drop_chance = 0.0
	manager.enemy_overdrive_ammo_drop_chance = 1.0
	manager.roll_enemy_drop(Vector2.ZERO)
	if manager.get_pickup_count() != 1:
		failures.append("Forced enemy overdrive ammo drop should create one pickup.")
	else:
		var ammo_pickup = manager._pickups[0]
		ammo_pickup._process(ammo_pickup.lifetime_seconds + 0.1)
		if manager.get_pickup_count() != 0:
			failures.append("Enemy overdrive ammo drops should still despawn after their normal lifetime.")
	manager.clear_pickups()
	manager.spawn_overdrive_reward_choices(Vector2.ZERO)
	if manager.get_pickup_count() != 3:
		failures.append("Overdrive reward rooms should spawn three optional choices.")
	else:
		var reward_pickup = manager._pickups[0]
		if not bool(reward_pickup.get("requires_confirm")):
			failures.append("Reward choices should require confirm instead of auto-collecting.")
		var focus_descriptions: Array[String] = []
		manager.reward_focus_changed.connect(func(_effect, description: String) -> void:
			if not description.is_empty():
				focus_descriptions.append(description)
		)
		var player = load("res://scenes/entities/player_entity.tscn").instantiate()
		reward_pickup._on_body_entered(player)
		if focus_descriptions.is_empty():
			failures.append("Focused reward choices should publish a description.")
		if not manager.collect_focused_reward() or manager.get_pickup_count() != 0:
			failures.append("Confirming one reward choice should collect it and clear the other choices.")
		player.free()
	manager.clear_pickups()
	manager.spawn_treasure_reward_choices(Vector2.ZERO)
	if manager.get_pickup_count() != 3:
		failures.append("Treasure rooms should spawn three permanent-stat choices.")
	else:
		var found_capacity_in_pool := false
		for upgrade in manager.permanent_upgrades:
			if upgrade != null and upgrade.has_method("get_stat_key") and upgrade.get_stat_key() == "overdrive_capacity":
				found_capacity_in_pool = true
		if not found_capacity_in_pool:
			failures.append("Treasure reward pool should include overdrive capacity upgrades.")
		for choice in manager._pickups:
			if choice.upgrade_effect == null or choice.upgrade_effect.get_pickup_kind() != "permanent":
				failures.append("Treasure reward choices should be permanent stat upgrades.")
			elif float(choice.upgrade_effect.roll_amount_max) > 0.0:
				var rolled_amount: float = float(choice.upgrade_effect.amount)
				if rolled_amount < float(choice.upgrade_effect.roll_amount_min) or rolled_amount > float(choice.upgrade_effect.roll_amount_max):
					failures.append("Treasure reward choices should roll permanent stat values inside their configured range.")
	manager.clear_pickups()
	manager.set_room_context(2, "treasure_1")
	manager.spawn_treasure_reward_choices(Vector2(12.0, 18.0))
	if manager.get_pickup_count() != 3:
		failures.append("Persistent treasure room should spawn three permanent choices.")
	else:
		var persistent_choice = manager._pickups[0]
		persistent_choice._process(persistent_choice.lifetime_seconds + 2.0)
		if manager.get_pickup_count() != 3:
			failures.append("Permanent upgrade choices should not despawn while staying on the floor.")
		manager.clear_pickups()
		if manager.get_pickup_count() != 0:
			failures.append("Room transition should clear active permanent pickup nodes.")
		manager.rehydrate_current_room_permanent_pickups()
		if manager.get_pickup_count() != 3:
			failures.append("Uncollected permanent upgrade choices should rehydrate when returning to the room.")
		var player_for_persistent = load("res://scenes/entities/player_entity.tscn").instantiate()
		manager._pickups[0]._on_body_entered(player_for_persistent)
		if not manager.collect_focused_reward() or manager.get_pickup_count() != 0:
			failures.append("Selecting one persistent permanent choice should clear the whole choice group.")
		manager.rehydrate_current_room_permanent_pickups()
		if manager.get_pickup_count() != 0:
			failures.append("Selected persistent permanent choices should not rehydrate later.")
		player_for_persistent.free()
	manager.clear_floor_persistent_pickups()
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


func _test_destructible_props(failures: Array[String]) -> void:
	var placement = load("res://scripts/resources/destructible_prop_placement.gd").new()
	placement.position = Vector2(80.0, 0.0)
	placement.size = Vector2(48.0, 48.0)
	placement.prop_kind = "crate"
	placement.max_health = 2
	placement.score_value = 1
	placement.drop_kind = "minor"
	var prop = load("res://scenes/entities/destructible_prop_entity.tscn").instantiate()
	prop.initialize(placement)
	if (int(prop.collision_layer) & 32) == 0 or not prop.is_in_group("arena_walls") or not prop.is_in_group("destructible_props"):
		failures.append("Destructible props should block movement/projectiles while alive.")
	var packet = load("res://scripts/resources/damage_packet.gd").new()
	packet.damage = 1
	var depleted_count := [0]
	prop.health_depleted.connect(func(_prop) -> void:
		depleted_count[0] += 1
	)
	prop.take_damage(packet)
	if prop.health != 1:
		failures.append("Destructible prop damage should reduce health.")
	prop.take_damage(packet)
	if depleted_count[0] != 1 or int(prop.collision_layer) != 0:
		failures.append("Destructible props should emit depletion and stop blocking when broken.")

	var projectile = load("res://scenes/entities/projectile_entity.tscn").instantiate()
	var hit_count := [0]
	projectile.hit_detected.connect(func(_projectile, target) -> void:
		if target == prop:
			hit_count[0] += 1
	)
	prop.initialize(placement)
	projectile.initialize(Vector2.ZERO, Vector2.RIGHT, packet, 560.0)
	projectile._handle_target_hit(prop, prop.global_position)
	if hit_count[0] != 1 or projectile.last_expire_reason != "hit":
		failures.append("Player projectiles should damage destructible props and stop on impact.")
	prop.free()
	projectile.free()

	var prop_layer := Node2D.new()
	var manager = load("res://scripts/managers/destructible_manager.gd").new()
	var level = load("res://scripts/resources/level_definition.gd").new()
	var prop_placements: Array[Resource] = [placement]
	level.destructible_prop_placements = prop_placements
	root.add_child(prop_layer)
	root.add_child(manager)
	manager.initialize({
		"destructible_layer": prop_layer
	})
	manager.reset_run(level)
	manager.set_enabled(true)
	if manager.get_destructible_count() != 1:
		failures.append("DestructibleManager should spawn level-defined props.")
	else:
		var spawned_prop = manager._destructibles[0]
		packet.damage = 3
		manager.apply_damage(spawned_prop, packet)
		if manager.get_destructible_count() != 0 or not level.destructible_prop_placements.is_empty():
			failures.append("Destroyed props should be removed from the live room definition for revisits.")
	manager.free()
	prop_layer.free()

	var pickup_layer := Node2D.new()
	var item_manager = load("res://scripts/managers/item_manager.gd").new()
	root.add_child(pickup_layer)
	root.add_child(item_manager)
	item_manager.initialize({
		"pickup_layer": pickup_layer
	})
	item_manager.set_enabled(true)
	item_manager.drop_destructible_reward(Vector2.ZERO, "treasure")
	if item_manager.get_pickup_count() != 1:
		failures.append("Treasure chest destructibles should drop one reward pickup.")
	item_manager.free()
	pickup_layer.free()


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
		[Rect2(90.0, -90.0, 46.0, 180.0)],
		[Rect2(-240.0, 120.0, 80.0, 80.0)]
	)
	if enemy._get_path_blocker_rects().size() != 2:
		failures.append("Enemy pathing should cache wall and void blockers without rebuilding the list every query.")
	enemy.set_target_position(Vector2.RIGHT * 320.0)
	var velocity: Vector2 = enemy._get_chaser_velocity(enemy.target_position - enemy.global_position)
	if velocity.length_squared() <= 0.001:
		failures.append("Enemy wall pathing should produce a steering velocity.")
	if abs(velocity.y) <= 1.0:
		failures.append("Enemy wall pathing should steer around an internal wall instead of pushing straight into it.")
	var cached_steering_target: Vector2 = enemy._cached_steering_target
	var cached_repath_remaining: float = enemy._path_repath_remaining
	enemy.set_target_position(Vector2(330.0, 8.0))
	enemy._get_chaser_velocity(enemy.target_position - enemy.global_position)
	if enemy._cached_steering_target != cached_steering_target or enemy._path_repath_remaining != cached_repath_remaining:
		failures.append("Enemy pathing should reuse cached steering for tiny target movement near walls.")
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
	if (projectile.collision_mask & 128) == 0:
		failures.append("Player projectile collision mask does not include the non-contact agent boss layer.")
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


func _test_floor_scaled_spawner_rates(failures: Array[String]) -> void:
	var spawner_layer := Node2D.new()
	var manager = load("res://scripts/managers/spawner_manager.gd").new()
	var level = load("res://scripts/resources/level_definition.gd").new()
	var placement = load("res://scripts/resources/spawner_placement.gd").new()
	var basic_profile = load("res://resources/spawners/basic_spawner.tres")
	var placements: Array[Resource] = [placement]
	placement.position = Vector2.ZERO
	placement.profile = basic_profile
	placement.warmup_seconds = 0.1
	level.use_default_spawners = false
	level.spawner_placements = placements
	root.add_child(spawner_layer)
	root.add_child(manager)
	manager.initialize({
		"spawner_layer": spawner_layer
	})

	level.floor_number = 1
	manager.reset_run(level)
	if manager._spawners.is_empty():
		failures.append("Floor-scaled spawner rate test could not create a floor-one spawner.")
		manager.free()
		spawner_layer.free()
		return
	var profile_interval: float = float(basic_profile.spawn_interval)
	var floor_one_interval: float = float(manager._spawners[0].spawn_interval)
	if floor_one_interval <= profile_interval:
		failures.append("Floor one spawn rates should start lower than the base spawner profile rate.")

	level.floor_number = 6
	manager.reset_run(level)
	if manager._spawners.is_empty():
		failures.append("Floor-scaled spawner rate test could not create a later-floor spawner.")
	else:
		var floor_six_interval: float = float(manager._spawners[0].spawn_interval)
		if floor_six_interval >= floor_one_interval:
			failures.append("Later floors should increase spawn rate by shortening spawner intervals.")
		if floor_six_interval >= profile_interval:
			failures.append("Mid-run floors should push spawn intervals below base profile timing.")
	manager.free()
	spawner_layer.free()


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
		var footprint_result: Dictionary = piece.validate_footprint()
		if not bool(footprint_result.get("ok", false)):
			failures.append("Room piece has invalid canonical footprint %s: %s" % [path, String(footprint_result.get("reason", ""))])
		if piece.id != "combat_crossroads" and piece.footprint_cells.size() > 4:
			failures.append("Only combat_crossroads may exceed four cells: %s" % path)
		if piece.id == "combat_crossroads" and piece.footprint_cells.size() != 5:
			failures.append("Combat crossroads should remain the sole five-cell room.")
		if (piece.room_kind == "start" or piece.room_kind == "treasure") and piece.footprint_cells.size() != 1:
			failures.append("Entry and treasure rooms should stay one cell: %s" % path)
		if piece.get_connector_directions().is_empty():
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
			var cell_count := piece.footprint_cells.size()
			if cell_count == 1 and int(level.max_active_enemies) < 20:
				failures.append("One-cell combat room pieces should still support a small encounter: %s" % path)
			elif cell_count >= 4 and int(level.max_active_enemies) < 30:
				failures.append("Large combat room pieces should support larger battles: %s" % path)
		if piece.room_kind == "challenge" and level.get_spawner_count() < 5:
			failures.append("Challenge room piece should carry at least five spawners: %s" % path)
		if piece.room_kind == "boss":
			if piece.footprint_cells.size() != 1 or level.arena_bounds.size != Vector2(1280.0, 720.0):
				failures.append("Boss room shell should be a true one-cell arena.")
			if level.get_spawner_count() != 0:
				failures.append("Boss room shell should not include interior spawner structures.")
			if level.boss_profile == null:
				failures.append("Boss room shell should carry a boss profile.")
			if not bool(level.generate_agent_boss):
				failures.append("Boss room shell should request procedural agent boss generation.")
			if level.max_active_enemies < 1:
				failures.append("Boss room max active enemies should allow the boss encounter.")
	if combat_piece_count < 8:
		failures.append("Dungeon solver should have at least eight combat room pieces to vary floor sizes and shapes.")
	_validate_room_piece_geometry_rules(failures)
	_validate_room_piece_runtime_variants(failures)
	var fallback_piece = load("res://scripts/resources/room_piece_definition.gd").new()
	fallback_piece.id = "combat_wide"
	fallback_piece.room_kind = "combat"
	if not fallback_piece.has_connector("north") or not fallback_piece.has_connector("west"):
		failures.append("Room piece connector fallbacks should protect dungeon generation when serialized connector fields are omitted.")


func _validate_room_piece_geometry_rules(failures: Array[String]) -> void:
	var builder = load("res://scripts/resources/room_geometry_builder.gd")
	var corner_cells: Array[Vector2i] = [Vector2i.ZERO]
	var multi_open_edges := {
		"north": {"source_cell": Vector2i.ZERO, "target_cell": Vector2i.ZERO},
		"east": {"source_cell": Vector2i.ZERO, "target_cell": Vector2i.ZERO}
	}
	var multi_open_tiles: Array[Rect2] = builder.build_wall_tile_rects(corner_cells, multi_open_edges)
	var north_east_corner := Rect2(Vector2(
		builder.CELL_SIZE.x * 0.5 - builder.WALL_TILE_SIZE,
		-builder.CELL_SIZE.y * 0.5
	), Vector2(builder.WALL_TILE_SIZE, builder.WALL_TILE_SIZE))
	if not _rect_list_has_rect(multi_open_tiles, north_east_corner):
		failures.append("Room shell generation should preserve exterior corner wall tiles when one cell has adjacent openings.")
	if _rect_list_count_rect(multi_open_tiles, north_east_corner) != 1:
		failures.append("Room shell generation should not duplicate exterior corner wall tiles shared by adjacent wall edges.")
	var manual_wall_top_tiles: Array[Rect2] = [
		Rect2(Vector2(-builder.WALL_TILE_SIZE, -builder.WALL_TILE_SIZE), Vector2(builder.WALL_TILE_SIZE, builder.WALL_TILE_SIZE))
	]
	var manual_wall_body_tiles: Array[Rect2] = builder.build_wall_body_tile_rects(manual_wall_top_tiles, corner_cells, {})
	var expected_wall_body := Rect2(Vector2(-builder.WALL_TILE_SIZE, 0.0), Vector2(builder.WALL_TILE_SIZE, builder.WALL_TILE_SIZE))
	if not _rect_list_has_rect(manual_wall_body_tiles, expected_wall_body):
		failures.append("RPG-style wall tops should derive one blocking wall body tile directly below them.")
	var bottom_wall_top_tiles: Array[Rect2] = [
		Rect2(Vector2(0.0, builder.CELL_SIZE.y * 0.5 - builder.WALL_TILE_SIZE), Vector2(builder.WALL_TILE_SIZE, builder.WALL_TILE_SIZE))
	]
	var bottom_wall_body_tiles: Array[Rect2] = builder.build_wall_body_tile_rects(bottom_wall_top_tiles, corner_cells, {})
	var outside_bottom_wall_body := Rect2(bottom_wall_top_tiles[0].position + Vector2(0.0, builder.WALL_TILE_SIZE), bottom_wall_top_tiles[0].size)
	if not _rect_list_has_rect(bottom_wall_body_tiles, outside_bottom_wall_body):
		failures.append("Bottom exterior wall tops should use the shifted body envelope to spawn their normal body tile below the footprint.")
	if _rect_list_has_rect(bottom_wall_body_tiles, bottom_wall_top_tiles[0]):
		failures.append("Bottom exterior wall tops should not become self-blocking fallback body tiles.")
	var east_opening_body_source := Rect2(
		Vector2(builder.CELL_SIZE.x * 0.5 - builder.WALL_TILE_SIZE, -builder.WALL_TILE_SIZE * 3.0),
		Vector2(builder.WALL_TILE_SIZE, builder.WALL_TILE_SIZE)
	)
	var east_opening_blocked_body := Rect2(east_opening_body_source.position + Vector2(0.0, builder.WALL_TILE_SIZE), east_opening_body_source.size)
	var east_opening_top_tiles: Array[Rect2] = [east_opening_body_source]
	var east_opening_body_tiles: Array[Rect2] = builder.build_wall_body_tile_rects(east_opening_top_tiles, corner_cells, multi_open_edges)
	if not _rect_list_has_rect(east_opening_body_tiles, east_opening_blocked_body):
		failures.append("Side-facing gate openings should keep a wall body frame at the top of the four-tile opening.")
	var east_opening := builder.get_opening_rect(corner_cells, Vector2i.ZERO, "east")
	var east_wall_top_opening := builder.get_wall_top_opening_rect(corner_cells, Vector2i.ZERO, "east")
	if abs(east_wall_top_opening.size.y - (east_opening.size.y - builder.WALL_TILE_SIZE)) > 0.5:
		failures.append("Side-facing wall-top openings should leave the lowest opening tile as a passable wall top.")
	var east_low_wall_top := Rect2(
		Vector2(east_opening.position.x, east_opening.position.y + east_opening.size.y - builder.WALL_TILE_SIZE),
		Vector2(builder.WALL_TILE_SIZE, builder.WALL_TILE_SIZE)
	)
	if not _rect_list_has_rect(multi_open_tiles, east_low_wall_top):
		failures.append("Side-facing gate construction should draw the lowest opening tile as a wall top.")
	var east_gate_passage := builder.get_gate_passage_rect(corner_cells, Vector2i.ZERO, "east")
	if abs(east_gate_passage.position.y - (east_opening.position.y + builder.WALL_TILE_SIZE)) > 0.5 or abs(east_gate_passage.size.y - (east_opening.size.y - builder.WALL_TILE_SIZE)) > 0.5:
		failures.append("Side-facing gate marker/passability should use the lower three tiles of the four-tile gate span.")
	var north_opening_top_source := builder.get_opening_rect(corner_cells, Vector2i.ZERO, "north")
	var north_opening_blocked_body := Rect2(north_opening_top_source.position + Vector2(0.0, builder.WALL_TILE_SIZE), north_opening_top_source.size)
	var north_opening_top_tiles: Array[Rect2] = [north_opening_top_source]
	var north_opening_body_tiles: Array[Rect2] = builder.build_wall_body_tile_rects(north_opening_top_tiles, corner_cells, multi_open_edges)
	if _rect_list_has_rect(north_opening_body_tiles, north_opening_blocked_body):
		failures.append("North-facing wall body openings should be cut on the body row, not only the top row.")
	var north_gate_rect: Rect2 = builder.get_wall_body_opening_rect(corner_cells, Vector2i.ZERO, "north")
	if abs(north_gate_rect.position.y - (north_opening_top_source.position.y + builder.WALL_TILE_SIZE)) > 0.5:
		failures.append("North-facing gate visuals should align with RPG-style wall body tiles.")
	var north_gate_visual := builder.get_gate_visual_rect(corner_cells, Vector2i.ZERO, "north")
	if abs(north_gate_visual.position.y - north_opening_top_source.position.y) > 0.5 or abs(north_gate_visual.size.y - builder.WALL_TILE_SIZE * 2.0) > 0.5:
		failures.append("North-facing locked gates should draw both a gate top and one body row.")
	var south_gate_visual := builder.get_gate_visual_rect(corner_cells, Vector2i.ZERO, "south")
	var south_opening := builder.get_opening_rect(corner_cells, Vector2i.ZERO, "south")
	if south_gate_visual != south_opening:
		failures.append("South-facing locked gates should draw only the gate top row.")
	var stacked_floor_cells: Array[Vector2i] = [Vector2i.ZERO, Vector2i(0, 1)]
	var upper_cell_rect: Rect2 = builder.get_cell_rect(stacked_floor_cells, Vector2i.ZERO)
	var lower_cell_rect: Rect2 = builder.get_cell_rect(stacked_floor_cells, Vector2i(0, 1))
	var stacked_upper_top := Rect2(
		Vector2(upper_cell_rect.get_center().x - builder.WALL_TILE_SIZE * 0.5, upper_cell_rect.position.y + upper_cell_rect.size.y - builder.WALL_TILE_SIZE),
		Vector2(builder.WALL_TILE_SIZE, builder.WALL_TILE_SIZE)
	)
	var stacked_lower_top := Rect2(
		Vector2(lower_cell_rect.get_center().x - builder.WALL_TILE_SIZE * 0.5, lower_cell_rect.position.y),
		Vector2(builder.WALL_TILE_SIZE, builder.WALL_TILE_SIZE)
	)
	var stacked_boundary_tops: Array[Rect2] = [stacked_upper_top, stacked_lower_top]
	var stacked_boundary_bodies: Array[Rect2] = builder.build_wall_body_tile_rects(stacked_boundary_tops, stacked_floor_cells, {})
	if not _rect_list_has_rect(stacked_boundary_bodies, stacked_lower_top):
		failures.append("Combined room-boundary wall tops should block the lower stacked wall-top tile.")
	var stacked_body_below_lower := Rect2(stacked_lower_top.position + Vector2(0.0, builder.WALL_TILE_SIZE), stacked_lower_top.size)
	if not _rect_list_has_rect(stacked_boundary_bodies, stacked_body_below_lower):
		failures.append("Combined room-boundary wall tops should create a second blocker tile below the lower stacked wall top.")
	var l_cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	var l_tiles: Array[Rect2] = builder.build_wall_tile_rects(l_cells, {})
	var l_boundary_turn_corner := Rect2(Vector2(
		-builder.WALL_TILE_SIZE,
		0.0
	), Vector2(builder.WALL_TILE_SIZE, builder.WALL_TILE_SIZE))
	if not _rect_list_has_rect(l_tiles, l_boundary_turn_corner):
		failures.append("L-shaped room shell generation should preserve boundary turn corner wall tiles.")
	if _rect_list_count_rect(l_tiles, l_boundary_turn_corner) != 1:
		failures.append("L-shaped room shell generation should not duplicate boundary turn corner wall tiles.")
	var absent_cell_fill_tile := Rect2(Vector2(
		0.0,
		0.0
	), Vector2(builder.WALL_TILE_SIZE, builder.WALL_TILE_SIZE))
	if _rect_list_has_rect(l_tiles, absent_cell_fill_tile):
		failures.append("L-shaped room shell generation should derive the exterior envelope without filling absent bounding-box cells.")
	var mirrored_l_cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]
	var mirrored_l_tiles: Array[Rect2] = builder.build_wall_tile_rects(mirrored_l_cells, {})
	var mirrored_l_miter_tile := Rect2(Vector2(
		0.0,
		-builder.WALL_TILE_SIZE
	), Vector2(builder.WALL_TILE_SIZE, builder.WALL_TILE_SIZE))
	if not _rect_list_has_rect(mirrored_l_tiles, mirrored_l_miter_tile):
		failures.append("L-shaped room shell generation should add diagonal miter tiles at unified envelope turns.")
	var west_edges: Array = builder.get_exposed_edges(l_cells, "west")
	var east_edges: Array = builder.get_exposed_edges(l_cells, "east")
	if west_edges.size() != 2 or east_edges.size() != 2:
		failures.append("Room geometry should expose cell-specific connector edges for non-rectangular footprints.")


func _validate_room_piece_runtime_variants(failures: Array[String]) -> void:
	var dungeon_manager = load("res://scripts/managers/dungeon_manager.gd").new()
	var l_piece = load("res://resources/rooms/combat_l_room.tres")
	var l_keys := _get_room_piece_variant_footprint_keys(dungeon_manager, l_piece)
	for key in [
		"0,0;0,1;1,0",
		"0,0;1,0;1,1",
		"0,1;1,0;1,1",
		"0,0;0,1;1,1"
	]:
		if not l_keys.has(key):
			failures.append("Runtime L-room variants should include footprint rotation/reflection %s." % key)
	var z_piece = load("res://resources/rooms/challenge_zigzag.tres")
	var z_keys := _get_room_piece_variant_footprint_keys(dungeon_manager, z_piece)
	for key in [
		"0,0;1,0;1,1",
		"0,1;1,0;1,1"
	]:
		if not z_keys.has(key):
			failures.append("Runtime zigzag variants should include both upper and lower missing-cell orientations.")
	var saw_south_connector := false
	for variant in dungeon_manager._get_room_piece_variants([z_piece]):
		if variant.has_connector("south"):
			saw_south_connector = true
			break
	if not saw_south_connector:
		failures.append("Runtime zigzag variants should transform connector directions with rotated footprints.")
	dungeon_manager.free()


func _get_room_piece_variant_footprint_keys(dungeon_manager, piece) -> Dictionary:
	var keys := {}
	for variant in dungeon_manager._get_room_piece_variants([piece]):
		keys[_footprint_key_for_test(variant.footprint_cells)] = true
	return keys


func _footprint_key_for_test(cells: Array) -> String:
	var sorted_cells: Array[Vector2i] = []
	for cell in cells:
		sorted_cells.append(cell)
	sorted_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	var parts: Array[String] = []
	for cell in sorted_cells:
		parts.append("%d,%d" % [cell.x, cell.y])
	return ";".join(parts)


func _test_room_interior_generator_determinism_and_budget(failures: Array[String]) -> void:
	var generator = load("res://scripts/resources/room_interior_generator.gd").new()
	var combat_piece = load("res://resources/rooms/combat_wide.tres")
	var challenge_piece = load("res://resources/rooms/challenge_zigzag.tres")
	var boss_piece = load("res://resources/rooms/boss_chamber.tres")
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
	if floor_one.destructible_prop_placements.size() < 2:
		failures.append("Generated combat rooms should include destructible crate/barrel cover.")
	if int(floor_one.max_active_enemies) != clamp(18 + 2 * 5 + floor_one.get_spawner_count() * 2 + 1 * 3 + int(floor_one.encounter_budget), 24, 66):
		failures.append("Generated combat rooms should compute floor-scaled max active enemies.")
	if not _generated_room_has_non_basic_spawner(floor_one):
		failures.append("Floor-one generated combat rooms should not collapse into only basic generals.")
	var tier_one_options: Array[Dictionary] = generator._get_spawner_options(1)
	var basic_cost := _get_spawner_option_cost_by_file(tier_one_options, "basic_spawner.tres")
	var fast_cost := _get_spawner_option_cost_by_file(tier_one_options, "fast_spawner.tres")
	var shooter_cost := _get_spawner_option_cost_by_file(tier_one_options, "shooter_spawner.tres")
	var tank_cost := _get_spawner_option_cost_by_file(tier_one_options, "tank_spawner.tres")
	if basic_cost <= 0 or fast_cost <= 0 or shooter_cost <= 0 or tank_cost <= 0:
		failures.append("Tier-one generated rooms should have all current general profiles available.")
	if basic_cost > shooter_cost or fast_cost > shooter_cost or shooter_cost > tank_cost:
		failures.append("Spawner budget values should keep basic/fast cheaper than shooter/tank generals.")
	var seen_floor_one_profiles: Dictionary = {}
	for seed in range(1100, 1140):
		var sampled_level = generator.generate(combat_piece, "floor_one_%d" % seed, 1, seed, connections)
		_collect_level_spawner_profile_files(sampled_level, seen_floor_one_profiles)
	for file_name in ["basic_spawner.tres", "fast_spawner.tres", "shooter_spawner.tres", "tank_spawner.tres"]:
		if not seen_floor_one_profiles.has(file_name):
			failures.append("Floor-one generated rooms should be able to roll %s." % file_name)

	var challenge = generator.generate(challenge_piece, "challenge_1", 5, 5555, {"north": "start", "west": "path_1"})
	if challenge.get_spawner_count() < 5 or challenge.get_spawner_count() > 7:
		failures.append("Generated challenge rooms should respect the v1 spawner count bounds.")
	if int(challenge.max_active_enemies) != clamp(18 + 3 * 5 + challenge.get_spawner_count() * 2 + 4 + 5 * 3 + int(challenge.encounter_budget), 24, 66):
		failures.append("Generated challenge rooms should compute floor-scaled max active enemies.")
	var boss = generator.generate(boss_piece, "boss", 4, 5555, {"west": "path_3"})
	var repeated_boss = generator.generate(boss_piece, "boss", 4, 5555, {"west": "path_3"})
	if _get_level_generation_signature(boss) != _get_level_generation_signature(repeated_boss):
		failures.append("Generated boss rooms should be deterministic for seed/floor/room id.")
	if boss.get_spawner_count() != 0:
		failures.append("Generated boss rooms should not carry interior spawner structures.")
	if boss.boss_profile == null:
		failures.append("Generated boss rooms should preserve the boss profile.")
	if boss.arena_bounds.size != Vector2(1280.0, 720.0):
		failures.append("Generated boss rooms should use a true one-cell arena.")
	if not bool(boss.generate_agent_boss):
		failures.append("Generated boss rooms should request procedural agent boss generation.")
	var boss_interior_blockers: Array[Rect2] = _get_level_interior_blocker_rects(boss)
	if boss_interior_blockers.is_empty():
		failures.append("Generated boss rooms should include symmetric interior cover blockers.")
	elif not _has_rotational_blocker_pair(boss_interior_blockers, boss.arena_bounds.get_center()):
		failures.append("Generated boss room cover blockers should keep rotational symmetry.")
	var boss_prop_rects: Array[Rect2] = _get_level_prop_rects(boss)
	if boss_prop_rects.size() < 2:
		failures.append("Generated boss rooms should include paired destructible cover.")
	elif not _has_rotational_blocker_pair(boss_prop_rects, boss.arena_bounds.get_center()):
		failures.append("Generated boss room destructible cover should keep rotational symmetry.")
	var boss_result: Dictionary = generator.validate_level(boss, {"west": "path_3"}, "boss")
	if not bool(boss_result.get("ok", false)):
		failures.append("Generated boss room failed its own validation: %s" % String(boss_result.get("reason", "")))
	var complex_room_count := 0
	var saw_wall_chain := false
	var saw_void_mass := false
	var prop_room_count := 0
	var chest_room_count := 0
	for seed in range(2400, 2420):
		var sampled_room = generator.generate(combat_piece, "complex_%d" % seed, 2, seed, connections)
		if not _level_blockers_are_tile_aligned(sampled_room):
			failures.append("Generated room blockers should stay aligned to the canonical tile grid.")
		if not _level_door_openings_are_unblocked(sampled_room, connections):
			failures.append("Generated exterior wall growth should not block connected door openings.")
		if not _level_generated_blockers_stay_inside_footprint(sampled_room):
			failures.append("Generated room blockers should stay inside the canonical footprint envelope.")
		if _get_blocker_tile_count(sampled_room) >= 12:
			complex_room_count += 1
		if _has_contiguous_blocker_group(_get_level_meta_rects(sampled_room, "wall_tile_rects", sampled_room.wall_rects), 4):
			saw_wall_chain = true
		if _has_contiguous_blocker_group(_get_level_meta_rects(sampled_room, "void_tile_rects", sampled_room.void_rects), 4):
			saw_void_mass = true
		if sampled_room.destructible_prop_placements.size() >= 2:
			prop_room_count += 1
		for prop in sampled_room.destructible_prop_placements:
			if prop != null and String(prop.prop_kind) == "chest":
				chest_room_count += 1
				break
	if complex_room_count < 8:
		failures.append("Generated rooms should usually spend enough blocker budget to create richer interiors.")
	if not saw_wall_chain:
		failures.append("Generated wall blockers should be able to form snaking/massed chains.")
	if not saw_void_mass:
		failures.append("Generated void blockers should be able to form massed or snaking shapes.")
	if prop_room_count < 12:
		failures.append("Generated rooms should usually include destructible props.")
	if chest_room_count <= 0 or chest_room_count >= prop_room_count:
		failures.append("Generated treasure chests should appear rarely among destructible props.")


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
	var blocked_opening = generator.generate(piece, "path_blocked_opening", 2, 1212, connections)
	var opening_rect := _get_level_connection_opening_rect(blocked_opening, "east")
	if opening_rect.size == Vector2.ZERO:
		failures.append("Generated validation test room should expose a connected door opening rect.")
	else:
		blocked_opening.wall_rects.append(opening_rect)
		if bool(generator.validate_level(blocked_opening, connections, "combat").get("ok", false)):
			failures.append("Room validation should reject a blocker occupying a connected door opening.")

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
	var prop_blocked_spawn = generator.generate(piece, "path_prop_blocked_spawn", 2, 1212, connections)
	var prop_placement = load("res://scripts/resources/destructible_prop_placement.gd").new()
	prop_placement.position = prop_blocked_spawn.arena_bounds.get_center()
	prop_placement.size = Vector2(120.0, 120.0)
	prop_placement.max_health = 3
	prop_blocked_spawn.destructible_prop_placements.append(prop_placement)
	if bool(generator.validate_level(prop_blocked_spawn, connections, "combat").get("ok", false)):
		failures.append("Room validation should reject destructible props blocking required spawn space.")

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

	var boss_piece = load("res://resources/rooms/boss_chamber.tres")
	var boss_connections := {"west": "path_3"}
	var boss_level = generator.generate(boss_piece, "boss_valid", 3, 3434, boss_connections)
	var boss_valid_result: Dictionary = generator.validate_level(boss_level, boss_connections, "boss")
	if not bool(boss_valid_result.get("ok", false)):
		failures.append("Generated boss validation room should validate: %s" % String(boss_valid_result.get("reason", "")))
	boss_level.wall_rects.append(Rect2(boss_level.boss_spawn_position - Vector2(90.0, 90.0), Vector2(180.0, 180.0)))
	if bool(generator.validate_level(boss_level, boss_connections, "boss").get("ok", false)):
		failures.append("Room validation should reject blocked boss spawn positions.")


func _test_dungeon_room_interiors_persist(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/dungeon_manager.gd").new()
	root.add_child(manager)
	manager.reset_run(2, 7777)
	manager.set_enabled(true)
	var first_path_direction := _get_connection_direction_between_rooms(manager, "start", "path_1")
	if first_path_direction.is_empty() or not manager.enter_direction(first_path_direction):
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
	var full_floor_during_combat = manager.get_current_full_floor_level_definition(true)
	var combat_dim_rects: Array = full_floor_during_combat.get_meta("inactive_room_dim_rects") if full_floor_during_combat.has_meta("inactive_room_dim_rects") else []
	if combat_dim_rects.is_empty():
		failures.append("Full-floor dungeon combat levels should expose dim rects for visible inactive rooms.")
	var active_combat_wall_rects: Array[Rect2] = _get_level_meta_rects(full_floor_during_combat, "active_room_wall_rects", [])
	if active_combat_wall_rects.is_empty():
		failures.append("Full-floor dungeon combat levels should expose active-room wall blockers for gameplay managers.")
	elif active_combat_wall_rects.size() >= full_floor_during_combat.wall_rects.size():
		failures.append("Active combat wall blockers should be a smaller room-local subset of full-floor wall blockers.")
	var active_combat_bounds: Rect2 = full_floor_during_combat.get_meta("active_room_bounds") if full_floor_during_combat.has_meta("active_room_bounds") else Rect2()
	if active_combat_bounds.size != Vector2.ZERO:
		for rect in active_combat_wall_rects:
			if not rect.intersects(active_combat_bounds.grow(96.0), true):
				failures.append("Active combat wall blockers should stay near the active room bounds.")
				break

	var persistent_prop = load("res://scripts/resources/destructible_prop_placement.gd").new()
	persistent_prop.position = Vector2(36.0, 28.0)
	persistent_prop.size = Vector2(48.0, 48.0)
	persistent_prop.prop_kind = "chest"
	persistent_prop.max_health = 5
	persistent_prop.score_value = 4
	persistent_prop.drop_kind = "treasure"
	first_level.destructible_prop_placements.append(persistent_prop)
	manager.mark_current_room_cleared()
	var full_floor_with_props = manager.get_current_full_floor_level_definition(false)
	var inactive_room_dim_rects: Array = full_floor_with_props.get_meta("inactive_room_dim_rects") if full_floor_with_props.has_meta("inactive_room_dim_rects") else []
	if not inactive_room_dim_rects.is_empty():
		failures.append("Cleared full-floor traversal should not keep inactive-room dim rects after combat ends.")
	var copied_persistent_prop = null
	for placement in full_floor_with_props.destructible_prop_placements:
		if placement != null and placement.has_meta("source_placement") and placement.get_meta("source_placement") == persistent_prop:
			copied_persistent_prop = placement
			break
	if copied_persistent_prop == null:
		failures.append("Cleared floor maps should keep unbroken destructible props from cleared rooms.")
	elif String(copied_persistent_prop.get_meta("source_room_id")) != manager.current_room_id:
		failures.append("Persisted cleared-floor props should retain their source room metadata.")
	if not manager.remove_destructible_prop_placement(manager.current_room_id, persistent_prop):
		failures.append("DungeonManager should remove destroyed persisted props from the source room.")
	var full_floor_after_prop_removed = manager.get_current_full_floor_level_definition(false)
	for placement in full_floor_after_prop_removed.destructible_prop_placements:
		if placement != null and placement.has_meta("source_placement") and placement.get_meta("source_placement") == persistent_prop:
			failures.append("Destroyed persisted props should not reappear in cleared floor maps.")
			break
	var return_direction := String(DUNGEON_OPPOSITE_DIRECTIONS.get(first_path_direction, ""))
	if manager.enter_direction(return_direction):
		if not manager.enter_direction(first_path_direction):
			failures.append("DungeonManager should preserve a generated combat room after revisiting it.")
		elif _get_level_generation_signature(manager.get_current_level_definition()) != first_signature:
			failures.append("Revisited generated dungeon room should keep the same interior.")
	else:
		failures.append("Dungeon persistence test could not return to the start room.")

	var repeated_manager = load("res://scripts/managers/dungeon_manager.gd").new()
	root.add_child(repeated_manager)
	repeated_manager.reset_run(2, 7777)
	repeated_manager.set_enabled(true)
	repeated_manager.enter_direction(first_path_direction)
	if _get_level_generation_signature(repeated_manager.get_current_level_definition()) != first_signature:
		failures.append("DungeonManager should regenerate the same room interior from the same floor seed.")
	var changed_manager = load("res://scripts/managers/dungeon_manager.gd").new()
	root.add_child(changed_manager)
	changed_manager.reset_run(2, 8888)
	changed_manager.set_enabled(true)
	var changed_path_direction := _get_connection_direction_between_rooms(changed_manager, "start", "path_1")
	changed_manager.enter_direction(changed_path_direction)
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
	var prop_parts: Array[String] = []
	for placement in level.destructible_prop_placements:
		if placement == null:
			continue
		prop_parts.append("%s@%d,%d:%dx%d:%d" % [
			String(placement.prop_kind),
			int(round(placement.position.x)),
			int(round(placement.position.y)),
			int(round(placement.size.x)),
			int(round(placement.size.y)),
			int(placement.max_health)
		])
	return "%s|%s|%s|%d" % [
		";".join(wall_parts),
		";".join(void_parts),
		";".join(spawner_parts) + "|" + ";".join(prop_parts),
		int(level.max_active_enemies)
	]


func _rect_signature(rect: Rect2) -> String:
	return "%d,%d,%d,%d" % [
		int(round(rect.position.x)),
		int(round(rect.position.y)),
		int(round(rect.size.x)),
		int(round(rect.size.y))
	]


func _rect_list_has_rect(rects: Array[Rect2], expected: Rect2) -> bool:
	return _rect_list_count_rect(rects, expected) > 0


func _rect_list_count_rect(rects: Array[Rect2], expected: Rect2) -> int:
	var count := 0
	for rect in rects:
		if _rects_are_same(rect, expected):
			count += 1
	return count


func _rects_are_same(first: Rect2, second: Rect2) -> bool:
	return first.position.distance_squared_to(second.position) <= 0.25 and first.size.distance_squared_to(second.size) <= 0.25


func _generated_room_has_non_basic_spawner(level) -> bool:
	for placement in level.spawner_placements:
		if placement != null and placement.profile != null and not String(placement.profile.resource_path).ends_with("basic_spawner.tres"):
			return true
	return false


func _get_spawner_option_cost_by_file(options: Array[Dictionary], file_name: String) -> int:
	for option in options:
		var profile = option.get("profile", null)
		if profile != null and String(profile.resource_path).ends_with(file_name):
			return int(option.get("cost", 0))
	return 0


func _collect_level_spawner_profile_files(level, seen_profiles: Dictionary) -> void:
	for placement in level.spawner_placements:
		if placement == null or placement.profile == null:
			continue
		seen_profiles[String(placement.profile.resource_path).get_file()] = true


func _get_level_meta_rects(level, meta_key: String, fallback: Array[Rect2]) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if level != null and level.has_meta(meta_key):
		for rect in level.get_meta(meta_key):
			rects.append(rect)
	else:
		rects.append_array(fallback)
	return rects


func _get_blocker_tile_count(level) -> int:
	if level == null:
		return 0
	return _get_level_meta_rects(level, "wall_tile_rects", level.wall_rects).size() + _get_level_meta_rects(level, "void_tile_rects", level.void_rects).size()


func _level_has_interior_blocker(level) -> bool:
	return not _get_level_interior_blocker_rects(level).is_empty()


func _get_level_interior_blocker_rects(level) -> Array[Rect2]:
	var interior: Array[Rect2] = []
	if level == null:
		return interior
	for rect in _get_level_meta_rects(level, "wall_tile_rects", level.wall_rects):
		if not _rect_touches_arena_edge(rect, level.arena_bounds):
			interior.append(rect)
	for rect in _get_level_meta_rects(level, "void_tile_rects", level.void_rects):
		if not _rect_touches_arena_edge(rect, level.arena_bounds):
			interior.append(rect)
	return interior


func _get_level_prop_rects(level) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if level == null:
		return rects
	for placement in level.destructible_prop_placements:
		if placement == null:
			continue
		rects.append(Rect2(placement.position - placement.size * 0.5, placement.size))
	return rects


func _rect_touches_arena_edge(rect: Rect2, bounds: Rect2) -> bool:
	var epsilon := 1.0
	return abs(rect.position.x - bounds.position.x) <= epsilon or abs(rect.position.y - bounds.position.y) <= epsilon or abs(rect.position.x + rect.size.x - (bounds.position.x + bounds.size.x)) <= epsilon or abs(rect.position.y + rect.size.y - (bounds.position.y + bounds.size.y)) <= epsilon


func _level_blockers_are_tile_aligned(level) -> bool:
	if level == null:
		return false
	var tile_size: float = load("res://scripts/resources/room_geometry_builder.gd").WALL_TILE_SIZE
	for rect in _get_level_meta_rects(level, "wall_tile_rects", level.wall_rects):
		if not _rect_is_tile_aligned(rect, tile_size):
			return false
	for rect in _get_level_meta_rects(level, "void_tile_rects", level.void_rects):
		if not _rect_is_tile_aligned(rect, tile_size):
			return false
	return true


func _level_generated_blockers_stay_inside_footprint(level) -> bool:
	if level == null or not level.has_meta("footprint_cells"):
		return false
	for rect in _get_level_meta_rects(level, "wall_tile_rects", level.wall_rects):
		if not _rect_fits_level_footprint(level, rect):
			return false
	for rect in _get_level_meta_rects(level, "wall_body_tile_rects", level.wall_rects):
		if not _rect_fits_level_footprint(level, rect):
			return false
	for rect in _get_level_meta_rects(level, "void_tile_rects", level.void_rects):
		if not _rect_fits_level_footprint(level, rect):
			return false
	for placement in level.destructible_prop_placements:
		if placement == null:
			continue
		var prop_rect := Rect2(placement.position - placement.size * 0.5, placement.size)
		if not _rect_fits_level_footprint(level, prop_rect):
			return false
	for placement in level.spawner_placements:
		if placement != null and not _point_is_in_level_footprint(level, placement.position):
			return false
	return true


func _rect_fits_level_footprint(level, rect: Rect2) -> bool:
	var inset: float = min(1.0, min(rect.size.x, rect.size.y) * 0.25)
	var points := [
		rect.position + Vector2(inset, inset),
		rect.position + Vector2(rect.size.x - inset, inset),
		rect.position + rect.size - Vector2(inset, inset),
		rect.position + Vector2(inset, rect.size.y - inset),
		rect.get_center()
	]
	for point in points:
		if not _point_is_in_level_footprint(level, point):
			return false
	return true


func _point_is_in_level_footprint(level, point: Vector2) -> bool:
	var builder = load("res://scripts/resources/room_geometry_builder.gd")
	var cells: Array[Vector2i] = []
	for cell in level.get_meta("footprint_cells"):
		cells.append(cell)
	for cell in cells:
		var rect: Rect2 = builder.get_cell_rect(cells, cell)
		if point.x >= rect.position.x - 0.5 and point.y >= rect.position.y - 0.5 and point.x <= rect.position.x + rect.size.x + 0.5 and point.y <= rect.position.y + rect.size.y + 0.5:
			return true
	return false


func _level_door_openings_are_unblocked(level, connections: Dictionary) -> bool:
	if level == null:
		return false
	for direction_key in connections.keys():
		var opening_rects := _get_level_connection_opening_rects(level, String(direction_key))
		if opening_rects.is_empty():
			continue
		for rect in level.wall_rects:
			for opening_rect in opening_rects:
				if rect.intersects(opening_rect):
					return false
		for rect in level.void_rects:
			for opening_rect in opening_rects:
				if rect.intersects(opening_rect):
					return false
	return true


func _get_level_connection_opening_rects(level, direction: String) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var top_opening := _get_level_connection_opening_rect(level, direction)
	if top_opening.size == Vector2.ZERO:
		return rects
	rects.append(top_opening)
	var body_opening := _get_level_connection_body_opening_rect(level, direction)
	if body_opening.size != Vector2.ZERO and body_opening != top_opening:
		rects.append(body_opening)
	return rects


func _get_level_connection_opening_rect(level, direction: String) -> Rect2:
	if level == null or not level.has_meta("connection_edges") or not level.has_meta("footprint_cells"):
		return Rect2()
	var edges: Dictionary = level.get_meta("connection_edges")
	if not edges.has(direction):
		return Rect2()
	var builder = load("res://scripts/resources/room_geometry_builder.gd")
	var cells: Array[Vector2i] = []
	for cell in level.get_meta("footprint_cells"):
		cells.append(cell)
	var edge: Dictionary = edges[direction]
	return builder.get_gate_passage_rect(cells, edge.get("source_cell", Vector2i.ZERO), direction)


func _get_level_connection_body_opening_rect(level, direction: String) -> Rect2:
	if level == null or not level.has_meta("connection_edges") or not level.has_meta("footprint_cells"):
		return Rect2()
	var edges: Dictionary = level.get_meta("connection_edges")
	if not edges.has(direction):
		return Rect2()
	var builder = load("res://scripts/resources/room_geometry_builder.gd")
	var cells: Array[Vector2i] = []
	for cell in level.get_meta("footprint_cells"):
		cells.append(cell)
	var edge: Dictionary = edges[direction]
	return builder.get_wall_body_opening_rect(cells, edge.get("source_cell", Vector2i.ZERO), direction)


func _rect_is_tile_aligned(rect: Rect2, tile_size: float) -> bool:
	if tile_size <= 0.0:
		return false
	var values := [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	for value in values:
		if abs(value - round(value / tile_size) * tile_size) > 0.5:
			return false
	return true


func _has_contiguous_blocker_group(rects: Array[Rect2], min_count: int) -> bool:
	var visited: Dictionary = {}
	for index in range(rects.size()):
		if visited.has(index):
			continue
		var group_size := 0
		var queue: Array[int] = [index]
		visited[index] = true
		while not queue.is_empty():
			var current_index: int = queue.pop_front()
			group_size += 1
			for next_index in range(rects.size()):
				if visited.has(next_index):
					continue
				if not _blocker_rects_touch(rects[current_index], rects[next_index]):
					continue
				visited[next_index] = true
				queue.append(next_index)
		if group_size >= min_count:
			return true
	return false


func _has_rotational_blocker_pair(rects: Array[Rect2], center: Vector2) -> bool:
	for first_index in range(rects.size()):
		var first := rects[first_index]
		var first_delta := first.get_center() - center
		for second_index in range(first_index + 1, rects.size()):
			var second := rects[second_index]
			var second_delta := second.get_center() - center
			if first.size.distance_squared_to(second.size) > 1.0:
				continue
			if (first_delta + second_delta).length_squared() <= 4.0:
				return true
	return false


func _blocker_rects_touch(first: Rect2, second: Rect2) -> bool:
	var tile_size: float = load("res://scripts/resources/room_geometry_builder.gd").WALL_TILE_SIZE
	var center_delta := first.get_center() - second.get_center()
	if abs(abs(center_delta.x) - tile_size) <= 1.0 and abs(center_delta.y) <= 1.0:
		return true
	if abs(abs(center_delta.y) - tile_size) <= 1.0 and abs(center_delta.x) <= 1.0:
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
	var seen_start_path_directions: Dictionary = {}
	for seed in range(1, 81):
		manager.reset_run(1, seed)
		var path_direction := _get_connection_direction_between_rooms(manager, "start", "path_1")
		if not path_direction.is_empty():
			seen_start_path_directions[path_direction] = true
	for direction in DUNGEON_DIRECTION_OFFSETS.keys():
		if not seen_start_path_directions.has(String(direction)):
			failures.append("Entry room should be able to start the boss path toward %s." % String(direction))
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


func _get_connection_direction_between_rooms(manager, from_id: String, to_id: String) -> String:
	if not manager._rooms.has(from_id):
		return ""
	var room_state: Dictionary = manager._rooms[from_id]
	var connections: Dictionary = room_state.get("connections", {})
	for direction_key in connections.keys():
		if String(connections[direction_key]) == to_id:
			return String(direction_key)
	return ""


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
		if String(room_info.get("kind", "")) == "boss" and connections.size() != 1:
			failures.append("Dungeon layout boss room should have exactly one entrance: %s" % label)
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
	_validate_dungeon_physical_door_adjacency(rooms_by_id, failures, label)
	_validate_dungeon_room_size_mix(rooms_by_id, failures, label)


func _validate_dungeon_room_size_mix(rooms_by_id: Dictionary, failures: Array[String], label: String) -> void:
	var combat_count := 0
	var large_count := 0
	var crossroads_count := 0
	for room_id in rooms_by_id.keys():
		var room_info: Dictionary = rooms_by_id[room_id]
		var kind := String(room_info.get("kind", ""))
		var cell_count := Array(room_info.get("footprint_cells", [])).size()
		if kind == "start" or kind == "treasure":
			if cell_count != 1:
				failures.append("Dungeon special rooms should stay one cell: %s %s" % [room_id, label])
		if kind != "combat":
			continue
		combat_count += 1
		if cell_count > 5:
			failures.append("Dungeon combat room exceeded the five-cell hard limit: %s %s" % [room_id, label])
		if cell_count == 5:
			crossroads_count += 1
		elif cell_count >= 4:
			large_count += 1
	if crossroads_count > 1:
		failures.append("Dungeon should place at most one five-cell crossroads room per floor: %s" % label)
	if combat_count > 0 and large_count > max(1, int(ceil(float(combat_count) * 0.25))):
		failures.append("Dungeon generated too many four-cell combat rooms: %s" % label)


func _validate_dungeon_physical_door_adjacency(rooms_by_id: Dictionary, failures: Array[String], label: String) -> void:
	var occupied: Dictionary = {}
	for room_id in rooms_by_id.keys():
		var room_info: Dictionary = rooms_by_id[room_id]
		var anchor: Vector2i = room_info["anchor"]
		for local_cell in room_info["footprint_cells"]:
			var world_cell: Vector2i = anchor + local_cell
			occupied[_cell_key_for_test(world_cell)] = String(room_id)
	for room_id in rooms_by_id.keys():
		var room_info: Dictionary = rooms_by_id[room_id]
		var connections: Dictionary = room_info.get("connections", {})
		var connection_edges: Dictionary = room_info.get("connection_edges", {})
		for direction_key in connections.keys():
			var key := "%s|%s" % [room_id, String(direction_key)]
			var direction := String(direction_key)
			var target_id := String(connections[direction_key])
			if not connection_edges.has(direction) or not rooms_by_id.has(target_id):
				failures.append("Dungeon layout logical doorway should store selected cell edge metadata %s: %s" % [key, label])
				continue
			var edge: Dictionary = connection_edges[direction]
			var target_info: Dictionary = rooms_by_id[target_id]
			var source_world: Vector2i = Vector2i(room_info["anchor"]) + edge.get("source_cell", Vector2i.ZERO)
			var target_world: Vector2i = Vector2i(target_info["anchor"]) + edge.get("target_cell", Vector2i.ZERO)
			if source_world + DUNGEON_DIRECTION_OFFSETS[direction] != target_world:
				failures.append("Dungeon layout selected cell edge should match physical adjacency %s: %s" % [key, label])
			if String(occupied.get(_cell_key_for_test(source_world), "")) != String(room_id) or String(occupied.get(_cell_key_for_test(target_world), "")) != target_id:
				failures.append("Dungeon layout selected cell edge should reference occupied cells %s: %s" % [key, label])


func _count_dungeon_incidental_contacts(manager) -> int:
	var rooms_by_id: Dictionary = {}
	var occupied: Dictionary = {}
	for room_info in manager.get_minimap_rooms():
		var room_id := String(room_info["id"])
		rooms_by_id[room_id] = room_info
		var anchor: Vector2i = room_info["anchor"]
		for local_cell in room_info["footprint_cells"]:
			var world_cell: Vector2i = anchor + local_cell
			occupied[_cell_key_for_test(world_cell)] = room_id
	var counted := {}
	var contact_count := 0
	for room_id in rooms_by_id.keys():
		var room_info: Dictionary = rooms_by_id[room_id]
		var anchor: Vector2i = room_info["anchor"]
		var connections: Dictionary = room_info.get("connections", {})
		for local_cell in room_info["footprint_cells"]:
			var world_cell: Vector2i = anchor + local_cell
			for direction_key in DUNGEON_DIRECTION_OFFSETS.keys():
				var direction := String(direction_key)
				var neighbor_cell: Vector2i = world_cell + DUNGEON_DIRECTION_OFFSETS[direction]
				var neighbor_id := String(occupied.get(_cell_key_for_test(neighbor_cell), ""))
				if neighbor_id.is_empty() or neighbor_id == String(room_id):
					continue
				if String(connections.get(direction, "")) == neighbor_id:
					continue
				var cell_key_a := "%s:%s" % [String(room_id), _cell_key_for_test(world_cell)]
				var cell_key_b := "%s:%s" % [neighbor_id, _cell_key_for_test(neighbor_cell)]
				var contact_key := "%s|%s" % [cell_key_a, cell_key_b]
				var reverse_contact_key := "%s|%s" % [cell_key_b, cell_key_a]
				if counted.has(contact_key) or counted.has(reverse_contact_key):
					continue
				counted[contact_key] = true
				contact_count += 1
	return contact_count


func _cell_key_for_test(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


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
	var boss_path := _get_path_to_room_kind(manager, "boss")
	if boss_path.size() < 2:
		failures.append("DungeonManager should expose a traversable boss route.")
	else:
		for path_index in range(1, boss_path.size()):
			var direction := _get_connection_direction_between_rooms(manager, boss_path[path_index - 1], boss_path[path_index])
			if direction.is_empty() or not manager.enter_direction(direction):
				failures.append("DungeonManager should allow traversing generated boss route edge %s -> %s." % [boss_path[path_index - 1], boss_path[path_index]])
				break
			if manager.get_revealed_room_count() < path_index + 1:
				failures.append("DungeonManager should reveal rooms as the player traverses them.")
			if path_index < boss_path.size() - 1:
				manager.mark_current_room_cleared()
		if not manager.is_current_boss_room():
			failures.append("DungeonManager generated boss route should lead to the boss room.")
	for seed in [116, 490, 887, 1115]:
		manager.reset_run(1, seed)
		_validate_dungeon_layout_integrity(manager, failures, "reported branch repro seed %d" % seed)
	var found_incidental_contact := false
	for floor in range(1, 6):
		for seed in range(1, 61):
			manager.reset_run(floor, seed)
			_validate_dungeon_layout_integrity(manager, failures, "floor %d seed %d" % [floor, seed])
			if _count_dungeon_incidental_contacts(manager) > 0:
				found_incidental_contact = true
	if not found_incidental_contact:
		failures.append("Dungeon layout solver should allow dense tesselation through incidental room adjacency.")
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
	for special_kind in ["treasure", "challenge", "boss"]:
		var path := _get_path_to_room_kind(dungeon, special_kind)
		if path.size() < 2:
			failures.append("Dungeon should expose a path to a %s room for door marking." % special_kind)
			continue
		dungeon.current_room_id = path[path.size() - 2]
		var target_id := String(path[path.size() - 1])
		var found_marked_door := false
		for door_info in dungeon.get_current_door_infos():
			if String(door_info.get("target_room_id", "")) == target_id and String(door_info.get("target_room_kind", "")) == special_kind:
				found_marked_door = true
				break
		if not found_marked_door:
			failures.append("Door info should mark entrances leading to %s rooms." % special_kind)
	dungeon.current_room_id = "start"
	manager.set_enabled(true)
	manager.load_room(dungeon.get_current_level_definition(), dungeon.get_current_door_infos(), true)
	for door_info in dungeon.get_current_door_infos():
		if not door_info.has("trigger_rect") or not door_info.has("opening_rect"):
			failures.append("Dungeon door infos should expose derived trigger and opening rects.")
		if not door_info.has("passage_rect"):
			failures.append("Dungeon door infos should expose derived passable gate rects for marker placement.")
		if not door_info.has("source_cell") or not door_info.has("target_cell"):
			failures.append("Dungeon door infos should expose source and target cells.")
	if manager.get_door_count() < 2:
		failures.append("RoomManager should create doors for the start room's connected exits.")
	if door_layer.get_child_count() != manager.get_door_count():
		failures.append("RoomManager should add door entities to the injected door layer.")
	for child in door_layer.get_children():
		if not child.is_in_group("dungeon_doors"):
			failures.append("Door entity is missing the dungeon_doors group.")
		if not child.unlocked:
			failures.append("RoomManager should unlock doors for an already-cleared room.")
		if child.has_method("is_gate_blocking") and child.is_gate_blocking():
			failures.append("Unlocked dungeon doors should not keep gate collision enabled.")
		if (child.collision_mask & 1) == 0:
			failures.append("Door entity should watch the player collision layer.")
		if not child.visible:
			failures.append("Generated dungeon doors should draw visible gate tiles aligned to wall openings.")
	var locked_layer := Node2D.new()
	var locked_manager = load("res://scripts/managers/room_manager.gd").new()
	root.add_child(locked_layer)
	root.add_child(locked_manager)
	locked_manager.initialize({
		"door_layer": locked_layer
	})
	locked_manager.load_room(dungeon.get_current_level_definition(), dungeon.get_current_door_infos(), false)
	for child in locked_layer.get_children():
		if not child.has_method("is_gate_blocking") or not child.is_gate_blocking():
			failures.append("Locked dungeon doors should block movement with gate collision.")
		child.set_unlocked(true)
		if child.has_method("is_gate_blocking") and child.is_gate_blocking():
			failures.append("Dungeon gate collision should disable when a door unlocks.")
	locked_manager.free()
	locked_layer.free()
	var marker_layer := Node2D.new()
	var marker_manager = load("res://scripts/managers/room_manager.gd").new()
	var marker_level = load("res://scripts/resources/level_definition.gd").new()
	var marker_infos := [
		{"direction": "north", "target_room_id": "treasure_1", "target_room_kind": "treasure"},
		{"direction": "east", "target_room_id": "challenge_1", "target_room_kind": "challenge"},
		{"direction": "south", "target_room_id": "boss", "target_room_kind": "boss"}
	]
	root.add_child(marker_layer)
	root.add_child(marker_manager)
	marker_manager.initialize({
		"door_layer": marker_layer
	})
	marker_manager.load_room(marker_level, marker_infos, true)
	var seen_markers: Dictionary = {}
	for child in marker_layer.get_children():
		seen_markers[String(child.target_room_kind)] = bool(child.has_special_marker())
	for special_kind in ["treasure", "challenge", "boss"]:
		if not bool(seen_markers.get(special_kind, false)):
			failures.append("RoomManager should propagate %s door markers to door entities." % special_kind)
	marker_manager.free()
	marker_layer.free()
	var direct_door = load("res://scenes/entities/door_entity.tscn").instantiate()
	var player = load("res://scenes/entities/player_entity.tscn").instantiate()
	var entered_count := [0]
	root.add_child(direct_door)
	root.add_child(player)
	direct_door.initialize("east", "next", Vector2.ZERO, Vector2(28.0, 92.0), true, "boss")
	if direct_door.is_gate_blocking():
		failures.append("Direct unlocked door should not create blocking gate collision.")
	direct_door.set_unlocked(false)
	if not direct_door.is_gate_blocking():
		failures.append("Direct locked door should create blocking gate collision.")
	var gate_top_visual = direct_door.get_node_or_null("GateTopVisual")
	if gate_top_visual == null or int(gate_top_visual.z_index) != 5:
		failures.append("Locked dungeon gates should draw their top cap on the wall-top z level.")
	var marker_tile_size: float = load("res://scripts/resources/room_geometry_builder.gd").WALL_TILE_SIZE
	var side_gate_rect := Rect2(Vector2.ZERO, Vector2(marker_tile_size, marker_tile_size * 4.0))
	var side_gate_top_rects: Array[Rect2] = direct_door._get_gate_top_rects(side_gate_rect)
	var side_gate_lowest_top := Rect2(Vector2(0.0, marker_tile_size * 2.0), Vector2(marker_tile_size, marker_tile_size))
	var side_gate_passable_wall_top := Rect2(Vector2(0.0, marker_tile_size * 3.0), Vector2(marker_tile_size, marker_tile_size))
	if side_gate_top_rects.size() != 3 or not _rect_list_has_rect(side_gate_top_rects, side_gate_lowest_top):
		failures.append("Closed side gates should render as a continuous top run above the lowest passable wall-top tile.")
	if _rect_list_has_rect(side_gate_top_rects, side_gate_passable_wall_top):
		failures.append("Closed side gate tops should not overpaint the lowest passable wall-top tile.")
	var side_gate_body_rects: Array[Rect2] = direct_door._get_gate_body_rects(side_gate_rect)
	var side_gate_lowest_body := Rect2(Vector2(0.0, marker_tile_size * 3.0), Vector2(marker_tile_size, marker_tile_size))
	if not _rect_list_has_rect(side_gate_body_rects, side_gate_lowest_body):
		failures.append("Closed side gate bodies should tuck under the lowest passable wall-top tile.")
	var south_door = load("res://scenes/entities/door_entity.tscn").instantiate()
	root.add_child(south_door)
	var south_gate_visual_rect := Rect2(Vector2(120.0, 320.0), Vector2(marker_tile_size * 4.0, marker_tile_size))
	var expected_south_gate_blocker := Rect2(south_gate_visual_rect.position + Vector2(0.0, marker_tile_size), south_gate_visual_rect.size)
	south_door.initialize("south", "next", Vector2.ZERO, south_gate_visual_rect.size, false)
	south_door.set_visual_rect(south_gate_visual_rect.get_center(), south_gate_visual_rect.size)
	if not _rects_are_same(south_door.get_gate_blocker_rect(), expected_south_gate_blocker):
		failures.append("Closed south gates should place their blocker on the wall body row below the visible gate top.")
	var south_gate_body := south_door.get_node_or_null("GateBlocker") as Node2D
	var south_gate_collision: CollisionShape2D = null
	if south_gate_body != null:
		south_gate_collision = south_gate_body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var south_gate_shape: RectangleShape2D = null
	if south_gate_collision != null:
		south_gate_shape = south_gate_collision.shape as RectangleShape2D
	if south_gate_body == null or south_gate_shape == null or south_gate_body.global_position.distance_squared_to(expected_south_gate_blocker.get_center()) > 0.25 or south_gate_shape.size.distance_squared_to(expected_south_gate_blocker.size) > 0.25:
		failures.append("Closed south gate collision should match the shifted wall body blocker, not the visible top strip.")
	direct_door.set_unlocked(true)
	if not direct_door.has_special_marker():
		failures.append("Door entity should treat boss targets as special marked doors.")
	var marker_passage_rect := Rect2(Vector2(80.0, 140.0), Vector2(40.0, 120.0))
	var expected_marker_center: Vector2 = marker_passage_rect.get_center() + Vector2(-marker_tile_size, 0.0)
	if direct_door._get_floor_marker_center(marker_passage_rect).distance_squared_to(expected_marker_center) > 0.5:
		failures.append("Door special markers should sit one tile in front of side-facing gate passages.")
	direct_door.entered.connect(func(_door) -> void:
		entered_count[0] += 1
	)
	direct_door._on_body_entered(player)
	if entered_count[0] != 0:
		failures.append("Freshly loaded doors should not trigger before the player leaves their trigger area.")
	direct_door._refresh_armed_state()
	direct_door._on_body_entered(player)
	if entered_count[0] != 1:
		failures.append("Door should trigger normally after it has armed.")
	south_door.free()
	direct_door.free()
	player.free()
	manager.free()
	dungeon.free()
	door_layer.free()


func _test_agent_boss_generation_and_behavior(failures: Array[String]) -> void:
	var generator = load("res://scripts/resources/agent_boss_generator.gd")
	var base_profile = load("res://resources/enemies/first_boss_enemy.tres")
	if generator == null or base_profile == null:
		failures.append("Agent boss resources failed to load.")
		return
	var first_profile: EnemyProfile = generator.generate_profile(base_profile, 123456, 3, "boss_room")
	var repeated_profile: EnemyProfile = generator.generate_profile(base_profile, 123456, 3, "boss_room")
	var different_profile: EnemyProfile = generator.generate_profile(base_profile, 123457, 3, "boss_room")
	if first_profile.agent_program == null:
		failures.append("Generated boss profile should carry an agent program.")
		return
	var program: AgentBossProgram = first_profile.agent_program
	var repeated_program: AgentBossProgram = repeated_profile.agent_program
	if program.personality_verb != repeated_program.personality_verb or program.normal_movement_verb != repeated_program.normal_movement_verb or program.slow_attack_verb != repeated_program.slow_attack_verb or program.high_explosive_verb != repeated_program.high_explosive_verb or program.special_movement_verb != repeated_program.special_movement_verb or program.special_reposition_verb != repeated_program.special_reposition_verb or program.special_attack_verb != repeated_program.special_attack_verb:
		failures.append("Agent boss generation should be deterministic for seed/floor/level id.")
	if program.generation_seed == different_profile.agent_program.generation_seed:
		failures.append("Agent boss generation should vary its deterministic seed when the run seed changes.")
	if not ["hunter", "bully", "coward", "duelist"].has(String(program.personality_verb)):
		failures.append("Generated agent boss picked an unknown movement personality.")
	if not ["strafe", "push_forward", "zig_zag", "pull_back"].has(String(program.normal_movement_verb)):
		failures.append("Generated agent boss picked an unknown normal movement verb.")
	if not ["fast_single", "short_scatter", "wide_scatter", "assault_burst"].has(String(program.slow_attack_verb)):
		failures.append("Generated agent boss picked an unknown slow pressure attack verb.")
	if not ["teleport_los", "dash_chain", "charge"].has(String(program.special_movement_verb)):
		failures.append("Generated agent boss picked an unknown special movement verb.")
	if not ["approach", "retreat", "strafe"].has(String(program.special_reposition_verb)):
		failures.append("Generated agent boss picked an unknown special reposition verb.")
	if not ["minigun_sweep_twice", "spiral_clockwise", "spiral_counter_clockwise", "ring_pulse_three_waves", "pinwheel_burst"].has(String(program.special_attack_verb)):
		failures.append("Generated agent boss picked an unknown special attack verb.")
	if not ["rocket", "grenade", "mines"].has(String(program.high_explosive_verb)):
		failures.append("Generated agent boss picked an unknown high-explosive normal-movement verb.")
	if not is_equal_approx(float(program.slow_action_weight), 0.33) or not is_equal_approx(float(program.normal_action_weight), 0.33) or not is_equal_approx(float(program.special_action_weight), 0.33):
		failures.append("Agent boss default action weights should stay at 33/33/33 before special cooldown gating.")
	var player = load("res://scenes/entities/player_entity.tscn").instantiate()
	var player_radius: float = float(player.body_radius)
	if float(first_profile.body_radius) < player_radius * 0.94 or float(first_profile.body_radius) > player_radius * 1.13:
		failures.append("Generated agent boss body radius should stay in the player-sized variation range.")
	if is_equal_approx(float(first_profile.body_radius), float(different_profile.body_radius)):
		failures.append("Generated agent boss body radius should vary across generated loadouts.")
	if int(first_profile.contact_damage) != 0 or float(first_profile.contact_radius) != 0.0:
		failures.append("Generated agent boss profile should not deal contact damage.")
	player.free()

	var boss = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	boss.initialize(first_profile)
	boss.set_arena_definition(Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0)), 0, [], [], [])
	if not boss._is_agent_boss():
		failures.append("Generated profile should enable agent boss behavior.")
	if int(boss.contact_damage) != 0 or (int(boss.collision_mask) & 1) != 0 or (int(boss.collision_layer) & 128) == 0:
		failures.append("Agent boss entity should not deal contact damage or hard-collide with the player body.")
	var shot_configs: Array[Dictionary] = []
	boss.shot_ready.connect(func(_enemy, _origin, _direction, shot_config) -> void:
		shot_configs.append(shot_config)
	)
	boss._agent_next_shot_remaining = 0.0
	boss._try_emit_agent_standard_shot(Vector2.RIGHT * 300.0, 0.4, 390.0, 1, 4.7)
	if shot_configs.is_empty() or String(shot_configs[0].get("kind", "")) != "hostile" or int(shot_configs[0].get("projectile_count", 0)) != 1:
		failures.append("Agent slow/normal shots should emit single hostile shot configs.")
	_test_agent_slow_pressure_variants(failures, boss)
	for attack_verb in ["minigun_sweep_twice", "spiral_clockwise", "ring_pulse_three_waves", "pinwheel_burst"]:
		boss.agent_program.special_attack_verb = attack_verb
		boss._emit_agent_special_attack(Vector2.RIGHT * 360.0)
		if attack_verb == "minigun_sweep_twice" or attack_verb == "spiral_clockwise":
			boss._update_agent_special_stream(0.08)
		elif attack_verb == "ring_pulse_three_waves":
			boss._update_agent_special_stream(0.2)
		elif attack_verb == "pinwheel_burst":
			boss._update_agent_special_stream(0.12)
	var saw_minigun := false
	var saw_spiral := false
	var saw_pulse := false
	var saw_pinwheel := false
	for config in shot_configs:
		saw_minigun = saw_minigun or String(config.get("kind", "")) == "hostile_minigun"
		saw_spiral = saw_spiral or String(config.get("kind", "")) == "hostile_spiral"
		saw_pulse = saw_pulse or String(config.get("kind", "")) == "hostile_pulse"
		saw_pinwheel = saw_pinwheel or String(config.get("kind", "")) == "hostile_pinwheel"
	if not saw_minigun or not saw_spiral or not saw_pulse or not saw_pinwheel:
		failures.append("Agent specials should emit double-sweep minigun, spiral, pulse, and pinwheel shot configs.")
	boss.free()
	_test_agent_contact_disabled(failures, first_profile)
	_test_agent_high_explosive_normal_moves(failures, first_profile)
	_test_agent_push_pull_pathing(failures, first_profile)
	_test_agent_special_reposition(failures, first_profile)
	_test_agent_teleport_cast_and_charge_special(failures, first_profile)
	_test_agent_special_cooldown_and_chain(failures, first_profile)


func _test_agent_slow_pressure_variants(failures: Array[String], boss: EnemyEntity) -> void:
	var emitted_kinds: Dictionary = {}
	var scatter_projectile_count := [0]
	var assault_shot_count := [0]
	boss.shot_ready.connect(func(_enemy, _origin, _direction, shot_config) -> void:
		var kind: String = String(shot_config.get("kind", ""))
		emitted_kinds[kind] = int(emitted_kinds.get(kind, 0)) + 1
		if kind == "hostile_scatter":
			scatter_projectile_count[0] = max(scatter_projectile_count[0], int(shot_config.get("projectile_count", 0)))
		if kind == "hostile_assault":
			assault_shot_count[0] += 1
	)
	var slow_attack_verbs: Array[String] = ["fast_single", "short_scatter", "wide_scatter", "assault_burst"]
	for slow_attack_verb in slow_attack_verbs:
		boss.agent_program.slow_attack_verb = slow_attack_verb
		boss._agent_next_shot_remaining = 0.0
		boss._clear_agent_slow_fire_state()
		boss._update_agent_slow_pressure_shots(Vector2.RIGHT * 320.0)
		if slow_attack_verb == "assault_burst":
			boss._agent_burst_interval_remaining = 0.0
			boss._update_agent_slow_pressure_shots(Vector2.RIGHT * 320.0)
			boss._agent_burst_interval_remaining = 0.0
			boss._update_agent_slow_pressure_shots(Vector2.RIGHT * 320.0)
	if int(emitted_kinds.get("hostile", 0)) <= 0:
		failures.append("Agent slow pressure fast-single variant should emit hostile single shots.")
	if int(emitted_kinds.get("hostile_scatter", 0)) < 2 or scatter_projectile_count[0] <= 1:
		failures.append("Agent slow pressure scatter variants should emit multi-projectile scatter shots.")
	if assault_shot_count[0] < 3:
		failures.append("Agent slow pressure assault-burst variant should emit sequential automatic fire.")


func _test_agent_contact_disabled(failures: Array[String], base_agent_profile) -> void:
	var enemy_layer := Node2D.new()
	var manager: EnemyManager = load("res://scripts/managers/enemy_manager.gd").new()
	var player: PlayerEntity = load("res://scenes/entities/player_entity.tscn").instantiate() as PlayerEntity
	var contact_count := [0]
	root.add_child(enemy_layer)
	root.add_child(player)
	root.add_child(manager)
	player.global_position = Vector2.ZERO
	manager.initialize({
		"enemy_layer": enemy_layer,
		"player_position_provider": func() -> Vector2:
			return player.global_position,
		"player_ref_provider": func():
			return player
	})
	manager.set_enabled(true)
	manager.player_contact_requested.connect(func(_enemy, _player, _damage) -> void:
		contact_count[0] += 1
	)
	manager.spawn_enemy(base_agent_profile, Vector2.ZERO)
	manager._physics_process(0.2)
	if contact_count[0] != 0:
		failures.append("Agent bosses should not request player contact damage while overlapping the player.")
	manager.free()
	player.free()
	enemy_layer.free()


func _test_agent_high_explosive_normal_moves(failures: Array[String], base_agent_profile) -> void:
	var seen_kinds: Dictionary = {}
	var high_explosive_verbs: Array[String] = ["rocket", "grenade", "mines"]
	for high_explosive_verb in high_explosive_verbs:
		var profile: EnemyProfile = base_agent_profile.duplicate(true) as EnemyProfile
		profile.agent_program.high_explosive_verb = high_explosive_verb
		profile.agent_program.high_explosive_action_chance = 1.0
		profile.agent_program.high_explosive_cooldown_seconds = 3.1
		profile.agent_program.high_explosive_windup_seconds = 0.2
		profile.agent_program.high_explosive_mine_count = 3
		profile.agent_program.high_explosive_mine_interval = 0.05
		var boss: EnemyEntity = load("res://scenes/entities/enemy_entity.tscn").instantiate() as EnemyEntity
		var emitted_configs: Array[Dictionary] = []
		boss.initialize(profile)
		boss.global_position = Vector2.ZERO
		boss.target_position = Vector2.RIGHT * 360.0
		boss.set_arena_definition(Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0)), 0, [], [], [])
		boss.shot_ready.connect(func(_enemy, _origin, _direction, shot_config) -> void:
			emitted_configs.append(shot_config)
			seen_kinds[String(shot_config.get("kind", ""))] = true
		)
		boss._agent_high_explosive_roll_pending = true
		boss._update_agent_normal_high_explosive(0.0, Vector2.RIGHT * 360.0)
		if boss._agent_high_explosive_windup_remaining <= 0.0:
			failures.append("Agent high-explosive %s normal move should start a windup before firing." % high_explosive_verb)
		boss._update_agent_normal_high_explosive(0.25, Vector2.RIGHT * 360.0)
		if high_explosive_verb == "mines":
			boss._agent_mine_sequence_interval_remaining = 0.0
			boss._update_agent_normal_high_explosive(0.05, Vector2.RIGHT * 360.0)
			boss._agent_mine_sequence_interval_remaining = 0.0
			boss._update_agent_normal_high_explosive(0.05, Vector2.RIGHT * 360.0)
		if emitted_configs.is_empty():
			failures.append("Agent high-explosive %s normal move should emit a shot config." % high_explosive_verb)
		if boss._agent_high_explosive_cooldown_remaining <= 0.0:
			failures.append("Agent high-explosive %s normal move should start cooldown." % high_explosive_verb)
		if high_explosive_verb == "mines" and emitted_configs.size() != 3:
			failures.append("Agent mine high-explosive move should emit three mines one at a time.")
		for config in emitted_configs:
			if float(config.get("explosion_radius", 0.0)) <= 0.0 or float(config.get("explosion_damage_multiplier", 0.0)) <= 0.0:
				failures.append("Agent high-explosive %s configs should carry explosion metadata." % high_explosive_verb)
			if high_explosive_verb == "grenade" and (String(config.get("kind", "")) != "agent_grenade" or not bool(config.get("exact_lifetime", false))):
				failures.append("Agent grenade high-explosive move should emit an exact-lifetime lobbed grenade.")
			if high_explosive_verb == "rocket" and (String(config.get("kind", "")) != "rocket" or not bool(config.get("exact_lifetime", false))):
				failures.append("Agent rocket high-explosive move should emit an exact-lifetime targeted rocket.")
			if high_explosive_verb == "mines" and String(config.get("kind", "")) != "agent_mine":
				failures.append("Agent mine high-explosive move should emit mine projectile configs.")
			if high_explosive_verb == "mines" and (float(config.get("arming_seconds", 0.0)) <= 0.0 or not config.has("target_position") or float(config.get("speed", 0.0)) <= 1.0):
				failures.append("Agent mine high-explosive move should emit thrown mine arming metadata.")
		boss.free()
	if not seen_kinds.has("rocket") or not seen_kinds.has("agent_grenade") or not seen_kinds.has("agent_mine"):
		failures.append("Agent high-explosive normal moves should cover rocket, grenade, and mine projectile kinds.")

	var packet: DamagePacket = load("res://scripts/resources/damage_packet.gd").new() as DamagePacket
	var grenade: ProjectileEntity = load("res://scenes/entities/projectile_entity.tscn").instantiate() as ProjectileEntity
	packet.projectile_kind = "agent_grenade"
	grenade.set_projectile_team("hostile")
	grenade.initialize(Vector2.ZERO, Vector2.RIGHT, packet, 300.0)
	if int(grenade.collision_mask) != 0:
		failures.append("Agent grenades should ignore wall and player collision while arcing.")
	grenade.free()

	var mine_packet: DamagePacket = load("res://scripts/resources/damage_packet.gd").new() as DamagePacket
	var mine: ProjectileEntity = load("res://scenes/entities/projectile_entity.tscn").instantiate() as ProjectileEntity
	mine_packet.projectile_kind = "agent_mine"
	mine.set_projectile_team("hostile")
	mine.initialize(Vector2.ZERO, Vector2.RIGHT, mine_packet, 1.0)
	if int(mine.collision_mask) != 1 or mine.speed != 0.0:
		failures.append("Agent mines should be stationary hostile proximity areas.")
	mine.free()


func _test_agent_push_pull_pathing(failures: Array[String], base_agent_profile) -> void:
	var wall_rect := Rect2(Vector2(90.0, -90.0), Vector2(160.0, 180.0))
	for verb in ["push_forward", "pull_back"]:
		var profile = base_agent_profile.duplicate(true)
		profile.agent_program.personality_verb = ""
		profile.agent_program.normal_movement_verb = verb
		profile.agent_program.normal_tactical_distance = 260.0
		var boss = load("res://scenes/entities/enemy_entity.tscn").instantiate()
		boss.initialize(profile)
		boss.global_position = Vector2.ZERO
		boss.set_arena_definition(Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0)), 0, [wall_rect], [], [])
		var to_target := Vector2.RIGHT * 360.0 if verb == "push_forward" else Vector2.LEFT * 360.0
		boss.target_position = boss.global_position + to_target
		var velocity: Vector2 = boss._get_agent_normal_velocity(to_target)
		if velocity.length_squared() <= 0.001:
			failures.append("Agent %s should pick a fallback lane when the direct lane is blocked." % verb)
		elif velocity.normalized().dot(Vector2.RIGHT) > 0.84:
			failures.append("Agent %s should not keep driving directly into a wall-blocked lane." % verb)
		boss.free()


func _test_agent_special_reposition(failures: Array[String], base_agent_profile) -> void:
	for reposition_verb in ["approach", "retreat", "strafe"]:
		var profile = base_agent_profile.duplicate(true)
		profile.agent_program.personality_verb = ""
		profile.agent_program.special_movement_verb = "dash_chain"
		profile.agent_program.special_reposition_verb = reposition_verb
		profile.agent_program.special_move_distance = 260.0
		var boss = load("res://scenes/entities/enemy_entity.tscn").instantiate()
		boss.initialize(profile)
		boss.global_position = Vector2.ZERO
		boss.target_position = Vector2.RIGHT * 360.0
		boss.set_arena_definition(Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0)), 0, [], [], [])
		var target: Vector2 = boss._pick_agent_dash_target(Vector2.RIGHT * 360.0)
		if target == Vector2.INF:
			failures.append("Agent special %s reposition should find a valid dash endpoint." % reposition_verb)
		elif reposition_verb == "approach" and target.x <= boss.global_position.x:
			failures.append("Agent approach special reposition should prefer moving toward the player.")
		elif reposition_verb == "retreat" and target.x >= boss.global_position.x:
			failures.append("Agent retreat special reposition should prefer moving away from the player.")
		elif reposition_verb == "strafe" and abs(target.y - boss.global_position.y) <= abs(target.x - boss.global_position.x):
			failures.append("Agent strafe special reposition should prefer lateral movement.")
		boss.free()


func _test_agent_teleport_cast_and_charge_special(failures: Array[String], base_agent_profile) -> void:
	var teleport_profile = base_agent_profile.duplicate(true)
	teleport_profile.agent_program.special_movement_verb = "teleport_los"
	teleport_profile.agent_program.special_reposition_verb = "retreat"
	teleport_profile.agent_program.teleport_cast_seconds = 0.24
	var teleport_boss = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	teleport_boss.initialize(teleport_profile)
	teleport_boss.global_position = Vector2.ZERO
	teleport_boss.target_position = Vector2.RIGHT * 360.0
	teleport_boss.set_arena_definition(Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0)), 0, [], [], [])
	teleport_boss._start_agent_special_movement(Vector2.RIGHT * 360.0)
	if teleport_boss.global_position != Vector2.ZERO:
		failures.append("Agent teleport should cast before relocating.")
	if teleport_boss._agent_teleport_target == Vector2.INF or teleport_boss._agent_teleport_cast_remaining <= 0.0:
		failures.append("Agent teleport should expose a visible cast destination before moving.")
	teleport_boss._update_agent_teleport_cast(0.3, Vector2.RIGHT * 360.0)
	if teleport_boss.global_position == Vector2.ZERO:
		failures.append("Agent teleport should relocate after the cast completes.")
	if teleport_boss._agent_special_stage != "telegraph":
		failures.append("Agent teleport should transition into special telegraph after relocating.")
	teleport_boss.free()

	var charge_profile = base_agent_profile.duplicate(true)
	charge_profile.agent_program.special_movement_verb = "charge"
	charge_profile.agent_program.special_attack_verb = "minigun_sweep_twice"
	charge_profile.agent_program.charge_windup_seconds = 0.05
	charge_profile.agent_program.charge_seconds = 0.5
	var charge_boss = load("res://scenes/entities/enemy_entity.tscn").instantiate()
	charge_boss.initialize(charge_profile)
	charge_boss.global_position = Vector2.ZERO
	charge_boss.target_position = Vector2.RIGHT * 360.0
	charge_boss.set_arena_definition(Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0)), 0, [], [], [])
	var minigun_shots := [0]
	charge_boss.shot_ready.connect(func(_enemy, _origin, _direction, shot_config) -> void:
		if String(shot_config.get("kind", "")) == "hostile_minigun":
			minigun_shots[0] += 1
	)
	charge_boss._start_agent_charge(Vector2.RIGHT * 360.0)
	var charge_velocity: Vector2 = charge_boss._update_agent_charge(0.12, Vector2.RIGHT * 360.0)
	if charge_velocity.length_squared() <= 0.001:
		failures.append("Agent charge should keep moving while firing its special.")
	if minigun_shots[0] <= 0:
		failures.append("Agent charge should fire stream specials during movement.")
	charge_boss.free()


func _test_agent_special_cooldown_and_chain(failures: Array[String], base_agent_profile) -> void:
	var cooldown_profile: EnemyProfile = base_agent_profile.duplicate(true) as EnemyProfile
	cooldown_profile.agent_program.special_base_cooldown_seconds = 2.4
	cooldown_profile.agent_program.special_chain_cooldown_bonus_seconds = 1.1
	cooldown_profile.agent_program.special_chain_chance = 0.0
	var cooldown_boss: EnemyEntity = load("res://scenes/entities/enemy_entity.tscn").instantiate() as EnemyEntity
	cooldown_boss.initialize(cooldown_profile)
	cooldown_boss.set_arena_definition(Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0)), 0, [], [], [])
	cooldown_boss._agent_special_chain_count = 1
	cooldown_boss._agent_special_attack_emitted = true
	cooldown_boss._finish_agent_special_action()
	if cooldown_boss._agent_special_cooldown_remaining < 2.39 or cooldown_boss._agent_special_cooldown_remaining > 2.41:
		failures.append("Agent special should enter its base cooldown after one completed special.")
	cooldown_boss.agent_program.slow_action_weight = 0.0
	cooldown_boss.agent_program.normal_action_weight = 0.0
	cooldown_boss.agent_program.special_action_weight = 0.33
	cooldown_boss._start_next_agent_action(Vector2.RIGHT * 320.0)
	if cooldown_boss._agent_action_kind == "special":
		failures.append("Agent action selection should gate specials while cooldown is active.")
	cooldown_boss.free()

	var chain_profile: EnemyProfile = base_agent_profile.duplicate(true) as EnemyProfile
	chain_profile.agent_program.special_movement_verb = "dash_chain"
	chain_profile.agent_program.special_chain_chance = 1.0
	chain_profile.agent_program.special_chain_chance_decay = 0.0
	chain_profile.agent_program.max_special_chain_count = 3
	chain_profile.agent_program.special_base_cooldown_seconds = 2.0
	chain_profile.agent_program.special_chain_cooldown_bonus_seconds = 1.5
	var chain_boss: EnemyEntity = load("res://scenes/entities/enemy_entity.tscn").instantiate() as EnemyEntity
	chain_boss.initialize(chain_profile)
	chain_boss.global_position = Vector2.ZERO
	chain_boss.target_position = Vector2.RIGHT * 360.0
	chain_boss.set_arena_definition(Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0)), 0, [], [], [])
	chain_boss._agent_special_chain_count = 1
	chain_boss._agent_special_attack_emitted = true
	chain_boss._finish_agent_special_action()
	if chain_boss._agent_action_kind != "special" or chain_boss._agent_special_chain_count != 2:
		failures.append("Agent special should be able to immediately chain into a second movement plus special combo.")
	chain_boss._agent_special_chain_count = 3
	chain_boss._agent_special_attack_emitted = true
	chain_boss._finish_agent_special_action()
	if chain_boss._agent_special_cooldown_remaining < 4.99 or chain_boss._agent_special_cooldown_remaining > 5.01:
		failures.append("Agent special chain should apply a longer cooldown after the maximum chain count.")
	chain_boss.free()


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
	manager.reset_run()
	var generator = load("res://scripts/resources/agent_boss_generator.gd")
	var agent_profile = generator.generate_profile(load("res://resources/enemies/first_boss_enemy.tres"), 3333, 1, "agent_add_test")
	manager.spawn_enemy(agent_profile, Vector2.ZERO)
	manager._physics_process(manager.boss_add_replenish_interval + 0.1)
	if manager._get_boss_add_count() != 0:
		failures.append("Procedural agent bosses should not summon boss adds.")
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
	if not main.level_list_label.text.contains("> 1. Main Game Loop Test"):
		failures.append("Main level select should keep Main Game Loop Test as the first choice.")
	if not main.level_list_label.text.contains("Generated Agent Intro Test"):
		failures.append("Main level select should expose the generated agent intro test room.")
	if not main.level_list_label.text.contains("Archive"):
		failures.append("Main level select should expose archived older arenas through an Archive option.")
	for archived_only_name in ["Cat Behavior Test", "Peaceful Cat Test", "Generated Drone Test", "Generated Armor Test", "Generated Cyber Test", "Boss Test Chamber"]:
		if main.level_list_label.text.contains(archived_only_name):
			failures.append("%s should live in the Archive menu instead of the main level-select list." % archived_only_name)
	main._level_select_page = main.LEVEL_SELECT_PAGE_ARCHIVE
	main._level_select_option_index = 0
	main._update_level_select_ui()
	for archived_name in ["Square Yard", "Diamond Engine", "Hex Pressure", "Crossfire Foundry", "Circle Gauntlet", "Maze Breaker"]:
		if not main.level_list_label.text.contains(archived_name):
			failures.append("Archive level select should include archived arena: %s" % archived_name)
	for archived_test_name in ["Generated Cyber Test", "Generated Armor Test", "Generated Drone Test", "Boss Test Chamber", "Peaceful Cat Test", "Cat Behavior Test"]:
		if not main.level_list_label.text.contains(archived_test_name):
			failures.append("Archive level select should include archived test room: %s" % archived_test_name)
	if not main.level_list_label.text.contains("Boss Test Chamber"):
		failures.append("Archive level select should include the standalone boss test chamber.")
	if not main.level_list_label.text.contains("Dungeon Prototype"):
		failures.append("Archive level select should include the dungeon prototype.")
	main._start_generated_encounter_test(main.GENERATED_TEST_AGENT_BOSS_INDEX)
	if main._status != "DUNGEON" or not main._is_dungeon_run or main._is_main_loop_run:
		failures.append("Generated agent intro test should start as a generated dungeon boss room.")
	if main.dungeon_manager.get_current_room_kind() != "boss":
		failures.append("Generated agent intro test should load a generated boss room.")
	if main.spawner_manager.get_spawner_count() != 0:
		failures.append("Generated agent intro test should not spawn supporting generals.")
	var current_level: LevelDefinition = main._current_level as LevelDefinition
	if current_level == null:
		failures.append("Generated agent intro test did not load a current full-floor level.")
	elif not bool(current_level.randomize_agent_boss_each_load):
		failures.append("Generated agent intro test should randomize the agent loadout independently from its fixed room seed.")
	var boss_found := false
	for enemy in main.enemy_manager._enemies:
		if is_instance_valid(enemy) and enemy.behavior_kind == "boss":
			boss_found = true
			if enemy.agent_program == null:
				failures.append("Generated agent intro test should spawn a generated agent boss.")
	if not boss_found:
		failures.append("Generated agent intro test should spawn a boss enemy.")
	main.free()


func _test_generated_encounter_test_level_select(failures: Array[String]) -> void:
	var scene = load("res://scenes/main.tscn")
	if scene == null:
		failures.append("Main scene failed to load for generated encounter test level-select test.")
		return
	var main = scene.instantiate()
	root.add_child(main)
	if main.dungeon_manager == null:
		_prime_main_for_direct_test_calls(main)
		main._connect_manager_signals()
		main._initialize_managers()
		main._enter_level_select()
	main._start_generated_encounter_test(main.GENERATED_TEST_DRONE_INDEX)
	if main._status != "DUNGEON" or not main._is_dungeon_run or main._is_main_loop_run:
		failures.append("Generated encounter test should start as a generated dungeon room.")
	if main._active_generated_encounter_test_index != main.GENERATED_TEST_DRONE_INDEX:
		failures.append("Generated encounter test should track the active test index for restart.")
	if main.dungeon_manager.get_current_room_kind() != "combat":
		failures.append("Generated drone test should start in a generated combat room.")
	var current_level: LevelDefinition = main._current_level as LevelDefinition
	if current_level == null:
		failures.append("Generated encounter test did not load a current full-floor level.")
	elif not current_level.has_meta("forced_opening_encounter_profiles"):
		failures.append("Generated encounter test should force its opening enemy profiles on the generated room.")
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

	var boss_path := _get_path_to_room_kind(main.dungeon_manager, "boss")
	if boss_path.size() < 2:
		failures.append("Dungeon orchestrator test could not find a generated boss route.")
	for path_index in range(1, boss_path.size()):
		var direction := _get_connection_direction_between_rooms(main.dungeon_manager, boss_path[path_index - 1], boss_path[path_index])
		if direction.is_empty() or not main.dungeon_manager.enter_direction(direction):
			failures.append("Dungeon orchestrator route could not enter %s from %s." % [boss_path[path_index], boss_path[path_index - 1]])
			break
		main._load_dungeon_current_room(direction, false)
		if path_index < boss_path.size() - 1:
			main.spawner_manager.clear_spawners()
			main.enemy_manager.reset_run()
			main.dungeon_manager.mark_current_room_cleared()
	if not main.dungeon_manager.is_current_boss_room():
		failures.append("Dungeon orchestrator route did not arrive at the boss room.")
	else:
		var boss_found := false
		for enemy in main.enemy_manager._enemies:
			if is_instance_valid(enemy) and enemy.behavior_kind == "boss":
				boss_found = true
				if enemy.agent_program == null:
					failures.append("Boss room should spawn a generated agent boss.")
		if not boss_found:
			failures.append("Boss room should spawn a boss enemy.")
	if main.spawner_manager.get_spawner_count() != 0:
		failures.append("Generated dungeon boss room should not spawn interior spawner structures.")
	if main.dungeon_manager.get_revealed_room_count() < boss_path.size():
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
	main._on_player_parry_chain_changed(3, 3, 2.0, 4.0)
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
	if main.item_manager.get_pickup_count() != 3:
		failures.append("Main loop boss kill should spawn three optional overdrive reward choices.")
	if main.win_panel.visible:
		failures.append("Main loop should wait for portal confirm before showing the next-floor panel.")
	if bool(main._tree_pause_requested):
		failures.append("Main loop boss exit portal should not pause the SceneTree before entry.")
	if not main.enemy_manager.enabled or not main.spawner_manager.enabled or not main.projectile_manager.enabled:
		failures.append("Main loop should keep gameplay managers enabled while the boss exit portal is open.")
	var active_portal = main._floor_exit_portal
	if not main._load_cleared_floor_map(main.player_manager.get_player_position()):
		failures.append("Main loop should allow returning to the cleared floor map after the boss dies.")
	elif main._floor_exit_portal != active_portal or not main._floor_exit_portal_active():
		failures.append("Main loop boss exit portal should persist when leaving the cleared boss room.")
	if main.item_manager.get_pickup_count() != 3:
		failures.append("Main loop boss reward choices should persist when leaving the cleared boss room.")
	main._on_menu_confirm_requested()
	if main._status == "FLOOR_CLEARED":
		failures.append("Main loop floor exit should require standing in the portal before confirm.")
	if main._floor_exit_portal != null and is_instance_valid(main._floor_exit_portal):
		main._floor_exit_portal._on_body_entered(main.player_manager.player)
	if main._status != "DUNGEON":
		failures.append("Main loop floor exit should not auto-complete on portal overlap.")
	if not main._floor_exit_portal_focused():
		failures.append("Main loop floor exit should focus when the player stands in the portal.")
	main._on_menu_confirm_requested()
	if main._status != "FLOOR_CLEARED":
		failures.append("Main loop portal confirm should move to floor-cleared state.")
	if main._run_floors_cleared != 1:
		failures.append("Main loop should tally cleared floors after portal confirm.")
	if not main.win_panel.visible:
		failures.append("Main loop floor clear should show the mission results panel after portal confirm.")
	if main.win_title_label == null or main.win_title_label.text != "MISSION RESULTS":
		failures.append("Main loop floor clear should present a mission results screen.")
	if main.win_score_label == null or not main.win_score_label.text.contains("Longest parry chain: 3"):
		failures.append("Main loop mission results should include the longest parry chain.")
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
	main.destructible_manager = main.get_node("Managers/DestructibleManager")
	main.audio_manager = main.get_node("Managers/AudioManager")
	main.arena_view = main.get_node("World/Arena")
	main.gameplay_camera = main.get_node("Camera2D")
	main.hud_background = main.get_node("UI/HUDBackground")
	main.hud_label = main.get_node("UI/HUDLabel")
	main.score_panel = main.get_node("UI/ScorePanel")
	main.score_label = main.get_node("UI/ScorePanel/ScoreLabel")
	main.dungeon_minimap = main.get_node("UI/DungeonMinimap")
	main.combat_panel = main.get_node("UI/CombatPanel")
	main.character_ui = main.get_node("UI/CharacterUi")
	main.health_bar_back = main.get_node("UI/CombatPanel/HealthBarBack")
	main.health_fill = main.get_node("UI/CombatPanel/HealthBarBack/HealthBarFill")
	main.health_tick_layer = main.get_node("UI/CombatPanel/HealthBarBack/HealthTickLayer")
	main.health_label = main.get_node("UI/CombatPanel/HealthLabel")
	main.invulnerability_bar_back = main.get_node("UI/CombatPanel/InvulnerabilityBarBack")
	main.invulnerability_fill = main.get_node("UI/CombatPanel/InvulnerabilityBarBack/InvulnerabilityBarFill")
	main.overdrive_label = main.get_node("UI/CombatPanel/OverdriveLabel")
	main.overdrive_bar_back = main.get_node("UI/CombatPanel/OverdriveBarBack")
	main.overdrive_fill = main.get_node("UI/CombatPanel/OverdriveBarBack/OverdriveBarFill")
	main.overdrive_tick_layer = main.get_node("UI/CombatPanel/OverdriveBarBack/OverdriveTickLayer")
	main.super_label = main.get_node("UI/CombatPanel/SuperLabel")
	main.super_bar_back = main.get_node("UI/CombatPanel/SuperBarBack")
	main.super_fill = main.get_node("UI/CombatPanel/SuperBarBack/SuperBarFill")
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
