class_name HumanoidAnimationRigSource
extends Resource

## [Description] Human-readable identity for this reusable animation rig.
@export var rig_name: StringName = &"humanoid_base"
## [Description] Five editable canonical scenes containing pivots, anchors, and AnimationPlayer tracks.
@export var directional_views: HumanoidDirectionalViewSet


func get_selection(direction: int) -> Dictionary:
	if directional_views == null:
		return {"scene": null, "mirror": false}
	return directional_views.get_selection(direction)


func is_valid() -> bool:
	return directional_views != null and directional_views.is_complete()
