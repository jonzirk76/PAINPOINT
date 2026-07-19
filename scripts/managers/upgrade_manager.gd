extends Node
class_name UpgradeManager

signal upgrade_changed(modifiers: Dictionary, active_effects: Array)
signal permanent_upgrades_changed(attribute_modifiers: Dictionary, permanent_stats: Array)
signal overdrive_changed(state: Dictionary)
signal upgrade_expired(effect)

@export var base_overdrive_capacity: int = 40

var enabled: bool = false
var _overdrive_effects: Dictionary = {}
var _permanent_upgrades: Dictionary = {}
var _overdrive_ammo: int = 40
var _overdrive_active: bool = false


func initialize(_context: Dictionary) -> void:
	pass


func reset_run() -> void:
	_overdrive_effects.clear()
	_permanent_upgrades.clear()
	_overdrive_active = false
	_overdrive_ammo = get_overdrive_max_ammo()
	permanent_upgrades_changed.emit(get_attribute_modifiers(), get_permanent_stats())
	_emit_upgrade_state()


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled and _overdrive_active:
		set_overdrive_active(false)


func _process(delta: float) -> void:
	pass


func activate_upgrade(effect) -> void:
	if effect == null:
		return
	var old_capacity := get_overdrive_max_ammo()
	var id: String = String(effect.id)
	var state: Dictionary = _overdrive_effects.get(id, {
		"effect": effect,
		"stacks": 0
	})
	state["stacks"] = int(state["stacks"]) + 1
	_overdrive_effects[id] = state
	_refill_ammo_for_capacity_change(old_capacity, get_overdrive_max_ammo())
	_emit_upgrade_state()


func activate_pickup(pickup_resource) -> void:
	if pickup_resource == null:
		return
	if pickup_resource.has_method("get_pickup_kind"):
		match String(pickup_resource.get_pickup_kind()):
			"permanent":
				activate_permanent_upgrade(pickup_resource)
			"overdrive_ammo":
				add_overdrive_ammo(int(pickup_resource.amount))
			_:
				activate_upgrade(pickup_resource)
	else:
		activate_upgrade(pickup_resource)


func activate_permanent_upgrade(upgrade) -> void:
	if upgrade == null:
		return
	var old_capacity := get_overdrive_max_ammo()
	var id: String = upgrade.id
	var state: Dictionary = _permanent_upgrades.get(id, {
		"upgrade": upgrade,
		"stacks": 0
	})
	state["stacks"] = min(int(state["stacks"]) + 1, int(upgrade.max_stacks))
	_permanent_upgrades[id] = state
	var new_capacity := get_overdrive_max_ammo()
	if new_capacity > old_capacity:
		_overdrive_ammo = min(_overdrive_ammo + new_capacity - old_capacity, new_capacity)
	else:
		_overdrive_ammo = min(_overdrive_ammo, new_capacity)
	permanent_upgrades_changed.emit(get_attribute_modifiers(), get_permanent_stats())
	_emit_upgrade_state()


func set_overdrive_active(value: bool) -> void:
	if _overdrive_active == value:
		return
	_overdrive_active = value
	_emit_upgrade_state()


func can_fire_overdrive() -> bool:
	return _overdrive_active and _overdrive_ammo > 0


func consume_overdrive_shot() -> bool:
	if not can_fire_overdrive():
		return false
	_overdrive_ammo = max(_overdrive_ammo - 1, 0)
	_emit_upgrade_state()
	return true


func consume_shot() -> void:
	consume_overdrive_shot()


func add_overdrive_ammo(amount: int) -> int:
	if amount <= 0:
		return 0
	var maximum := get_overdrive_max_ammo()
	var before := _overdrive_ammo
	_overdrive_ammo = clamp(_overdrive_ammo + amount, 0, maximum)
	var added := _overdrive_ammo - before
	if added > 0:
		_emit_upgrade_state()
	return added


