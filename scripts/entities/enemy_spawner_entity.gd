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
@export var special_attack_kind: String = ""
@export var special_cooldown: float = 5.8
@export var special_telegraph_seconds: float = 0.58
@export var special_minigun_duration: float = 0.55
@export var special_minigun_shot_interval: float = 0.08
@export var special_minigun_sweep_degrees: float = 58.0
@export var special_rocket_recoil: float = 145.0
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
@export var void_rects: Array[Rect2] = []

var health: int = max_health
var playable_rects: Array[Rect2] = []
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
var _special_timer: float = 0.0
var _special_telegraph_remaining: float = 0.0
var _special_telegraph_duration: float = 0.58
var _active_special_kind: String = ""
var _minigun_remaining: float = 0.0
var _minigun_elapsed: float = 0.0
var _minigun_next_shot_remaining: float = 0.0
var _minigun_base_direction: Vector2 = Vector2.RIGHT
var _recoil_velocity: Vector2 = Vector2.ZERO
var _crowd_separation_velocity: Vector2 = Vector2.ZERO


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
	collision_mask = 112
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
		var special_active: bool = _update_special_attack(delta)
		if not special_active:
			_shot_timer -= delta
			if _shot_timer <= 0.0:
				_shot_timer = shot_cooldown
				_try_emit_shot()


func _physics_process(_delta: float) -> void:
	if _is_destroyed or not active:
		velocity = Vector2.ZERO
		return
	var intent_velocity: Vector2 = _get_general_velocity()
	if _special_telegraph_remaining > 0.0:
		intent_velocity *= 0.45
	if _minigun_remaining > 0.0:
		intent_velocity = Vector2.ZERO
	velocity = intent_velocity + _recoil_velocity + _crowd_separation_velocity
	move_and_slide()
	if get_slide_collision_count() > 0:
		_strafe_sign *= -1.0
	global_position = _constrain_to_playable(global_position)
	_recoil_velocity = _recoil_velocity.move_toward(Vector2.ZERO, 360.0 * _delta)
	_crowd_separation_velocity = _crowd_separation_velocity.move_toward(Vector2.ZERO, 760.0 * _delta)
	if velocity.length_squared() > 1.0 or _special_telegraph_remaining > 0.0 or _minigun_remaining > 0.0:
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
	special_attack_kind = profile.special_attack_kind
	special_cooldown = profile.special_cooldown
	special_telegraph_seconds = profile.special_telegraph_seconds
	special_minigun_duration = profile.special_minigun_duration
	special_minigun_shot_interval = profile.special_minigun_shot_interval
	special_minigun_sweep_degrees = profile.special_minigun_sweep_degrees
	special_rocket_recoil = profile.special_rocket_recoil
	move_speed = profile.move_speed
	preferred_distance = profile.preferred_distance
	distance_band = profile.distance_band
	strafe_speed = profile.strafe_speed
	_shot_timer = shot_cooldown * 0.5
	_special_timer = special_cooldown * 0.62
	_special_telegraph_remaining = 0.0
	_minigun_remaining = 0.0
	_recoil_velocity = Vector2.ZERO
	_crowd_separation_velocity = Vector2.ZERO


func set_target_position(position: Vector2) -> void:
	target_position = position
	queue_redraw()


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


func take_damage(packet) -> bool:
	if packet == null or health <= 0 or _is_destroyed:
		return false
	if blocks_projectile_damage(packet):
		return false
	var damage_amount: int = max(int(packet.damage), 0)
	if _should_reduce_shield_pierce_damage(packet):
		damage_amount = max(roundi(float(damage_amount) * clamp(float(packet.shield_damage_multiplier), 0.05, 1.0)), 1)
		_projectile_shield_block_flash_remaining = 0.22
	var old_health := health
	health = max(health - damage_amount, 0)
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
	if bool(packet.pierces_projectile_shields):
		return false
	_projectile_shield_block_flash_remaining = 0.18
	queue_redraw()
	return true


func _should_reduce_shield_pierce_damage(packet) -> bool:
	if packet == null or not is_projectile_shield_active():
		return false
	return bool(packet.pierces_projectile_shields) and String(packet.projectile_kind) != "hostile"


func apply_crowd_separation(push_vector: Vector2) -> void:
	if _is_destroyed or push_vector.length_squared() <= 0.001:
		return
	_crowd_separation_velocity += push_vector
	_crowd_separation_velocity = _crowd_separation_velocity.limit_length(120.0)


