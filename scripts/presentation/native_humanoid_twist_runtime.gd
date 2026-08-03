class_name NativeHumanoidTwistRuntime
extends Node2D

signal pose_changed(hips_direction: int, torso_direction: int, head_direction: int, arms_direction: int)

enum Direction {
	SOUTH,
	SOUTH_WEST,
	WEST,
	NORTH_WEST,
	NORTH,
	NORTH_EAST,
	EAST,
	SOUTH_EAST,
}

const HIPS_PATH := ^"Hips"
const HEAD_PATH := ^"Hips/Torso/Head"
const FAR_ARM_PATH := ^"Hips/Torso/FarArm"
const NEAR_ARM_PATH := ^"Hips/Torso/NearArm"

## [Description] Compresses the body vertically while preserving independently directed native subassemblies.
@export_range(0.4, 1.0, 0.01) var foreshortening: float = 0.65
## [Description] Keeps the head silhouette at authored proportions after body foreshortening.
@export var preserve_head_shape: bool = true
## [Description] Blends head height from the torso socket toward the selected head view's authored elevation.
@export_range(0.0, 1.0, 0.05) var head_authored_elevation_weight: float = 1.0
## [Description] Extra screen-space advantage required before continuous aim switches to the opposite shoulder.
@export_range(0.0, 40.0, 1.0) var active_arm_switch_margin: float = 8.0

@onready var hips_runtime: NativeHumanoidSkeletonRuntime = $HipsRuntime
@onready var torso_runtime: NativeHumanoidSkeletonRuntime = $TorsoRuntime
@onready var head_runtime: NativeHumanoidSkeletonRuntime = $HeadRuntime
@onready var arms_runtime: NativeHumanoidSkeletonRuntime = $ArmsRuntime
@onready var active_arm_projection: Node2D = $ActiveArmProjection
@onready var active_arm_socket: Node2D = $ActiveArmProjection/ActiveArmSocket

var active_arm: Node2D
var _hips_direction: int = Direction.SOUTH
var _torso_direction: int = Direction.SOUTH
var _head_direction: int = Direction.SOUTH
var _arms_direction: int = Direction.SOUTH
var _walking: bool = false
var _aim_active: bool = false
var _aim_vector: Vector2 = Vector2.ZERO
var _active_arm_path: NodePath = NEAR_ARM_PATH
var _twist_sign: int = 1


func _ready() -> void:
	_setup_active_arm()
	_apply_foreshortening()
	_apply_runtime_states()
	_align_subassemblies()
	_apply_active_arm_state()


func _process(_delta: float) -> void:
	# The hips own locomotion bob. The other persistent assemblies retain their
	# independently mirrored view while following the authored body sockets.
	_align_subassemblies()
	_apply_active_arm_state()


func set_pose(
	hips_direction: int,
	desired_direction: int,
	walking: bool,
	aim_vector: Vector2 = Vector2.ZERO
) -> void:
	var hips := wrapi(hips_direction, 0, 8)
	var desired := wrapi(desired_direction, 0, 8)
	var initial_delta := _signed_direction_delta(hips, desired)
	if initial_delta != 0 and abs(initial_delta) < 4:
		_twist_sign = 1 if initial_delta > 0 else -1
	var torso := _step_toward(hips, desired, 1)
	var head := _step_toward(torso, desired, 2)
	# The inactive arm pair is part of the torso subassembly. The future active
	# pointing arm owns the remaining shoulder-to-aim rotation independently.
	var arms := torso
	var next_aim_active := aim_vector.length_squared() > 0.01
	var next_aim_vector := aim_vector.normalized() if next_aim_active else Vector2.ZERO
	var changed := (
		_hips_direction != hips
		or _torso_direction != torso
		or _head_direction != head
		or _arms_direction != arms
		or _walking != walking
		or _aim_active != next_aim_active
	)
	_hips_direction = hips
	_torso_direction = torso
	_head_direction = head
	_arms_direction = arms
	_walking = walking
	_aim_active = next_aim_active
	_aim_vector = next_aim_vector
	if changed:
		_apply_runtime_states()
		_align_subassemblies()
	_apply_active_arm_state()
	pose_changed.emit(hips, torso, head, arms)


func get_pose_directions() -> PackedInt32Array:
	return PackedInt32Array([
		_hips_direction,
		_torso_direction,
		_head_direction,
		_arms_direction,
	])


func set_foreshortening(value: float) -> void:
	foreshortening = clampf(value, 0.4, 1.0)
	if is_node_ready():
		_apply_foreshortening()
		_align_subassemblies()


func get_foreshortening() -> float:
	return foreshortening


func _apply_runtime_states() -> void:
	hips_runtime.set_motion_state(_hips_direction, _walking)
	torso_runtime.set_motion_state(_torso_direction, false)
	head_runtime.set_motion_state(_head_direction, false)
	arms_runtime.set_motion_state(_arms_direction, _walking and not _aim_active)


