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
var _walking: bool = true


func _ready() -> void:
	_rebuild_view()


func _rebuild_view() -> void:
	if not is_inside_tree():
		return
	var preserved_walk_position := _get_walk_position()
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
	_apply_animation_state(preserved_walk_position)


func set_walking(value: bool) -> void:
	if _walking == value:
		return
	_walking = value
	_apply_animation_state()


func _get_walk_position() -> float:
	var animation_player := _get_active_animation_player()
	if animation_player == null or animation_player.current_animation != &"walk":
		return 0.0
	return animation_player.current_animation_position


func _apply_animation_state(walk_position: float = 0.0) -> void:
	var animation_player := _get_active_animation_player()
	if animation_player == null:
		return
	if not _walking:
		animation_player.play(&"RESET")
		animation_player.advance(0.0)
		return
	animation_player.play(&"walk")
	var walk_animation := animation_player.get_animation(&"walk")
	if walk_animation != null and walk_animation.length > 0.0:
		animation_player.seek(fposmod(walk_position, walk_animation.length), true)


func _get_active_animation_player() -> AnimationPlayer:
	if not is_instance_valid(_active_view):
		return null
	return _active_view.get_node_or_null("AnimationPlayer") as AnimationPlayer


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
