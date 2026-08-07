@tool
extends RefCounted

const Tracer := preload("res://addons/raster_region_polygon/raster_region_tracer.gd")

var source_sprite: Sprite2D
var source_image: Image
var recipe: RefCounted
var result: Dictionary = {}


func set_source(sprite: Sprite2D, image: Image) -> void:
	source_sprite = sprite
	source_image = image
	result.clear()


func rebuild() -> Dictionary:
	result.clear()
	if not is_instance_valid(source_sprite) or source_image == null:
		result = {"ok": false, "error": "No source sprite is loaded."}
		return result
	if recipe == null or not recipe.is_ready():
		result = {"ok": false, "error": "Select a seed pixel first."}
		return result
	result = Tracer.trace_region(
		source_image,
		recipe.seed,
		recipe.tolerance,
		recipe.vertex_error,
		recipe.include_alpha,
		recipe.cleanup_radius,
		recipe.limit_polygon
	)
	return result


func is_ready() -> bool:
	return bool(result.get("ok", false))


func build_polygon_data() -> Dictionary:
	if not is_ready():
		return {}
	return Tracer.build_polygon_data(
		result["pieces"],
		source_image.get_size(),
		source_sprite.offset,
		source_sprite.centered,
		source_sprite.flip_h,
		source_sprite.flip_v
	)
