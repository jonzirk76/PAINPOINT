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


func initialize(context: Dictionary) -> void:
	_projectile_layer = context.get("projectile_layer", null)


func reset_run() -> void:
	for projectile in _projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	_projectiles.clear()


func set_enabled(value: bool) -> void:
	enabled = value


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
		projectile.initialize(origin, shot_direction, packet, base_projectile_speed)
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


func _on_projectile_hit(projectile, target: Node) -> void:
	if projectile == null or not is_instance_valid(projectile):
		return
	projectile_hit.emit(projectile, target, projectile.damage_packet)


func _on_projectile_expired(projectile) -> void:
	_projectiles.erase(projectile)
	projectile_expired.emit(projectile)
