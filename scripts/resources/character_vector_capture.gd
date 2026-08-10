@tool
extends Resource
class_name CharacterVectorCapture

## Stable id for this authored vector capture.
@export var capture_id: String = "":
	set(value):
		capture_id = value
		emit_changed()

## Source scene used to extract the vector blockout.
@export var source_scene_path: String = "":
	set(value):
		source_scene_path = value
		emit_changed()

## Captured workbench settings keyed by source workbench node path.
@export var workbench_properties: Dictionary = {}:
	set(value):
		workbench_properties = value
		emit_changed()

## Captured polygon modules.
@export var shapes: Array[Resource] = []:
	set(value):
		shapes = value
		emit_changed()


func get_shapes_for_view(view_direction: String) -> Array[Resource]:
	var results: Array[Resource] = []
	for shape in shapes:
		if shape != null and String(shape.get("view_direction")) == view_direction:
			results.append(shape)
	results.sort_custom(Callable(self, "_sort_shape_layer"))
	return results


func _sort_shape_layer(left: Resource, right: Resource) -> bool:
	return int(left.get("layer_order")) < int(right.get("layer_order"))
