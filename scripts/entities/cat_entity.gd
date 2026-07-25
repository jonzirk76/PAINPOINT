extends CharacterBody2D
class_name CatEntity

signal meowed(pitch_center: float, pitch_variation: float)

const DEFAULT_CAT_TEXTURE := preload("res://art/characters/white_0.png")
const FRAME_SIZE := Vector2i(32, 32)
const COLLISION_MASK_WALLS_AND_VOID := 96
# Direction row groups start facing south, then rotate 45 degrees clockwise every two rows.
const DIRECTION_ROW_START := 1
const DIRECTION_ROW_STRIDE := 2
const DIRECTION_COUNT := 8
const DIRECTION_STEP_RADIANS := PI / 4.0
const ANIMATION_FRAMES_PER_ROW := 4
const SIT_COLUMN_START := 0
const SIT_FRAME_COUNTS := [7, 6, 6, 6, 7, 6, 6, 6]
const LOOK_COLUMN_START := 4
const LOOK_FRAME_COUNT := 5
# Look clips move from one side, through forward head placement, to the other side.
const LOOK_NEUTRAL_FRAME_INDEX := 2
const LAY_COLUMN_START := 8
const LAY_FRAME_COUNT := 8
const WALK_COLUMN_START := 12
const WALK_FRAME_COUNT := 4
const RUN_COLUMN_START := 20
const RUN_FRAME_COUNT := 8
const STARTLE_JUMP_FRAME_COUNT := 4
const IDLE_STATE_STANDING := "standing"
const IDLE_STATE_SITTING := "sitting"
const IDLE_STATE_GLANCING := "glancing"
const IDLE_STATE_SCANNING := "scanning"
const IDLE_STATE_LAYING := "laying"
const MOTION_STATE_GROUNDED := "grounded"
const MOTION_STATE_JUMPING := "jumping"
const SIT_TRANSITION_NONE := "none"
const SIT_TRANSITION_DOWN := "down"
const SIT_TRANSITION_UP := "up"
const LAY_TRANSITION_NONE := "none"
const LAY_TRANSITION_DOWN := "down"
const LAY_TRANSITION_UP := "up"
const INVALID_PATH_CELL := Vector2i(-999999, -999999)

## Controls the cat's wall clearance and soft movement body size.
@export var body_radius: float = 11.0
## Controls normal wandering speed when the cat is away from combat.
@export var wander_speed: float = 78.0
## Controls burst speed while the cat is moving away from active combat.
@export var flee_speed: float = 142.0
## Controls how quickly the cat accelerates toward its current movement intent.
@export var acceleration: float = 520.0
## Controls how often fleeing cats recheck their wall-sliding escape route.
@export var flee_retarget_seconds: float = 0.18
## Controls how far the cat jumps when startled before it starts running.
@export var startle_jump_distance: float = 86.0
## Controls how long the startled jump takes.
@export var startle_jump_duration: float = 0.24
## Controls how high the startled jump visually lifts the sprite.
@export var startle_jump_arc_height: float = 24.0
## Controls how long the cat keeps running after a startled jump lands.
@export var startle_run_seconds: float = 0.55
## Controls how soon the same continuous danger can trigger another startled jump.
@export var startle_retrigger_cooldown: float = 0.9
## Controls how quickly rest animations reverse when the cat is startled.
@export var startle_get_up_animation_rate: float = 14.0
## Controls how far away enemies and spawners start influencing the cat.
@export var combat_avoidance_radius: float = 260.0
## Controls how far the cat tries to move when choosing a flee target.
@export var flee_target_distance: float = 220.0
## Controls how quickly curiosity rises while the player is nearby but not moving toward the cat.
@export var curiosity_build_rate: float = 0.075
## Controls how quickly curiosity falls while the player approaches or combat is nearby.
@export var curiosity_decay_rate: float = 0.22
## Controls how curious the cat must be before it starts preferring wander targets near the player.
@export var curiosity_target_bias_threshold: float = 0.28
## Controls the farthest player distance where curiosity can build.
@export var curiosity_awareness_radius: float = 560.0
## Controls how much wall clearance the cat needs for curiosity line-of-sight checks.
@export var curiosity_line_of_sight_margin: float = 6.0
## Controls how often curiosity refreshes line of sight while the cat and player are mostly steady.
@export var curiosity_line_of_sight_check_seconds: float = 0.22
## Controls how curious the cat must be before it starts meowing periodically.
@export var curiosity_meow_threshold: float = 0.68
## Controls the shortest delay between meows while the cat remains curious.
@export var min_curiosity_meow_seconds: float = 5.5
## Controls the longest delay between meows while the cat remains curious.
@export var max_curiosity_meow_seconds: float = 12.0
## Controls the lowest per-cat center pitch selected for meows.
@export var meow_pitch_center_min: float = 0.86
## Controls the highest per-cat center pitch selected for meows.
@export var meow_pitch_center_max: float = 1.18
## Controls how much each meow varies above or below this cat's center pitch.
@export var meow_pitch_variation: float = 0.06
## Controls the wander target radius when curiosity first starts influencing movement.
@export var curiosity_outer_target_radius: float = 300.0
## Controls the wander target radius when curiosity is full.
@export var curiosity_inner_target_radius: float = 135.0
## Controls the closest distance the cat tolerates before backing away from the player.
@export var player_personal_space_radius: float = 82.0
## Controls how fast the player must move toward the cat before curiosity decays.
@export var player_approach_speed_threshold: float = 55.0
## Controls how directly the player must move toward the cat before it counts as approaching.
@export var player_approach_dot_threshold: float = 0.55
## Controls how close player shots must pass before they reset the cat's curiosity.
@export var shot_curiosity_reset_radius: float = 210.0
## Controls the coarse grid size used when the cat needs a path around walls.
@export var path_grid_size: float = 48.0
## Controls the largest coarse path search before the cat falls back to direct movement.
@export var path_search_cell_limit: int = 6000
## Controls when larger cleared-floor roam bounds switch the cat to cheaper pathing.
@export var large_roam_area_threshold: float = 1400000.0
## Controls how much coarser pathfinding gets on larger cleared-floor roam bounds.
@export var large_roam_path_grid_multiplier: float = 1.75
## Controls the largest large-floor path search before falling back to direct movement.
@export var large_roam_path_search_cell_limit: int = 1400
## Controls how much longer wandering targets last on larger cleared-floor roam bounds.
@export var large_roam_wander_retarget_multiplier: float = 1.8
## Controls how close the cat gets to a path waypoint before advancing to the next one.
@export var path_waypoint_radius: float = 20.0
## Controls how often the cat chooses a fresh wander target.
@export var wander_retarget_seconds: float = 2.4
## Controls how likely the cat is to pause instead of immediately choosing another wander target.
@export var idle_chance: float = 0.28
## Controls the shortest random idle pause between wandering moves.
@export var min_idle_seconds: float = 1.45
## Controls the largest random idle pause between wandering moves.
@export var max_idle_seconds: float = 5.2
## Controls how often an idle cat remains in a standing rest pose.
@export var standing_idle_weight: float = 0.35
## Controls how often an idle cat uses the sit-down animation.
@export var sitting_idle_weight: float = 0.32
## Controls how often an idle cat repeats the seated look-around motion.
@export var glancing_idle_weight: float = 0.14
## Controls how often an idle cat scans in place through the look-around animation.
@export var scanning_idle_weight: float = 0.09
## Controls how often a seated idle cat chooses to lay down.
@export var laying_idle_weight: float = 0.10
## Controls the shortest time for one seated head movement frame step.
@export var min_look_step_seconds: float = 0.10
## Controls the longest time for one seated head movement frame step.
@export var max_look_step_seconds: float = 0.32
## Controls the shortest pause after seated head movement reaches a look target.
@export var min_look_pause_seconds: float = 0.35
## Controls the longest pause after seated head movement reaches a look target.
@export var max_look_pause_seconds: float = 1.15
## Controls the visual sprite scale applied to 32x32 sheet frames.
@export var sprite_scale: float = 1.45

var enabled: bool = false
var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var arena_shape: int = 0
var wall_rects: Array[Rect2] = []
var void_rects: Array[Rect2] = []
var playable_rects: Array[Rect2] = []
var _blocker_rects: Array[Rect2] = []