func _apply_foreshortening() -> void:
	for runtime in [hips_runtime, torso_runtime, head_runtime, arms_runtime]:
		runtime.preserve_head_shape = preserve_head_shape
		runtime.set_foreshortening(foreshortening)
	active_arm_projection.scale = Vector2(1.0, foreshortening)


func _align_subassemblies() -> void:
	if not (
		hips_runtime.is_compiled()
		and torso_runtime.is_compiled()
		and head_runtime.is_compiled()
		and arms_runtime.is_compiled()
	):
		return
	_align_runtime_anchor(torso_runtime, HIPS_PATH, hips_runtime.get_bone_global_position(HIPS_PATH))
	_align_head_runtime()
	_align_runtime_anchor(
		arms_runtime,
		FAR_ARM_PATH,
		torso_runtime.get_bone_global_position(FAR_ARM_PATH)
	)
	arms_runtime.set_bone_global_position(
		NEAR_ARM_PATH,
		torso_runtime.get_bone_global_position(NEAR_ARM_PATH)
	)


func _align_runtime_anchor(
	runtime: NativeHumanoidSkeletonRuntime,
	bone_path: NodePath,
	target: Vector2
) -> void:
	runtime.global_position += target - runtime.get_bone_global_position(bone_path)


func _align_head_runtime() -> void:
	# Head bones in the canonical views currently encode both the neck socket
	# and direction-specific head elevation. Normalize through the hips first so
	# a profile head keeps its authored height, then let the torso own horizontal
	# attachment. The exported blend permits later art-driven seam tuning.
	_align_runtime_anchor(
		head_runtime,
		HIPS_PATH,
		torso_runtime.get_bone_global_position(HIPS_PATH)
	)
	var authored_anchor := head_runtime.get_bone_global_position(HEAD_PATH)
	var torso_anchor := torso_runtime.get_bone_global_position(HEAD_PATH)
	var target_anchor := Vector2(
		torso_anchor.x,
		lerpf(torso_anchor.y, authored_anchor.y, head_authored_elevation_weight)
	)
	head_runtime.global_position += target_anchor - authored_anchor


func _setup_active_arm() -> void:
	for child in active_arm_socket.get_children():
		child.queue_free()
	var skin_source := arms_runtime.character_skin_source
	if skin_source == null or skin_source.active_arm_scene == null:
		push_error("Native humanoid twist runtime requires an active arm scene from its skin source.")
		return
	active_arm = skin_source.active_arm_scene.instantiate() as Node2D
	if active_arm == null:
		push_error("Native humanoid twist runtime could not instantiate the active arm scene.")
		return
	active_arm.name = "ActiveArm"
	active_arm.visible = false
	active_arm_socket.add_child(active_arm)


func _apply_active_arm_state() -> void:
	arms_runtime.set_bone_branch_visible(FAR_ARM_PATH, true)
	arms_runtime.set_bone_branch_visible(NEAR_ARM_PATH, true)
	if active_arm == null:
		return
	active_arm.visible = _aim_active
	if not _aim_active:
		return
	_active_arm_path = _select_active_arm_path()
	# Read the authored directional slot before hiding its branch so the
	# replacement inherits the same near/far draw order and depth tint.
	var style := arms_runtime.get_bone_visual_style(_active_arm_path)
	arms_runtime.set_bone_branch_visible(_active_arm_path, false)
	active_arm.global_position = torso_runtime.get_bone_global_position(_active_arm_path)
	var local_aim := Vector2(
		_aim_vector.x,
		_aim_vector.y / maxf(foreshortening, 0.001)
	).normalized()
	active_arm.rotation = local_aim.angle() - PI * 0.5
	active_arm.z_index = int(style.get("z_index", 0))
	active_arm.modulate = style.get("modulate", Color.WHITE)


func _select_active_arm_path() -> NodePath:
	var far_position := torso_runtime.get_bone_global_position(FAR_ARM_PATH)
	var near_position := torso_runtime.get_bone_global_position(NEAR_ARM_PATH)
	var center := (far_position + near_position) * 0.5
	var far_score := (far_position - center).dot(_aim_vector)
	var near_score := (near_position - center).dot(_aim_vector)
	if _active_arm_path == FAR_ARM_PATH and near_score - far_score < active_arm_switch_margin:
		return FAR_ARM_PATH
	if _active_arm_path == NEAR_ARM_PATH and far_score - near_score < active_arm_switch_margin:
		return NEAR_ARM_PATH
	return FAR_ARM_PATH if far_score > near_score else NEAR_ARM_PATH


func _step_toward(source: int, target: int, maximum_steps: int) -> int:
	var delta := _signed_direction_delta(source, target)
	return wrapi(source + clampi(delta, -maximum_steps, maximum_steps), 0, 8)


func _signed_direction_delta(source: int, target: int) -> int:
	var clockwise_steps := wrapi(target - source, 0, 8)
	if clockwise_steps == 4:
		return 4 * _twist_sign
	return clockwise_steps if clockwise_steps < 4 else clockwise_steps - 8
