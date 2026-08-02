@tool
extends Node2D

enum Direction {
	SOUTH,
	SOUTH_WEST,
	WEST,
	NORTH_WEST,
	NORTH,
	NORTH_EAST,
	EAST,
	SOUTH_EAST,
}

const SOUTH_SCENE := preload("res://scenes/characters/neutral_polygon_base/neutral_polygon_south.tscn")
const SOUTH_WEST_SCENE := preload("res://scenes/characters/neutral_polygon_base/neutral_polygon_south_west.tscn")
const WEST_SCENE := preload("res://scenes/characters/neutral_polygon_base/neutral_polygon_west.tscn")
const NORTH_EAST_SCENE := preload("res://scenes/characters/neutral_polygon_base/neutral_polygon_north_east.tscn")
const NORTH_SCENE := preload("res://scenes/characters/neutral_polygon_base/neutral_polygon_north.tscn")

## Selects one of five editable polygon projections or a mirrored derivative.
@export_enum("South", "South West", "West", "North West", "North", "North East", "East", "South East")
var direction: int = Direction.SOUTH:
	set(value):
		direction = clampi(value, Direction.SOUTH, Direction.SOUTH_EAST)
		_rebuild_view()

var _active_view: Node2D


func _ready() -> void:
	_rebuild_view()


func _rebuild_view() -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(_active_view):
		_active_view.queue_free()
		_active_view = null
	var selection := _canonical_selection(direction)
	var scene: PackedScene = selection["scene"]
	_active_view = scene.instantiate()
	_active_view.name = "ActivePolygonView"
	if selection["mirror"]:
		_active_view.scale.x = -1.0
	add_child(_active_view)


func _canonical_selection(value: int) -> Dictionary:
	match value:
		Direction.SOUTH_WEST:
			return {"scene": SOUTH_WEST_SCENE, "mirror": false}
		Direction.WEST:
			return {"scene": WEST_SCENE, "mirror": false}
		Direction.NORTH_WEST:
			return {"scene": NORTH_EAST_SCENE, "mirror": true}
		Direction.NORTH:
			return {"scene": NORTH_SCENE, "mirror": false}
		Direction.NORTH_EAST:
			return {"scene": NORTH_EAST_SCENE, "mirror": false}
		Direction.EAST:
			return {"scene": WEST_SCENE, "mirror": true}
		Direction.SOUTH_EAST:
			return {"scene": SOUTH_WEST_SCENE, "mirror": true}
		_:
			return {"scene": SOUTH_SCENE, "mirror": false}
