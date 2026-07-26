@tool
extends Control
class_name CharacterWalkCyclePreview

const DEFAULT_CHARACTER_SCENE: PackedScene = preload("res://walk_test.tscn")

const VIEW_FRONT := "front"
const VIEW_SIDE := "side"
const VIEW_REAR := "rear"
const VIEW_ALL := "all"

## Scene containing the blocked-out character nodes to preview.
@export var character_scene: PackedScene = DEFAULT_CHARACTER_SCENE:
	set(value):
		character_scene = value
		_rebuild_preview_deferred()

## Which view roots to show while previewing the walk cycle.
@export_enum("front", "side", "rear", "all") var view_mode: String = VIEW_FRONT:
	set(value):
		view_mode = value
		_update_view_visibility()
		_layout_character()

## Fits the visible view into this preview control.
@export var auto_center_character: bool = true:
	set(value):
		auto_center_character = value
		_layout_character()

## Scale applied to the character scene instance inside the preview.
@export_range(0.05, 1.0, 0.01) var character_scale: float = 0.2:
	set(value):
		character_scale = value
		_layout_character()

## Screen-space offset applied after centering.
@export var preview_offset: Vector2 = Vector2.ZERO:
	set(value):
		preview_offset = value
		_layout_character()

## Plays the walk cycle in the editor.
@export var animate_walk: bool = true:
	set(value):
		animate_walk = value
		_update_processing()

## Manual pose phase used when Animate Walk is disabled.
@export_range(0.0, 1.0, 0.01) var manual_phase: float = 0.0:
	set(value):
		manual_phase = value
		_apply_walk_pose()

## Matches the current PlayerEntity walk-cycle rate.
@export_range(1.0, 24.0, 0.1) var walk_speed: float = 12.0:
	set(value):
		walk_speed = value

## Direction that the previewed character is walking in scene-local coordinates.
@export var walk_direction: Vector2 = Vector2.DOWN:
	set(value):
		walk_direction = value
		_apply_walk_pose()

## Maximum local-pixel leg travel before character scale is applied.
@export_range(0.0, 64.0, 0.5) var stride_distance: float = 5.0:
	set(value):
		stride_distance = value
		_apply_walk_pose()

## Small sideways counter-motion before character scale is applied.
@export_range(0.0, 24.0, 0.5) var lateral_sway: float = 0.0:
	set(value):
		lateral_sway = value
		_apply_walk_pose()

## Rotates each leg group opposite its paired leg.
@export_range(0.0, 18.0, 0.1) var leg_swing_degrees: float = 0.0:
	set(value):
		leg_swing_degrees = value
		_apply_walk_pose()

## Optional vertical bob on the visible view root.
@export_range(0.0, 16.0, 0.25) var body_bob_distance: float = 0.0:
	set(value):
		body_bob_distance = value
		_apply_walk_pose()

## Extra upward travel applied to KneePad nodes during the lifted half of each stride.
@export_range(0.0, 24.0, 0.25) var knee_lift_distance: float = 2.0:
	set(value):
		knee_lift_distance = value
		_apply_walk_pose()

## Extra upward travel applied to Shoe nodes during the lifted half of each stride.
@export_range(0.0, 24.0, 0.25) var foot_lift_distance: float = 3.5:
	set(value):
		foot_lift_distance = value
		_apply_walk_pose()

## Maximum degrees used to tilt hip target nodes around their visible centers.
@export_range(0.0, 18.0, 0.1) var hip_tilt_degrees: float = 0.0:
	set(value):
		hip_tilt_degrees = value
		_apply_walk_pose()

## Cycle offset for hip tilt timing; 0 follows the left-leg stride and 0.5 swaps sides.
@export_range(-1.0, 1.0, 0.01) var hip_tilt_phase_offset: float = 0.0:
	set(value):
		hip_tilt_phase_offset = value
		_apply_walk_pose()

## Flips the hip tilt direction without changing its timing.
@export var invert_hip_tilt: bool = false:
	set(value):
		invert_hip_tilt = value
		_apply_walk_pose()

## Upward torso/body bounce applied to body target nodes.
@export_range(0.0, 24.0, 0.25) var body_bounce_distance: float = 0.0:
	set(value):
		body_bounce_distance = value
		_apply_walk_pose()

