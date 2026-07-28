extends SceneTree

const OUTPUT_DIRECTORY := "res://scenes/tools/character_turnarounds"
const SHEET_DIRECTORY := "res://art/concept_art"

const CHARACTER_SPECS := {
	"volette": {
		"sheet": "volette_sheet.png",
		"skin": Color("#d9a98f"),
		"hair": Color("#33225f"),
		"hair_shadow": Color("#171035"),
		"primary": Color("#10233d"),
		"secondary": Color("#20242d"),
		"accent": Color("#0759b8"),
		"metal": Color("#343b48"),
		"eye": Color("#8b55db"),
		"views": [
			["FrontView", Vector2(420, 302), 430.0, 118.0, "front"],
			["ThreeQuarterFrontView", Vector2(590, 302), 430.0, 116.0, "three_quarter"],
			["SideView", Vector2(750, 302), 430.0, 96.0, "side"],
			["ThreeQuarterBackView", Vector2(895, 302), 430.0, 112.0, "three_quarter_back"],
			["BackView", Vector2(1060, 302), 430.0, 116.0, "back"],
		],
	},
	"jules": {
		"sheet": "jules_sheet.png",
		"skin": Color("#6f4b35"),
		"hair": Color("#181715"),
		"hair_shadow": Color("#090a09"),
		"primary": Color("#171a1d"),
		"secondary": Color("#292820"),
		"accent": Color("#d28c12"),
		"metal": Color("#42413b"),
		"eye": Color("#b77b17"),
		"views": [
			["FrontView", Vector2(378, 320), 510.0, 128.0, "front"],
			["ThreeQuarterFrontView", Vector2(548, 320), 510.0, 126.0, "three_quarter"],
			["SideView", Vector2(704, 320), 510.0, 104.0, "side"],
			["ThreeQuarterBackView", Vector2(856, 320), 510.0, 126.0, "three_quarter_back"],
			["BackView", Vector2(1014, 320), 510.0, 130.0, "back"],
		],
	},
	"kairo": {
		"sheet": "kairo_sheet.png",
		"skin": Color("#b98067"),
		"hair": Color("#181a20"),
		"hair_shadow": Color("#090b10"),
		"primary": Color("#171a20"),
		"secondary": Color("#282a2e"),
		"accent": Color("#b31f26"),
		"metal": Color("#3d4148"),
		"eye": Color("#d62f35"),
		"views": [
			["FrontView", Vector2(462, 401), 650.0, 154.0, "front"],
			["BackView", Vector2(720, 401), 650.0, 154.0, "back"],
			["SideView", Vector2(969, 401), 650.0, 130.0, "side"],
		],
	},
	"periwinkle": {
		"sheet": "periwinkle_sheet.png",
		"skin": Color("#9b6848"),
		"hair": Color("#171b18"),
		"hair_shadow": Color("#090c0a"),
		"primary": Color("#1a201b"),
		"secondary": Color("#303625"),
		"accent": Color("#78a92b"),
		"metal": Color("#454a43"),
		"eye": Color("#9abf52"),
		"views": [
			["FrontView", Vector2(410, 290), 420.0, 116.0, "front"],
			["ThreeQuarterFrontView", Vector2(565, 290), 420.0, 114.0, "three_quarter"],
			["SideView", Vector2(714, 290), 420.0, 96.0, "side"],
			["ThreeQuarterBackView", Vector2(864, 290), 420.0, 112.0, "three_quarter_back"],
			["BackView", Vector2(1014, 290), 420.0, 116.0, "back"],
		],
	},
}


func _initialize() -> void:
	call_deferred("_build_all")


func _build_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	for character_name in CHARACTER_SPECS:
		_build_character_scene(character_name, CHARACTER_SPECS[character_name])
	quit()


