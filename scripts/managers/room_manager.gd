extends Node
class_name RoomManager

const DOOR_WELCOME_MAT_VISUAL_SCRIPT := preload("res://scripts/entities/door_welcome_mat_visual.gd")
const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")

signal door_entered(direction: String, target_room_id: String)

@export var door_scene: PackedScene = preload("res://scenes/entities/door_entity.tscn")
@export var door_depth: float = 28.0
@export var door_width: float = 92.0
## [Description] Slightly darkens the canonical floor tiles immediately inside each doorway.
@export var door_welcome_mat_color: Color = Color(0.12, 0.13, 0.14, 0.72)
## [Description] Controls how many floor tiles each doorway welcome mat extends into the room.
@export_range(1, 3, 1) var door_welcome_mat_depth_tiles: int = 1

var enabled: bool = false
var _door_layer: Node = null
var _door_mat_layer: Node = null
var _doors: Array = []
var _door_welcome_mats: Array[Node2D] = []


func initialize(context: Dictionary) -> void:
	_door_layer = context.get("door_layer", null)
	_door_mat_layer = context.get("door_mat_layer", null)


func reset_run() -> void:
	clear_doors()


func set_enabled(value: bool) -> void:
	enabled = value
	for door in _doors:
		if is_instance_valid(door):
			if door.has_method("set_monitoring_enabled"):
				door.set_monitoring_enabled(value)
			elif door is Area2D:
				door.set_deferred("monitoring", value)


func load_room(level_definition, door_infos: Array, doors_unlocked: bool, welcome_mat_infos: Array = []) -> void:
	clear_doors()
	if level_definition == null:
		return
	for door_info in door_infos:
		var direction := String(door_info.get("direction", "north"))
		var target_id := String(door_info.get("target_room_id", ""))
		var target_kind := String(door_info.get("target_room_kind", ""))
		var door = door_scene.instantiate()
		if door.has_method("set_wall_height_tiles"):
			door.set_wall_height_tiles(int(door_info.get(
				"wall_height_tiles",
				level_definition.get_meta(
					"wall_height_tiles",
					ROOM_GEOMETRY_BUILDER.DEFAULT_WALL_HEIGHT_TILES
				)
			)))
		var rect: Rect2 = door_info.get("trigger_rect", _get_door_rect(level_definition.arena_bounds, direction))
		door.initialize(direction, target_id, rect.get_center(), rect.size, doors_unlocked, target_kind)
		if door_info.has("opening_rect") and door.has_method("set_visual_rect"):
			var opening_rect: Rect2 = door_info["opening_rect"]
			door.set_visual_rect(opening_rect.get_center(), opening_rect.size)
		if door_info.has("passage_rect") and door.has_method("set_passage_rect"):
			var passage_rect: Rect2 = door_info["passage_rect"]
			door.set_passage_rect(passage_rect.get_center(), passage_rect.size)
		door.entered.connect(_on_door_entered)
		_doors.append(door)
		_add_child_safely(_get_door_parent(), door)
	var resolved_mat_infos: Array = welcome_mat_infos if not welcome_mat_infos.is_empty() else door_infos
	for mat_info in resolved_mat_infos:
		if not mat_info is Dictionary or not mat_info.has("opening_rect"):
			continue
		_add_welcome_mat(
			mat_info["opening_rect"],
			String(mat_info.get("direction", "north")),
			String(mat_info.get("source_room_id", ""))
		)
	set_enabled(enabled)


func clear_doors() -> void:
	for welcome_mat in _door_welcome_mats:
		if is_instance_valid(welcome_mat):
			welcome_mat.queue_free()
	_door_welcome_mats.clear()
	for door in _doors:
		if is_instance_valid(door):
			door.queue_free()
	_doors.clear()


func _add_welcome_mat(opening_rect: Rect2, direction: String, room_id: String = "") -> void:
	var welcome_mat = DOOR_WELCOME_MAT_VISUAL_SCRIPT.new()
	welcome_mat.name = "DoorWelcomeMat"
	welcome_mat.configure(
		opening_rect,
		direction,
		door_welcome_mat_depth_tiles,
		door_welcome_mat_color,
		room_id
	)
	_door_welcome_mats.append(welcome_mat)
	_add_child_safely(_get_door_mat_parent(), welcome_mat)


func set_doors_unlocked(value: bool) -> void:
	for door in _doors:
		if is_instance_valid(door):
			door.set_unlocked(value)


func set_only_door_unlocked(unlocked_direction: String) -> void:
	for door_node in _doors:
		var door: DoorEntity = door_node as DoorEntity
		if door == null or not is_instance_valid(door):
			continue
		door.set_unlocked(door.direction == unlocked_direction)


func get_door_count() -> int:
	return _doors.size()


func get_gate_blocker_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for door in _doors:
		if is_instance_valid(door) and door.has_method("is_gate_blocking") and bool(door.is_gate_blocking()):
			rects.append(door.get_gate_blocker_rect())
	return rects


func _on_door_entered(door) -> void:
	if not enabled or door == null or not is_instance_valid(door):
		return
	door_entered.emit(door.direction, door.target_room_id)


func _get_door_parent() -> Node:
	return _door_layer if _door_layer != null else self


func _get_door_mat_parent() -> Node:
	return _door_mat_layer if _door_mat_layer != null else _get_door_parent()


func _add_child_safely(parent: Node, child: Node) -> void:
	if parent == null or child == null or child.get_parent() != null:
		return
	if parent.is_inside_tree() and Engine.is_in_physics_frame():
		parent.call_deferred("add_child", child)
		return
	parent.add_child(child)


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
