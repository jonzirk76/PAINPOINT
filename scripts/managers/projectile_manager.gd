extends Node
class_name ProjectileManager

const WALL_OCCLUSION_LAYERS := preload("res://scripts/arena/wall_occlusion_layers.gd")

signal projectile_hit(projectile, target: Node, damage_packet)
signal projectile_expired(projectile, expire_info: Dictionary)

@export var projectile_scene: PackedScene = preload("res://scenes/entities/projectile_entity.tscn")
@export var base_projectile_speed: float = 560.0
@export var base_damage: int = 1
@export var base_knockback: float = 95.0
@export var max_active_projectiles: int = 220
@export var super_projectile_speed_min: float = 520.0
@export var super_projectile_speed_max: float = 740.0
@export var super_projectile_damage_min: int = 4
@export var super_projectile_damage_max: int = 14
@export var super_projectile_knockback_min: float = 185.0
@export var super_projectile_knockback_max: float = 560.0
@export var super_projectile_explosion_radius: float = 122.0
@export var super_projectile_explosion_damage_multiplier: float = 0.68
@export var parry_projectile_ammo_award: int = 1
@export var perfect_parry_projectile_ammo_award: int = 2

const DAMAGE_PACKET_SCRIPT := preload("res://scripts/resources/damage_packet.gd")

var enabled: bool = false
var _projectile_layer: Node = null
var _projectiles: Array = []
var _arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var _arena_shape: int = 0
var _perspective_room_id: String = ""


func initialize(context: Dictionary) -> void:
	_projectile_layer = context.get("projectile_layer", null)


func reset_run() -> void:
	for projectile in _projectiles.duplicate():
		_discard_projectile(projectile)
	_projectiles.clear()
	if _projectile_layer != null:
		for child in _projectile_layer.get_children():
			if child is ProjectileEntity:
				_discard_projectile(child)
	_projectiles.clear()


func set_enabled(value: bool) -> void:
	enabled = value


func set_arena_definition(level_definition) -> void:
	if level_definition == null:
		return
	_perspective_room_id = String(level_definition.get_meta("active_room_id", ""))
	_arena_bounds = level_definition.arena_bounds
	_arena_shape = int(level_definition.arena_shape)
	for projectile in _projectiles:
		if is_instance_valid(projectile):
			projectile.set_arena_definition(_arena_bounds, _arena_shape)


func fire(origin: Vector2, direction: Vector2, modifiers: Dictionary) -> void:
	if not enabled or direction.length_squared() <= 0.001:
		return
	var projectile_count: int = max(int(modifiers.get("projectile_count", 1)), 1)
	var spread_degrees: float = float(modifiers.get("spread_angle_degrees", 0.0))
	var visual_reveal_distance: float = max(float(modifiers.get("visual_reveal_distance", 0.0)), 0.0)
	var base_angle := direction.normalized().angle()
	var start_angle := base_angle
	var angle_step := 0.0
	if projectile_count > 1:
		angle_step = deg_to_rad(spread_degrees) / float(projectile_count - 1)
		start_angle = base_angle - deg_to_rad(spread_degrees) * 0.5

	for index in range(projectile_count):
		if _projectiles.size() >= max_active_projectiles:
			return
		var shot_angle := start_angle + angle_step * float(index)
		var shot_direction := Vector2.RIGHT.rotated(shot_angle)
		var packet = _create_damage_packet(modifiers, origin, shot_direction)
		var projectile = projectile_scene.instantiate()
		WALL_OCCLUSION_LAYERS.mark_entity_tree(projectile, _perspective_room_id)
		projectile.set_arena_definition(_arena_bounds, _arena_shape)
		projectile.set_projectile_team("player")
		projectile.initialize(origin, shot_direction, packet, base_projectile_speed, visual_reveal_distance)
		projectile.hit_detected.connect(_on_projectile_hit)
		projectile.expired.connect(_on_projectile_expired)
		_projectiles.append(projectile)
		_add_child_safely(_get_projectile_parent(), projectile)