## Multiplies only the body/head/hair/gun bounce timing; lower values make bounce slower than the stride.
@export_range(0.1, 2.0, 0.01) var bounce_speed_multiplier: float = 1.0:
	set(value):
		bounce_speed_multiplier = value
		_apply_walk_pose()

## Cycle offset for torso/body bounce timing.
@export_range(-1.0, 1.0, 0.01) var body_bounce_phase_offset: float = 0.0:
	set(value):
		body_bounce_phase_offset = value
		_apply_walk_pose()

## Upward bounce applied to head target nodes.
@export_range(0.0, 24.0, 0.25) var head_bounce_distance: float = 0.0:
	set(value):
		head_bounce_distance = value
		_apply_walk_pose()

## Cycle offset for head bounce timing.
@export_range(-1.0, 1.0, 0.01) var head_bounce_phase_offset: float = 0.04:
	set(value):
		head_bounce_phase_offset = value
		_apply_walk_pose()

## Upward bounce applied to hair target nodes.
@export_range(0.0, 32.0, 0.25) var hair_bounce_distance: float = 0.0:
	set(value):
		hair_bounce_distance = value
		_apply_walk_pose()

## Cycle offset for hair bounce timing; positive values make hair lag the body.
@export_range(-1.0, 1.0, 0.01) var hair_bounce_phase_offset: float = 0.08:
	set(value):
		hair_bounce_phase_offset = value
		_apply_walk_pose()

## Upward bounce applied to gun or weapon target nodes.
@export_range(0.0, 24.0, 0.25) var gun_bounce_distance: float = 0.0:
	set(value):
		gun_bounce_distance = value
		_apply_walk_pose()

## Cycle offset for gun or weapon bounce timing.
@export_range(-1.0, 1.0, 0.01) var gun_bounce_phase_offset: float = 0.02:
	set(value):
		gun_bounce_phase_offset = value
		_apply_walk_pose()

## Draws the preview frame and center guides.
@export var show_guides: bool = true:
	set(value):
		show_guides = value
		queue_redraw()

## Draws the bounds used for automatic centering.
@export var show_character_bounds: bool = true:
	set(value):
		show_character_bounds = value
		queue_redraw()

## Root shown for the front-facing character view.
@export var front_view_path: NodePath = NodePath("FrontView"):
	set(value):
		front_view_path = value
		_update_view_visibility()
		_layout_character()

## Left leg group for the front-facing walk cycle.
@export var front_left_leg_path: NodePath = NodePath("FrontView/Legs/LeftLeg"):
	set(value):
		front_left_leg_path = value
		_capture_baselines()
		_apply_walk_pose()

## Right leg group for the front-facing walk cycle.
@export var front_right_leg_path: NodePath = NodePath("FrontView/Legs/LegMirrorPivot"):
	set(value):
		front_right_leg_path = value
		_capture_baselines()
		_apply_walk_pose()

## Root shown for the side-facing character view.
@export var side_view_path: NodePath = NodePath("SideView"):
	set(value):
		side_view_path = value
		_update_view_visibility()
		_layout_character()

## Back leg group for the side-facing walk cycle.
@export var side_back_leg_path: NodePath = NodePath("SideView/BackLeg_Side"):
	set(value):
		side_back_leg_path = value
		_capture_baselines()
		_apply_walk_pose()

## Front leg group for the side-facing walk cycle.
@export var side_front_leg_path: NodePath = NodePath("SideView/FrontLeg_Side"):
	set(value):
		side_front_leg_path = value
		_capture_baselines()
		_apply_walk_pose()

## Root shown for the rear-facing character view.
@export var rear_view_path: NodePath = NodePath("RearView"):
	set(value):
		rear_view_path = value
		_update_view_visibility()
		_layout_character()

## Left leg group for the rear-facing walk cycle.
@export var rear_left_leg_path: NodePath = NodePath("RearView/Legs/LeftLeg"):
	set(value):
		rear_left_leg_path = value
		_capture_baselines()
		_apply_walk_pose()

