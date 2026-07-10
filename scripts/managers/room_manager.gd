extends Node
class_name RoomManager

signal door_entered(direction: String)

@export var door_scene: PackedScene = preload("res://scenes/entities/door_entity.tscn")
@export var door_depth: float = 28.0
@export var door_width: float = 92.0

var enabled: bool = false
var _door_layer: Node = null
var _doors: Array = []


func initialize(context: Dictionary) -> void:
	_door_layer = context.get("door_layer", null)


func reset_run() -> void:
	clear_doors()


func set_enabled(value: bool) -> void:
	enabled = value
	for door in _doors:
		if is_instance_valid(door):
			door.monitoring = value


func load_room(level_definition, door_infos: Array, doors_unlocked: bool) -> void:
	clear_doors()
	if level_definition == null:
		return
	for door_info in door_infos:
		var direction := String(door_info.get("direction", "north"))
		var target_id := String(door_info.get("target_room_id", ""))
		var target_kind := String(door_info.get("target_room_kind", ""))
		var door = door_scene.instantiate()
		var rect: Rect2 = door_info.get("trigger_rect", _get_door_rect(level_definition.arena_bounds, direction))
		if _door_layer != null:
			_door_layer.add_child(door)
		else:
			add_child(door)
		door.initialize(direction, target_id, rect.get_center(), rect.size, doors_unlocked, target_kind)
		if door_info.has("opening_rect") and door.has_method("set_visual_rect"):
			var opening_rect: Rect2 = door_info["opening_rect"]
			door.set_visual_rect(opening_rect.get_center(), opening_rect.size)
		door.entered.connect(_on_door_entered)
		_doors.append(door)
	set_enabled(enabled)


func clear_doors() -> void:
	for door in _doors:
		if is_instance_valid(door):
			door.queue_free()
	_doors.clear()


func set_doors_unlocked(value: bool) -> void:
	for door in _doors:
		if is_instance_valid(door):
			door.set_unlocked(value)


func get_door_count() -> int:
	return _doors.size()


func _on_door_entered(door) -> void:
	if not enabled or door == null or not is_instance_valid(door):
		return
	door_entered.emit(door.direction)


func _get_door_rect(bounds: Rect2, direction: String) -> Rect2:
	var center := bounds.get_center()
	match direction:
		"north":
			return Rect2(Vector2(center.x - door_width * 0.5, bounds.position.y - door_depth * 0.5), Vector2(door_width, door_depth))
		"south":
			return Rect2(Vector2(center.x - door_width * 0.5, bounds.position.y + bounds.size.y - door_depth * 0.5), Vector2(door_width, door_depth))
		"east":
			return Rect2(Vector2(bounds.position.x + bounds.size.x - door_depth * 0.5, center.y - door_width * 0.5), Vector2(door_depth, door_width))
		"west":
			return Rect2(Vector2(bounds.position.x - door_depth * 0.5, center.y - door_width * 0.5), Vector2(door_depth, door_width))
	return Rect2(center - Vector2(door_width, door_depth) * 0.5, Vector2(door_width, door_depth))
