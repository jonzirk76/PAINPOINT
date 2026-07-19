extends CharacterBody2D
class_name CatEntity

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
const LAY_COLUMN_START := 8
const LAY_FRAME_COUNT := 8
const WALK_COLUMN_START := 12
const WALK_FRAME_COUNT := 4
const RUN_COLUMN_START := 20
const RUN_FRAME_COUNT := 8
const IDLE_STATE_STANDING := "standing"
const IDLE_STATE_SITTING := "sitting"
const IDLE_STATE_LOOKING := "looking"
const IDLE_STATE_LAYING := "laying"

## Controls the cat's wall clearance and soft movement body size.
@export var body_radius: float = 11.0
## Controls normal wandering speed when the cat is away from combat.
@export var wander_speed: float = 78.0
## Controls burst speed while the cat is moving away from active combat.
@export var flee_speed: float = 142.0
## Controls how quickly the cat accelerates toward its current movement intent.
@export var acceleration: float = 520.0
## Controls how far away enemies and spawners start influencing the cat.
@export var combat_avoidance_radius: float = 260.0
## Controls how far the cat tries to move when choosing a flee target.
@export var flee_target_distance: float = 220.0
## Controls how often the cat chooses a fresh wander target.
@export var wander_retarget_seconds: float = 2.4
## Controls how likely the cat is to pause instead of immediately choosing another wander target.
@export var idle_chance: float = 0.28
## Controls the shortest random idle pause between wandering moves.
@export var min_idle_seconds: float = 0.85
## Controls the largest random idle pause between wandering moves.
@export var max_idle_seconds: float = 3.4
## Controls how often an idle cat remains in a standing rest pose.
@export var standing_idle_weight: float = 0.35
## Controls how often an idle cat uses the sit-down animation.
@export var sitting_idle_weight: float = 0.32
## Controls how often an idle cat uses the look-around animation.
@export var looking_idle_weight: float = 0.23
## Controls how often an idle cat uses the lay-down animation.
@export var laying_idle_weight: float = 0.10
## Controls the visual sprite scale applied to 32x32 sheet frames.
@export var sprite_scale: float = 1.45

var enabled: bool = false
var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var arena_shape: int = 0
var wall_rects: Array[Rect2] = []
var void_rects: Array[Rect2] = []
var playable_rects: Array[Rect2] = []

var _sprite: Sprite2D = null
var _cat_texture: Texture2D = DEFAULT_CAT_TEXTURE
var _rng := RandomNumberGenerator.new()
var _target_position: Vector2 = Vector2.INF
var _danger_points: Array[Dictionary] = []
var _roam_bounds: Rect2 = Rect2()
var _has_roam_bounds: bool = false
var _retarget_remaining: float = 0.0
var _idle_remaining: float = 0.0
var _animation_time: float = 0.0
var _last_facing_direction: Vector2 = Vector2.DOWN
var _is_fleeing: bool = false
var _idle_state: String = IDLE_STATE_STANDING


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
	_retarget_remaining = 0.0
	_idle_remaining = 0.0
	_animation_time = 0.0
	_last_facing_direction = Vector2.DOWN
	_is_fleeing = false
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


func set_cat_texture(texture: Texture2D) -> void:
	if texture == null:
		return
	_cat_texture = texture
	_ensure_sprite()
	_sprite.texture = _cat_texture


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
	global_position = _constrain_to_playable(global_position)
	if _target_position != Vector2.INF:
		_target_position = _constrain_to_playable(_target_position)


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


func _physics_process(delta: float) -> void:
	if not enabled:
		velocity = Vector2.ZERO
		return
	var avoidance: Vector2 = _get_combat_avoidance_vector()
	var desired_velocity := Vector2.ZERO
	_is_fleeing = avoidance.length_squared() > 0.001
	if _is_fleeing:
		_idle_remaining = 0.0
		_set_idle_state(IDLE_STATE_STANDING)
		_target_position = _find_clear_target(global_position + avoidance.normalized() * flee_target_distance)
		desired_velocity = (_target_position - global_position).normalized() * flee_speed
	else:
		_update_wander_target(delta)
		if _idle_remaining <= 0.0 and _target_position != Vector2.INF:
			var to_target: Vector2 = _target_position - global_position
			if to_target.length_squared() > 16.0 * 16.0:
				desired_velocity = to_target.normalized() * wander_speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	move_and_slide()
	if get_slide_collision_count() > 0 and avoidance.length_squared() <= 0.001:
		_pick_next_wander_target()
	global_position = _constrain_to_playable(global_position)
	_update_visual_state(delta)