## Right leg group for the rear-facing walk cycle.
@export var rear_right_leg_path: NodePath = NodePath("RearView/Legs/RightLeg"):
	set(value):
		rear_right_leg_path = value
		_capture_baselines()
		_apply_walk_pose()

## Comma-separated hip nodes that can receive walk-cycle tilt.
@export var hip_target_paths: String = "FrontView/Hips,SideView/SideHips,RearView/Hips":
	set(value):
		hip_target_paths = value
		_capture_baselines()
		_apply_walk_pose()

## Comma-separated torso/body nodes that can receive walk-cycle bounce.
@export var body_target_paths: String = "FrontView/Body,SideView/SideBody,RearView/Body":
	set(value):
		body_target_paths = value
		_capture_baselines()
		_apply_walk_pose()

## Comma-separated head nodes that can receive walk-cycle bounce.
@export var head_target_paths: String = "FrontView/FrontHead,SideView/ProfileReference,RearView/FrontHead":
	set(value):
		head_target_paths = value
		_capture_baselines()
		_apply_walk_pose()

## Comma-separated hair nodes that can receive walk-cycle bounce.
@export var hair_target_paths: String = "FrontView/BackHair_Front,FrontView/ScalpHair_Front,FrontView/Bang_Front,SideView/BackHair_Side,SideView/ScalpHair_Side,SideView/Bang_Side,RearView/BackHair_Rear,RearView/ScalpHair_Front,RearView/Bang_Rear":
	set(value):
		hair_target_paths = value
		_capture_baselines()
		_apply_walk_pose()

## Comma-separated weapon or gun nodes that can receive walk-cycle bounce.
@export var gun_target_paths: String = "FrontView/Guns":
	set(value):
		gun_target_paths = value
		_capture_baselines()
		_apply_walk_pose()

var _character_instance: Node2D
var _walk_cycle: float = 0.0
var _baseline_transforms: Dictionary = {}
var _lower_extremity_baselines: Dictionary = {}
var _motion_target_baselines: Dictionary = {}
var _view_root_baselines: Dictionary = {}
var _last_bounds: Rect2 = Rect2()


func _ready() -> void:
	custom_minimum_size = Vector2(720.0, 560.0)
	_rebuild_preview_instance()
	_update_processing()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_character()


func _process(delta: float) -> void:
	if not Engine.is_editor_hint() or not animate_walk:
		return
	_walk_cycle += delta * walk_speed
	_apply_walk_pose()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.12, 0.13, 0.14, 1.0), true)
	var preview_rect := rect.grow(-28.0)
	draw_rect(preview_rect, Color(0.035, 0.04, 0.048, 1.0), true)
	if not show_guides:
		return
	draw_rect(preview_rect, Color(0.35, 0.55, 0.82, 0.36), false, 2.0)
	draw_line(Vector2(preview_rect.position.x, size.y * 0.5), Vector2(preview_rect.end.x, size.y * 0.5), Color(0.35, 0.55, 0.82, 0.22), 1.0)
	draw_line(Vector2(size.x * 0.5, preview_rect.position.y), Vector2(size.x * 0.5, preview_rect.end.y), Color(0.35, 0.55, 0.82, 0.22), 1.0)
	if show_character_bounds and _last_bounds.size != Vector2.ZERO:
		var top_left := _character_instance.position + _last_bounds.position * character_scale if is_instance_valid(_character_instance) else Vector2.ZERO
		var scaled_size := _last_bounds.size * character_scale
		draw_rect(Rect2(top_left, scaled_size), Color(0.0, 0.82, 1.0, 0.55), false, 1.0)


func _rebuild_preview_deferred() -> void:
	if not is_inside_tree():
		return
	call_deferred("_rebuild_preview_instance")


func _rebuild_preview_instance() -> void:
	if not Engine.is_editor_hint():
		return
	if is_instance_valid(_character_instance):
		_character_instance.queue_free()
	_character_instance = null
	_baseline_transforms.clear()
	_lower_extremity_baselines.clear()
	_motion_target_baselines.clear()
	_view_root_baselines.clear()
	_last_bounds = Rect2()
	if character_scene == null:
		queue_redraw()
		return
	var instance := character_scene.instantiate()
	if not instance is Node2D:
		push_warning("Character walk preview expects a Node2D root scene.")
		instance.queue_free()
		queue_redraw()
		return
	_character_instance = instance
	add_child(_character_instance)
	_capture_baselines()
	_update_view_visibility()
	_layout_character()
	_apply_walk_pose()