func _constrain_to_playable(position: Vector2) -> Vector2:
	var blockers: Array[Rect2] = []
	blockers.append_array(wall_rects)
	blockers.append_array(void_rects)
	return ArenaGeometry.constrain_point_to_playable_regions(position, arena_bounds, arena_shape, playable_rects, blockers, body_radius)


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
	if _special_telegraph_remaining > 0.0:
		_draw_special_telegraph()
	if _minigun_remaining > 0.0:
		_draw_minigun_sweep()
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


func _draw_special_telegraph() -> void:
	var progress: float = 1.0 - clamp(_special_telegraph_remaining / max(_special_telegraph_duration, 0.001), 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.045)
	var aim: Vector2 = (target_position - global_position).normalized()
	if aim.length_squared() <= 0.001:
		aim = Vector2.RIGHT
	var telegraph_color: Color = _get_special_telegraph_color()
	var radius: float = body_radius + 10.0 + progress * 14.0 + pulse * 3.0
	draw_circle(Vector2.ZERO, radius, Color(telegraph_color.r, telegraph_color.g, telegraph_color.b, 0.08 + pulse * 0.07))
	draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 46, telegraph_color, 4.0)
	match _active_special_kind:
		"spread":
			for index in range(3):
				var offset: float = deg_to_rad(30.0) * (float(index) - 1.0)
				draw_line(Vector2.ZERO, aim.rotated(offset) * (body_radius + 62.0), Color(1.0, 0.96, 0.58, 0.68), 3.0)
		"rocket":
			draw_line(Vector2.ZERO, aim * (body_radius + 76.0), Color(1.0, 0.42, 0.18, 0.84), 5.0)
			draw_arc(aim * (body_radius + 64.0), 12.0 + pulse * 5.0, 0.0, TAU, 24, Color(1.0, 0.78, 0.22, 0.76), 3.0)
		"minigun":
			var sweep_direction: Vector2 = aim.rotated(sin(progress * PI * 4.0) * 0.46)
			var side: Vector2 = sweep_direction.orthogonal()
			draw_line(side * -body_radius * 0.82, sweep_direction * (body_radius + 72.0), Color(1.0, 0.96, 0.58, 0.72), 4.0)
			draw_line(side * body_radius * 0.82, sweep_direction * (body_radius + 62.0), Color(0.54, 1.0, 1.0, 0.42), 3.0)
		_:
			draw_line(Vector2.ZERO, aim * (body_radius + 58.0), Color(1.0, 0.98, 0.64, 0.7), 4.0)


func _draw_minigun_sweep() -> void:
	var direction: Vector2 = _get_minigun_direction()
	var side: Vector2 = direction.orthogonal()
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.075)
	draw_line(side * -body_radius * 0.75, direction * (body_radius + 82.0), Color(1.0, 0.96, 0.42, 0.68 + pulse * 0.18), 4.0)
	draw_line(side * body_radius * 0.75, direction * (body_radius + 68.0), Color(0.45, 1.0, 1.0, 0.4 + pulse * 0.12), 3.0)
	draw_circle(direction * (body_radius + 30.0), 4.0 + pulse * 1.8, Color(1.0, 0.82, 0.16, 0.72))


func _get_special_telegraph_color() -> Color:
	match _active_special_kind:
		"rocket":
			return Color(1.0, 0.32, 0.12, 0.86)
		"minigun":
			return Color(1.0, 0.92, 0.28, 0.78)
		"spread":
			return Color(0.74, 1.0, 0.34, 0.8)
		_:
			return Color(0.58, 1.0, 1.0, 0.76)


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


func _update_special_attack(delta: float) -> bool:
	if special_attack_kind.is_empty():
		return false
	if _minigun_remaining > 0.0:
		_update_minigun(delta)
		return true
	if _special_telegraph_remaining > 0.0:
		_special_telegraph_remaining = max(_special_telegraph_remaining - delta, 0.0)
		if _special_telegraph_remaining <= 0.0:
			if _active_special_kind == "minigun":
				_start_minigun()
			else:
				_emit_special_shot()
				_finish_special_attack()
		queue_redraw()
		return true
	_special_timer = max(_special_timer - delta, 0.0)
	var to_target: Vector2 = target_position - global_position
	if _special_timer > 0.0 or to_target.length_squared() <= 4.0:
		return false
	if _wall_blocks_segment(global_position, target_position):
		return false
	_active_special_kind = special_attack_kind
	_special_telegraph_duration = max(special_telegraph_seconds, 0.1)
	_special_telegraph_remaining = _special_telegraph_duration
	queue_redraw()
	return true


