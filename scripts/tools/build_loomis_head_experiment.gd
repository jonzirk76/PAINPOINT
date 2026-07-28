extends SceneTree

const OUTPUT_PATH := "res://scenes/tools/anatomy/loomis_head_construction_experiment.tscn"
const REFERENCE_PATH := "res://art/concept_art/How_to_Draw_a_Head_Looing_Upward_Bruce_Wayne.jpg"

const GUIDE_COLOR := Color(0.22, 0.86, 0.92, 0.82)
const GUIDE_SECONDARY := Color(0.95, 0.48, 0.3, 0.72)
const CRANIUM_COLOR := Color("#b9a6d8")
const SIDE_PLANE_COLOR := Color("#77649b")
const SKIN_COLOR := Color("#e4af98")
const SKIN_LIGHT := Color("#f2c2ab")
const SKIN_SHADOW := Color("#bd7e78")
const HAIR_COLOR := Color("#33225f")
const HAIR_SHADOW := Color("#171035")
const EYE_COLOR := Color("#8b55db")
const FEATURE_COLOR := Color("#24172f")


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(
		"res://scenes/tools/anatomy"
	))
	var scene_root := Node2D.new()
	scene_root.name = "LoomisHeadConstructionExperiment"
	root.add_child(scene_root)

	_add_title(scene_root)
	_add_stage_one(scene_root, Vector2(275.0, 330.0))
	_add_stage_two(scene_root, Vector2(700.0, 330.0))
	_add_stage_three(scene_root, Vector2(1130.0, 330.0))
	_add_reference(scene_root)

	_set_owner_recursive(scene_root, scene_root)
	var packed_scene := PackedScene.new()
	var pack_error := packed_scene.pack(scene_root)
	if pack_error != OK:
		push_error("Could not pack Loomis experiment: %s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(packed_scene, OUTPUT_PATH)
	if save_error != OK:
		push_error("Could not save Loomis experiment: %s" % error_string(save_error))
		quit(1)
		return
	print("Built %s" % OUTPUT_PATH)
	quit()


func _add_title(parent: Node2D) -> void:
	var title := Label.new()
	title.name = "ExperimentTitle"
	title.position = Vector2(55.0, 25.0)
	title.text = "LOOMIS → PLANES → STYLED POLYGON HEAD"
	title.add_theme_font_size_override("font_size", 28)
	parent.add_child(title)
	var subtitle := Label.new()
	subtitle.name = "ExperimentNotes"
	subtitle.position = Vector2(55.0, 65.0)
	subtitle.text = "All construction groups are editable and independently toggleable. The final head preserves the scaffold beneath the hair and features."
	subtitle.add_theme_font_size_override("font_size", 17)
	parent.add_child(subtitle)


func _add_stage_one(parent: Node2D, origin: Vector2) -> void:
	var stage := Node2D.new()
	stage.name = "Stage1LoomisScaffold"
	stage.position = origin
	parent.add_child(stage)
	_add_stage_label(stage, "1  LOOMIS SCAFFOLD")
	var construction := Node2D.new()
	construction.name = "Construction"
	stage.add_child(construction)
	_add_polygon(
		construction,
		"CraniumSphere",
		Color(CRANIUM_COLOR, 0.34),
		_ellipse_points(Vector2(-24.0, -58.0), Vector2(125.0, 132.0), 24, -0.08)
	)
	_add_polygon(
		construction,
		"SidePlaneCut",
		Color(SIDE_PLANE_COLOR, 0.46),
		_ellipse_points(Vector2(-93.0, -52.0), Vector2(42.0, 76.0), 18, -0.08)
	)
	_add_polygon(construction, "JawWedge", Color(SKIN_SHADOW, 0.34), _jaw_polygon())
	_add_line(construction, "CraniumContour", _closed(
		_ellipse_points(Vector2(-24.0, -58.0), Vector2(125.0, 132.0), 24, -0.08)
	), GUIDE_COLOR, 3.0)
	_add_line(construction, "SidePlaneContour", _closed(
		_ellipse_points(Vector2(-93.0, -52.0), Vector2(42.0, 76.0), 18, -0.08)
	), GUIDE_SECONDARY, 3.0)
	_add_line(construction, "JawContour", _closed(_jaw_polygon()), GUIDE_COLOR, 3.0)
	_add_scaffold_guides(construction, 1.0)


func _add_stage_two(parent: Node2D, origin: Vector2) -> void:
	var stage := Node2D.new()
	stage.name = "Stage2AnatomicalPlanes"
	stage.position = origin
	parent.add_child(stage)
	_add_stage_label(stage, "2  ANATOMICAL PLANES")
	var construction := Node2D.new()
	construction.name = "ConstructionUnderlay"
	construction.modulate = Color(1.0, 1.0, 1.0, 0.42)
	stage.add_child(construction)
	_add_scaffold_guides(construction, 0.9)
	_add_line(construction, "CraniumGuide", _closed(
		_ellipse_points(Vector2(-24.0, -58.0), Vector2(125.0, 132.0), 24, -0.08)
	), GUIDE_COLOR, 2.0)

	var planes := Node2D.new()
	planes.name = "AnatomicalPlanes"
	stage.add_child(planes)
	_add_polygon(planes, "BackCranium", CRANIUM_COLOR, PackedVector2Array([
		Vector2(-139, -72), Vector2(-116, -145), Vector2(-47, -190),
		Vector2(34, -181), Vector2(70, -132), Vector2(28, -77),
		Vector2(-17, -36), Vector2(-66, 15), Vector2(-128, 2),
	]))
	_add_polygon(planes, "SidePlane", SIDE_PLANE_COLOR, PackedVector2Array([
		Vector2(-126, -116), Vector2(-82, -139), Vector2(-48, -105),
		Vector2(-50, -42), Vector2(-74, 14), Vector2(-119, 8),
		Vector2(-139, -44),
	]))
	_add_polygon(planes, "ForeheadPlane", SKIN_LIGHT, PackedVector2Array([
		Vector2(-48, -105), Vector2(28, -128), Vector2(79, -93),
		Vector2(91, -43), Vector2(13, -48), Vector2(-47, -39),
	]))
	_add_polygon(planes, "NearCheekPlane", SKIN_COLOR, PackedVector2Array([
		Vector2(-47, -39), Vector2(13, -48), Vector2(50, 8),
		Vector2(34, 54), Vector2(-23, 74), Vector2(-70, 24),
	]))
	_add_polygon(planes, "FarCheekPlane", Color("#cf918b"), PackedVector2Array([
		Vector2(13, -48), Vector2(91, -43), Vector2(108, 4),
		Vector2(78, 23), Vector2(50, 8),
	]))
	_add_polygon(planes, "NoseWedge", Color("#d79790"), PackedVector2Array([
		Vector2(65, -39), Vector2(91, -26), Vector2(111, 1),
		Vector2(84, 17), Vector2(65, 5),
	]))
	_add_polygon(planes, "MuzzlePlane", Color("#e8b19f"), PackedVector2Array([
		Vector2(34, 54), Vector2(78, 23), Vector2(92, 58),
		Vector2(59, 80), Vector2(18, 78),
	]))
	_add_polygon(planes, "JawPlane", SKIN_COLOR, PackedVector2Array([
		Vector2(-70, 24), Vector2(-23, 74), Vector2(18, 78),
		Vector2(59, 80), Vector2(48, 119), Vector2(5, 134),
		Vector2(-54, 102), Vector2(-96, 39),
	]))
	_add_polygon(planes, "JawUnderside", SKIN_SHADOW, PackedVector2Array([
		Vector2(-54, 102), Vector2(5, 134), Vector2(48, 119),
		Vector2(28, 145), Vector2(-20, 148),
	]))
	_add_polygon(planes, "EarBlock", Color("#c98680"), _ellipse_points(
		Vector2(-105.0, 12.0), Vector2(30.0, 44.0), 12, -0.15
	))


func _add_stage_three(parent: Node2D, origin: Vector2) -> void:
	var stage := Node2D.new()
	stage.name = "Stage3VoletteStyledHead"
	stage.position = origin
	parent.add_child(stage)
	_add_stage_label(stage, "3  VOLETTE STYLE")

	var back_shapes := Node2D.new()
	back_shapes.name = "BackShapes"
	stage.add_child(back_shapes)
	_add_polygon(back_shapes, "NeckShadow", Color("#9e6670"), PackedVector2Array([
		Vector2(-45, 90), Vector2(43, 104), Vector2(50, 171),
		Vector2(-55, 171), Vector2(-62, 121),
	]))
	_add_polygon(back_shapes, "BackHair", HAIR_SHADOW, PackedVector2Array([
		Vector2(-149, -80), Vector2(-120, -164), Vector2(-43, -202),
		Vector2(48, -191), Vector2(95, -129), Vector2(104, -51),
		Vector2(86, 42), Vector2(78, 128), Vector2(38, 174),
		Vector2(8, 116), Vector2(-31, 174), Vector2(-72, 117),
		Vector2(-119, 72), Vector2(-151, 2),
	]))
	_add_polygon(back_shapes, "Neck", SKIN_COLOR, PackedVector2Array([
		Vector2(-42, 77), Vector2(45, 92), Vector2(34, 166),
		Vector2(-40, 166), Vector2(-62, 116),
	]))

	var face := Node2D.new()
	face.name = "FacePlanes"
	stage.add_child(face)
	_add_polygon(face, "FaceBase", SKIN_COLOR, PackedVector2Array([
		Vector2(-105, -77), Vector2(-48, -122), Vector2(31, -130),
		Vector2(81, -92), Vector2(97, -42), Vector2(112, 0),
		Vector2(87, 20), Vector2(91, 58), Vector2(58, 82),
		Vector2(47, 119), Vector2(6, 133), Vector2(-51, 103),
		Vector2(-91, 42), Vector2(-120, 8),
	]))
	_add_polygon(face, "FarFaceShadow", Color("#c98584"), PackedVector2Array([
		Vector2(31, -130), Vector2(81, -92), Vector2(97, -42),
		Vector2(112, 0), Vector2(87, 20), Vector2(52, 3),
		Vector2(17, -51),
	]))
	_add_polygon(face, "NearCheekLight", SKIN_LIGHT, PackedVector2Array([
		Vector2(-62, -40), Vector2(17, -51), Vector2(52, 3),
		Vector2(35, 54), Vector2(-23, 71), Vector2(-74, 24),
	]))
	_add_polygon(face, "JawShadow", SKIN_SHADOW, PackedVector2Array([
		Vector2(-51, 103), Vector2(6, 133), Vector2(47, 119),
		Vector2(58, 82), Vector2(14, 91),
	]))
	_add_polygon(face, "Ear", Color("#c98584"), _ellipse_points(
		Vector2(-108.0, 12.0), Vector2(29.0, 43.0), 12, -0.15
	))
	_add_polygon(face, "EarInner", Color("#8e5668"), PackedVector2Array([
		Vector2(-119, -5), Vector2(-99, -15), Vector2(-89, 9),
		Vector2(-102, 30), Vector2(-113, 17), Vector2(-101, 4),
	]))

	var features := Node2D.new()
	features.name = "FacialFeatures"
	stage.add_child(features)
	_add_polygon(features, "NearEyeWhite", Color("#f4ecfa"), PackedVector2Array([
		Vector2(-52, -48), Vector2(-13, -59), Vector2(4, -50),
		Vector2(-13, -36), Vector2(-44, -35),
	]))
	_add_polygon(features, "NearIris", EYE_COLOR, PackedVector2Array([
		Vector2(-29, -56), Vector2(-10, -52), Vector2(-12, -35),
		Vector2(-28, -36),
	]))
	_add_polygon(features, "NearUpperLash", FEATURE_COLOR, PackedVector2Array([
		Vector2(-57, -50), Vector2(-17, -64), Vector2(7, -53),
		Vector2(3, -47), Vector2(-17, -57), Vector2(-51, -44),
	]))
	_add_polygon(features, "FarEyeWhite", Color("#eee7f5"), PackedVector2Array([
		Vector2(38, -57), Vector2(68, -54), Vector2(82, -42),
		Vector2(60, -35), Vector2(39, -40),
	]))
	_add_polygon(features, "FarIris", EYE_COLOR, PackedVector2Array([
		Vector2(57, -55), Vector2(72, -48), Vector2(66, -35),
		Vector2(52, -39),
	]))
	_add_polygon(features, "FarUpperLash", FEATURE_COLOR, PackedVector2Array([
		Vector2(34, -61), Vector2(69, -58), Vector2(86, -44),
		Vector2(81, -39), Vector2(65, -51), Vector2(38, -53),
	]))
	_add_polygon(features, "NosePlane", Color("#bd7e78"), PackedVector2Array([
		Vector2(62, -35), Vector2(83, -22), Vector2(105, 1),
		Vector2(82, 14), Vector2(67, 5),
	]))
	_add_polygon(features, "NoseHighlight", Color("#f3c7b1"), PackedVector2Array([
		Vector2(78, -21), Vector2(99, 1), Vector2(83, 5),
	]))
	_add_polygon(features, "Mouth", Color("#7d475c"), PackedVector2Array([
		Vector2(28, 55), Vector2(58, 49), Vector2(82, 57),
		Vector2(56, 63), Vector2(31, 61),
	]))
	_add_polygon(features, "LowerLipLight", Color("#efb4ae"), PackedVector2Array([
		Vector2(35, 64), Vector2(57, 66), Vector2(73, 62),
		Vector2(57, 72),
	]))

	var hair := Node2D.new()
	hair.name = "Hair"
	stage.add_child(hair)
	_add_polygon(hair, "HairCap", HAIR_COLOR, PackedVector2Array([
		Vector2(-145, -77), Vector2(-120, -164), Vector2(-43, -205),
		Vector2(47, -191), Vector2(94, -129), Vector2(98, -69),
		Vector2(76, -101), Vector2(43, -119), Vector2(12, -85),
		Vector2(-20, -121), Vector2(-49, -82), Vector2(-79, -113),
		Vector2(-97, -69), Vector2(-123, -39),
	]))
	_add_polygon(hair, "CenterBang", Color("#49307d"), PackedVector2Array([
		Vector2(-25, -137), Vector2(20, -152), Vector2(47, -112),
		Vector2(23, -57), Vector2(6, -14), Vector2(-8, -63),
		Vector2(-42, -35), Vector2(-31, -91),
	]))
	_add_polygon(hair, "NearBang", Color("#422b72"), PackedVector2Array([
		Vector2(-92, -110), Vector2(-44, -151), Vector2(-13, -122),
		Vector2(-39, -75), Vector2(-67, -43), Vector2(-65, -91),
		Vector2(-104, -50),
	]))
	_add_polygon(hair, "FarBang", Color("#2c1d55"), PackedVector2Array([
		Vector2(22, -148), Vector2(69, -133), Vector2(89, -95),
		Vector2(74, -57), Vector2(49, -81), Vector2(35, -39),
		Vector2(17, -80),
	]))
	_add_polygon(hair, "NearSideLock", HAIR_COLOR, PackedVector2Array([
		Vector2(-125, -58), Vector2(-97, -80), Vector2(-78, -25),
		Vector2(-72, 62), Vector2(-94, 125), Vector2(-122, 78),
		Vector2(-137, 8),
	]))
	_add_polygon(hair, "FarSideLock", Color("#291b50"), PackedVector2Array([
		Vector2(88, -84), Vector2(105, -42), Vector2(93, 31),
		Vector2(82, 104), Vector2(67, 67), Vector2(73, -8),
	]))
	_add_polygon(hair, "HairHighlight", Color("#6e4aa7"), PackedVector2Array([
		Vector2(-82, -166), Vector2(-34, -188), Vector2(5, -181),
		Vector2(-25, -163), Vector2(-58, -142),
	]))

	var styled_scaffold := Node2D.new()
	styled_scaffold.name = "ToggleableLoomisScaffold"
	styled_scaffold.modulate = Color(1.0, 1.0, 1.0, 0.42)
	stage.add_child(styled_scaffold)
	_add_scaffold_guides(styled_scaffold, 0.85)
	_add_line(styled_scaffold, "CraniumGuide", _closed(
		_ellipse_points(Vector2(-24.0, -58.0), Vector2(125.0, 132.0), 24, -0.08)
	), GUIDE_COLOR, 2.0)


func _add_reference(parent: Node2D) -> void:
	var texture := load(REFERENCE_PATH) as Texture2D
	if texture == null:
		push_error("Could not load Loomis reference: %s" % REFERENCE_PATH)
		return
	var panel := Node2D.new()
	panel.name = "ReferencePanel"
	panel.position = Vector2(55.0, 585.0)
	parent.add_child(panel)
	var label := Label.new()
	label.name = "ReferenceLabel"
	label.position = Vector2.ZERO
	label.text = "SOURCE PROCESS REFERENCE"
	label.add_theme_font_size_override("font_size", 18)
	panel.add_child(label)
	var reference := Sprite2D.new()
	reference.name = "LoomisReferenceCopy"
	reference.texture = texture
	reference.centered = false
	reference.position = Vector2(0.0, 38.0)
	reference.scale = Vector2(0.62, 0.62)
	panel.add_child(reference)


func _add_scaffold_guides(parent: Node2D, width_scale: float) -> void:
	_add_line(parent, "FaceCenterLine", PackedVector2Array([
		Vector2(5, -185), Vector2(36, -123), Vector2(56, -53),
		Vector2(67, 16), Vector2(58, 77), Vector2(47, 119),
	]), GUIDE_COLOR, 3.0 * width_scale)
	_add_line(parent, "BrowGuide", PackedVector2Array([
		Vector2(-126, -55), Vector2(-73, -66), Vector2(-7, -69),
		Vector2(57, -61), Vector2(95, -45),
	]), GUIDE_SECONDARY, 2.5 * width_scale)
	_add_line(parent, "NoseGuide", PackedVector2Array([
		Vector2(-124, -11), Vector2(-66, -20), Vector2(-2, -22),
		Vector2(61, -15), Vector2(109, 1),
	]), GUIDE_COLOR, 2.5 * width_scale)
	_add_line(parent, "MouthGuide", PackedVector2Array([
		Vector2(-110, 35), Vector2(-54, 30), Vector2(8, 32),
		Vector2(64, 42), Vector2(91, 57),
	]), GUIDE_SECONDARY, 2.0 * width_scale)
	_add_line(parent, "ChinGuide", PackedVector2Array([
		Vector2(-73, 83), Vector2(-18, 99), Vector2(47, 119),
	]), GUIDE_COLOR, 2.0 * width_scale)
	_add_line(parent, "SidePlaneAxis", PackedVector2Array([
		Vector2(-126, -114), Vector2(-94, -52), Vector2(-78, 13),
	]), GUIDE_SECONDARY, 2.0 * width_scale)


func _jaw_polygon() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-96, -3), Vector2(-69, 31), Vector2(-52, 86),
		Vector2(4, 127), Vector2(47, 119), Vector2(75, 77),
		Vector2(91, 24), Vector2(109, 1), Vector2(92, -51),
		Vector2(30, -72), Vector2(-46, -43),
	])


func _ellipse_points(
	center: Vector2,
	radius: Vector2,
	point_count: int,
	rotation: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(max(point_count, 3)):
		var angle: float = TAU * float(index) / float(max(point_count, 3))
		var point := Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
		points.append(center + point.rotated(rotation))
	return points


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed_points := points.duplicate()
	if not closed_points.is_empty():
		closed_points.append(closed_points[0])
	return closed_points


func _add_stage_label(parent: Node2D, text: String) -> void:
	var label := Label.new()
	label.name = "StageLabel"
	label.position = Vector2(-150.0, -245.0)
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	parent.add_child(label)


func _add_polygon(
	parent: Node2D,
	node_name: String,
	color: Color,
	points: PackedVector2Array
) -> void:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.color = color
	polygon.polygon = points
	parent.add_child(polygon)


func _add_line(
	parent: Node2D,
	node_name: String,
	points: PackedVector2Array,
	color: Color,
	width: float
) -> void:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.default_color = color
	line.width = width
	line.antialiased = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	parent.add_child(line)


func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_owner_recursive(child, scene_owner)
