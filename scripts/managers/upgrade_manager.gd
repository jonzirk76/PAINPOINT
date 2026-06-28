extends Node
class_name UpgradeManager

signal upgrade_changed(modifiers: Dictionary, active_effects: Array)
signal permanent_upgrades_changed(attribute_modifiers: Dictionary, permanent_stats: Array)
signal upgrade_expired(effect)

var enabled: bool = false
var _active_effects: Dictionary = {}
var _permanent_upgrades: Dictionary = {}


func initialize(_context: Dictionary) -> void:
	pass


func reset_run() -> void:
	_active_effects.clear()
	_permanent_upgrades.clear()
	permanent_upgrades_changed.emit(get_attribute_modifiers(), get_permanent_stats())
	upgrade_changed.emit(get_modifiers(), get_active_effects())


func set_enabled(value: bool) -> void:
	enabled = value


func _process(delta: float) -> void:
	if not enabled or _active_effects.is_empty():
		return
	var expired_ids: Array[String] = []
	for id in _active_effects.keys():
		var state: Dictionary = _active_effects[id]
		var effect = state["effect"]
		if int(effect.max_ammo) > 0 or float(effect.duration_seconds) <= 0.0:
			continue
		state["remaining"] = float(state["remaining"]) - delta
		_active_effects[id] = state
		if float(state["remaining"]) <= 0.0:
			expired_ids.append(id)
	for id in expired_ids:
		var state: Dictionary = _active_effects[id]
		var effect = state["effect"]
		_active_effects.erase(id)
		upgrade_expired.emit(effect)
	if not expired_ids.is_empty():
		upgrade_changed.emit(get_modifiers(), get_active_effects())


func activate_upgrade(effect) -> void:
	if effect == null:
		return
	_active_effects[effect.id] = {
		"effect": effect,
		"remaining": effect.duration_seconds,
		"ammo": effect.max_ammo
	}
	upgrade_changed.emit(get_modifiers(), get_active_effects())


func activate_pickup(pickup_resource) -> void:
	if pickup_resource == null:
		return
	if pickup_resource.has_method("get_pickup_kind") and pickup_resource.get_pickup_kind() == "permanent":
		activate_permanent_upgrade(pickup_resource)
	else:
		activate_upgrade(pickup_resource)


func activate_permanent_upgrade(upgrade) -> void:
	if upgrade == null:
		return
	var id: String = upgrade.id
	var state: Dictionary = _permanent_upgrades.get(id, {
		"upgrade": upgrade,
		"stacks": 0
	})
	state["stacks"] = min(int(state["stacks"]) + 1, int(upgrade.max_stacks))
	_permanent_upgrades[id] = state
	permanent_upgrades_changed.emit(get_attribute_modifiers(), get_permanent_stats())
	upgrade_changed.emit(get_modifiers(), get_active_effects())


func consume_shot() -> void:
	if _active_effects.is_empty():
		return
	var expired_ids: Array[String] = []
	for id in _active_effects.keys():
		var state: Dictionary = _active_effects[id]
		var effect = state["effect"]
		if int(effect.max_ammo) <= 0:
			continue
		state["ammo"] = max(int(state.get("ammo", 0)) - 1, 0)
		_active_effects[id] = state
		if int(state["ammo"]) <= 0:
			expired_ids.append(id)
	for id in expired_ids:
		var state: Dictionary = _active_effects[id]
		var effect = state["effect"]
		_active_effects.erase(id)
		upgrade_expired.emit(effect)
	if not expired_ids.is_empty() or not _active_effects.is_empty():
		upgrade_changed.emit(get_modifiers(), get_active_effects())


func get_modifiers() -> Dictionary:
	var modifiers := {
		"damage_multiplier": 1.0,
		"projectile_count": 1,
		"spread_angle_degrees": 0.0,
		"pierce_count": 0,
		"chain_count": 0,
		"chain_radius": 0.0,
		"explosion_radius": 0.0,
		"explosion_damage_multiplier": 0.0,
		"projectile_size_multiplier": 1.0,
		"projectile_growth_per_second": 0.0,
		"projectile_max_size_multiplier": 1.0,
		"projectile_kind": "normal",
		"fire_cooldown_multiplier": 1.0,
		"move_speed_multiplier": 1.0
	}
	for state in _active_effects.values():
		var effect = state["effect"]
		modifiers = effect.merge_into_modifiers(modifiers)
	var attributes := get_attribute_modifiers()
	modifiers["fire_cooldown_multiplier"] = float(modifiers["fire_cooldown_multiplier"]) * float(attributes["fire_cooldown_multiplier"])
	modifiers["damage_multiplier"] = float(modifiers["damage_multiplier"]) * float(attributes["damage_multiplier"])
	modifiers["move_speed_multiplier"] = float(attributes["move_speed_multiplier"])
	modifiers["projectile_size_multiplier"] = float(modifiers["projectile_size_multiplier"]) * float(attributes["projectile_size_multiplier"])
	modifiers["projectile_max_size_multiplier"] = max(float(modifiers["projectile_max_size_multiplier"]), float(modifiers["projectile_size_multiplier"]))
	return modifiers


func get_attribute_modifiers() -> Dictionary:
	var fire_rate_bonus: float = 0.0
	var move_speed_bonus: float = 0.0
	var damage_bonus: float = 0.0
	var projectile_size_bonus: float = 0.0
	for state in _permanent_upgrades.values():
		var upgrade = state["upgrade"]
		var stacks: int = int(state["stacks"])
		match int(upgrade.stat_type):
			0:
				fire_rate_bonus += upgrade.amount * float(stacks)
			1:
				move_speed_bonus += upgrade.amount * float(stacks)
			2:
				damage_bonus += upgrade.amount * float(stacks)
			3:
				projectile_size_bonus += upgrade.amount * float(stacks)
	return {
		"fire_cooldown_multiplier": max(1.0 - fire_rate_bonus, 0.4),
		"move_speed_multiplier": 1.0 + move_speed_bonus,
		"damage_multiplier": 1.0 + damage_bonus,
		"projectile_size_multiplier": 1.0 + projectile_size_bonus,
		"fire_rate_bonus": fire_rate_bonus,
		"move_speed_bonus": move_speed_bonus,
		"damage_bonus": damage_bonus,
		"projectile_size_bonus": projectile_size_bonus
	}


func get_permanent_stats() -> Array:
	var stats: Array = []
	for state in _permanent_upgrades.values():
		var upgrade = state["upgrade"]
		var stacks: int = int(state["stacks"])
		stats.append({
			"id": upgrade.id,
			"display_name": upgrade.display_name,
			"stat_key": upgrade.get_stat_key(),
			"stat_label": upgrade.get_stat_label(),
			"amount": upgrade.amount,
			"stacks": stacks,
			"max_stacks": upgrade.max_stacks,
			"total": upgrade.amount * float(stacks)
		})
	stats.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["stat_label"]) < String(b["stat_label"])
	)
	return stats


func get_active_effects() -> Array:
	var active: Array = []
	for state in _active_effects.values():
		var effect = state["effect"]
		active.append({
			"effect": effect,
			"remaining": state["remaining"],
			"ammo": state.get("ammo", effect.max_ammo),
			"max_ammo": effect.max_ammo
		})
	return active
