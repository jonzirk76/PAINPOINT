extends Area2D
class_name ProjectileEntity

signal hit_detected(projectile, target: Node)
signal expired(projectile)

const HOSTILE_PROJECTILE_COLLISION_MASK := 33
const PLAYER_PROJECTILE_COLLISION_MASK := 178

@export var speed: float = 560.0
@export var lifetime_seconds: float = 1.2
@export var body_radius: float = 6.0
@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var arena_shape: int = 0
@export var projectile_team: String = "player"

var direction: Vector2 = Vector2.RIGHT
var damage_packet = null
var pierce_remaining: int = 0
var hit_targets: Array[Node] = []
var last_expire_reason: String = ""
var last_expire_position: Vector2 = Vector2.ZERO
var last_expire_direction: Vector2 = Vector2.RIGHT
var last_expire_radius: float = 6.0
var _age: float = 0.0
var _is_expired: bool = false
var _base_body_radius: float = 6.0
var _collision_shape: CollisionShape2D = null


func _init() -> void:
	_configure_collision_identity()


func _ready() -> void:
	_configure_collision_identity()
	_add_collision()
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _configure_collision_identity() -> void:
	collision_layer = 4
	collision_mask = HOSTILE_PROJECTILE_COLLISION_MASK if projectile_team == "hostile" else PLAYER_PROJECTILE_COLLISION_MASK
	monitoring = true
	monitorable = false


func initialize(origin: Vector2, shot_direction: Vector2, packet, projectile_speed: float) -> void:
	global_position = origin
	if shot_direction.length_squared() > 0.001:
		direction = shot_direction.normalized()
	damage_packet = packet
	speed = projectile_speed
	pierce_remaining = packet.pierce_count if packet != null else 0
	_base_body_radius = body_radius * max(packet.projectile_size_multiplier if packet != null else 1.0, 0.1)
	body_radius = _base_body_radius
	_update_collision_radius()
	rotation = direction.angle()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _is_expired:
		return
	_age += delta
	var previous_position := global_position
	var next_position := global_position + direction * speed * delta
	global_position = next_position
	_check_swept_hit(previous_position, next_position)
	if not _is_expired and not ArenaGeometry.contains_point(global_position, arena_bounds, arena_shape):
		expire("bounds", global_position)
		return
	_update_growth(delta)
	queue_redraw()
	if _age >= lifetime_seconds:
		expire("lifetime", global_position)


func _on_body_entered(body: Node) -> void:
	_handle_target_hit(body, global_position)


func set_arena_definition(bounds: Rect2, shape: int) -> void:
	arena_bounds = bounds
	arena_shape = shape


func set_projectile_team(team: String) -> void:
	projectile_team = team
	_configure_collision_identity()


func _handle_target_hit(body: Node, hit_position: Vector2 = Vector2.INF) -> void:
	if _is_expired:
		return
	var resolved_hit_position := global_position if hit_position == Vector2.INF else hit_position
	if body.is_in_group("destructible_props"):
		_handle_destructible_hit(body, resolved_hit_position)
		return
	if body.is_in_group("arena_walls"):
		expire("wall", resolved_hit_position)
		return
	if projectile_team == "hostile":
		if not body.is_in_group("player"):
			return
	else:
		if not body.is_in_group("enemies") and not body.is_in_group("spawners"):
			return
	if damage_packet == null:
		return
	if hit_targets.has(body):
		return
	hit_targets.append(body)
	if damage_packet != null:
		damage_packet.hit_targets = hit_targets.duplicate()
	hit_detected.emit(self, body)
	if _should_force_impact_on_target(body) or pierce_remaining <= 0:
		expire("hit", resolved_hit_position)
	else:
		pierce_remaining -= 1


func _handle_destructible_hit(body: Node, hit_position: Vector2) -> void:
	if damage_packet == null or hit_targets.has(body):
		expire("wall", hit_position)
		return
	hit_targets.append(body)
	damage_packet.hit_targets = hit_targets.duplicate()
	hit_detected.emit(self, body)
	expire("hit", hit_position)


func _should_force_impact_on_target(body: Node) -> bool:
	if damage_packet == null or not bool(damage_packet.impact_on_strong_targets):
		return false
	if body == null or not is_instance_valid(body):
		return false
	if body.has_method("is_projectile_shield_active") and bool(body.is_projectile_shield_active()):
		return true
	if body.is_in_group("destructible_props"):
		return true
	if body.is_in_group("spawners"):
		return true
	if body.has_method("is_super_shot_impact_target"):
		return bool(body.is_super_shot_impact_target())
	return false