func add_ammo_to_active_upgrades(amount: int) -> int:
	return add_overdrive_ammo(amount)


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
		"burn_damage_per_second": 0.0,
		"burn_duration_seconds": 0.0,
		"slow_multiplier": 1.0,
		"slow_duration_seconds": 0.0,
		"lightning_charge_damage_bonus": 0.0,
		"lightning_charge_duration_seconds": 0.0,
		"lightning_charge_max_stacks": 0,
		"projectile_size_multiplier": 1.0,
		"projectile_growth_per_second": 0.0,
		"projectile_max_size_multiplier": 1.0,
		"projectile_kind": "normal",
		"fire_cooldown_multiplier": 1.0,
		"move_speed_multiplier": 1.0,
		"overdrive_active": can_fire_overdrive(),
		"overdrive_has_effects": not _overdrive_effects.is_empty()
	}
	if can_fire_overdrive():
		if _overdrive_effects.is_empty():
			modifiers["projectile_size_multiplier"] = 2.0
			modifiers["projectile_max_size_multiplier"] = 2.0
		else:
			for state in _overdrive_effects.values():
				modifiers = _merge_overdrive_effect(modifiers, state["effect"], int(state["stacks"]))
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
	var overdrive_capacity_bonus: float = 0.0
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
			4:
				overdrive_capacity_bonus += upgrade.amount * float(stacks)
	return {
		"fire_cooldown_multiplier": max(1.0 - fire_rate_bonus, 0.4),
		"move_speed_multiplier": 1.0 + move_speed_bonus,
		"damage_multiplier": 1.0 + damage_bonus,
		"projectile_size_multiplier": 1.0 + projectile_size_bonus,
		"fire_rate_bonus": fire_rate_bonus,
		"move_speed_bonus": move_speed_bonus,
		"damage_bonus": damage_bonus,
		"projectile_size_bonus": projectile_size_bonus,
		"overdrive_capacity_bonus": overdrive_capacity_bonus
	}


func get_overdrive_max_ammo() -> int:
	var attributes := get_attribute_modifiers()
	return max(base_overdrive_capacity + roundi(float(attributes.get("overdrive_capacity_bonus", 0.0))) + _get_overdrive_effect_capacity_bonus(), 1)


func get_overdrive_ammo() -> int:
	return _overdrive_ammo


func get_overdrive_state() -> Dictionary:
	return {
		"ammo": _overdrive_ammo,
		"max_ammo": get_overdrive_max_ammo(),
		"is_held": _overdrive_active,
		"is_active": can_fire_overdrive(),
		"has_effects": not _overdrive_effects.is_empty(),
		"effects": get_active_effects()
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
	for state in _overdrive_effects.values():
		var effect = state["effect"]
		active.append({
			"effect": effect,
			"stacks": int(state["stacks"])
		})
	active.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["effect"].display_name) < String(b["effect"].display_name)
	)
	return active