var _sprite: Sprite2D = null
var _cat_texture: Texture2D = DEFAULT_CAT_TEXTURE
var _rng := RandomNumberGenerator.new()
var _target_position: Vector2 = Vector2.INF
var _path_points: Array[Vector2] = []
var _danger_points: Array[Dictionary] = []
var _roam_bounds: Rect2 = Rect2()
var _has_roam_bounds: bool = false
var _retarget_remaining: float = 0.0
var _flee_retarget_remaining: float = 0.0
var _idle_remaining: float = 0.0
var _animation_time: float = 0.0
var _last_facing_direction: Vector2 = Vector2.DOWN
var _is_fleeing: bool = false
var _curiosity: float = 0.0
var _player_position: Vector2 = Vector2.INF
var _player_velocity: Vector2 = Vector2.ZERO
var _player_avoidance_radius: float = 150.0
var _has_player_context: bool = false
var _player_projectile_points: Array[Vector2] = []
var _curiosity_line_of_sight_remaining: float = 0.0
var _curiosity_line_of_sight_visible: bool = false
var _curiosity_line_of_sight_cat_position: Vector2 = Vector2.INF
var _curiosity_line_of_sight_player_position: Vector2 = Vector2.INF
var _curiosity_meow_remaining: float = 0.0
var _meow_pitch_center: float = 1.0
var _motion_state: String = MOTION_STATE_GROUNDED
var _movement_state_label: String = "idle"
var _idle_state: String = IDLE_STATE_STANDING
var _idle_direction_index: int = 0
var _look_frame_index: int = LOOK_NEUTRAL_FRAME_INDEX
var _look_target_frame_index: int = LOOK_NEUTRAL_FRAME_INDEX
var _look_pause_remaining: float = 0.0
var _look_step_remaining: float = 0.0
var _look_exit_state: String = ""
var _pending_seated_idle_state: String = ""
var _stand_after_lay_up: bool = false
var _sit_transition_mode: String = SIT_TRANSITION_NONE
var _lay_transition_mode: String = LAY_TRANSITION_NONE
var _startle_source_was_active: bool = false
var _startle_jump_queued: bool = false
var _startle_jump_elapsed: float = 0.0
var _startle_jump_start_position: Vector2 = Vector2.ZERO
var _startle_jump_land_position: Vector2 = Vector2.ZERO
var _startle_jump_direction: Vector2 = Vector2.DOWN
var _startle_jump_cooldown_remaining: float = 0.0
var _startle_run_remaining: float = 0.0
var _collision_shape: CollisionShape2D = null
var _collision_add_deferred: bool = false


func _ready() -> void:
	_configure_collision_identity()
	_add_collision()
	_ensure_sprite()
	_pick_next_wander_target()
	queue_redraw()


func initialize(spawn_position: Vector2, movement_seed: int = 0) -> void:
	_rng.seed = max(movement_seed, 1)
	global_position = spawn_position
	_target_position = spawn_position
	_path_points.clear()
	_retarget_remaining = 0.0
	_flee_retarget_remaining = 0.0
	_idle_remaining = 0.0
	_animation_time = 0.0
	_last_facing_direction = Vector2.DOWN
	_is_fleeing = false
	_curiosity = 0.0
	_player_position = Vector2.INF
	_player_velocity = Vector2.ZERO
	_has_player_context = false
	_player_projectile_points.clear()
	_reset_curiosity_line_of_sight_cache()
	_meow_pitch_center = _pick_meow_pitch_center()
	_reset_curiosity_meow_timer()
	_motion_state = MOTION_STATE_GROUNDED
	_movement_state_label = "idle"
	_idle_direction_index = _get_direction_index(_last_facing_direction)
	_reset_look_motion()
	_pending_seated_idle_state = ""
	_stand_after_lay_up = false
	_sit_transition_mode = SIT_TRANSITION_NONE
	_lay_transition_mode = LAY_TRANSITION_NONE
	_startle_source_was_active = false
	_startle_jump_queued = false
	_startle_jump_elapsed = 0.0
	_startle_jump_start_position = spawn_position
	_startle_jump_land_position = spawn_position
	_startle_jump_direction = Vector2.DOWN
	_startle_jump_cooldown_remaining = 0.0
	_startle_run_remaining = 0.0
	_set_idle_state(IDLE_STATE_STANDING)
	_configure_collision_identity()
	_ensure_sprite()
	_update_sprite_frame()
	queue_redraw()


func set_enabled(value: bool) -> void:
	enabled = value
	set_physics_process(value)
	if not enabled:
		velocity = Vector2.ZERO
		_is_fleeing = false
		_movement_state_label = "sleeping"


func set_cat_texture(texture: Texture2D) -> void:
	if texture == null:
		return
	_cat_texture = texture
	_ensure_sprite()
	_sprite.texture = _cat_texture


func set_player_context(player_position: Vector2, player_velocity: Vector2, avoidance_radius: float) -> void:
	if player_position == Vector2.INF:
		_has_player_context = false
		_player_position = Vector2.INF
		_player_velocity = Vector2.ZERO
		_reset_curiosity_line_of_sight_cache()
		return
	_has_player_context = true
	_player_position = player_position
	_player_velocity = player_velocity
	_player_avoidance_radius = maxf(avoidance_radius, player_personal_space_radius + 1.0)


func set_player_projectile_points(points: Array) -> void:
	_player_projectile_points.clear()
	for point in points:
		if point is Vector2:
			_player_projectile_points.append(point)


func get_curiosity() -> float:
	return _curiosity


func get_state_snapshot() -> Dictionary:
	var target_distance: float = -1.0
	if _target_position != Vector2.INF:
		target_distance = global_position.distance_to(_target_position)
	return {
		"motion_state": _motion_state,
		"movement_state": _movement_state_label,
		"idle_state": _idle_state,
		"sit_transition": _sit_transition_mode,
		"lay_transition": _lay_transition_mode,
		"look_exit": _look_exit_state,
		"jump_queued": _startle_jump_queued,
		"is_fleeing": _is_fleeing,
		"curiosity": _curiosity,
		"meow_pitch_center": _meow_pitch_center,
		"meow_cooldown": _curiosity_meow_remaining,
		"speed": velocity.length(),
		"target_distance": target_distance,
		"path_points": _path_points.size(),
		"position": global_position
	}


func set_arena_definition(bounds: Rect2, shape: int, walls: Array = [], voids: Array = [], playable_regions: Array = []) -> void:
	arena_bounds = bounds
	arena_shape = shape
	wall_rects.clear()
	for wall in walls:
		if wall is Rect2:
			wall_rects.append(wall)
	void_rects.clear()
	for void_rect in voids:
		if void_rect is Rect2:
			void_rects.append(void_rect)
	playable_rects.clear()
	for playable_rect in playable_regions:
		if playable_rect is Rect2:
			playable_rects.append(playable_rect)
	_rebuild_blocker_rects()
	global_position = _constrain_to_playable_if_needed(global_position)
	if _target_position != Vector2.INF:
		_set_target_position(_constrain_to_playable_if_needed(_target_position))


func set_roam_bounds(bounds: Rect2) -> void:
	_roam_bounds = bounds
	_has_roam_bounds = bounds.size.x > 0.0 and bounds.size.y > 0.0
	if _target_position != Vector2.INF and not _position_inside_roam_bounds(_target_position):
		_pick_next_wander_target()


func set_danger_points(points: Array) -> void:
	_danger_points.clear()
	for point in points:
		if point is Dictionary and point.has("position"):
			_danger_points.append(Dictionary(point))


func _set_target_position(new_target_position: Vector2, rebuild_path: bool = true) -> void:
	_target_position = new_target_position
	_path_points.clear()
	if rebuild_path and new_target_position != Vector2.INF:
		_path_points = _build_path_to(new_target_position)


func _get_current_movement_target() -> Vector2:
	if _target_position == Vector2.INF:
		return Vector2.INF
	_discard_reached_path_points()
	if not _path_points.is_empty():
		return _path_points[0]
	return _target_position


func _discard_reached_path_points() -> void:
	var reach_radius: float = maxf(path_waypoint_radius, body_radius + 2.0)
	var reach_distance_squared: float = reach_radius * reach_radius
	while not _path_points.is_empty() and global_position.distance_squared_to(_path_points[0]) <= reach_distance_squared:
		_path_points.pop_front()


