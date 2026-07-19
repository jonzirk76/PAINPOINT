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
## Groups small and full versions of the same stat into one run-long stack.
@export var stack_key: String = ""
## Overrides the pause/HUD stack name when variants share a stack key.
@export var stack_display_name: String = ""
@export var stat_type: StatType = StatType.FIRE_RATE
@export var amount: float = 0.04
## Lowest amount this reward can roll when spawned; leave at 0 to use amount exactly.
@export var roll_amount_min: float = 0.0
## Highest amount this reward can roll when spawned; leave at 0 to use amount exactly.
@export var roll_amount_max: float = 0.0
@export var max_stacks: int = 12


func get_pickup_kind() -> String:
	return "permanent"


func get_stack_key() -> String:
	return stack_key if not stack_key.is_empty() else id


func get_stack_display_name() -> String:
	if not stack_display_name.is_empty():
		return stack_display_name
	return display_name


func create_rolled_copy(rng) -> PermanentUpgrade:
	var rolled := duplicate(true) as PermanentUpgrade
	if rolled == null:
		return self
	rolled.amount = _roll_amount(rng)
	return rolled


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


func _roll_amount(rng) -> float:
	if roll_amount_min <= 0.0 and roll_amount_max <= 0.0:
		return amount
	if rng == null:
		return amount
	var lower: float = roll_amount_min
	var upper: float = roll_amount_max
	if upper <= 0.0:
		upper = amount
	if lower <= 0.0:
		lower = amount
	if upper < lower:
		var swap := lower
		lower = upper
		upper = swap
	if stat_type == StatType.OVERDRIVE_CAPACITY:
		return float(rng.randi_range(roundi(lower), roundi(upper)))
	return rng.randf_range(lower, upper)


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
