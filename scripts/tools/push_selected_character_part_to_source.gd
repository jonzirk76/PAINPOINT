@tool
extends EditorScript

const SOURCE_SYNC := preload("res://scripts/tools/character_part_source_sync.gd")


func _run() -> void:
	if not Engine.is_editor_hint():
		push_warning("Character part source push is editor-only.")
		return
	var editor_interface := get_editor_interface()
	var sync = SOURCE_SYNC.new()
	var selected_node: Node = sync.get_selected_node(editor_interface)
	if selected_node == null:
		return
	var source_path: String = sync.push_node_to_source(selected_node)
	if source_path.is_empty():
		return
	_refresh_filesystem(editor_interface)
	_mark_scene_unsaved(editor_interface)


func _refresh_filesystem(editor_interface: EditorInterface) -> void:
	if editor_interface == null:
		return
	var filesystem := editor_interface.get_resource_filesystem()
	if filesystem != null:
		filesystem.scan()


func _mark_scene_unsaved(editor_interface: EditorInterface) -> void:
	if editor_interface != null and editor_interface.has_method("mark_scene_as_unsaved"):
		editor_interface.mark_scene_as_unsaved()
