extends Node
class_name EnemyManager

signal enemy_defeated(enemy, score_value: int)
signal enemy_count_changed(count: int)
signal player_contact_requested(enemy, player, damage: int)
signal hostile_shot_requested(origin: Vector2, direction: Vector2, shot_config: Dictionary)

@export var enemy_scene: PackedScene = preload("res://scenes/entities/enemy_entity.tscn")
@export var default_enemy_profile: Resource = preload("res://resources/enemies/basic_enemy.tres")
@export var boss_add_profile: Resource = preload("res://resources/enemies/shooter_enemy.tres")
@export var boss_add_target_count: int = 3
@export var boss_add_replenish_interval: float = 4.2
@export var boss_projectile_shield_lead_seconds: float = 1.25
@export var boss_projectile_shield_after_spawn_seconds: float = 1.15
@export var crowd_separation_force: float = 115.0
@export var crowd_separation_padding: float = 10.0

var enabled: bool = false
var _enemy_layer: Node = null
var _player_provider: Callable
var _player_ref_provider: Callable
var _enemies: Array = []
var _contact_timers: Dictionary = {}
var _arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var _arena_shape: int = 0
var _wall_rects: Array[Rect2] = []
var _void_rects: Array[Rect2] = []
var _boss_add_timer: float = 0.0


func initialize(context: Dictionary) -> void:
	_enemy_layer = context.get("enemy_layer", null)
	_player_provider = context.get("player_position_provider", Callable())
	_player_ref_provider = context.get("player_ref_provider", Callable())


func reset_run() -> void:
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()
	_contact_timers.clear()
	_boss_add_timer = 0.0
	enemy_count_changed.emit(0)


func set_enabled(value: bool) -> void:
	enabled = value


func set_arena_definition(level_definition) -> void:
	if level_definition == null:
		return
	_arena_bounds = level_definition.arena_bounds
	_arena_shape = int(level_definition.arena_shape)
	_wall_rects = level_definition.wall_rects
	_void_rects = level_definition.void_rects
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects)


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var player_position := _get_player_position()
	var player = _get_player_ref()
	for enemy in _enemies.duplicate():
		if not is_instance_valid(enemy):
			_enemies.erase(enemy)
			continue
		enemy.set_target_position(player_position)
		var id: int = enemy.get_instance_id()
		_contact_timers[id] = max(float(_contact_timers.get(id, 0.0)) - delta, 0.0)
		if enemy.has_method("is_birth_animation_active") and bool(enemy.is_birth_animation_active()):
			continue
		if player != null and is_instance_valid(player):
			var contact_range: float = _get_effective_contact_range(enemy, player)
			if enemy.global_position.distance_squared_to(player.global_position) <= contact_range * contact_range and float(_contact_timers[id]) <= 0.0:
				_contact_timers[id] = enemy.contact_cooldown
				player_contact_requested.emit(enemy, player, enemy.contact_damage)
	_apply_crowd_separation()
	_update_boss_adds(delta)


func spawn_enemy(profile, spawn_position: Vector2, spawn_flags: Dictionary = {}):
	if not enabled:
		return null
	var enemy = enemy_scene.instantiate()
	var selected_profile = profile if profile != null else default_enemy_profile
	enemy.initialize(selected_profile)
	enemy.global_position = ArenaGeometry.constrain_point(spawn_position, _arena_bounds, _arena_shape)
	enemy.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects)
	if bool(spawn_flags.get("boss_add", false)):
		enemy.set_meta("boss_add", true)
	if _enemy_layer != null:
		_enemy_layer.add_child(enemy)
	else:
		add_child(enemy)
	if bool(spawn_flags.get("birth", false)) and enemy.has_method("play_birth_animation"):
		enemy.play_birth_animation(float(spawn_flags.get("birth_duration", 0.36)))
	enemy.health_depleted.connect(_on_enemy_health_depleted)
	enemy.shot_ready.connect(_on_enemy_shot_ready)
	_enemies.append(enemy)
	enemy_count_changed.emit(_enemies.size())
	return enemy


func apply_damage(target: Node, packet) -> bool:
	if target == null or packet == null or not is_instance_valid(target):
		return false
	if not target.is_in_group("enemies") or not target.has_method("take_damage"):
		return false
	var enemy = target
	if not _enemies.has(enemy):
		return false
	return bool(enemy.take_damage(packet))


func apply_parry_pushback(origin: Vector2, radius: float, force: float) -> int:
	var pushed_count := 0
	var radius_squared := radius * radius
	for enemy in _enemies:
		if not is_instance_valid(enemy):
			continue
		var effective_radius: float = radius + float(enemy.body_radius)
		if enemy.global_position.distance_squared_to(origin) > max(radius_squared, effective_radius * effective_radius):
			continue
		if enemy.has_method("apply_pushback"):
			enemy.apply_pushback(origin, force * _get_parry_pushback_size_factor(enemy))
			_contact_timers[enemy.get_instance_id()] = max(float(_contact_timers.get(enemy.get_instance_id(), 0.0)), 0.22)
			pushed_count += 1
	return pushed_count


