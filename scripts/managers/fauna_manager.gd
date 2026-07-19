extends Node
class_name FaunaManager

const CAT_TEXTURES := [
	preload("res://art/characters/Cats Download/black_0.png"),
	preload("res://art/characters/Cats Download/black_1.png"),
	preload("res://art/characters/Cats Download/black_2.png"),
	preload("res://art/characters/Cats Download/black_3.png"),
	preload("res://art/characters/Cats Download/black_4.png"),
	preload("res://art/characters/Cats Download/blue_0.png"),
	preload("res://art/characters/Cats Download/blue_1.png"),
	preload("res://art/characters/Cats Download/blue_2.png"),
	preload("res://art/characters/Cats Download/blue_3.png"),
	preload("res://art/characters/Cats Download/brown_0.png"),
	preload("res://art/characters/Cats Download/brown_1.png"),
	preload("res://art/characters/Cats Download/brown_2.png"),
	preload("res://art/characters/Cats Download/brown_3.png"),
	preload("res://art/characters/Cats Download/brown_4.png"),
	preload("res://art/characters/Cats Download/brown_5.png"),
	preload("res://art/characters/Cats Download/brown_6.png"),
	preload("res://art/characters/Cats Download/brown_7.png"),
	preload("res://art/characters/Cats Download/brown_8.png"),
	preload("res://art/characters/Cats Download/calico_0.png"),
	preload("res://art/characters/Cats Download/cotton_candy_blue_0.png"),
	preload("res://art/characters/Cats Download/cotton_candy_pink_0.png"),
	preload("res://art/characters/Cats Download/creme_0.png"),
	preload("res://art/characters/Cats Download/creme_1.png"),
	preload("res://art/characters/Cats Download/dark_0.png"),
	preload("res://art/characters/Cats Download/game_boy_0.png"),
	preload("res://art/characters/Cats Download/game_boy_1.png"),
	preload("res://art/characters/Cats Download/game_boy_2.png"),
	preload("res://art/characters/Cats Download/ghost_0.png"),
	preload("res://art/characters/Cats Download/gold_0.png"),
	preload("res://art/characters/Cats Download/grey_0.png"),
	preload("res://art/characters/Cats Download/grey_1.png"),
	preload("res://art/characters/Cats Download/grey_2.png"),
	preload("res://art/characters/Cats Download/hairless_0.png"),
	preload("res://art/characters/Cats Download/hairless_1.png"),
	preload("res://art/characters/Cats Download/indigo_0.png"),
	preload("res://art/characters/Cats Download/orange_0.png"),
	preload("res://art/characters/Cats Download/orange_1.png"),
	preload("res://art/characters/Cats Download/orange_2.png"),
	preload("res://art/characters/Cats Download/orange_3.png"),
	preload("res://art/characters/Cats Download/peach_0.png"),
	preload("res://art/characters/Cats Download/pink_0.png"),
	preload("res://art/characters/Cats Download/radioactive_0.png"),
	preload("res://art/characters/Cats Download/red_0.png"),
	preload("res://art/characters/Cats Download/red_1.png"),
	preload("res://art/characters/Cats Download/seal_point_0.png"),
	preload("res://art/characters/Cats Download/teal_0.png"),
	preload("res://art/characters/Cats Download/white_0.png"),
	preload("res://art/characters/Cats Download/white_grey_0.png"),
	preload("res://art/characters/Cats Download/white_grey_1.png"),
	preload("res://art/characters/Cats Download/yellow_0.png")
]

@export var cat_scene: PackedScene = preload("res://scenes/entities/cat_entity.tscn")
## Controls the radius around the player that a cat treats as mildly unsafe.
@export var player_avoidance_radius: float = 150.0
## Controls the radius around enemies that a cat treats as unsafe.
@export var enemy_avoidance_radius: float = 285.0
## Controls the radius around active spawners that a cat treats as unsafe.
@export var spawner_avoidance_radius: float = 235.0
## Controls how far outside the current dungeon activity bounds a cat remains simulated.
@export var cat_activity_bounds_margin: float = 96.0

var enabled: bool = false
var _fauna_layer: Node = null
var _player_position_provider: Callable
var _enemy_positions_provider: Callable
var _spawner_positions_provider: Callable
var _player_projectile_positions_provider: Callable
var _cat = null
var _arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var _arena_shape: int = 0
var _wall_rects: Array[Rect2] = []
var _level_wall_rects: Array[Rect2] = []
var _void_rects: Array[Rect2] = []
var _playable_rects: Array[Rect2] = []
var _roam_bounds: Rect2 = Rect2()
var _cat_activity_bounds: Rect2 = Rect2()
var _has_cat_activity_bounds: bool = false
var _cat_texture_rng := RandomNumberGenerator.new()
var _last_player_position: Vector2 = Vector2.INF
var _has_last_player_position: bool = false


