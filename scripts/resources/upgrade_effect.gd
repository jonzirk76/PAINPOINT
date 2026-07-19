extends Resource
class_name UpgradeEffect

enum UpgradeType {
	SPREAD,
	PIERCING,
	CHAIN_LIGHTNING,
	FIRE,
	WATER
}

@export var id: String = "upgrade"
@export var display_name: String = "Upgrade"
@export var upgrade_type: UpgradeType = UpgradeType.SPREAD
@export var duration_seconds: float = 8.0
## Adds this much shared overdrive ammo capacity per reward stack.
@export var max_ammo: int = 0
@export var projectile_count: int = 1
@export var spread_angle_degrees: float = 0.0
@export var pierce_count: int = 0
@export var chain_count: int = 0
@export var chain_radius: float = 0.0
@export var explosion_radius: float = 0.0
@export var explosion_damage_multiplier: float = 0.0
## Applies this much damage per second while the fire burn is active.
@export var burn_damage_per_second: float = 0.0
## Controls how long fire burn lasts before it must be refreshed.
@export var burn_duration_seconds: float = 0.0
## Multiplies enemy movement speed while the water slow is active.
@export_range(0.25, 1.0, 0.01) var slow_multiplier: float = 1.0
## Controls how long water slow lasts before it must be refreshed.
@export var slow_duration_seconds: float = 0.0
## Adds repeat-hit lightning bonus damage per existing shock stack.
@export var lightning_charge_damage_bonus: float = 0.0
## Controls how long lightning shock stacks remain without another hit.
@export var lightning_charge_duration_seconds: float = 0.0
## Caps shock stacks that can build on one enemy from repeated lightning hits.
@export var lightning_charge_max_stacks: int = 0
@export var projectile_size_multiplier: float = 1.0
@export var projectile_growth_per_second: float = 0.0
@export var projectile_max_size_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var fire_cooldown_multiplier: float = 1.0


func merge_into_modifiers(modifiers: Dictionary) -> Dictionary:
	var merged := modifiers.duplicate()
	merged["damage_multiplier"] = max(float(merged.get("damage_multiplier", 1.0)), damage_multiplier)
	merged["projectile_count"] = max(int(merged.get("projectile_count", 1)), projectile_count)
	merged["spread_angle_degrees"] = max(float(merged.get("spread_angle_degrees", 0.0)), spread_angle_degrees)
	merged["pierce_count"] = max(int(merged.get("pierce_count", 0)), pierce_count)
	merged["chain_count"] = max(int(merged.get("chain_count", 0)), chain_count)
	merged["chain_radius"] = max(float(merged.get("chain_radius", 0.0)), chain_radius)
	merged["explosion_radius"] = max(float(merged.get("explosion_radius", 0.0)), explosion_radius)
	merged["explosion_damage_multiplier"] = max(float(merged.get("explosion_damage_multiplier", 0.0)), explosion_damage_multiplier)
	merged["burn_damage_per_second"] = max(float(merged.get("burn_damage_per_second", 0.0)), burn_damage_per_second)
	merged["burn_duration_seconds"] = max(float(merged.get("burn_duration_seconds", 0.0)), burn_duration_seconds)
	merged["slow_multiplier"] = min(float(merged.get("slow_multiplier", 1.0)), slow_multiplier)
	merged["slow_duration_seconds"] = max(float(merged.get("slow_duration_seconds", 0.0)), slow_duration_seconds)
	merged["lightning_charge_damage_bonus"] = max(float(merged.get("lightning_charge_damage_bonus", 0.0)), lightning_charge_damage_bonus)
	merged["lightning_charge_duration_seconds"] = max(float(merged.get("lightning_charge_duration_seconds", 0.0)), lightning_charge_duration_seconds)
	merged["lightning_charge_max_stacks"] = max(int(merged.get("lightning_charge_max_stacks", 0)), lightning_charge_max_stacks)
	merged["projectile_size_multiplier"] = max(float(merged.get("projectile_size_multiplier", 1.0)), projectile_size_multiplier)
	merged["projectile_growth_per_second"] = max(float(merged.get("projectile_growth_per_second", 0.0)), projectile_growth_per_second)
	merged["projectile_max_size_multiplier"] = max(float(merged.get("projectile_max_size_multiplier", 1.0)), projectile_max_size_multiplier)
	merged["fire_cooldown_multiplier"] = min(float(merged.get("fire_cooldown_multiplier", 1.0)), fire_cooldown_multiplier)
	if explosion_radius > 0.0:
		merged["projectile_kind"] = "fire"
	elif projectile_growth_per_second > 0.0:
		merged["projectile_kind"] = "water"
	elif chain_count > 0:
		merged["projectile_kind"] = "lightning"
	return merged


func get_pickup_kind() -> String:
	return "overdrive_effect"


func get_reward_description() -> String:
	match upgrade_type:
		UpgradeType.SPREAD:
			return _with_capacity("%s: overdrive shots fire +1 projectile." % display_name)
		UpgradeType.PIERCING:
			return _with_capacity("%s: overdrive shots pierce +%d targets and hit harder." % [display_name, max(pierce_count, 1)])
		UpgradeType.CHAIN_LIGHTNING:
			return _with_capacity("%s: overdrive shots chain +%d jump and charge targets for repeat-hit damage." % [display_name, max(chain_count, 1)])
		UpgradeType.FIRE:
			return _with_capacity("%s: overdrive hits create a small explosion and burn targets." % display_name)
		UpgradeType.WATER:
			return _with_capacity("%s: overdrive shots grow, pierce, and slow targets." % display_name)
	return display_name


func _with_capacity(description: String) -> String:
	if max_ammo <= 0:
		return description
	return "%s Max overdrive +%d." % [description, max_ammo]
