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

enum Subassembly {
	LEGS_AND_HIPS,
	TORSO,
	HEAD,
	ARMS,
}

const POLYGON_SEAM_SOLVER := preload("res://scripts/presentation/polygon_seam_solver.gd")
const SUBASSEMBLIES := [
	Subassembly.LEGS_AND_HIPS,
	Subassembly.TORSO,
	Subassembly.HEAD,
	Subassembly.ARMS,
]
const FAR_ARM_PATH := ^"Skeleton2D/Hips/Torso/FarArm"
const NEAR_ARM_PATH := ^"Skeleton2D/Hips/Torso/NearArm"
const HIP_EXCLUDED_BRANCHES := [&"Torso", &"FarLeg", &"NearLeg"]
const TORSO_EXCLUDED_BRANCHES := [&"Head", &"FarArm", &"NearArm"]
const DRIVER_SEAM_BAND := 1.5
const FOLLOWER_SEAM_BAND := 18.0
const SEAM_TANGENT_MARGIN := 4.0

## [Description] Editable directional skeleton, anchors, and animation tracks shared by compatible humanoid skins.
@export var animation_rig_source: HumanoidAnimationRigSource
## [Description] Editable directional polygon geometry applied to the persistent humanoid rig cache.
@export var character_skin_source: PolygonCharacterSkinSource
## [Description] Extra authored-space advantage required before continuous aiming switches to the opposite shoulder.
@export_range(0.0, 40.0, 1.0) var active_arm_switch_margin: float = 8.0
## [Description] Compresses the completed character along screen Y around its feet; 1.0 preserves authored proportions.
@export_range(0.4, 1.0, 0.01) var foreshortening: float = 1.0:
	set(value):
		foreshortening = clampf(value, 0.4, 1.0)
		if is_node_ready():
			_apply_foreshortening()
## [Description] Keeps the head silhouette at authored proportions while its neck anchor follows body foreshortening.
@export var preserve_head_shape: bool = true:
	set(value):
		preserve_head_shape = value
		if is_node_ready():
			_apply_head_foreshortening_compensation()
## [Description] Enables the procedural lower-torso seam attachment to the hips' upper boundary.
@export var torso_hip_seam_enabled: bool = true:
	set(value):
		torso_hip_seam_enabled = value
		if is_node_ready():
			_refresh_torso_hip_seam()
## [Description] Adds authored-space overlap from the torso seam into the hips to prevent visible cracks.
@export_range(0.0, 16.0, 0.5) var torso_hip_seam_overlap: float = 3.0:
	set(value):
		torso_hip_seam_overlap = value
		if is_node_ready():
			_refresh_torso_hip_seam()

@onready var projection_root: Node2D = $ProjectionRoot
@onready var cache_root: Node2D = $ProjectionRoot/DirectionalCache
@onready var active_arm_socket: Node2D = $ProjectionRoot/ActiveArmSocket

var active_arm: Node2D
var _views: Dictionary = {}
var _view_cache: Dictionary = {}
var _view_base_transforms: Dictionary = {}
var _hip_driver_polygons: Dictionary = {}
var _torso_source_hip_polygons: Dictionary = {}
var _torso_follower_polygons: Dictionary = {}
var _directions := {
	Subassembly.LEGS_AND_HIPS: Direction.SOUTH,
	Subassembly.TORSO: Direction.SOUTH,
	Subassembly.HEAD: Direction.SOUTH,
	Subassembly.ARMS: Direction.SOUTH,
}
var _walking: bool = false
var _twist_sign: int = 1
var _arms_active: bool = false
var _aim_vector: Vector2 = Vector2.ZERO
var _active_arm_path: NodePath = NEAR_ARM_PATH
var _torso_authored_polygons: Dictionary = {}
var _head_authored_scales: Dictionary = {}


func _ready() -> void:
	if not _sources_are_valid():
		push_error("Neutral polygon twist rig requires valid animation rig and character skin sources.")
		set_process(false)
		return
	_setup_active_arm()
	_build_view_cache()
	_apply_foreshortening()
	_activate_cached_views()


func _process(_delta: float) -> void:
	if _walking:
		_apply_torso_hip_seam()
	if not _arms_active or not _walking:
		return
	var torso_view := _views.get(Subassembly.TORSO) as Node2D
	var arms_view := _views.get(Subassembly.ARMS) as Node2D
	if torso_view == null or arms_view == null:
		return
	_attach_arm_root_to_torso(arms_view, torso_view, FAR_ARM_PATH)
	_attach_arm_root_to_torso(arms_view, torso_view, NEAR_ARM_PATH)
	_apply_active_arm_state()


