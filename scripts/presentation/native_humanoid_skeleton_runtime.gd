class_name NativeHumanoidSkeletonRuntime
extends Node2D

signal direction_changed(direction: int)

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

enum BodyPart {
	HIPS = 1,
	TORSO = 2,
	HEAD = 4,
	ARMS = 8,
	LEGS = 16,
}

const RUNTIME_DIRECTIONS := [
	Direction.SOUTH,
	Direction.SOUTH_WEST,
	Direction.WEST,
	Direction.NORTH_WEST,
	Direction.NORTH,
	Direction.NORTH_EAST,
	Direction.EAST,
	Direction.SOUTH_EAST,
]
const CANONICAL_DIRECTIONS := [
	Direction.SOUTH,
	Direction.SOUTH_WEST,
	Direction.WEST,
	Direction.NORTH,
	Direction.NORTH_EAST,
]
const DIRECTION_NAMES := {
	Direction.SOUTH: &"south",
	Direction.SOUTH_WEST: &"south_west",
	Direction.WEST: &"west",
	Direction.NORTH_WEST: &"north_west",
	Direction.NORTH: &"north",
	Direction.NORTH_EAST: &"north_east",
	Direction.EAST: &"east",
	Direction.SOUTH_EAST: &"south_east",
}
const SEMANTIC_BONE_PATHS := [
	^"Hips",
	^"Hips/Torso",
	^"Hips/Torso/Head",
	^"Hips/Torso/FarArm",
	^"Hips/Torso/NearArm",
	^"Hips/FarLeg",
	^"Hips/NearLeg",
]
const ANIMATED_LIMB_BONE_PATHS := [
	^"Hips/Torso/FarArm",
	^"Hips/Torso/NearArm",
	^"Hips/FarLeg",
	^"Hips/NearLeg",
]

## [Description] Canonical scenes supplying the invariant bone rests and editable locomotion clips.
@export var animation_rig_source: HumanoidAnimationRigSource
## [Description] Canonical scenes supplying character-specific Polygon2D artwork for each semantic body slot.
@export var character_skin_source: PolygonCharacterSkinSource
## [Description] Initial authored direction compiled into the persistent skeleton.
@export_enum("South:0", "South West:1", "West:2", "North West:3", "North:4", "North East:5", "East:6", "South East:7") var initial_direction: int = Direction.SOUTH
## [Description] Starts the native locomotion state after the three-view source has been compiled.
@export var starts_walking: bool = true
## [Description] Compresses the body vertically after authored transforms are resolved.
@export_range(0.4, 1.0, 0.01) var foreshortening: float = 0.65
## [Description] Counter-scales the head so body foreshortening does not squash its authored silhouette.
@export var preserve_head_shape: bool = true
## [Description] Cross-fade duration between compatible clips; directional cutout views default to a discrete zero-duration swap.
@export_range(0.0, 0.25, 0.01) var direction_crossfade: float = 0.0
## [Description] Semantic polygon groups compiled into this persistent runtime instance.
@export_flags("Hips", "Torso", "Head", "Arms", "Legs") var body_parts: int = 31

@onready var projection_root: Node2D = $ProjectionRoot
@onready var motion_offset: Node2D = $ProjectionRoot/MotionOffset
@onready var skeleton: Skeleton2D = $ProjectionRoot/MotionOffset/Skeleton2D
@onready var animation_player: AnimationPlayer = $ProjectionRoot/AnimationPlayer
@onready var animation_tree: AnimationTree = $ProjectionRoot/AnimationTree

var _direction_poses: Dictionary = {}
var _direction_slots: Dictionary = {}
var _state_names: Dictionary = {}
var _playback: AnimationNodeStateMachinePlayback
var _current_direction: int = Direction.SOUTH
var _walking: bool = false
var _compiled_polygon_count: int = 0
var _compiled: bool = false
var _motion_state_applied: bool = false


func _enter_tree() -> void:
	# Bone2D only exposes autocalculation through setter methods in Godot 4.7,
	# so it cannot be reliably serialized as a scene property. Disable it on
	# the socket-style terminal bones before they enter the SceneTree.
	var runtime_skeleton := get_node_or_null(^"ProjectionRoot/MotionOffset/Skeleton2D") as Skeleton2D
	if runtime_skeleton == null:
		return
	for candidate in runtime_skeleton.find_children("*", "Bone2D", true, false):
		(candidate as Bone2D).set_autocalculate_length_and_angle(false)