func _physics_process(delta: float) -> void:
	if not enabled:
		velocity = Vector2.ZERO
		_movement_state_label = "disabled"
		return
	_startle_jump_cooldown_remaining = maxf(_startle_jump_cooldown_remaining - delta, 0.0)
	_startle_run_remaining = maxf(_startle_run_remaining - delta, 0.0)
	var combat_avoidance: Vector2 = _get_combat_avoidance_vector()
	var player_avoidance: Vector2 = _get_player_avoidance_vector()
	var projectile_startle: Vector2 = _get_player_projectile_startle_vector()
	var startle_avoidance: Vector2 = combat_avoidance + projectile_startle
	var avoidance: Vector2 = startle_avoidance + player_avoidance
	var startle_source_active: bool = startle_avoidance.length_squared() > 0.001
	if startle_source_active and not _startle_source_was_active:
		_request_startle_jump(startle_avoidance)
	_startle_source_was_active = startle_source_active
	_update_curiosity(delta, combat_avoidance.length_squared() > 0.001)
	var desired_velocity := Vector2.ZERO
	_is_fleeing = startle_avoidance.length_squared() > 0.001 or _startle_jump_queued or _startle_run_remaining > 0.0 or _is_jumping()
	_update_curiosity_meow(delta)
	if _is_jumping():
		_movement_state_label = "jumping"
		velocity = Vector2.ZERO
		_update_startle_jump(delta)
		global_position = _constrain_to_playable_if_needed(global_position)
		_update_visual_state(delta)
		return
	if _is_fleeing:
		_idle_remaining = 0.0
		var flee_vector: Vector2 = avoidance
		if flee_vector.length_squared() <= 0.001:
			flee_vector = _startle_jump_direction
		_set_idle_state(IDLE_STATE_STANDING)
		_movement_state_label = _get_startled_movement_label(startle_avoidance)
		if _startle_jump_queued and not _has_rest_transition():
			var jump_direction: Vector2 = _get_slippery_escape_direction(flee_vector, startle_jump_distance)
			_begin_startle_jump(jump_direction)
		if _is_jumping():
			_movement_state_label = "jumping"
			velocity = Vector2.ZERO
			_update_startle_jump(delta)
			global_position = _constrain_to_playable_if_needed(global_position)
			_update_visual_state(delta)
			return
		if not _has_get_up_transition():
			_flee_retarget_remaining = maxf(_flee_retarget_remaining - delta, 0.0)
			if _should_refresh_flee_target():
				var escape_direction: Vector2 = _get_slippery_escape_direction(flee_vector, flee_target_distance)
				_set_target_position(_find_escape_target(escape_direction, flee_target_distance), false)
				_flee_retarget_remaining = maxf(flee_retarget_seconds, 0.05)
			var flee_target: Vector2 = _get_current_movement_target()
			if flee_target != Vector2.INF:
				desired_velocity = (flee_target - global_position).normalized() * flee_speed
	elif player_avoidance.length_squared() > 0.001:
		_movement_state_label = "personal_space"
		_idle_remaining = 0.0
		_set_idle_state(IDLE_STATE_STANDING)
		if not _has_get_up_transition():
			_flee_retarget_remaining = maxf(_flee_retarget_remaining - delta, 0.0)
			if _should_refresh_flee_target():
				var personal_space_direction: Vector2 = _get_slippery_escape_direction(player_avoidance, player_personal_space_radius)
				_set_target_position(_find_escape_target(personal_space_direction, maxf(player_personal_space_radius, body_radius + 8.0)), false)
				_flee_retarget_remaining = maxf(flee_retarget_seconds, 0.05)
			var personal_space_target: Vector2 = _get_current_movement_target()
			if personal_space_target != Vector2.INF:
				desired_velocity = (personal_space_target - global_position).normalized() * wander_speed
	else:
		_flee_retarget_remaining = 0.0
		_update_wander_target(delta)
		if desired_velocity.length_squared() <= 0.001 and _idle_remaining <= 0.0 and _target_position != Vector2.INF:
			var movement_target: Vector2 = _get_current_movement_target()
			if movement_target != Vector2.INF:
				var to_target: Vector2 = movement_target - global_position
				if to_target.length_squared() > 16.0 * 16.0:
					desired_velocity = to_target.normalized() * wander_speed
		_movement_state_label = "wander" if desired_velocity.length_squared() > 0.001 else "idle"
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	move_and_slide()
	if get_slide_collision_count() > 0:
		if avoidance.length_squared() <= 0.001:
			_pick_next_wander_target()
		elif _is_fleeing:
			_flee_retarget_remaining = 0.0
	global_position = _constrain_to_playable_if_needed(global_position)
	_update_visual_state(delta)


