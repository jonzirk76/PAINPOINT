@tool
extends RefCounted

const Plan := preload("res://addons/raster_region_polygon/in_place_part_edit_plan.gd")


static func propose(editor_interface: EditorInterface) -> RefCounted:
	var edited_root := editor_interface.get_edited_scene_root()
	if not edited_root is Node2D:
		return Plan.reject("Open a saved 2D assembly scene before editing a part in place.")
	var layout_path: String = edited_root.scene_file_path
	if layout_path.is_empty():
		return Plan.reject("Save the assembly scene before starting an in-place edit session.")
	if editor_interface.get_unsaved_scenes().has(layout_path):
		return Plan.reject("Save the assembly scene before editing a part in place.")

	var selection := editor_interface.get_selection().get_selected_nodes()
	if selection.size() != 1 or not selection[0] is Node:
		return Plan.reject("Select exactly one node inside an instantiated 2D part.")
	var selected := selection[0] as Node
	var instance_root := _find_instance_root(selected, edited_root)
	if instance_root == null or not instance_root is Node2D:
		return Plan.reject(
			"The selection is not inside a saved 2D PackedScene instance. "
			+ "Select an Authored or Mirrored part node."
		)
	var source_path: String = instance_root.scene_file_path
	if source_path.is_empty() or source_path == layout_path:
		return Plan.reject("The selected node has no separate governing part scene.")
	if editor_interface.get_unsaved_scenes().has(source_path):
		return Plan.reject(
			"The governing part scene is already open with unsaved changes. Save or revert it first."
		)

	var packed := load(source_path) as PackedScene
	if packed == null or not packed.can_instantiate():
		return Plan.reject("Could not load the governing PackedScene: %s" % source_path)
	var source_instance := packed.instantiate()
	if not source_instance is Node2D:
		source_instance.free()
		return Plan.reject("Only Node2D-based part scenes are supported in this first version.")
	var source_root := source_instance as Node2D

	var draft_snapshot := capture_part_snapshot(instance_root)
	var source_snapshot := capture_part_snapshot(source_root)
	var compatibility := validate_snapshot(source_root, draft_snapshot)
	if not compatibility.valid:
		source_root.free()
		return Plan.reject(compatibility.reason)

	var plan := Plan.new()
	plan.allowed = true
	plan.layout_path = layout_path
	plan.source_path = source_path
	plan.instance_path = edited_root.get_path_to(instance_root)
	plan.instance_name = instance_root.name
	plan.source_modified_time = FileAccess.get_modified_time(source_path)
	plan.instance_transform = (
		(edited_root as Node2D).global_transform.affine_inverse()
		* (instance_root as Node2D).global_transform
	)
	plan.draft_snapshot = draft_snapshot
	plan.source_snapshot = source_snapshot
	plan.has_instance_overrides = not snapshots_match(draft_snapshot, source_snapshot)
	plan.context_polygons = _capture_context_polygons(
		edited_root as Node2D,
		instance_root as Node2D,
		source_path
	)
	source_root.free()
	return plan


static func capture_part_snapshot(root: Node) -> Dictionary:
	var snapshot := {}
	_capture_node(root, root, snapshot)
	return snapshot


static func apply_snapshot(root: Node, snapshot: Dictionary) -> Dictionary:
	for path_text: String in snapshot:
		var node := root if path_text == "." else root.get_node_or_null(NodePath(path_text))
		if node == null:
			return {
				"valid": false,
				"reason": "The source part no longer contains %s." % path_text,
			}
		var values: Dictionary = snapshot[path_text]
		if values.has("transform") and node is Node2D:
			(node as Node2D).transform = values.transform
		if values.has("rest") and node is Bone2D:
			(node as Bone2D).rest = values.rest
		if values.has("polygon") and node is Polygon2D:
			var polygon := node as Polygon2D
			var points: PackedVector2Array = values.polygon
			var pieces: Array[PackedInt32Array] = values.polygons
			polygon.polygon = points.duplicate()
			polygon.polygons = pieces.duplicate(true)
			polygon.color = values.color
			polygon.antialiased = values.antialiased
		if values.has("z_index") and node is CanvasItem:
			var canvas_item := node as CanvasItem
			canvas_item.z_as_relative = values.z_as_relative
			canvas_item.z_index = values.z_index
	return {"valid": true, "reason": ""}


