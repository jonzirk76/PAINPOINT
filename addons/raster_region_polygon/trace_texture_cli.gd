extends SceneTree

const Tracer := preload("res://addons/raster_region_polygon/raster_region_tracer.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	for required_key in ["texture", "x", "y"]:
		if not options.has(required_key):
			_fail("Missing required --%s argument." % required_key)
			return

	var texture_path := str(options["texture"])
	var resource: Resource = load(texture_path)
	if resource == null or not resource is Texture2D:
		_fail("Texture could not be loaded as Texture2D: %s" % texture_path)
		return

	var texture := resource as Texture2D
	var image := texture.get_image()
	if image == null or image.is_empty():
		_fail("Godot could not read image data from: %s" % texture_path)
		return
	var region := _read_region(options)
	if region.size != Vector2i.ZERO:
		var image_bounds := Rect2i(Vector2i.ZERO, image.get_size())
		if not image_bounds.encloses(region):
			_fail("Requested region is outside the source texture.")
			return
		image = image.get_region(region)

	var seed := Vector2i(
		int(options["x"]),
		int(options["y"])
	)
	var tolerance := float(options.get("tolerance", 0.08))
	var vertex_error := float(options.get("vertex-error", 1.5))
	var include_alpha := _parse_bool(
		str(options.get("include-alpha", "true"))
	)
	var result: Dictionary = Tracer.trace_region(
		image,
		seed,
		tolerance,
		vertex_error,
		include_alpha
	)
	if not result.get("ok", false):
		_fail(str(result.get("error", "Trace failed.")), result)
		return

	var polygon: PackedVector2Array = result["polygon"]
	var points: Array[Array] = []
	for point in polygon:
		points.append([point.x, point.y])
	var pieces: Array[Array] = []
	for piece: PackedVector2Array in result["pieces"]:
		var piece_points: Array[Array] = []
		for point in piece:
			piece_points.append([point.x, point.y])
		pieces.append(piece_points)
	var sample: Color = result["sample"]
	var image_size: Vector2i = result["image_size"]
	var output := {
		"ok": true,
		"texture": texture_path,
		"seed": [seed.x, seed.y],
		"image_size": [image_size.x, image_size.y],
		"sample_rgba": [sample.r, sample.g, sample.b, sample.a],
		"selected_pixel_count": result["selected_pixel_count"],
		"vertex_count": result["vertex_count"],
		"piece_count": result["piece_count"],
		"used_piece_fallback": result["used_piece_fallback"],
		"tolerance": tolerance,
		"vertex_error": vertex_error,
		"include_alpha": include_alpha,
		"points": points,
		"pieces": pieces,
	}
	if region.size != Vector2i.ZERO:
		output["source_region"] = [
			region.position.x,
			region.position.y,
			region.size.x,
			region.size.y,
		]
	print(JSON.stringify(output))
	quit(0)


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var result := {}
	var index := 0
	while index < arguments.size():
		var argument := arguments[index]
		if not argument.begins_with("--"):
			index += 1
			continue
		var key := argument.trim_prefix("--")
		if index + 1 >= arguments.size():
			result[key] = "true"
			index += 1
			continue
		var value := arguments[index + 1]
		if value.begins_with("--"):
			result[key] = "true"
			index += 1
			continue
		result[key] = value
		index += 2
	return result


func _parse_bool(value: String) -> bool:
	return value.to_lower() not in ["0", "false", "no", "off"]


func _read_region(options: Dictionary) -> Rect2i:
	var region_keys := [
		"region-x",
		"region-y",
		"region-width",
		"region-height",
	]
	var has_any := false
	for key in region_keys:
		has_any = has_any or options.has(key)
	if not has_any:
		return Rect2i()
	for key in region_keys:
		if not options.has(key):
			return Rect2i()
	return Rect2i(
		int(options["region-x"]),
		int(options["region-y"]),
		int(options["region-width"]),
		int(options["region-height"])
	)


func _fail(message: String, details: Dictionary = {}) -> void:
	var output := details.duplicate()
	output["ok"] = false
	output["error"] = message
	output.erase("polygon")
	printerr(JSON.stringify(output))
	quit(1)
