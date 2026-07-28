extends SceneTree

const BoxProjectionUtil := preload("res://scripts/tools/construction_lab/box_projection.gd")
const GENERATED_DIR := "res://scenes/tools/construction_lab/generated"
const BATCH_SEED := 250
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const AXIS_COLORS := {
	"x": Color("#ef6a69"),
	"y": Color("#66c88a"),
	"z": Color("#62a8ef"),
}
const PALETTES := [
	[Color("#315a88"), Color("#4779aa"), Color("#6a9bc8")],
	[Color("#6c417f"), Color("#8a5a9f"), Color("#ad7cbd")],
	[Color("#397063"), Color("#4d8b7b"), Color("#75aa99")],
	[Color("#8a5538"), Color("#ad7048"), Color("#ce9568")],
]


func _initialize() -> void:
	var absolute_dir := ProjectSettings.globalize_path(GENERATED_DIR)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if make_error != OK and make_error != ERR_ALREADY_EXISTS:
		push_error("Could not create generated visual batch directory (error %d)." % make_error)
		quit(1)
		return

	var batch := BoxProjectionUtil.build_default_batch(BATCH_SEED)
	var manifest_lines := PackedStringArray([
		"Generated visual box batch",
		"",
		"Open any .tscn in this folder and press F6.",
		"These files are intentionally generated review artifacts and are not committed.",
		"",
	])
	for index in range(batch.size()):
		var case_data: Dictionary = batch[index]
		var slug := _slugify(String(case_data["name"]))
		var scene_path := "%s/%02d_%s_proof.tscn" % [GENERATED_DIR, index + 1, slug]
		var packed_scene := _build_proof_scene(case_data, index)
		var save_error := ResourceSaver.save(packed_scene, scene_path)
		if save_error != OK:
			push_error("Could not save %s (error %d)." % [scene_path, save_error])
			quit(1)
			return
		manifest_lines.append("%02d  %s  ->  %s" % [index + 1, case_data["name"], scene_path])
		print("Generated %s" % scene_path)

	var manifest_path := "%s/README.txt" % GENERATED_DIR
	var manifest := FileAccess.open(manifest_path, FileAccess.WRITE)
	if manifest == null:
		push_error("Could not write %s." % manifest_path)
		quit(1)
		return
	manifest.store_string("\n".join(manifest_lines) + "\n")
	manifest.close()
	print("Generated visual batch manifest: %s" % manifest_path)
	quit(0)


func _build_proof_scene(case_data: Dictionary, case_index: int) -> PackedScene:
	var root := Node2D.new()
	root.name = "BoxProof%02d%s" % [case_index + 1, _pascal_case(String(case_data["name"]))]
	var background := Polygon2D.new()
	background.name = "Background"
	background.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(VIEWPORT_SIZE.x, 0.0),
		VIEWPORT_SIZE,
		Vector2(0.0, VIEWPORT_SIZE.y),
	])
	background.color = Color("#101722")
	_add_owned(root, background, root)

	var metrics: Dictionary = case_data["metrics"]
	_add_label(
		root,
		root,
		"Title",
		Vector2(30.0, 18.0),
		"%02d  %s — score %.2f (%s)" % [
			case_index + 1,
			case_data["name"],
			float(metrics["overall_score"]),
			metrics["rating"],
		],
		28,
		Color("#f0f4fa")
	)
	_add_label(
		root,
		root,
		"Instructions",
		Vector2(30.0, 57.0),
		"LEFT: shaded attempted Polygon2D faces.  RIGHT: exact target rays meet the diamond; bright attempted extensions reveal drift.",
		16,
		Color("#aebbd0")
	)

	_build_main_box(root, case_data, case_index)
	for axis_index in range(BoxProjectionUtil.AXIS_NAMES.size()):
		_build_axis_proof(root, case_data, BoxProjectionUtil.AXIS_NAMES[axis_index], axis_index)

	_add_label(
		root,
		root,
		"Metrics",
		Vector2(32.0, 665.0),
		"corner RMSE %.2f px   convergence %.2f°   valid faces %d/%d   area error %.1f%%" % [
			float(metrics["corner_rmse_px"]),
			float(metrics["edge_angle_mean_deg"]),
			int(metrics["valid_faces"]),
			int(metrics["face_count"]),
			float(metrics["face_area_mean_relative_error"]) * 100.0,
		],
		17,
		Color("#c7d1df")
	)

	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("Could not pack visual proof scene (error %d)." % pack_error)
	root.free()
	return packed


