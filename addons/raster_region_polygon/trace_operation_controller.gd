@tool
extends RefCounted

const Checker := preload("res://addons/raster_region_polygon/trace_scene_checker.gd")
const Plan := preload("res://addons/raster_region_polygon/trace_operation_plan.gd")
const SessionModel := preload("res://addons/raster_region_polygon/trace_session_model.gd")
const TRACE_METADATA := &"raster_region_trace"

var editor_interface: EditorInterface
var undo_redo: EditorUndoRedoManager


func initialize(
	p_editor_interface: EditorInterface,
	p_undo_redo: EditorUndoRedoManager
) -> void:
	editor_interface = p_editor_interface
	undo_redo = p_undo_redo


func propose_create(model: RefCounted, requested_name: String) -> RefCounted:
	if not model.draft.is_ready():
		return Plan.reject("Choose a source and trace a region first.")
	var normalized_name := requested_name.strip_edges()
	if normalized_name.is_empty():
		normalized_name = "TracedRegion"
	var name_snapshot := Checker.inspect_name(
		model.draft.source_sprite,
		StringName(normalized_name)
	)
	if not name_snapshot.get("available", false):
		var kind := "generated polygon" if name_snapshot.get("generated", false) else "node"
		return Plan.reject(
			"A %s named '%s' already exists. Create New never overwrites nodes."
			% [kind, normalized_name]
		)
	var plan := Plan.new()
	plan.kind = Plan.Kind.CREATE
	plan.allowed = true
	plan.requested_name = normalized_name
	return plan


func propose_update(model: RefCounted) -> RefCounted:
	if not model.draft.is_ready():
		return Plan.reject("The current trace draft is not valid.")
	var snapshot: Dictionary = model.synchronize()
	var status := int(snapshot.get("status", Checker.TargetStatus.STALE))
	if status == Checker.TargetStatus.CLEAN:
		var update_plan := Plan.new()
		update_plan.kind = Plan.Kind.UPDATE
		update_plan.allowed = true
		update_plan.target = model.target
		return update_plan
	if status == Checker.TargetStatus.MANUALLY_EDITED:
		var regenerate_plan := Plan.new()
		regenerate_plan.kind = Plan.Kind.REGENERATE
		regenerate_plan.allowed = true
		regenerate_plan.target = model.target
		regenerate_plan.requires_confirmation = true
		regenerate_plan.reason = str(snapshot.get("reason", "Manual edits will be replaced."))
		return regenerate_plan
	return Plan.reject(str(snapshot.get("reason", "Selected target is stale or missing.")))


func apply_create(model: RefCounted, plan: RefCounted) -> Polygon2D:
	if not plan.allowed or plan.kind != Plan.Kind.CREATE:
		return null
	var edited_root := editor_interface.get_edited_scene_root()
	if edited_root == null:
		return null
	var polygon_data: Dictionary = model.draft.build_polygon_data()
	var polygon_node := Polygon2D.new()
	polygon_node.name = plan.requested_name
	polygon_node.polygon = polygon_data["vertices"]
	polygon_node.polygons = polygon_data["polygons"]
	polygon_node.color = model.draft.result["sample"]
	polygon_node.set_meta(
		TRACE_METADATA,
		model.recipe.to_metadata(_new_trace_id())
	)

	undo_redo.create_action("Create raster region Polygon2D")
	undo_redo.add_do_method(model.draft.source_sprite, "add_child", polygon_node, true)
	undo_redo.add_do_method(polygon_node, "set_owner", edited_root)
	undo_redo.add_do_method(editor_interface.get_selection(), "clear")
	undo_redo.add_do_method(editor_interface.get_selection(), "add_node", polygon_node)
	undo_redo.add_undo_method(model.draft.source_sprite, "remove_child", polygon_node)
	undo_redo.add_do_reference(polygon_node)
	undo_redo.commit_action()
	model.target = polygon_node
	model.synchronize()
	return polygon_node


func apply_update(model: RefCounted, plan: RefCounted) -> bool:
	if (
		not plan.allowed
		or plan.kind not in [Plan.Kind.UPDATE, Plan.Kind.REGENERATE]
		or not is_instance_valid(plan.target)
	):
		return false
	# Re-inspect immediately before mutation so a stale proposal cannot overwrite
	# a scene change made after the button was pressed.
	var fresh_plan := propose_update(model)
	if not fresh_plan.allowed or fresh_plan.kind != plan.kind:
		return false
	var target: Polygon2D = plan.target
	var polygon_data: Dictionary = model.draft.build_polygon_data()
	var old_polygon := target.polygon
	var old_polygons := target.polygons
	var old_color := target.color
	var old_metadata: Variant = target.get_meta(TRACE_METADATA, {})
	var trace_id: String = str((old_metadata as Dictionary).get("trace_id", ""))
	if trace_id.is_empty():
		trace_id = _new_trace_id()
	var new_metadata: Dictionary = model.recipe.to_metadata(trace_id)

	undo_redo.create_action(
		"Regenerate raster region Polygon2D"
		if plan.kind == Plan.Kind.REGENERATE
		else "Update raster region Polygon2D"
	)
	undo_redo.add_do_property(target, "polygon", polygon_data["vertices"])
	undo_redo.add_do_property(target, "polygons", polygon_data["polygons"])
	undo_redo.add_do_property(target, "color", model.draft.result["sample"])
	undo_redo.add_do_method(target, "set_meta", TRACE_METADATA, new_metadata)
	undo_redo.add_undo_property(target, "polygon", old_polygon)
	undo_redo.add_undo_property(target, "polygons", old_polygons)
	undo_redo.add_undo_property(target, "color", old_color)
	undo_redo.add_undo_method(target, "set_meta", TRACE_METADATA, old_metadata)
	undo_redo.commit_action()
	model.synchronize()
	return true


func _new_trace_id() -> String:
	return "%x" % ResourceUID.create_id()
