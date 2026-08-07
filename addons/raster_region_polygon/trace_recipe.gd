@tool
extends RefCounted

const METADATA_VERSION := 4

var seed := Vector2i(-1, -1)
var tolerance := 0.08
var vertex_error := 1.5
var cleanup_radius := 0
var include_alpha := true
var limit_polygon := PackedVector2Array()


static func from_metadata(metadata: Dictionary) -> RefCounted:
	var recipe: RefCounted = load("res://addons/raster_region_polygon/trace_recipe.gd").new()
	var values: Dictionary = metadata.get("recipe", metadata)
	var stored_seed: Variant = values.get("seed", Vector2i(-1, -1))
	if stored_seed is Vector2i:
		recipe.seed = stored_seed
	elif stored_seed is Vector2:
		recipe.seed = Vector2i(stored_seed)
	recipe.tolerance = float(values.get("tolerance", 0.08))
	recipe.vertex_error = float(values.get("vertex_error", 1.5))
	recipe.cleanup_radius = int(values.get("cleanup_radius", 0))
	recipe.include_alpha = bool(values.get("include_alpha", true))
	recipe.limit_polygon = _read_limit_polygon(
		values.get("limit_polygon", PackedVector2Array())
	)
	return recipe


func duplicate_recipe() -> RefCounted:
	return from_metadata(to_dictionary())


func to_dictionary() -> Dictionary:
	return {
		"seed": seed,
		"tolerance": tolerance,
		"vertex_error": vertex_error,
		"cleanup_radius": cleanup_radius,
		"include_alpha": include_alpha,
		"limit_polygon": limit_polygon,
	}


func to_metadata(trace_id: String) -> Dictionary:
	return {
		"version": METADATA_VERSION,
		"trace_id": trace_id,
		"recipe": to_dictionary(),
	}


func is_ready() -> bool:
	return seed.x >= 0 and seed.y >= 0


static func _read_limit_polygon(value: Variant) -> PackedVector2Array:
	if value is PackedVector2Array:
		return value.duplicate()
	var points := PackedVector2Array()
	if value is Array:
		for point in value:
			if point is Vector2:
				points.append(point)
	return points
