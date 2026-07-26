extends RefCounted
class_name WallOcclusionLayers

const ENTITY_LAYER_INDEX := 19
const ENTITY_VISIBILITY_LAYER := 1 << ENTITY_LAYER_INDEX


static func mark_entity_tree(root: Node) -> void:
	if root is CanvasItem:
		(root as CanvasItem).visibility_layer |= ENTITY_VISIBILITY_LAYER
	for child in root.get_children():
		mark_entity_tree(child)


static func open_visibility_path(item: CanvasItem) -> void:
	var current: Node = item
	while current != null:
		if current is CanvasItem:
			(current as CanvasItem).visibility_layer |= ENTITY_VISIBILITY_LAYER
		current = current.get_parent()
