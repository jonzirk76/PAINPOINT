@tool
extends RefCounted

const Checker := preload("res://addons/raster_region_polygon/in_place_part_edit_checker.gd")

var active := false
var plan: RefCounted
var source_root: Node2D
var context_root: Node2D
var preview_bindings: Array[Dictionary] = []


func begin(p_plan: RefCounted, p_source_root: Node2D) -> Dictionary:
	plan = p_plan
	source_root = p_source_root
	var applied := Checker.apply_snapshot(source_root, plan.draft_snapshot)
	if not applied.valid:
		clear()
		return applied
	_build_context()
	active = true
	synchronize_preview()
	return {"valid": true, "reason": ""}


func synchronize_preview() -> void:
	if not active or not is_instance_valid(source_root):
		return
	for binding in preview_bindings:
		var proxy := binding.proxy as Polygon2D
		if not is_instance_valid(proxy):
			continue
		var path_text: String = binding.source_relative_path
		var source_node := (
			source_root
			if path_text == "."
			else source_root.get_node_or_null(NodePath(path_text))
		)
		if not source_node is Polygon2D:
			continue
		var source_polygon := source_node as Polygon2D
		var relative_transform := (
			source_root.global_transform.affine_inverse()
			* source_polygon.global_transform
		)
		proxy.transform = binding.occurrence_transform * relative_transform
		proxy.polygon = source_polygon.polygon.duplicate()
		proxy.polygons = source_polygon.polygons.duplicate(true)
		proxy.color = source_polygon.color
		proxy.antialiased = source_polygon.antialiased


func remove_context() -> void:
	preview_bindings.clear()
	if is_instance_valid(context_root):
		var parent := context_root.get_parent()
		if parent != null:
			parent.remove_child(context_root)
		context_root.free()
	context_root = null


func clear() -> void:
	remove_context()
	active = false
	plan = null
	source_root = null


func _build_context() -> void:
	context_root = Node2D.new()
	context_root.name = "__RasterPolygonPartEditContext"
	context_root.top_level = true
	context_root.z_as_relative = false
	context_root.z_index = -10000
	context_root.modulate = Color(1.0, 1.0, 1.0, 0.38)
	source_root.add_child(context_root, false, Node.INTERNAL_MODE_FRONT)
	context_root.global_transform = (
		source_root.global_transform
		* plan.instance_transform.affine_inverse()
	)

	for record: Dictionary in plan.context_polygons:
		var proxy := Polygon2D.new()
		proxy.name = "ContextPolygon"
		proxy.transform = record.transform
		var points: PackedVector2Array = record.polygon
		var pieces: Array[PackedInt32Array] = record.polygons
		proxy.polygon = points.duplicate()
		proxy.polygons = pieces.duplicate(true)
		proxy.color = record.color
		proxy.antialiased = record.antialiased
		proxy.z_as_relative = true
		proxy.z_index = 0
		context_root.add_child(proxy, false, Node.INTERNAL_MODE_FRONT)
		var source_relative_path: String = record.source_relative_path
		if not source_relative_path.is_empty():
			preview_bindings.append({
				"proxy": proxy,
				"source_relative_path": source_relative_path,
				"occurrence_transform": record.occurrence_transform,
			})
