extends Node2D

const CELL_PIECE := preload("res://resources/rooms/combat_cell.tres")
const ROOM_INTERIOR_GENERATOR_SCRIPT := preload("res://scripts/resources/room_interior_generator.gd")
const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")
const BASIC_ENEMY_PROFILE := preload("res://resources/enemies/basic_enemy.tres")
const FAST_ENEMY_PROFILE := preload("res://resources/enemies/fast_enemy.tres")
const TANK_ENEMY_PROFILE := preload("res://resources/enemies/tank_enemy.tres")

## [Description] Deterministic seed used to generate the single-cell room interior.
@export var generation_seed: int = 81527

@onready var arena_view: ArenaView = $World/Arena
@onready var player = $World/DepthSortLayer/NeutralPolygonTestPlayer
@onready var input_manager: InputManager = $InputManager
@onready var room_label: Label = $UI/RoomLabel
@onready var twist_label: Label = $UI/TwistLabel
@onready var size_references: Node2D = $UI/SizeReferences

var _interior_generator = ROOM_INTERIOR_GENERATOR_SCRIPT.new()


func _ready() -> void:
	var level = _interior_generator.generate(
		CELL_PIECE,
		"neutral_polygon_locomotion_test",
		1,
		generation_seed,
		{}
	)
	if level == null:
		push_error("Neutral polygon locomotion test could not generate its room.")
		return
	_strip_combat_contents(level)
	arena_view.configure(level)
	player.global_position = ROOM_GEOMETRY_BUILDER.get_spawn_position(CELL_PIECE.footprint_cells)
	room_label.text = "ONE-CELL PROCEDURAL ROOM  •  SEED %d  •  NO ENEMIES" % generation_seed
	_configure_size_references()
	input_manager.initialize({})
	input_manager.reset_run()
	input_manager.move_changed.connect(_on_move_changed)
	input_manager.aim_changed.connect(_on_aim_changed)
	var visual := player.get_node_or_null("NeutralNativeTwistRuntime") as NativeHumanoidTwistRuntime
	if visual != null:
		visual.pose_changed.connect(_on_visual_pose_changed)
	input_manager.set_enabled(true)
	_update_twist_label()


func _exit_tree() -> void:
	if is_instance_valid(input_manager):
		input_manager.set_enabled(false)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().quit()
	elif event.keycode == KEY_BRACKETLEFT:
		player.adjust_foreshortening(-0.05)
		_update_twist_label()
	elif event.keycode == KEY_BRACKETRIGHT:
		player.adjust_foreshortening(0.05)
		_update_twist_label()
	elif event.keycode == KEY_C:
		player.clear_aim_vector()
		_update_twist_label()


func _on_move_changed(move_vector: Vector2) -> void:
	player.set_move_vector(move_vector)
	_update_twist_label()


func _on_aim_changed(aim_vector: Vector2) -> void:
	player.set_aim_vector(aim_vector)
	_update_twist_label()


func _on_visual_pose_changed(
	_hips_direction: int,
	_torso_direction: int,
	_head_direction: int,
	_arms_direction: int
) -> void:
	_update_twist_label()


func _update_twist_label() -> void:
	var directions: PackedInt32Array = player.get_twist_pose_directions()
	if directions.is_empty():
		return
	twist_label.text = "NATIVE TWIST  •  H %s  T %s  HEAD %s  A %s  •  %s  •  SHORT %d%%" % [
		_direction_name(directions[0]),
		_direction_name(directions[1]),
		_direction_name(directions[2]),
		_direction_name(directions[3]),
		player.get_posture_phase_name().to_upper(),
		roundi(player.get_foreshortening() * 100.0),
	]


func _direction_name(direction: int) -> String:
	return String(["S", "SW", "W", "NW", "N", "NE", "E", "SE"][wrapi(direction, 0, 8)])


func _strip_combat_contents(level) -> void:
	level.use_default_spawners = false
	level.spawner_positions.clear()
	level.spawner_placements.clear()
	level.encounter_table.clear()
	level.encounter_budget = 0
	level.max_active_enemies = 0
	level.boss_profile = null
	level.generate_agent_boss = false
	level.destructible_prop_placements.clear()


func _configure_size_references() -> void:
	var basic_enemy = size_references.get_node("BasicEnemy")
	var fast_enemy = size_references.get_node("FastEnemy")
	var tank_enemy = size_references.get_node("TankEnemy")
	basic_enemy.initialize(BASIC_ENEMY_PROFILE)
	fast_enemy.initialize(FAST_ENEMY_PROFILE)
	tank_enemy.initialize(TANK_ENEMY_PROFILE)
	for reference in size_references.get_children():
		_disable_reference_gameplay_state(reference)
		if reference is CanvasItem:
			(reference as CanvasItem).queue_redraw()


func _disable_reference_gameplay_state(node: Node) -> void:
	if node is CollisionObject2D:
		var collision_object := node as CollisionObject2D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
		collision_object.remove_from_group("player")
		collision_object.remove_from_group("enemies")
		collision_object.remove_from_group("arena_walls")
		collision_object.remove_from_group("destructible_props")
	for child in node.get_children():
		_disable_reference_gameplay_state(child)