func fire_super_shot(origin: Vector2, direction: Vector2, charge_ratio: float, visual_reveal_distance: float = 0.0) -> void:
	if not enabled or direction.length_squared() <= 0.001 or _projectiles.size() >= max_active_projectiles:
		return
	var shot_direction := direction.normalized()
	var normalized_charge: float = clamp(charge_ratio, 0.08, 1.0)
	var packet = _create_super_damage_packet(origin, shot_direction, normalized_charge)
	var reveal_distance: float = max(visual_reveal_distance, 0.0)
	var projectile = projectile_scene.instantiate()
	WALL_OCCLUSION_LAYERS.mark_entity_tree(projectile, _perspective_room_id)
	projectile.lifetime_seconds = 1.55
	projectile.set_arena_definition(_arena_bounds, _arena_shape)
	projectile.set_projectile_team("player")
	projectile.initialize(origin, shot_direction, packet, lerp(super_projectile_speed_min, super_projectile_speed_max, normalized_charge), reveal_distance)
	projectile.hit_detected.connect(_on_projectile_hit)
	projectile.expired.connect(_on_projectile_expired)
	_projectiles.append(projectile)
	_add_child_safely(_get_projectile_parent(), projectile)


func fire_hostile(origin: Vector2, direction: Vector2, shot_config: Dictionary) -> void:
	if not enabled or direction.length_squared() <= 0.001 or _projectiles.size() >= max_active_projectiles:
		return
	var shot_direction := direction.normalized()
	var shot_speed: float = max(float(shot_config.get("speed", 250.0)), 1.0)
	var projectile_count: int = max(int(shot_config.get("projectile_count", 1)), 1)
	var spread_degrees: float = float(shot_config.get("spread_angle_degrees", 0.0))
	var base_angle := shot_direction.angle()
	var angle_step := 0.0
	var start_angle := base_angle
	if projectile_count > 1:
		angle_step = deg_to_rad(spread_degrees) / float(projectile_count - 1)
		start_angle = base_angle - deg_to_rad(spread_degrees) * 0.5
	for index in range(projectile_count):
		if _projectiles.size() >= max_active_projectiles:
			return
		var projectile_direction := Vector2.RIGHT.rotated(start_angle + angle_step * float(index))
		_spawn_hostile_projectile(origin, projectile_direction, shot_config, shot_speed)


func absorb_hostile_projectiles(origin: Vector2, radius: float, perfect_radius: float) -> Dictionary:
	var absorbed_count := 0
	var perfect_count := 0
	var ammo_awarded := 0
	var absorbed_projectiles: Array[Dictionary] = []
	for projectile in _projectiles.duplicate():
		if not is_instance_valid(projectile):
			_projectiles.erase(projectile)
			continue
		if projectile.projectile_team != "hostile":
			continue
		var projectile_radius: float = float(projectile.body_radius)
		var distance_squared: float = projectile.global_position.distance_squared_to(origin)
		var effect_radius: float = radius + projectile_radius
		if distance_squared > effect_radius * effect_radius:
			continue
		var perfect_effect_radius: float = perfect_radius + projectile_radius
		var is_perfect: bool = distance_squared <= perfect_effect_radius * perfect_effect_radius
		absorbed_count += 1
		if is_perfect:
			perfect_count += 1
			ammo_awarded += perfect_parry_projectile_ammo_award
		else:
			ammo_awarded += parry_projectile_ammo_award
		absorbed_projectiles.append({
			"position": projectile.global_position,
			"perfect": is_perfect,
			"radius": projectile_radius
		})
		projectile.expire("absorbed", projectile.global_position)
	return {
		"absorbed_count": absorbed_count,
		"perfect_count": perfect_count,
		"ammo_awarded": ammo_awarded,
		"absorbed_projectiles": absorbed_projectiles
	}


func has_hostile_projectile_in_radius(origin: Vector2, radius: float) -> bool:
	var effect_radius: float = max(radius, 0.0)
	for projectile in _projectiles:
		if not is_instance_valid(projectile):
			continue
		if String(projectile.projectile_team) != "hostile":
			continue
		var projectile_radius: float = float(projectile.body_radius)
		var graze_radius: float = effect_radius + projectile_radius
		if projectile.global_position.distance_squared_to(origin) <= graze_radius * graze_radius:
			return true
	return false


