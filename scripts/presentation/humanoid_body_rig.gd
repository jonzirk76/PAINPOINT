@tool
extends Node2D
class_name HumanoidBodyRig

const DEFAULT_FORWARD_MOTION: Resource = preload("res://resources/presentation/humanoid_forward_motion_profile.tres")
const DEFAULT_PROFILE_MOTION: Resource = preload("res://resources/presentation/humanoid_profile_motion_profile.tres")
const DEFAULT_THREE_QUARTER_MOTION: Resource = preload("res://resources/presentation/humanoid_three_quarter_motion_profile.tres")
const DEFAULT_REAR_MOTION: Resource = preload("res://resources/presentation/humanoid_rear_motion_profile.tres")

enum PreviewDirection {
	DOWN,
	DOWN_RIGHT,
	RIGHT,
	UP_RIGHT,
	UP,
	UP_LEFT,
	LEFT,
	DOWN_LEFT,
}

## Plays the locomotion pose in the editor so pivots can be evaluated without running gameplay.
@export var animate_preview: bool = true:
	set(value):
		animate_preview = value
		_update_processing()

## Shows optional hairstyle overlays. Body projection work keeps these hidden by default.
@export var show_hair: bool = false:
	set(value):
		show_hair = value
		_refresh_hair_visibility()

## Eight-way direction shown by the editor preview and used as the initial runtime facing.
@export_enum("Down", "Down Right", "Right", "Up Right", "Up", "Up Left", "Left", "Down Left") var preview_direction: int = PreviewDirection.DOWN:
	set(value):
		preview_direction = value
		set_motion_state(_preview_direction_vector(), preview_speed_ratio)

## Normalized locomotion speed used by the editor preview.
@export_range(0.0, 1.0, 0.01) var preview_speed_ratio := 0.75:
	set(value):
		preview_speed_ratio = value
		set_motion_state(_preview_direction_vector(), preview_speed_ratio)

@export_group("View Motion Profiles")

## Motion semantics and tuning used only by the forward-facing projection.
@export var forward_motion_profile: Resource = DEFAULT_FORWARD_MOTION

## Motion semantics and tuning used only by the left/right profile projection.
@export var profile_motion_profile: Resource = DEFAULT_PROFILE_MOTION

## Motion semantics and tuning used only by the forward three-quarter projection.
@export var three_quarter_motion_profile: Resource = DEFAULT_THREE_QUARTER_MOTION

## Motion semantics and tuning used only by the rear-facing projection.
@export var rear_motion_profile: Resource = DEFAULT_REAR_MOTION

var _phase := 0.0
var _speed_ratio := 0.0
var _facing := Vector2.DOWN
var _active_view: Node2D
var _rest_transforms: Dictionary = {}


func _ready() -> void:
	_refresh_hair_visibility()
	_capture_rest_pose()
	set_motion_state(_preview_direction_vector(), preview_speed_ratio if Engine.is_editor_hint() else 0.0)
	_update_processing()


func _preview_direction_vector() -> Vector2:
	match preview_direction:
		PreviewDirection.DOWN_RIGHT:
			return Vector2(1.0, 1.0).normalized()
		PreviewDirection.RIGHT:
			return Vector2.RIGHT
		PreviewDirection.UP_RIGHT:
			return Vector2(1.0, -1.0).normalized()
		PreviewDirection.UP:
			return Vector2.UP
		PreviewDirection.UP_LEFT:
			return Vector2(-1.0, -1.0).normalized()
		PreviewDirection.LEFT:
			return Vector2.LEFT
		PreviewDirection.DOWN_LEFT:
			return Vector2(-1.0, 1.0).normalized()
		_:
			return Vector2.DOWN


func _notification(what: int) -> void:
	if not Engine.is_editor_hint() or _rest_transforms.is_empty():
		return
	if what == NOTIFICATION_EDITOR_PRE_SAVE or what == NOTIFICATION_EXIT_TREE:
		_restore_rest_pose()
		_reset_dynamic_depth_layers()
	elif what == NOTIFICATION_EDITOR_POST_SAVE and animate_preview:
		_apply_pose()


func _process(delta: float) -> void:
	if not Engine.is_editor_hint() or not animate_preview:
		return
	var motion: Resource = _get_active_motion_profile()
	_phase = fposmod(_phase + delta * motion.cycle_speed * maxf(preview_speed_ratio, 0.05), 1.0)
	_apply_pose()


