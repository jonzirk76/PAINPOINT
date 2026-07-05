extends Node
class_name DestructibleManager

signal prop_destroyed(prop, score_value: int, drop_kind: String)

@export var destructible_scene: PackedScene = preload("res://scenes/entities/destructible_prop_entity.tscn")

var enabled: bool = false
var _destructible_layer: Node = null
var _destructibles: Array = []
var _level_definition = null


func initialize(context: Dictionary) -> void:
	_destructible_layer = context.get("destructible_layer", null)


func reset_run(level_definition = null) -> void:
	clear_destructibles()
	_level_definition = level_definition
	if _level_definition == null:
		return
	for placement in _level_definition.destructible_prop_placements:
		_spawn_destructible(placement)


func clear_destructibles() -> void:
	for prop in _destructibles:
		if is_instance_valid(prop):
			prop.queue_free()
	_destructibles.clear()


func set_enabled(value: bool) -> void:
	enabled = value


func apply_damage(target: Node, packet) -> bool:
	if not enabled or target == null or packet == null or not is_instance_valid(target):
		return false
	if not target.is_in_group("destructible_props") or not target.has_method("take_damage"):
		return false
	if not _destructibles.has(target):
		return false
	return bool(target.take_damage(packet))


func get_nearby_destructibles(origin: Vector2, radius: float, excluded: Array[Node]) -> Array:
	var candidates: Array = []
	var radius_squared := radius * radius
	for prop in _destructibles:
		if not is_instance_valid(prop) or excluded.has(prop):
			continue
		if prop.global_position.distance_squared_to(origin) <= radius_squared:
			candidates.append(prop)
	candidates.sort_custom(func(a, b) -> bool:
		return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin)
	)
	return candidates


func get_destructible_count() -> int:
	return _destructibles.size()


func _spawn_destructible(placement):
	if placement == null:
		return null
	var prop = destructible_scene.instantiate()
	if _destructible_layer != null:
		_destructible_layer.add_child(prop)
	else:
		add_child(prop)
	prop.initialize(placement)
	prop.health_depleted.connect(_on_prop_health_depleted)
	_destructibles.append(prop)
	return prop


func _on_prop_health_depleted(prop) -> void:
	if not _destructibles.has(prop):
		return
	_destructibles.erase(prop)
	if _level_definition != null and prop.placement_resource != null:
		_level_definition.destructible_prop_placements.erase(prop.placement_resource)
	prop_destroyed.emit(prop, int(prop.score_value), String(prop.drop_kind))
	prop.queue_free()
