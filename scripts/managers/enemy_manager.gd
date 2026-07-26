extends Node
class_name EnemyManager

const WALL_OCCLUSION_LAYERS := preload("res://scripts/arena/wall_occlusion_layers.gd")

signal enemy_defeated(enemy, score_value: int)
signal enemy_health_changed(enemy, old_value: int, new_value: int)
signal enemy_count_changed(count: int)
signal player_contact_requested(enemy, player, damage: int)
signal hostile_shot_requested(origin: Vector2, direction: Vector2, shot_config: Dictionary)
signal repair_requested(enemy, repair_target, amount: int)

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
var _spawner_repair_targets_provider: Callable
var _enemies: Array = []
var _contact_timers: Dictionary = {}
var _arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var _arena_shape: int = 0
var _wall_rects: Array[Rect2] = []
var _level_wall_rects: Array[Rect2] = []
var _void_rects: Array[Rect2] = []
var _playable_rects: Array[Rect2] = []
var _boss_add_timer: float = 0.0


func initialize(context: Dictionary) -> void:
	_enemy_layer = context.get("enemy_layer", null)
	_player_provider = context.get("player_position_provider", Callable())
	_player_ref_provider = context.get("player_ref_provider", Callable())
	_spawner_repair_targets_provider = context.get("spawner_repair_targets_provider", Callable())


func reset_run() -> void:
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()
	_contact_timers.clear()
	_boss_add_timer = 0.0
	enemy_count_changed.emit(0)


func offset_transient_enemies(offset: Vector2) -> void:
	if offset == Vector2.ZERO:
		return
	var parent: Node = _enemy_layer if _enemy_layer != null else self
	for child in parent.get_children():
		if not is_instance_valid(child) or not child is EnemyEntity:
			continue
		child.global_position += offset
		child.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)


func set_enabled(value: bool) -> void:
	enabled = value


func set_entities_active(value: bool, materialize_preloaded: bool = false) -> void:
	for enemy_node in _enemies:
		var enemy: EnemyEntity = enemy_node as EnemyEntity
		if enemy == null or not is_instance_valid(enemy):
			continue
		enemy.set_physics_process(value)
		if value and bool(enemy.get_meta("preloaded_hidden", false)):
			enemy.visible = true
			enemy.remove_meta("preloaded_hidden")
			if materialize_preloaded and enemy.has_method("play_birth_animation"):
				enemy.play_birth_animation(float(enemy.get_meta("preloaded_birth_duration", 0.42)))
			if enemy.has_meta("preloaded_birth_duration"):
				enemy.remove_meta("preloaded_birth_duration")
		if not value:
			enemy.velocity = Vector2.ZERO


func set_arena_definition(level_definition) -> void:
	if level_definition == null:
		return
	_arena_bounds = level_definition.arena_bounds
	_arena_shape = int(level_definition.arena_shape)
	_level_wall_rects = _get_level_collision_rects(level_definition, "active_room_wall_rects", level_definition.wall_rects)
	_wall_rects = _level_wall_rects.duplicate()
	_void_rects = _get_level_collision_rects(level_definition, "active_room_void_rects", level_definition.void_rects)
	_playable_rects = _get_playable_rects(level_definition)
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)


func set_dynamic_wall_rects(extra_wall_rects: Array[Rect2]) -> void:
	_wall_rects = _level_wall_rects.duplicate()
	_wall_rects.append_array(extra_wall_rects)
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var player_position := _get_player_position()
	var player = _get_player_ref()
	_assign_repair_targets()
	for enemy in _enemies.duplicate():
		if not is_instance_valid(enemy):
			_enemies.erase(enemy)
			continue
		enemy.set_target_position(player_position)
		var id: int = enemy.get_instance_id()
		_contact_timers[id] = max(float(_contact_timers.get(id, 0.0)) - delta, 0.0)
		if enemy.has_method("is_birth_animation_active") and bool(enemy.is_birth_animation_active()):
			continue
		if int(enemy.contact_damage) <= 0:
			continue
		if player != null and is_instance_valid(player):
			var contact_range: float = _get_effective_contact_range(enemy, player)
			if enemy.global_position.distance_squared_to(player.global_position) <= contact_range * contact_range and float(_contact_timers[id]) <= 0.0:
				_contact_timers[id] = enemy.contact_cooldown
				player_contact_requested.emit(enemy, player, enemy.contact_damage)
	_apply_crowd_separation()
	_update_boss_adds(delta)