## Updates the body-only rig from an entity-owned movement direction and normalized speed.
func set_motion_state(direction: Vector2, speed_ratio: float) -> void:
	if direction.length_squared() > 0.001:
		_facing = direction.normalized()
	_speed_ratio = clampf(speed_ratio, 0.0, 1.0)
	_select_directional_view()
	_apply_pose()


## Advances locomotion explicitly when the owning entity does not want editor-style processing.
func advance_motion(delta: float) -> void:
	if _speed_ratio <= 0.001:
		_apply_pose()
		return
	var motion: Resource = _get_active_motion_profile()
	_phase = fposmod(_phase + delta * motion.cycle_speed * _speed_ratio, 1.0)
	_apply_pose()


func reset_pose() -> void:
	_phase = 0.0
	_speed_ratio = 0.0
	_apply_pose()


func _update_processing() -> void:
	set_process(Engine.is_editor_hint() and animate_preview)


func _capture_rest_pose() -> void:
	_rest_transforms.clear()
	for view_name in [&"FrontView", &"SideView", &"ThreeQuarterView", &"RearThreeQuarterView", &"RearView"]:
		var view := get_node_or_null(NodePath(String(view_name))) as Node2D
		if view == null:
			continue
		_capture_node(view)
		for relative_path in [
			"BodyMotion",
			"BodyMotion/TorsoPivot",
			"BodyMotion/TorsoPivot/HipsAnchor/HipsPivot",
			"BodyMotion/TorsoPivot/HeadAnchor/HeadPivot",
			"BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/LeftHipSocket/LeftLegPivot",
			"BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/RightHipSocket/RightLegPivot",
			"BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/BackHipSocket/BackLegPivot",
			"BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/FrontHipSocket/FrontLegPivot",
			"BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/FarHipSocket/FarLegPivot",
			"BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/NearHipSocket/NearLegPivot",
			"BodyMotion/TorsoPivot/LeftShoulderAnchor/LeftArmPivot",
			"BodyMotion/TorsoPivot/RightShoulderAnchor/RightArmPivot",
			"BodyMotion/TorsoPivot/FarShoulderAnchor/FarArmPivot",
			"BodyMotion/TorsoPivot/NearShoulderAnchor/NearArmPivot",
			"BodyMotion/LeftLegPivot",
			"BodyMotion/RightLegPivot",
			"BodyMotion/RightLegMirrorAxis/RightLegPivot",
			"BodyMotion/LeftArmPivot",
			"BodyMotion/LeftArmPivot/ElbowPivot",
			"BodyMotion/RightArmPivot",
			"BodyMotion/RightArmMirrorAxis/RightArmPivot",
			"BodyMotion/RightArmPivot/ElbowPivot",
			"BodyMotion/RightArmMirrorAxis/RightArmPivot/ElbowPivot",
		]:
			var target := view.get_node_or_null(NodePath(relative_path)) as Node2D
			if target != null:
				_capture_node(target)


func _capture_node(node: Node2D) -> void:
	_rest_transforms[node.get_path()] = node.transform


func _select_directional_view() -> void:
	var front := get_node_or_null("FrontView") as Node2D
	var side := get_node_or_null("SideView") as Node2D
	var three_quarter := get_node_or_null("ThreeQuarterView") as Node2D
	var rear_three_quarter := get_node_or_null("RearThreeQuarterView") as Node2D
	var rear := get_node_or_null("RearView") as Node2D
	if front == null or side == null or three_quarter == null or rear_three_quarter == null or rear == null:
		return
	front.visible = false
	side.visible = false
	three_quarter.visible = false
	rear_three_quarter.visible = false
	rear.visible = false
	var has_horizontal := absf(_facing.x) > 0.001
	var has_vertical := absf(_facing.y) > 0.001
	var horizontal_vertical_ratio := absf(_facing.x) / maxf(absf(_facing.y), 0.001)
	var is_diagonal := (
		has_horizontal
		and has_vertical
		and horizontal_vertical_ratio >= 0.4142
		and horizontal_vertical_ratio <= 2.4142
	)
	if is_diagonal and _facing.y >= 0.0:
		_active_view = three_quarter
		three_quarter.visible = true
		# The authored source is the bottom-left concept cell.
		three_quarter.scale.x = 1.0 if _facing.x < 0.0 else -1.0
	elif is_diagonal:
		_active_view = rear_three_quarter
		rear_three_quarter.visible = true
		# The rear source is authored up-right and mirrors to up-left.
		rear_three_quarter.scale.x = 1.0 if _facing.x > 0.0 else -1.0
	elif absf(_facing.x) > absf(_facing.y):
		_active_view = side
		side.visible = true
		side.scale.x = -1.0 if _facing.x < 0.0 else 1.0
	elif _facing.y < 0.0:
		_active_view = rear
		rear.visible = true
	else:
		_active_view = front
		front.visible = true