func _merge_overdrive_effect(modifiers: Dictionary, effect, stacks: int) -> Dictionary:
	var merged := modifiers.duplicate()
	var safe_stacks: int = max(stacks, 0)
	if safe_stacks <= 0 or effect == null:
		return merged
	var projectile_bonus: int = max(int(effect.projectile_count) - 1, 0) * safe_stacks
	if projectile_bonus > 0:
		merged["projectile_count"] = max(int(merged.get("projectile_count", 1)) + projectile_bonus, 1)
		var spread_angle: float = max(float(effect.spread_angle_degrees), 12.0)
		merged["spread_angle_degrees"] = max(float(merged.get("spread_angle_degrees", 0.0)), min(spread_angle + float(max(projectile_bonus - 1, 0)) * 8.0, 72.0))
	merged["pierce_count"] = int(merged.get("pierce_count", 0)) + max(int(effect.pierce_count), 0) * safe_stacks
	if int(effect.chain_count) > 0:
		merged["chain_count"] = int(merged.get("chain_count", 0)) + int(effect.chain_count) * safe_stacks
		merged["chain_radius"] = max(float(merged.get("chain_radius", 0.0)), float(effect.chain_radius) + float(safe_stacks - 1) * 12.0)
	if float(effect.lightning_charge_damage_bonus) > 0.0:
		merged["lightning_charge_damage_bonus"] = max(
			float(merged.get("lightning_charge_damage_bonus", 0.0)),
			float(effect.lightning_charge_damage_bonus) + float(safe_stacks - 1) * 0.18
		)
		merged["lightning_charge_duration_seconds"] = max(
			float(merged.get("lightning_charge_duration_seconds", 0.0)),
			float(effect.lightning_charge_duration_seconds) + float(safe_stacks - 1) * 0.45
		)
		merged["lightning_charge_max_stacks"] = max(
			int(merged.get("lightning_charge_max_stacks", 0)),
			int(effect.lightning_charge_max_stacks) + safe_stacks - 1
		)
	if float(effect.explosion_radius) > 0.0:
		merged["explosion_radius"] = max(float(merged.get("explosion_radius", 0.0)), float(effect.explosion_radius) + float(safe_stacks - 1) * 14.0)
		merged["explosion_damage_multiplier"] = max(float(merged.get("explosion_damage_multiplier", 0.0)), min(float(effect.explosion_damage_multiplier) + float(safe_stacks - 1) * 0.04, 0.75))
	if float(effect.burn_damage_per_second) > 0.0:
		merged["burn_damage_per_second"] = max(
			float(merged.get("burn_damage_per_second", 0.0)),
			float(effect.burn_damage_per_second) * float(safe_stacks)
		)
		merged["burn_duration_seconds"] = max(
			float(merged.get("burn_duration_seconds", 0.0)),
			float(effect.burn_duration_seconds) + float(safe_stacks - 1) * 0.5
		)
	if float(effect.projectile_growth_per_second) > 0.0:
		merged["projectile_growth_per_second"] = float(merged.get("projectile_growth_per_second", 0.0)) + float(effect.projectile_growth_per_second) * float(safe_stacks)
		var max_size_bonus: float = max(float(effect.projectile_max_size_multiplier) - 1.0, 0.0) * float(safe_stacks)
		merged["projectile_max_size_multiplier"] = max(float(merged.get("projectile_max_size_multiplier", 1.0)), 1.0 + max_size_bonus)
	if float(effect.slow_duration_seconds) > 0.0 and float(effect.slow_multiplier) < 1.0:
		var slow_strength: float = clamp((1.0 - float(effect.slow_multiplier)) * float(safe_stacks), 0.0, 0.48)
		merged["slow_multiplier"] = min(float(merged.get("slow_multiplier", 1.0)), 1.0 - slow_strength)
		merged["slow_duration_seconds"] = max(
			float(merged.get("slow_duration_seconds", 0.0)),
			float(effect.slow_duration_seconds) + float(safe_stacks - 1) * 0.45
		)
	var projectile_size_bonus: float = max(float(effect.projectile_size_multiplier) - 1.0, 0.0) * float(safe_stacks)
	if projectile_size_bonus > 0.0:
		merged["projectile_size_multiplier"] = max(float(merged.get("projectile_size_multiplier", 1.0)), 1.0 + projectile_size_bonus)
	var damage_bonus: float = max(float(effect.damage_multiplier) - 1.0, 0.0) * float(safe_stacks)
	if damage_bonus > 0.0:
		merged["damage_multiplier"] = max(float(merged.get("damage_multiplier", 1.0)), 1.0 + damage_bonus)
	if float(effect.fire_cooldown_multiplier) > 0.0 and float(effect.fire_cooldown_multiplier) < 1.0:
		merged["fire_cooldown_multiplier"] = min(float(merged.get("fire_cooldown_multiplier", 1.0)), pow(float(effect.fire_cooldown_multiplier), float(safe_stacks)))
	if float(merged.get("explosion_radius", 0.0)) > 0.0:
		merged["projectile_kind"] = "fire"
	elif float(merged.get("projectile_growth_per_second", 0.0)) > 0.0:
		merged["projectile_kind"] = "water"
	elif int(merged.get("chain_count", 0)) > 0:
		merged["projectile_kind"] = "lightning"
	return merged


func _refill_ammo_for_capacity_change(old_capacity: int, new_capacity: int) -> void:
	if new_capacity > old_capacity:
		_overdrive_ammo = min(_overdrive_ammo + new_capacity - old_capacity, new_capacity)
	else:
		_overdrive_ammo = min(_overdrive_ammo, new_capacity)


func _get_overdrive_effect_capacity_bonus() -> int:
	var bonus := 0
	for state in _overdrive_effects.values():
		var effect = state["effect"]
		if effect == null:
			continue
		bonus += max(int(effect.max_ammo), 0) * max(int(state["stacks"]), 0)
	return bonus


func _emit_upgrade_state() -> void:
	upgrade_changed.emit(get_modifiers(), get_active_effects())
	overdrive_changed.emit(get_overdrive_state())
