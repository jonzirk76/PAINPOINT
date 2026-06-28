extends Resource
class_name RoomPieceDefinition

const LEVEL_DEFINITION_SCRIPT := preload("res://scripts/resources/level_definition.gd")

@export var id: String = "room_piece"
@export var display_name: String = "Room Piece"
@export var room_kind: String = "combat"
@export var difficulty_weight: int = 1
@export var footprint_cells: Array[Vector2i] = [Vector2i.ZERO]
@export var connector_directions: PackedStringArray = []
@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var arena_shape: int = 0
@export var wall_rects: Array[Rect2] = []
@export var spawner_placements: Array[Resource] = []
@export var max_active_enemies: int = 12
@export var boss_profile: Resource = null
@export var boss_spawn_position: Vector2 = Vector2.ZERO


func create_level_definition():
	var level = LEVEL_DEFINITION_SCRIPT.new()
	level.id = id
	level.display_name = display_name
	level.difficulty_label = room_kind.capitalize()
	level.arena_shape = arena_shape
	level.arena_bounds = arena_bounds
	level.spawner_placements = spawner_placements.duplicate()
	level.wall_rects = wall_rects.duplicate()
	level.max_active_enemies = max_active_enemies
	level.boss_profile = boss_profile
	level.boss_spawn_position = boss_spawn_position
	return level


func has_connector(direction: String) -> bool:
	return connector_directions.has(direction)


func get_min_cell() -> Vector2i:
	var min_cell := footprint_cells[0]
	for cell in footprint_cells:
		min_cell.x = min(min_cell.x, cell.x)
		min_cell.y = min(min_cell.y, cell.y)
	return min_cell


func get_max_cell() -> Vector2i:
	var max_cell := footprint_cells[0]
	for cell in footprint_cells:
		max_cell.x = max(max_cell.x, cell.x)
		max_cell.y = max(max_cell.y, cell.y)
	return max_cell