func _emit_special_shot() -> void:
	var to_target: Vector2 = target_position - global_position
	if to_target.length_squared() <= 4.0:
		return
	var shot_direction: Vector2 = to_target.normalized()
	var shot_config: Dictionary = _get_special_shot_config(_active_special_kind)
	var radius: float = float(shot_config.get("radius", projectile_radius))
	var shot_origin: Vector2 = global_position + shot_direction * (body_radius + radius + 6.0)
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		shot_origin = global_position
	if _active_special_kind == "rocket":
		var target_position_at_launch: Vector2 = target_position
		var target_direction: Vector2 = target_position_at_launch - shot_origin
		if target_direction.length_squared() > 4.0:
			shot_direction = target_direction.normalized()
		var rocket_speed: float = max(float(shot_config.get("speed", projectile_speed)), 1.0)
		shot_config["target_position"] = target_position_at_launch
		shot_config["lifetime"] = max(shot_origin.distance_to(target_position_at_launch) / rocket_speed, 0.08)
		shot_config["exact_lifetime"] = true
		_recoil_velocity += -shot_direction * max(special_rocket_recoil, 0.0)
	shot_ready.emit(self, shot_origin, shot_direction, shot_config)


func _start_minigun() -> void:
	var to_target: Vector2 = target_position - global_position
	if to_target.length_squared() <= 4.0:
		_finish_special_attack()
		return
	_minigun_base_direction = to_target.normalized()
	_minigun_elapsed = 0.0
	_minigun_remaining = max(special_minigun_duration, 0.12)
	_minigun_next_shot_remaining = max(special_minigun_shot_interval, 0.025)
	_emit_minigun_shot()


func _update_minigun(delta: float) -> void:
	var duration: float = max(special_minigun_duration, 0.12)
	_minigun_elapsed = min(_minigun_elapsed + delta, duration)
	_minigun_remaining = max(duration - _minigun_elapsed, 0.0)
	_minigun_next_shot_remaining -= delta
	var interval: float = max(special_minigun_shot_interval, 0.025)
	var emitted_count := 0
	while _minigun_remaining > 0.0 and _minigun_next_shot_remaining <= 0.0 and emitted_count < 8:
		_emit_minigun_shot()
		_minigun_next_shot_remaining += interval
		emitted_count += 1
	if _minigun_remaining <= 0.0:
		_finish_special_attack()
	queue_redraw()


func _emit_minigun_shot() -> void:
	var shot_direction: Vector2 = _get_minigun_direction()
	var shot_config: Dictionary = _get_special_shot_config("minigun")
	var radius: float = float(shot_config.get("radius", projectile_radius))
	var shot_origin: Vector2 = global_position + shot_direction * (body_radius + radius + 6.0)
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		shot_origin = global_position
	shot_ready.emit(self, shot_origin, shot_direction, shot_config)


func _get_minigun_direction() -> Vector2:
	var duration: float = max(special_minigun_duration, 0.12)
	var progress: float = clamp(_minigun_elapsed / duration, 0.0, 1.0)
	var half_sweep: float = deg_to_rad(special_minigun_sweep_degrees) * 0.5
	return _minigun_base_direction.rotated(lerp(-half_sweep, half_sweep, progress)).normalized()


func _finish_special_attack() -> void:
	_minigun_remaining = 0.0
	_minigun_elapsed = 0.0
	_minigun_next_shot_remaining = 0.0
	_special_timer = special_cooldown


func _get_special_shot_config(kind: String) -> Dictionary:
	match kind:
		"rocket":
			return {
				"speed": max(projectile_speed * 3.2, 560.0),
				"damage": max(projectile_damage + 1, 2),
				"radius": max(projectile_radius * 0.9, 11.0),
				"kind": "rocket",
				"projectile_count": 1,
				"spread_angle_degrees": 0.0,
				"knockback": 420.0,
				"explosion_radius": 58.0,
				"explosion_damage_multiplier": 1.0
			}
		"minigun":
			return {
				"speed": projectile_speed * 1.36,
				"damage": projectile_damage,
				"radius": max(projectile_radius * 0.72, 4.8),
				"kind": "hostile_minigun",
				"projectile_count": 1,
				"spread_angle_degrees": 0.0,
				"lifetime": 1.35,
				"knockback": 0.0
			}
		"spread":
			return {
				"speed": max(projectile_speed * 1.14, projectile_speed + 32.0),
				"damage": projectile_damage,
				"radius": projectile_radius,
				"kind": "hostile",
				"projectile_count": 3,
				"spread_angle_degrees": 34.0,
				"knockback": 0.0
			}
		_:
			return {
				"speed": projectile_speed * 1.32,
				"damage": projectile_damage,
				"radius": projectile_radius,
				"kind": "hostile",
				"projectile_count": max(shot_projectile_count, 1),
				"spread_angle_degrees": shot_spread_degrees,
				"lifetime": 1.45,
				"knockback": 0.0
			}


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
