extends SceneTree

const BoxProjectionUtil := preload("res://scripts/tools/construction_lab/box_projection.gd")
const LoomisProjectionUtil := preload("res://scripts/tools/construction_lab/loomis_head_projection.gd")

const GENERATED_DIR := "res://scenes/tools/anatomy/generated_loomis_step3"
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const CUBE_FACE_COLORS := {
	"x": Color(0.94, 0.43, 0.42, 0.10),
	"y": Color(0.40, 0.80, 0.56, 0.10),
	"z": Color(0.40, 0.66, 0.94, 0.10),
}
const AXIS_COLORS := {
	"x": Color("#ef6a69"),
	"y": Color("#66c88a"),
	"z": Color("#62a8ef"),
}


func _initialize() -> void:
	var absolute_dir := ProjectSettings.globalize_path(GENERATED_DIR)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if make_error != OK and make_error != ERR_ALREADY_EXISTS:
		push_error("Could not create generated Loomis directory (error %d)." % make_error)
		quit(1)
		return

	var batch := LoomisProjectionUtil.build_default_tilt_batch()
	var manifest_lines := PackedStringArray([
		"Generated Loomis step-3 head tilt batch",
		"",
		"Open any .tscn in this folder and press F6.",
		"Toggle ComplianceCube, Step1Sphere, Step2SidePlaneCut, or Step3Midlines in the scene tree.",
		"These generated visual review artifacts are intentionally untracked.",
		"",
	])
	for index in range(batch.size()):
		var case_data: Dictionary = batch[index]
		var scene_path := "%s/%02d_%s.tscn" % [
			GENERATED_DIR,
			index + 1,
			_slugify(String(case_data["name"])),
		]
		var packed := _build_scene(case_data, index)
		var save_error := ResourceSaver.save(packed, scene_path)
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
	print("Generated Loomis step-3 manifest: %s" % manifest_path)
	quit(0)


func _build_scene(case_data: Dictionary, case_index: int) -> PackedScene:
	var root := Node2D.new()
	root.name = "LoomisStep3%02d%s" % [case_index + 1, _pascal_case(String(case_data["name"]))]
	_add_background(root)
	var construction: Dictionary = case_data["construction"]
	var spec: Dictionary = construction["spec"]
	_add_label(
		root,
		root,
		"Title",
		Vector2(30.0, 17.0),
		"%02d  LOOMIS STEP 3 — %s" % [case_index + 1, case_data["name"]],
		28,
		Color("#f0f4fa")
	)
	_add_label(
		root,
		root,
		"PoseReadout",
		Vector2(31.0, 58.0),
		"pitch %.1f°   yaw %.1f°   roll %.1f°   |   cube, side slice, and midlines share one 3D Basis" % [
			float(spec["rotation_degrees"].x),
			float(spec["rotation_degrees"].y),
			float(spec["rotation_degrees"].z),
		],
		16,
		Color("#aebbd0")
	)

	var construction_panel := _add_panel(
		root,
		root,
		"ConstructionPanel",
		Rect2(28.0, 96.0, 790.0, 590.0),
		Color("#182333")
	)
	var display := Node2D.new()
	display.name = "SharedProjection"
	display.position = Vector2(395.0, 310.0)
	display.scale = Vector2(2.25, 2.25)
	_add_owned(construction_panel, display, root)
	_add_compliance_cube(display, root, construction["compliance_cube"])
	_add_step1_sphere(display, root, construction)
	_add_step2_side_plane(display, root, construction)
	_add_step3_midlines(display, root, construction)

	_add_label(
		construction_panel,
		root,
		"ConstructionCaption",
		Vector2(18.0, 539.0),
		"Translucent cube = orientation audit only. It is not part of the head silhouette.",
		15,
		Color("#b9c7d9")
	)
	_add_reference_panel(root, construction, spec)

	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("Could not pack Loomis step-3 scene (error %d)." % pack_error)
	root.free()
	return packed


