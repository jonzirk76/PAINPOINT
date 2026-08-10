@tool
extends RefCounted

enum Mode {
	INACTIVE,
	BOX_SELECT,
	MOVE,
}

var target: Polygon2D
var baseline_polygon := PackedVector2Array()
var selected_indices := PackedInt32Array()
var mode := Mode.INACTIVE


func begin(node: Polygon2D) -> void:
	target = node
	baseline_polygon = node.polygon.duplicate()
	selected_indices.clear()
	mode = Mode.BOX_SELECT


func end() -> void:
	target = null
	baseline_polygon.clear()
	selected_indices.clear()
	mode = Mode.INACTIVE


func synchronize() -> void:
	if is_instance_valid(target):
		baseline_polygon = target.polygon.duplicate()
	selected_indices.clear()


func has_selection() -> bool:
	return not selected_indices.is_empty()

