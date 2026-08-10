@tool
extends RefCounted

var allowed := false
var reason := ""
var layout_path := ""
var source_path := ""
var instance_path := NodePath()
var instance_name := ""
var source_modified_time := 0
var instance_transform := Transform2D.IDENTITY
var draft_snapshot: Dictionary = {}
var source_snapshot: Dictionary = {}
var context_polygons: Array[Dictionary] = []
var has_instance_overrides := false


static func reject(message: String) -> RefCounted:
	var plan: RefCounted = load(
		"res://addons/raster_region_polygon/in_place_part_edit_plan.gd"
	).new()
	plan.reason = message
	return plan