func _draw() -> void:
	draw_set_transform(Vector2(0.0, body_radius * 0.82), 0.0, Vector2(body_radius * 1.15, body_radius * 0.34))
	draw_circle(Vector2.ZERO, 1.0, Color(0.0, 0.0, 0.0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _configure_collision_identity() -> void:
	_set_body_collision_property("collision_layer", 0)
	_set_body_collision_property("collision_mask", COLLISION_MASK_WALLS_AND_VOID)


func _add_collision() -> void:
	if _collision_shape != null or get_node_or_null("CollisionShape2D") != null:
		_collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
		return
	if is_inside_tree() and Engine.is_in_physics_frame():
		if not _collision_add_deferred:
			_collision_add_deferred = true
			call_deferred("_add_collision")
		return
	_collision_add_deferred = false
	var shape := CircleShape2D.new()
	shape.radius = body_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)
	_collision_shape = collision_shape


func _set_body_collision_property(property_name: StringName, value: Variant) -> void:
	if is_inside_tree() and Engine.is_in_physics_frame():
		set_deferred(property_name, value)
		return
	set(property_name, value)


func _ensure_sprite() -> void:
	if _sprite != null and is_instance_valid(_sprite):
		return
	_sprite = Sprite2D.new()
	_sprite.name = "CatSprite"
	_sprite.texture = _cat_texture
	_sprite.region_enabled = true
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(sprite_scale, sprite_scale)
	_sprite.position = _get_sprite_base_position()
	add_child(_sprite)


func _update_wander_target(delta: float) -> void:
	if _has_get_up_transition():
		return
	if _idle_remaining > 0.0:
		_idle_remaining = maxf(_idle_remaining - delta, 0.0)
		if _idle_remaining <= 0.0:
			_set_idle_state(IDLE_STATE_STANDING)
		return
	_retarget_remaining = maxf(_retarget_remaining - delta, 0.0)
	var target_reached := _target_position == Vector2.INF or global_position.distance_squared_to(_target_position) <= 18.0 * 18.0
	if target_reached or _retarget_remaining <= 0.0:
		if _rng.randf() < clamp(idle_chance, 0.0, 1.0):
			_begin_idle_pause()
			return
		_pick_next_wander_target()


func _pick_next_wander_target() -> void:
	_set_idle_state(IDLE_STATE_STANDING)
	var picked_position: Vector2 = _pick_curiosity_biased_position()
	if picked_position == Vector2.INF:
		picked_position = _pick_clear_random_position()
	_set_target_position(picked_position)
	var retarget_seconds: float = wander_retarget_seconds
	if _uses_large_roam_cost_controls():
		retarget_seconds *= maxf(large_roam_wander_retarget_multiplier, 1.0)
	_retarget_remaining = maxf(retarget_seconds * _rng.randf_range(0.65, 1.35), 0.2)


func _begin_idle_pause() -> void:
	var idle_min: float = maxf(min_idle_seconds, 0.1)
	var idle_max: float = maxf(max_idle_seconds, idle_min + 0.1)
	_idle_remaining = _rng.randf_range(idle_min, idle_max)
	_retarget_remaining = 0.0
	_set_target_position(global_position, false)
	velocity = Vector2.ZERO
	_set_idle_state(_choose_idle_state())


func _choose_idle_state() -> String:
	var weights: Array[float] = [
		maxf(standing_idle_weight, 0.0),
		maxf(sitting_idle_weight, 0.0),
		maxf(glancing_idle_weight, 0.0),
		maxf(scanning_idle_weight, 0.0),
		maxf(laying_idle_weight, 0.0)
	]
	var states: Array[String] = [
		IDLE_STATE_STANDING,
		IDLE_STATE_SITTING,
		IDLE_STATE_GLANCING,
		IDLE_STATE_SCANNING,
		IDLE_STATE_LAYING
	]
	var total_weight: float = 0.0
	for weight: float in weights:
		total_weight += weight
	if total_weight <= 0.0:
		return IDLE_STATE_STANDING
	var roll: float = _rng.randf_range(0.0, total_weight)
	for index: int in range(weights.size()):
		if roll < weights[index]:
			return states[index]
		roll -= weights[index]
	return IDLE_STATE_LAYING


func _set_idle_state(state: String, force: bool = false) -> void:
	if _idle_state == state and not _has_rest_transition() and _pending_seated_idle_state.is_empty() and _look_exit_state.is_empty():
		return
	if state == IDLE_STATE_STANDING:
		_pending_seated_idle_state = ""
	if state == IDLE_STATE_STANDING and _is_look_idle_state() and not force:
		_begin_look_exit(IDLE_STATE_STANDING)
		return
	if state == IDLE_STATE_LAYING and _is_look_idle_state() and not force:
		_begin_look_exit(IDLE_STATE_LAYING)
		return
	if state == IDLE_STATE_STANDING and _is_seated_idle_state() and not force:
		if _sit_transition_mode != SIT_TRANSITION_UP:
			_sit_transition_mode = SIT_TRANSITION_UP
			_animation_time = 0.0
			_reset_look_motion()
		return
	if state == IDLE_STATE_STANDING and _idle_state == IDLE_STATE_LAYING and not force:
		if _lay_transition_mode != LAY_TRANSITION_UP:
			_lay_transition_mode = LAY_TRANSITION_UP
			_animation_time = 0.0
		_stand_after_lay_up = true
		return
	if state == IDLE_STATE_LAYING and not force and not _is_seated_idle_state() and _idle_state != IDLE_STATE_LAYING:
		_pending_seated_idle_state = IDLE_STATE_LAYING
		_idle_state = IDLE_STATE_SITTING
		_animation_time = 0.0
		_idle_direction_index = _get_direction_index(_last_facing_direction)
		_reset_look_motion()
		_lay_transition_mode = LAY_TRANSITION_NONE
		_sit_transition_mode = SIT_TRANSITION_DOWN
		return
	if state == IDLE_STATE_LAYING and not force and _is_seated_idle_state():
		_pending_seated_idle_state = ""
		_idle_state = IDLE_STATE_LAYING
		_animation_time = 0.0
		_reset_look_motion()
		_lay_transition_mode = LAY_TRANSITION_DOWN
		_sit_transition_mode = SIT_TRANSITION_NONE
		return
	_idle_state = state
	_animation_time = 0.0
	_idle_direction_index = _get_direction_index(_last_facing_direction)
	_reset_look_motion()
	_pending_seated_idle_state = ""
	_stand_after_lay_up = false
	_sit_transition_mode = SIT_TRANSITION_DOWN if _is_seated_idle_state() else SIT_TRANSITION_NONE
	_lay_transition_mode = LAY_TRANSITION_DOWN if _idle_state == IDLE_STATE_LAYING else LAY_TRANSITION_NONE
	if _is_look_idle_state() and _sit_transition_mode == SIT_TRANSITION_NONE:
		_configure_look_idle()


func _is_look_idle_state() -> bool:
	return _idle_state == IDLE_STATE_GLANCING or _idle_state == IDLE_STATE_SCANNING


func _is_seated_idle_state() -> bool:
	return _idle_state == IDLE_STATE_SITTING or _is_look_idle_state()


func _has_rest_transition() -> bool:
	return _sit_transition_mode != SIT_TRANSITION_NONE or _lay_transition_mode != LAY_TRANSITION_NONE


func _has_get_up_transition() -> bool:
	return _sit_transition_mode == SIT_TRANSITION_UP or _lay_transition_mode == LAY_TRANSITION_UP or not _look_exit_state.is_empty() or _startle_jump_queued or _is_jumping()


func _is_jumping() -> bool:
	return _motion_state == MOTION_STATE_JUMPING


func _get_startled_movement_label(startle_avoidance: Vector2) -> String:
	if _startle_jump_queued:
		return "startle_get_up"
	if _startle_run_remaining > 0.0:
		return "startle_run"
	if startle_avoidance.length_squared() > 0.001:
		return "combat_flee"
	return "flee"


func _should_refresh_flee_target() -> bool:
	if _flee_retarget_remaining <= 0.0:
		return true
	if _target_position == Vector2.INF:
		return true
	var current_target: Vector2 = _get_current_movement_target()
	if current_target == Vector2.INF:
		return true
	return global_position.distance_squared_to(current_target) <= 18.0 * 18.0


func _request_startle_jump(startle_vector: Vector2) -> void:
	if _is_jumping() or _startle_jump_queued or _startle_jump_cooldown_remaining > 0.0:
		return
	if startle_vector.length_squared() <= 0.001:
		return
	_startle_jump_direction = _get_slippery_escape_direction(startle_vector, startle_jump_distance)
	_startle_jump_queued = true
	_idle_remaining = 0.0
	_retarget_remaining = 0.0
	_set_target_position(global_position, false)


func _begin_startle_jump(flee_vector: Vector2) -> void:
	if flee_vector.length_squared() > 0.001:
		_startle_jump_direction = _get_slippery_escape_direction(flee_vector, startle_jump_distance)
	elif _startle_jump_direction.length_squared() <= 0.001:
		_startle_jump_direction = Vector2.DOWN
	_startle_jump_queued = false
	_motion_state = MOTION_STATE_JUMPING
	_idle_state = IDLE_STATE_STANDING
	_sit_transition_mode = SIT_TRANSITION_NONE
	_lay_transition_mode = LAY_TRANSITION_NONE
	_reset_look_motion()
	_animation_time = 0.0
	velocity = Vector2.ZERO
	_startle_jump_elapsed = 0.0
	_startle_jump_start_position = global_position
	_startle_jump_land_position = _find_startle_jump_landing(_startle_jump_direction)
	_last_facing_direction = _startle_jump_direction
	if _startle_jump_start_position.distance_squared_to(_startle_jump_land_position) <= 4.0:
		_finish_startle_jump()


func _update_startle_jump(delta: float) -> void:
	var jump_duration: float = maxf(startle_jump_duration, 0.05)
	_startle_jump_elapsed = minf(_startle_jump_elapsed + delta, jump_duration)
	var jump_progress: float = clampf(_startle_jump_elapsed / jump_duration, 0.0, 1.0)
	global_position = _startle_jump_start_position.lerp(_startle_jump_land_position, jump_progress)
	if jump_progress >= 1.0:
		_finish_startle_jump()


func _finish_startle_jump() -> void:
	global_position = _constrain_to_playable_if_needed(_startle_jump_land_position)
	_motion_state = MOTION_STATE_GROUNDED
	_startle_jump_elapsed = 0.0
	_startle_jump_cooldown_remaining = maxf(startle_retrigger_cooldown, 0.0)
	_startle_run_remaining = maxf(startle_run_seconds, 0.0)
	_last_facing_direction = _startle_jump_direction
	_set_target_position(_find_escape_target(_startle_jump_direction, flee_target_distance), false)
	velocity = _startle_jump_direction * flee_speed


func _find_startle_jump_landing(jump_direction: Vector2) -> Vector2:
	var direction: Vector2 = jump_direction.normalized() if jump_direction.length_squared() > 0.001 else Vector2.DOWN
	var jump_distance: float = maxf(startle_jump_distance, body_radius + 4.0)
	var distance_ratios: Array[float] = [1.0, 0.75, 0.5, 0.3]
	for ratio: float in distance_ratios:
		var candidate: Vector2 = _get_direct_escape_target(direction, jump_distance * ratio)
		if candidate != Vector2.INF:
			return candidate
	return global_position


func _get_slippery_escape_direction(preferred_vector: Vector2, probe_distance: float) -> Vector2:
	var preferred_direction: Vector2 = _get_valid_escape_direction(preferred_vector)
	var best_direction: Vector2 = preferred_direction
	var best_distance: float = _get_escape_clear_distance(preferred_direction, probe_distance)
	if best_distance >= probe_distance * 0.9:
		return preferred_direction
	var side_sign: float = 1.0 if preferred_direction.cross(_last_facing_direction) >= 0.0 else -1.0
	var candidate_angles: Array[float] = [
		side_sign * PI * 0.5,
		-side_sign * PI * 0.5,
		side_sign * PI * 0.25,
		-side_sign * PI * 0.25,
		side_sign * PI * 0.75,
		-side_sign * PI * 0.75,
		PI
	]
	for angle: float in candidate_angles:
		var candidate_direction: Vector2 = preferred_direction.rotated(angle).normalized()
		var clear_distance: float = _get_escape_clear_distance(candidate_direction, probe_distance)
		if clear_distance > best_distance + 1.0:
			best_direction = candidate_direction
			best_distance = clear_distance
		if best_distance >= probe_distance * 0.9:
			return best_direction
	return best_direction


func _get_valid_escape_direction(vector: Vector2) -> Vector2:
	if vector.length_squared() > 0.001:
		return vector.normalized()
	if _startle_jump_direction.length_squared() > 0.001:
		return _startle_jump_direction.normalized()
	if _last_facing_direction.length_squared() > 0.001:
		return _last_facing_direction.normalized()
	return Vector2.DOWN


func _get_escape_clear_distance(direction: Vector2, max_distance: float) -> float:
	var distance: float = maxf(max_distance, body_radius + 4.0)
	var distance_ratios: Array[float] = [1.0, 0.75, 0.5, 0.3]
	for ratio: float in distance_ratios:
		var target: Vector2 = _get_direct_escape_target(direction, distance * ratio)
		if target != Vector2.INF:
			return global_position.distance_to(target)
	return 0.0


func _find_escape_target(direction: Vector2, distance: float) -> Vector2:
	var escape_distance: float = maxf(distance, body_radius + 4.0)
	var distance_ratios: Array[float] = [1.0, 0.75, 0.5, 0.3]
	for ratio: float in distance_ratios:
		var target: Vector2 = _get_direct_escape_target(direction, escape_distance * ratio)
		if target != Vector2.INF:
			return target
	return global_position


func _get_direct_escape_target(direction: Vector2, distance: float) -> Vector2:
	if direction.length_squared() <= 0.001:
		return Vector2.INF
	var target: Vector2 = _clamp_to_roam_bounds(global_position + direction.normalized() * maxf(distance, body_radius + 4.0))
	if target.distance_squared_to(global_position) <= maxf(body_radius * 0.5, 4.0) * maxf(body_radius * 0.5, 4.0):
		return Vector2.INF
	if not _position_is_clear(target):
		return Vector2.INF
	if not _has_clear_segment(global_position, target, body_radius * 0.5):
		return Vector2.INF
	return target


func _reset_look_motion() -> void:
	_look_frame_index = _get_neutral_look_frame_index()
	_look_target_frame_index = _look_frame_index
	_look_pause_remaining = 0.0
	_look_step_remaining = 0.0
	_look_exit_state = ""


func _configure_look_idle() -> void:
	_look_exit_state = ""
	_look_frame_index = _get_neutral_look_frame_index()
	_look_pause_remaining = _get_next_look_pause_seconds()
	_set_next_look_target()


func _begin_look_exit(next_state: String) -> void:
	if not _is_look_idle_state() or _has_rest_transition():
		return
	if _look_exit_state == next_state:
		return
	_look_exit_state = next_state
	_look_target_frame_index = _get_neutral_look_frame_index()
	_look_pause_remaining = 0.0
	_look_step_remaining = 0.0
	if _look_frame_index == _look_target_frame_index:
		_finish_look_exit()


func _finish_look_exit() -> void:
	var exit_state: String = _look_exit_state
	_reset_look_motion()
	_pending_seated_idle_state = ""
	if exit_state == IDLE_STATE_LAYING:
		_idle_state = IDLE_STATE_LAYING
		_animation_time = 0.0
		_lay_transition_mode = LAY_TRANSITION_DOWN
		_sit_transition_mode = SIT_TRANSITION_NONE
	elif exit_state == IDLE_STATE_STANDING:
		_animation_time = 0.0
		_sit_transition_mode = SIT_TRANSITION_UP
		_lay_transition_mode = LAY_TRANSITION_NONE


func _set_next_look_target() -> void:
	_look_target_frame_index = _pick_next_look_target_frame()
	_look_step_remaining = _get_next_look_step_seconds()


func _pick_next_look_target_frame() -> int:
	var candidates: Array[int] = []
	if _idle_state == IDLE_STATE_GLANCING:
		candidates.append(LOOK_NEUTRAL_FRAME_INDEX - 1)
		candidates.append(LOOK_NEUTRAL_FRAME_INDEX + 1)
		if _rng.randf() < 0.35:
			candidates.append(LOOK_NEUTRAL_FRAME_INDEX)
	else:
		candidates.append(0)
		candidates.append(1)
		candidates.append(3)
		candidates.append(4)
		if _rng.randf() < 0.25:
			candidates.append(LOOK_NEUTRAL_FRAME_INDEX)
	var bounded_candidates: Array[int] = []
	for candidate: int in candidates:
		var bounded_candidate: int = clampi(candidate, 0, LOOK_FRAME_COUNT - 1)
		if bounded_candidate == _look_frame_index:
			continue
		if not bounded_candidates.has(bounded_candidate):
			bounded_candidates.append(bounded_candidate)
	if bounded_candidates.is_empty():
		return _get_neutral_look_frame_index()
	return bounded_candidates[_rng.randi_range(0, bounded_candidates.size() - 1)]


func _get_next_look_step_seconds() -> float:
	var step_min: float = maxf(min_look_step_seconds, 0.03)
	var step_max: float = maxf(max_look_step_seconds, step_min)
	return _rng.randf_range(step_min, step_max)


func _get_next_look_pause_seconds() -> float:
	var pause_min: float = maxf(min_look_pause_seconds, 0.05)
	var pause_max: float = maxf(max_look_pause_seconds, pause_min + 0.05)
	var pause_seconds: float = _rng.randf_range(pause_min, pause_max)
	if _idle_state == IDLE_STATE_SCANNING:
		return pause_seconds * _rng.randf_range(0.55, 0.95)
	return pause_seconds


func _update_look_idle(delta: float) -> void:
	if not _is_look_idle_state():
		return
	if not _look_exit_state.is_empty():
		_look_target_frame_index = _get_neutral_look_frame_index()
	if _look_pause_remaining > 0.0:
		_look_pause_remaining = maxf(_look_pause_remaining - delta, 0.0)
		if _look_pause_remaining > 0.0:
			return
	if _look_frame_index == _look_target_frame_index:
		if not _look_exit_state.is_empty():
			_finish_look_exit()
			return
		_set_next_look_target()
	if _look_frame_index == _look_target_frame_index:
		_look_pause_remaining = _get_next_look_pause_seconds()
		return
	_look_step_remaining -= delta
	while _look_step_remaining <= 0.0 and _look_frame_index != _look_target_frame_index:
		var frame_step: int = 1 if _look_target_frame_index > _look_frame_index else -1
		_look_frame_index = clampi(_look_frame_index + frame_step, 0, LOOK_FRAME_COUNT - 1)
		if _look_frame_index != _look_target_frame_index:
			_look_step_remaining += _get_next_look_step_seconds()
	if _look_frame_index == _look_target_frame_index:
		if not _look_exit_state.is_empty():
			_finish_look_exit()
		else:
			_look_pause_remaining = _get_next_look_pause_seconds()


func _update_sit_transition() -> void:
	var sit_frame_count: int = _get_sit_frame_count(_idle_direction_index)
	if int(floor(_animation_time)) < sit_frame_count:
		return
	if _sit_transition_mode == SIT_TRANSITION_DOWN:
		_sit_transition_mode = SIT_TRANSITION_NONE
		_animation_time = 0.0
		if _pending_seated_idle_state == IDLE_STATE_LAYING:
			_pending_seated_idle_state = ""
			_set_idle_state(IDLE_STATE_LAYING)
			return
		if _is_look_idle_state():
			_configure_look_idle()
	elif _sit_transition_mode == SIT_TRANSITION_UP:
		_sit_transition_mode = SIT_TRANSITION_NONE
		_idle_state = IDLE_STATE_STANDING
		_animation_time = 0.0
		_last_facing_direction = _get_direction_vector(_idle_direction_index)


func _update_lay_transition() -> void:
	if int(floor(_animation_time)) < LAY_FRAME_COUNT:
		return
	if _lay_transition_mode == LAY_TRANSITION_DOWN:
		_lay_transition_mode = LAY_TRANSITION_NONE
		_animation_time = 0.0
	elif _lay_transition_mode == LAY_TRANSITION_UP:
		_lay_transition_mode = LAY_TRANSITION_NONE
		_idle_state = IDLE_STATE_SITTING
		_animation_time = 0.0
		_last_facing_direction = _get_direction_vector(_idle_direction_index)
		if _stand_after_lay_up:
			_stand_after_lay_up = false
			_set_idle_state(IDLE_STATE_STANDING)


func _get_combat_avoidance_vector() -> Vector2:
	var avoidance := Vector2.ZERO
	for point_info in _danger_points:
		var point_kind: String = String(point_info.get("kind", "combat"))
		if point_kind == "player":
			continue
		var danger_position: Vector2 = point_info.get("position", Vector2.INF)
		if danger_position == Vector2.INF:
			continue
		var radius: float = maxf(float(point_info.get("radius", combat_avoidance_radius)), body_radius + 1.0)
		var to_cat: Vector2 = global_position - danger_position
		var distance: float = to_cat.length()
		if distance > radius:
			continue
		if distance <= 0.001:
			to_cat = Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
			distance = 1.0
		var weight: float = maxf(float(point_info.get("weight", 1.0)), 0.0)
		var ratio: float = clamp(1.0 - distance / radius, 0.0, 1.0)
		avoidance += to_cat.normalized() * ratio * ratio * weight
	return avoidance


func _get_player_avoidance_vector() -> Vector2:
	if not _has_player_context:
		return Vector2.ZERO
	var to_cat: Vector2 = global_position - _player_position
	var distance: float = to_cat.length()
	if distance <= 0.001:
		to_cat = Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
		distance = 1.0
	var active_radius: float = player_personal_space_radius
	if _is_player_moving_toward_cat():
		active_radius = maxf(_player_avoidance_radius, player_personal_space_radius)
	if distance > active_radius:
		return Vector2.ZERO
	var ratio: float = clampf(1.0 - distance / active_radius, 0.0, 1.0)
	return to_cat.normalized() * ratio * ratio * 0.82


func _update_curiosity(delta: float, combat_near: bool) -> void:
	var was_meow_curious: bool = _curiosity >= clampf(curiosity_meow_threshold, 0.0, 1.0)
	if _has_nearby_player_projectile():
		_curiosity = 0.0
		_reset_curiosity_meow_timer()
		return
	if _can_build_curiosity(combat_near, delta):
		_curiosity = minf(1.0, _curiosity + maxf(curiosity_build_rate, 0.0) * delta)
	else:
		_curiosity = maxf(0.0, _curiosity - maxf(curiosity_decay_rate, 0.0) * delta)
	if was_meow_curious and _curiosity < clampf(curiosity_meow_threshold, 0.0, 1.0):
		_reset_curiosity_meow_timer()


func _update_curiosity_meow(delta: float) -> void:
	if _is_fleeing or _curiosity < clampf(curiosity_meow_threshold, 0.0, 1.0):
		return
	if not _can_build_curiosity(false, 0.0, false):
		return
	_curiosity_meow_remaining = maxf(_curiosity_meow_remaining - delta, 0.0)
	if _curiosity_meow_remaining > 0.0:
		return
	meowed.emit(_meow_pitch_center, maxf(meow_pitch_variation, 0.0))
	_reset_curiosity_meow_timer()


func _pick_meow_pitch_center() -> float:
	var pitch_min: float = maxf(minf(meow_pitch_center_min, meow_pitch_center_max), 0.05)
	var pitch_max: float = maxf(maxf(meow_pitch_center_min, meow_pitch_center_max), pitch_min)
	return _rng.randf_range(pitch_min, pitch_max)


func _reset_curiosity_meow_timer() -> void:
	var min_seconds: float = maxf(min_curiosity_meow_seconds, 0.1)
	var max_seconds: float = maxf(max_curiosity_meow_seconds, min_seconds)
	_curiosity_meow_remaining = _rng.randf_range(min_seconds, max_seconds)


func _can_build_curiosity(combat_near: bool, delta: float = 0.0, refresh_line_of_sight: bool = true) -> bool:
	if not _has_player_context or combat_near:
		return false
	if global_position.distance_squared_to(_player_position) > curiosity_awareness_radius * curiosity_awareness_radius:
		return false
	if refresh_line_of_sight:
		if not _has_cached_line_of_sight_to_player(delta):
			return false
	elif not _curiosity_line_of_sight_visible:
		return false
	if _is_player_moving_toward_cat():
		return false
	return true


func _should_bias_wander_toward_player() -> bool:
	if _curiosity < curiosity_target_bias_threshold:
		return false
	if not _can_build_curiosity(false, 0.0, false):
		return false
	return global_position.distance_squared_to(_player_position) > player_personal_space_radius * player_personal_space_radius


func _get_curiosity_target_radius() -> float:
	var threshold: float = clampf(curiosity_target_bias_threshold, 0.0, 0.99)
	var curiosity_ratio: float = clampf((_curiosity - threshold) / maxf(1.0 - threshold, 0.001), 0.0, 1.0)
	var inner_radius: float = maxf(curiosity_inner_target_radius, player_personal_space_radius + body_radius + 12.0)
	var outer_radius: float = maxf(curiosity_outer_target_radius, inner_radius + 1.0)
	return lerpf(outer_radius, inner_radius, curiosity_ratio)


func _is_player_moving_toward_cat() -> bool:
	if not _has_player_context:
		return false
	var approach_speed: float = maxf(player_approach_speed_threshold, 0.0)
	if _player_velocity.length_squared() < approach_speed * approach_speed:
		return false
	var to_cat: Vector2 = global_position - _player_position
	if to_cat.length_squared() <= 0.001:
		return true
	var approach_dot: float = _player_velocity.normalized().dot(to_cat.normalized())
	return approach_dot >= clampf(player_approach_dot_threshold, -1.0, 1.0)


func _has_nearby_player_projectile() -> bool:
	var reset_radius: float = maxf(shot_curiosity_reset_radius, 0.0)
	if reset_radius <= 0.0:
		return false
	for projectile_position: Vector2 in _player_projectile_points:
		if global_position.distance_squared_to(projectile_position) <= reset_radius * reset_radius:
			return true
	return false


func _get_player_projectile_startle_vector() -> Vector2:
	var reset_radius: float = maxf(shot_curiosity_reset_radius, 0.0)
	if reset_radius <= 0.0:
		return Vector2.ZERO
	var startle_vector := Vector2.ZERO
	for projectile_position: Vector2 in _player_projectile_points:
		var to_cat: Vector2 = global_position - projectile_position
		var distance: float = to_cat.length()
		if distance > reset_radius:
			continue
		if distance <= 0.001:
			to_cat = Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
			distance = 1.0
		var ratio: float = clampf(1.0 - distance / reset_radius, 0.0, 1.0)
		startle_vector += to_cat.normalized() * ratio * ratio
	return startle_vector


func _pick_curiosity_biased_position() -> Vector2:
	if not _should_bias_wander_toward_player():
		return Vector2.INF
	var min_radius: float = player_personal_space_radius + body_radius + 12.0
	var max_radius: float = maxf(_get_curiosity_target_radius(), min_radius + 1.0)
	for _attempt in range(32):
		var sample_radius: float = _rng.randf_range(min_radius, max_radius)
		var candidate: Vector2 = _player_position + Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)) * sample_radius
		candidate = _find_clear_target(candidate)
		if _position_is_clear(candidate) and _position_respects_player_space(candidate, min_radius):
			return candidate
	var fallback_direction: Vector2 = global_position - _player_position
	if fallback_direction.length_squared() <= 0.001:
		fallback_direction = _last_facing_direction
	if fallback_direction.length_squared() <= 0.001:
		fallback_direction = Vector2.RIGHT
	var fallback: Vector2 = _find_clear_target(_player_position + fallback_direction.normalized() * max_radius)
	if _position_is_clear(fallback) and _position_respects_player_space(fallback, min_radius):
		return fallback
	return Vector2.INF