func _ready() -> void:
	if not _sources_are_valid():
		push_error("Native humanoid skeleton requires valid rig and skin sources.")
		return
	_create_animation_library()
	for direction in CANONICAL_DIRECTIONS:
		_compile_direction(direction)
	_build_animation_tree()
	_compiled = _direction_poses.size() == CANONICAL_DIRECTIONS.size()
	if not _compiled:
		push_error("Native humanoid skeleton could not compile all five canonical directions.")
		return
	set_motion_state(initial_direction, starts_walking)


func set_motion_state(direction: int, walking: bool) -> void:
	if not _compiled:
		return
	if not RUNTIME_DIRECTIONS.has(direction):
		push_warning("Native humanoid skeleton direction must be one of the eight facing octants.")
		return
	var direction_changed_now := direction != _current_direction
	var motion_changed := walking != _walking
	if (
		_motion_state_applied
		and not direction_changed_now
		and not motion_changed
		and _playback != null
	):
		return
	_current_direction = direction
	_walking = walking
	var canonical_direction := _canonical_direction(direction)
	_apply_direction_pose(canonical_direction, _is_mirrored_direction(direction))
	_set_active_skin(canonical_direction)
	_play_state(canonical_direction, walking)
	_motion_state_applied = true
	if direction_changed_now:
		direction_changed.emit(direction)


func set_direction(direction: int) -> void:
	set_motion_state(direction, _walking)


func set_walking(walking: bool) -> void:
	set_motion_state(_current_direction, walking)


func get_direction() -> int:
	return _current_direction


func is_walking() -> bool:
	return _walking


func is_compiled() -> bool:
	return _compiled


func get_compiled_stats() -> Dictionary:
	return {
		"runtime_directions": RUNTIME_DIRECTIONS.size(),
		"canonical_directions": _direction_poses.size(),
		"semantic_bones": SEMANTIC_BONE_PATHS.size(),
		"polygons": _compiled_polygon_count,
		"animation_players": 1,
		"animation_trees": 1,
	}


func get_bone_global_position(bone_path: NodePath) -> Vector2:
	var bone := skeleton.get_node_or_null(bone_path) as Bone2D
	return bone.global_position if bone != null else global_position


func set_bone_global_position(bone_path: NodePath, target: Vector2) -> void:
	var bone := skeleton.get_node_or_null(bone_path) as Bone2D
	if bone != null:
		bone.global_position = target


func set_bone_branch_visible(bone_path: NodePath, is_visible: bool) -> void:
	var bone := skeleton.get_node_or_null(bone_path) as Bone2D
	if bone != null:
		bone.visible = is_visible


func get_bone_visual_style(bone_path: NodePath) -> Dictionary:
	var bone := skeleton.get_node_or_null(bone_path) as Bone2D
	if bone == null:
		return {}
	var branch_z_index := bone.z_index
	for candidate in bone.find_children("*", "Polygon2D", true, false):
		var polygon := candidate as Polygon2D
		if polygon.is_visible_in_tree():
			return {
				# Symmetrical views keep depth on the semantic Bone2D, while
				# diagonal/profile views may encode it on the artwork itself.
				"z_index": polygon.z_index if branch_z_index == 0 else branch_z_index,
				"modulate": polygon.modulate,
			}
	return {
		"z_index": branch_z_index,
		"modulate": bone.modulate,
	}


func _sources_are_valid() -> bool:
	return (
		animation_rig_source != null
		and animation_rig_source.is_valid()
		and character_skin_source != null
		and character_skin_source.is_valid()
	)


func _create_animation_library() -> void:
	for library_name in animation_player.get_animation_library_list():
		animation_player.remove_animation_library(library_name)
	animation_player.add_animation_library(&"", AnimationLibrary.new())