func _capture_baselines() -> void:
	_baseline_transforms.clear()
	_lower_extremity_baselines.clear()
	_motion_target_baselines.clear()
	_view_root_baselines.clear()
	if not is_instance_valid(_character_instance):
		return
	for path in _get_all_leg_paths():
		var node := _get_node2d(path)
		if node == null:
			continue
		_baseline_transforms[String(path)] = {
			"position": node.position,
			"rotation": node.rotation,
			"scale": node.scale,
			"transform": node.transform,
			"pivot_local": _calculate_node_local_bounds(node).get_center(),
		}
		_capture_lower_extremity_baseline(path, node, "KneePad", "knee")
		_capture_lower_extremity_baseline(path, node, "Shoe", "foot")
	for path in _get_all_motion_target_paths():
		_capture_motion_target_baseline(path)
	for path in [front_view_path, side_view_path, rear_view_path]:
		var root := _get_node2d(path)
		if root == null:
			continue
		_view_root_baselines[String(path)] = {
			"position": root.position,
			"rotation": root.rotation,
			"scale": root.scale,
		}


func _update_processing() -> void:
	if Engine.is_editor_hint():
		set_process(animate_walk)


func _update_view_visibility() -> void:
	if not is_instance_valid(_character_instance):
		return
	var front_root := _get_node2d(front_view_path)
	var side_root := _get_node2d(side_view_path)
	var rear_root := _get_node2d(rear_view_path)
	if front_root != null:
		front_root.visible = view_mode == VIEW_FRONT or view_mode == VIEW_ALL
	if side_root != null:
		side_root.visible = view_mode == VIEW_SIDE or view_mode == VIEW_ALL
	if rear_root != null:
		rear_root.visible = view_mode == VIEW_REAR or view_mode == VIEW_ALL


func _layout_character() -> void:
	if not is_inside_tree() or not is_instance_valid(_character_instance):
		queue_redraw()
		return
	_character_instance.scale = Vector2.ONE
	if auto_center_character:
		_last_bounds = _calculate_visible_bounds()
		var center := size * 0.5
		if center == Vector2.ZERO:
			center = custom_minimum_size * 0.5
		if _last_bounds.size != Vector2.ZERO:
			_character_instance.position = center + preview_offset - _last_bounds.get_center() * character_scale
		else:
			_character_instance.position = center + preview_offset
	else:
		_last_bounds = _calculate_visible_bounds()
		_character_instance.position = size * 0.5 + preview_offset
	_character_instance.scale = Vector2(character_scale, character_scale)
	queue_redraw()


func _apply_walk_pose() -> void:
	if not is_instance_valid(_character_instance):
		return
	_reset_pose_to_baseline()
	var cycle := _walk_cycle if animate_walk else manual_phase * TAU
	var phase := sin(cycle)
	var sway_phase := cos(cycle)
	var direction := walk_direction
	if direction.length_squared() < 0.0001:
		direction = Vector2.DOWN
	direction = direction.normalized()
	var lateral := Vector2(-direction.y, direction.x)
	var pairs := _get_active_leg_pairs()
	for pair in pairs:
		var path: NodePath = pair["path"]
		var sign: float = pair["sign"]
		var node := _get_node2d(path)
		if node == null:
			continue
		var baseline: Dictionary = _baseline_transforms.get(String(path), {})
		if baseline.is_empty():
			continue
		var forward_amount := phase * sign
		var offset := direction * forward_amount * stride_distance
		offset += lateral * sway_phase * sign * lateral_sway
		var swing_angle: float = deg_to_rad(leg_swing_degrees) * forward_amount
		_apply_leg_transform(node, baseline, offset, swing_angle)
		_apply_lower_extremity_lift(path, node, direction, forward_amount)
	_apply_secondary_motion(cycle)
	if body_bob_distance > 0.0:
		_apply_body_bob(cycle)


