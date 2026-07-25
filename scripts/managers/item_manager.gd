extends Node
class_name ItemManager

signal pickup_collected(effect)
signal pickup_count_changed(count: int)
signal reward_focus_changed(effect, description: String)

const SPREAD_SHOT := preload("res://resources/upgrades/spread_shot.tres")
const PIERCING_SHOT := preload("res://resources/upgrades/piercing_shot.tres")
const CHAIN_LIGHTNING := preload("res://resources/upgrades/chain_lightning.tres")
const FIRE_BURST := preload("res://resources/upgrades/fire_burst.tres")
const WATER_SWELL := preload("res://resources/upgrades/water_swell.tres")
const FASTER_REFLEXES := preload("res://resources/permanent_upgrades/faster_reflexes.tres")
const RUNNER_LEGS := preload("res://resources/permanent_upgrades/runner_legs.tres")
const HEAVY_TEARS := preload("res://resources/permanent_upgrades/heavy_tears.tres")
const FAT_TEARS := preload("res://resources/permanent_upgrades/fat_tears.tres")
const OVERDRIVE_CAPACITY := preload("res://resources/permanent_upgrades/overdrive_capacity.tres")
const MINOR_FASTER_REFLEXES := preload("res://resources/permanent_upgrades/minor_faster_reflexes.tres")
const MINOR_RUNNER_LEGS := preload("res://resources/permanent_upgrades/minor_runner_legs.tres")
const MINOR_HEAVY_TEARS := preload("res://resources/permanent_upgrades/minor_heavy_tears.tres")
const MINOR_FAT_TEARS := preload("res://resources/permanent_upgrades/minor_fat_tears.tres")
const MINOR_OVERDRIVE_CAPACITY := preload("res://resources/permanent_upgrades/minor_overdrive_capacity.tres")
const SMALL_HEAL := preload("res://resources/pickups/small_heal.tres")
const FULL_HEAL := preload("res://resources/pickups/full_heal.tres")
const OVERDRIVE_AMMO := preload("res://resources/pickups/overdrive_ammo.tres")
const OVERDRIVE_AMMO_CACHE := preload("res://resources/pickups/overdrive_ammo_cache.tres")

@export var pickup_scene: PackedScene = preload("res://scenes/entities/pickup_entity.tscn")
@export var pickup_spawn_interval: float = 10.0
@export var enemy_permanent_drop_chance: float = 0.0
@export var enemy_temporary_drop_chance: float = 0.0
@export var enemy_overdrive_ammo_drop_chance: float = 0.03
@export var enemy_heal_drop_chance: float = 0.08
@export var spawner_full_heal_drop_chance: float = 0.16

var enabled: bool = false
var upgrade_effects: Array = [SPREAD_SHOT, PIERCING_SHOT, CHAIN_LIGHTNING, FIRE_BURST, WATER_SWELL]
var permanent_upgrades: Array = [FASTER_REFLEXES, RUNNER_LEGS, HEAVY_TEARS, FAT_TEARS, OVERDRIVE_CAPACITY]
var minor_permanent_upgrades: Array = [MINOR_FASTER_REFLEXES, MINOR_RUNNER_LEGS, MINOR_HEAVY_TEARS, MINOR_FAT_TEARS, MINOR_OVERDRIVE_CAPACITY]
var healing_pickups: Array = [SMALL_HEAL]
var full_heal_pickup = FULL_HEAL
var overdrive_ammo_pickup = OVERDRIVE_AMMO
var overdrive_ammo_cache_pickup = OVERDRIVE_AMMO_CACHE
var _pickup_layer: Node = null
var _pickups: Array = []
var _rng := RandomNumberGenerator.new()
var _spawn_timer: float = 0.0
var _effect_index: int = 0
var _reward_choice_group_index: int = 0
var _choice_groups: Dictionary = {}
var _focused_reward_pickup = null
var _current_floor: int = 0
var _current_room_id: String = ""
var _persistent_permanent_pickups: Dictionary = {}


func initialize(context: Dictionary) -> void:
	_pickup_layer = context.get("pickup_layer", null)
	_rng.seed = 1907


func reset_run() -> void:
	clear_pickups()
	clear_floor_persistent_pickups()
	_spawn_timer = pickup_spawn_interval
	_effect_index = 0
	_reward_choice_group_index = 0
	pickup_count_changed.emit(_pickups.size())


func clear_pickups() -> void:
	for pickup in _pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	_pickups.clear()
	_choice_groups.clear()
	_focused_reward_pickup = null
	reward_focus_changed.emit(null, "")
	pickup_count_changed.emit(0)


func clear_floor_persistent_pickups() -> void:
	_persistent_permanent_pickups.clear()


