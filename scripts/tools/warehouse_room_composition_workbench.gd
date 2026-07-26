@tool
extends Node2D
class_name WarehouseRoomCompositionWorkbench

const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")
const ROOM_CELLS: Array[Vector2i] = [Vector2i.ZERO]

## Opens the north wall with the renderer's canonical four-tile doorway.
@export var north_opening: bool = true:
	set(value):
		north_opening = value
		queue_redraw()

## Opens the east wall with the renderer's canonical four-tile doorway.
@export var east_opening: bool = false:
	set(value):
		east_opening = value
		queue_redraw()

## Opens the south wall with the renderer's canonical four-tile doorway.
@export var south_opening: bool = true:
	set(value):
		south_opening = value
		queue_redraw()

## Opens the west wall with the renderer's canonical four-tile doorway.
@export var west_opening: bool = false:
	set(value):
		west_opening = value
		queue_redraw()

## Shows every native 40×40 renderer cell.
@export var show_tile_grid: bool = true:
	set(value):
		show_tile_grid = value
		queue_redraw()

## Shows 80×80 composition guides over the native tile grid.
@export var show_large_tile_grid: bool = true:
	set(value):
		show_large_tile_grid = value
		queue_redraw()

## Shows labels for room, doorway, player, and prop dimensions.
@export var show_measurements: bool = true:
	set(value):
		show_measurements = value
		queue_redraw()

@export_group("Preview Palette")
## Empty space outside the generated room.
@export var void_color := Color("#111317"):
	set(value):
		void_color = value
		queue_redraw()

## Canonical room floor.
@export var floor_color := Color("#34373a"):
	set(value):
		floor_color = value
		queue_redraw()

## Vertical wall face offset below its wall-top tile.
@export var wall_face_color := Color("#55565a"):
	set(value):
		wall_face_color = value
		queue_redraw()

## Top-facing wall surface.
@export var wall_top_color := Color("#85827a"):
	set(value):
		wall_top_color = value
		queue_redraw()

## Deep shadow under walls and props.
@export var shadow_color := Color("#101216"):
	set(value):
		shadow_color = value
		queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var room_bounds := ROOM_GEOMETRY_BUILDER.get_bounds(ROOM_CELLS)
	var connection_edges := _connection_edges()
	var wall_top_tiles := ROOM_GEOMETRY_BUILDER.build_wall_tile_rects(ROOM_CELLS, connection_edges)
	var wall_body_tiles := ROOM_GEOMETRY_BUILDER.build_wall_body_tile_rects(
		wall_top_tiles,
		ROOM_CELLS,
		connection_edges
	)

	draw_rect(room_bounds.grow(160.0), void_color, true)
	draw_rect(room_bounds, floor_color, true)
	if show_tile_grid:
		_draw_grid(room_bounds, ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE, Color(0.18, 0.2, 0.22, 0.42), 1.0)
	if show_large_tile_grid:
		_draw_grid(room_bounds, ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE * 2.0, Color(0.28, 0.31, 0.34, 0.5), 1.5)

	for body_tile in wall_body_tiles:
		draw_rect(Rect2(body_tile.position + Vector2(4.0, 5.0), body_tile.size), shadow_color, true)
	for body_tile in wall_body_tiles:
		draw_rect(body_tile, wall_face_color, true)
		draw_line(body_tile.position, Vector2(body_tile.end.x, body_tile.position.y), wall_face_color.lightened(0.18), 1.5)
	for top_tile in wall_top_tiles:
		draw_rect(top_tile, wall_top_color, true)
		draw_rect(top_tile, Color(0.8, 0.82, 0.8, 0.26), false, 1.0)

	draw_rect(room_bounds, Color(0.7, 0.76, 0.8, 0.76), false, 3.0)
	_draw_origin_axes()
	if show_measurements:
		_draw_measurements(room_bounds, connection_edges)


func _connection_edges() -> Dictionary:
	var edges := {}
	if north_opening:
		edges["north"] = {"source_cell": Vector2i.ZERO, "target_cell": Vector2i.ZERO}
	if east_opening:
		edges["east"] = {"source_cell": Vector2i.ZERO, "target_cell": Vector2i.ZERO}
	if south_opening:
		edges["south"] = {"source_cell": Vector2i.ZERO, "target_cell": Vector2i.ZERO}
	if west_opening:
		edges["west"] = {"source_cell": Vector2i.ZERO, "target_cell": Vector2i.ZERO}
	return edges


func _draw_grid(bounds: Rect2, step: float, color: Color, width: float) -> void:
	var x := bounds.position.x
	while x <= bounds.end.x + 0.5:
		draw_line(Vector2(x, bounds.position.y), Vector2(x, bounds.end.y), color, width)
		x += step
	var y := bounds.position.y
	while y <= bounds.end.y + 0.5:
		draw_line(Vector2(bounds.position.x, y), Vector2(bounds.end.x, y), color, width)
		y += step


func _draw_origin_axes() -> void:
	draw_line(Vector2(-28.0, 0.0), Vector2(28.0, 0.0), Color(1.0, 0.35, 0.32, 0.9), 2.0)
	draw_line(Vector2(0.0, -28.0), Vector2(0.0, 28.0), Color(0.3, 0.95, 0.48, 0.9), 2.0)


func _draw_measurements(bounds: Rect2, connection_edges: Dictionary) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	draw_string(
		font,
		bounds.position + Vector2(8.0, -54.0),
		"ONE GENERATED ROOM CELL — 1280×720 world px — 32×18 canonical 40 px tiles",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		22,
		Color(0.92, 0.95, 0.98)
	)
	draw_string(
		font,
		bounds.position + Vector2(8.0, -27.0),
		"Wall body depth: 40 px   Door opening: 160 px   Cyan placement guides are movable examples",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		17,
		Color(0.52, 0.9, 1.0)
	)
	for direction in connection_edges.keys():
		var opening := ROOM_GEOMETRY_BUILDER.get_opening_rect(ROOM_CELLS, Vector2i.ZERO, String(direction))
		draw_rect(opening, Color(0.15, 0.92, 1.0, 0.72), false, 3.0)
