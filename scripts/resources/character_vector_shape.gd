@tool
extends Resource
class_name CharacterVectorShape

## Character view this polygon belongs to, such as front, side_left, or back.
@export var view_direction: String = "":
	set(value):
		view_direction = value
		emit_changed()

## Stable module role for later character assembly.
@export var role: String = "":
	set(value):
		role = value
		emit_changed()

## Draw order inside the captured view.
@export var layer_order: int = 0:
	set(value):
		layer_order = value
		emit_changed()

## Original scene node path used to extract this polygon.
@export var source_node_path: String = "":
	set(value):
		source_node_path = value
		emit_changed()

## Workbench node used as the 128x128 source-space reference.
@export var source_workbench_path: String = "":
	set(value):
		source_workbench_path = value
		emit_changed()

## Polygon fill color from the authored blockout.
@export var color: Color = Color.WHITE:
	set(value):
		color = value
		emit_changed()

## Polygon points normalized to the character 128x128 source space.
@export var points: PackedVector2Array = PackedVector2Array():
	set(value):
		points = value
		emit_changed()

## Whether this module originated from a mirrored authoring node.
@export var mirror_x: bool = false:
	set(value):
		mirror_x = value
		emit_changed()