func set_room_context(floor_number: int, room_id: String) -> void:
	_current_floor = floor_number
	_current_room_id = room_id


func rehydrate_current_room_permanent_pickups() -> void:
	if _current_room_id.is_empty():
		return
	var room_key := _get_current_room_persistent_key()
	var saved_pickups: Array = _persistent_permanent_pickups.get(room_key, [])
	for saved in saved_pickups:
		var data := Dictionary(saved)
		_spawn_pickup_from_persistent_data(data)
	pickup_count_changed.emit(_pickups.size())


func rehydrate_floor_permanent_pickups() -> void:
	if _current_floor <= 0:
		return
	var floor_prefix := "%d:" % _current_floor
	for room_key in _persistent_permanent_pickups.keys():
		if not String(room_key).begins_with(floor_prefix):
			continue
		var saved_pickups: Array = _persistent_permanent_pickups.get(room_key, [])
		for saved in saved_pickups:
			var data: Dictionary = Dictionary(saved)
			_spawn_pickup_from_persistent_data(data)
	pickup_count_changed.emit(_pickups.size())


func offset_active_pickups(offset: Vector2) -> void:
	if offset == Vector2.ZERO:
		return
	for pickup in _pickups:
		if not is_instance_valid(pickup):
			continue
		pickup.global_position += offset
		_update_persistent_pickup_position(pickup)
	pickup_count_changed.emit(_pickups.size())


func set_enabled(value: bool) -> void:
	enabled = value


func _process(delta: float) -> void:
	if not enabled:
		return
	_spawn_timer = max(_spawn_timer - delta, 0.0)


func spawn_pickup(effect, spawn_position: Vector2, requires_confirm: bool = false, choice_group_id: String = "", persist_for_floor: bool = false):
	persist_for_floor = persist_for_floor or _should_persist_for_floor(effect)
	var pickup = pickup_scene.instantiate()
	pickup.initialize(effect, spawn_position, requires_confirm, choice_group_id, persist_for_floor)
	pickup.collected.connect(_on_pickup_collected)
	pickup.expired.connect(_on_pickup_expired)
	if pickup.has_signal("focused"):
		pickup.focused.connect(_on_pickup_focused)
	if pickup.has_signal("focus_exited"):
		pickup.focus_exited.connect(_on_pickup_focus_exited)
	_pickups.append(pickup)
	if requires_confirm and not choice_group_id.is_empty():
		var group: Array = _choice_groups.get(choice_group_id, [])
		group.append(pickup)
		_choice_groups[choice_group_id] = group
	if persist_for_floor:
		_register_persistent_pickup(pickup, effect, spawn_position, requires_confirm, choice_group_id)
	pickup_count_changed.emit(_pickups.size())
	_add_child_safely(_get_pickup_parent(), pickup)
	return pickup


func roll_enemy_drop(enemy_position: Vector2) -> void:
	if not enabled:
		return
	if _rng.randf() < enemy_heal_drop_chance:
		spawn_pickup(_choose_heal_pickup(), _jitter_drop_position(enemy_position))
	if _rng.randf() < enemy_overdrive_ammo_drop_chance:
		spawn_pickup(overdrive_ammo_pickup, _jitter_drop_position(enemy_position))


func drop_spawner_reward(spawner_position: Vector2) -> void:
	if not enabled:
		return
	if _rng.randf() < spawner_full_heal_drop_chance:
		spawn_pickup(full_heal_pickup, _jitter_drop_position(spawner_position))
	else:
		spawn_pickup(overdrive_ammo_cache_pickup, _jitter_drop_position(spawner_position))


func drop_destructible_reward(prop_position: Vector2, drop_kind: String) -> void:
	if not enabled:
		return
	match drop_kind:
		"treasure":
			var roll := _rng.randf()
			if roll < 0.34:
				spawn_pickup(_choose_minor_permanent_upgrade(), _jitter_drop_position(prop_position))
			elif roll < 0.66:
				spawn_pickup(full_heal_pickup, _jitter_drop_position(prop_position))
			else:
				spawn_pickup(overdrive_ammo_cache_pickup, _jitter_drop_position(prop_position))
		"minor":
			var roll := _rng.randf()
			if roll < 0.14:
				spawn_pickup(_choose_heal_pickup(), _jitter_drop_position(prop_position))
			elif roll < 0.28:
				spawn_pickup(overdrive_ammo_pickup, _jitter_drop_position(prop_position))


func get_pickup_count() -> int:
	return _pickups.size()


func spawn_overdrive_reward_choices(center_position: Vector2) -> void:
	_spawn_reward_choices(_choose_unique_rewards(upgrade_effects, 3), center_position)