func set_pose(
	hips_direction: int,
	desired_direction: int,
	walking: bool,
	aim_vector: Vector2 = Vector2.ZERO
) -> void:
	var hips := wrapi(hips_direction, 0, 8)
	var desired := wrapi(desired_direction, 0, 8)
	var next_arms_active := aim_vector.length_squared() > 0.01
	var next_aim_vector := aim_vector.normalized() if next_arms_active else Vector2.ZERO
	var initial_delta := _signed_direction_delta(hips, desired)
	if initial_delta != 0 and abs(initial_delta) < 4:
		_twist_sign = 1 if initial_delta > 0 else -1
	var torso := _step_toward(hips, desired, 1)
	var head := _step_toward(torso, desired, 2)
	var arms := _step_toward(head, desired, 1)
	var directions_changed := (
		int(_directions[Subassembly.LEGS_AND_HIPS]) != hips
		or int(_directions[Subassembly.TORSO]) != torso
		or int(_directions[Subassembly.HEAD]) != head
		or int(_directions[Subassembly.ARMS]) != arms
	)
	var walking_changed := _walking != walking
	var active_state_changed := _arms_active != next_arms_active
	var aim_changed := not _aim_vector.is_equal_approx(next_aim_vector)
	_directions[Subassembly.LEGS_AND_HIPS] = hips
	_directions[Subassembly.TORSO] = torso
	_directions[Subassembly.HEAD] = head
	_directions[Subassembly.ARMS] = arms
	_walking = walking
	_arms_active = next_arms_active
	_aim_vector = next_aim_vector
	if directions_changed or active_state_changed:
		_activate_cached_views()
	else:
		if aim_changed:
			_apply_active_arm_state()
		if walking_changed:
			_apply_animation_state()
	pose_changed.emit(hips, torso, head, arms)


func get_pose_directions() -> PackedInt32Array:
	return PackedInt32Array([
		int(_directions[Subassembly.LEGS_AND_HIPS]),
		int(_directions[Subassembly.TORSO]),
		int(_directions[Subassembly.HEAD]),
		int(_directions[Subassembly.ARMS]),
	])


func is_torso_hip_seam_enabled() -> bool:
	return torso_hip_seam_enabled


func set_foreshortening(value: float) -> void:
	foreshortening = value


func get_foreshortening() -> float:
	return foreshortening


func _step_toward(source: int, target: int, maximum_steps: int) -> int:
	var delta := _signed_direction_delta(source, target)
	var step := clampi(delta, -maximum_steps, maximum_steps)
	return wrapi(source + step, 0, 8)


func _signed_direction_delta(source: int, target: int) -> int:
	var clockwise_steps := wrapi(target - source, 0, 8)
	if clockwise_steps == 4:
		return 4 * _twist_sign
	if clockwise_steps < 4:
		return clockwise_steps
	return clockwise_steps - 8


func _activate_cached_views() -> void:
	var walk_phase := _get_walk_phase()
	_deactivate_current_views()
	for subassembly in SUBASSEMBLIES:
		var view_direction := int(_directions[subassembly])
		if subassembly == Subassembly.ARMS and _arms_active:
			view_direction = int(_directions[Subassembly.TORSO])
		var cached_directions: Array = _view_cache.get(subassembly, [])
		if view_direction >= cached_directions.size():
			continue
		var cache_entry: Dictionary = cached_directions[view_direction]
		var view := cache_entry.get("view") as Node2D
		if view == null:
			continue
		view.transform = _view_base_transforms.get(view.get_instance_id(), view.transform)
		if bool(cache_entry.get("mirror", false)):
			view.scale.x *= -1.0
		view.visible = true
		_views[subassembly] = view
	_apply_animation_state(walk_phase)
	_align_subassemblies()
	_apply_head_foreshortening_compensation()
	if torso_hip_seam_enabled:
		_apply_torso_hip_seam()
	else:
		_restore_torso_authored_polygons()
	_apply_active_arm_state()


func _deactivate_current_views() -> void:
	for view in _views.values():
		if not is_instance_valid(view):
			continue
		var animation_player := view.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if animation_player != null:
			animation_player.stop()
		view.visible = false
	_views.clear()


