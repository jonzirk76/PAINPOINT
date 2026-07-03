extends Node
class_name EffectsManager

@export var chain_lightning_scene: PackedScene = preload("res://scenes/entities/chain_lightning_effect.tscn")
@export var explosion_scene: PackedScene = preload("res://scenes/entities/explosion_effect.tscn")
@export var parry_absorb_scene: PackedScene = preload("res://scenes/entities/parry_absorb_effect.tscn")
@export var max_active_effects: int = 80

var enabled: bool = false
var _effect_layer: Node = null
var _effects: Array = []


func initialize(context: Dictionary) -> void:
	_effect_layer = context.get("effect_layer", null)


func reset_run() -> void:
	for effect in _effects:
		if is_instance_valid(effect):
			effect.queue_free()
	_effects.clear()


func set_enabled(value: bool) -> void:
	enabled = value


func play_chain_lightning(from_position: Vector2, to_position: Vector2) -> void:
	if not enabled:
		return
	_trim_effects()
	var effect = chain_lightning_scene.instantiate()
	effect.process_mode = Node.PROCESS_MODE_ALWAYS
	if _effect_layer != null:
		_effect_layer.add_child(effect)
	else:
		add_child(effect)
	effect.initialize(from_position, to_position)
	effect.expired.connect(_on_effect_expired)
	_effects.append(effect)


func play_explosion(spawn_position: Vector2, radius: float, lifetime: float = -1.0) -> void:
	if not enabled:
		return
	_trim_effects()
	var effect = explosion_scene.instantiate()
	effect.process_mode = Node.PROCESS_MODE_ALWAYS
	if _effect_layer != null:
		_effect_layer.add_child(effect)
	else:
		add_child(effect)
	effect.initialize(spawn_position, radius, lifetime)
	effect.expired.connect(_on_effect_expired)
	_effects.append(effect)


func play_spawner_explosion(spawn_position: Vector2, radius: float) -> void:
	play_explosion(spawn_position, radius, 0.55)


func play_parry_absorbs(absorbed_projectiles: Array, default_target_position: Vector2) -> void:
	for info in absorbed_projectiles:
		if info is Dictionary:
			var target_position: Vector2 = info.get("target_position", default_target_position)
			play_parry_absorb(
				info.get("position", target_position),
				target_position,
				bool(info.get("perfect", false)),
				float(info.get("radius", 7.0)),
				float(info.get("arc_seed", 0.0))
			)


func play_parry_absorb(from_position: Vector2, to_position: Vector2, is_perfect: bool, radius: float = 7.0, arc_seed: float = 0.0) -> void:
	if not enabled:
		return
	_trim_effects()
	var effect = parry_absorb_scene.instantiate()
	effect.process_mode = Node.PROCESS_MODE_ALWAYS
	if _effect_layer != null:
		_effect_layer.add_child(effect)
	else:
		add_child(effect)
	effect.initialize(from_position, to_position, is_perfect, radius, arc_seed)
	effect.expired.connect(_on_effect_expired)
	_effects.append(effect)


func _on_effect_expired(effect) -> void:
	_effects.erase(effect)


func _trim_effects() -> void:
	while _effects.size() >= max_active_effects:
		var oldest = _effects.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
