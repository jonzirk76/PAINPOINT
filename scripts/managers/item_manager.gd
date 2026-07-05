extends Node
class_name ItemManager

signal pickup_collected(effect)
signal pickup_count_changed(count: int)

const SPREAD_SHOT := preload("res://resources/upgrades/spread_shot.tres")
const PIERCING_SHOT := preload("res://resources/upgrades/piercing_shot.tres")
const CHAIN_LIGHTNING := preload("res://resources/upgrades/chain_lightning.tres")
const FIRE_BURST := preload("res://resources/upgrades/fire_burst.tres")
const WATER_SWELL := preload("res://resources/upgrades/water_swell.tres")
const FASTER_REFLEXES := preload("res://resources/permanent_upgrades/faster_reflexes.tres")
const RUNNER_LEGS := preload("res://resources/permanent_upgrades/runner_legs.tres")
const HEAVY_TEARS := preload("res://resources/permanent_upgrades/heavy_tears.tres")
const FAT_TEARS := preload("res://resources/permanent_upgrades/fat_tears.tres")
const SMALL_HEAL := preload("res://resources/pickups/small_heal.tres")
const FULL_HEAL := preload("res://resources/pickups/full_heal.tres")

@export var pickup_scene: PackedScene = preload("res://scenes/entities/pickup_entity.tscn")
@export var pickup_spawn_interval: float = 10.0
@export var enemy_permanent_drop_chance: float = 0.18
@export var enemy_temporary_drop_chance: float = 0.055
@export var enemy_heal_drop_chance: float = 0.1
@export var spawner_full_heal_drop_chance: float = 0.16

var enabled: bool = false
var upgrade_effects: Array = [SPREAD_SHOT, PIERCING_SHOT, CHAIN_LIGHTNING, FIRE_BURST, WATER_SWELL]
var permanent_upgrades: Array = [FASTER_REFLEXES, RUNNER_LEGS, HEAVY_TEARS, FAT_TEARS]
var healing_pickups: Array = [SMALL_HEAL]
var full_heal_pickup = FULL_HEAL
var _pickup_layer: Node = null
var _pickups: Array = []
var _rng := RandomNumberGenerator.new()
var _spawn_timer: float = 0.0
var _effect_index: int = 0


func initialize(context: Dictionary) -> void:
	_pickup_layer = context.get("pickup_layer", null)
	_rng.seed = 1907


func reset_run() -> void:
	clear_pickups()
	_spawn_timer = pickup_spawn_interval
	_effect_index = 0
	pickup_count_changed.emit(_pickups.size())


func clear_pickups() -> void:
	for pickup in _pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	_pickups.clear()
	pickup_count_changed.emit(0)


func set_enabled(value: bool) -> void:
	enabled = value


func _process(delta: float) -> void:
	if not enabled:
		return
	_spawn_timer = max(_spawn_timer - delta, 0.0)


func spawn_pickup(effect, spawn_position: Vector2):
	var pickup = pickup_scene.instantiate()
	if _pickup_layer != null:
		_pickup_layer.add_child(pickup)
	else:
		add_child(pickup)
	pickup.initialize(effect, spawn_position)
	pickup.collected.connect(_on_pickup_collected)
	pickup.expired.connect(_on_pickup_expired)
	_pickups.append(pickup)
	pickup_count_changed.emit(_pickups.size())
	return pickup


func roll_enemy_drop(enemy_position: Vector2) -> void:
	if not enabled:
		return
	if _rng.randf() < enemy_temporary_drop_chance:
		spawn_pickup(_choose_temporary_upgrade(), _jitter_drop_position(enemy_position))
	if _rng.randf() < enemy_permanent_drop_chance:
		spawn_pickup(_choose_permanent_upgrade(), _jitter_drop_position(enemy_position))
	if _rng.randf() < enemy_heal_drop_chance:
		spawn_pickup(_choose_heal_pickup(), _jitter_drop_position(enemy_position))


func drop_spawner_reward(spawner_position: Vector2) -> void:
	if not enabled:
		return
	if _rng.randf() < spawner_full_heal_drop_chance:
		spawn_pickup(full_heal_pickup, _jitter_drop_position(spawner_position))
	else:
		spawn_pickup(_choose_temporary_upgrade(), _jitter_drop_position(spawner_position))


func drop_destructible_reward(prop_position: Vector2, drop_kind: String) -> void:
	if not enabled:
		return
	match drop_kind:
		"treasure":
			var roll := _rng.randf()
			if roll < 0.42:
				spawn_pickup(_choose_temporary_upgrade(), _jitter_drop_position(prop_position))
			elif roll < 0.76:
				spawn_pickup(_choose_permanent_upgrade(), _jitter_drop_position(prop_position))
			else:
				spawn_pickup(_choose_heal_pickup(), _jitter_drop_position(prop_position))
		"minor":
			if _rng.randf() < 0.22:
				spawn_pickup(_choose_heal_pickup(), _jitter_drop_position(prop_position))


func get_pickup_count() -> int:
	return _pickups.size()


func _on_pickup_collected(pickup, _collector: Node, effect) -> void:
	_pickups.erase(pickup)
	pickup_collected.emit(effect)
	pickup_count_changed.emit(_pickups.size())


func _on_pickup_expired(pickup) -> void:
	_pickups.erase(pickup)
	pickup_count_changed.emit(_pickups.size())


func _choose_temporary_upgrade():
	return upgrade_effects[_rng.randi_range(0, upgrade_effects.size() - 1)]


func _choose_permanent_upgrade():
	return permanent_upgrades[_rng.randi_range(0, permanent_upgrades.size() - 1)]


func _choose_heal_pickup():
	return healing_pickups[_rng.randi_range(0, healing_pickups.size() - 1)]


func _jitter_drop_position(origin: Vector2) -> Vector2:
	return origin + Vector2(_rng.randf_range(-22.0, 22.0), _rng.randf_range(-22.0, 22.0))