func _build_view_cache() -> void:
	for subassembly in SUBASSEMBLIES:
		var cached_directions: Array[Dictionary] = []
		var canonical_views: Dictionary = {}
		for direction in range(8):
			var selection := character_skin_source.get_selection(direction)
			var scene := selection.get("scene") as PackedScene
			var scene_key := scene.resource_path if scene != null else ""
			var view := canonical_views.get(scene_key) as Node2D
			if view == null:
				view = _instantiate_composed_direction(direction)
				if view != null:
					view.name = "%s_%sSource" % [
						_get_subassembly_name(subassembly),
						_direction_name(direction),
					]
					view.visible = false
					cache_root.add_child(view)
					_filter_subassembly(view, subassembly)
					_view_base_transforms[view.get_instance_id()] = view.transform
					_cache_view_contract(view, subassembly)
					canonical_views[scene_key] = view
			cached_directions.append({
				"view": view,
				"mirror": bool(selection.get("mirror", false)),
			})
		_view_cache[subassembly] = cached_directions


func _instantiate_composed_direction(direction: int) -> Node2D:
	var skin_selection := character_skin_source.get_selection(direction)
	var skin_scene := skin_selection.get("scene") as PackedScene
	if skin_scene == null:
		return null
	var view := skin_scene.instantiate() as Node2D
	if view == null:
		return null
	var rig_selection := animation_rig_source.get_selection(direction)
	var rig_scene := rig_selection.get("scene") as PackedScene
	if rig_scene != null and rig_scene != skin_scene:
		var rig_view := rig_scene.instantiate() as Node2D
		if rig_view != null:
			_apply_rig_contract(rig_view, view)
			rig_view.free()
	return view


func _apply_rig_contract(rig_view: Node2D, skin_view: Node2D) -> void:
	skin_view.transform = rig_view.transform
	var rig_nodes := rig_view.find_children("*", "Node2D", true, false)
	for rig_node in rig_nodes:
		if not rig_node is Skeleton2D and not rig_node is Bone2D:
			continue
		var relative_path := rig_view.get_path_to(rig_node)
		var skin_node := skin_view.get_node_or_null(relative_path) as Node2D
		if skin_node != null:
			skin_node.transform = (rig_node as Node2D).transform
	var rig_player := rig_view.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if rig_player == null:
		return
	var skin_player := skin_view.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if skin_player == null:
		skin_player = AnimationPlayer.new()
		skin_player.name = "AnimationPlayer"
		skin_view.add_child(skin_player)
	skin_player.root_node = rig_player.root_node
	for library_name in skin_player.get_animation_library_list():
		skin_player.remove_animation_library(library_name)
	for library_name in rig_player.get_animation_library_list():
		skin_player.add_animation_library(library_name, rig_player.get_animation_library(library_name))


func _cache_view_contract(view: Node2D, subassembly: int) -> void:
	var instance_id := view.get_instance_id()
	if subassembly == Subassembly.LEGS_AND_HIPS:
		var hips_root := view.get_node_or_null("Skeleton2D/Hips")
		_hip_driver_polygons[instance_id] = _collect_editable_polygons(
			hips_root,
			HIP_EXCLUDED_BRANCHES
		)
	elif subassembly == Subassembly.TORSO:
		var source_hips_root := view.get_node_or_null("Skeleton2D/Hips")
		var torso_root := view.get_node_or_null("Skeleton2D/Hips/Torso")
		_torso_source_hip_polygons[instance_id] = _collect_editable_polygons(
			source_hips_root,
			HIP_EXCLUDED_BRANCHES
		)
		var followers := _collect_editable_polygons(torso_root, TORSO_EXCLUDED_BRANCHES)
		_torso_follower_polygons[instance_id] = followers
		_capture_torso_authored_polygons(followers)


func _setup_active_arm() -> void:
	for child in active_arm_socket.get_children():
		child.queue_free()
	active_arm = character_skin_source.active_arm_scene.instantiate() as Node2D
	if active_arm == null:
		return
	active_arm.name = "ActiveArm"
	active_arm_socket.add_child(active_arm)
	active_arm.visible = false


func _sources_are_valid() -> bool:
	return (
		animation_rig_source != null
		and animation_rig_source.is_valid()
		and character_skin_source != null
		and character_skin_source.is_valid()
	)


