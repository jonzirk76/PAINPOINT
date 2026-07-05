extends Resource
class_name PermanentUpgrade

enum StatType {
	FIRE_RATE,
	MOVE_SPEED,
	DAMAGE,
	PROJECTILE_SIZE,
	OVERDRIVE_CAPACITY
}

@export var id: String = "permanent_upgrade"
@export var display_name: String = "Permanent Upgrade"
@export var stat_type: StatType = StatType.FIRE_RATE
@export var amount: float = 0.04
@export var max_stacks: int = 12


func get_pickup_kind() -> String:
	return "permanent"


func get_stat_key() -> String:
	match stat_type:
		StatType.FIRE_RATE:
			return "fire_rate"
		StatType.MOVE_SPEED:
			return "move_speed"
		StatType.DAMAGE:
			return "damage"
		StatType.PROJECTILE_SIZE:
			return "projectile_size"
		StatType.OVERDRIVE_CAPACITY:
			return "overdrive_capacity"
	return "unknown"


func get_stat_label() -> String:
	match stat_type:
		StatType.FIRE_RATE:
			return "Fire Rate"
		StatType.MOVE_SPEED:
			return "Move Speed"
		StatType.DAMAGE:
			return "Bullet Damage"
		StatType.PROJECTILE_SIZE:
			return "Projectile Size"
		StatType.OVERDRIVE_CAPACITY:
			return "Overdrive Capacity"
	return "Unknown"


func get_reward_description() -> String:
	match stat_type:
		StatType.FIRE_RATE:
			return "%s: fire rate +%d%%." % [display_name, roundi(amount * 100.0)]
		StatType.MOVE_SPEED:
			return "%s: move speed +%d%%." % [display_name, roundi(amount * 100.0)]
		StatType.DAMAGE:
			return "%s: bullet damage +%d%%." % [display_name, roundi(amount * 100.0)]
		StatType.PROJECTILE_SIZE:
			return "%s: projectile size +%d%%." % [display_name, roundi(amount * 100.0)]
		StatType.OVERDRIVE_CAPACITY:
			return "%s: max overdrive ammo +%d." % [display_name, roundi(amount)]
	return display_name