func _build_main_box(root: Node2D, case_data: Dictionary, case_index: int) -> void:
	var panel := _add_panel(root, root, "AttemptedForm", Rect2(28.0, 96.0, 610.0, 548.0), Color("#182333"))
	_add_label(panel, root, "PanelTitle", Vector2(16.0, 12.0), "ATTEMPTED FORM", 19, Color("#e8edf5"))
	var projection: Dictionary = case_data["projection"]
	var attempt: Dictionary = case_data["attempt"]
	var palette: Array = PALETTES[case_index % PALETTES.size()]
	var box_group := Node2D.new()
	box_group.name = "PolygonBox"
	box_group.position = Vector2(305.0, 282.0)
	box_group.scale = Vector2(1.65, 1.65)
	_add_owned(panel, box_group, root)

	var shade_index := 0
	for ground_face: Dictionary in projection["faces"]:
		if not bool(ground_face["visible"]):
			continue
		var face := Polygon2D.new()
		face.name = "Face%s" % _pascal_case(String(ground_face["name"]))
		face.polygon = _attempt_face_points(attempt["corners"], ground_face["indices"])
		face.color = palette[shade_index % palette.size()]
		_add_owned(box_group, face, root)
		var outline := Line2D.new()
		outline.name = "%sOutline" % face.name
		outline.points = _closed_points(face.polygon)
		outline.width = 1.6
		outline.default_color = Color(0.94, 0.97, 1.0, 0.62)
		outline.antialiased = true
		_add_owned(box_group, outline, root)
		shade_index += 1

	var exact_cage := Node2D.new()
	exact_cage.name = "ExactWhiteCage"
	_add_owned(box_group, exact_cage, root)
	for axis_name: String in BoxProjectionUtil.AXIS_NAMES:
		for edge_index in range(projection["edges"][axis_name].size()):
			var exact_edge: Dictionary = projection["edges"][axis_name][edge_index]
			_add_line(
				exact_cage,
				root,
				"%sExact%02d" % [axis_name.to_upper(), edge_index + 1],
				PackedVector2Array([exact_edge["a"], exact_edge["b"]]),
				Color(0.95, 0.97, 1.0, 0.30),
				1.2
			)

	var attempted_cage := Node2D.new()
	attempted_cage.name = "AttemptedAxisCage"
	_add_owned(box_group, attempted_cage, root)
	for axis_name: String in BoxProjectionUtil.AXIS_NAMES:
		for edge_index in range(attempt["edges"][axis_name].size()):
			var edge: Dictionary = attempt["edges"][axis_name][edge_index]
			_add_line(
				attempted_cage,
				root,
				"%sAttempt%02d" % [axis_name.to_upper(), edge_index + 1],
				PackedVector2Array([edge["a"], edge["b"]]),
				AXIS_COLORS[axis_name],
				2.4
			)
	for corner_index in range(attempt["corners"].size()):
		var marker := Polygon2D.new()
		marker.name = "Corner%02d" % (corner_index + 1)
		marker.position = attempt["corners"][corner_index]
		marker.polygon = _diamond_points(2.7)
		marker.color = Color("#ffffff")
		_add_owned(attempted_cage, marker, root)

	var legend_y := 472.0
	for axis_index in range(BoxProjectionUtil.AXIS_NAMES.size()):
		var axis_name: String = BoxProjectionUtil.AXIS_NAMES[axis_index]
		var key := Polygon2D.new()
		key.name = "%sLegendKey" % axis_name.to_upper()
		key.position = Vector2(18.0 + axis_index * 128.0, legend_y + 6.0)
		key.polygon = PackedVector2Array([Vector2.ZERO, Vector2(20.0, 0.0), Vector2(20.0, 4.0), Vector2(0.0, 4.0)])
		key.color = AXIS_COLORS[axis_name]
		_add_owned(panel, key, root)
		_add_label(
			panel,
			root,
			"%sLegend" % axis_name.to_upper(),
			Vector2(44.0 + axis_index * 128.0, legend_y - 3.0),
			"%s edges" % axis_name.to_upper(),
			14,
			Color("#c9d3e1")
		)