func _align_subassemblies() -> void:
	var legs_view: Node2D = _views[Subassembly.LEGS_AND_HIPS]
	var torso_view: Node2D = _views[Subassembly.TORSO]
	var head_view: Node2D = _views[Subassembly.HEAD]
	var arms_view: Node2D = _views[Subassembly.ARMS]
	_offset_view_to_anchor(torso_view, ^"Skeleton2D/Hips", _anchor_position(legs_view, ^"Skeleton2D/Hips"))
	_offset_view_to_anchor(
		head_view,
		^"Skeleton2D/Hips/Torso/Head",
		_anchor_position(torso_view, ^"Skeleton2D/Hips/Torso/Head")
	)
	_attach_arm_root_to_torso(arms_view, torso_view, FAR_ARM_PATH)
	_attach_arm_root_to_torso(arms_view, torso_view, NEAR_ARM_PATH)


func _offset_view_to_anchor(view: Node2D, source_path: NodePath, target_position: Vector2) -> void:
	view.position += target_position - _anchor_position(view, source_path)


func _anchor_position(view: Node2D, path: NodePath) -> Vector2:
	var anchor := view.get_node_or_null(path) as Node2D
	if anchor == null:
		return Vector2.ZERO
	return projection_root.to_local(anchor.global_position)


func _attach_arm_root_to_torso(arms_view: Node2D, torso_view: Node2D, arm_path: NodePath) -> void:
	var arm_root := arms_view.get_node_or_null(arm_path) as Bone2D
	var torso_shoulder := torso_view.get_node_or_null(arm_path) as Bone2D
	if arm_root == null or torso_shoulder == null:
		return
	arm_root.global_position = torso_shoulder.global_position


func _apply_foreshortening() -> void:
	projection_root.scale = Vector2(1.0, foreshortening)
	_apply_head_foreshortening_compensation()
	_refresh_torso_hip_seam()
	_apply_active_arm_state()


func _apply_head_foreshortening_compensation() -> void:
	if not _views.has(Subassembly.HEAD):
		return
	var head_view: Node2D = _views[Subassembly.HEAD]
	var head := head_view.get_node_or_null("Skeleton2D/Hips/Torso/Head") as Bone2D
	if head == null:
		return
	var instance_id := head.get_instance_id()
	if not _head_authored_scales.has(instance_id):
		_head_authored_scales[instance_id] = head.scale
	var authored_scale: Vector2 = _head_authored_scales[instance_id]
	head.scale = authored_scale
	if preserve_head_shape:
		head.scale = Vector2(authored_scale.x, authored_scale.y / maxf(foreshortening, 0.001))


func _refresh_torso_hip_seam() -> void:
	_restore_torso_authored_polygons()
	_apply_torso_hip_seam()


func _capture_torso_authored_polygons(polygons: Array[Polygon2D]) -> void:
	for polygon in polygons:
		_torso_authored_polygons[polygon.get_instance_id()] = polygon.polygon.duplicate()


func _restore_torso_authored_polygons() -> void:
	if not _views.has(Subassembly.TORSO):
		return
	var torso_view: Node2D = _views[Subassembly.TORSO]
	var polygons: Array[Polygon2D] = _torso_follower_polygons.get(
		torso_view.get_instance_id(),
		[]
	)
	for polygon in polygons:
		var instance_id := polygon.get_instance_id()
		if _torso_authored_polygons.has(instance_id):
			polygon.polygon = PackedVector2Array(_torso_authored_polygons[instance_id])


func _apply_torso_hip_seam() -> void:
	if not torso_hip_seam_enabled:
		return
	if not _views.has(Subassembly.LEGS_AND_HIPS) or not _views.has(Subassembly.TORSO):
		return
	var hips_view: Node2D = _views[Subassembly.LEGS_AND_HIPS]
	var torso_view: Node2D = _views[Subassembly.TORSO]
	var hips_polygons: Array[Polygon2D] = _hip_driver_polygons.get(
		hips_view.get_instance_id(),
		[]
	)
	var source_hips_polygons: Array[Polygon2D] = _torso_source_hip_polygons.get(
		torso_view.get_instance_id(),
		[]
	)
	var followers: Array[Polygon2D] = _torso_follower_polygons.get(
		torso_view.get_instance_id(),
		[]
	)
	var target_seam := _build_driver_seam(
		hips_polygons
	)
	var source_seam := _build_driver_seam(
		source_hips_polygons
	)
	if source_seam.size() < 2 or target_seam.size() < 2:
		return
	for follower in followers:
		_solve_follower_polygon(follower, source_seam, target_seam)