func spawn_enemy(profile, spawn_position: Vector2, spawn_flags: Dictionary = {}):
	var allow_when_disabled: bool = bool(spawn_flags.get("allow_when_disabled", false))
	if not enabled and not allow_when_disabled:
		return null
	var enemy = enemy_scene.instantiate()
	WALL_OCCLUSION_LAYERS.mark_entity_tree(enemy)
	var selected_profile = profile if profile != null else default_enemy_profile
	enemy.initialize(selected_profile)
	enemy.global_position = _constrain_spawn_position(spawn_position, float(enemy.body_radius))
	enemy.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)
	if bool(spawn_flags.get("boss_add", false)):
		enemy.set_meta("boss_add", true)
	if bool(spawn_flags.get("birth", false)) and enemy.has_method("play_birth_animation"):
		enemy.play_birth_animation(float(spawn_flags.get("birth_duration", 0.36)))
	enemy.health_changed.connect(_on_enemy_health_changed)
	enemy.health_depleted.connect(_on_enemy_health_depleted)
	enemy.shot_ready.connect(_on_enemy_shot_ready)
	if enemy.has_signal("repair_ready"):
		enemy.repair_ready.connect(_on_enemy_repair_ready)
	_enemies.append(enemy)
	if bool(spawn_flags.get("inactive", false)):
		enemy.velocity = Vector2.ZERO
		enemy.visible = false
		enemy.set_meta("preloaded_hidden", true)
		enemy.set_meta("preloaded_birth_duration", float(spawn_flags.get("birth_duration", 0.42)))
		enemy.set_physics_process(false)
	enemy_count_changed.emit(_enemies.size())
	_add_child_safely(_get_enemy_parent(), enemy)
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


func _get_enemy_parent() -> Node:
	return _enemy_layer if _enemy_layer != null else self


func _add_child_safely(parent: Node, child: Node) -> void:
	if parent == null or child == null or child.get_parent() != null:
		return
	if parent.is_inside_tree() and Engine.is_in_physics_frame():
		parent.call_deferred("add_child", child)
		return
	parent.add_child(child)


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


func get_enemy_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for enemy in _enemies:
		if is_instance_valid(enemy):
			positions.append(enemy.global_position)
	return positions


func _on_enemy_health_depleted(enemy) -> void:
	if not _enemies.has(enemy):
		return
	_enemies.erase(enemy)
	_contact_timers.erase(enemy.get_instance_id())
	enemy_defeated.emit(enemy, enemy.score_value)
	enemy_count_changed.emit(_enemies.size())


func _on_enemy_health_changed(enemy, old_value: int, new_value: int) -> void:
	if not _enemies.has(enemy):
		return
	enemy_health_changed.emit(enemy, old_value, new_value)


func _on_enemy_shot_ready(_enemy, origin: Vector2, direction: Vector2, shot_config: Dictionary) -> void:
	if not enabled or direction.length_squared() <= 0.001:
		return
	hostile_shot_requested.emit(origin, direction, shot_config)


func _on_enemy_repair_ready(enemy, repair_target, amount: int) -> void:
	var repair_drone := enemy as EnemyEntity
	var target := repair_target as Node
	if not enabled or repair_drone == null or target == null:
		return
	if not _enemies.has(repair_drone):
		return
	if not is_instance_valid(repair_drone) or not is_instance_valid(target):
		return
	if amount <= 0 or not target.has_method("apply_healing"):
		return
	if target.is_in_group("enemies"):
		var enemy_target := target as EnemyEntity
		if enemy_target == null or not _enemies.has(enemy_target):
			return
		enemy_target.apply_healing(amount)
	elif target.is_in_group("spawners"):
		repair_requested.emit(repair_drone, target, amount)


