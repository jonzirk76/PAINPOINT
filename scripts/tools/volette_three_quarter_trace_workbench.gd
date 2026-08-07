@tool
extends Node2D

const THREE_QUARTER_MOTION: Resource = preload("res://resources/presentation/humanoid_three_quarter_motion_profile.tres")
const CURRENT_PLAYER_TEXTURE: Texture2D = preload("res://art/characters/player_body.svg")
const GAME_VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const CURRENT_PLAYER_ART_SIZE := 80.0

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
@export var show_hair_comparison: bool = false:
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
			_rebuild_game_scale_preview()
		animate_motion_preview = value
		if not animate_motion_preview:
			_restore_motion_rest_pose()
		_update_processing()

## Chooses which diagonal source assembly receives the motion preview.
@export_enum("Bottom Left (Authored)", "Top Right (Draft)") var motion_preview_direction: int = 0:
	set(value):
		_restore_motion_rest_pose()
		motion_preview_direction = value
		_capture_motion_rest_pose()
		_rebuild_game_scale_preview()

## Multiplies the cycle speed without changing the canonical motion profile.
@export_range(0.1, 2.0, 0.05) var motion_speed_scale := 1.0

@export_group("Game Scale Preview")

## Shows a reduced 1280x720 game frame below the full-size tracing workbench.
@export var show_game_scale_preview: bool = true:
	set(value):
		show_game_scale_preview = value
		_refresh_game_scale_preview()

## Display scale of the 1280x720 game frame; 0.5 produces a 640x360 panel.
@export_range(0.25, 0.75, 0.05) var game_screen_display_scale := 0.5:
	set(value):
		game_screen_display_scale = value
		_rebuild_game_scale_preview()

## Target height of the diagonal mass in game-world pixels.
@export_range(40.0, 140.0, 1.0) var game_character_height := CURRENT_PLAYER_ART_SIZE:
	set(value):
		game_character_height = value
		_rebuild_game_scale_preview()

## Rebuilds the scaled copy after editing source polygons or pivots.
@export var refresh_game_scale_preview_now: bool = false:
	set(value):
		refresh_game_scale_preview_now = false
		if value:
			_rebuild_game_scale_preview()

var _motion_phase := 0.0
var _motion_rest_transforms: Dictionary = {}
var _game_preview_root: Node2D
var _game_preview_character: Node2D


func _ready() -> void:
	_refresh_workbench()
	_capture_motion_rest_pose()
	_rebuild_game_scale_preview()
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
	var instructions := get_node_or_null("GuideLabels/Instructions") as Label
	if instructions != null:
		instructions.text = (
			"BOTTOM-LEFT AUTHORED SOURCE: edit the *Mass Polygon2D nodes. "
			+ "Move pivots only when changing an anchor/socket.\n"
			+ "The opposite view is mirrored; guns and hair are excluded from the body contract."
		)


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
	_sync_game_preview_pose(assembly)


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
	_sync_game_preview_pose(assembly)


func _rebuild_game_scale_preview() -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(_game_preview_root):
		_game_preview_root.free()
	_game_preview_root = Node2D.new()
	_game_preview_root.name = "GameScalePreview"
	_game_preview_root.position = Vector2(0.0, 650.0)
	add_child(_game_preview_root, false, Node.INTERNAL_MODE_FRONT)

	var panel_size := GAME_VIEWPORT_SIZE * game_screen_display_scale
	var background := Polygon2D.new()
	background.name = "GameScreenBackground"
	background.z_index = -100
	background.color = Color(0.035, 0.04, 0.048, 1.0)
	background.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(panel_size.x, 0.0),
		panel_size,
		Vector2(0.0, panel_size.y),
	])
	_game_preview_root.add_child(background)
	_add_game_preview_grid(panel_size)

	var border := Line2D.new()
	border.name = "GameScreenBorder"
	border.z_index = 50
	border.width = 2.0
	border.default_color = Color(0.36, 0.75, 1.0, 0.9)
	border.closed = true
	border.points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(panel_size.x, 0.0),
		panel_size,
		Vector2(0.0, panel_size.y),
	])
	_game_preview_root.add_child(border)

	var title := Label.new()
	title.name = "GameScaleLabel"
	title.z_index = 60
	title.position = Vector2(12.0, 10.0)
	title.text = "1280 x 720 GAME VIEW @ %.0f%%   |   target character height: %.0f world px" % [
		game_screen_display_scale * 100.0,
		game_character_height,
	]
	title.add_theme_font_size_override("font_size", 14)
	_game_preview_root.add_child(title)

	var assembly := _selected_assembly()
	if assembly != null:
		_game_preview_character = assembly.duplicate() as Node2D
		if _game_preview_character != null:
			_game_preview_character.name = "MovingDiagonalMass"
			_game_preview_character.position = Vector2.ZERO
			_game_preview_character.rotation = 0.0
			_game_preview_character.scale = Vector2.ONE
			_game_preview_root.add_child(_game_preview_character)
			var bounds := _calculate_polygon_bounds(_game_preview_character)
			if bounds.size.y > 0.001:
				var display_height := game_character_height * game_screen_display_scale
				var character_scale := display_height / bounds.size.y
				_game_preview_character.scale = Vector2.ONE * character_scale
				var target_center := Vector2(panel_size.x * 0.44, panel_size.y * 0.52)
				_game_preview_character.position = target_center - bounds.get_center() * character_scale

	_add_current_player_reference(panel_size)
	_refresh_game_scale_preview()
	_sync_game_preview_pose(assembly)