func _build_axis_proof(
	root: Node2D,
	case_data: Dictionary,
	axis_name: String,
	axis_index: int
) -> void:
	var panel_rect := Rect2(660.0, 96.0 + axis_index * 182.0, 592.0, 170.0)
	var panel := _add_panel(
		root,
		root,
		"%sVanishingPointProof" % axis_name.to_upper(),
		panel_rect,
		Color("#151f2d")
	)
	var metrics: Dictionary = case_data["metrics"]
	_add_label(
		panel,
		root,
		"AxisTitle",
		Vector2(14.0, 9.0),
		"%s VANISHING POINT PROOF — mean attempt error %.2f°" % [
			axis_name.to_upper(),
			float(metrics["axis_angle_mean_deg"][axis_name]),
		],
		16,
		AXIS_COLORS[axis_name]
	)

	var projection: Dictionary = case_data["projection"]
	var attempt: Dictionary = case_data["attempt"]
	var vanishing_point: Variant = projection["vanishing_points"][axis_name]
	if vanishing_point == null:
		_add_label(panel, root, "ParallelNotice", Vector2(18.0, 70.0), "Vanishing point is at infinity.", 16, Color("#d9dfeb"))
		return

	var fit_points: Array[Vector2] = []
	for edge: Dictionary in projection["edges"][axis_name]:
		fit_points.append(edge["a"])
		fit_points.append(edge["b"])
	var intended_vp: Vector2 = vanishing_point
	fit_points.append(intended_vp)
	var inner_rect := Rect2(16.0, 38.0, panel_rect.size.x - 32.0, panel_rect.size.y - 50.0)
	var transform_data := _fit_transform(fit_points, inner_rect)
	var fit_scale: float = transform_data["scale"]
	var fit_offset: Vector2 = transform_data["offset"]
	var vp_screen: Vector2 = intended_vp * fit_scale + fit_offset

	var exact_rays := Node2D.new()
	exact_rays.name = "ExactTargetRays"
	_add_owned(panel, exact_rays, root)
	for edge_index in range(projection["edges"][axis_name].size()):
		var exact_edge: Dictionary = projection["edges"][axis_name][edge_index]
		var start: Vector2 = exact_edge["a"] * fit_scale + fit_offset
		_add_line(
			exact_rays,
			root,
			"TargetRay%02d" % (edge_index + 1),
			PackedVector2Array([start, vp_screen]),
			Color(0.88, 0.92, 0.98, 0.28),
			1.2
		)

	var attempted_extensions := Node2D.new()
	attempted_extensions.name = "AttemptedExtensions"
	_add_owned(panel, attempted_extensions, root)
	for edge_index in range(attempt["edges"][axis_name].size()):
		var attempted_edge: Dictionary = attempt["edges"][axis_name][edge_index]
		var start: Vector2 = attempted_edge["a"] * fit_scale + fit_offset
		var end: Vector2 = attempted_edge["b"] * fit_scale + fit_offset
		var extended_end := _ray_to_rect_boundary(start, end - start, inner_rect)
		_add_line(
			attempted_extensions,
			root,
			"AttemptExtension%02d" % (edge_index + 1),
			PackedVector2Array([start, extended_end]),
			AXIS_COLORS[axis_name],
			1.8
		)
		var edge_segment := _add_line(
			attempted_extensions,
			root,
			"AttemptEdge%02d" % (edge_index + 1),
			PackedVector2Array([start, end]),
			AXIS_COLORS[axis_name].lightened(0.20),
			3.0
		)
		edge_segment.z_index = 2

	var vp_marker := Polygon2D.new()
	vp_marker.name = "IntendedVanishingPoint"
	vp_marker.position = vp_screen
	vp_marker.polygon = _diamond_points(7.0)
	vp_marker.color = Color("#fff3a8")
	vp_marker.z_index = 4
	_add_owned(panel, vp_marker, root)
	_add_label(
		panel,
		root,
		"VanishingPointLabel",
		vp_screen + Vector2(10.0, -11.0),
		"VP",
		13,
		Color("#fff3a8")
	)