func _position_respects_player_space(candidate_position: Vector2, min_radius: float) -> bool:
	if not _has_player_context:
		return true
	return candidate_position.distance_squared_to(_player_position) >= min_radius * min_radius


func _has_line_of_sight_to_player() -> bool:
	if not _has_player_context:
		return false
	return _has_clear_segment(global_position, _player_position, maxf(curiosity_line_of_sight_margin, 0.0))


func _has_cached_line_of_sight_to_player(delta: float) -> bool:
	if not _has_player_context:
		_reset_curiosity_line_of_sight_cache()
		return false
	_curiosity_line_of_sight_remaining = maxf(_curiosity_line_of_sight_remaining - delta, 0.0)
	var refresh_distance: float = maxf(path_grid_size * 0.75, 24.0)
	var refresh_distance_squared: float = refresh_distance * refresh_distance
	var cat_position_changed: bool = _curiosity_line_of_sight_cat_position == Vector2.INF or global_position.distance_squared_to(_curiosity_line_of_sight_cat_position) > refresh_distance_squared
	var player_position_changed: bool = _curiosity_line_of_sight_player_position == Vector2.INF or _player_position.distance_squared_to(_curiosity_line_of_sight_player_position) > refresh_distance_squared
	if _curiosity_line_of_sight_remaining <= 0.0 or cat_position_changed or player_position_changed:
		_curiosity_line_of_sight_visible = _has_line_of_sight_to_player()
		_curiosity_line_of_sight_cat_position = global_position
		_curiosity_line_of_sight_player_position = _player_position
		_curiosity_line_of_sight_remaining = maxf(curiosity_line_of_sight_check_seconds, 0.05)
	return _curiosity_line_of_sight_visible


