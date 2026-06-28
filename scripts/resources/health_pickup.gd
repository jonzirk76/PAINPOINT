extends Resource
class_name HealthPickup

@export var id: String = "small_heal"
@export var display_name: String = "Small Heal"
@export var heal_amount: int = 2


func get_pickup_kind() -> String:
	return "heal"