func _solve_follower_polygon(
	follower: Polygon2D,
	source_seam: PackedVector2Array,
	target_seam: PackedVector2Array
) -> void:
	var instance_id := follower.get_instance_id()
	if not _torso_authored_polygons.has(instance_id):
		_torso_authored_polygons[instance_id] = follower.polygon.duplicate()
	var authored := PackedVector2Array(_torso_authored_polygons[instance_id])
	if authored.is_empty():
		return
	var solved := authored.duplicate()
	var maximum_y := authored[0].y
	for point in authored:
		maximum_y = maxf(maximum_y, point.y)
	for index in authored.size():
		if authored[index].y < maximum_y - FOLLOWER_SEAM_BAND:
			continue
		var authored_position := projection_root.to_local(follower.to_global(authored[index]))
		if not _is_within_seam_tangent_span(authored_position, source_seam):
			continue
		var binding: Vector2 = POLYGON_SEAM_SOLVER.bind_point(authored_position, source_seam)
		var resolved: Vector2 = POLYGON_SEAM_SOLVER.resolve_binding(
			binding,
			target_seam,
			torso_hip_seam_overlap
		)
		solved[index] = follower.to_local(projection_root.to_global(resolved))
	follower.polygon = solved


func _is_within_seam_tangent_span(point: Vector2, seam: PackedVector2Array) -> bool:
	if seam.size() < 2:
		return false
	var start := seam[0]
	var finish := seam[seam.size() - 1]
	var axis := finish - start
	var span := axis.length()
	if span <= 0.0001:
		return false
	var tangent_distance := (point - start).dot(axis / span)
	return tangent_distance >= -SEAM_TANGENT_MARGIN and tangent_distance <= span + SEAM_TANGENT_MARGIN


func _build_driver_seam(polygons: Array[Polygon2D]) -> PackedVector2Array:
	var candidates: Array[Vector2] = []
	for polygon in polygons:
		if polygon.polygon.is_empty():
			continue
		var minimum_y := polygon.polygon[0].y
		for point in polygon.polygon:
			minimum_y = minf(minimum_y, point.y)
		for point in polygon.polygon:
			if point.y <= minimum_y + DRIVER_SEAM_BAND:
				candidates.append(projection_root.to_local(polygon.to_global(point)))
	candidates.sort_custom(func(left: Vector2, right: Vector2) -> bool: return left.x < right.x)
	var seam := PackedVector2Array()
	for candidate in candidates:
		if seam.is_empty() or seam[seam.size() - 1].distance_squared_to(candidate) > 0.01:
			seam.append(candidate)
	return seam


func _collect_editable_polygons(root: Node, excluded_branches: Array) -> Array[Polygon2D]:
	var results: Array[Polygon2D] = []
	if root == null:
		return results
	_collect_editable_polygons_recursive(root, excluded_branches, results)
	return results


func _collect_editable_polygons_recursive(
	root: Node,
	excluded_branches: Array,
	results: Array[Polygon2D]
) -> void:
	for child in root.get_children():
		if excluded_branches.has(child.name):
			continue
		if child is Polygon2D and bool(child.get_meta("editable_polygon_base", false)):
			results.append(child as Polygon2D)
		_collect_editable_polygons_recursive(child, excluded_branches, results)


func _apply_active_arm_state() -> void:
	if active_arm == null:
		return
	active_arm.visible = _arms_active
	if not _views.has(Subassembly.ARMS) or not _views.has(Subassembly.TORSO):
		return
	var arms_view: Node2D = _views[Subassembly.ARMS]
	var torso_view: Node2D = _views[Subassembly.TORSO]
	var far_arm := arms_view.get_node_or_null(FAR_ARM_PATH) as Bone2D
	var near_arm := arms_view.get_node_or_null(NEAR_ARM_PATH) as Bone2D
	if far_arm == null or near_arm == null:
		return
	far_arm.visible = true
	near_arm.visible = true
	if not _arms_active:
		return
	_active_arm_path = _select_active_arm_path(torso_view)
	var replaced_arm := arms_view.get_node_or_null(_active_arm_path) as Bone2D
	var shoulder := torso_view.get_node_or_null(_active_arm_path) as Bone2D
	if replaced_arm == null or shoulder == null:
		active_arm.visible = false
		return
	replaced_arm.visible = false
	active_arm.global_position = shoulder.global_position
	var local_aim := Vector2(_aim_vector.x, _aim_vector.y / maxf(foreshortening, 0.001)).normalized()
	active_arm.rotation = local_aim.angle() - PI * 0.5
	_copy_arm_depth(replaced_arm)