func _reset_curiosity_line_of_sight_cache() -> void:
	_curiosity_line_of_sight_remaining = 0.0
	_curiosity_line_of_sight_visible = false
	_curiosity_line_of_sight_cat_position = Vector2.INF
	_curiosity_line_of_sight_player_position = Vector2.INF


func _build_path_to(destination: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if destination == Vector2.INF:
		return points
	if _has_clear_segment(global_position, destination, body_radius * 0.75):
		points.append(destination)
		return points
	var bounds: Rect2 = _get_effective_roam_bounds()
	var grid_size: float = _get_effective_path_grid_size(bounds)
	var cols: int = max(int(ceil(bounds.size.x / grid_size)), 1)
	var rows: int = max(int(ceil(bounds.size.y / grid_size)), 1)
	var start_cell: Vector2i = _nearest_clear_path_cell(_world_to_path_cell(global_position, bounds, grid_size, cols, rows), bounds, grid_size, cols, rows)
	var goal_cell: Vector2i = _nearest_clear_path_cell(_world_to_path_cell(destination, bounds, grid_size, cols, rows), bounds, grid_size, cols, rows)
	if start_cell == INVALID_PATH_CELL or goal_cell == INVALID_PATH_CELL:
		points.append(destination)
		return points
	var path_cells: Array[Vector2i] = _find_path_cells(start_cell, goal_cell, bounds, grid_size, cols, rows, _get_effective_path_search_cell_limit(bounds))
	if path_cells.is_empty():
		points.append(destination)
		return points
	return _smooth_path_points(_path_cells_to_points(path_cells, bounds, grid_size, destination))


func _world_to_path_cell(world_position: Vector2, bounds: Rect2, grid_size: float, cols: int, rows: int) -> Vector2i:
	var local_position: Vector2 = world_position - bounds.position
	return Vector2i(
		clampi(int(floor(local_position.x / grid_size)), 0, cols - 1),
		clampi(int(floor(local_position.y / grid_size)), 0, rows - 1)
	)


func _path_cell_center(bounds: Rect2, cell: Vector2i, grid_size: float) -> Vector2:
	return bounds.position + Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5) * grid_size


func _nearest_clear_path_cell(origin_cell: Vector2i, bounds: Rect2, grid_size: float, cols: int, rows: int) -> Vector2i:
	if _path_cell_is_clear(origin_cell, bounds, grid_size, cols, rows):
		return origin_cell
	var max_radius: int = max(cols, rows)
	for radius: int in range(1, max_radius + 1):
		for x: int in range(origin_cell.x - radius, origin_cell.x + radius + 1):
			for y: int in range(origin_cell.y - radius, origin_cell.y + radius + 1):
				if abs(x - origin_cell.x) != radius and abs(y - origin_cell.y) != radius:
					continue
				var candidate: Vector2i = Vector2i(x, y)
				if _path_cell_is_clear(candidate, bounds, grid_size, cols, rows):
					return candidate
	return INVALID_PATH_CELL