func _assign_repair_targets() -> void:
	for enemy in _enemies:
		var repair_drone := enemy as EnemyEntity
		if repair_drone == null or not is_instance_valid(repair_drone):
			continue
		if repair_drone.behavior_kind != "repair_drone" or not repair_drone.has_method("set_repair_target"):
			continue
		repair_drone.set_repair_target(_get_repair_target_for(repair_drone))


func _get_repair_target_for(repair_drone: EnemyEntity) -> Node:
	if repair_drone == null or not is_instance_valid(repair_drone):
		return null
	var repair_radius: float = max(float(repair_drone.repair_radius), 1.0)
	var search_radius: float = max(repair_radius * 2.2, float(repair_drone.preferred_distance))
	var health_ratio_threshold: float = clamp(float(repair_drone.repair_target_health_ratio), 0.0, 1.0)
	var spawner_target := _get_spawner_repair_target_for(repair_drone, search_radius, health_ratio_threshold)
	if spawner_target != null:
		return spawner_target
	return _get_large_enemy_repair_target_for(repair_drone, search_radius, health_ratio_threshold)


func _get_spawner_repair_target_for(repair_drone: EnemyEntity, search_radius: float, health_ratio_threshold: float) -> Node:
	if not _spawner_repair_targets_provider.is_valid():
		return null
	var candidates: Array = _spawner_repair_targets_provider.call(repair_drone.global_position, search_radius, health_ratio_threshold)
	var best_target: Node = null
	var best_score := INF
	for candidate in candidates:
		var target := candidate as Node2D
		if target == null or not is_instance_valid(target) or not target.has_method("apply_healing"):
			continue
		var score: float = _get_repair_target_score(repair_drone, target)
		if score < best_score:
			best_score = score
			best_target = target
	return best_target


func _get_large_enemy_repair_target_for(repair_drone: EnemyEntity, search_radius: float, health_ratio_threshold: float) -> EnemyEntity:
	var search_radius_squared: float = search_radius * search_radius
	var best_target: EnemyEntity = null
	var best_score := INF
	for candidate in _enemies:
		var candidate_enemy := candidate as EnemyEntity
		if candidate_enemy == null or not is_instance_valid(candidate_enemy) or candidate_enemy == repair_drone:
			continue
		if not _is_priority_repair_enemy(candidate_enemy):
			continue
		if not candidate_enemy.has_method("apply_healing"):
			continue
		if candidate_enemy.health <= 0 or candidate_enemy.health >= candidate_enemy.max_health:
			continue
		var distance_squared: float = repair_drone.global_position.distance_squared_to(candidate_enemy.global_position)
		if distance_squared > search_radius_squared:
			continue
		var health_ratio: float = float(candidate_enemy.health) / float(max(candidate_enemy.max_health, 1))
		if health_ratio > health_ratio_threshold:
			continue
		var score: float = health_ratio * 10000.0 + sqrt(distance_squared)
		if score < best_score:
			best_score = score
			best_target = candidate_enemy
	return best_target


func _get_repair_target_score(repair_drone: EnemyEntity, target: Node2D) -> float:
	var target_health: int = int(target.get("health"))
	var target_max_health: int = max(int(target.get("max_health")), 1)
	var health_ratio: float = float(target_health) / float(target_max_health)
	return health_ratio * 10000.0 + sqrt(repair_drone.global_position.distance_squared_to(target.global_position))


func _is_priority_repair_enemy(enemy: EnemyEntity) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	match String(enemy.behavior_kind):
		"boss", "power_armor", "cyber_soldier":
			return true
	return float(enemy.body_radius) >= 24.0 or int(enemy.max_health) >= 8


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
	if valid_enemies.size() < 2:
		return
	var bucket_size := _get_crowd_separation_bucket_size(valid_enemies)
	var buckets: Dictionary = {}
	for index in range(valid_enemies.size()):
		var enemy = valid_enemies[index]
		var key := _crowd_bucket_key(enemy.global_position, bucket_size)
		var bucket: Array = buckets.get(key, [])
		bucket.append(index)
		buckets[key] = bucket
	for first_index in range(valid_enemies.size()):
		var first = valid_enemies[first_index]
		var base_cell := _crowd_bucket_cell(first.global_position, bucket_size)
		for offset_x in range(-1, 2):
			for offset_y in range(-1, 2):
				var key := "%d,%d" % [base_cell.x + offset_x, base_cell.y + offset_y]
				var bucket: Array = buckets.get(key, [])
				for second_index in bucket:
					if int(second_index) <= first_index:
						continue
					_apply_crowd_separation_pair(first_index, int(second_index), valid_enemies, pushes)
	for index in range(valid_enemies.size()):
		if pushes[index].length_squared() > 0.001:
			valid_enemies[index].apply_crowd_separation(pushes[index])