func _select_active_arm_path(torso_view: Node2D) -> NodePath:
	var far_shoulder := torso_view.get_node_or_null(FAR_ARM_PATH) as Bone2D
	var near_shoulder := torso_view.get_node_or_null(NEAR_ARM_PATH) as Bone2D
	if far_shoulder == null or near_shoulder == null:
		return NEAR_ARM_PATH
	var far_position := far_shoulder.global_position
	var near_position := near_shoulder.global_position
	var center := (far_position + near_position) * 0.5
	var far_score := (far_position - center).dot(_aim_vector)
	var near_score := (near_position - center).dot(_aim_vector)
	if _active_arm_path == FAR_ARM_PATH and near_score - far_score < active_arm_switch_margin:
		return FAR_ARM_PATH
	if _active_arm_path == NEAR_ARM_PATH and far_score - near_score < active_arm_switch_margin:
		return NEAR_ARM_PATH
	return FAR_ARM_PATH if far_score > near_score else NEAR_ARM_PATH


func _copy_arm_depth(replaced_arm: Bone2D) -> void:
	if active_arm == null:
		return
	var upper_arm := replaced_arm.find_child("UpperArm", true, false) as Polygon2D
	active_arm.z_index = replaced_arm.z_index
	active_arm.modulate = Color.WHITE
	if upper_arm != null:
		if active_arm.z_index == 0:
			active_arm.z_index = upper_arm.z_index
		active_arm.modulate = upper_arm.modulate


func _filter_subassembly(view: Node2D, subassembly: int) -> void:
	var hips := view.get_node_or_null("Skeleton2D/Hips") as Node2D
	var torso := view.get_node_or_null("Skeleton2D/Hips/Torso") as Node2D
	if hips == null or torso == null:
		return
	match subassembly:
		Subassembly.LEGS_AND_HIPS:
			torso.visible = false
		Subassembly.TORSO:
			_set_direct_children_visible(hips, [&"Torso"])
			_hide_named_children(torso, [&"Head", &"FarArm", &"NearArm"])
		Subassembly.HEAD:
			_set_direct_children_visible(hips, [&"Torso"])
			_set_direct_children_visible(torso, [&"Head"])
		Subassembly.ARMS:
			_set_direct_children_visible(hips, [&"Torso"])
			_set_direct_children_visible(torso, [&"FarArm", &"NearArm"])


func _set_direct_children_visible(parent: Node, visible_names: Array) -> void:
	for child in parent.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = visible_names.has(child.name)


func _hide_named_children(parent: Node, hidden_names: Array) -> void:
	for child in parent.get_children():
		if child is CanvasItem and hidden_names.has(child.name):
			(child as CanvasItem).visible = false


func _apply_animation_state(walk_phase: float = 0.0) -> void:
	for subassembly in SUBASSEMBLIES:
		if not _views.has(subassembly):
			continue
		var view: Node2D = _views[subassembly]
		var animation_player := view.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if animation_player == null:
			continue
		if not _walking or (subassembly == Subassembly.ARMS and _arms_active):
			animation_player.play(&"RESET")
			animation_player.advance(0.0)
			continue
		animation_player.play(&"walk")
		var walk_animation := animation_player.get_animation(&"walk")
		if walk_animation != null and walk_animation.length > 0.0:
			animation_player.seek(fposmod(walk_phase, 1.0) * walk_animation.length, true)


func _get_walk_phase() -> float:
	if not _views.has(Subassembly.LEGS_AND_HIPS):
		return 0.0
	var legs_view: Node2D = _views[Subassembly.LEGS_AND_HIPS]
	var animation_player := legs_view.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player == null or animation_player.current_animation != &"walk":
		return 0.0
	var walk_animation := animation_player.get_animation(&"walk")
	if walk_animation == null or walk_animation.length <= 0.0:
		return 0.0
	return fposmod(animation_player.current_animation_position / walk_animation.length, 1.0)


func _get_subassembly_name(subassembly: int) -> String:
	match subassembly:
		Subassembly.LEGS_AND_HIPS:
			return "LegsAndHipsView"
		Subassembly.TORSO:
			return "TorsoView"
		Subassembly.HEAD:
			return "HeadView"
		_:
			return "ArmsView"


func _direction_name(direction: int) -> String:
	return String(["S", "SW", "W", "NW", "N", "NE", "E", "SE"][wrapi(direction, 0, 8)])
