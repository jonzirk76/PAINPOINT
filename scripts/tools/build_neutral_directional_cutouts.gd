@tool
extends SceneTree

const SOURCE_TEXTURE_PATH := "res://art/concept_art/characterbasetransparent.png"
const GUIDE_SCENE_PATH := "res://scenes/tools/joint_designation.tscn"
const OUTPUT_DIRECTORY := "res://scenes/characters/neutral_cutout"
const IMAGE_CENTER := Vector2(512.0, 512.0)
const FAR_MODULATE := Color(0.62, 0.65, 0.72, 1.0)
const CONTOUR_ERROR := 2.0
const FORWARD_MOTION: Resource = preload("res://resources/presentation/humanoid_forward_motion_profile.tres")
const PROFILE_MOTION: Resource = preload("res://resources/presentation/humanoid_profile_motion_profile.tres")
const THREE_QUARTER_MOTION: Resource = preload("res://resources/presentation/humanoid_three_quarter_motion_profile.tres")
const REAR_MOTION: Resource = preload("res://resources/presentation/humanoid_rear_motion_profile.tres")

const VIEW_SPECS := [
	{
		"id": "south",
		"guide": "Looking_South",
		"bounds": Rect2(68, 55, 265, 425),
		"near": "Screen_Right",
		"far": "Screen_Left",
		"equal_depth": true,
	},
	{
		"id": "south_west",
		"guide": "Looking_South_West",
		"bounds": Rect2(403, 55, 235, 435),
		"near": "Near",
		"far": "Far",
	},
	{
		"id": "west",
		"guide": "Looking_West",
		"bounds": Rect2(742, 55, 178, 455),
		"near": "Near",
		"far": "Far",
		"duplicate_far_arm": true,
		"duplicate_far_leg": true,
	},
	{
		"id": "north_east",
		"guide": "Looking_North_East",
		"bounds": Rect2(255, 510, 235, 420),
		"near": "Near",
		"far": "Far",
	},
	{
		"id": "north",
		"guide": "Looking_North",
		"bounds": Rect2(550, 510, 265, 430),
		"near": "Screen_Right",
		"far": "Screen_Left",
		"equal_depth": true,
	},
]


func _initialize() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE_TEXTURE_PATH))
	if image == null or image.is_empty():
		push_error("Could not load neutral character source image.")
		quit(1)
		return
	var texture: Texture2D = load(SOURCE_TEXTURE_PATH)
	var guide_scene: PackedScene = load(GUIDE_SCENE_PATH)
	var guide_root := guide_scene.instantiate()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	for spec: Dictionary in VIEW_SPECS:
		var root := _build_view(spec, guide_root, image, texture)
		var packed := PackedScene.new()
		_set_scene_owner(root, root)
		var pack_error := packed.pack(root)
		if pack_error != OK:
			push_error("Could not pack neutral cutout %s." % spec["id"])
			quit(1)
			return
		var output_path := "%s/neutral_humanoid_%s.tscn" % [OUTPUT_DIRECTORY, spec["id"]]
		var save_error := ResourceSaver.save(packed, output_path)
		if save_error != OK:
			push_error("Could not save %s." % output_path)
			quit(1)
			return
		print("Generated %s" % output_path)
		root.free()

	guide_root.free()
	quit()


func _build_view(spec: Dictionary, guide_root: Node, image: Image, texture: Texture2D) -> Node2D:
	var view_bounds: Rect2 = spec["bounds"]
	var origin := Vector2(view_bounds.get_center().x, view_bounds.end.y)
	var guides: Node = guide_root.get_node(spec["guide"])
	var joints := {
		"neck": _guide_points(guides, "Neck_Joint"),
		"waist": _guide_points(guides, "Waist_Joint"),
	}
	for side_name: String in [spec["near"], spec["far"]]:
		for joint_name in ["Shoulder", "Elbow", "Wrist", "Hip", "Knee", "Ankle"]:
			var key := "%s_%s" % [side_name.to_lower(), joint_name.to_lower()]
			var node_name := "%s_%s_Joint" % [side_name, joint_name]
			if guides.has_node(node_name):
				joints[key] = _guide_points(guides, node_name)

	var waist_pivot := _polyline_center(joints["waist"])
	var neck_pivot := _polyline_center(joints["neck"])
	var root := Node2D.new()
	root.name = "NeutralHumanoid%s" % _pascal_case(spec["id"])

	var skeleton := Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	skeleton.position = -origin
	root.add_child(skeleton)

	var hips := _add_bone(skeleton, "Hips", waist_pivot)
	_add_polygon(
		hips,
		"HipsMass",
		image,
		texture,
		_build_hips_clip(joints, spec),
		waist_pivot,
		0,
		Color.WHITE
	)

	var torso := _add_bone(hips, "Torso", Vector2.ZERO)
	_add_polygon(
		torso,
		"TorsoMass",
		image,
		texture,
		_build_torso_clip(joints),
		waist_pivot,
		10,
		Color.WHITE
	)

	var head := _add_bone(torso, "Head", neck_pivot - waist_pivot)
	_add_polygon(
		head,
		"HeadMass",
		image,
		texture,
		_build_head_clip(joints["neck"], view_bounds),
		neck_pivot,
		30,
		Color.WHITE
	)

	_build_limb_pair(spec, joints, image, texture, hips, torso)
	_add_animation_player(root, -origin, spec)
	return root


