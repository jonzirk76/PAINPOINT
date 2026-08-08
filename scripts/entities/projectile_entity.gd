extends Area2D
class_name ProjectileEntity

signal hit_detected(projectile, target: Node)
signal expired(projectile)

const HOSTILE_PROJECTILE_COLLISION_MASK := 33
const PLAYER_PROJECTILE_COLLISION_MASK := 178
const ROCKET_KIND := "rocket"
const AGENT_GRENADE_KIND := "agent_grenade"
const AGENT_MINE_KIND := "agent_mine"
const HE_TARGET_RETICLE_MIN_RADIUS := 26.0
const HE_TARGET_RETICLE_MAX_RADIUS := 88.0

@export var speed: float = 560.0
@export var lifetime_seconds: float = 1.2
@export var body_radius: float = 6.0
@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var arena_shape: int = 0
@export var projectile_team: String = "player"
## Hides projectile visuals until the projectile has traveled this far from its collision spawn point.
@export var visual_reveal_distance: float = 0.0
## Controls how high hostile grenades visually lift while traveling.
@export var hostile_grenade_arc_height: float = 34.0
## [Description] Controls the procedural projectile animation refresh rate without changing projectile movement or collision cadence.
@export_range(15.0, 60.0, 1.0) var visual_refresh_rate: float = 30.0

var direction: Vector2 = Vector2.RIGHT
var damage_packet = null
var pierce_remaining: int = 0
var hit_targets: Array[Node] = []
var last_expire_reason: String = ""
var last_expire_position: Vector2 = Vector2.ZERO
var last_expire_direction: Vector2 = Vector2.RIGHT
var last_expire_radius: float = 6.0
var _age: float = 0.0
var _distance_traveled: float = 0.0
var _is_expired: bool = false
var _base_body_radius: float = 6.0
var _collision_shape: CollisionShape2D = null
var _agent_mine_arming_remaining: float = 0.0
var _agent_mine_arming_duration: float = 0.0
var _agent_mine_target_position: Vector2 = Vector2.INF
var _hostile_he_target_position: Vector2 = Vector2.INF
var _hostile_he_target_radius: float = 0.0
var _hostile_he_target_reticle_enabled: bool = false
var _visual_rotation_offset: float = 0.0
var _collision_add_deferred: bool = false
var _visual_refresh_remaining: float = 0.0
var _projectile_visual: ProjectileVisual = null


func _init() -> void:
	_configure_collision_identity()
	_add_collision()


func _ready() -> void:
	_projectile_visual = get_node_or_null("ProjectileVisual") as ProjectileVisual
	_configure_collision_identity()
	_add_collision()
	body_entered.connect(_on_body_entered)
	_update_projectile_visual()
	queue_redraw()


func _configure_collision_identity() -> void:
	_set_area_collision_property("collision_layer", 4)
	_set_area_collision_property("collision_mask", HOSTILE_PROJECTILE_COLLISION_MASK if projectile_team == "hostile" else PLAYER_PROJECTILE_COLLISION_MASK)
	_set_area_collision_property("monitoring", true)
	_set_area_collision_property("monitorable", false)
	_configure_projectile_kind_behavior()


func initialize(origin: Vector2, shot_direction: Vector2, packet, projectile_speed: float, reveal_distance: float = 0.0) -> void:
	global_position = origin
	if shot_direction.length_squared() > 0.001:
		direction = shot_direction.normalized()
	damage_packet = packet
	speed = projectile_speed
	visual_reveal_distance = max(reveal_distance, 0.0)
	_distance_traveled = 0.0
	visible = visual_reveal_distance <= 0.0
	pierce_remaining = packet.pierce_count if packet != null else 0
	_base_body_radius = body_radius * max(packet.projectile_size_multiplier if packet != null else 1.0, 0.1)
	body_radius = _base_body_radius
	_configure_projectile_kind_behavior()
	_update_collision_radius()
	rotation = direction.angle() + _visual_rotation_offset
	_update_projectile_visual()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _is_expired:
		return
	_age += delta
	if _is_agent_mine_arming():
		_update_agent_mine_throw(delta)
		if _age >= lifetime_seconds:
			expire("lifetime", global_position)
		return
	var previous_position := global_position
	var next_position := global_position + direction * speed * delta
	var step_distance: float = previous_position.distance_to(next_position)
	global_position = next_position
	_distance_traveled += step_distance
	_update_projectile_visual_offset()
	if not visible and _distance_traveled >= visual_reveal_distance:
		visible = true
	# Area monitoring is sufficient when the projectile advances by no more than its
	# radius. Reserve the direct-space ray query for steps that could tunnel.
	if step_distance > body_radius:
		_check_swept_hit(previous_position, next_position)
	if not _is_expired and not ArenaGeometry.contains_point(global_position, arena_bounds, arena_shape):
		expire("bounds", global_position)
		return
	_update_growth(delta)
	_visual_refresh_remaining -= delta
	if _uses_procedural_overlay() and _visual_refresh_remaining <= 0.0:
		queue_redraw()
		_visual_refresh_remaining = 1.0 / max(visual_refresh_rate, 1.0)
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


