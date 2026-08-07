@tool
extends EditorPlugin

const DockScene := preload("res://addons/raster_region_polygon/raster_region_polygon_dock.tscn")
const ViewportEditTool := preload("res://addons/raster_region_polygon/polygon_viewport_edit_tool.gd")

var _dock_content
var _viewport_edit_tool: RefCounted
var _dock_added: bool = false


func _enter_tree() -> void:
	_viewport_edit_tool = ViewportEditTool.new()
	_viewport_edit_tool.initialize(get_editor_interface(), get_undo_redo())
	_viewport_edit_tool.state_changed.connect(_on_edit_tool_state_changed)
	_dock_content = DockScene.instantiate()
	_dock_content.initialize(get_editor_interface(), get_undo_redo(), _viewport_edit_tool)
	_dock_content.name = "Raster Polygon"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock_content)
	_dock_added = true


func _exit_tree() -> void:
	if is_instance_valid(_dock_content):
		_dock_content.shutdown_part_editing()
		if _dock_added:
			remove_control_from_docks(_dock_content)
		_dock_content.queue_free()
	_dock_content = null
	_viewport_edit_tool = null
	_dock_added = false


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if _viewport_edit_tool == null:
		return false
	# Pointer editing belongs to the dock preview. Only forward keyboard actions
	# from the 2D viewport so Godot retains its normal node-selection behavior.
	if not event is InputEventKey:
		return false
	var handled: bool = _viewport_edit_tool.forward_input(event)
	if handled:
		update_overlays()
	return handled


func _on_edit_tool_state_changed(message: String) -> void:
	update_overlays()
	if is_instance_valid(_dock_content):
		_dock_content.show_vertex_edit_status(message)
