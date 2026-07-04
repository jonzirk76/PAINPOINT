extends CharacterBody2D
class_name EnemySpawnerEntity

signal spawn_ready(spawner, spawn_position: Vector2)
signal health_changed(spawner, old_value: int, new_value: int)
signal health_depleted(spawner)
signal shot_ready(spawner, origin: Vector2, direction: Vector2, shot_config: Dictionary)

@export var spawn_interval: float = 2.8
@export var spawn_batch_count: int = 1
@export var warmup_seconds: float = 1.0
@export var active: bool = true
@export var body_radius: float = 32.0
@export var max_health: int = 18
@export var score_value: int = 75
@export var base_color: Color = Color(0.34, 0.28, 0.38)
@export var core_color: Color = Color(0.72, 0.24, 0.92)
@export var accent_color: Color = Color(0.52, 1.0, 0.42)
@export var shape_kind: String = "basic"
@export var shoots_projectiles: bool = false
@export var shot_cooldown: float = 1.8
@export var projectile_speed: float = 250.0
@export var projectile_damage: int = 1
@export var projectile_radius: float = 7.0
@export var shot_projectile_count: int = 1
@export var shot_spread_degrees: float = 0.0
@export var move_speed: float = 18.0
@export var preferred_distance: float = 340.0
@export var distance_band: float = 85.0
@export var strafe_speed: float = 8.0
@export var projectile_shield_lead_seconds: float = 0.72
@export var projectile_shield_after_spawn_seconds: float = 0.34
@export var projectile_shield_radius_bonus: float = 14.0
@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var arena_shape: int = 0
@export var wall_rects: Array[Rect2] = []

var health: int = max_health
var enemy_profile: Resource = null
var target_position: Vector2 = Vector2.ZERO
var _timer: float = 0.0
var _shot_timer: float = 0.0
var _hit_flash_remaining: float = 0.0
var _is_destroyed: bool = false
var _strafe_sign: float = 1.0
var _collision_shape: CollisionShape2D = null
var _projectile_shield_remaining: float = 0.0
var _projectile_shield_block_flash_remaining: float = 0.0


func _init() -> void:
	_configure_collision_identity()


func _ready() -> void:
	health = max_health
	_configure_collision_identity()
	_add_collision()
	_timer = max(warmup_seconds, 0.0)
	queue_redraw()


func _configure_collision_identity() -> void:
	collision_layer = 16
	collision_mask = 32
	add_to_group("spawners")


func _process(delta: float) -> void:
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = max(_hit_flash_remaining - delta, 0.0)
		queue_redraw()
	_update_projectile_shield(delta)
	if _is_destroyed or not active:
		return
	_timer -= delta
	if _timer <= projectile_shield_lead_seconds:
		activate_projectile_shield(max(_timer, 0.0) + projectile_shield_after_spawn_seconds)
	if _timer <= 0.0:
		_timer = spawn_interval
		spawn_ready.emit(self, global_position)
		queue_redraw()
	if shoots_projectiles:
		_shot_timer -= delta
		if _shot_timer <= 0.0:
			_shot_timer = shot_cooldown
			_try_emit_shot()


func _physics_process(_delta: float) -> void:
	if _is_destroyed or not active:
		velocity = Vector2.ZERO
		return
	velocity = _get_general_velocity()
	move_and_slide()
	if get_slide_collision_count() > 0:
		_strafe_sign *= -1.0
	global_position = ArenaGeometry.constrain_point(global_position, arena_bounds, arena_shape)
	if velocity.length_squared() > 1.0:
		queue_redraw()


func set_enabled(value: bool) -> void:
	active = value and not _is_destroyed
	if not active:
		velocity = Vector2.ZERO


func delay_next_spawn_until(delay_seconds: float) -> void:
	_timer = max(_timer, max(delay_seconds, 0.0))


func initialize(spawner_health: int, interval: float, radius: float) -> void:
	max_health = spawner_health
	health = max_health
	spawn_interval = interval
	spawn_batch_count = 1
	body_radius = radius
	_shot_timer = shot_cooldown * 0.5


func initialize_from_profile(profile) -> void:
	if profile == null:
		return
	enemy_profile = profile.enemy_profile
	max_health = profile.max_health
	health = max_health
	spawn_interval = profile.spawn_interval
	spawn_batch_count = max(int(profile.spawn_batch_count), 1)
	body_radius = profile.body_radius
	score_value = profile.score_value
	base_color = profile.base_color
	core_color = profile.core_color
	accent_color = profile.accent_color
	shape_kind = profile.shape_kind
	shoots_projectiles = profile.shoots_projectiles
	shot_cooldown = profile.shot_cooldown
	projectile_speed = profile.projectile_speed
	projectile_damage = profile.projectile_damage
	projectile_radius = profile.projectile_radius
	shot_projectile_count = profile.shot_projectile_count
	shot_spread_degrees = profile.shot_spread_degrees
	move_speed = profile.move_speed
	preferred_distance = profile.preferred_distance
	distance_band = profile.distance_band
	strafe_speed = profile.strafe_speed
	_shot_timer = shot_cooldown * 0.5