func configure_hostile_metadata(shot_config: Dictionary) -> void:
	var projectile_kind: String = String(shot_config.get("kind", ""))
	var configured_target: Variant = shot_config.get("target_position", Vector2.INF)
	if bool(shot_config.get("show_target_reticle", false)) and configured_target is Vector2 and _is_hostile_he_projectile_kind(projectile_kind):
		_hostile_he_target_position = configured_target
		_hostile_he_target_radius = clamp(float(shot_config.get("target_reticle_radius", shot_config.get("explosion_radius", body_radius * 4.0))), HE_TARGET_RETICLE_MIN_RADIUS, HE_TARGET_RETICLE_MAX_RADIUS)
		_hostile_he_target_reticle_enabled = true
	if projectile_kind == AGENT_MINE_KIND:
		_agent_mine_arming_duration = max(float(shot_config.get("arming_seconds", 0.0)), 0.0)
		_agent_mine_arming_remaining = _agent_mine_arming_duration
		if configured_target is Vector2:
			_agent_mine_target_position = configured_target
	_visual_rotation_offset = float(shot_config.get("visual_rotation_offset", 0.0))


func _configure_projectile_kind_behavior() -> void:
	if projectile_team != "hostile" or damage_packet == null:
		return
	match String(damage_packet.projectile_kind):
		AGENT_GRENADE_KIND:
			_set_area_collision_property("collision_mask", 0)
		AGENT_MINE_KIND:
			if _is_agent_mine_arming():
				_set_area_collision_property("collision_mask", 0)
			else:
				_set_area_collision_property("collision_mask", 1)
				speed = 0.0


func _is_hostile_he_projectile_kind(projectile_kind: String) -> bool:
	return projectile_kind == ROCKET_KIND or projectile_kind == AGENT_GRENADE_KIND or projectile_kind == AGENT_MINE_KIND


func _is_agent_mine_arming() -> bool:
	return damage_packet != null and String(damage_packet.projectile_kind) == AGENT_MINE_KIND and _agent_mine_arming_remaining > 0.0


func _update_agent_mine_throw(delta: float) -> void:
	var previous_position: Vector2 = global_position
	var next_position: Vector2 = global_position + direction * speed * delta
	_agent_mine_arming_remaining = max(_agent_mine_arming_remaining - delta, 0.0)
	if _agent_mine_target_position != Vector2.INF:
		var step_distance: float = previous_position.distance_to(next_position)
		if _agent_mine_arming_remaining <= 0.0 or previous_position.distance_to(_agent_mine_target_position) <= step_distance + 1.0:
			global_position = _agent_mine_target_position
			_land_agent_mine()
		else:
			global_position = next_position
	else:
		global_position = next_position
		if _agent_mine_arming_remaining <= 0.0:
			_land_agent_mine()
	if not _is_expired and not ArenaGeometry.contains_point(global_position, arena_bounds, arena_shape):
		expire("bounds", global_position)
		return
	queue_redraw()


func _land_agent_mine() -> void:
	_agent_mine_arming_remaining = 0.0
	speed = 0.0
	_set_area_collision_property("collision_mask", 1)
	_update_collision_radius()
	_update_projectile_visual()
	queue_redraw()


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
	_disable_collision_state()
	expired.emit(self)
	queue_free()


func despawn() -> void:
	if _is_expired:
		return
	_is_expired = true
	visible = false
	set_process(false)
	set_physics_process(false)
	_disable_collision_state()
	queue_free()


func _disable_collision_state() -> void:
	_collision_add_deferred = false
	if is_inside_tree() and Engine.is_in_physics_frame():
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		return
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0


