extends Resource
class_name RoomPieceDefinition

const LEVEL_DEFINITION_SCRIPT := preload("res://scripts/resources/level_definition.gd")
const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")
const CARDINAL_CONNECTORS := ["north", "east", "south", "west"]
const CONNECTOR_FALLBACKS := {
	"start_square": ["north", "east", "south", "west"],
	"combat_cell": ["north", "east", "south", "west"],
	"combat_wide": ["west", "east", "north", "south"],
	"combat_tall": ["west", "east", "north", "south"],
	"combat_l_room": ["west", "east", "south", "north"],
	"combat_t_room": ["west", "east", "north", "south"],
	"combat_ring": ["west", "east", "north", "south"],
	"combat_hourglass": ["west", "east", "north", "south"],
	"combat_crossroads": ["west", "east", "north", "south"],
	"challenge_zigzag": ["north", "west", "east"],
	"treasure_nook": ["south", "west"],
	"boss_chamber": ["west"]
}

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
@export var destructible_prop_placements: Array[Resource] = []
@export var max_active_enemies: int = 12
@export var boss_profile: Resource = null
@export var boss_spawn_position: Vector2 = Vector2.ZERO


func create_level_definition():
	var level = LEVEL_DEFINITION_SCRIPT.new()
	level.id = id
	level.display_name = display_name
	level.difficulty_label = room_kind.capitalize()
	level.arena_shape = 0
	level.arena_bounds = ROOM_GEOMETRY_BUILDER.get_bounds(footprint_cells)
	level.spawner_placements = spawner_placements.duplicate()
	level.destructible_prop_placements = destructible_prop_placements.duplicate()
	var wall_tiles: Array[Rect2] = ROOM_GEOMETRY_BUILDER.build_wall_tile_rects(footprint_cells)
	wall_tiles.append_array(ROOM_GEOMETRY_BUILDER.rects_to_wall_tiles(wall_rects))
	level.wall_rects = ROOM_GEOMETRY_BUILDER.merge_wall_tiles(wall_tiles)
	var empty_voids: Array[Rect2] = []
	level.void_rects = empty_voids
	level.max_active_enemies = max_active_enemies
	level.boss_profile = boss_profile
	level.boss_spawn_position = boss_spawn_position
	level.set_meta("footprint_cells", footprint_cells.duplicate())
	level.set_meta("connection_edges", {})
	level.set_meta("wall_tile_rects", wall_tiles)
	return level


func get_connector_directions() -> PackedStringArray:
	if not connector_directions.is_empty():
		return connector_directions.duplicate()
	if CONNECTOR_FALLBACKS.has(id):
		return PackedStringArray(CONNECTOR_FALLBACKS[id])
	if room_kind == "combat":
		return PackedStringArray(CARDINAL_CONNECTORS)
	return PackedStringArray()


func has_connector(direction: String) -> bool:
	return get_connector_directions().has(direction)


func get_min_cell() -> Vector2i:
	return ROOM_GEOMETRY_BUILDER.get_min_cell(footprint_cells)


func get_max_cell() -> Vector2i:
	return ROOM_GEOMETRY_BUILDER.get_max_cell(footprint_cells)


func validate_footprint() -> Dictionary:
	return ROOM_GEOMETRY_BUILDER.validate_footprint(id, room_kind, footprint_cells)