func _add_background(root: Node2D) -> void:
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


func _add_compliance_cube(parent: Node2D, root: Node2D, cube: Dictionary) -> void:
	var group := Node2D.new()
	group.name = "ComplianceCube"
	_add_owned(parent, group, root)
	var visible_faces := Node2D.new()
	visible_faces.name = "TranslucentPolygonFaces"
	_add_owned(group, visible_faces, root)
	for face: Dictionary in cube["faces"]:
		if not bool(face["visible"]):
			continue
		var axis_name := String(face["name"]).left(1)
		var polygon := Polygon2D.new()
		polygon.name = "%sFace" % _pascal_case(String(face["name"]))
		polygon.polygon = face["points"]
		polygon.color = CUBE_FACE_COLORS[axis_name]
		_add_owned(visible_faces, polygon, root)
	var cage := Node2D.new()
	cage.name = "PerspectiveEdges"
	_add_owned(group, cage, root)
	for axis_name: String in BoxProjectionUtil.AXIS_NAMES:
		for edge_index in range(cube["edges"][axis_name].size()):
			var edge: Dictionary = cube["edges"][axis_name][edge_index]
			var color: Color = AXIS_COLORS[axis_name]
			color.a = 0.32
			_add_line(
				cage,
				root,
				"%sEdge%02d" % [axis_name.to_upper(), edge_index + 1],
				PackedVector2Array([edge["a"], edge["b"]]),
				color,
				1.15
			)


func _add_step1_sphere(parent: Node2D, root: Node2D, construction: Dictionary) -> void:
	var group := Node2D.new()
	group.name = "Step1Sphere"
	_add_owned(parent, group, root)
	var sphere_fill := Polygon2D.new()
	sphere_fill.name = "CraniumSphere"
	sphere_fill.polygon = construction["sphere_silhouette"]
	sphere_fill.color = Color(0.42, 0.66, 0.88, 0.19)
	_add_owned(group, sphere_fill, root)
	_add_line(
		group,
		root,
		"SphereContour",
		_closed_points(construction["sphere_silhouette"]),
		Color("#dbeaff"),
		2.2
	)


func _add_step2_side_plane(parent: Node2D, root: Node2D, construction: Dictionary) -> void:
	var group := Node2D.new()
	group.name = "Step2SidePlaneCut"
	_add_owned(parent, group, root)
	var side_fill := Polygon2D.new()
	side_fill.name = "SidePlaneEllipse"
	side_fill.polygon = _without_duplicate_close(construction["side_plane"])
	side_fill.color = Color(0.94, 0.57, 0.38, 0.28)
	_add_owned(group, side_fill, root)
	_add_line(
		group,
		root,
		"SidePlaneContour",
		construction["side_plane"],
		Color("#f2a06f"),
		2.0
	)
	_add_line(
		group,
		root,
		"SidePlaneVerticalAxis",
		construction["side_vertical_axis"],
		Color(1.0, 0.80, 0.61, 0.82),
		1.2
	)
	_add_line(
		group,
		root,
		"SidePlaneDepthAxis",
		construction["side_depth_axis"],
		Color(1.0, 0.72, 0.48, 0.70),
		1.2
	)


func _add_step3_midlines(parent: Node2D, root: Node2D, construction: Dictionary) -> void:
	var group := Node2D.new()
	group.name = "Step3Midlines"
	_add_owned(parent, group, root)
	_add_line(
		group,
		root,
		"VerticalCenterLine",
		construction["vertical_midline"],
		Color("#5ee0ec"),
		2.1
	)
	_add_line(
		group,
		root,
		"BrowMidline",
		construction["brow_midline"],
		Color("#f09ac0"),
		2.1
	)
	var center_marker := Polygon2D.new()
	center_marker.name = "FrontCenterIntersection"
	center_marker.position = construction["front_center"]
	center_marker.polygon = PackedVector2Array([
		Vector2(0.0, -2.8),
		Vector2(2.8, 0.0),
		Vector2(0.0, 2.8),
		Vector2(-2.8, 0.0),
	])
	center_marker.color = Color("#fff3a8")
	_add_owned(group, center_marker, root)