static func validate_snapshot(root: Node, snapshot: Dictionary) -> Dictionary:
	for path_text: String in snapshot:
		var node := root if path_text == "." else root.get_node_or_null(NodePath(path_text))
		if node == null:
			return {
				"valid": false,
				"reason": (
					"The layout instance contains %s, but the governing source does not. "
					+ "Local structural overrides cannot be promoted automatically."
				) % path_text,
			}
		var values: Dictionary = snapshot[path_text]
		if values.has("polygon") and not node is Polygon2D:
			return {"valid": false, "reason": "%s is not a Polygon2D in the source." % path_text}
	return {"valid": true, "reason": ""}


static func snapshots_match(left: Dictionary, right: Dictionary) -> bool:
	if left.size() != right.size():
		return false
	for path_text: String in left:
		if not right.has(path_text):
			return false
		var left_values: Dictionary = left[path_text]
		var right_values: Dictionary = right[path_text]
		if left_values.size() != right_values.size():
			return false
		for property_name: String in left_values:
			if not right_values.has(property_name):
				return false
			if left_values[property_name] != right_values[property_name]:
				return false
	return true


static func _find_instance_root(selected: Node, edited_root: Node) -> Node:
	var candidate := selected
	while candidate != null and candidate != edited_root:
		if not candidate.scene_file_path.is_empty():
			return candidate
		candidate = candidate.get_parent()
	return null


static func _capture_node(root: Node, node: Node, snapshot: Dictionary) -> void:
	var path_text := str(root.get_path_to(node))
	var values := {}
	if node is Node2D and node != root:
		values.transform = (node as Node2D).transform
	if node is Bone2D and node != root:
		values.rest = (node as Bone2D).rest
	if node is Polygon2D:
		var polygon := node as Polygon2D
		values.polygon = polygon.polygon.duplicate()
		values.polygons = polygon.polygons.duplicate(true)
		values.color = polygon.color
		values.antialiased = polygon.antialiased
	if node is CanvasItem and node != root:
		var canvas_item := node as CanvasItem
		values.z_as_relative = canvas_item.z_as_relative
		values.z_index = canvas_item.z_index
	if not values.is_empty():
		snapshot[path_text] = values
	for child in node.get_children():
		_capture_node(root, child, snapshot)


static func _capture_context_polygons(
	layout_root: Node2D,
	selected_instance: Node2D,
	source_path: String
) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var layout_inverse := layout_root.global_transform.affine_inverse()
	for candidate in layout_root.find_children("*", "Polygon2D", true, false):
		var polygon := candidate as Polygon2D
		if polygon == selected_instance or selected_instance.is_ancestor_of(polygon):
			continue
		var record := {
			"transform": layout_inverse * polygon.global_transform,
			"polygon": polygon.polygon.duplicate(),
			"polygons": polygon.polygons.duplicate(true),
			"color": polygon.color,
			"antialiased": polygon.antialiased,
			"source_relative_path": "",
			"occurrence_transform": Transform2D.IDENTITY,
		}
		var occurrence := _find_source_occurrence(polygon, layout_root, source_path)
		if occurrence != null:
			record.source_relative_path = str(occurrence.get_path_to(polygon))
			record.occurrence_transform = layout_inverse * occurrence.global_transform
		records.append(record)
	return records


static func _find_source_occurrence(
	node: Node,
	layout_root: Node,
	source_path: String
) -> Node2D:
	var candidate := node
	while candidate != null and candidate != layout_root:
		if candidate is Node2D and candidate.scene_file_path == source_path:
			return candidate as Node2D
		candidate = candidate.get_parent()
	return null
