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
## [Description] Number of 40 px visual wall-body tiers drawn beneath each wall top; collision remains one tier deep.
@export_range(1, 8, 1) var wall_height_tiles: int = 3
@export var spawner_placements: Array[Resource] = []
## Weighted non-spawner enemy entries copied to generated level definitions for this room piece.
@export var encounter_table: Array[Resource] = []
## Base opening non-spawner encounter budget copied to generated level definitions for this room piece.
@export var encounter_budget: int = 0
@export var destructible_prop_placements: Array[Resource] = []
@export var max_active_enemies: int = 12
@export var boss_profile: Resource = null
## Generates a procedural agent boss from boss_profile when this room piece becomes a boss room.
@export var generate_agent_boss: bool = false
@export var boss_spawn_position: Vector2 = Vector2.ZERO


func create_level_definition() -> LevelDefinition:
	var level = LEVEL_DEFINITION_SCRIPT.new()
	level.id = id
	level.display_name = display_name
	level.difficulty_label = room_kind.capitalize()
	level.arena_shape = 0
	level.arena_bounds = ROOM_GEOMETRY_BUILDER.get_bounds(footprint_cells)
	level.spawner_placements = spawner_placements.duplicate()
	level.encounter_table = encounter_table.duplicate()
	level.encounter_budget = encounter_budget
	level.destructible_prop_placements = destructible_prop_placements.duplicate()
	var wall_floor_tiles: Array[Rect2] = ROOM_GEOMETRY_BUILDER.build_wall_tile_rects(footprint_cells)
	wall_floor_tiles.append_array(ROOM_GEOMETRY_BUILDER.rects_to_wall_tiles(wall_rects))
	var wall_body_tiles: Array[Rect2] = ROOM_GEOMETRY_BUILDER.build_wall_body_tile_rects(wall_floor_tiles, footprint_cells, {}, wall_height_tiles)
	var wall_top_tiles: Array[Rect2] = ROOM_GEOMETRY_BUILDER.build_wall_top_visual_tile_rects(wall_floor_tiles, wall_height_tiles)
	var wall_collision_tiles: Array[Rect2] = ROOM_GEOMETRY_BUILDER.build_wall_collision_tile_rects(wall_floor_tiles, footprint_cells)
	level.wall_rects = ROOM_GEOMETRY_BUILDER.merge_wall_tiles(wall_collision_tiles)
	var empty_voids: Array[Rect2] = []
	level.void_rects = empty_voids
	level.max_active_enemies = max_active_enemies
	level.boss_profile = boss_profile
	level.generate_agent_boss = generate_agent_boss
	level.boss_spawn_position = boss_spawn_position
	level.set_meta("footprint_cells", footprint_cells.duplicate())
	level.set_meta("wall_height_tiles", wall_height_tiles)
	level.set_meta("connection_edges", {})
	level.set_meta("wall_top_tile_rects", wall_top_tiles)
	level.set_meta("wall_body_tile_rects", wall_body_tiles)
	level.set_meta("wall_floor_tile_rects", wall_floor_tiles)
	level.set_meta("wall_tile_rects", wall_floor_tiles)
	level.set_meta("void_tile_rects", empty_voids)
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