func _check_swept_hit(previous_position: Vector2, next_position: Vector2) -> void:
	if _is_expired or previous_position.distance_squared_to(next_position) <= 0.001:
		return
	if not is_inside_tree():
		return
	var world := get_world_2d()
	if world == null:
		return
	var query := PhysicsRayQueryParameters2D.create(previous_position, next_position, collision_mask, [get_rid()])
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result := world.direct_space_state.intersect_ray(query)
	if result.is_empty():
		return
	var collider = result.get("collider", null)
	if collider is Node:
		_handle_target_hit(collider, result.get("position", global_position))


func expire(reason: String = "expired", expire_position: Vector2 = Vector2.INF) -> void:
	if _is_expired:
		return
	last_expire_reason = reason
	last_expire_position = global_position if expire_position == Vector2.INF else expire_position
	last_expire_direction = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	last_expire_radius = body_radius
	global_position = last_expire_position
	_is_expired = true
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	expired.emit(self)
	queue_free()


func despawn() -> void:
	if _is_expired:
		return
	_is_expired = true
	visible = false
	set_process(false)
	set_physics_process(false)
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	queue_free()


func _draw() -> void:
	var fill_color := Color(1.0, 0.92, 0.24)
	var streak_color := Color(1.0, 0.42, 0.08)
	if damage_packet != null:
		if projectile_team == "hostile":
			fill_color = Color(0.9, 0.18, 1.0)
			streak_color = Color(0.34, 0.95, 1.0)
		else:
			match damage_packet.projectile_kind:
				"fire":
					fill_color = Color(1.0, 0.26, 0.08)
					streak_color = Color(1.0, 0.82, 0.16)
				"water":
					fill_color = Color(0.18, 0.62, 1.0)
					streak_color = Color(0.75, 0.95, 1.0)
				"super":
					fill_color = Color(1.0, 0.86, 0.18)
					streak_color = Color(0.28, 1.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.022 + _age * 18.0)
	var glow_color := Color(fill_color.r, fill_color.g, fill_color.b, 0.2 + pulse * 0.32)
	var glow_points := _build_lemon_points(body_radius * (1.95 + pulse * 0.25), body_radius * (1.05 + pulse * 0.12))
	var body_points := _build_lemon_points(body_radius * 1.58, body_radius * 0.82)
	var outline_points := body_points.duplicate()
	outline_points.append(body_points[0])
	draw_colored_polygon(glow_points, glow_color)
	draw_colored_polygon(body_points, fill_color)
	draw_polyline(outline_points, Color(0.08, 0.07, 0.03, 0.85), 2.0, true)
	draw_line(Vector2(-body_radius * 0.75, -body_radius * 0.18), Vector2(body_radius * 0.72, -body_radius * 0.18), Color(1.0, 1.0, 1.0, 0.45 + pulse * 0.35), 2.0)
	draw_line(Vector2(-body_radius * 0.35, body_radius * 0.26), Vector2(body_radius * 0.52, body_radius * 0.16), streak_color, 2.0)
	if damage_packet != null and String(damage_packet.projectile_kind) == "super" and bool(damage_packet.super_full_charge):
		draw_arc(Vector2.ZERO, body_radius * (1.92 + pulse * 0.35), 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.54 + pulse * 0.28), 3.0)


func _add_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = body_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)
	_collision_shape = collision_shape


func _update_growth(_delta: float) -> void:
	if damage_packet == null or damage_packet.projectile_growth_per_second <= 0.0:
		return
	var max_radius: float = _base_body_radius * max(damage_packet.projectile_max_size_multiplier, 1.0)
	body_radius = min(_base_body_radius + _base_body_radius * damage_packet.projectile_growth_per_second * _age, max_radius)
	_update_collision_radius()
	queue_redraw()


func _update_collision_radius() -> void:
	if _collision_shape == null or _collision_shape.shape == null:
		return
	_collision_shape.shape.radius = body_radius


func _build_lemon_points(length_radius: float, height_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 24
	for index in range(segments):
		var angle: float = TAU * float(index) / float(segments)
		var x: float = cos(angle) * length_radius
		var point_factor: float = 1.0 - abs(cos(angle)) * 0.72
		var y: float = sin(angle) * height_radius * point_factor
		points.append(Vector2(x, y))
	return points
