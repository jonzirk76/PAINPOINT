extends RefCounted
class_name WallOcclusionLayers

const ENTITY_LAYER_INDEX := 19
const ENTITY_VISIBILITY_LAYER := 1 << ENTITY_LAYER_INDEX
const CANDIDATE_GROUP := &"perspective_information_candidates"
const ROOM_ID_META := &"perspective_room_id"


static func mark_entity_tree(root: Node, room_id: String = "") -> void:
	if root == null:
		return
	root.add_to_group(CANDIDATE_GROUP)
	root.set_meta(ROOM_ID_META, room_id)
	set_entity_capture_enabled(root, true)


static func set_candidate_room_id(root: Node, room_id: String) -> void:
	if root != null:
		root.set_meta(ROOM_ID_META, room_id)


static func set_entity_capture_enabled(root: Node, enabled: bool) -> void:
	if root == null:
		return
	if root is CanvasItem:
		var item := root as CanvasItem
		if enabled:
			item.visibility_layer |= ENTITY_VISIBILITY_LAYER
		else:
			item.visibility_layer &= ~ENTITY_VISIBILITY_LAYER
	for child in root.get_children():
		set_entity_capture_enabled(child, enabled)


static func open_visibility_path(item: CanvasItem) -> void:
	var current: Node = item
	while current != null:
		if current is CanvasItem:
			(current as CanvasItem).visibility_layer |= ENTITY_VISIBILITY_LAYER
		current = current.get_parent()