func _build_limb_pair(
	spec: Dictionary,
	joints: Dictionary,
	image: Image,
	texture: Texture2D,
	hips: Bone2D,
	torso: Bone2D
) -> void:
	var near_prefix: String = spec["near"].to_lower()
	var far_prefix: String = spec["far"].to_lower()
	var equal_depth: bool = spec.get("equal_depth", false)

	var near_arm_data := _limb_joint_data(joints, near_prefix, "arm")
	var near_leg_data := _limb_joint_data(joints, near_prefix, "leg")
	var far_arm_data := _limb_joint_data(joints, far_prefix, "arm")
	var far_leg_data := _limb_joint_data(joints, far_prefix, "leg")
	if spec.get("duplicate_far_arm", false):
		far_arm_data = _translated_limb_data(near_arm_data, far_arm_data[0] - near_arm_data[0])
	if spec.get("duplicate_far_leg", false):
		far_leg_data = _translated_limb_data(near_leg_data, far_leg_data[0] - near_leg_data[0])

	_build_arm(torso, "FarArm", far_arm_data, image, texture, -20, Color.WHITE if equal_depth else FAR_MODULATE)
	_build_leg(hips, "FarLeg", far_leg_data, image, texture, -30, Color.WHITE if equal_depth else FAR_MODULATE)
	_build_leg(hips, "NearLeg", near_leg_data, image, texture, 5, Color.WHITE)
	_build_arm(torso, "NearArm", near_arm_data, image, texture, 20, Color.WHITE)


func _build_arm(
	parent: Bone2D,
	name_prefix: String,
	points: Array[Vector2],
	image: Image,
	texture: Texture2D,
	z_index: int,
	modulate_color: Color
) -> void:
	var shoulder := points[0]
	var elbow := points[1]
	var wrist := points[2]
	var terminal := wrist + (wrist - elbow).normalized() * 45.0
	var arm := _add_bone(parent, name_prefix, shoulder - _bone_global_pivot(parent))
	_add_polygon(arm, "UpperArm", image, texture, _corridor(shoulder, elbow, 18.0, 16.0), shoulder, z_index, modulate_color)
	var forearm := _add_bone(arm, "Forearm", elbow - shoulder)
	_add_polygon(forearm, "ForearmMass", image, texture, _corridor(elbow, wrist, 16.0, 14.0), elbow, z_index, modulate_color)
	var hand := _add_bone(forearm, "Hand", wrist - elbow)
	_add_polygon(hand, "HandMass", image, texture, _corridor(wrist, terminal, 15.0, 13.0), wrist, z_index, modulate_color)


func _build_leg(
	parent: Bone2D,
	name_prefix: String,
	points: Array[Vector2],
	image: Image,
	texture: Texture2D,
	z_index: int,
	modulate_color: Color
) -> void:
	var hip := points[0]
	var knee := points[1]
	var ankle := points[2]
	# Feet fan away from the shin axis in several source projections. A wider,
	# longer terminal mask preserves the toe silhouette without reconnecting it
	# to the opposite leg above the authored ankle cut.
	var terminal := ankle + (ankle - knee).normalized() * 78.0
	var leg := _add_bone(parent, name_prefix, hip - _bone_global_pivot(parent))
	_add_polygon(leg, "Thigh", image, texture, _corridor(hip, knee, 24.0, 21.0), hip, z_index, modulate_color)
	var shin := _add_bone(leg, "Shin", knee - hip)
	_add_polygon(shin, "ShinMass", image, texture, _corridor(knee, ankle, 21.0, 18.0), knee, z_index, modulate_color)
	var foot := _add_bone(shin, "Foot", ankle - knee)
	_add_polygon(foot, "FootMass", image, texture, _corridor(ankle, terminal, 28.0, 45.0), ankle, z_index, modulate_color)


