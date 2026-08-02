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

const SOUTH_SCENE := preload("res://scenes/characters/neutral_cutout/neutral_humanoid_south.tscn")
const SOUTH_WEST_SCENE := preload("res://scenes/characters/neutral_cutout/neutral_humanoid_south_west.tscn")
const WEST_SCENE := preload("res://scenes/characters/neutral_cutout/neutral_humanoid_west.tscn")
const NORTH_WEST_SCENE := preload("res://scenes/characters/neutral_cutout/neutral_humanoid_north_west.tscn")
const NORTH_SCENE := preload("res://scenes/characters/neutral_cutout/neutral_humanoid_north.tscn")

## Selects one of five authored projections or one of their three mirrored derivatives.
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
	_active_view.name = "ActiveCutout"
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
			return {"scene": NORTH_WEST_SCENE, "mirror": false}
		Direction.NORTH:
			return {"scene": NORTH_SCENE, "mirror": false}
		Direction.NORTH_EAST:
			return {"scene": NORTH_WEST_SCENE, "mirror": true}
		Direction.EAST:
			return {"scene": WEST_SCENE, "mirror": true}
		Direction.SOUTH_EAST:
			return {"scene": SOUTH_WEST_SCENE, "mirror": true}
		_:
			return {"scene": SOUTH_SCENE, "mirror": false}