func get_player_projectile_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for projectile in _projectiles:
		if projectile == null or not is_instance_valid(projectile):
			continue
		if String(projectile.projectile_team) != "player":
			continue
		positions.append(projectile.global_position)
	return positions


func _spawn_hostile_projectile(origin: Vector2, direction: Vector2, shot_config: Dictionary, shot_speed: float) -> void:
	var packet = _create_hostile_damage_packet(shot_config, origin, direction)
	var projectile = projectile_scene.instantiate()
	WALL_OCCLUSION_LAYERS.mark_entity_tree(projectile, _perspective_room_id)
	projectile.body_radius = float(shot_config.get("radius", 7.0))
	var player_projectile_range: float = base_projectile_speed * projectile.lifetime_seconds
	var requested_lifetime: float = float(shot_config.get("lifetime", 0.0))
	if bool(shot_config.get("exact_lifetime", false)):
		projectile.lifetime_seconds = max(requested_lifetime, 0.05)
	else:
		projectile.lifetime_seconds = max(requested_lifetime, player_projectile_range / shot_speed)
	projectile.set_arena_definition(_arena_bounds, _arena_shape)
	projectile.set_projectile_team("hostile")
	if projectile.has_method("configure_hostile_metadata"):
		projectile.configure_hostile_metadata(shot_config)
	projectile.initialize(origin, direction, packet, shot_speed)
	projectile.hit_detected.connect(_on_projectile_hit)
	projectile.expired.connect(_on_projectile_expired)
	_projectiles.append(projectile)
	_add_child_safely(_get_projectile_parent(), projectile)


func _create_damage_packet(modifiers: Dictionary, origin: Vector2, direction: Vector2):
	var packet = DAMAGE_PACKET_SCRIPT.new()
	packet.damage = max(roundi(float(base_damage) * float(modifiers.get("damage_multiplier", 1.0))), 1)
	packet.pierce_count = int(modifiers.get("pierce_count", 0))
	packet.chain_count = int(modifiers.get("chain_count", 0))
	packet.chain_radius = float(modifiers.get("chain_radius", 0.0))
	packet.explosion_radius = float(modifiers.get("explosion_radius", 0.0))
	packet.explosion_damage_multiplier = float(modifiers.get("explosion_damage_multiplier", 0.0))
	packet.burn_damage_per_second = float(modifiers.get("burn_damage_per_second", 0.0))
	packet.burn_duration_seconds = float(modifiers.get("burn_duration_seconds", 0.0))
	packet.slow_multiplier = float(modifiers.get("slow_multiplier", 1.0))
	packet.slow_duration_seconds = float(modifiers.get("slow_duration_seconds", 0.0))
	packet.lightning_charge_damage_multiplier = float(modifiers.get("lightning_charge_damage_multiplier", 1.0))
	packet.lightning_charge_required_stacks = int(modifiers.get("lightning_charge_required_stacks", 0))
	packet.lightning_charge_duration_seconds = float(modifiers.get("lightning_charge_duration_seconds", 0.0))
	packet.lightning_charge_max_stacks = int(modifiers.get("lightning_charge_max_stacks", 0))
	packet.projectile_size_multiplier = float(modifiers.get("projectile_size_multiplier", 1.0))
	packet.projectile_growth_per_second = float(modifiers.get("projectile_growth_per_second", 0.0))
	packet.projectile_max_size_multiplier = float(modifiers.get("projectile_max_size_multiplier", packet.projectile_size_multiplier))
	packet.projectile_kind = String(modifiers.get("projectile_kind", "normal"))
	packet.knockback = base_knockback * max(float(modifiers.get("knockback_multiplier", 1.0)), 0.0)
	packet.source_position = origin
	packet.knockback_direction = direction.normalized()
	return packet


func _get_projectile_parent() -> Node:
	return _projectile_layer if _projectile_layer != null else self


func _add_child_safely(parent: Node, child: Node) -> void:
	if parent == null or child == null or child.get_parent() != null:
		return
	if parent.is_inside_tree() and Engine.is_in_physics_frame():
		parent.call_deferred("add_child", child)
		return
	parent.add_child(child)


