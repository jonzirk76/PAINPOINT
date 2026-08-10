extends RefCounted
class_name CharacterBlockoutExtractionRunner

const CAPTURE_SCRIPT := preload("res://scripts/resources/character_vector_capture.gd")
const SHAPE_SCRIPT := preload("res://scripts/resources/character_vector_shape.gd")

const DEFAULT_SCENE_PATH := "res://scenes/tools/Back Hair Test.tscn"
const DEFAULT_OUTPUT_PATH := "res://resources/characters/blockouts/back_hair_test_vector_capture.tres"
const FRONT_WORKBENCH_PATH := "FrontView/FrontHead"
const SIDE_WORKBENCH_PATH := "SideView/ProfileReference"
const VIEW_FRONT := "front"
const VIEW_SIDE_LEFT := "side_left"

const WORKBENCH_PROPERTY_NAMES := [
	"view_direction",
	"preview_scale",
	"head_width",
	"head_height",
	"chin_length",
	"chin_roundness",
	"show_hair",
	"side_cranium_x_offset",
	"side_cranium_width",
	"side_face_projection",
	"side_jaw_adjustment",
	"side_jaw_height",
	"side_chin_tip_x_offset",
	"side_cranium_front_x_offset",
	"side_cranium_front_y_offset",
	"side_cranium_front_top_curve",
	"side_cranium_front_face_curve",
	"side_nose_x_offset",
	"side_nose_y_offset",
	"side_nose_bridge_x_offset",
	"side_nose_bridge_y_offset",
	"side_nose_tip_x_offset",
	"side_nose_tip_y_offset",
	"side_upper_lip_x_offset",
	"side_upper_lip_y_offset",
	"side_eye_x_offset",
	"side_eye_width",
	"side_eye_height",
	"side_eye_y_offset",
	"side_brow_front_x_offset",
	"side_brow_front_y_offset",
	"side_brow_rear_x_offset",
	"side_brow_rear_y_offset",
	"side_mouth_x_offset",
	"side_mouth_y_offset",
	"side_mouth_width",
	"side_mouth_angle_degrees",
	"side_mouth_curve",
	"side_mouth_taper",
]

const DEFAULT_MAPPINGS := [
	{"node_path": "FrontView/BackHair_L", "role": "hair_back_left", "view": "front", "layer": 10},
	{"node_path": "FrontView/BackHair_L/FrontBackHair", "role": "hair_back_inner_left", "view": "front", "layer": 11},
	{"node_path": "FrontView/BackHair_R", "role": "hair_back_right", "view": "front", "layer": 10},
	{"node_path": "FrontView/BackHair_R/FrontBackHair", "role": "hair_back_inner_right", "view": "front", "layer": 11},
	{"node_path": "FrontView/Legs/LeftLeg", "role": "leg_left", "view": "front", "layer": 20},
	{"node_path": "FrontView/Legs/RightLeg", "role": "leg_right", "view": "front", "layer": 20},
	{"node_path": "FrontView/Hips", "role": "hips", "view": "front", "layer": 30},
	{"node_path": "FrontView/Body", "role": "torso", "view": "front", "layer": 40},
	{"node_path": "FrontView/ScalpHair_Front/ScalpHair_L", "role": "hair_scalp_left", "view": "front", "layer": 80},
	{"node_path": "FrontView/ScalpHair_Front/ScalpHair_R", "role": "hair_scalp_right", "view": "front", "layer": 80},
	{"node_path": "FrontView/Bang_Front", "role": "hair_bangs", "view": "front", "layer": 90},
	{"node_path": "SideView/BackLeg_Side", "role": "leg_back", "view": "side_left", "layer": 20, "workbench_path": SIDE_WORKBENCH_PATH},
	{"node_path": "SideView/FrontLeg_Side", "role": "leg_front", "view": "side_left", "layer": 21, "workbench_path": SIDE_WORKBENCH_PATH},
	{"node_path": "SideView/SideHips", "role": "hips", "view": "side_left", "layer": 30, "workbench_path": SIDE_WORKBENCH_PATH},
	{"node_path": "SideView/SideBody", "role": "torso", "view": "side_left", "layer": 40, "workbench_path": SIDE_WORKBENCH_PATH},
	{"node_path": "SideView/SideArm", "role": "arm_front", "view": "side_left", "layer": 50, "workbench_path": SIDE_WORKBENCH_PATH},
	{"node_path": "SideView/BackHair_Side", "role": "hair_back_mass", "view": "side_left", "layer": 5, "workbench_path": SIDE_WORKBENCH_PATH},
	{"node_path": "SideView/ScalpHair_Side", "role": "hair_scalp", "view": "side_left", "layer": 82, "workbench_path": SIDE_WORKBENCH_PATH},
	{"node_path": "SideView/Bang_Side", "role": "hair_bangs", "view": "side_left", "layer": 90, "workbench_path": SIDE_WORKBENCH_PATH},
]