func _compile_direction(direction: int) -> void:
	var rig_selection := animation_rig_source.get_selection(direction)
	var skin_selection := character_skin_source.get_selection(direction)
	var rig_scene := rig_selection.get("scene") as PackedScene
	var skin_scene := skin_selection.get("scene") as PackedScene
	if rig_scene == null or skin_scene == null:
		push_error("Missing canonical source for native direction %s." % _direction_name(direction))
		return
	var rig_view := rig_scene.instantiate() as Node2D
	var skin_view := rig_view if rig_scene == skin_scene else skin_scene.instantiate() as Node2D
	if rig_view == null or skin_view == null:
		push_error("Canonical source for %s is not a Node2D." % _direction_name(direction))
		return
	_prepare_source(rig_view)
	if skin_view != rig_view:
		_prepare_source(skin_view)
	var rig_skeleton := rig_view.get_node_or_null("Skeleton2D") as Skeleton2D
	var skin_skeleton := skin_view.get_node_or_null("Skeleton2D") as Skeleton2D
	if rig_skeleton == null or skin_skeleton == null:
		push_error("Canonical source %s is missing Skeleton2D." % _direction_name(direction))
		if skin_view != rig_view:
			_free_staged_source(skin_view)
		_free_staged_source(rig_view)
		return
	_capture_direction_pose(direction, rig_view, rig_skeleton)
	_capture_direction_animations(direction, rig_view, rig_skeleton.position)
	_capture_direction_skin(direction, skin_view, skin_skeleton)
	if skin_view != rig_view:
		_free_staged_source(skin_view)
	_free_staged_source(rig_view)


func _prepare_source(view: Node2D) -> void:
	view.visible = false
	view.process_mode = Node.PROCESS_MODE_DISABLED
	# Canonical cutout scenes use terminal bones as polygon sockets. They do
	# not need Godot to infer a drawable bone length from a child bone.
	for candidate in view.find_children("*", "Bone2D", true, false):
		(candidate as Bone2D).set_autocalculate_length_and_angle(false)


func _free_staged_source(view: Node2D) -> void:
	if not is_instance_valid(view):
		return
	view.free()


func _capture_direction_pose(direction: int, rig_view: Node2D, rig_skeleton: Skeleton2D) -> void:
	var bone_poses: Dictionary = {}
	for bone_path in SEMANTIC_BONE_PATHS:
		var source_bone := rig_skeleton.get_node_or_null(bone_path) as Bone2D
		if source_bone == null:
			push_error("%s is missing semantic bone %s." % [_direction_name(direction), bone_path])
			continue
		bone_poses[String(bone_path)] = {
			"transform": source_bone.transform,
			"rest": source_bone.rest,
			"z_index": source_bone.z_index,
			"z_as_relative": source_bone.z_as_relative,
		}
	_direction_poses[direction] = {
		"root_position": rig_view.position,
		"skeleton_transform": rig_skeleton.transform,
		"bones": bone_poses,
	}


func _capture_direction_animations(
	direction: int,
	rig_view: Node2D,
	source_skeleton_position: Vector2
) -> void:
	var source_player := rig_view.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if source_player == null:
		push_error("%s is missing its canonical AnimationPlayer." % _direction_name(direction))
		return
	var library := animation_player.get_animation_library(&"")
	for source_name in [&"RESET", &"walk"]:
		var source_animation := source_player.get_animation(source_name)
		if source_animation == null:
			push_error("%s is missing animation %s." % [_direction_name(direction), source_name])
			continue
		var compiled_name := _animation_name(direction, source_name == &"walk")
		var compiled_animation := source_animation.duplicate(true) as Animation
		_normalize_animation_tracks(compiled_animation, source_skeleton_position)
		_ensure_complete_limb_tracks(compiled_animation, direction)
		library.add_animation(compiled_name, compiled_animation)


func _normalize_animation_tracks(animation: Animation, source_skeleton_position: Vector2) -> void:
	for track_index in animation.get_track_count():
		var source_path := String(animation.track_get_path(track_index))
		if source_path == "Skeleton2D:position":
			animation.track_set_path(track_index, ^"MotionOffset:position")
			for key_index in animation.track_get_key_count(track_index):
				var key_value = animation.track_get_key_value(track_index, key_index)
				if key_value is Vector2:
					animation.track_set_key_value(
						track_index,
						key_index,
						(key_value as Vector2) - source_skeleton_position
					)
		elif source_path.begins_with("Skeleton2D/"):
			animation.track_set_path(track_index, NodePath("MotionOffset/" + source_path))