func _apply_crowd_separation_pair(first_index: int, second_index: int, valid_enemies: Array, pushes: Array[Vector2]) -> void:
	var first = valid_enemies[first_index]
	var second = valid_enemies[second_index]
	var separation: Vector2 = first.global_position - second.global_position
	var desired_distance: float = float(first.body_radius) + float(second.body_radius) + crowd_separation_padding
	var distance_squared: float = separation.length_squared()
	if distance_squared > desired_distance * desired_distance:
		return
	var direction: Vector2 = Vector2.RIGHT.rotated(float((first.get_instance_id() + second.get_instance_id()) % 628) * 0.01)
	var distance: float = 0.0
	if distance_squared > 0.001:
		distance = sqrt(distance_squared)
		direction = separation / distance
	var strength: float = (1.0 - clamp(distance / desired_distance, 0.0, 1.0)) * crowd_separation_force
	pushes[first_index] += direction * strength
	pushes[second_index] -= direction * strength


func _get_crowd_separation_bucket_size(valid_enemies: Array) -> float:
	var largest_body_radius := 0.0
	for enemy in valid_enemies:
		largest_body_radius = max(largest_body_radius, float(enemy.body_radius))
	return max(96.0, largest_body_radius * 2.0 + crowd_separation_padding + 16.0)


func _crowd_bucket_key(position: Vector2, bucket_size: float) -> String:
	var cell := _crowd_bucket_cell(position, bucket_size)
	return "%d,%d" % [cell.x, cell.y]


func _crowd_bucket_cell(position: Vector2, bucket_size: float) -> Vector2i:
	return Vector2i(floori(position.x / bucket_size), floori(position.y / bucket_size))


func _update_boss_adds(delta: float) -> void:
	if boss_add_target_count <= 0 or boss_add_profile == null:
		return
	var boss = _get_alive_boss()
	if boss == null:
		_boss_add_timer = 0.0
		return
	if boss.get("agent_program") != null:
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
	return _constrain_spawn_position(boss.global_position + Vector2.RIGHT.rotated(angle) * radius, 24.0)


func _constrain_spawn_position(position: Vector2, clearance: float) -> Vector2:
	var blockers: Array[Rect2] = []
	blockers.append_array(_wall_rects)
	blockers.append_array(_void_rects)
	return ArenaGeometry.constrain_point_to_playable_regions(position, _arena_bounds, _arena_shape, _playable_rects, blockers, clearance)


func _get_playable_rects(level_definition) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if level_definition == null:
		return rects
	if level_definition.has_meta("active_room_playable_rects"):
		var active_rects_value: Variant = level_definition.get_meta("active_room_playable_rects")
		if active_rects_value is Array:
			for active_rect in active_rects_value:
				if active_rect is Rect2:
					rects.append(active_rect)
			if not rects.is_empty():
				return rects
	if not level_definition.has_meta("footprint_cells"):
		return rects
	rects.append_array(ArenaGeometry.get_footprint_cell_rects(level_definition.arena_bounds, level_definition.get_meta("footprint_cells")))
	return rects


func _get_level_collision_rects(level_definition, meta_key: String, fallback: Array[Rect2]) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if level_definition != null and level_definition.has_meta(meta_key):
		var meta_value: Variant = level_definition.get_meta(meta_key)
		if meta_value is Array:
			for rect in meta_value:
				if rect is Rect2:
					rects.append(rect)
			if not rects.is_empty():
				return rects
	rects.append_array(fallback)
	return rects