const AUTO_CAPTURE_ROOTS := [
	{"node_path": "FrontView", "view": VIEW_FRONT, "workbench_path": FRONT_WORKBENCH_PATH},
	{"node_path": "SideView", "view": VIEW_SIDE_LEFT, "workbench_path": SIDE_WORKBENCH_PATH},
]

var extracted_shape_count := 0
var skipped_shape_count := 0
var inferred_shape_count := 0


func extract_default() -> Resource:
	return extract_scene(DEFAULT_SCENE_PATH, DEFAULT_OUTPUT_PATH)


func extract_scene(scene_path: String, output_path: String) -> Resource:
	extracted_shape_count = 0
	skipped_shape_count = 0
	inferred_shape_count = 0
	var packed_scene: Resource = load(scene_path)
	if not packed_scene is PackedScene:
		push_error("Blockout extraction scene is not a PackedScene: %s" % scene_path)
		return null
	var root: Node = (packed_scene as PackedScene).instantiate()
	if root == null:
		push_error("Failed to instantiate blockout scene: %s" % scene_path)
		return null
	var capture: Resource = CAPTURE_SCRIPT.new()
	capture.capture_id = output_path.get_file().get_basename()
	capture.source_scene_path = scene_path
	capture.workbench_properties = _extract_workbench_properties(root)
	capture.shapes = _extract_shapes(root)
	root.free()
	_ensure_dir_for_path(output_path)
	var error := ResourceSaver.save(capture, output_path)
	if error != OK:
		push_error("Failed to save vector capture %s: %s" % [output_path, error])
	else:
		print("Extracted %s vector blockout shapes to %s" % [extracted_shape_count, output_path])
		if inferred_shape_count > 0:
			print("Captured %s inferred blockout shapes without explicit mappings." % inferred_shape_count)
		if skipped_shape_count > 0:
			print("Skipped %s missing or empty blockout mappings." % skipped_shape_count)
	return capture


func _extract_shapes(root: Node) -> Array[Resource]:
	var shapes: Array[Resource] = []
	var mapped_paths: Dictionary = {}
	for mapping in DEFAULT_MAPPINGS:
		var node_path: String = String(mapping.get("node_path", ""))
		mapped_paths[node_path] = true
		var polygon_node: Node = root.get_node_or_null(NodePath(node_path))
		if not polygon_node is Polygon2D:
			push_warning("Skipping missing blockout polygon: %s" % node_path)
			skipped_shape_count += 1
			continue
		var polygon: PackedVector2Array = polygon_node.polygon
		if polygon.size() < 3:
			push_warning("Skipping empty blockout polygon: %s" % node_path)
			skipped_shape_count += 1
			continue
		var view: String = String(mapping.get("view", "front"))
		var workbench_path: String = String(mapping.get("workbench_path", _workbench_path_for_view(view)))
		var workbench: Node = root.get_node_or_null(NodePath(workbench_path))
		if not workbench is Control:
			push_warning("Skipping %s because workbench is missing: %s" % [node_path, workbench_path])
			skipped_shape_count += 1
			continue
		var shape: Resource = SHAPE_SCRIPT.new()
		shape.view_direction = view
		shape.role = String(mapping.get("role", polygon_node.name))
		shape.layer_order = int(mapping.get("layer", 0))
		shape.source_node_path = node_path
		shape.source_workbench_path = workbench_path
		shape.color = polygon_node.color
		shape.mirror_x = _is_mirrored(polygon_node)
		shape.points = _polygon_to_source_space(polygon_node, workbench)
		shapes.append(shape)
		extracted_shape_count += 1
	_append_inferred_shapes(root, mapped_paths, shapes)
	shapes.sort_custom(Callable(self, "_sort_shape_layer"))
	return shapes


func _append_inferred_shapes(root: Node, mapped_paths: Dictionary, shapes: Array[Resource]) -> void:
	for root_info in AUTO_CAPTURE_ROOTS:
		var root_path: String = String(root_info.get("node_path", ""))
		var capture_root: Node = root.get_node_or_null(NodePath(root_path))
		if capture_root == null:
			continue
		var polygon_nodes: Array[Polygon2D] = []
		_collect_polygon_nodes(capture_root, polygon_nodes)
		for polygon_node in polygon_nodes:
			var node_path: String = String(root.get_path_to(polygon_node))
			if mapped_paths.has(node_path):
				continue
			if polygon_node.polygon.size() < 3:
				continue
			var view: String = _infer_view_direction(root_info, polygon_node)
			var workbench_path: String = _workbench_path_for_view(view)
			var workbench: Node = root.get_node_or_null(NodePath(workbench_path))
			if not workbench is Control:
				continue
			var role: String = _role_from_node_name(polygon_node.name)
			var shape: Resource = SHAPE_SCRIPT.new()
			shape.view_direction = view
			shape.role = role
			shape.layer_order = _infer_layer_order(role)
			shape.source_node_path = node_path
			shape.source_workbench_path = workbench_path
			shape.color = polygon_node.color
			shape.mirror_x = _is_mirrored(polygon_node)
			shape.points = _polygon_to_source_space(polygon_node, workbench)
			shapes.append(shape)
			extracted_shape_count += 1
			inferred_shape_count += 1


