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

@export var pickup_scene: PackedScene = preload("res://scenes/entities/pickup_entity.tscn")
@export var pickup_spawn_interval: float = 10.0
@export var enemy_permanent_drop_chance: float = 0.42
@export var enemy_temporary_drop_chance: float = 0.12

var enabled: bool = false
var upgrade_effects: Array = [SPREAD_SHOT, PIERCING_SHOT, CHAIN_LIGHTNING, FIRE_BURST, WATER_SWELL]
var permanent_upgrades: Array = [FASTER_REFLEXES, RUNNER_LEGS, HEAVY_TEARS, FAT_TEARS]
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
	var positions := [
		Vector2(-240.0, 0.0),
		Vector2(240.0, 0.0),
		Vector2(0.0, -190.0)
	]
	for index in range(positions.size()):
		spawn_pickup(upgrade_effects[index % upgrade_effects.size()], positions[index])
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
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = pickup_spawn_interval
		var effect = upgrade_effects[_effect_index % upgrade_effects.size()]
		_effect_index += 1
		var position := Vector2(_rng.randf_range(-430.0, 430.0), _rng.randf_range(-240.0, 240.0))
		spawn_pickup(effect, position)


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
	var roll := _rng.randf()
	if roll < enemy_temporary_drop_chance:
		spawn_pickup(_choose_temporary_upgrade(), _jitter_drop_position(enemy_position))
	elif roll < enemy_temporary_drop_chance + enemy_permanent_drop_chance:
		spawn_pickup(_choose_permanent_upgrade(), _jitter_drop_position(enemy_position))


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


func _jitter_drop_position(origin: Vector2) -> Vector2:
	return origin + Vector2(_rng.randf_range(-22.0, 22.0), _rng.randf_range(-22.0, 22.0))
