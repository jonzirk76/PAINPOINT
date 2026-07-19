extends Node
class_name FaunaManager

@export var cat_scene: PackedScene = preload("res://scenes/entities/cat_entity.tscn")
## Controls the radius around the player that a cat treats as mildly unsafe.
@export var player_avoidance_radius: float = 150.0
## Controls the radius around enemies that a cat treats as unsafe.
@export var enemy_avoidance_radius: float = 285.0
## Controls the radius around active spawners that a cat treats as unsafe.
@export var spawner_avoidance_radius: float = 235.0

var enabled: bool = false
var _fauna_layer: Node = null
var _player_position_provider: Callable
var _enemy_positions_provider: Callable
var _spawner_positions_provider: Callable
var _cat = null
var _arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var _arena_shape: int = 0
var _wall_rects: Array[Rect2] = []
var _level_wall_rects: Array[Rect2] = []
var _void_rects: Array[Rect2] = []
var _playable_rects: Array[Rect2] = []
var _roam_bounds: Rect2 = Rect2()


func initialize(context: Dictionary) -> void:
	_fauna_layer = context.get("fauna_layer", null)
	_player_position_provider = context.get("player_position_provider", Callable())
	_enemy_positions_provider = context.get("enemy_positions_provider", Callable())
	_spawner_positions_provider = context.get("spawner_positions_provider", Callable())


func reset_run(level_definition = null) -> void:
	clear_fauna()
	if level_definition != null:
		set_arena_definition(level_definition)


func clear_fauna() -> void:
	if _cat != null and is_instance_valid(_cat):
		_cat.queue_free()
	_cat = null


func set_enabled(value: bool) -> void:
	enabled = value
	if _has_cat() and _cat.has_method("set_enabled"):
		_cat.set_enabled(value)


func set_arena_definition(level_definition) -> void:
	if level_definition == null:
		return
	_arena_bounds = level_definition.arena_bounds
	_arena_shape = int(level_definition.arena_shape)
	_level_wall_rects = level_definition.wall_rects
	_wall_rects = _level_wall_rects.duplicate()
	_void_rects = level_definition.void_rects
	_playable_rects = _get_playable_rects(level_definition)
	if _has_cat():
		_cat.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)


func set_dynamic_wall_rects(extra_wall_rects: Array[Rect2]) -> void:
	_wall_rects = _level_wall_rects.duplicate()
	_wall_rects.append_array(extra_wall_rects)
	if _has_cat():
		_cat.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)


func set_roam_bounds(bounds: Rect2) -> void:
	_roam_bounds = bounds
	if _has_cat() and _cat.has_method("set_roam_bounds"):
		_cat.set_roam_bounds(bounds)


func spawn_cat(spawn_position: Vector2, movement_seed: int = 0):
	if _has_cat():
		return _cat
	var cat = cat_scene.instantiate()
	if _fauna_layer != null:
		_fauna_layer.add_child(cat)
	else:
		add_child(cat)
	_cat = cat
	if cat.has_method("initialize"):
		cat.initialize(spawn_position, max(movement_seed, 1))
	cat.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)
	if cat.has_method("set_roam_bounds"):
		cat.set_roam_bounds(_roam_bounds)
	if cat.has_method("set_enabled"):
		cat.set_enabled(enabled)
	return cat


func has_active_cat() -> bool:
	return _has_cat()


func get_cat_count() -> int:
	return 1 if _has_cat() else 0


func get_cat_position() -> Vector2:
	if _has_cat():
		return _cat.global_position
	return Vector2.INF


func _process(_delta: float) -> void:
	if not enabled or not _has_cat() or not _cat.has_method("set_danger_points"):
		return
	_cat.set_danger_points(_get_danger_points())


func _has_cat() -> bool:
	return _cat != null and is_instance_valid(_cat)


func _get_danger_points() -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	if _player_position_provider.is_valid():
		var player_position = _player_position_provider.call()
		if player_position is Vector2:
			points.append({
				"position": player_position,
				"radius": player_avoidance_radius,
				"weight": 0.42
			})
	if _enemy_positions_provider.is_valid():
		for enemy_position in _enemy_positions_provider.call():
			if enemy_position is Vector2:
				points.append({
					"position": enemy_position,
					"radius": enemy_avoidance_radius,
					"weight": 1.0
				})
	if _spawner_positions_provider.is_valid():
		for spawner_position in _spawner_positions_provider.call():
			if spawner_position is Vector2:
				points.append({
					"position": spawner_position,
					"radius": spawner_avoidance_radius,
					"weight": 0.7
				})
	return points


func _get_playable_rects(level_definition) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if level_definition == null or not level_definition.has_meta("footprint_cells"):
		return rects
	rects.append_array(ArenaGeometry.get_footprint_cell_rects(level_definition.arena_bounds, level_definition.get_meta("footprint_cells")))
	return rects
