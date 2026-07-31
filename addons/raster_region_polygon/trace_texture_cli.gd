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
	var cleanup_radius: int = int(options.get("cleanup-radius", 0))
	var limit_polygon: PackedVector2Array = _parse_limit_polygon(str(options.get("limit-points", "")))
	if options.has("limit-points") and limit_polygon.size() < 3:
		_fail("--limit-points requires at least three x,y pairs separated by semicolons.")
		return
	var include_alpha := _parse_bool(
		str(options.get("include-alpha", "true"))
	)
	var result: Dictionary = Tracer.trace_region(
		image,
		seed,
		tolerance,
		vertex_error,
		include_alpha,
		cleanup_radius,
		limit_polygon
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
	var updated_scene := ""
	if options.has("scene") or options.has("node"):
		if not options.has("scene") or not options.has("node"):
			_fail("--scene and --node must be supplied together.")
			return
		updated_scene = _update_scene_polygon(
			str(options["scene"]),
			str(options["node"]),
			result,
			sample,
			seed,
			tolerance,
			vertex_error,
			include_alpha,
			cleanup_radius,
			limit_polygon
		)
		if updated_scene.is_empty():
			return
	var output := {
		"ok": true,
		"texture": texture_path,
		"seed": [seed.x, seed.y],
		"image_size": [image_size.x, image_size.y],
		"sample_rgba": [sample.r, sample.g, sample.b, sample.a],
		"selected_pixel_count": result["selected_pixel_count"],
		"original_pixel_count": result["original_pixel_count"],
		"cleanup_pixel_delta": result["cleanup_pixel_delta"],
		"vertex_count": result["vertex_count"],
		"piece_count": result["piece_count"],
		"used_contour_repair": result["used_contour_repair"],
		"tolerance": tolerance,
		"vertex_error": vertex_error,
		"include_alpha": include_alpha,
		"cleanup_radius": cleanup_radius,
		"limit_point_count": limit_polygon.size(),
	}
	if not _parse_bool(str(options.get("summary-only", "false"))):
		output["points"] = points
		output["pieces"] = pieces
	if not updated_scene.is_empty():
		output["updated_scene"] = updated_scene
		output["updated_node"] = str(options["node"])
	if region.size != Vector2i.ZERO:
		output["source_region"] = [
			region.position.x,
			region.position.y,
			region.size.x,
			region.size.y,
		]
	print(JSON.stringify(output))
	quit(0)


func _update_scene_polygon(
	scene_path: String,
	node_path: String,
	result: Dictionary,
	sample: Color,
	seed: Vector2i,
	tolerance: float,
	vertex_error: float,
	include_alpha: bool,
	cleanup_radius: int,
	limit_polygon: PackedVector2Array
) -> String:
	var packed_scene: Resource = load(scene_path)
	if packed_scene == null or not packed_scene is PackedScene:
		_fail("Scene could not be loaded as PackedScene: %s" % scene_path)
		return ""
	var scene_root: Node = (packed_scene as PackedScene).instantiate()
	var node := scene_root.get_node_or_null(NodePath(node_path))
	if node == null or not node is Polygon2D:
		scene_root.free()
		_fail("Node is not a Polygon2D: %s" % node_path)
		return ""
	if not node.get_parent() is Sprite2D:
		scene_root.free()
		_fail("The target Polygon2D must be a child of its source Sprite2D.")
		return ""

	var polygon_node := node as Polygon2D
	var source_sprite := polygon_node.get_parent() as Sprite2D
	var polygon_data: Dictionary = Tracer.build_polygon_data(
		result["pieces"],
		result["image_size"],
		source_sprite.offset,
		source_sprite.centered,
		source_sprite.flip_h,
		source_sprite.flip_v
	)
	polygon_node.polygon = polygon_data["vertices"]
	polygon_node.polygons = polygon_data["polygons"]
	polygon_node.color = sample
	polygon_node.set_meta(&"raster_region_trace", {
		"version": 3,
		"seed": seed,
		"tolerance": tolerance,
		"vertex_error": vertex_error,
		"include_alpha": include_alpha,
		"cleanup_radius": cleanup_radius,
		"limit_polygon": limit_polygon,
	})

	var updated_scene := PackedScene.new()
	var pack_error := updated_scene.pack(scene_root)
	if pack_error != OK:
		scene_root.free()
		_fail("Could not pack updated scene (error %d)." % pack_error)
		return ""
	var save_error := ResourceSaver.save(updated_scene, scene_path)
	scene_root.free()
	if save_error != OK:
		_fail("Could not save updated scene (error %d)." % save_error)
		return ""
	return scene_path


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


func _parse_limit_polygon(value: String) -> PackedVector2Array:
	var points := PackedVector2Array()
	if value.strip_edges().is_empty():
		return points
	for encoded_point in value.split(";", false):
		var coordinates := encoded_point.split(",", false)
		if coordinates.size() != 2:
			return PackedVector2Array()
		points.append(Vector2(float(coordinates[0]), float(coordinates[1])))
	return points


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