func _apply_pose() -> void:
	_restore_rest_pose()
	if not is_instance_valid(_active_view):
		_select_directional_view()
	if not is_instance_valid(_active_view):
		return
	if _active_view.name == &"SideView":
		_active_view.scale.x = -1.0 if _facing.x < 0.0 else 1.0
	elif _active_view.name == &"ThreeQuarterView":
		_active_view.scale.x = 1.0 if _facing.x < 0.0 else -1.0
	elif _active_view.name == &"RearThreeQuarterView":
		_active_view.scale.x = 1.0 if _facing.x > 0.0 else -1.0
	var wave := sin(_phase * TAU) * _speed_ratio
	var lift := absf(sin(_phase * TAU * 0.65)) * _speed_ratio
	var body_motion := _active_view.get_node_or_null("BodyMotion") as Node2D
	var torso := _active_view.get_node_or_null("BodyMotion/TorsoPivot") as Node2D
	var hips := _find_first(_active_view, ["BodyMotion/TorsoPivot/HipsAnchor/HipsPivot", "BodyMotion/PelvisPivot"])
	var head := _find_first(_active_view, ["BodyMotion/TorsoPivot/HeadAnchor/HeadPivot", "BodyMotion/TorsoPivot/NeckPivot/HeadPivot"])
	var left_leg := _find_first(_active_view, ["BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/LeftHipSocket/LeftLegPivot", "BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/BackHipSocket/BackLegPivot", "BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/FarHipSocket/FarLegPivot", "BodyMotion/LeftLegPivot"])
	var right_leg := _find_first(_active_view, ["BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/RightHipSocket/RightLegPivot", "BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/FrontHipSocket/FrontLegPivot", "BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/NearHipSocket/NearLegPivot", "BodyMotion/RightLegPivot", "BodyMotion/RightLegMirrorAxis/RightLegPivot"])
	var left_arm := _find_first(_active_view, ["BodyMotion/TorsoPivot/LeftShoulderAnchor/LeftArmPivot", "BodyMotion/TorsoPivot/FarShoulderAnchor/FarArmPivot", "BodyMotion/LeftArmPivot"])
	var right_arm := _find_first(_active_view, ["BodyMotion/TorsoPivot/RightShoulderAnchor/RightArmPivot", "BodyMotion/TorsoPivot/NearShoulderAnchor/NearArmPivot", "BodyMotion/RightArmPivot", "BodyMotion/RightArmMirrorAxis/RightArmPivot"])
	var uses_forward_depth_projection := _active_view.name in [&"FrontView", &"ThreeQuarterView", &"RearThreeQuarterView"]
	var uses_profile_projection := _active_view.name == &"SideView"
	var motion: Resource = _get_active_motion_profile()
	if body_motion != null:
		body_motion.position.y -= lift * motion.body_bob_distance
	if torso != null:
		torso.rotation -= deg_to_rad(motion.torso_twist_degrees) * wave
	if hips != null:
		hips.rotation += deg_to_rad(motion.hip_tilt_degrees) * wave
	if head != null:
		head.rotation += deg_to_rad(motion.head_counter_tilt_degrees) * wave
	if left_leg != null:
		if uses_forward_depth_projection:
			left_leg.scale.y *= 1.0 + motion.leg_depth_swing_ratio * wave
		elif not uses_profile_projection:
			left_leg.position.y += motion.stride_distance * wave
		left_leg.rotation += deg_to_rad(motion.leg_swing_degrees) * wave
	if right_leg != null:
		if uses_forward_depth_projection:
			right_leg.scale.y *= 1.0 - motion.leg_depth_swing_ratio * wave
		elif not uses_profile_projection:
			right_leg.position.y -= motion.stride_distance * wave
		_apply_opposed_rotation(right_leg, deg_to_rad(motion.leg_swing_degrees) * wave)
	if left_arm != null:
		if uses_forward_depth_projection:
			left_arm.scale.y *= 1.0 - motion.arm_depth_swing_ratio * wave
			left_arm.z_index = _depth_layer(-wave)
		left_arm.rotation -= deg_to_rad(motion.arm_swing_degrees) * wave
	if right_arm != null:
		if uses_forward_depth_projection:
			right_arm.scale.y *= 1.0 + motion.arm_depth_swing_ratio * wave
			right_arm.z_index = _depth_layer(wave)
		_apply_opposed_rotation(right_arm, -deg_to_rad(motion.arm_swing_degrees) * wave)


