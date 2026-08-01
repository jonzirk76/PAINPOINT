@tool
extends Node2D
class_name HumanoidBodyRig

## Plays the locomotion pose in the editor so pivots can be evaluated without running gameplay.
@export var animate_preview: bool = true:
	set(value):
		animate_preview = value
		_update_processing()

## Direction used by the editor preview and as the initial runtime facing.
@export var preview_direction := Vector2.DOWN:
	set(value):
		preview_direction = value
		set_motion_state(preview_direction, preview_speed_ratio)

## Normalized locomotion speed used by the editor preview.
@export_range(0.0, 1.0, 0.01) var preview_speed_ratio := 0.75:
	set(value):
		preview_speed_ratio = value
		set_motion_state(preview_direction, preview_speed_ratio)

## Cycles per second for the procedural prototype walk.
@export_range(0.1, 8.0, 0.1) var cycle_speed := 2.4

## Maximum rigid upper-leg rotation in degrees.
@export_range(0.0, 30.0, 0.5) var leg_swing_degrees := 12.0

## Maximum elbow counter-swing in degrees.
@export_range(0.0, 24.0, 0.5) var arm_swing_degrees := 8.0

## Vertical body travel at full locomotion speed.
@export_range(0.0, 8.0, 0.25) var body_bob_distance := 1.5

## Small torso counter-rotation at full locomotion speed.
@export_range(0.0, 8.0, 0.25) var torso_twist_degrees := 2.0

var _phase := 0.0
var _speed_ratio := 0.0
var _facing := Vector2.DOWN
var _active_view: Node2D
var _rest_transforms: Dictionary = {}


func _ready() -> void:
	_capture_rest_pose()
	set_motion_state(preview_direction, preview_speed_ratio if Engine.is_editor_hint() else 0.0)
	_update_processing()


func _process(delta: float) -> void:
	if not Engine.is_editor_hint() or not animate_preview:
		return
	_phase = fposmod(_phase + delta * cycle_speed * maxf(preview_speed_ratio, 0.05), 1.0)
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
	_phase = fposmod(_phase + delta * cycle_speed * _speed_ratio, 1.0)
	_apply_pose()


func reset_pose() -> void:
	_phase = 0.0
	_speed_ratio = 0.0
	_apply_pose()


func _update_processing() -> void:
	set_process(Engine.is_editor_hint() and animate_preview)


func _capture_rest_pose() -> void:
	_rest_transforms.clear()
	for view_name in [&"FrontView", &"SideView", &"RearView"]:
		var view := get_node_or_null(NodePath(String(view_name))) as Node2D
		if view == null:
			continue
		_capture_node(view)
		for relative_path in [
			"BodyMotion",
			"BodyMotion/TorsoPivot",
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
	var rear := get_node_or_null("RearView") as Node2D
	if front == null or side == null or rear == null:
		return
	front.visible = false
	side.visible = false
	rear.visible = false
	if absf(_facing.x) > absf(_facing.y):
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
	var wave := sin(_phase * TAU) * _speed_ratio
	var lift := absf(cos(_phase * TAU)) * _speed_ratio
	var body_motion := _active_view.get_node_or_null("BodyMotion") as Node2D
	var torso := _active_view.get_node_or_null("BodyMotion/TorsoPivot") as Node2D
	var left_leg := _active_view.get_node_or_null("BodyMotion/LeftLegPivot") as Node2D
	var right_leg := _find_part(_active_view, "BodyMotion/RightLegPivot", "BodyMotion/RightLegMirrorAxis/RightLegPivot")
	var left_arm := _active_view.get_node_or_null("BodyMotion/LeftArmPivot") as Node2D
	var right_arm := _find_part(_active_view, "BodyMotion/RightArmPivot", "BodyMotion/RightArmMirrorAxis/RightArmPivot")
	if body_motion != null:
		body_motion.position.y -= lift * body_bob_distance
	if torso != null:
		torso.rotation += deg_to_rad(torso_twist_degrees) * wave
	if left_leg != null:
		left_leg.rotation += deg_to_rad(leg_swing_degrees) * wave
	if right_leg != null:
		right_leg.rotation -= deg_to_rad(leg_swing_degrees) * wave
	if left_arm != null:
		left_arm.rotation -= deg_to_rad(arm_swing_degrees) * wave
	if right_arm != null:
		right_arm.rotation += deg_to_rad(arm_swing_degrees) * wave


func _find_part(view: Node2D, direct_path: NodePath, mirrored_path: NodePath) -> Node2D:
	var part := view.get_node_or_null(direct_path) as Node2D
	if part == null:
		part = view.get_node_or_null(mirrored_path) as Node2D
	return part


func _restore_rest_pose() -> void:
	for path: NodePath in _rest_transforms:
		var target := get_node_or_null(path) as Node2D
		if target != null:
			target.transform = _rest_transforms[path]
