@tool
extends EditorPlugin

const DockScene := preload("res://addons/raster_region_polygon/raster_region_polygon_dock.tscn")

var _dock: EditorDock
var _dock_content


func _enter_tree() -> void:
	_dock_content = DockScene.instantiate()
	_dock_content.initialize(get_editor_interface(), get_undo_redo())

	_dock = EditorDock.new()
	_dock.title = "Raster Polygon"
	_dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL
	_dock.available_layouts = (
		EditorDock.DOCK_LAYOUT_VERTICAL
		| EditorDock.DOCK_LAYOUT_FLOATING
	)
	_dock.add_child(_dock_content)
	add_dock(_dock)


func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_dock(_dock)
		_dock.queue_free()
	_dock = null
	_dock_content = null