func _build_character_scene(character_name: String, spec: Dictionary) -> void:
	var root_node := Node2D.new()
	root_node.name = "%sTurnaroundWorkbench" % character_name.capitalize()
	root.add_child(root_node)

	for view_spec in spec["views"]:
		_add_view(root_node, view_spec, spec)

	var sheet_path: String = "%s/%s" % [SHEET_DIRECTORY, String(spec["sheet"])]
	var sheet_texture := load(sheet_path) as Texture2D
	if sheet_texture == null:
		push_error("Could not load character sheet: %s" % sheet_path)
		return
	var tracing_overlay := Sprite2D.new()
	tracing_overlay.name = "TracingOverlay"
	tracing_overlay.texture = sheet_texture
	tracing_overlay.centered = false
	tracing_overlay.z_index = 20
	tracing_overlay.modulate = Color(1.0, 1.0, 1.0, 0.62)
	root_node.add_child(tracing_overlay)

	var palette_reference := Sprite2D.new()
	palette_reference.name = "PaletteReference"
	palette_reference.texture = sheet_texture
	palette_reference.centered = false
	palette_reference.position = Vector2(1660.0, 100.0)
	palette_reference.scale = Vector2(0.62, 0.62)
	palette_reference.z_index = 20
	root_node.add_child(palette_reference)

	var instructions := Label.new()
	instructions.name = "WorkbenchInstructions"
	instructions.position = Vector2(1660.0, 20.0)
	instructions.text = "TracingOverlay: toggle visibility or adjust alpha\nPaletteReference: full-color sampling copy\nViews: editable Polygon2D masses in sheet coordinates"
	instructions.add_theme_font_size_override("font_size", 18)
	root_node.add_child(instructions)

	_set_owner_recursive(root_node, root_node)
	var packed_scene := PackedScene.new()
	var pack_error := packed_scene.pack(root_node)
	if pack_error != OK:
		push_error("Could not pack %s turnaround: %s" % [character_name, error_string(pack_error)])
		return
	var output_path := "%s/%s_turnaround_workbench.tscn" % [OUTPUT_DIRECTORY, character_name]
	var save_error := ResourceSaver.save(packed_scene, output_path)
	if save_error != OK:
		push_error("Could not save %s turnaround: %s" % [character_name, error_string(save_error)])
		return
	print("Built %s" % output_path)


