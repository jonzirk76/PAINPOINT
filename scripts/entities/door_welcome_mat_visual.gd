extends Node2D
class_name DoorWelcomeMatVisual

const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")
const WALL_OCCLUSION_LAYERS := preload("res://scripts/arena/wall_occlusion_layers.gd")

var mat_rect: Rect2 = Rect2()
var mat_color: Color = Color(0.12, 0.13, 0.14, 0.72)


func configure(opening_rect: Rect2, direction: String, depth_tiles: int, color: Color) -> void:
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	var depth: float = tile_size * float(max(depth_tiles, 1))
	var world_rect := opening_rect
	match direction:
		"north":
			world_rect = Rect2(
				Vector2(opening_rect.position.x, opening_rect.end.y),
				Vector2(opening_rect.size.x, depth)
			)
		"south":
			world_rect = Rect2(
				Vector2(opening_rect.position.x, opening_rect.position.y - depth),
				Vector2(opening_rect.size.x, depth)
			)
		"east":
			world_rect = Rect2(
				Vector2(opening_rect.position.x - depth, opening_rect.position.y),
				Vector2(depth, opening_rect.size.y)
			)
		"west":
			world_rect = Rect2(
				Vector2(opening_rect.end.x, opening_rect.position.y),
				Vector2(depth, opening_rect.size.y)
			)
	position = world_rect.get_center()
	mat_rect = Rect2(-world_rect.size * 0.5, world_rect.size)
	mat_color = color
	WALL_OCCLUSION_LAYERS.mark_entity_tree(self)
	queue_redraw()


func _draw() -> void:
	for tile_rect in _rect_to_tiles(mat_rect):
		var inset_rect := tile_rect.grow(-2.0)
		draw_rect(inset_rect, mat_color, true)
		draw_rect(inset_rect, Color(0.28, 0.29, 0.3, 0.34), false, 1.0)


func _rect_to_tiles(rect: Rect2) -> Array[Rect2]:
	var tiles: Array[Rect2] = []
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	var columns: int = max(1, int(ceil(rect.size.x / tile_size)))
	var rows: int = max(1, int(ceil(rect.size.y / tile_size)))
	for y in range(rows):
		for x in range(columns):
			var tile_position := rect.position + Vector2(float(x) * tile_size, float(y) * tile_size)
			var clipped_size := Vector2(
				min(tile_size, rect.end.x - tile_position.x),
				min(tile_size, rect.end.y - tile_position.y)
			)
			if clipped_size.x > 0.0 and clipped_size.y > 0.0:
				tiles.append(Rect2(tile_position, clipped_size))
	return tiles
