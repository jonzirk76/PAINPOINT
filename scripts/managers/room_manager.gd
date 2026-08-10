extends Node
class_name RoomManager

const DOOR_PATH_VISUAL_SCRIPT := preload("res://scripts/entities/door_path_visual.gd")
const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")

signal door_entered(direction: String, target_room_id: String)

@export var door_scene: PackedScene = preload("res://scenes/entities/door_entity.tscn")
@export var door_depth: float = 28.0
@export var door_width: float = 92.0
## [Description] Slightly darkens the canonical floor tiles immediately inside each doorway.
@export var door_welcome_mat_color: Color = Color(0.12, 0.13, 0.14, 0.72)
## [Description] Controls how many floor tiles each doorway welcome mat extends into the room.
@export_range(1, 3, 1) var door_welcome_mat_depth_tiles: int = 1
## [Description] Fill color of the smooth rendering-only paths between selected doorway mats.
@export var door_path_color: Color = Color(0.19, 0.2, 0.21, 0.78)
## [Description] Border shared by doorway mats and their connecting paths.
@export var door_path_border_color: Color = Color(0.08, 0.09, 0.1, 0.9)
## [Description] Width of smooth doorway paths measured in canonical wall/floor tiles.
@export_range(1, 8, 1) var door_path_width_tiles: int = 4
## [Description] Width of the darker border around mats and paths.
@export_range(1.0, 10.0, 0.5) var door_path_border_width: float = 5.0

var enabled: bool = false
var _door_layer: Node = null
var _door_mat_layer: Node = null
var _doors: Array = []
var _door_path_visuals: Array[Node2D] = []


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
			if door.has_method("set_floor_marker_world_position"):
				door.set_floor_marker_world_position(
					_get_welcome_mat_rect(opening_rect, direction).get_center()
				)
		if door_info.has("passage_rect") and door.has_method("set_passage_rect"):
			var passage_rect: Rect2 = door_info["passage_rect"]
			door.set_passage_rect(passage_rect.get_center(), passage_rect.size)
		door.entered.connect(_on_door_entered)
		_doors.append(door)
		_add_child_safely(_get_door_parent(), door)
	var resolved_mat_infos: Array = welcome_mat_infos if not welcome_mat_infos.is_empty() else door_infos
	var fallback_room_id := String(level_definition.get_meta("active_room_id", ""))
	var infos_by_room: Dictionary = {}
	for mat_info in resolved_mat_infos:
		if not mat_info is Dictionary or not mat_info.has("opening_rect"):
			continue
		var source_room_id := String(mat_info.get("source_room_id", fallback_room_id))
		var room_infos: Array = infos_by_room.get(source_room_id, [])
		room_infos.append(mat_info)
		infos_by_room[source_room_id] = room_infos
	var path_obstruction_rects: Array[Rect2] = _get_path_obstruction_rects(level_definition)
	for source_room_id in infos_by_room.keys():
		_add_door_path_visual(
			infos_by_room[source_room_id],
			String(source_room_id),
			path_obstruction_rects
		)
	set_enabled(enabled)


func clear_doors() -> void:
	for path_visual in _door_path_visuals:
		if is_instance_valid(path_visual):
			path_visual.queue_free()
	_door_path_visuals.clear()
	for door in _doors:
		if is_instance_valid(door):
			door.queue_free()
	_doors.clear()


func _add_door_path_visual(
	opening_infos: Array,
	room_id: String,
	obstruction_rects: Array[Rect2]
) -> void:
	if opening_infos.is_empty():
		return
	var first_info: Dictionary = opening_infos[0]
	var room_center: Vector2 = first_info.get("room_center", Vector2.ZERO)
	var path_visual = DOOR_PATH_VISUAL_SCRIPT.new()
	path_visual.name = "DoorPathVisual"
	path_visual.configure(
		opening_infos,
		door_welcome_mat_depth_tiles,
		door_welcome_mat_color,
		door_path_color,
		door_path_border_color,
		max(
			ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE * float(max(door_path_width_tiles, 1))
				- door_path_border_width * 2.0,
			4.0
		),
		door_path_border_width,
		room_center,
		obstruction_rects,
		room_id
	)
	_door_path_visuals.append(path_visual)
	_add_child_safely(_get_door_mat_parent(), path_visual)


func _get_path_obstruction_rects(level_definition) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for wall_rect in level_definition.wall_rects:
		if wall_rect is Rect2:
			rects.append(wall_rect)
	for void_rect in level_definition.void_rects:
		if void_rect is Rect2:
			rects.append(void_rect)
	if level_definition.has_meta("path_obstruction_rects"):
		for obstruction_rect in level_definition.get_meta("path_obstruction_rects"):
			if obstruction_rect is Rect2:
				rects.append(obstruction_rect)
	return rects


func _get_welcome_mat_rect(opening_rect: Rect2, direction: String) -> Rect2:
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	var depth: float = tile_size * float(max(door_welcome_mat_depth_tiles, 1))
	match direction:
		"north":
			return Rect2(
				Vector2(opening_rect.position.x, opening_rect.end.y),
				Vector2(opening_rect.size.x, depth)
			)
		"south":
			return Rect2(
				Vector2(opening_rect.position.x, opening_rect.position.y - depth),
				Vector2(opening_rect.size.x, depth)
			)
		"east":
			return Rect2(
				Vector2(opening_rect.position.x - depth, opening_rect.position.y),
				Vector2(depth, opening_rect.size.y)
			)
		"west":
			return Rect2(
				Vector2(opening_rect.end.x, opening_rect.position.y),
				Vector2(depth, opening_rect.size.y)
			)
	return opening_rect


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