func _get_active_motion_profile():
	if is_instance_valid(_active_view):
		if _active_view.name == &"SideView":
			return profile_motion_profile if profile_motion_profile != null else DEFAULT_PROFILE_MOTION
		if _active_view.name in [&"ThreeQuarterView", &"RearThreeQuarterView"]:
			return three_quarter_motion_profile if three_quarter_motion_profile != null else DEFAULT_THREE_QUARTER_MOTION
		if _active_view.name == &"RearView":
			return rear_motion_profile if rear_motion_profile != null else DEFAULT_REAR_MOTION
	return forward_motion_profile if forward_motion_profile != null else DEFAULT_FORWARD_MOTION


func _find_part(view: Node2D, direct_path: NodePath, mirrored_path: NodePath) -> Node2D:
	var part := view.get_node_or_null(direct_path) as Node2D
	if part == null:
		part = view.get_node_or_null(mirrored_path) as Node2D
	return part


func _find_first(view: Node2D, paths: Array) -> Node2D:
	for path in paths:
		var part := view.get_node_or_null(NodePath(path)) as Node2D
		if part != null:
			return part
	return null


func _apply_opposed_rotation(part: Node2D, visual_angle: float) -> void:
	var relative_transform := part.global_transform
	if is_instance_valid(_active_view):
		relative_transform = _active_view.global_transform.affine_inverse() * part.global_transform
	var internally_mirrored := relative_transform.determinant() < 0.0
	# Ignore reflection of the complete directional view here. Only a mirror
	# inside the assembly changes which local sign produces the opposed pose.
	part.rotation += visual_angle if internally_mirrored else -visual_angle


func _depth_layer(depth_amount: float) -> int:
	if depth_amount > 0.01:
		return 1
	if depth_amount < -0.01:
		return -1
	return 0


func _reset_dynamic_depth_layers() -> void:
	for path in [
		"FrontView/BodyMotion/TorsoPivot/LeftShoulderAnchor/LeftArmPivot",
		"FrontView/BodyMotion/TorsoPivot/RightShoulderAnchor/RightArmPivot",
		"ThreeQuarterView/BodyMotion/TorsoPivot/FarShoulderAnchor/FarArmPivot",
		"ThreeQuarterView/BodyMotion/TorsoPivot/NearShoulderAnchor/NearArmPivot",
		"RearThreeQuarterView/BodyMotion/TorsoPivot/FarShoulderAnchor/FarArmPivot",
		"RearThreeQuarterView/BodyMotion/TorsoPivot/NearShoulderAnchor/NearArmPivot",
	]:
		var arm := get_node_or_null(NodePath(path)) as Node2D
		if arm != null:
			arm.z_index = 0


func _restore_rest_pose() -> void:
	for path: NodePath in _rest_transforms:
		var target := get_node_or_null(path) as Node2D
		if target != null:
			target.transform = _rest_transforms[path]


func _refresh_hair_visibility() -> void:
	for view_name in [&"FrontView", &"SideView", &"ThreeQuarterView", &"RearThreeQuarterView", &"RearView"]:
		var view := get_node_or_null(NodePath(String(view_name)))
		if view == null:
			continue
		for candidate in view.find_children("*Hair*", "", true, false):
			if candidate is CanvasItem:
				(candidate as CanvasItem).visible = show_hair