func _collect_polygon_nodes(node: Node, polygon_nodes: Array[Polygon2D]) -> void:
	if node is Polygon2D:
		polygon_nodes.append(node)
	for child in node.get_children():
		_collect_polygon_nodes(child, polygon_nodes)


func _infer_view_direction(root_info: Dictionary, polygon_node: Polygon2D) -> String:
	var name: String = String(polygon_node.name)
	if name.begins_with("Side") or name.ends_with("_Side"):
		return VIEW_SIDE_LEFT
	return String(root_info.get("view", VIEW_FRONT))


func _role_from_node_name(node_name: StringName) -> String:
	var raw_name: String = String(node_name)
	var role: String = ""
	var previous_was_separator := false
	for index in raw_name.length():
		var character: String = raw_name.substr(index, 1)
		var is_uppercase_letter: bool = character == character.to_upper() and character != character.to_lower()
		if index > 0 and is_uppercase_letter and not previous_was_separator:
			role += "_"
		if character == " " or character == "-" or character == "/":
			if not role.ends_with("_"):
				role += "_"
			previous_was_separator = true
		else:
			role += character.to_lower()
			previous_was_separator = character == "_"
	return role.trim_prefix("_").trim_suffix("_")


func _infer_layer_order(role: String) -> int:
	if role.contains("back_hair"):
		return 5
	if role.contains("leg"):
		return 20
	if role.contains("hip"):
		return 30
	if role.contains("torso") or role.contains("body"):
		return 40
	if role.contains("arm") or role.contains("shoulder"):
		return 50
	if role.contains("neck"):
		return 55
	if role.contains("head") or role.contains("face"):
		return 60
	if role.contains("scalp"):
		return 80
	if role.contains("bang"):
		return 90
	return 60


func _extract_workbench_properties(root: Node) -> Dictionary:
	var result: Dictionary = {}
	for workbench_path in [FRONT_WORKBENCH_PATH, SIDE_WORKBENCH_PATH]:
		var workbench: Node = root.get_node_or_null(NodePath(workbench_path))
		if workbench == null:
			continue
		var values: Dictionary = {}
		for property_name in WORKBENCH_PROPERTY_NAMES:
			values[property_name] = workbench.get(property_name)
		result[workbench_path] = values
	return result


func _polygon_to_source_space(polygon_node: Polygon2D, workbench: Control) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var polygon_transform: Transform2D = polygon_node.get_global_transform()
	var workbench_inverse: Transform2D = workbench.get_global_transform().affine_inverse()
	var center: Vector2 = _workbench_center(workbench)
	var preview_scale: float = max(float(workbench.get("preview_scale")), 0.001)
	var head_width: float = max(float(workbench.get("head_width")), 0.001)
	var head_height: float = max(float(workbench.get("head_height")), 0.001)
	for local_point in polygon_node.polygon:
		var global_point: Vector2 = polygon_transform * local_point
		var workbench_point: Vector2 = workbench_inverse * global_point
		var source_point: Vector2 = (workbench_point - center) / preview_scale
		source_point.x /= head_width
		source_point.y /= head_height
		points.append(source_point + Vector2(64.0, 64.0))
	return points


func _workbench_center(workbench: Control) -> Vector2:
	if workbench.size != Vector2.ZERO:
		return workbench.size * 0.5
	return Vector2(280.0, 280.0)


func _workbench_path_for_view(view_direction: String) -> String:
	if view_direction.begins_with("side"):
		return SIDE_WORKBENCH_PATH
	return FRONT_WORKBENCH_PATH


func _is_mirrored(node: CanvasItem) -> bool:
	var transform: Transform2D = node.get_global_transform()
	return transform.x.cross(transform.y) < 0.0


func _sort_shape_layer(left: Resource, right: Resource) -> bool:
	var left_view: String = String(left.get("view_direction"))
	var right_view: String = String(right.get("view_direction"))
	if left_view == right_view:
		return int(left.get("layer_order")) < int(right.get("layer_order"))
	return left_view.naturalnocasecmp_to(right_view) < 0


func _ensure_dir_for_path(path: String) -> void:
	var absolute: String = ProjectSettings.globalize_path(path.get_base_dir())
	var error: Error = DirAccess.make_dir_recursive_absolute(absolute)
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("Failed to create directory %s: %s" % [path.get_base_dir(), error])