func _reset_pose_to_baseline() -> void:
	for path_string in _baseline_transforms.keys():
		var node := _get_node2d(NodePath(path_string))
		if node == null:
			continue
		var baseline: Dictionary = _baseline_transforms[path_string]
		node.transform = baseline["transform"]
	for path_string in _motion_target_baselines.keys():
		_reset_motion_target(path_string)
	for key in _lower_extremity_baselines.keys():
		var baseline: Dictionary = _lower_extremity_baselines[key]
		var node := _get_node2d(baseline["instance_path"])
		if node == null:
			continue
		node.transform = baseline["transform"]
	for path_string in _view_root_baselines.keys():
		var root := _get_node2d(NodePath(path_string))
		if root == null:
			continue
		var baseline: Dictionary = _view_root_baselines[path_string]
		root.position = baseline["position"]
		root.rotation = baseline["rotation"]
		root.scale = baseline["scale"]


func _apply_body_bob(cycle: float) -> void:
	var bob: float = -abs(sin(cycle * 2.0)) * body_bob_distance
	for path in _get_active_view_paths():
		var root := _get_node2d(path)
		if root == null:
			continue
		var baseline: Dictionary = _view_root_baselines.get(String(path), {})
		if baseline.is_empty():
			continue
		root.position = baseline["position"] + Vector2(0.0, bob)


func _get_active_leg_pairs() -> Array[Dictionary]:
	var pairs: Array[Dictionary] = []
	if view_mode == VIEW_FRONT or view_mode == VIEW_ALL:
		pairs.append({"path": front_left_leg_path, "sign": 1.0})
		pairs.append({"path": front_right_leg_path, "sign": -1.0})
	if view_mode == VIEW_SIDE or view_mode == VIEW_ALL:
		pairs.append({"path": side_back_leg_path, "sign": 1.0})
		pairs.append({"path": side_front_leg_path, "sign": -1.0})
	if view_mode == VIEW_REAR or view_mode == VIEW_ALL:
		pairs.append({"path": rear_left_leg_path, "sign": 1.0})
		pairs.append({"path": rear_right_leg_path, "sign": -1.0})
	return pairs


func _get_active_view_paths() -> Array[NodePath]:
	var paths: Array[NodePath] = []
	if view_mode == VIEW_FRONT or view_mode == VIEW_ALL:
		paths.append(front_view_path)
	if view_mode == VIEW_SIDE or view_mode == VIEW_ALL:
		paths.append(side_view_path)
	if view_mode == VIEW_REAR or view_mode == VIEW_ALL:
		paths.append(rear_view_path)
	return paths


func _get_all_leg_paths() -> Array[NodePath]:
	return [
		front_left_leg_path,
		front_right_leg_path,
		side_back_leg_path,
		side_front_leg_path,
		rear_left_leg_path,
		rear_right_leg_path,
	]


func _apply_secondary_motion(cycle: float) -> void:
	if hip_tilt_degrees > 0.0:
		var hip_amount := sin(cycle + hip_tilt_phase_offset * TAU)
		if invert_hip_tilt:
			hip_amount *= -1.0
		_apply_rotation_to_path_list(hip_target_paths, deg_to_rad(hip_tilt_degrees) * hip_amount)
	var bounce_cycle: float = cycle * bounce_speed_multiplier
	_apply_bounce_to_path_list(body_target_paths, body_bounce_distance, body_bounce_phase_offset, bounce_cycle)
	_apply_bounce_to_path_list(head_target_paths, head_bounce_distance, head_bounce_phase_offset, bounce_cycle)
	_apply_bounce_to_path_list(hair_target_paths, hair_bounce_distance, hair_bounce_phase_offset, bounce_cycle)
	_apply_bounce_to_path_list(gun_target_paths, gun_bounce_distance, gun_bounce_phase_offset, bounce_cycle)


func _apply_rotation_to_path_list(path_list: String, angle: float) -> void:
	if is_zero_approx(angle):
		return
	for path in _parse_node_path_list(path_list):
		_apply_motion_target_transform(path, Vector2.ZERO, angle)