func set_target_position(position: Vector2) -> void:
	target_position = position
	queue_redraw()


func set_arena_definition(bounds: Rect2, shape: int, walls: Array = []) -> void:
	arena_bounds = bounds
	arena_shape = shape
	wall_rects.clear()
	for wall in walls:
		if wall is Rect2:
			wall_rects.append(wall)
	global_position = ArenaGeometry.constrain_point(global_position, arena_bounds, arena_shape)


func take_damage(packet) -> bool:
	if packet == null or health <= 0 or _is_destroyed:
		return false
	if blocks_projectile_damage(packet):
		return false
	var old_health := health
	health = max(health - max(packet.damage, 0), 0)
	_hit_flash_remaining = 0.18
	health_changed.emit(self, old_health, health)
	queue_redraw()
	if health == 0:
		_is_destroyed = true
		active = false
		collision_layer = 0
		collision_mask = 0
		velocity = Vector2.ZERO
		remove_from_group("spawners")
		health_depleted.emit(self)
	return true


func activate_projectile_shield(duration: float) -> void:
	if duration <= 0.0 or _is_destroyed:
		return
	_projectile_shield_remaining = max(_projectile_shield_remaining, duration)
	queue_redraw()


func is_projectile_shield_active() -> bool:
	return _projectile_shield_remaining > 0.0 and not _is_destroyed


func blocks_projectile_damage(packet) -> bool:
	if packet == null or not is_projectile_shield_active():
		return false
	if String(packet.projectile_kind) == "hostile":
		return false
	_projectile_shield_block_flash_remaining = 0.18
	queue_redraw()
	return true


func _draw() -> void:
	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(health) / float(max_health)
	var draw_base_color := base_color
	var draw_core_color := core_color
	if _hit_flash_remaining > 0.0:
		draw_base_color = Color(0.96, 0.9, 0.82)
		draw_core_color = Color(1.0, 0.58, 1.0)
	var base_points := PackedVector2Array([
		Vector2(-body_radius, body_radius * 0.55),
		Vector2(-body_radius * 0.7, -body_radius * 0.6),
		Vector2(0.0, -body_radius),
		Vector2(body_radius * 0.7, -body_radius * 0.6),
		Vector2(body_radius, body_radius * 0.55),
		Vector2(0.0, body_radius)
	])
	draw_colored_polygon(base_points, draw_base_color)
	draw_polyline(_closed_points(base_points), Color(0.08, 0.06, 0.1), 3.0, true)
	_draw_type_details(draw_core_color)
	if is_projectile_shield_active() or _projectile_shield_block_flash_remaining > 0.0:
		_draw_projectile_shield()
	draw_arc(Vector2.ZERO, body_radius * 0.38, 0.0, TAU * health_ratio, 28, accent_color, 4.0)
	var damage_level := 1.0 - health_ratio
	if damage_level > 0.22:
		draw_line(Vector2(-body_radius * 0.55, -body_radius * 0.2), Vector2(-body_radius * 0.1, body_radius * 0.18), Color(0.04, 0.03, 0.05), 2.0)
	if damage_level > 0.48:
		draw_line(Vector2(body_radius * 0.52, -body_radius * 0.32), Vector2(body_radius * 0.12, body_radius * 0.4), Color(0.04, 0.03, 0.05), 2.0)
	if damage_level > 0.72:
		draw_line(Vector2(-body_radius * 0.18, -body_radius * 0.72), Vector2(body_radius * 0.42, -body_radius * 0.18), Color(0.04, 0.03, 0.05), 2.0)
	draw_line(Vector2(-body_radius * 0.65, body_radius + 8.0), Vector2(-body_radius * 0.65 + body_radius * 1.3 * health_ratio, body_radius + 8.0), accent_color, 4.0)


func _add_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = body_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)
	_collision_shape = collision_shape


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed


func _draw_type_details(draw_core_color: Color) -> void:
	match shape_kind:
		"tank":
			draw_rect(Rect2(Vector2(-body_radius * 0.48, -body_radius * 0.42), Vector2(body_radius * 0.96, body_radius * 0.84)), Color(0.12, 0.08, 0.08), true)
			draw_rect(Rect2(Vector2(-body_radius * 0.32, -body_radius * 0.3), Vector2(body_radius * 0.64, body_radius * 0.6)), draw_core_color, true)
			draw_line(Vector2(-body_radius * 0.75, body_radius * 0.7), Vector2(body_radius * 0.75, body_radius * 0.7), accent_color, 4.0)
		"fast":
			var points := PackedVector2Array([
				Vector2(0.0, -body_radius * 0.52),
				Vector2(body_radius * 0.5, 0.0),
				Vector2(0.0, body_radius * 0.52),
				Vector2(-body_radius * 0.5, 0.0)
			])
			draw_colored_polygon(points, draw_core_color)
			draw_polyline(_closed_points(points), accent_color, 2.0, true)
		"shooter":
			var aim := (target_position - global_position).normalized()
			if aim.length_squared() <= 0.001:
				aim = Vector2.RIGHT
			draw_circle(Vector2.ZERO, body_radius * 0.31, draw_core_color)
			draw_line(Vector2.ZERO, aim * (body_radius * 0.82), accent_color, 7.0)
			draw_circle(aim * (body_radius * 0.82), body_radius * 0.1, Color(0.04, 0.04, 0.07))
		_:
			draw_rect(Rect2(Vector2(-body_radius * 0.42, -body_radius * 0.38), Vector2(body_radius * 0.84, body_radius * 0.78)), Color(0.16, 0.12, 0.18), true)
			draw_circle(Vector2.ZERO, body_radius * 0.28, draw_core_color)


