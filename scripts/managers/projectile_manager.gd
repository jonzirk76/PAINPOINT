extends Node
class_name ProjectileManager

signal projectile_hit(projectile, target: Node, damage_packet)
signal projectile_expired(projectile)

@export var projectile_scene: PackedScene = preload("res://scenes/entities/projectile_entity.tscn")
@export var base_projectile_speed: float = 560.0
@export var base_damage: int = 1
@export var base_knockback: float = 95.0
@export var max_active_projectiles: int = 220

const DAMAGE_PACKET_SCRIPT := preload("res://scripts/resources/damage_packet.gd")

var enabled: bool = false
var _projectile_layer: Node = null
var _projectiles: Array = []
var _arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var _arena_shape: int = 0


func initialize(context: Dictionary) -> void:
	_projectile_layer = context.get("projectile_layer", null)


func reset_run() -> void:
	for projectile in _projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	_projectiles.clear()


func set_enabled(value: bool) -> void:
	enabled = value


func set_arena_definition(level_definition) -> void:
	if level_definition == null:
		return
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
		if _projectile_layer != null:
			_projectile_layer.add_child(projectile)
		else:
			add_child(projectile)
		projectile.set_arena_definition(_arena_bounds, _arena_shape)
		projectile.set_projectile_team("player")
		projectile.initialize(origin, shot_direction, packet, base_projectile_speed)
		projectile.hit_detected.connect(_on_projectile_hit)
		projectile.expired.connect(_on_projectile_expired)
		_projectiles.append(projectile)


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


func _spawn_hostile_projectile(origin: Vector2, direction: Vector2, shot_config: Dictionary, shot_speed: float) -> void:
	var packet = _create_hostile_damage_packet(shot_config, origin, direction)
	var projectile = projectile_scene.instantiate()
	projectile.body_radius = float(shot_config.get("radius", 7.0))
	var player_projectile_range: float = base_projectile_speed * projectile.lifetime_seconds
	var requested_lifetime: float = float(shot_config.get("lifetime", 0.0))
	projectile.lifetime_seconds = max(requested_lifetime, player_projectile_range / shot_speed)
	if _projectile_layer != null:
		_projectile_layer.add_child(projectile)
	else:
		add_child(projectile)
	projectile.set_arena_definition(_arena_bounds, _arena_shape)
	projectile.set_projectile_team("hostile")
	projectile.initialize(origin, direction, packet, shot_speed)
	projectile.hit_detected.connect(_on_projectile_hit)
	projectile.expired.connect(_on_projectile_expired)
	_projectiles.append(projectile)


func _create_damage_packet(modifiers: Dictionary, origin: Vector2, direction: Vector2):
	var packet = DAMAGE_PACKET_SCRIPT.new()
	packet.damage = max(roundi(float(base_damage) * float(modifiers.get("damage_multiplier", 1.0))), 1)
	packet.pierce_count = int(modifiers.get("pierce_count", 0))
	packet.chain_count = int(modifiers.get("chain_count", 0))
	packet.chain_radius = float(modifiers.get("chain_radius", 0.0))
	packet.explosion_radius = float(modifiers.get("explosion_radius", 0.0))
	packet.explosion_damage_multiplier = float(modifiers.get("explosion_damage_multiplier", 0.0))
	packet.projectile_size_multiplier = float(modifiers.get("projectile_size_multiplier", 1.0))
	packet.projectile_growth_per_second = float(modifiers.get("projectile_growth_per_second", 0.0))
	packet.projectile_max_size_multiplier = float(modifiers.get("projectile_max_size_multiplier", packet.projectile_size_multiplier))
	packet.projectile_kind = String(modifiers.get("projectile_kind", "normal"))
	packet.knockback = base_knockback
	packet.source_position = origin
	packet.knockback_direction = direction.normalized()
	return packet


func _create_hostile_damage_packet(shot_config: Dictionary, origin: Vector2, direction: Vector2):
	var packet = DAMAGE_PACKET_SCRIPT.new()
	packet.damage = max(int(shot_config.get("damage", 1)), 1)
	packet.pierce_count = 0
	packet.chain_count = 0
	packet.chain_radius = 0.0
	packet.explosion_radius = 0.0
	packet.explosion_damage_multiplier = 0.0
	packet.projectile_size_multiplier = 1.0
	packet.projectile_growth_per_second = 0.0
	packet.projectile_max_size_multiplier = 1.0
	packet.projectile_kind = String(shot_config.get("kind", "hostile"))
	packet.knockback = 0.0
	packet.source_position = origin
	packet.knockback_direction = direction.normalized()
	return packet


func _on_projectile_hit(projectile, target: Node) -> void:
	if projectile == null or not is_instance_valid(projectile):
		return
	projectile_hit.emit(projectile, target, projectile.damage_packet)


func _on_projectile_expired(projectile) -> void:
	_projectiles.erase(projectile)
	projectile_expired.emit(projectile)