func spawn_treasure_reward_choices(center_position: Vector2) -> void:
	_spawn_reward_choices(_roll_permanent_rewards(_choose_unique_rewards(permanent_upgrades, 3)), center_position)


func collect_focused_reward() -> bool:
	if _focused_reward_pickup == null or not is_instance_valid(_focused_reward_pickup):
		_focused_reward_pickup = null
		reward_focus_changed.emit(null, "")
		return false
	if not bool(_focused_reward_pickup.get("requires_confirm")):
		return false
	if _focused_reward_pickup.has_method("confirm_collect"):
		_focused_reward_pickup.confirm_collect()
		return true
	return false


func _on_pickup_collected(pickup, _collector: Node, effect) -> void:
	_pickups.erase(pickup)
	var choice_group_id := String(pickup.get("choice_group_id")) if pickup != null else ""
	if not choice_group_id.is_empty():
		_clear_persistent_choice_group(choice_group_id)
		_clear_choice_group(choice_group_id, pickup)
	else:
		_clear_persistent_pickup(pickup)
	if pickup == _focused_reward_pickup:
		_focused_reward_pickup = null
		reward_focus_changed.emit(null, "")
	pickup_collected.emit(effect)
	pickup_count_changed.emit(_pickups.size())


func _on_pickup_expired(pickup) -> void:
	_pickups.erase(pickup)
	if pickup == _focused_reward_pickup:
		_focused_reward_pickup = null
		reward_focus_changed.emit(null, "")
	pickup_count_changed.emit(_pickups.size())


func _choose_temporary_upgrade():
	return upgrade_effects[_rng.randi_range(0, upgrade_effects.size() - 1)]


func _choose_permanent_upgrade():
	return _roll_permanent_reward(permanent_upgrades[_rng.randi_range(0, permanent_upgrades.size() - 1)])


func _choose_minor_permanent_upgrade():
	return _roll_permanent_reward(minor_permanent_upgrades[_rng.randi_range(0, minor_permanent_upgrades.size() - 1)])


func _choose_heal_pickup():
	return healing_pickups[_rng.randi_range(0, healing_pickups.size() - 1)]


func _jitter_drop_position(origin: Vector2) -> Vector2:
	return origin + Vector2(_rng.randf_range(-22.0, 22.0), _rng.randf_range(-22.0, 22.0))


func _spawn_reward_choices(options: Array, center_position: Vector2) -> void:
	if options.is_empty():
		return
	_reward_choice_group_index += 1
	var group_id := "reward_choice_%d" % _reward_choice_group_index
	var spacing := 72.0
	var start_x := -spacing * float(options.size() - 1) * 0.5
	for index in range(options.size()):
		var offset := Vector2(start_x + float(index) * spacing, 0.0)
		spawn_pickup(options[index], center_position + offset, true, group_id, true)


func _choose_unique_rewards(pool: Array, count: int) -> Array:
	var available := pool.duplicate()
	var choices: Array = []
	while not available.is_empty() and choices.size() < count:
		var index := _rng.randi_range(0, available.size() - 1)
		choices.append(available[index])
		available.remove_at(index)
	return choices


func _roll_permanent_rewards(options: Array) -> Array:
	var rolled_options: Array = []
	for option in options:
		rolled_options.append(_roll_permanent_reward(option))
	return rolled_options


func _roll_permanent_reward(option):
	if option != null and option.has_method("create_rolled_copy"):
		return option.create_rolled_copy(_rng)
	return option


func _on_pickup_focused(pickup, _collector: Node, effect) -> void:
	if pickup == null or not bool(pickup.get("requires_confirm")):
		return
	_focused_reward_pickup = pickup
	reward_focus_changed.emit(effect, _get_reward_description(effect))


func _on_pickup_focus_exited(pickup, _collector: Node, _effect) -> void:
	if pickup != _focused_reward_pickup:
		return
	_focused_reward_pickup = null
	reward_focus_changed.emit(null, "")


func _clear_choice_group(choice_group_id: String, selected_pickup) -> void:
	if choice_group_id.is_empty() or not _choice_groups.has(choice_group_id):
		return
	var group: Array = _choice_groups[choice_group_id]
	for pickup in group:
		if pickup == selected_pickup:
			continue
		_pickups.erase(pickup)
		if is_instance_valid(pickup):
			pickup.queue_free()
	_choice_groups.erase(choice_group_id)


func _should_persist_for_floor(effect) -> bool:
	if effect == null or _current_room_id.is_empty():
		return false
	if not effect.has_method("get_pickup_kind"):
		return false
	return String(effect.get_pickup_kind()) == "permanent"