func _find_path_cells(start_cell: Vector2i, goal_cell: Vector2i, bounds: Rect2, grid_size: float, cols: int, rows: int, search_cell_limit: int) -> Array[Vector2i]:
	var empty_path: Array[Vector2i] = []
	if start_cell == goal_cell:
		empty_path.append(start_cell)
		return empty_path
	var queue: Array[Vector2i] = [start_cell]
	var queue_index: int = 0
	var came_from: Dictionary = {}
	came_from[_path_cell_key(start_cell)] = start_cell
	var neighbor_offsets: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]
	var searched_cells: int = 0
	var search_limit: int = max(search_cell_limit, 1)
	while queue_index < queue.size() and searched_cells < search_limit:
		var current_cell: Vector2i = queue[queue_index]
		queue_index += 1
		searched_cells += 1
		if current_cell == goal_cell:
			return _reconstruct_path_cells(start_cell, goal_cell, came_from)
		for offset: Vector2i in neighbor_offsets:
			var next_cell: Vector2i = current_cell + offset
			if not _path_cell_is_clear(next_cell, bounds, grid_size, cols, rows):
				continue
			var next_key: String = _path_cell_key(next_cell)
			if came_from.has(next_key):
				continue
			came_from[next_key] = current_cell
			queue.append(next_cell)
	return empty_path


func _reconstruct_path_cells(start_cell: Vector2i, goal_cell: Vector2i, came_from: Dictionary) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current_cell: Vector2i = goal_cell
	while true:
		path.push_front(current_cell)
		if current_cell == start_cell:
			return path
		var previous_value: Variant = came_from.get(_path_cell_key(current_cell), INVALID_PATH_CELL)
		if not previous_value is Vector2i:
			path.clear()
			return path
		current_cell = previous_value
		if current_cell == INVALID_PATH_CELL:
			path.clear()
			return path
	return path


func _path_cells_to_points(path_cells: Array[Vector2i], bounds: Rect2, grid_size: float, destination: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for index: int in range(1, path_cells.size()):
		points.append(_path_cell_center(bounds, path_cells[index], grid_size))
	points.append(destination)
	return points


func _smooth_path_points(points: Array[Vector2]) -> Array[Vector2]:
	var smoothed: Array[Vector2] = []
	var anchor: Vector2 = global_position
	var index: int = 0
	while index < points.size():
		var best_index: int = index
		var candidate_index: int = points.size() - 1
		while candidate_index >= index:
			if _has_clear_segment(anchor, points[candidate_index], body_radius * 0.75):
				best_index = candidate_index
				break
			candidate_index -= 1
		smoothed.append(points[best_index])
		anchor = points[best_index]
		index = best_index + 1
	return smoothed


func _path_cell_is_clear(cell: Vector2i, bounds: Rect2, grid_size: float, cols: int, rows: int) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= cols or cell.y >= rows:
		return false
	return _position_is_clear(_path_cell_center(bounds, cell, grid_size))


func _path_cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]


func _get_effective_path_grid_size(bounds: Rect2) -> float:
	var grid_size: float = maxf(path_grid_size, maxf(body_radius * 2.6, 24.0))
	if _uses_large_roam_cost_controls(bounds):
		grid_size *= maxf(large_roam_path_grid_multiplier, 1.0)
	return grid_size


func _get_effective_path_search_cell_limit(bounds: Rect2) -> int:
	if _uses_large_roam_cost_controls(bounds):
		return max(large_roam_path_search_cell_limit, 1)
	return max(path_search_cell_limit, 1)


func _uses_large_roam_cost_controls(bounds: Rect2 = Rect2()) -> bool:
	var checked_bounds: Rect2 = bounds
	if checked_bounds.size == Vector2.ZERO:
		checked_bounds = _get_effective_roam_bounds()
	return checked_bounds.size.x * checked_bounds.size.y >= maxf(large_roam_area_threshold, 1.0)


func _has_clear_segment(from_position: Vector2, to_position: Vector2, margin: float) -> bool:
	if from_position == Vector2.INF or to_position == Vector2.INF:
		return false
	if _segment_hits_blocker(from_position, to_position, _get_blocker_rects(), margin):
		return false
	return _segment_stays_in_playable_area(from_position, to_position)


func _segment_hits_blocker(from_position: Vector2, to_position: Vector2, blockers: Array[Rect2], margin: float) -> bool:
	for blocker: Rect2 in blockers:
		if _segment_intersects_rect(from_position, to_position, blocker.grow(margin)):
			return true
	return false


func _segment_stays_in_playable_area(from_position: Vector2, to_position: Vector2) -> bool:
	var distance: float = from_position.distance_to(to_position)
	var sample_step: float = maxf(minf(_get_effective_path_grid_size(_get_effective_roam_bounds()) * 0.5, 32.0), 8.0)
	var sample_count: int = max(int(ceil(distance / sample_step)), 1)
	for index: int in range(sample_count + 1):
		var sample: Vector2 = from_position.lerp(to_position, float(index) / float(sample_count))
		if not _point_inside_playable_area(sample):
			return false
	return true


func _point_inside_playable_area(candidate_position: Vector2) -> bool:
	if not playable_rects.is_empty():
		for rect: Rect2 in playable_rects:
			if _rect_has_point_inclusive(rect, candidate_position):
				return true
		return false
	return ArenaGeometry.contains_point(candidate_position, arena_bounds, arena_shape)


func _rect_has_point_inclusive(rect: Rect2, candidate_position: Vector2) -> bool:
	var rect_end: Vector2 = rect.position + rect.size
	return candidate_position.x >= rect.position.x - 0.001 and candidate_position.x <= rect_end.x + 0.001 and candidate_position.y >= rect.position.y - 0.001 and candidate_position.y <= rect_end.y + 0.001


func _segment_intersects_rect(from_position: Vector2, to_position: Vector2, rect: Rect2) -> bool:
	if rect.has_point(from_position) or rect.has_point(to_position):
		return true
	var top_left: Vector2 = rect.position
	var top_right: Vector2 = rect.position + Vector2(rect.size.x, 0.0)
	var bottom_right: Vector2 = rect.position + rect.size
	var bottom_left: Vector2 = rect.position + Vector2(0.0, rect.size.y)
	if _segments_intersect(from_position, to_position, top_left, top_right):
		return true
	if _segments_intersect(from_position, to_position, top_right, bottom_right):
		return true
	if _segments_intersect(from_position, to_position, bottom_right, bottom_left):
		return true
	if _segments_intersect(from_position, to_position, bottom_left, top_left):
		return true
	return false


func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var r: Vector2 = b - a
	var s: Vector2 = d - c
	var denominator: float = r.cross(s)
	var c_to_a: Vector2 = c - a
	if abs(denominator) <= 0.001:
		if abs(c_to_a.cross(r)) > 0.001:
			return false
		var use_x: bool = abs(r.x) >= abs(r.y)
		var a0: float = a.x if use_x else a.y
		var b0: float = b.x if use_x else b.y
		var c0: float = c.x if use_x else c.y
		var d0: float = d.x if use_x else d.y
		return max(min(a0, b0), min(c0, d0)) <= min(max(a0, b0), max(c0, d0))
	var t: float = c_to_a.cross(s) / denominator
	var u: float = c_to_a.cross(r) / denominator
	return t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0


func _pick_clear_random_position() -> Vector2:
	var bounds := _get_effective_roam_bounds()
	var margin: float = maxf(body_radius + 18.0, 24.0)
	for _attempt in range(24):
		var candidate := Vector2(
			_rng.randf_range(bounds.position.x + margin, bounds.position.x + bounds.size.x - margin),
			_rng.randf_range(bounds.position.y + margin, bounds.position.y + bounds.size.y - margin)
		)
		candidate = _find_clear_target(candidate)
		if _position_is_clear(candidate):
			return candidate
	return _find_clear_target(bounds.get_center())


func _find_clear_target(preferred_position: Vector2) -> Vector2:
	var clamped := _clamp_to_roam_bounds(preferred_position)
	var blockers := _get_blocker_rects()
	var constrained := ArenaGeometry.constrain_point_to_playable_regions(clamped, arena_bounds, arena_shape, playable_rects, blockers, body_radius)
	if _position_is_clear(constrained):
		return constrained
	var search_step: float = maxf(body_radius * 2.2, 28.0)
	for radius_index in range(1, 8):
		var radius := search_step * float(radius_index)
		var sample_count := 8 + radius_index * 4
		for sample_index in range(sample_count):
			var candidate := clamped + Vector2.RIGHT.rotated(TAU * float(sample_index) / float(sample_count)) * radius
			candidate = _clamp_to_roam_bounds(candidate)
			candidate = ArenaGeometry.constrain_point_to_playable_regions(candidate, arena_bounds, arena_shape, playable_rects, blockers, body_radius)
			if _position_is_clear(candidate):
				return candidate
	return ArenaGeometry.constrain_point_to_playable_regions(clamped, arena_bounds, arena_shape, playable_rects, blockers, body_radius)


func _position_is_clear(candidate_position: Vector2) -> bool:
	if not _position_inside_roam_bounds(candidate_position):
		return false
	if not _point_inside_playable_area(candidate_position):
		return false
	for blocker in _get_blocker_rects():
		if blocker.grow(body_radius + 4.0).has_point(candidate_position):
			return false
	return true