func _limb_joint_data(joints: Dictionary, prefix: String, limb: String) -> Array[Vector2]:
	var names: Array[String]
	if limb == "arm":
		names = ["shoulder", "elbow", "wrist"]
	else:
		names = ["hip", "knee", "ankle"]
	var result: Array[Vector2] = []
	for joint_name in names:
		var key := "%s_%s" % [prefix, joint_name]
		if not joints.has(key):
			# Profile far-side guides intentionally provide only the anchor. The
			# complete visible limb is translated onto this first pivot below.
			result.append(result.back() if not result.is_empty() else Vector2.ZERO)
		else:
			result.append(_polyline_center(joints[key]))
	return result


func _translated_limb_data(source: Array[Vector2], offset: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for point in source:
		result.append(point + offset)
	return result


func _build_head_clip(neck: PackedVector2Array, bounds: Rect2) -> PackedVector2Array:
	var result := PackedVector2Array([
		Vector2(bounds.position.x, bounds.position.y),
		Vector2(bounds.end.x, bounds.position.y),
		Vector2(bounds.end.x, neck[-1].y),
	])
	for index in range(neck.size() - 1, -1, -1):
		result.append(neck[index])
	result.append(Vector2(bounds.position.x, neck[0].y))
	return result


func _build_torso_clip(joints: Dictionary) -> PackedVector2Array:
	var neck: PackedVector2Array = joints["neck"]
	var waist: PackedVector2Array = joints["waist"]
	var left := minf(_minimum_x(neck), _minimum_x(waist)) - 30.0
	var right := maxf(_maximum_x(neck), _maximum_x(waist)) + 30.0
	var bottom := _maximum_y(waist) + 5.0
	var result := PackedVector2Array()
	# Follow the authored underside of the head instead of retaining a second,
	# hidden copy of chin pixels inside the torso mass.
	for point in neck:
		result.append(point)
	result.append(Vector2(right, neck[-1].y))
	result.append(Vector2(right, bottom))
	for index in range(waist.size() - 1, -1, -1):
		result.append(waist[index])
	result.append(Vector2(left, bottom))
	result.append(Vector2(left, neck[0].y))
	return result


func _build_hips_clip(joints: Dictionary, spec: Dictionary) -> PackedVector2Array:
	var waist: PackedVector2Array = joints["waist"]
	var near_hip: PackedVector2Array = joints["%s_hip" % String(spec["near"]).to_lower()]
	var far_hip: PackedVector2Array = joints["%s_hip" % String(spec["far"]).to_lower()]
	var left := minf(_minimum_x(waist), minf(_minimum_x(near_hip), _minimum_x(far_hip))) - 12.0
	var right := maxf(_maximum_x(waist), maxf(_maximum_x(near_hip), _maximum_x(far_hip))) + 12.0
	var bottom := maxf(_maximum_y(near_hip), _maximum_y(far_hip)) + 18.0
	return PackedVector2Array([
		Vector2(left, _minimum_y(waist) - 3.0),
		Vector2(right, _minimum_y(waist) - 3.0),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])


func _corridor(start: Vector2, end: Vector2, start_half_width: float, end_half_width: float) -> PackedVector2Array:
	var direction := (end - start).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	var perpendicular := Vector2(-direction.y, direction.x)
	return PackedVector2Array([
		start - perpendicular * start_half_width - direction * 4.0,
		start + perpendicular * start_half_width - direction * 4.0,
		end + perpendicular * end_half_width + direction * 4.0,
		end - perpendicular * end_half_width + direction * 4.0,
	])


func _add_polygon(
	parent: Node,
	polygon_name: String,
	image: Image,
	texture: Texture2D,
	clip: PackedVector2Array,
	pivot: Vector2,
	z_index: int,
	modulate_color: Color
) -> Polygon2D:
	var contour := _extract_alpha_contour(image, clip)
	var polygon := Polygon2D.new()
	polygon.name = polygon_name
	polygon.texture = texture
	polygon.polygon = _translated_points(contour, -pivot)
	polygon.uv = contour
	polygon.z_index = z_index
	polygon.z_as_relative = false
	polygon.antialiased = true
	polygon.modulate = modulate_color
	parent.add_child(polygon)
	return polygon


func _extract_alpha_contour(image: Image, clip: PackedVector2Array) -> PackedVector2Array:
	var mask := BitMap.new()
	mask.create(image.get_size())
	var bounds := _polygon_bounds(clip).intersection(Rect2(Vector2.ZERO, Vector2(image.get_size())))
	var bounds_i := Rect2i(Vector2i(floor(bounds.position.x), floor(bounds.position.y)), Vector2i(ceil(bounds.size.x), ceil(bounds.size.y)))
	for y in range(bounds_i.position.y, bounds_i.end.y):
		for x in range(bounds_i.position.x, bounds_i.end.x):
			var sample_point := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(sample_point, clip) and image.get_pixel(x, y).a > 0.08:
				mask.set_bit(x, y, true)
	var contours: Array[PackedVector2Array] = mask.opaque_to_polygons(bounds_i, CONTOUR_ERROR)
	var largest := PackedVector2Array()
	var largest_area := 0.0
	for local_contour in contours:
		# BitMap returns contour coordinates relative to the requested rectangle.
		# Restore image-space UV coordinates before comparing or serializing them.
		var contour := _translated_points(local_contour, Vector2(bounds_i.position))
		var area := absf(_signed_area(contour))
		if area > largest_area and not Geometry2D.triangulate_polygon(contour).is_empty():
			largest = contour
			largest_area = area
	return clip if largest.size() < 3 else largest


func _add_bone(parent: Node, bone_name: String, bone_position: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = bone_position
	bone.rest = Transform2D(0.0, bone_position)
	parent.add_child(bone)
	return bone


func _bone_global_pivot(bone: Bone2D) -> Vector2:
	var result := Vector2.ZERO
	var current: Node = bone
	while current is Bone2D:
		result += (current as Bone2D).position
		current = current.get_parent()
	return result + Vector2.ZERO


func _add_animation_player(root: Node2D, skeleton_origin: Vector2, spec: Dictionary) -> void:
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	root.add_child(player)
	var library := AnimationLibrary.new()
	library.add_animation("RESET", _build_reset_animation(root, skeleton_origin))
	library.add_animation("walk", _build_walk_animation(root, skeleton_origin, spec))
	player.add_animation_library("", library)
	player.autoplay = "walk"


func _build_reset_animation(root: Node2D, skeleton_origin: Vector2) -> Animation:
	var animation := Animation.new()
	animation.length = 0.001
	_add_track(animation, "Skeleton2D:position", [0.0], [skeleton_origin])
	for path in _animated_bone_paths():
		_add_track(animation, "%s:rotation" % path, [0.0], [0.0])
		_add_track(animation, "%s:scale" % path, [0.0], [Vector2.ONE])
	for path in _animated_leg_paths():
		var leg: Bone2D = root.get_node(path)
		_add_track(animation, "%s:position" % path, [0.0], [leg.position])
	return animation


func _build_walk_animation(root: Node2D, skeleton_origin: Vector2, spec: Dictionary) -> Animation:
	var motion_selection := _motion_profile(String(spec["id"]))
	var motion: Resource = motion_selection["resource"]
	var animation := Animation.new()
	animation.length = 1.0 / motion.cycle_speed
	animation.loop_mode = Animation.LOOP_LINEAR
	var quarter := animation.length * 0.25
	var times := [0.0, quarter, quarter * 2.0, quarter * 3.0, animation.length]
	var wave := [0.0, 1.0, 0.0, -1.0, 0.0]
	var leg_angle: float = deg_to_rad(motion.leg_swing_degrees)
	var arm_angle: float = deg_to_rad(motion.arm_swing_degrees)
	_add_track(animation, "Skeleton2D:position", times, _offset_vectors(skeleton_origin, Vector2.UP * motion.body_bob_distance, [0.0, 1.0, 0.0, 1.0, 0.0]))
	_add_track(animation, "Skeleton2D/Hips/FarLeg:rotation", times, _scaled_floats(leg_angle, wave))
	_add_track(animation, "Skeleton2D/Hips/NearLeg:rotation", times, _scaled_floats(-leg_angle, wave))
	_add_track(animation, "Skeleton2D/Hips/Torso/FarArm:rotation", times, _scaled_floats(-arm_angle, wave))
	_add_track(animation, "Skeleton2D/Hips/Torso/NearArm:rotation", times, _scaled_floats(arm_angle, wave))

	var projection: String = motion_selection["projection"]
	if projection in ["forward_depth", "three_quarter_depth"]:
		_add_track(animation, "Skeleton2D/Hips/FarLeg:scale", times, _depth_scales(motion.leg_depth_swing_ratio, wave))
		_add_track(animation, "Skeleton2D/Hips/NearLeg:scale", times, _depth_scales(-motion.leg_depth_swing_ratio, wave))
		_add_track(animation, "Skeleton2D/Hips/Torso/FarArm:scale", times, _depth_scales(-motion.arm_depth_swing_ratio, wave))
		_add_track(animation, "Skeleton2D/Hips/Torso/NearArm:scale", times, _depth_scales(motion.arm_depth_swing_ratio, wave))
	elif projection == "rear_stride":
		var far_leg: Bone2D = root.get_node("Skeleton2D/Hips/FarLeg")
		var near_leg: Bone2D = root.get_node("Skeleton2D/Hips/NearLeg")
		_add_track(animation, "Skeleton2D/Hips/FarLeg:position", times, _offset_vectors(far_leg.position, Vector2.DOWN * motion.stride_distance, wave))
		_add_track(animation, "Skeleton2D/Hips/NearLeg:position", times, _offset_vectors(near_leg.position, Vector2.UP * motion.stride_distance, wave))
	return animation


func _motion_profile(view_id: String) -> Dictionary:
	match view_id:
		"south":
			return {"projection": "forward_depth", "resource": FORWARD_MOTION}
		"west":
			return {"projection": "profile_rotation", "resource": PROFILE_MOTION}
		"north":
			# Rear-facing locomotion shares the south view's foreshortening
			# semantics while retaining an independently tunable rear profile.
			return {"projection": "forward_depth", "resource": REAR_MOTION}
		_:
			return {"projection": "three_quarter_depth", "resource": THREE_QUARTER_MOTION}


func _scaled_floats(amount: float, factors: Array) -> Array:
	var result: Array = []
	for factor in factors:
		result.append(amount * float(factor))
	return result


func _depth_scales(amount: float, factors: Array) -> Array:
	var result: Array = []
	for factor in factors:
		result.append(Vector2(1.0, 1.0 + amount * float(factor)))
	return result


func _offset_vectors(origin: Vector2, offset: Vector2, factors: Array) -> Array:
	var result: Array = []
	for factor in factors:
		result.append(origin + offset * float(factor))
	return result


func _animated_bone_paths() -> Array[String]:
	return [
		"Skeleton2D/Hips/FarLeg",
		"Skeleton2D/Hips/NearLeg",
		"Skeleton2D/Hips/Torso/FarArm",
		"Skeleton2D/Hips/Torso/NearArm",
	]


func _animated_leg_paths() -> Array[String]:
	return [
		"Skeleton2D/Hips/FarLeg",
		"Skeleton2D/Hips/NearLeg",
	]


func _add_track(animation: Animation, path: String, times: Array, values: Array) -> void:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath(path))
	animation.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
	for index in times.size():
		animation.track_insert_key(track, times[index], values[index])


func _guide_points(parent: Node, node_name: String) -> PackedVector2Array:
	var line: Line2D = parent.get_node(node_name)
	var result := PackedVector2Array()
	for point in line.points:
		result.append(point + line.position + IMAGE_CENTER)
	return result


func _polyline_center(points: PackedVector2Array) -> Vector2:
	var center := Vector2.ZERO
	for point in points:
		center += point
	return center / float(points.size())


func _translated_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + offset)
	return result


func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds.grow(1.0)


func _minimum_x(points: PackedVector2Array) -> float:
	var result := INF
	for point in points:
		result = minf(result, point.x)
	return result


func _maximum_x(points: PackedVector2Array) -> float:
	var result := -INF
	for point in points:
		result = maxf(result, point.x)
	return result


func _minimum_y(points: PackedVector2Array) -> float:
	var result := INF
	for point in points:
		result = minf(result, point.y)
	return result


func _maximum_y(points: PackedVector2Array) -> float:
	var result := -INF
	for point in points:
		result = maxf(result, point.y)
	return result


func _signed_area(points: PackedVector2Array) -> float:
	var area := 0.0
	for index in points.size():
		var next_index := (index + 1) % points.size()
		area += points[index].x * points[next_index].y - points[next_index].x * points[index].y
	return area * 0.5


func _set_scene_owner(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		_set_scene_owner(child, scene_root)


func _pascal_case(value: String) -> String:
	var result := ""
	for piece in value.split("_"):
		result += piece.capitalize()
	return result
