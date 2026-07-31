@tool
extends EditorPlugin

const DockScene := preload("res://addons/raster_region_polygon/raster_region_polygon_dock.tscn")

var _dock_content
var _dock_added: bool = false


func _enter_tree() -> void:
	_dock_content = DockScene.instantiate()
	_dock_content.initialize(get_editor_interface(), get_undo_redo())
	_dock_content.name = "Raster Polygon"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock_content)
	_dock_added = true


func _exit_tree() -> void:
	if is_instance_valid(_dock_content):
		if _dock_added:
			remove_control_from_docks(_dock_content)
		_dock_content.queue_free()
	_dock_content = null
	_dock_added = false