func _draw() -> void:
	var projectile_kind: String = String(damage_packet.projectile_kind) if damage_packet != null else ""
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.022 + _age * 18.0)
	if _should_draw_hostile_he_target_reticle():
		_draw_hostile_he_target_reticle(pulse)
	var grenade_arc_progress: float = _get_lifetime_progress() if projectile_kind == AGENT_GRENADE_KIND else 0.0
	var grenade_visual_y_offset: float = _get_lob_visual_y_offset(grenade_arc_progress, maxf(hostile_grenade_arc_height, body_radius * 1.8)) if projectile_kind == AGENT_GRENADE_KIND else 0.0
	if projectile_kind == AGENT_GRENADE_KIND:
		_draw_lob_shadow(grenade_arc_progress, grenade_visual_y_offset, body_radius * 0.76, Color(0.0, 0.0, 0.0, 0.18))
	if projectile_kind == AGENT_GRENADE_KIND:
		var grenade_visual_position: Vector2 = _projectile_visual.position if _projectile_visual != null else Vector2.ZERO
		draw_arc(grenade_visual_position, body_radius * (1.9 + pulse * 0.22), -PI * 0.15, PI * 1.05, 24, Color(1.0, 0.94, 0.24, 0.46), 2.2)
	if damage_packet != null and projectile_kind == AGENT_MINE_KIND:
		if _is_agent_mine_arming():
			var throw_progress: float = 1.0 - clamp(_agent_mine_arming_remaining / max(_agent_mine_arming_duration, 0.001), 0.0, 1.0)
			var throw_height: float = sin(throw_progress * PI) * body_radius * 1.05
			draw_circle(Vector2.DOWN * (throw_height * 0.24 + body_radius * 0.82), body_radius * (0.6 - throw_progress * 0.08), Color(0.0, 0.0, 0.0, 0.14))
			draw_arc(Vector2.ZERO, body_radius * (1.72 + pulse * 0.18), -PI * 0.1, PI * 0.95, 24, Color(1.0, 0.82, 0.16, 0.42), 2.0)
			return
		var armed_duration: float = max(lifetime_seconds - _agent_mine_arming_duration, 0.001)
		var arm_ratio: float = clamp((_age - _agent_mine_arming_duration) / armed_duration, 0.0, 1.0)
		draw_arc(Vector2.ZERO, body_radius * (1.34 + pulse * 0.18), -PI * 0.5, -PI * 0.5 + TAU * arm_ratio, 36, Color(1.0, 0.82, 0.12, 0.72), 2.4)
		draw_circle(Vector2.ZERO, body_radius * (1.85 + pulse * 0.16), Color(1.0, 0.16, 0.08, 0.08))
	if damage_packet != null and projectile_kind == "super" and bool(damage_packet.super_full_charge):
		draw_arc(Vector2.ZERO, body_radius * (1.92 + pulse * 0.35), 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.54 + pulse * 0.28), 3.0)


func _get_lifetime_progress() -> float:
	return clampf(_age / maxf(lifetime_seconds, 0.001), 0.0, 1.0)


func _uses_procedural_overlay() -> bool:
	if damage_packet == null:
		return false
	var projectile_kind: String = String(damage_packet.projectile_kind)
	return _should_draw_hostile_he_target_reticle() or projectile_kind == AGENT_GRENADE_KIND or projectile_kind == AGENT_MINE_KIND or (projectile_kind == "super" and bool(damage_packet.super_full_charge))


func _update_projectile_visual() -> void:
	if _projectile_visual == null:
		_projectile_visual = get_node_or_null("ProjectileVisual") as ProjectileVisual
	if _projectile_visual == null:
		return
	var projectile_kind: String = String(damage_packet.projectile_kind) if damage_packet != null else "normal"
	_projectile_visual.configure(projectile_team, projectile_kind, body_radius)
	_update_projectile_visual_offset()


func _update_projectile_visual_offset() -> void:
	if _projectile_visual == null or damage_packet == null:
		return
	if String(damage_packet.projectile_kind) == AGENT_GRENADE_KIND:
		var progress: float = _get_lifetime_progress()
		var arc_height: float = maxf(hostile_grenade_arc_height, body_radius * 1.8)
		_projectile_visual.position = _get_screen_space_local_offset(Vector2(0.0, _get_lob_visual_y_offset(progress, arc_height)))
	else:
		_projectile_visual.position = Vector2.ZERO