func _register_persistent_pickup(pickup, effect, spawn_position: Vector2, requires_confirm: bool, choice_group_id: String) -> void:
	var room_key := _get_current_room_persistent_key()
	var persistent_id := "%s_pickup_%d" % [room_key, _get_persistent_room_pickups(room_key).size()]
	pickup.set_meta("persistent_pickup_id", persistent_id)
	var data := {
		"id": persistent_id,
		"effect": effect,
		"position": spawn_position,
		"requires_confirm": requires_confirm,
		"choice_group_id": choice_group_id
	}
	var saved_pickups := _get_persistent_room_pickups(room_key)
	saved_pickups.append(data)
	_persistent_permanent_pickups[room_key] = saved_pickups


func _spawn_pickup_from_persistent_data(data: Dictionary):
	var pickup = pickup_scene.instantiate()
	var effect = data.get("effect", null)
	var spawn_position: Vector2 = data.get("position", Vector2.ZERO)
	var requires_confirm := bool(data.get("requires_confirm", false))
	var choice_group_id := String(data.get("choice_group_id", ""))
	pickup.initialize(effect, spawn_position, requires_confirm, choice_group_id, true)
	pickup.set_meta("persistent_pickup_id", String(data.get("id", "")))
	pickup.collected.connect(_on_pickup_collected)
	pickup.expired.connect(_on_pickup_expired)
	if pickup.has_signal("focused"):
		pickup.focused.connect(_on_pickup_focused)
	if pickup.has_signal("focus_exited"):
		pickup.focus_exited.connect(_on_pickup_focus_exited)
	_pickups.append(pickup)
	if requires_confirm and not choice_group_id.is_empty():
		var group: Array = _choice_groups.get(choice_group_id, [])
		group.append(pickup)
		_choice_groups[choice_group_id] = group
	_add_child_safely(_get_pickup_parent(), pickup)
	return pickup


func _get_pickup_parent() -> Node:
	return _pickup_layer if _pickup_layer != null else self


func _add_child_safely(parent: Node, child: Node) -> void:
	if parent == null or child == null or child.get_parent() != null:
		return
	if parent.is_inside_tree() and Engine.is_in_physics_frame():
		parent.call_deferred("add_child", child)
		return
	parent.add_child(child)


func _clear_persistent_pickup(pickup) -> void:
	if pickup == null or not pickup.has_meta("persistent_pickup_id"):
		return
	var persistent_id := String(pickup.get_meta("persistent_pickup_id"))
	for room_key in _persistent_permanent_pickups.keys():
		var saved_pickups: Array = _get_persistent_room_pickups(String(room_key))
		for index in range(saved_pickups.size() - 1, -1, -1):
			var data: Dictionary = Dictionary(saved_pickups[index])
			if String(data.get("id", "")) == persistent_id:
				saved_pickups.remove_at(index)
		_persistent_permanent_pickups[String(room_key)] = saved_pickups


func _clear_persistent_choice_group(choice_group_id: String) -> void:
	for room_key in _persistent_permanent_pickups.keys():
		var saved_pickups: Array = _get_persistent_room_pickups(String(room_key))
		for index in range(saved_pickups.size() - 1, -1, -1):
			var data: Dictionary = Dictionary(saved_pickups[index])
			if String(data.get("choice_group_id", "")) == choice_group_id:
				saved_pickups.remove_at(index)
		_persistent_permanent_pickups[String(room_key)] = saved_pickups


func _update_persistent_pickup_position(pickup) -> void:
	if pickup == null or not pickup.has_meta("persistent_pickup_id"):
		return
	var persistent_id := String(pickup.get_meta("persistent_pickup_id"))
	for room_key in _persistent_permanent_pickups.keys():
		var saved_pickups: Array = _get_persistent_room_pickups(String(room_key))
		var changed: bool = false
		for index in range(saved_pickups.size()):
			var data: Dictionary = Dictionary(saved_pickups[index])
			if String(data.get("id", "")) == persistent_id:
				data["position"] = pickup.global_position
				saved_pickups[index] = data
				changed = true
		if changed:
			_persistent_permanent_pickups[String(room_key)] = saved_pickups


func _get_persistent_room_pickups(room_key: String) -> Array:
	return _persistent_permanent_pickups.get(room_key, []).duplicate()


func _get_current_room_persistent_key() -> String:
	return "%d:%s" % [_current_floor, _current_room_id]


func _get_reward_description(effect) -> String:
	if effect == null:
		return ""
	if effect.has_method("get_reward_description"):
		return effect.get_reward_description()
	if effect.get("display_name") != null:
		return String(effect.display_name)
	return "Reward"