func _add_reference_panel(root: Node2D, construction: Dictionary, spec: Dictionary) -> void:
	var panel := _add_panel(
		root,
		root,
		"JudgingPanel",
		Rect2(842.0, 96.0, 410.0, 590.0),
		Color("#151f2d")
	)
	_add_label(panel, root, "PanelTitle", Vector2(18.0, 15.0), "STEP GROUPS", 20, Color("#e9eef6"))
	_add_stage_row(
		panel,
		root,
		"Step1",
		80.0,
		Color("#dbeaff"),
		"STEP 1 — SPHERE",
		"Projected spherical silhouette remains circular."
	)
	_add_stage_row(
		panel,
		root,
		"Step2",
		172.0,
		Color("#f2a06f"),
		"STEP 2 — SIDE-PLANE CUT",
		"Ellipse is a fixed %.0f%% radius slice on the near side." % (float(spec["side_cut_ratio"]) * 100.0)
	)
	_add_stage_row(
		panel,
		root,
		"Step3",
		278.0,
		Color("#5ee0ec"),
		"STEP 3 — SPHERICAL MIDLINES",
		"Center and brow curves share the same rotated sphere."
	)
	_add_label(panel, root, "ChecksTitle", Vector2(18.0, 386.0), "VISUAL ACCEPTANCE", 18, Color("#fff3a8"))
	_add_label(
		panel,
		root,
		"Checks",
		Vector2(18.0, 422.0),
		"• ellipse stays inside the sphere\n• midlines meet at the yellow front center\n• pitch, yaw, and roll move every guide together\n• cube axes agree with the head tilt\n• no jaw or facial proportions are inferred yet",
		15,
		Color("#c3cedd")
	)
	_add_label(
		panel,
		root,
		"SideReadout",
		Vector2(18.0, 545.0),
		"Near-side slice: %s" % ("RIGHT (+X)" if float(construction["side_sign"]) > 0.0 else "LEFT (-X)"),
		14,
		Color("#aebbd0")
	)


func _add_stage_row(
	parent: Node,
	root: Node,
	node_name: String,
	y_position: float,
	color: Color,
	title: String,
	description: String
) -> void:
	var swatch := Polygon2D.new()
	swatch.name = "%sSwatch" % node_name
	swatch.position = Vector2(20.0, y_position + 8.0)
	swatch.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(20.0, 0.0),
		Vector2(20.0, 20.0),
		Vector2(0.0, 20.0),
	])
	swatch.color = color
	_add_owned(parent, swatch, root)
	_add_label(parent, root, "%sTitle" % node_name, Vector2(54.0, y_position), title, 16, color)
	var description_label := _add_label(
		parent,
		root,
		"%sDescription" % node_name,
		Vector2(54.0, y_position + 31.0),
		description,
		14,
		Color("#b9c5d5")
	)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(322.0, 44.0)


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
	_add_line(
		panel,
		root,
		"PanelBorder",
		_closed_points(fill.polygon),
		Color("#35445a"),
		1.2
	)
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


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed


func _without_duplicate_close(points: PackedVector2Array) -> PackedVector2Array:
	var polygon := points.duplicate()
	if polygon.size() > 1 and polygon[0].is_equal_approx(polygon[polygon.size() - 1]):
		polygon.remove_at(polygon.size() - 1)
	return polygon


func _slugify(value: String) -> String:
	return value.to_lower().replace(" ", "_").replace("-", "_")


func _pascal_case(value: String) -> String:
	var output := ""
	for part: String in value.replace("-", " ").replace("_", " ").split(" ", false):
		output += part.capitalize()
	return output