func _get_lob_visual_y_offset(progress: float, arc_height: float) -> float:
	return -sin(clampf(progress, 0.0, 1.0) * PI) * maxf(arc_height, 0.0)


func _get_screen_space_local_offset(offset: Vector2) -> Vector2:
	return to_local(global_position + offset)


func _draw_lob_shadow(progress: float, visual_y_offset: float, radius: float, shadow_color: Color) -> void:
	var height: float = absf(visual_y_offset)
	var shadow_center: Vector2 = _get_screen_space_local_offset(Vector2(0.0, height * 0.22 + body_radius * 0.9))
	var shadow_radius: float = maxf(radius * (1.0 - clampf(progress, 0.0, 1.0) * 0.16), 1.0)
	draw_circle(shadow_center, shadow_radius, shadow_color)


func _should_draw_hostile_he_target_reticle() -> bool:
	if not _hostile_he_target_reticle_enabled or projectile_team != "hostile" or damage_packet == null:
		return false
	if _hostile_he_target_position == Vector2.INF:
		return false
	var projectile_kind: String = String(damage_packet.projectile_kind)
	if projectile_kind == AGENT_MINE_KIND:
		return _is_agent_mine_arming()
	return projectile_kind == ROCKET_KIND or projectile_kind == AGENT_GRENADE_KIND


func _draw_hostile_he_target_reticle(pulse: float) -> void:
	var projectile_kind: String = String(damage_packet.projectile_kind) if damage_packet != null else ""
	var target_center: Vector2 = to_local(_hostile_he_target_position)
	var progress: float = clamp(_age / max(lifetime_seconds, 0.001), 0.0, 1.0)
	var reticle_color: Color = Color(1.0, 0.34, 0.08, 0.78)
	if projectile_kind == AGENT_GRENADE_KIND:
		reticle_color = Color(1.0, 0.68, 0.14, 0.76)
	elif projectile_kind == AGENT_MINE_KIND:
		reticle_color = Color(1.0, 0.2, 0.08, 0.7)
	var radius: float = clamp(_hostile_he_target_radius, HE_TARGET_RETICLE_MIN_RADIUS, HE_TARGET_RETICLE_MAX_RADIUS)
	var inner_radius: float = max(radius * 0.42, 12.0)
	var rotation_offset: float = progress * TAU
	draw_circle(target_center, radius, Color(reticle_color.r, reticle_color.g, reticle_color.b, 0.04 + pulse * 0.03))
	draw_arc(target_center, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 58, reticle_color, 3.0)
	draw_arc(target_center, inner_radius, rotation_offset, rotation_offset + TAU * 0.52, 34, Color(1.0, 0.94, 0.28, 0.64), 2.0)
	draw_line(target_center + Vector2.LEFT * radius, target_center + Vector2.LEFT * inner_radius, Color(1.0, 0.94, 0.28, 0.56), 2.0)
	draw_line(target_center + Vector2.RIGHT * inner_radius, target_center + Vector2.RIGHT * radius, Color(1.0, 0.94, 0.28, 0.56), 2.0)
	draw_line(target_center + Vector2.UP * radius, target_center + Vector2.UP * inner_radius, Color(1.0, 0.94, 0.28, 0.56), 2.0)
	draw_line(target_center + Vector2.DOWN * inner_radius, target_center + Vector2.DOWN * radius, Color(1.0, 0.94, 0.28, 0.56), 2.0)


func _add_collision() -> void:
	if _collision_shape != null:
		_update_collision_radius()
		return
	if _is_expired:
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
	_update_collision_radius()


func _set_area_collision_property(property_name: StringName, value: Variant) -> void:
	if is_inside_tree() and Engine.is_in_physics_frame():
		set_deferred(property_name, value)
		return
	set(property_name, value)


func _update_growth(_delta: float) -> void:
	if damage_packet == null or damage_packet.projectile_growth_per_second <= 0.0:
		return
	var max_radius: float = _base_body_radius * max(damage_packet.projectile_max_size_multiplier, 1.0)
	var next_radius: float = min(_base_body_radius + _base_body_radius * damage_packet.projectile_growth_per_second * _age, max_radius)
	if is_equal_approx(next_radius, body_radius):
		return
	body_radius = next_radius
	_update_collision_radius()
	if _projectile_visual != null:
		_projectile_visual.set_radius(body_radius)


func _update_collision_radius() -> void:
	if _collision_shape == null or _collision_shape.shape == null:
		return
	_collision_shape.shape.radius = body_radius