func _apply_bounce_to_path_list(path_list: String, distance: float, phase_offset: float, cycle: float) -> void:
	if distance <= 0.0:
		return
	var bounce_amount: float = abs(sin(cycle + phase_offset * TAU)) * distance
	if bounce_amount <= 0.0001:
		return
	for path in _parse_node_path_list(path_list):
		_apply_motion_target_transform(path, Vector2(0.0, -bounce_amount), 0.0)


func _apply_leg_transform(node: Node2D, baseline: Dictionary, offset: Vector2, swing_angle: float) -> void:
	var baseline_transform: Transform2D = baseline["transform"]
	var pivot_local: Vector2 = baseline.get("pivot_local", Vector2.ZERO)
	var pivot_parent: Vector2 = baseline_transform * pivot_local
	var rotation_transform := Transform2D(swing_angle, Vector2.ZERO)
	var rotation_origin: Vector2 = offset + pivot_parent - rotation_transform * pivot_parent
	node.transform = Transform2D(swing_angle, rotation_origin) * baseline_transform


func _capture_motion_target_baseline(path: NodePath) -> void:
	var target := _get_canvas_item(path)
	if target == null:
		return
	var key := String(path)
	if _motion_target_baselines.has(key):
		return
	if target is Node2D:
		var node := target as Node2D
		_motion_target_baselines[key] = {
			"kind": "node2d",
			"transform": node.transform,
			"pivot_local": _calculate_node_local_bounds(node).get_center(),
		}
	elif target is Control:
		var control := target as Control
		_motion_target_baselines[key] = {
			"kind": "control",
			"position": control.position,
			"rotation": control.rotation,
			"scale": control.scale,
		}


func _apply_motion_target_transform(path: NodePath, offset: Vector2, angle: float) -> void:
	var key := String(path)
	var baseline: Dictionary = _motion_target_baselines.get(key, {})
	if baseline.is_empty():
		return
	var target := _get_canvas_item(path)
	if target == null:
		return
	if baseline.get("kind", "") == "node2d" and target is Node2D:
		var node := target as Node2D
		var node_baseline := {
			"transform": baseline["transform"],
			"pivot_local": baseline.get("pivot_local", Vector2.ZERO),
		}
		_apply_leg_transform(node, node_baseline, offset, angle)
	elif baseline.get("kind", "") == "control" and target is Control:
		var control := target as Control
		control.position = baseline["position"] + offset
		control.rotation = baseline["rotation"] + angle
		control.scale = baseline["scale"]


func _reset_motion_target(path_string: String) -> void:
	var baseline: Dictionary = _motion_target_baselines.get(path_string, {})
	if baseline.is_empty():
		return
	var target := _get_canvas_item(NodePath(path_string))
	if target == null:
		return
	if baseline.get("kind", "") == "node2d" and target is Node2D:
		(target as Node2D).transform = baseline["transform"]
	elif baseline.get("kind", "") == "control" and target is Control:
		var control := target as Control
		control.position = baseline["position"]
		control.rotation = baseline["rotation"]
		control.scale = baseline["scale"]


func _capture_lower_extremity_baseline(leg_path: NodePath, leg_node: Node2D, child_name: String, role: String) -> void:
	var child := leg_node.find_child(child_name, true, false) as Node2D
	if child == null:
		return
	var instance_path := _character_instance.get_path_to(child)
	_lower_extremity_baselines[_lower_extremity_key(leg_path, role)] = {
		"instance_path": instance_path,
		"transform": child.transform,
		"role": role,
	}


func _apply_lower_extremity_lift(leg_path: NodePath, leg_node: Node2D, stride_amount: Vector2, forward_amount: float) -> void:
	var lift_phase: float = max(0.0, -forward_amount)
	if lift_phase <= 0.0:
		return
	_apply_lower_extremity_role_lift(leg_path, leg_node, "knee", knee_lift_distance, stride_amount, lift_phase)
	_apply_lower_extremity_role_lift(leg_path, leg_node, "foot", foot_lift_distance, stride_amount, lift_phase)


func _apply_lower_extremity_role_lift(leg_path: NodePath, leg_node: Node2D, role: String, lift_distance: float, stride_amount: Vector2, lift_phase: float) -> void:
	if lift_distance <= 0.0:
		return
	var baseline: Dictionary = _lower_extremity_baselines.get(_lower_extremity_key(leg_path, role), {})
	if baseline.is_empty():
		return
	var node := _get_node2d(baseline["instance_path"])
	if node == null:
		return
	var local_stride := _character_direction_to_node_local(leg_node, stride_amount)
	node.transform = baseline["transform"]
	node.position += -local_stride * lift_distance * lift_phase