func _add_view(root_node: Node2D, view_spec: Array, spec: Dictionary) -> void:
	var view := Node2D.new()
	view.name = String(view_spec[0])
	root_node.add_child(view)
	var center: Vector2 = view_spec[1]
	var height: float = float(view_spec[2])
	var width: float = float(view_spec[3])
	var facing: String = String(view_spec[4])
	var top: float = center.y - height * 0.5
	var bottom: float = center.y + height * 0.5
	var head_center := Vector2(center.x, top + height * 0.145)
	var shoulder_y: float = top + height * 0.245
	var waist_y: float = top + height * 0.515
	var hip_y: float = top + height * 0.59
	var knee_y: float = top + height * 0.78
	var face_visible: bool = facing in ["front", "three_quarter", "side"]
	var back_visible: bool = facing in ["back", "three_quarter_back"]
	var side_factor: float = 0.76 if facing == "side" else 1.0
	var facing_shift: float = width * 0.07 if facing in ["three_quarter", "side"] else 0.0

	_add_polygon(view, "BackHair", spec["hair_shadow"], PackedVector2Array([
		Vector2(head_center.x - width * 0.43 * side_factor, top + height * 0.06),
		Vector2(head_center.x + width * 0.42 * side_factor, top + height * 0.05),
		Vector2(center.x + width * 0.49, shoulder_y + height * 0.11),
		Vector2(center.x + width * 0.38, waist_y + height * 0.04),
		Vector2(center.x, hip_y - height * 0.03),
		Vector2(center.x - width * 0.42, waist_y + height * 0.05),
		Vector2(center.x - width * 0.5, shoulder_y + height * 0.1),
	]))
	if back_visible:
		_add_polygon(view, "CapeOrBackMass", spec["primary"], PackedVector2Array([
			Vector2(center.x - width * 0.46, shoulder_y),
			Vector2(center.x + width * 0.46, shoulder_y),
			Vector2(center.x + width * 0.58, waist_y + height * 0.12),
			Vector2(center.x + width * 0.31, hip_y + height * 0.12),
			Vector2(center.x - width * 0.34, hip_y + height * 0.12),
			Vector2(center.x - width * 0.57, waist_y + height * 0.1),
		]))

	_add_polygon(view, "LeftLeg", spec["secondary"], PackedVector2Array([
		Vector2(center.x - width * 0.36, hip_y),
		Vector2(center.x - width * 0.02, hip_y),
		Vector2(center.x - width * 0.06, knee_y),
		Vector2(center.x - width * 0.13, bottom - height * 0.055),
		Vector2(center.x - width * 0.38, bottom - height * 0.055),
		Vector2(center.x - width * 0.43, knee_y),
	]))
	_add_polygon(view, "RightLeg", spec["secondary"], PackedVector2Array([
		Vector2(center.x + width * 0.02, hip_y),
		Vector2(center.x + width * 0.36, hip_y),
		Vector2(center.x + width * 0.43, knee_y),
		Vector2(center.x + width * 0.38, bottom - height * 0.055),
		Vector2(center.x + width * 0.13, bottom - height * 0.055),
		Vector2(center.x + width * 0.06, knee_y),
	]))
	_add_polygon(view, "LeftBoot", spec["primary"], PackedVector2Array([
		Vector2(center.x - width * 0.4, bottom - height * 0.12),
		Vector2(center.x - width * 0.12, bottom - height * 0.12),
		Vector2(center.x - width * 0.1, bottom - height * 0.015),
		Vector2(center.x - width * 0.47, bottom),
		Vector2(center.x - width * 0.52, bottom - height * 0.025),
	]))
	_add_polygon(view, "RightBoot", spec["primary"], PackedVector2Array([
		Vector2(center.x + width * 0.12, bottom - height * 0.12),
		Vector2(center.x + width * 0.4, bottom - height * 0.12),
		Vector2(center.x + width * 0.52, bottom - height * 0.025),
		Vector2(center.x + width * 0.47, bottom),
		Vector2(center.x + width * 0.1, bottom - height * 0.015),
	]))
	_add_polygon(view, "HipMass", spec["primary"], PackedVector2Array([
		Vector2(center.x - width * 0.42, waist_y),
		Vector2(center.x + width * 0.42, waist_y),
		Vector2(center.x + width * 0.38, hip_y + height * 0.035),
		Vector2(center.x, hip_y + height * 0.055),
		Vector2(center.x - width * 0.38, hip_y + height * 0.035),
	]))
	_add_polygon(view, "Torso", spec["primary"], PackedVector2Array([
		Vector2(center.x - width * 0.43, shoulder_y),
		Vector2(center.x + width * 0.42, shoulder_y),
		Vector2(center.x + width * 0.34, waist_y),
		Vector2(center.x, waist_y + height * 0.025),
		Vector2(center.x - width * 0.34, waist_y),
	]))
	_add_polygon(view, "ChestArmor", spec["metal"], PackedVector2Array([
		Vector2(center.x - width * 0.32, shoulder_y + height * 0.035),
		Vector2(center.x + width * 0.32, shoulder_y + height * 0.035),
		Vector2(center.x + width * 0.26, waist_y - height * 0.045),
		Vector2(center.x, waist_y),
		Vector2(center.x - width * 0.26, waist_y - height * 0.045),
	]))
	_add_polygon(view, "LeftArm", spec["secondary"], PackedVector2Array([
		Vector2(center.x - width * 0.43, shoulder_y),
		Vector2(center.x - width * 0.62, shoulder_y + height * 0.045),
		Vector2(center.x - width * 0.58, waist_y + height * 0.04),
		Vector2(center.x - width * 0.43, waist_y + height * 0.06),
		Vector2(center.x - width * 0.32, shoulder_y + height * 0.09),
	]))
	_add_polygon(view, "RightArm", spec["secondary"], PackedVector2Array([
		Vector2(center.x + width * 0.42, shoulder_y),
		Vector2(center.x + width * 0.61, shoulder_y + height * 0.05),
		Vector2(center.x + width * 0.57, waist_y + height * 0.04),
		Vector2(center.x + width * 0.42, waist_y + height * 0.06),
		Vector2(center.x + width * 0.31, shoulder_y + height * 0.09),
	]))
	_add_polygon(view, "BeltAccent", spec["accent"], PackedVector2Array([
		Vector2(center.x - width * 0.37, waist_y - height * 0.018),
		Vector2(center.x + width * 0.37, waist_y - height * 0.018),
		Vector2(center.x + width * 0.36, waist_y + height * 0.016),
		Vector2(center.x - width * 0.36, waist_y + height * 0.016),
	]))

	_add_polygon(view, "Head", spec["skin"], PackedVector2Array([
		Vector2(head_center.x - width * 0.25 * side_factor + facing_shift, top + height * 0.07),
		Vector2(head_center.x + width * 0.25 * side_factor + facing_shift, top + height * 0.075),
		Vector2(head_center.x + width * 0.29 * side_factor + facing_shift, top + height * 0.155),
		Vector2(head_center.x + width * 0.18 * side_factor + facing_shift, top + height * 0.215),
		Vector2(head_center.x + facing_shift, top + height * 0.24),
		Vector2(head_center.x - width * 0.2 * side_factor + facing_shift, top + height * 0.21),
		Vector2(head_center.x - width * 0.29 * side_factor + facing_shift, top + height * 0.15),
	]))
	_add_polygon(view, "HairCap", spec["hair"], PackedVector2Array([
		Vector2(head_center.x - width * 0.34 * side_factor, top + height * 0.13),
		Vector2(head_center.x - width * 0.27 * side_factor, top + height * 0.045),
		Vector2(head_center.x, top + height * 0.015),
		Vector2(head_center.x + width * 0.31 * side_factor, top + height * 0.055),
		Vector2(head_center.x + width * 0.34 * side_factor, top + height * 0.14),
		Vector2(head_center.x + width * 0.12 + facing_shift, top + height * 0.11),
		Vector2(head_center.x + facing_shift, top + height * 0.18),
		Vector2(head_center.x - width * 0.11 + facing_shift, top + height * 0.12),
	]))
	if face_visible:
		var eye_y: float = top + height * 0.145
		_add_polygon(view, "LeftEye", spec["eye"], PackedVector2Array([
			Vector2(head_center.x - width * 0.17 + facing_shift, eye_y),
			Vector2(head_center.x - width * 0.06 + facing_shift, eye_y - height * 0.007),
			Vector2(head_center.x - width * 0.08 + facing_shift, eye_y + height * 0.018),
			Vector2(head_center.x - width * 0.16 + facing_shift, eye_y + height * 0.017),
		]))
		if facing != "side":
			_add_polygon(view, "RightEye", spec["eye"], PackedVector2Array([
				Vector2(head_center.x + width * 0.06 + facing_shift, eye_y - height * 0.007),
				Vector2(head_center.x + width * 0.17 + facing_shift, eye_y),
				Vector2(head_center.x + width * 0.16 + facing_shift, eye_y + height * 0.017),
				Vector2(head_center.x + width * 0.08 + facing_shift, eye_y + height * 0.018),
			]))
	if back_visible:
		_add_polygon(view, "BackEmblemBlock", spec["accent"], PackedVector2Array([
			Vector2(center.x - width * 0.13, shoulder_y + height * 0.11),
			Vector2(center.x, shoulder_y + height * 0.075),
			Vector2(center.x + width * 0.13, shoulder_y + height * 0.11),
			Vector2(center.x, shoulder_y + height * 0.18),
		]))


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


func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_owner_recursive(child, scene_owner)
