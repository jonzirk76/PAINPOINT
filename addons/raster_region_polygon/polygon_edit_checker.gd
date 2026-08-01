@tool
extends RefCounted

const TRACE_METADATA := &"raster_region_trace"


static func inspect_target(node: Polygon2D, expected: PackedVector2Array) -> Dictionary:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return {"valid": false, "reason": "The edit target is missing."}
	if not node.has_meta(TRACE_METADATA):
		return {"valid": false, "reason": "Only plugin-generated polygons can be edited."}
	if not _points_match(node.polygon, expected):
		return {
			"valid": false,
			"reason": "The polygon changed after the edit session began. Reload it before editing.",
		}
	return {"valid": true}


static func validate_geometry(
	points: PackedVector2Array,
	pieces: Array[PackedInt32Array]
) -> Dictionary:
	if points.size() < 3:
		return {"valid": false, "reason": "A polygon needs at least three vertices."}
	var effective_pieces: Array[PackedInt32Array] = pieces.duplicate(true)
	if effective_pieces.is_empty():
		effective_pieces = [PackedInt32Array(range(points.size()))]
	for indices in effective_pieces:
		if indices.size() < 3:
			return {"valid": false, "reason": "Deleting this selection would destroy a polygon piece."}
		var contour := PackedVector2Array()
		for index in indices:
			if index < 0 or index >= points.size():
				return {"valid": false, "reason": "Polygon piece indices are invalid."}
			contour.append(points[index])
		if Geometry2D.triangulate_polygon(contour).is_empty():
			return {
				"valid": false,
				"reason": "The proposed edit creates a self-intersection or invalid contour.",
			}
	return {"valid": true}


static func _points_match(left: PackedVector2Array, right: PackedVector2Array) -> bool:
	if left.size() != right.size():
		return false
	for index in left.size():
		if not left[index].is_equal_approx(right[index]):
			return false
	return true