func _draw() -> void:
	draw_set_transform(Vector2(0.0, body_radius * 0.82), 0.0, Vector2(body_radius * 1.15, body_radius * 0.34))
	draw_circle(Vector2.ZERO, 1.0, Color(0.0, 0.0, 0.0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _configure_collision_identity() -> void:
	collision_layer = 0
	collision_mask = COLLISION_MASK_WALLS_AND_VOID


func _add_collision() -> void:
	if get_node_or_null("CollisionShape2D") != null:
		return
	var shape := CircleShape2D.new()
	shape.radius = body_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)


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
	_sprite.position = Vector2(0.0, -body_radius * 0.42)
	add_child(_sprite)


func _update_wander_target(delta: float) -> void:
	if _idle_remaining > 0.0:
		_idle_remaining = max(_idle_remaining - delta, 0.0)
		if _idle_remaining <= 0.0:
			_set_idle_state(IDLE_STATE_STANDING)
		return
	_retarget_remaining = max(_retarget_remaining - delta, 0.0)
	var target_reached := _target_position == Vector2.INF or global_position.distance_squared_to(_target_position) <= 18.0 * 18.0
	if target_reached or _retarget_remaining <= 0.0:
		if _rng.randf() < clamp(idle_chance, 0.0, 1.0):
			_begin_idle_pause()
			return
		_pick_next_wander_target()


func _pick_next_wander_target() -> void:
	_set_idle_state(IDLE_STATE_STANDING)
	_target_position = _pick_clear_random_position()
	_retarget_remaining = max(wander_retarget_seconds * _rng.randf_range(0.65, 1.35), 0.2)


func _begin_idle_pause() -> void:
	var idle_min := max(min_idle_seconds, 0.1)
	var idle_max := max(max_idle_seconds, idle_min + 0.1)
	_idle_remaining = _rng.randf_range(idle_min, idle_max)
	_retarget_remaining = 0.0
	_target_position = global_position
	velocity = Vector2.ZERO
	_set_idle_state(_choose_idle_state())


func _choose_idle_state() -> String:
	var weights := [
		max(standing_idle_weight, 0.0),
		max(sitting_idle_weight, 0.0),
		max(looking_idle_weight, 0.0),
		max(laying_idle_weight, 0.0)
	]
	var total_weight := 0.0
	for weight in weights:
		total_weight += float(weight)
	if total_weight <= 0.0:
		return IDLE_STATE_STANDING
	var roll := _rng.randf_range(0.0, total_weight)
	if roll < weights[0]:
		return IDLE_STATE_STANDING
	roll -= weights[0]
	if roll < weights[1]:
		return IDLE_STATE_SITTING
	roll -= weights[1]
	if roll < weights[2]:
		return IDLE_STATE_LOOKING
	return IDLE_STATE_LAYING


func _set_idle_state(state: String) -> void:
	if _idle_state == state:
		return
	_idle_state = state
	_animation_time = 0.0


func _get_combat_avoidance_vector() -> Vector2:
	var avoidance := Vector2.ZERO
	for point_info in _danger_points:
		var position: Vector2 = point_info.get("position", Vector2.INF)
		if position == Vector2.INF:
			continue
		var radius: float = max(float(point_info.get("radius", combat_avoidance_radius)), body_radius + 1.0)
		var to_cat: Vector2 = global_position - position
		var distance: float = to_cat.length()
		if distance > radius:
			continue
		if distance <= 0.001:
			to_cat = Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
			distance = 1.0
		var weight: float = max(float(point_info.get("weight", 1.0)), 0.0)
		var ratio: float = clamp(1.0 - distance / radius, 0.0, 1.0)
		avoidance += to_cat.normalized() * ratio * ratio * weight
	return avoidance


func _pick_clear_random_position() -> Vector2:
	var bounds := _get_effective_roam_bounds()
	var margin: float = max(body_radius + 18.0, 24.0)
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
	var search_step: float = max(body_radius * 2.2, 28.0)
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


func _position_is_clear(position: Vector2) -> bool:
	if not _position_inside_roam_bounds(position):
		return false
	if position.distance_squared_to(_constrain_to_playable(position)) > 1.0:
		return false
	for blocker in _get_blocker_rects():
		if blocker.grow(body_radius + 4.0).has_point(position):
			return false
	return true


func _get_blocker_rects() -> Array[Rect2]:
	var blockers: Array[Rect2] = []
	blockers.append_array(wall_rects)
	blockers.append_array(void_rects)
	return blockers


func _constrain_to_playable(position: Vector2) -> Vector2:
	return ArenaGeometry.constrain_point_to_playable_regions(position, arena_bounds, arena_shape, playable_rects, _get_blocker_rects(), body_radius)


func _get_effective_roam_bounds() -> Rect2:
	if _has_roam_bounds:
		return _roam_bounds
	return arena_bounds


func _position_inside_roam_bounds(position: Vector2) -> bool:
	if not _has_roam_bounds:
		return true
	return _roam_bounds.grow(-body_radius).has_point(position)


func _clamp_to_roam_bounds(position: Vector2) -> Vector2:
	if not _has_roam_bounds:
		return position
	return Vector2(
		clamp(position.x, _roam_bounds.position.x + body_radius, _roam_bounds.position.x + _roam_bounds.size.x - body_radius),
		clamp(position.y, _roam_bounds.position.y + body_radius, _roam_bounds.position.y + _roam_bounds.size.y - body_radius)
	)


func _update_visual_state(delta: float) -> void:
	var moving := velocity.length_squared() > 4.0
	var animating_idle := not moving and _idle_state != IDLE_STATE_STANDING
	if moving:
		_last_facing_direction = velocity.normalized()
	if moving or animating_idle:
		var animation_rate := 12.0 if _is_fleeing else 8.0
		_animation_time += delta * animation_rate
		queue_redraw()
	_update_sprite_frame()


func _update_sprite_frame() -> void:
	_ensure_sprite()
	var moving := velocity.length_squared() > 4.0
	var direction := _last_facing_direction
	if direction.length_squared() <= 0.001:
		direction = Vector2.DOWN
	var direction_index := _get_direction_index(direction)
	var frames := _get_movement_frames(direction_index, _is_fleeing) if moving else _get_idle_frames(direction_index)
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


func _get_movement_frames(direction_index: int, running: bool) -> Array[Vector2i]:
	var column_start := RUN_COLUMN_START if running else WALK_COLUMN_START
	var frame_count := RUN_FRAME_COUNT if running else WALK_FRAME_COUNT
	return _get_clip_frames(direction_index, column_start, frame_count)


func _get_idle_frames(direction_index: int) -> Array[Vector2i]:
	if _idle_state == IDLE_STATE_SITTING:
		return _get_clip_frames(direction_index, SIT_COLUMN_START, int(SIT_FRAME_COUNTS[wrapi(direction_index, 0, DIRECTION_COUNT)]))
	if _idle_state == IDLE_STATE_LOOKING:
		return _get_clip_frames(direction_index, LOOK_COLUMN_START, LOOK_FRAME_COUNT)
	if _idle_state == IDLE_STATE_LAYING:
		return _get_clip_frames(direction_index, LAY_COLUMN_START, LAY_FRAME_COUNT)
	return _get_clip_frames(direction_index, WALK_COLUMN_START, 1)


func _get_frame_index(frame_count: int, moving: bool) -> int:
	if moving or _idle_state == IDLE_STATE_LOOKING:
		return int(floor(_animation_time)) % frame_count
	if _idle_state == IDLE_STATE_STANDING:
		return 0
	return min(int(floor(_animation_time)), frame_count - 1)


func _get_clip_frames(direction_index: int, column_start: int, frame_count: int) -> Array[Vector2i]:
	var row := DIRECTION_ROW_START + wrapi(direction_index, 0, DIRECTION_COUNT) * DIRECTION_ROW_STRIDE
	var frames: Array[Vector2i] = []
	for frame_offset in range(frame_count):
		var column := column_start + frame_offset % ANIMATION_FRAMES_PER_ROW
		var row_offset := int(frame_offset / ANIMATION_FRAMES_PER_ROW)
		frames.append(Vector2i(column, row + row_offset))
	return frames
