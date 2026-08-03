class_name PolygonCharacterSkinSource
extends Resource

## [Description] Human-readable identity for this editable character skin.
@export var skin_name: StringName = &"neutral_polygon"
## [Description] Five editable canonical scenes supplying polygons and other visible skin layers.
@export var directional_views: HumanoidDirectionalViewSet
## [Description] Editable arm scene used while a character has an active aim direction.
@export var active_arm_scene: PackedScene


func get_selection(direction: int) -> Dictionary:
	if directional_views == null:
		return {"scene": null, "mirror": false}
	return directional_views.get_selection(direction)


func is_valid() -> bool:
	return directional_views != null and directional_views.is_complete() and active_arm_scene != null