func _create_super_damage_packet(origin: Vector2, direction: Vector2, charge_ratio: float):
	var ratio: float = clamp(charge_ratio, 0.08, 1.0)
	var power_curve: float = pow(ratio, 1.12)
	var packet = DAMAGE_PACKET_SCRIPT.new()
	packet.damage = max(roundi(lerp(float(super_projectile_damage_min), float(super_projectile_damage_max), power_curve)), 1)
	packet.pierce_count = 999
	packet.chain_count = 0
	packet.chain_radius = 0.0
	packet.explosion_radius = super_projectile_explosion_radius if ratio >= 0.995 else 0.0
	packet.explosion_damage_multiplier = super_projectile_explosion_damage_multiplier if ratio >= 0.995 else 0.0
	packet.projectile_size_multiplier = lerp(1.65, 4.25, ratio)
	packet.projectile_growth_per_second = 0.0
	packet.projectile_max_size_multiplier = packet.projectile_size_multiplier
	packet.projectile_kind = "super"
	packet.knockback = lerp(super_projectile_knockback_min, super_projectile_knockback_max, power_curve)
	packet.source_position = origin
	packet.knockback_direction = direction.normalized()
	packet.impact_on_strong_targets = true
	packet.pierces_projectile_shields = true
	packet.shield_damage_multiplier = 0.55
	packet.shield_knockback_multiplier = 0.42
	packet.super_charge_ratio = ratio
	packet.super_full_charge = ratio >= 0.995
	return packet


func _create_hostile_damage_packet(shot_config: Dictionary, origin: Vector2, direction: Vector2):
	var packet = DAMAGE_PACKET_SCRIPT.new()
	packet.damage = max(int(shot_config.get("damage", 1)), 1)
	packet.pierce_count = 0
	packet.chain_count = 0
	packet.chain_radius = 0.0
	packet.explosion_radius = float(shot_config.get("explosion_radius", 0.0))
	packet.explosion_damage_multiplier = float(shot_config.get("explosion_damage_multiplier", 0.0))
	packet.projectile_size_multiplier = 1.0
	packet.projectile_growth_per_second = 0.0
	packet.projectile_max_size_multiplier = 1.0
	packet.projectile_kind = String(shot_config.get("kind", "hostile"))
	packet.knockback = max(float(shot_config.get("knockback", 0.0)), 0.0)
	packet.source_position = origin
	packet.knockback_direction = direction.normalized()
	return packet


func _on_projectile_hit(projectile, target: Node) -> void:
	if projectile == null or not is_instance_valid(projectile):
		return
	projectile_hit.emit(projectile, target, projectile.damage_packet)


func _on_projectile_expired(projectile) -> void:
	_projectiles.erase(projectile)
	projectile_expired.emit(projectile, _get_projectile_expire_info(projectile))


func _get_projectile_expire_info(projectile) -> Dictionary:
	if projectile == null or not is_instance_valid(projectile):
		return {}
	var packet = projectile.damage_packet
	return {
		"reason": String(projectile.last_expire_reason),
		"position": projectile.last_expire_position,
		"direction": projectile.last_expire_direction,
		"radius": float(projectile.last_expire_radius),
		"team": String(projectile.projectile_team),
		"kind": String(packet.projectile_kind) if packet != null else "normal",
		"damage_packet": packet
	}


func _discard_projectile(projectile) -> void:
	if projectile == null or not is_instance_valid(projectile):
		return
	_projectiles.erase(projectile)
	if projectile.has_signal("hit_detected"):
		var hit_callable := Callable(self, "_on_projectile_hit")
		if projectile.hit_detected.is_connected(hit_callable):
			projectile.hit_detected.disconnect(hit_callable)
	if projectile.has_signal("expired"):
		var expired_callable := Callable(self, "_on_projectile_expired")
		if projectile.expired.is_connected(expired_callable):
			projectile.expired.disconnect(expired_callable)
	if projectile.has_method("despawn"):
		projectile.despawn()
	elif projectile is Node:
		projectile.hide()
		projectile.queue_free()