func _refresh_game_scale_preview() -> void:
	if is_instance_valid(_game_preview_root):
		_game_preview_root.visible = show_game_scale_preview


func _add_game_preview_grid(panel_size: Vector2) -> void:
	var grid_step := 80.0 * game_screen_display_scale
	var grid_color := Color(0.14, 0.17, 0.2, 0.42)
	var x := grid_step
	while x < panel_size.x:
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = grid_color
		line.points = PackedVector2Array([Vector2(x, 0.0), Vector2(x, panel_size.y)])
		_game_preview_root.add_child(line)
		x += grid_step
	var y := grid_step
	while y < panel_size.y:
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = grid_color
		line.points = PackedVector2Array([Vector2(0.0, y), Vector2(panel_size.x, y)])
		_game_preview_root.add_child(line)
		y += grid_step


func _add_current_player_reference(panel_size: Vector2) -> void:
	if CURRENT_PLAYER_TEXTURE == null:
		return
	var reference := Sprite2D.new()
	reference.name = "CurrentPlayerReference"
	reference.texture = CURRENT_PLAYER_TEXTURE
	reference.position = Vector2(panel_size.x * 0.56, panel_size.y * 0.52)
	var display_size := CURRENT_PLAYER_ART_SIZE * game_screen_display_scale
	var texture_size := CURRENT_PLAYER_TEXTURE.get_size()
	var longest_side := maxf(texture_size.x, texture_size.y)
	reference.scale = Vector2.ONE * (display_size / maxf(longest_side, 1.0))
	reference.modulate = Color(1.0, 1.0, 1.0, 0.7)
	_game_preview_root.add_child(reference)

	var label := Label.new()
	label.name = "CurrentPlayerLabel"
	label.position = reference.position + Vector2(-58.0, display_size * 0.65)
	label.text = "current player"
	label.add_theme_font_size_override("font_size", 11)
	_game_preview_root.add_child(label)


func _calculate_polygon_bounds(root_node: Node2D) -> Rect2:
	var bounds := Rect2()
	var has_point := false
	var root_inverse := root_node.global_transform.affine_inverse()
	var polygons: Array[Polygon2D] = []
	_collect_polygons(root_node, polygons)
	for polygon_node in polygons:
		for point in polygon_node.polygon:
			var local_point := root_inverse * (polygon_node.global_transform * point)
			if not has_point:
				bounds = Rect2(local_point, Vector2.ZERO)
				has_point = true
			else:
				bounds = bounds.expand(local_point)
	return bounds


func _collect_polygons(node: Node, output: Array[Polygon2D]) -> void:
	if node is Polygon2D:
		output.append(node as Polygon2D)
	for child in node.get_children():
		_collect_polygons(child, output)


func _sync_game_preview_pose(source_assembly: Node2D) -> void:
	if source_assembly == null or not is_instance_valid(_game_preview_character):
		return
	for relative_path in MOTION_PATHS:
		var source_part := source_assembly.get_node_or_null(relative_path) as Node2D
		var preview_part := _game_preview_character.get_node_or_null(relative_path) as Node2D
		if source_part != null and preview_part != null:
			preview_part.transform = source_part.transform