func _ensure_complete_limb_tracks(animation: Animation, direction: int) -> void:
	# AnimationTree blends the union of every property track in its graph. A
	# missing track therefore blends toward the property's zero value, not the
	# currently applied directional pose. For Bone2D scale that zero is clamped
	# to roughly 0.00001, which visually collapses the limb into its socket.
	var direction_pose: Dictionary = _direction_poses.get(direction, {})
	var bone_poses: Dictionary = direction_pose.get("bones", {})
	for bone_path in ANIMATED_LIMB_BONE_PATHS:
		var bone_pose: Dictionary = bone_poses.get(String(bone_path), {})
		if bone_pose.is_empty():
			continue
		var base_transform: Transform2D = bone_pose.get("transform", Transform2D.IDENTITY)
		var runtime_prefix := "MotionOffset/Skeleton2D/%s" % String(bone_path)
		_ensure_value_track(
			animation,
			NodePath(runtime_prefix + ":position"),
			base_transform.origin
		)
		_ensure_value_track(
			animation,
			NodePath(runtime_prefix + ":rotation"),
			base_transform.get_rotation()
		)
		_ensure_value_track(
			animation,
			NodePath(runtime_prefix + ":scale"),
			base_transform.get_scale()
		)


func _ensure_value_track(animation: Animation, property_path: NodePath, base_value: Variant) -> void:
	for track_index in animation.get_track_count():
		if animation.track_get_path(track_index) == property_path:
			return
	var track_index := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, property_path)
	animation.value_track_set_update_mode(track_index, Animation.UPDATE_CONTINUOUS)
	animation.track_insert_key(track_index, 0.0, base_value)


func _capture_direction_skin(direction: int, skin_view: Node2D, skin_skeleton: Skeleton2D) -> void:
	var slots: Array[Node2D] = []
	for bone_path in SEMANTIC_BONE_PATHS:
		if not _includes_bone_skin(bone_path):
			continue
		var runtime_bone := skeleton.get_node_or_null(bone_path) as Bone2D
		if runtime_bone == null:
			continue
		var slot := Node2D.new()
		slot.name = "%sSkin" % _direction_name(direction).to_pascal_case()
		slot.visible = false
		runtime_bone.add_child(slot)
		slots.append(slot)
	_direction_slots[direction] = slots
	for candidate in skin_skeleton.find_children("*", "Polygon2D", true, false):
		var source_polygon := candidate as Polygon2D
		var semantic_source_bone := _find_semantic_source_bone(source_polygon, skin_skeleton)
		if semantic_source_bone == null:
			continue
		var semantic_path := skin_skeleton.get_path_to(semantic_source_bone)
		var runtime_bone := skeleton.get_node_or_null(semantic_path) as Bone2D
		if runtime_bone == null:
			continue
		var slot := runtime_bone.get_node_or_null(
			"%sSkin" % _direction_name(direction).to_pascal_case()
		) as Node2D
		if slot == null:
			continue
		var compiled_polygon := source_polygon.duplicate(0) as Polygon2D
		compiled_polygon.name = "%s_%s" % [
			_direction_name(direction).to_pascal_case(),
			String(source_polygon.name),
		]
		compiled_polygon.transform = _relative_transform_to_ancestor(
			source_polygon,
			semantic_source_bone
		)
		compiled_polygon.set_meta("native_skin_direction", _direction_name(direction))
		compiled_polygon.set_meta("canonical_polygon_path", skin_view.get_path_to(source_polygon))
		slot.add_child(compiled_polygon)
		_compiled_polygon_count += 1


func _includes_bone_skin(bone_path: NodePath) -> bool:
	var required_part := 0
	match String(bone_path):
		"Hips":
			required_part = BodyPart.HIPS
		"Hips/Torso":
			required_part = BodyPart.TORSO
		"Hips/Torso/Head":
			required_part = BodyPart.HEAD
		"Hips/Torso/FarArm", "Hips/Torso/NearArm":
			required_part = BodyPart.ARMS
		"Hips/FarLeg", "Hips/NearLeg":
			required_part = BodyPart.LEGS
	return (body_parts & required_part) != 0


func _find_semantic_source_bone(node: Node, source_skeleton: Skeleton2D) -> Bone2D:
	var cursor := node.get_parent()
	while cursor != null and cursor != source_skeleton:
		if cursor is Bone2D:
			var candidate_path := source_skeleton.get_path_to(cursor)
			if SEMANTIC_BONE_PATHS.has(candidate_path):
				return cursor as Bone2D
		cursor = cursor.get_parent()
	return null


