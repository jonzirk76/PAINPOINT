@tool
extends RefCounted

enum Kind {
	REJECT,
	CREATE,
	UPDATE,
	REGENERATE,
}

var kind := Kind.REJECT
var allowed := false
var reason := ""
var requested_name := ""
var target: Polygon2D
var requires_confirmation := false


static func reject(message: String) -> RefCounted:
	var plan: RefCounted = load("res://addons/raster_region_polygon/trace_operation_plan.gd").new()
	plan.reason = message
	return plan
