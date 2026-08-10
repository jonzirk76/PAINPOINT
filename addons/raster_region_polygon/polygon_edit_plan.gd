@tool
extends RefCounted

enum Kind {
	REJECT,
	MOVE_VERTICES,
	DELETE_VERTICES,
}

var kind := Kind.REJECT
var allowed := false
var reason := ""
var target: Polygon2D
var before := PackedVector2Array()
var after := PackedVector2Array()
var before_polygons: Array[PackedInt32Array] = []
var after_polygons: Array[PackedInt32Array] = []


static func reject(message: String) -> RefCounted:
	var plan: RefCounted = load(
		"res://addons/raster_region_polygon/polygon_edit_plan.gd"
	).new()
	plan.reason = message
	return plan

