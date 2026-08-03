class_name NativeHumanoidTwistRuntime
extends Node2D

signal pose_changed(hips_direction: int, torso_direction: int, head_direction: int, arms_direction: int)

const AIM_POSTURE_RESOLVER := preload(
	"res://scripts/presentation/humanoid_aim_posture_resolver.gd"
)

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
## [Description] Keeps the pointing arm active for this long after each shot event.
@export_range(0.05, 2.0, 0.05) var shot_pose_hold_seconds: float = 0.4
## [Description] Delays stationary body rotation so brief movement interruptions do not shift the stance.
@export_range(0.0, 0.5, 0.01) var brace_entry_delay_seconds: float = 0.15
## [Description] Permits nearby shot angles without selecting a different 45-degree braced body view.
@export_range(0.0, 44.0, 0.5) var brace_aim_grace_degrees: float = 30.0
## [Description] Time between consecutive 45-degree body steps while entering a stationary brace.
@export_range(0.01, 0.3, 0.01) var brace_turn_step_seconds: float = 0.1
## [Description] Movement strength below which the current shot may begin taking ownership of the stance.
@export_range(0.0, 1.0, 0.01) var brace_speed_enter_threshold: float = 0.15
## [Description] Movement strength required to leave a retained brace and resume locomotion ownership.
@export_range(0.0, 1.0, 0.01) var movement_speed_resume_threshold: float = 0.25
## [Description] Angular tolerance used when shot depth does not clearly select the near or far shoulder.
@export_range(0.0, 30.0, 0.5) var active_arm_switch_grace_degrees: float = 12.0

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
var _posture_phase: int = 0
var _posture_resolver = AIM_POSTURE_RESOLVER.new()


func _ready() -> void:
	_configure_posture_resolver()
	_posture_resolver.reset(_hips_direction)
	_setup_active_arm()
	_apply_foreshortening()
	_apply_resolved_posture(true)
	_align_subassemblies()
	_apply_active_arm_state()


func _process(delta: float) -> void:
	_posture_resolver.advance(delta)
	_apply_resolved_posture()
	# The hips own locomotion bob. The other persistent assemblies retain their
	# independently mirrored view while following the authored body sockets.
	_align_subassemblies()
	_apply_active_arm_state()


func set_locomotion(direction: int, movement_strength: float) -> void:
	_posture_resolver.set_locomotion(direction, movement_strength)
	_apply_resolved_posture()


func register_shot(shot_vector: Vector2) -> void:
	_posture_resolver.register_shot(shot_vector)
	_apply_resolved_posture()
	_apply_active_arm_state()


func clear_active_aim() -> void:
	_posture_resolver.clear_active_aim()
	_apply_resolved_posture()
	_apply_active_arm_state()


func set_aim_held(is_held: bool) -> void:
	_posture_resolver.set_aim_held(is_held)
	_apply_resolved_posture()
	_apply_active_arm_state()


func is_aim_active() -> bool:
	return _posture_resolver.is_aim_active()


func get_posture_phase_name() -> String:
	return _posture_resolver.get_phase_name()


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


func _configure_posture_resolver() -> void:
	_posture_resolver.shot_pose_hold_seconds = shot_pose_hold_seconds
	_posture_resolver.brace_entry_delay_seconds = brace_entry_delay_seconds
	_posture_resolver.brace_aim_grace_degrees = brace_aim_grace_degrees
	_posture_resolver.brace_turn_step_seconds = brace_turn_step_seconds
	_posture_resolver.brace_speed_enter_threshold = brace_speed_enter_threshold
	_posture_resolver.movement_speed_resume_threshold = maxf(
		movement_speed_resume_threshold,
		brace_speed_enter_threshold
	)


func _apply_resolved_posture(force: bool = false) -> void:
	var pose: Dictionary = _posture_resolver.get_pose()
	var next_hips := int(pose.get("hips_direction", _hips_direction))
	var next_torso := int(pose.get("torso_direction", _torso_direction))
	var next_head := int(pose.get("head_direction", _head_direction))
	var next_arms := int(pose.get("arms_direction", _arms_direction))
	var next_walking := bool(pose.get("walking", _walking))
	var next_aim_active := bool(pose.get("aim_active", _aim_active))
	var next_aim_vector := pose.get("aim_vector", _aim_vector) as Vector2
	var next_phase := int(pose.get("phase", _posture_phase))
	var runtime_changed := (
		force
		or _hips_direction != next_hips
		or _torso_direction != next_torso
		or _head_direction != next_head
		or _arms_direction != next_arms
		or _walking != next_walking
		or _aim_active != next_aim_active
	)
	var posture_changed := (
		runtime_changed
		or not _aim_vector.is_equal_approx(next_aim_vector)
		or _posture_phase != next_phase
	)
	_hips_direction = next_hips
	_torso_direction = next_torso
	_head_direction = next_head
	_arms_direction = next_arms
	_walking = next_walking
	_aim_active = next_aim_active
	_aim_vector = next_aim_vector
	_posture_phase = next_phase
	if runtime_changed:
		_apply_runtime_states()
		_align_subassemblies()
	if posture_changed:
		pose_changed.emit(
			_hips_direction,
			_torso_direction,
			_head_direction,
			_arms_direction
		)


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
	var shoulder_separation := near_position - far_position
	if shoulder_separation.length_squared() <= 0.0001:
		return _active_arm_path
	# The canonical torso pose owns the shoulder sockets. Projecting their
	# authored separation onto the shot vector identifies which socket is
	# geometrically closer to the shot without a direction-specific rule table.
	# The torso runtime does not play gait, so locomotion cannot disturb this
	# reference geometry.
	var shoulder_alignment := shoulder_separation.normalized().dot(_aim_vector)
	var switch_alignment := sin(deg_to_rad(active_arm_switch_grace_degrees))
	if shoulder_alignment > switch_alignment:
		return NEAR_ARM_PATH
	if shoulder_alignment < -switch_alignment:
		return FAR_ARM_PATH
	# Retain the selected shoulder inside the ambiguous band. The wider switch
	# threshold and zero-width retain threshold form hysteresis around the
	# shoulder-axis boundary and prevent small aim changes from swapping arms.
	if _active_arm_path == FAR_ARM_PATH or _active_arm_path == NEAR_ARM_PATH:
		return _active_arm_path
	return NEAR_ARM_PATH
