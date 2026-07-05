extends Resource
class_name OverdriveAmmoPickup

@export var id: String = "overdrive_ammo"
@export var display_name: String = "Overdrive Ammo"
@export var amount: int = 8


func get_pickup_kind() -> String:
	return "overdrive_ammo"


func get_reward_description() -> String:
	return "%s: restore %d overdrive ammo." % [display_name, amount]