func _add_panel(
	parent: Node,
	root: Node,
	node_name: String,
	rect: Rect2,
	color: Color
) -> Node2D:
	var panel := Node2D.new()
	panel.name = node_name
	panel.position = rect.position
	_add_owned(parent, panel, root)
	var fill := Polygon2D.new()
	fill.name = "PanelFill"
	fill.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(rect.size.x, 0.0),
		rect.size,
		Vector2(0.0, rect.size.y),
	])
	fill.color = color
	_add_owned(panel, fill, root)
	var border := Line2D.new()
	border.name = "PanelBorder"
	border.points = _closed_points(fill.polygon)
	border.width = 1.2
	border.default_color = Color("#35445a")
	border.antialiased = true
	_add_owned(panel, border, root)
	return panel


func _add_label(
	parent: Node,
	root: Node,
	node_name: String,
	position: Vector2,
	text_value: String,
	font_size: int,
	color: Color
) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = position
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_add_owned(parent, label, root)
	return label


func _add_line(
	parent: Node,
	root: Node,
	node_name: String,
	points: PackedVector2Array,
	color: Color,
	width: float
) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.default_color = color
	line.width = width
	line.antialiased = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	_add_owned(parent, line, root)
	return line


func _add_owned(parent: Node, child: Node, root: Node) -> void:
	parent.add_child(child)
	child.owner = root


func _attempt_face_points(corners: Array, indices: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in indices:
		points.append(corners[index])
	return points


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed


func _diamond_points(radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -radius),
		Vector2(radius, 0.0),
		Vector2(0.0, radius),
		Vector2(-radius, 0.0),
	])


func _fit_transform(points: Array[Vector2], target: Rect2) -> Dictionary:
	var minimum := points[0]
	var maximum := points[0]
	for point: Vector2 in points:
		minimum.x = minf(minimum.x, point.x)
		minimum.y = minf(minimum.y, point.y)
		maximum.x = maxf(maximum.x, point.x)
		maximum.y = maxf(maximum.y, point.y)
	var source_size := maximum - minimum
	var fit_scale := minf(
		target.size.x / maxf(source_size.x, 1.0),
		target.size.y / maxf(source_size.y, 1.0)
	)
	fit_scale *= 0.90
	var source_center := (minimum + maximum) * 0.5
	return {
		"scale": fit_scale,
		"offset": target.get_center() - source_center * fit_scale,
	}


func _ray_to_rect_boundary(start: Vector2, direction: Vector2, rect: Rect2) -> Vector2:
	if direction.length_squared() <= 0.000001:
		return start
	var normalized := direction.normalized()
	var candidates: Array[float] = []
	if absf(normalized.x) > 0.00001:
		candidates.append((rect.position.x - start.x) / normalized.x)
		candidates.append((rect.end.x - start.x) / normalized.x)
	if absf(normalized.y) > 0.00001:
		candidates.append((rect.position.y - start.y) / normalized.y)
		candidates.append((rect.end.y - start.y) / normalized.y)
	var best_distance := 0.0
	for distance: float in candidates:
		if distance <= 0.0:
			continue
		var hit := start + normalized * distance
		if (
			hit.x >= rect.position.x - 0.1
			and hit.x <= rect.end.x + 0.1
			and hit.y >= rect.position.y - 0.1
			and hit.y <= rect.end.y + 0.1
			and distance > best_distance
		):
			best_distance = distance
	return start + normalized * best_distance


func _slugify(value: String) -> String:
	return value.to_lower().replace(" ", "_").replace("-", "_")


func _pascal_case(value: String) -> String:
	var output := ""
	for part: String in value.replace("-", " ").replace("_", " ").split(" ", false):
		output += part.capitalize()
	return output