func _get_blocker_rects() -> Array[Rect2]:
	return _blocker_rects


func _rebuild_blocker_rects() -> void:
	_blocker_rects.clear()
	_blocker_rects.append_array(wall_rects)
	_blocker_rects.append_array(void_rects)


func _constrain_to_playable(candidate_position: Vector2) -> Vector2:
	return ArenaGeometry.constrain_point_to_playable_regions(candidate_position, arena_bounds, arena_shape, playable_rects, _get_blocker_rects(), body_radius)


func _constrain_to_playable_if_needed(candidate_position: Vector2) -> Vector2:
	if _position_is_clear(candidate_position):
		return candidate_position
	return _constrain_to_playable(candidate_position)


func _get_effective_roam_bounds() -> Rect2:
	if _has_roam_bounds:
		return _roam_bounds
	return arena_bounds


func _position_inside_roam_bounds(candidate_position: Vector2) -> bool:
	if not _has_roam_bounds:
		return true
	return _roam_bounds.grow(-body_radius).has_point(candidate_position)


func _clamp_to_roam_bounds(candidate_position: Vector2) -> Vector2:
	if not _has_roam_bounds:
		return candidate_position
	return Vector2(
		clamp(candidate_position.x, _roam_bounds.position.x + body_radius, _roam_bounds.position.x + _roam_bounds.size.x - body_radius),
		clamp(candidate_position.y, _roam_bounds.position.y + body_radius, _roam_bounds.position.y + _roam_bounds.size.y - body_radius)
	)


func _update_visual_state(delta: float) -> void:
	var moving := velocity.length_squared() > 4.0 or _is_jumping()
	var animating_idle := not moving and _idle_state != IDLE_STATE_STANDING
	if _is_jumping():
		_last_facing_direction = _startle_jump_direction
	elif moving:
		_last_facing_direction = velocity.normalized()
	elif _is_look_idle_state() and not _has_rest_transition():
		_update_look_idle(delta)
	if moving or animating_idle:
		var animation_rate: float = _get_animation_rate(moving)
		_animation_time += delta * animation_rate
		if not moving and _sit_transition_mode != SIT_TRANSITION_NONE:
			_update_sit_transition()
		if not moving and _lay_transition_mode != LAY_TRANSITION_NONE:
			_update_lay_transition()
		queue_redraw()
	_update_sprite_frame()


func _get_animation_rate(moving: bool) -> float:
	if moving:
		return 12.0 if _is_fleeing else 8.0
	if _startle_jump_queued and _has_rest_transition():
		return maxf(startle_get_up_animation_rate, 1.0)
	return 8.0


func _update_sprite_frame() -> void:
	_ensure_sprite()
	_sprite.position = _get_sprite_base_position() + Vector2(0.0, _get_startle_jump_visual_y_offset())
	var moving := velocity.length_squared() > 4.0 or _is_jumping()
	var direction := _startle_jump_direction if _is_jumping() else _last_facing_direction
	if direction.length_squared() <= 0.001:
		direction = Vector2.DOWN
	var direction_index := _get_direction_index(direction)
	if not moving and _idle_state != IDLE_STATE_STANDING:
		direction_index = _idle_direction_index
	var frames: Array[Vector2i] = []
	if _is_jumping():
		frames = _get_startle_jump_frames(direction_index)
	elif moving:
		frames = _get_movement_frames(direction_index, _is_fleeing)
	else:
		frames = _get_idle_frames(direction_index)
	_sprite.flip_h = false
	var frame_index := _get_frame_index(frames.size(), moving)
	var frame: Vector2i = frames[frame_index]
	_sprite.region_rect = Rect2(
		Vector2(frame.x * FRAME_SIZE.x, frame.y * FRAME_SIZE.y),
		Vector2(float(FRAME_SIZE.x), float(FRAME_SIZE.y))
	)


func _get_direction_index(direction: Vector2) -> int:
	var signed_steps := int(round(Vector2.DOWN.angle_to(direction.normalized()) / DIRECTION_STEP_RADIANS))
	return wrapi(signed_steps, 0, DIRECTION_COUNT)


func _get_direction_vector(direction_index: int) -> Vector2:
	return Vector2.DOWN.rotated(DIRECTION_STEP_RADIANS * float(wrapi(direction_index, 0, DIRECTION_COUNT)))


func _get_movement_frames(direction_index: int, running: bool) -> Array[Vector2i]:
	var column_start: int = RUN_COLUMN_START if running else WALK_COLUMN_START
	var frame_count: int = RUN_FRAME_COUNT if running else WALK_FRAME_COUNT
	return _get_clip_frames(direction_index, column_start, frame_count)


func _get_startle_jump_frames(direction_index: int) -> Array[Vector2i]:
	return _get_clip_frames(direction_index, RUN_COLUMN_START, mini(STARTLE_JUMP_FRAME_COUNT, RUN_FRAME_COUNT))


func _get_idle_frames(direction_index: int) -> Array[Vector2i]:
	if _is_seated_idle_state() and _sit_transition_mode != SIT_TRANSITION_NONE:
		return _get_clip_frames(direction_index, SIT_COLUMN_START, _get_sit_frame_count(direction_index))
	if _idle_state == IDLE_STATE_LAYING:
		return _get_clip_frames(direction_index, LAY_COLUMN_START, LAY_FRAME_COUNT)
	if _idle_state == IDLE_STATE_SITTING:
		return _get_clip_frames(direction_index, SIT_COLUMN_START, _get_sit_frame_count(direction_index))
	if _idle_state == IDLE_STATE_GLANCING or _idle_state == IDLE_STATE_SCANNING:
		return _get_clip_frames(direction_index, LOOK_COLUMN_START, LOOK_FRAME_COUNT)
	return _get_clip_frames(direction_index, WALK_COLUMN_START, 1)


func _get_frame_index(frame_count: int, moving: bool) -> int:
	if _is_jumping():
		return _get_startle_jump_frame_index(frame_count)
	if _sit_transition_mode == SIT_TRANSITION_DOWN:
		return mini(int(floor(_animation_time)), frame_count - 1)
	if _sit_transition_mode == SIT_TRANSITION_UP:
		var stand_up_frame_index: int = mini(int(floor(_animation_time)), frame_count - 1)
		return frame_count - 1 - stand_up_frame_index
	if _lay_transition_mode == LAY_TRANSITION_DOWN:
		return mini(int(floor(_animation_time)), frame_count - 1)
	if _lay_transition_mode == LAY_TRANSITION_UP:
		var lay_up_frame_index: int = mini(int(floor(_animation_time)), frame_count - 1)
		return frame_count - 1 - lay_up_frame_index
	if moving:
		return int(floor(_animation_time)) % frame_count
	if _is_look_idle_state():
		return _get_look_frame_index(frame_count)
	if _idle_state == IDLE_STATE_SITTING or _idle_state == IDLE_STATE_LAYING:
		return frame_count - 1
	if _idle_state == IDLE_STATE_STANDING:
		return 0
	return mini(int(floor(_animation_time)), frame_count - 1)


func _get_look_frame_index(frame_count: int) -> int:
	if frame_count <= 1:
		return 0
	return clampi(_look_frame_index, 0, frame_count - 1)


func _get_neutral_look_frame_index(frame_count: int = LOOK_FRAME_COUNT) -> int:
	return clampi(LOOK_NEUTRAL_FRAME_INDEX, 0, maxi(frame_count - 1, 0))


func _get_startle_jump_frame_index(frame_count: int) -> int:
	if frame_count <= 1:
		return 0
	var jump_duration: float = maxf(startle_jump_duration, 0.05)
	var jump_progress: float = clampf(_startle_jump_elapsed / jump_duration, 0.0, 1.0)
	return mini(int(floor(jump_progress * float(frame_count))), frame_count - 1)


func _get_sprite_base_position() -> Vector2:
	return Vector2(0.0, -body_radius * 0.42)


func _get_startle_jump_visual_y_offset() -> float:
	if not _is_jumping():
		return 0.0
	var jump_duration: float = maxf(startle_jump_duration, 0.05)
	var jump_progress: float = clampf(_startle_jump_elapsed / jump_duration, 0.0, 1.0)
	return -sin(jump_progress * PI) * maxf(startle_jump_arc_height, 0.0)


func _get_sit_frame_count(direction_index: int) -> int:
	return int(SIT_FRAME_COUNTS[wrapi(direction_index, 0, DIRECTION_COUNT)])


func _get_clip_frames(direction_index: int, column_start: int, frame_count: int) -> Array[Vector2i]:
	var row := DIRECTION_ROW_START + wrapi(direction_index, 0, DIRECTION_COUNT) * DIRECTION_ROW_STRIDE
	var frames: Array[Vector2i] = []
	for frame_offset in range(frame_count):
		var column := column_start + frame_offset % ANIMATION_FRAMES_PER_ROW
		var row_offset := int(floor(float(frame_offset) / float(ANIMATION_FRAMES_PER_ROW)))
		frames.append(Vector2i(column, row + row_offset))
	return frames
