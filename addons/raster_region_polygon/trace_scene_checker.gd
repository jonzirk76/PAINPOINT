@tool
extends RefCounted

const Recipe := preload("res://addons/raster_region_polygon/trace_recipe.gd")
const Tracer := preload("res://addons/raster_region_polygon/raster_region_tracer.gd")
const TRACE_METADATA := &"raster_region_trace"

enum TargetStatus {
	NONE,
	CLEAN,
	MANUALLY_EDITED,
	MISSING,
	UNMANAGED,
	STALE,
}


static func inspect_target(
	node: Polygon2D,
	source_sprite: Sprite2D,
	source_image: Image
) -> Dictionary:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return {"status": TargetStatus.MISSING, "reason": "Target is missing."}
	if not node.has_meta(TRACE_METADATA):
		return {"status": TargetStatus.UNMANAGED, "reason": "Target is unmanaged."}
	if node.get_parent() != source_sprite:
		return {
			"status": TargetStatus.STALE,
			"reason": "Target is no longer a child of its recorded source sprite.",
		}

	var metadata: Dictionary = node.get_meta(TRACE_METADATA)
	var recipe: RefCounted = Recipe.from_metadata(metadata)
	var trace_result: Dictionary = Tracer.trace_region(
		source_image,
		recipe.seed,
		recipe.tolerance,
		recipe.vertex_error,
		recipe.include_alpha,
		recipe.cleanup_radius,
		recipe.limit_polygon
	)
	if not trace_result.get("ok", false):
		return {
			"status": TargetStatus.STALE,
			"reason": str(trace_result.get("error", "Stored recipe cannot be rebuilt.")),
			"recipe": recipe,
		}
	var baseline: Dictionary = Tracer.build_polygon_data(
		trace_result["pieces"],
		source_image.get_size(),
		source_sprite.offset,
		source_sprite.centered,
		source_sprite.flip_h,
		source_sprite.flip_v
	)
	var matches: bool = (
		_packed_vector_arrays_match(node.polygon, baseline["vertices"])
		and node.polygons == baseline["polygons"]
		and node.color.is_equal_approx(trace_result["sample"])
	)
	return {
		"status": TargetStatus.CLEAN if matches else TargetStatus.MANUALLY_EDITED,
		"reason": "" if matches else "Generated geometry or color was changed manually.",
		"node": node,
		"trace_id": str(metadata.get("trace_id", "")),
		"recipe": recipe,
		"baseline": baseline,
		"baseline_color": trace_result["sample"],
	}


static func inspect_name(source_sprite: Sprite2D, requested_name: StringName) -> Dictionary:
	for child in source_sprite.get_children():
		if child.name != requested_name:
			continue
		return {
			"available": false,
			"node": child,
			"generated": child.has_meta(TRACE_METADATA),
		}
	return {"available": true}


static func _packed_vector_arrays_match(
	left: PackedVector2Array,
	right: PackedVector2Array
) -> bool:
	if left.size() != right.size():
		return false
	for index in left.size():
		if not left[index].is_equal_approx(right[index]):
			return false
	return true