func _draw_projectile_shield() -> void:
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.016)
	var block_ratio: float = clamp(_projectile_shield_block_flash_remaining / 0.18, 0.0, 1.0)
	var radius: float = body_radius + projectile_shield_radius_bonus + pulse * 2.0 + block_ratio * 4.0
	draw_circle(Vector2.ZERO, radius, Color(0.28, 0.9, 1.0, 0.09 + block_ratio * 0.12))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 44, Color(0.52, 1.0, 0.95, 0.58 + block_ratio * 0.32), 3.0 + block_ratio * 1.5)
	draw_arc(Vector2.ZERO, radius * 0.82, PI * 0.12, PI * 1.88, 36, Color(1.0, 1.0, 0.78, 0.36 + block_ratio * 0.34), 2.0)


func _try_emit_shot() -> void:
	var to_target := target_position - global_position
	if to_target.length_squared() <= 4.0:
		return
	var shot_direction := to_target.normalized()
	var shot_origin := global_position + shot_direction * (body_radius + projectile_radius + 5.0)
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		return
	if _wall_blocks_segment(global_position, target_position) or _wall_blocks_segment(global_position, shot_origin):
		return
	var shot_config := {
		"speed": projectile_speed,
		"damage": projectile_damage,
		"radius": projectile_radius,
		"kind": "hostile",
		"projectile_count": max(shot_projectile_count, 1),
		"spread_angle_degrees": shot_spread_degrees
	}
	shot_ready.emit(self, shot_origin, shot_direction, shot_config)


func _update_projectile_shield(delta: float) -> void:
	var had_visual := _projectile_shield_remaining > 0.0 or _projectile_shield_block_flash_remaining > 0.0
	if _projectile_shield_remaining > 0.0:
		_projectile_shield_remaining = max(_projectile_shield_remaining - delta, 0.0)
	if _projectile_shield_block_flash_remaining > 0.0:
		_projectile_shield_block_flash_remaining = max(_projectile_shield_block_flash_remaining - delta, 0.0)
	if had_visual or _projectile_shield_remaining > 0.0 or _projectile_shield_block_flash_remaining > 0.0:
		queue_redraw()


func _get_general_velocity() -> Vector2:
	if move_speed <= 0.0:
		return Vector2.ZERO
	var to_target := target_position - global_position
	if to_target.length_squared() <= 4.0:
		return Vector2.ZERO
	var distance := to_target.length()
	var direction := to_target / distance
	var radial_velocity := Vector2.ZERO
	if distance > preferred_distance + distance_band:
		radial_velocity = direction * move_speed
	elif distance < preferred_distance - distance_band:
		radial_velocity = -direction * move_speed * 0.72
	var orbit_scale := 1.0
	if distance < preferred_distance + distance_band:
		orbit_scale = 0.5
	var strafe_velocity := direction.orthogonal() * _strafe_sign * strafe_speed * orbit_scale
	return radial_velocity + strafe_velocity


func _wall_blocks_segment(from_position: Vector2, to_position: Vector2) -> bool:
	for wall_rect in wall_rects:
		if _segment_intersects_rect(from_position, to_position, wall_rect.grow(max(projectile_radius, 2.0))):
			return true
	if not is_inside_tree() or from_position.distance_squared_to(to_position) <= 0.001:
		return false
	var world := get_world_2d()
	if world == null:
		return false
	var query := PhysicsRayQueryParameters2D.create(from_position, to_position, 32, [get_rid()])
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result := world.direct_space_state.intersect_ray(query)
	return not result.is_empty()


func _segment_intersects_rect(from_position: Vector2, to_position: Vector2, rect: Rect2) -> bool:
	if rect.has_point(from_position) or rect.has_point(to_position):
		return true
	var top_left := rect.position
	var top_right := rect.position + Vector2(rect.size.x, 0.0)
	var bottom_right := rect.position + rect.size
	var bottom_left := rect.position + Vector2(0.0, rect.size.y)
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
	var r := b - a
	var s := d - c
	var denominator := r.cross(s)
	var c_to_a := c - a
	if abs(denominator) <= 0.001:
		if abs(c_to_a.cross(r)) > 0.001:
			return false
		var use_x: bool = abs(r.x) >= abs(r.y)
		var a0: float = a.x if use_x else a.y
		var b0: float = b.x if use_x else b.y
		var c0: float = c.x if use_x else c.y
		var d0: float = d.x if use_x else d.y
		return max(min(a0, b0), min(c0, d0)) <= min(max(a0, b0), max(c0, d0))
	var t := c_to_a.cross(s) / denominator
	var u := c_to_a.cross(r) / denominator
	return t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0
