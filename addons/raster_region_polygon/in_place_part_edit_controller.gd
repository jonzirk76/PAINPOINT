@tool
extends RefCounted

const Checker := preload("res://addons/raster_region_polygon/in_place_part_edit_checker.gd")
const Session := preload("res://addons/raster_region_polygon/in_place_part_edit_session.gd")
const Plan := preload("res://addons/raster_region_polygon/in_place_part_edit_plan.gd")

var editor_interface: EditorInterface
var session: RefCounted = Session.new()


func initialize(p_editor_interface: EditorInterface) -> void:
	editor_interface = p_editor_interface


func propose_begin() -> RefCounted:
	if session.active:
		return Plan.reject(
			"Finish or cancel the current in-place part edit first."
		)
	return Checker.propose(editor_interface)


func finish_begin(plan: RefCounted) -> Dictionary:
	var source_root := editor_interface.get_edited_scene_root() as Node2D
	if source_root == null or source_root.scene_file_path != plan.source_path:
		return {
			"valid": false,
			"reason": "Godot did not finish opening the governing part scene.",
		}
	var current_snapshot: Dictionary = Checker.capture_part_snapshot(source_root)
	if not Checker.snapshots_match(current_snapshot, plan.source_snapshot):
		return {
			"valid": false,
			"reason": (
				"The governing part changed after the proposal was created. "
				+ "Return to the assembly and start a fresh session."
			),
		}
	var result: Dictionary = session.begin(plan, source_root)
	if not result.valid:
		return result
	# Loading saved instance overrides into the canonical draft is an editor-side
	# mutation; Godot does not mark tool-script changes dirty automatically.
	editor_interface.mark_scene_as_unsaved()
	var selection := editor_interface.get_selection()
	selection.clear()
	selection.add_node(source_root)
	editor_interface.edit_node(source_root)
	editor_interface.set_main_screen_editor("2D")
	return {"valid": true, "reason": ""}


func synchronize_preview() -> void:
	session.synchronize_preview()


func apply_to_source() -> Dictionary:
	var precondition := _inspect_active_source()
	if not precondition.valid:
		return precondition
	var plan := session.plan
	var final_snapshot: Dictionary = Checker.capture_part_snapshot(session.source_root)
	session.remove_context()
	var error := editor_interface.save_scene()
	if error != OK:
		return {
			"valid": false,
			"reason": "Godot could not save the governing part scene (error %d)." % error,
		}
	var result := {
		"valid": true,
		"reason": "",
		"layout_path": plan.layout_path,
		"instance_path": plan.instance_path,
		"source_path": plan.source_path,
		"final_snapshot": final_snapshot,
	}
	session.clear()
	_refresh_and_open_layout(result.layout_path, result.source_path)
	return result


func finalize_layout_after_apply(result: Dictionary) -> Dictionary:
	var layout_root := editor_interface.get_edited_scene_root()
	if layout_root == null or layout_root.scene_file_path != result.layout_path:
		return {
			"valid": false,
			"reason": (
				"The source was saved, but Godot did not reopen the assembly. "
				+ "Reopen it before continuing."
			),
		}
	var occurrences: Array[Node] = []
	_collect_source_occurrences(layout_root, result.source_path, occurrences)
	if occurrences.is_empty():
		return {
			"valid": false,
			"reason": (
				"The source was saved, but the assembly no longer contains that part."
			),
		}
	for occurrence in occurrences:
		var synchronized := Checker.apply_snapshot(occurrence, result.final_snapshot)
		if not synchronized.valid:
			return synchronized
	# Re-saving a freshly reloaded layout with values equal to the source removes
	# redundant instance overrides while preserving each insertion transform.
	editor_interface.mark_scene_as_unsaved()
	var error := editor_interface.save_scene()
	if error != OK:
		return {
			"valid": false,
			"reason": (
				"The source was saved, but Godot could not normalize the assembly "
				+ "overrides (error %d)."
			) % error,
		}
	editor_interface.reload_scene_from_path(result.layout_path)
	return {"valid": true, "reason": ""}


func cancel() -> Dictionary:
	var precondition := _inspect_active_source()
	if not precondition.valid:
		return precondition
	var plan := session.plan
	session.remove_context()
	editor_interface.reload_scene_from_path(plan.source_path)
	var result := {
		"valid": true,
		"reason": "",
		"layout_path": plan.layout_path,
		"instance_path": plan.instance_path,
	}
	session.clear()
	editor_interface.open_scene_from_path(result.layout_path)
	return result


func abandon_context() -> void:
	# Plugin shutdown must never discard an unsaved source scene. Remove only the
	# non-persistent overlay and leave normal Godot save/revert controls intact.
	if session.active:
		session.remove_context()
		session.clear()


func _inspect_active_source() -> Dictionary:
	if not session.active or session.plan == null:
		return {"valid": false, "reason": "No in-place part edit session is active."}
	var current_root := editor_interface.get_edited_scene_root()
	if current_root == null or current_root.scene_file_path != session.plan.source_path:
		return {
			"valid": false,
			"reason": "Return to the governing part scene before finishing this session.",
		}
	var disk_time := FileAccess.get_modified_time(session.plan.source_path)
	if disk_time != session.plan.source_modified_time:
		return {
			"valid": false,
			"reason": (
				"The governing part file changed on disk during this session. "
				+ "Resolve that change before applying or canceling."
			),
		}
	return {"valid": true, "reason": ""}


func _refresh_and_open_layout(layout_path: String, source_path: String) -> void:
	ResourceLoader.load(source_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	if editor_interface.get_open_scenes().has(layout_path):
		editor_interface.reload_scene_from_path(layout_path)
	editor_interface.open_scene_from_path(layout_path)


func _collect_source_occurrences(
	node: Node,
	source_path: String,
	result: Array[Node]
) -> void:
	if node.scene_file_path == source_path:
		result.append(node)
		return
	for child in node.get_children():
		_collect_source_occurrences(child, source_path, result)
