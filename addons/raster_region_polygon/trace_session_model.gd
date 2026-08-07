@tool
extends RefCounted

const Recipe := preload("res://addons/raster_region_polygon/trace_recipe.gd")
const Draft := preload("res://addons/raster_region_polygon/trace_draft.gd")
const Checker := preload("res://addons/raster_region_polygon/trace_scene_checker.gd")

enum DestinationState {
	NEW_ONLY,
	UPDATE_SELECTED,
	REGENERATE_SELECTED,
	STALE_SELECTED,
}

var recipe: RefCounted = Recipe.new()
var draft: RefCounted = Draft.new()
var target: Polygon2D
var target_snapshot: Dictionary = {"status": Checker.TargetStatus.NONE}
var destination_state := DestinationState.NEW_ONLY


func use_source(sprite: Sprite2D, image: Image) -> void:
	recipe = Recipe.new()
	draft.recipe = recipe
	draft.set_source(sprite, image)
	clear_target()


func load_target(node: Polygon2D) -> Dictionary:
	target = node
	var metadata: Dictionary = node.get_meta(&"raster_region_trace", {})
	recipe = Recipe.from_metadata(metadata)
	draft.recipe = recipe
	synchronize()
	return target_snapshot


func rebuild() -> Dictionary:
	draft.recipe = recipe
	return draft.rebuild()


func synchronize() -> Dictionary:
	if not is_instance_valid(target):
		clear_target()
		return target_snapshot
	target_snapshot = Checker.inspect_target(
		target,
		draft.source_sprite,
		draft.source_image
	)
	match int(target_snapshot.get("status", Checker.TargetStatus.STALE)):
		Checker.TargetStatus.CLEAN:
			destination_state = DestinationState.UPDATE_SELECTED
		Checker.TargetStatus.MANUALLY_EDITED:
			destination_state = DestinationState.REGENERATE_SELECTED
		_:
			destination_state = DestinationState.STALE_SELECTED
	return target_snapshot


func clear_target() -> void:
	target = null
	target_snapshot = {"status": Checker.TargetStatus.NONE}
	destination_state = DestinationState.NEW_ONLY
