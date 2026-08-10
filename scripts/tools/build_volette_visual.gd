extends SceneTree

const SOURCE_SCENE_PATH := "res://scenes/tools/Back Hair Test.tscn"
const OUTPUT_SCENE_PATH := "res://scenes/characters/volette_visual.tscn"
const VIEW_NAMES := ["FrontView", "SideView", "RearView"]


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	var source_scene := load(SOURCE_SCENE_PATH) as PackedScene
	if source_scene == null:
		push_error("Could not load Volette turnaround source: %s" % SOURCE_SCENE_PATH)
		quit(1)
		return
	var source_root := source_scene.instantiate() as Node2D
	root.add_child(source_root)

	var visual_root := Node2D.new()
	visual_root.name = "VoletteVisual"
	root.add_child(visual_root)

	for view_name in VIEW_NAMES:
		var source_view := source_root.get_node_or_null(view_name) as Node2D
		if source_view == null:
			push_error("Turnaround source is missing %s." % view_name)
			quit(1)
			return
		var view := source_view.duplicate() as Node2D
		view.name = view_name
		visual_root.add_child(view)
		view.position = Vector2.ZERO
		view.visible = view_name == "FrontView"
		_prepare_view(view_name, view)
		_center_view(view)

	_set_owner_recursive(visual_root, visual_root)
	var packed_scene := PackedScene.new()
	var pack_error := packed_scene.pack(visual_root)
	if pack_error != OK:
		push_error("Could not pack Volette visual scene: %s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(packed_scene, OUTPUT_SCENE_PATH)
	if save_error != OK:
		push_error("Could not save Volette visual scene: %s" % error_string(save_error))
		quit(1)
		return
	print("Built %s from %s" % [OUTPUT_SCENE_PATH, SOURCE_SCENE_PATH])
	quit()


func _prepare_view(view_name: String, view: Node2D) -> void:
	match view_name:
		"FrontView":
			_prepare_front_view(view)
		"SideView":
			_prepare_side_view(view)
		"RearView":
			_prepare_rear_view(view)


func _prepare_front_view(view: Node2D) -> void:
	var legs := view.get_node_or_null("Legs") as Node2D
	if legs == null:
		return
	var left_leg := legs.get_node_or_null("LeftLegNode")
	if left_leg != null:
		left_leg.name = "LeftLeg"
		_rename_child(left_leg, "LegPolygon", "Leg")
		_rename_child(left_leg, "ShoePolygon", "Shoe")
		_rename_child(left_leg, "KneePadPolygon", "KneePad")
	var right_leg := legs.get_node_or_null("LegMirrorPivot")
	if right_leg != null:
		right_leg.name = "RightLeg"


func _prepare_side_view(view: Node2D) -> void:
	var legs := Node2D.new()
	legs.name = "Legs"
	view.add_child(legs)
	_make_part_pivot(
		legs,
		"BackLeg",
		view,
		["BackLeg_Side", "BackShoe_Side", "BackKneePad_Side"],
		["Leg", "Shoe", "KneePad"]
	)
	_make_part_pivot(
		legs,
		"FrontLeg",
		view,
		["FrontLeg_Side", "FrontShoe_Side", "FrontKneePad_Side"],
		["Leg", "Shoe", "KneePad"]
	)


func _prepare_rear_view(view: Node2D) -> void:
	var legs := view.get_node_or_null("Legs") as Node2D
	if legs == null:
		return
	_make_part_pivot(
		legs,
		"LeftLegPivot",
		legs,
		["LeftLeg", "LeftShoe", "LeftKneePad"],
		["Leg", "Shoe", "KneePad"]
	)
	_make_part_pivot(
		legs,
		"RightLegPivot",
		legs,
		["RightLeg", "RightShoe", "RightKneePad"],
		["Leg", "Shoe", "KneePad"]
	)
	var left_pivot := legs.get_node_or_null("LeftLegPivot")
	if left_pivot != null:
		left_pivot.name = "LeftLeg"
	var right_pivot := legs.get_node_or_null("RightLegPivot")
	if right_pivot != null:
		right_pivot.name = "RightLeg"


func _make_part_pivot(
	new_parent: Node2D,
	pivot_name: String,
	old_parent: Node2D,
	part_names: Array,
	final_names: Array
) -> void:
	var primary := old_parent.get_node_or_null(String(part_names[0])) as Node2D
	if primary == null:
		return
	var pivot := Node2D.new()
	pivot.name = pivot_name
	new_parent.add_child(pivot)
	var primary_bounds := _canvas_item_bounds(primary, old_parent.global_transform.affine_inverse())
	pivot.global_position = old_parent.global_transform * primary_bounds.get_center()
	for index in range(part_names.size()):
		var part := old_parent.get_node_or_null(String(part_names[index]))
		if part == null:
			continue
		part.reparent(pivot, true)
		part.name = String(final_names[index])


func _rename_child(parent: Node, old_name: String, new_name: String) -> void:
	var child := parent.get_node_or_null(old_name)
	if child != null:
		child.name = new_name


func _center_view(view: Node2D) -> void:
	var bounds := _canvas_item_bounds(view, view.global_transform.affine_inverse())
	if bounds.size != Vector2.ZERO:
		view.position -= bounds.get_center()


func _canvas_item_bounds(node: Node, target_inverse: Transform2D) -> Rect2:
	var has_bounds := false
	var bounds := Rect2()
	if node is Polygon2D:
		var polygon_node := node as Polygon2D
		var polygon_transform := target_inverse * polygon_node.global_transform
		for point in polygon_node.polygon:
			var transformed_point := polygon_transform * point
			if not has_bounds:
				bounds = Rect2(transformed_point, Vector2.ZERO)
				has_bounds = true
			else:
				bounds = bounds.expand(transformed_point)
	for child in node.get_children():
		if not child is CanvasItem or not child.visible:
			continue
		var child_bounds := _canvas_item_bounds(child, target_inverse)
		if child_bounds.size == Vector2.ZERO:
			continue
		if not has_bounds:
			bounds = child_bounds
			has_bounds = true
		else:
			bounds = bounds.merge(child_bounds)
	return bounds if has_bounds else Rect2()


func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_owner_recursive(child, scene_owner)