func _relative_transform_to_ancestor(node: Node2D, ancestor: Node2D) -> Transform2D:
	var relative := node.transform
	var cursor := node.get_parent()
	while cursor != null and cursor != ancestor:
		if cursor is Node2D:
			relative = (cursor as Node2D).transform * relative
		cursor = cursor.get_parent()
	if cursor != ancestor:
		push_error("Compiled polygon is not a descendant of its semantic bone.")
	return relative


func _build_animation_tree() -> void:
	var state_machine := AnimationNodeStateMachine.new()
	var all_states: Array[StringName] = []
	for direction in CANONICAL_DIRECTIONS:
		for walking in [false, true]:
			var state_name := _state_name(direction, walking)
			var animation_node := AnimationNodeAnimation.new()
			animation_node.animation = _animation_name(direction, walking)
			state_machine.add_node(state_name, animation_node)
			_state_names[Vector2i(direction, int(walking))] = state_name
			all_states.append(state_name)
	for from_state in all_states:
		for to_state in all_states:
			if from_state == to_state:
				continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_SYNC
			transition.xfade_time = direction_crossfade
			transition.reset = false
			state_machine.add_transition(from_state, to_state, transition)
	animation_tree.tree_root = state_machine
	animation_tree.anim_player = animation_tree.get_path_to(animation_player)
	animation_tree.active = true
	_playback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback


func _apply_direction_pose(direction: int, mirrored: bool = false) -> void:
	var pose: Dictionary = _direction_poses.get(direction, {})
	if pose.is_empty():
		return
	projection_root.position = pose.get("root_position", Vector2.ZERO)
	projection_root.scale = Vector2(-1.0 if mirrored else 1.0, foreshortening)
	motion_offset.position = Vector2.ZERO
	skeleton.transform = pose.get("skeleton_transform", Transform2D.IDENTITY)
	var bone_poses: Dictionary = pose.get("bones", {})
	for bone_path in SEMANTIC_BONE_PATHS:
		var bone := skeleton.get_node_or_null(bone_path) as Bone2D
		var bone_pose: Dictionary = bone_poses.get(String(bone_path), {})
		if bone == null or bone_pose.is_empty():
			continue
		bone.transform = bone_pose.get("transform", Transform2D.IDENTITY)
		bone.rest = bone_pose.get("rest", Transform2D.IDENTITY)
		bone.z_index = int(bone_pose.get("z_index", 0))
		bone.z_as_relative = bool(bone_pose.get("z_as_relative", true))
	if preserve_head_shape:
		var head := skeleton.get_node_or_null(^"Hips/Torso/Head") as Bone2D
		if head != null:
			head.scale.y /= maxf(foreshortening, 0.001)


func _set_active_skin(direction: int) -> void:
	for compiled_direction in _direction_slots:
		var is_active_direction := int(compiled_direction) == direction
		for slot in _direction_slots[compiled_direction]:
			(slot as Node2D).visible = is_active_direction


func _play_state(direction: int, walking: bool) -> void:
	if _playback == null:
		return
	var state_name: StringName = _state_names.get(Vector2i(direction, int(walking)), &"")
	if state_name.is_empty():
		return
	if _playback.get_current_node().is_empty():
		_playback.start(state_name)
	else:
		_playback.travel(state_name)


func _animation_name(direction: int, walking: bool) -> StringName:
	return StringName("%s_%s" % [_direction_name(direction), "walk" if walking else "reset"])


func _state_name(direction: int, walking: bool) -> StringName:
	return StringName("%s_%s" % [_direction_name(direction), "walk" if walking else "idle"])


func _direction_name(direction: int) -> String:
	return String(DIRECTION_NAMES.get(direction, &"unsupported"))


func set_foreshortening(value: float) -> void:
	foreshortening = clampf(value, 0.4, 1.0)
	if _compiled:
		_apply_direction_pose(
			_canonical_direction(_current_direction),
			_is_mirrored_direction(_current_direction)
		)


func get_foreshortening() -> float:
	return foreshortening


func _canonical_direction(direction: int) -> int:
	match wrapi(direction, 0, 8):
		Direction.NORTH_WEST:
			return Direction.NORTH_EAST
		Direction.EAST:
			return Direction.WEST
		Direction.SOUTH_EAST:
			return Direction.SOUTH_WEST
		_:
			return wrapi(direction, 0, 8)


func _is_mirrored_direction(direction: int) -> bool:
	return wrapi(direction, 0, 8) in [
		Direction.NORTH_WEST,
		Direction.EAST,
		Direction.SOUTH_EAST,
	]