func initialize(context: Dictionary) -> void:
	_cat_texture_rng.randomize()
	_fauna_layer = context.get("fauna_layer", null)
	_player_position_provider = context.get("player_position_provider", Callable())
	_enemy_positions_provider = context.get("enemy_positions_provider", Callable())
	_spawner_positions_provider = context.get("spawner_positions_provider", Callable())
	_player_projectile_positions_provider = context.get("player_projectile_positions_provider", Callable())


func reset_run(level_definition = null) -> void:
	clear_fauna()
	if level_definition != null:
		set_arena_definition(level_definition)


func clear_fauna() -> void:
	if _cat != null and is_instance_valid(_cat):
		_cat.queue_free()
	_cat = null
	clear_cat_activity_bounds()
	_last_player_position = Vector2.INF
	_has_last_player_position = false


func set_enabled(value: bool) -> void:
	enabled = value
	_apply_cat_enabled_state()


func set_arena_definition(level_definition) -> void:
	if level_definition == null:
		return
	_arena_bounds = level_definition.arena_bounds
	_arena_shape = int(level_definition.arena_shape)
	_level_wall_rects = level_definition.wall_rects
	_wall_rects = _level_wall_rects.duplicate()
	_void_rects = level_definition.void_rects
	_playable_rects = _get_playable_rects(level_definition)
	_sync_cat_simulation_state()


func set_dynamic_wall_rects(extra_wall_rects: Array[Rect2]) -> void:
	_wall_rects = _level_wall_rects.duplicate()
	_wall_rects.append_array(extra_wall_rects)
	_sync_cat_simulation_state()

func set_roam_bounds(bounds: Rect2) -> void:
	_roam_bounds = bounds
	if _has_cat() and _cat_should_sync_geometry() and _cat.has_method("set_roam_bounds"):
		_cat.set_roam_bounds(_roam_bounds)
	_apply_cat_enabled_state()


func set_cat_activity_bounds(bounds: Rect2) -> void:
	_cat_activity_bounds = bounds
	_has_cat_activity_bounds = bounds.size.x > 0.0 and bounds.size.y > 0.0
	_apply_cat_enabled_state()


func clear_cat_activity_bounds() -> void:
	_cat_activity_bounds = Rect2()
	_has_cat_activity_bounds = false
	_apply_cat_enabled_state()


func spawn_cat(spawn_position: Vector2, movement_seed: int = 0):
	if _has_cat():
		return _cat
	var cat_seed: int = max(movement_seed, 1)
	var cat = cat_scene.instantiate()
	if _fauna_layer != null:
		_fauna_layer.add_child(cat)
	else:
		add_child(cat)
	_cat = cat
	if cat.has_method("set_cat_texture"):
		cat.set_cat_texture(_pick_cat_texture())
	if cat.has_method("initialize"):
		cat.initialize(spawn_position, cat_seed)
	_sync_cat_simulation_state()
	return cat


func has_active_cat() -> bool:
	return _has_cat()


func get_cat_count() -> int:
	return 1 if _has_cat() else 0


func get_cat_position() -> Vector2:
	if _has_cat():
		return _cat.global_position
	return Vector2.INF


func get_cat_state_snapshot() -> Dictionary:
	if _has_cat() and _cat.has_method("get_state_snapshot"):
		return _cat.get_state_snapshot()
	return {}


func _process(delta: float) -> void:
	if not enabled or not _has_cat():
		return
	if not _cat_is_inside_activity_bounds():
		_apply_cat_enabled_state()
		return
	var player_position: Vector2 = _get_current_player_position()
	if _cat.has_method("set_danger_points"):
		_cat.set_danger_points(_get_danger_points(player_position))
	if _cat.has_method("set_player_context"):
		_cat.set_player_context(player_position, _get_player_velocity(player_position, delta), player_avoidance_radius)
	if _cat.has_method("set_player_projectile_points"):
		_cat.set_player_projectile_points(_get_player_projectile_positions())


func _has_cat() -> bool:
	return _cat != null and is_instance_valid(_cat)