func _character_direction_to_node_local(node: Node2D, direction: Vector2) -> Vector2:
	if direction.length_squared() < 0.0001:
		return Vector2.ZERO
	var global_direction := _character_instance.global_transform.basis_xform(direction.normalized())
	var local_direction := node.global_transform.basis_xform_inv(global_direction)
	if local_direction.length_squared() < 0.0001:
		return Vector2.ZERO
	return local_direction.normalized()


func _lower_extremity_key(leg_path: NodePath, role: String) -> String:
	return "%s|%s" % [String(leg_path), role]


func _get_all_motion_target_paths() -> Array[NodePath]:
	var paths: Array[NodePath] = []
	for path_list in [hip_target_paths, body_target_paths, head_target_paths, hair_target_paths, gun_target_paths]:
		paths.append_array(_parse_node_path_list(path_list))
	return paths


func _parse_node_path_list(path_list: String) -> Array[NodePath]:
	var paths: Array[NodePath] = []
	for raw_path in path_list.split(",", false):
		var trimmed_path := String(raw_path).strip_edges()
		if not trimmed_path.is_empty():
			paths.append(NodePath(trimmed_path))
	return paths


func _calculate_node_local_bounds(root: Node2D) -> Rect2:
	var root_inverse := root.get_global_transform().affine_inverse()
	return _calculate_canvas_item_bounds(root, root_inverse)


func _calculate_visible_bounds() -> Rect2:
	if not is_instance_valid(_character_instance):
		return Rect2()
	var has_bounds := false
	var bounds := Rect2()
	var instance_inverse := _character_instance.get_global_transform().affine_inverse()
	for child in _character_instance.get_children():
		if child is CanvasItem and not child.visible:
			continue
		var child_bounds := _calculate_canvas_item_bounds(child, instance_inverse)
		if child_bounds.size == Vector2.ZERO:
			continue
		if not has_bounds:
			bounds = child_bounds
			has_bounds = true
		else:
			bounds = bounds.merge(child_bounds)
	return bounds if has_bounds else Rect2()


func _calculate_canvas_item_bounds(node: Node, instance_inverse: Transform2D) -> Rect2:
	var has_bounds := false
	var bounds := Rect2()
	if node is Polygon2D:
		var polygon_node := node as Polygon2D
		var transform: Transform2D = instance_inverse * polygon_node.get_global_transform()
		for point in polygon_node.polygon:
			var transformed_point: Vector2 = transform * point
			if not has_bounds:
				bounds = Rect2(transformed_point, Vector2.ZERO)
				has_bounds = true
			else:
				bounds = bounds.expand(transformed_point)
	elif node is Control:
		var control := node as Control
		var rect := control.get_rect()
		var transform: Transform2D = instance_inverse * control.get_global_transform()
		for point in [
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y),
		]:
			var transformed_point: Vector2 = transform * point
			if not has_bounds:
				bounds = Rect2(transformed_point, Vector2.ZERO)
				has_bounds = true
			else:
				bounds = bounds.expand(transformed_point)
	for child in node.get_children():
		if child is CanvasItem and not child.visible:
			continue
		var child_bounds := _calculate_canvas_item_bounds(child, instance_inverse)
		if child_bounds.size == Vector2.ZERO:
			continue
		if not has_bounds:
			bounds = child_bounds
			has_bounds = true
		else:
			bounds = bounds.merge(child_bounds)
	return bounds if has_bounds else Rect2()


func _get_node2d(path: NodePath) -> Node2D:
	if not is_instance_valid(_character_instance) or path.is_empty():
		return null
	var node := _character_instance.get_node_or_null(path)
	return node as Node2D


func _get_canvas_item(path: NodePath) -> CanvasItem:
	if not is_instance_valid(_character_instance) or path.is_empty():
		return null
	var node := _character_instance.get_node_or_null(path)
	return node as CanvasItem