func _get_parry_pushback_size_factor(enemy) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 1.0
	var body_size: float = max(float(enemy.body_radius), 1.0)
	return clamp(22.0 / body_size, 0.28, 1.0)


func get_nearby_enemies(origin: Vector2, radius: float, excluded: Array[Node]) -> Array:
	var candidates: Array = []
	var radius_squared := radius * radius
	for enemy in _enemies:
		if not is_instance_valid(enemy) or excluded.has(enemy):
			continue
		if enemy.global_position.distance_squared_to(origin) <= radius_squared:
			candidates.append(enemy)
	candidates.sort_custom(func(a, b) -> bool:
		return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin)
	)
	return candidates


func get_enemy_count() -> int:
	return _enemies.size()


func _on_enemy_health_depleted(enemy) -> void:
	if not _enemies.has(enemy):
		return
	_enemies.erase(enemy)
	_contact_timers.erase(enemy.get_instance_id())
	enemy_defeated.emit(enemy, enemy.score_value)
	enemy_count_changed.emit(_enemies.size())


func _on_enemy_shot_ready(_enemy, origin: Vector2, direction: Vector2, shot_config: Dictionary) -> void:
	if not enabled or direction.length_squared() <= 0.001:
		return
	hostile_shot_requested.emit(origin, direction, shot_config)


func _get_effective_contact_range(enemy, player) -> float:
	var body_touch_range: float = float(enemy.body_radius) + float(player.body_radius) + 4.0
	return max(float(enemy.contact_radius), body_touch_range)


func _get_player_position() -> Vector2:
	if _player_provider.is_valid():
		return _player_provider.call()
	return Vector2.ZERO


func _get_player_ref():
	if _player_ref_provider.is_valid():
		var player = _player_ref_provider.call()
		if player != null and is_instance_valid(player) and player.is_in_group("player"):
			return player
	return null


func _apply_crowd_separation() -> void:
	if crowd_separation_force <= 0.0 or _enemies.size() < 2:
		return
	var valid_enemies: Array = []
	var pushes: Array[Vector2] = []
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.has_method("apply_crowd_separation"):
			valid_enemies.append(enemy)
			pushes.append(Vector2.ZERO)
	for first_index in range(valid_enemies.size()):
		var first = valid_enemies[first_index]
		for second_index in range(first_index + 1, valid_enemies.size()):
			var second = valid_enemies[second_index]
			var separation: Vector2 = first.global_position - second.global_position
			var desired_distance: float = float(first.body_radius) + float(second.body_radius) + crowd_separation_padding
			var distance_squared: float = separation.length_squared()
			if distance_squared > desired_distance * desired_distance:
				continue
			var direction: Vector2 = Vector2.RIGHT.rotated(float((first.get_instance_id() + second.get_instance_id()) % 628) * 0.01)
			var distance: float = 0.0
			if distance_squared > 0.001:
				distance = sqrt(distance_squared)
				direction = separation / distance
			var strength: float = (1.0 - clamp(distance / desired_distance, 0.0, 1.0)) * crowd_separation_force
			pushes[first_index] += direction * strength
			pushes[second_index] -= direction * strength
	for index in range(valid_enemies.size()):
		if pushes[index].length_squared() > 0.001:
			valid_enemies[index].apply_crowd_separation(pushes[index])


func _update_boss_adds(delta: float) -> void:
	if boss_add_target_count <= 0 or boss_add_profile == null:
		return
	var boss = _get_alive_boss()
	if boss == null:
		_boss_add_timer = 0.0
		return
	var current_adds := _get_boss_add_count()
	if current_adds >= boss_add_target_count:
		_boss_add_timer = min(_boss_add_timer, boss_add_replenish_interval)
		return
	_boss_add_timer = max(_boss_add_timer - delta, 0.0)
	if _boss_add_timer <= boss_projectile_shield_lead_seconds and boss.has_method("activate_projectile_shield"):
		boss.activate_projectile_shield(max(_boss_add_timer, 0.0) + boss_projectile_shield_after_spawn_seconds)
	if _boss_add_timer > 0.0:
		return
	var missing_count: int = boss_add_target_count - current_adds
	for index in range(missing_count):
		spawn_enemy(boss_add_profile, _get_boss_add_spawn_position(boss, index, missing_count), {"boss_add": true, "birth": true})
	_boss_add_timer = boss_add_replenish_interval


func _get_alive_boss():
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.behavior_kind == "boss":
			return enemy
	return null


func _get_boss_add_count() -> int:
	var count := 0
	for enemy in _enemies:
		if is_instance_valid(enemy) and bool(enemy.get_meta("boss_add", false)):
			count += 1
	return count


func _get_boss_add_spawn_position(boss, index: int, count: int) -> Vector2:
	var radius: float = float(boss.body_radius) + 100.0
	var angle: float = TAU * float(index) / float(max(count, 1)) + float(Time.get_ticks_msec() % 1000) * 0.001
	return ArenaGeometry.constrain_point(boss.global_position + Vector2.RIGHT.rotated(angle) * radius, _arena_bounds, _arena_shape)