func _sync_cat_simulation_state() -> void:
	if not _has_cat():
		return
	if not _cat_should_sync_geometry():
		_apply_cat_enabled_state()
		return
	_cat.set_arena_definition(_arena_bounds, _arena_shape, _get_cat_wall_rects(), _get_cat_void_rects(), _get_cat_playable_rects())
	if _cat.has_method("set_roam_bounds"):
		_cat.set_roam_bounds(_roam_bounds)
	_apply_cat_enabled_state()


func _apply_cat_enabled_state() -> void:
	if not _has_cat() or not _cat.has_method("set_enabled"):
		return
	var inside_activity_bounds: bool = _cat_is_inside_activity_bounds()
	_cat.set_enabled(enabled and inside_activity_bounds)


func _cat_is_inside_activity_bounds() -> bool:
	if not _has_cat():
		return false
	if not _has_cat_activity_bounds:
		return true
	return _cat_activity_bounds.grow(maxf(cat_activity_bounds_margin, 0.0)).has_point(_cat.global_position)


func _cat_should_sync_geometry() -> bool:
	if not _has_cat():
		return false
	if not _has_cat_activity_bounds:
		return true
	return _cat_is_inside_activity_bounds()


func _get_cat_wall_rects() -> Array[Rect2]:
	return _filter_rects_for_cat_activity(_wall_rects)


func _get_cat_void_rects() -> Array[Rect2]:
	return _filter_rects_for_cat_activity(_void_rects)


func _get_cat_playable_rects() -> Array[Rect2]:
	return _filter_rects_for_cat_activity(_playable_rects)


func _filter_rects_for_cat_activity(rects: Array[Rect2]) -> Array[Rect2]:
	if not _has_cat_activity_bounds:
		return rects.duplicate()
	var filtered: Array[Rect2] = []
	var filter_bounds: Rect2 = _cat_activity_bounds.grow(maxf(cat_activity_bounds_margin, 0.0) + 96.0)
	for rect: Rect2 in rects:
		if rect.intersects(filter_bounds, true):
			filtered.append(rect)
	return filtered


func _pick_cat_texture() -> Texture2D:
	if CAT_TEXTURES.is_empty():
		return null
	return CAT_TEXTURES[_cat_texture_rng.randi_range(0, CAT_TEXTURES.size() - 1)]


func _get_danger_points(player_position: Vector2 = Vector2.INF) -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	if player_position != Vector2.INF:
		points.append({
			"kind": "player",
			"position": player_position,
			"radius": player_avoidance_radius,
			"weight": 0.42
		})
	if _enemy_positions_provider.is_valid():
		var enemy_positions_value: Variant = _enemy_positions_provider.call()
		if enemy_positions_value is Array:
			for enemy_position in enemy_positions_value:
				if not enemy_position is Vector2:
					continue
				points.append({
					"kind": "combat",
					"position": enemy_position,
					"radius": enemy_avoidance_radius,
					"weight": 1.0
				})
	if _spawner_positions_provider.is_valid():
		var spawner_positions_value: Variant = _spawner_positions_provider.call()
		if spawner_positions_value is Array:
			for spawner_position in spawner_positions_value:
				if not spawner_position is Vector2:
					continue
				points.append({
					"kind": "combat",
					"position": spawner_position,
					"radius": spawner_avoidance_radius,
					"weight": 0.7
				})
	return points


func _get_current_player_position() -> Vector2:
	if not _player_position_provider.is_valid():
		return Vector2.INF
	var position_value: Variant = _player_position_provider.call()
	if position_value is Vector2:
		return position_value
	return Vector2.INF


func _get_player_velocity(player_position: Vector2, delta: float) -> Vector2:
	if player_position == Vector2.INF or delta <= 0.0:
		_last_player_position = Vector2.INF
		_has_last_player_position = false
		return Vector2.ZERO
	if not _has_last_player_position:
		_last_player_position = player_position
		_has_last_player_position = true
		return Vector2.ZERO
	var player_velocity: Vector2 = (player_position - _last_player_position) / delta
	_last_player_position = player_position
	return player_velocity


func _get_player_projectile_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if not _player_projectile_positions_provider.is_valid():
		return positions
	var positions_value: Variant = _player_projectile_positions_provider.call()
	if not positions_value is Array:
		return positions
	for projectile_position in positions_value:
		if projectile_position is Vector2:
			positions.append(projectile_position)
	return positions


func _get_playable_rects(level_definition) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if level_definition == null or not level_definition.has_meta("footprint_cells"):
		return rects
	rects.append_array(ArenaGeometry.get_footprint_cell_rects(level_definition.arena_bounds, level_definition.get_meta("footprint_cells")))
	return rects
