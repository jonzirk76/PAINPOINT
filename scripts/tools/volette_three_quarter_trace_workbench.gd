@tool
extends Node2D

const THREE_QUARTER_MOTION: Resource = preload("res://resources/presentation/humanoid_three_quarter_motion_profile.tres")

const MOTION_PATHS := [
	"BodyMotion",
	"BodyMotion/TorsoPivot",
	"BodyMotion/TorsoPivot/HipsAnchor/HipsPivot",
	"BodyMotion/TorsoPivot/HeadAnchor/HeadPivot",
	"BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/FarHipSocket_Left/FarLegPivot_Left",
	"BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/NearHipSocket_Right/NearLegPivot_Right",
	"BodyMotion/TorsoPivot/FarShoulderAnchor_Left/FarArmPivot_Left",
	"BodyMotion/TorsoPivot/NearShoulderAnchor_Right/NearArmPivot_Right",
]

## Shows the bald concept cell used to align the body assembly.
@export var show_structure_reference: bool = true:
	set(value):
		show_structure_reference = value
		_refresh_workbench()

## Opacity of the concept image beneath the editable polygons.
@export_range(0.0, 1.0, 0.01) var structure_reference_opacity := 0.52:
	set(value):
		structure_reference_opacity = value
		_refresh_workbench()

## Shows the matching haired concept cell beside the editing area.
@export var show_hair_comparison: bool = true:
	set(value):
		show_hair_comparison = value
		_refresh_workbench()

## Shows or hides the entire editable polygon assembly without affecting the reference.
@export var show_editable_assembly: bool = true:
	set(value):
		show_editable_assembly = value
		_refresh_workbench()

@export_group("Motion Preview")

## Plays a non-destructive stiff gait on the selected editable assembly.
@export var animate_motion_preview: bool = true:
	set(value):
		if value and not animate_motion_preview:
			_capture_motion_rest_pose()
		animate_motion_preview = value
		if not animate_motion_preview:
			_restore_motion_rest_pose()
		_update_processing()

## Chooses which independently authored diagonal assembly receives the motion preview.
@export_enum("Down Right", "Up Right") var motion_preview_direction: int = 0:
	set(value):
		_restore_motion_rest_pose()
		motion_preview_direction = value
		_capture_motion_rest_pose()

## Multiplies the cycle speed without changing the canonical motion profile.
@export_range(0.1, 2.0, 0.05) var motion_speed_scale := 1.0

var _motion_phase := 0.0
var _motion_rest_transforms: Dictionary = {}


func _ready() -> void:
	_refresh_workbench()
	_capture_motion_rest_pose()
	_update_processing()


func _notification(what: int) -> void:
	if not Engine.is_editor_hint() or _motion_rest_transforms.is_empty():
		return
	if what == NOTIFICATION_EDITOR_PRE_SAVE or what == NOTIFICATION_EXIT_TREE:
		_restore_motion_rest_pose()
	elif what == NOTIFICATION_EDITOR_POST_SAVE and animate_motion_preview:
		_apply_motion_preview()


func _process(delta: float) -> void:
	if not Engine.is_editor_hint() or not animate_motion_preview:
		return
	_motion_phase = fposmod(
		_motion_phase + delta * THREE_QUARTER_MOTION.cycle_speed * motion_speed_scale,
		1.0
	)
	_apply_motion_preview()


func _refresh_workbench() -> void:
	for path in ["References/ForwardStructureReference", "References/RearStructureReference"]:
		var structure_reference := get_node_or_null(path) as CanvasItem
		if structure_reference != null:
			structure_reference.visible = show_structure_reference
			structure_reference.modulate = Color(1.0, 1.0, 1.0, structure_reference_opacity)
	for path in ["References/ForwardHairComparison", "References/RearHairComparison"]:
		var hair_comparison := get_node_or_null(path) as CanvasItem
		if hair_comparison != null:
			hair_comparison.visible = show_hair_comparison
	for path in ["ThreeQuarterDownRight", "ThreeQuarterUpRight"]:
		var assembly := get_node_or_null(path) as CanvasItem
		if assembly != null:
			assembly.visible = show_editable_assembly


func _update_processing() -> void:
	set_process(Engine.is_editor_hint() and animate_motion_preview)


func _selected_assembly() -> Node2D:
	var path := "ThreeQuarterDownRight" if motion_preview_direction == 0 else "ThreeQuarterUpRight"
	return get_node_or_null(path) as Node2D


func _capture_motion_rest_pose() -> void:
	_motion_rest_transforms.clear()
	var assembly := _selected_assembly()
	if assembly == null:
		return
	for relative_path in MOTION_PATHS:
		var part := assembly.get_node_or_null(relative_path) as Node2D
		if part != null:
			_motion_rest_transforms[relative_path] = part.transform


func _restore_motion_rest_pose() -> void:
	var assembly := _selected_assembly()
	if assembly == null:
		return
	for relative_path: String in _motion_rest_transforms:
		var part := assembly.get_node_or_null(relative_path) as Node2D
		if part != null:
			part.transform = _motion_rest_transforms[relative_path]


func _apply_motion_preview() -> void:
	_restore_motion_rest_pose()
	var assembly := _selected_assembly()
	if assembly == null:
		return
	var wave := sin(_motion_phase * TAU)
	var lift := absf(sin(_motion_phase * TAU * 0.65))
	var body_motion := assembly.get_node_or_null("BodyMotion") as Node2D
	var far_leg := assembly.get_node_or_null(
		"BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/FarHipSocket_Left/FarLegPivot_Left"
	) as Node2D
	var near_leg := assembly.get_node_or_null(
		"BodyMotion/TorsoPivot/HipsAnchor/HipsPivot/NearHipSocket_Right/NearLegPivot_Right"
	) as Node2D
	var far_arm := assembly.get_node_or_null(
		"BodyMotion/TorsoPivot/FarShoulderAnchor_Left/FarArmPivot_Left"
	) as Node2D
	var near_arm := assembly.get_node_or_null(
		"BodyMotion/TorsoPivot/NearShoulderAnchor_Right/NearArmPivot_Right"
	) as Node2D
	if body_motion != null:
		body_motion.position.y -= lift * THREE_QUARTER_MOTION.body_bob_distance
	if far_leg != null:
		far_leg.scale.y *= 1.0 + THREE_QUARTER_MOTION.leg_depth_swing_ratio * wave
		far_leg.rotation += deg_to_rad(THREE_QUARTER_MOTION.leg_swing_degrees) * wave
	if near_leg != null:
		near_leg.scale.y *= 1.0 - THREE_QUARTER_MOTION.leg_depth_swing_ratio * wave
		near_leg.rotation -= deg_to_rad(THREE_QUARTER_MOTION.leg_swing_degrees) * wave
	if far_arm != null:
		far_arm.scale.y *= 1.0 - THREE_QUARTER_MOTION.arm_depth_swing_ratio * wave
		far_arm.rotation -= deg_to_rad(THREE_QUARTER_MOTION.arm_swing_degrees) * wave
	if near_arm != null:
		near_arm.scale.y *= 1.0 + THREE_QUARTER_MOTION.arm_depth_swing_ratio * wave
		near_arm.rotation += deg_to_rad(THREE_QUARTER_MOTION.arm_swing_degrees) * wave
