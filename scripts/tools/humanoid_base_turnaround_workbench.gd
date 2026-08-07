@tool
extends Node2D

## Shows the neutral character-base reference above the editable block assemblies.
@export var show_reference_overlay: bool = true:
	set(value):
		show_reference_overlay = value
		_refresh_workbench()

## Controls how strongly the neutral character-base reference covers the block assemblies.
@export_range(0.0, 1.0, 0.01) var reference_overlay_opacity := 0.42:
	set(value):
		reference_overlay_opacity = value
		_refresh_workbench()

## Shows the compact eight-direction sequence beneath the five canonical authoring views.
@export var show_clockwise_preview: bool = true:
	set(value):
		show_clockwise_preview = value
		_refresh_workbench()


func _ready() -> void:
	_refresh_workbench()


func _refresh_workbench() -> void:
	var overlay := get_node_or_null("ReferenceOverlay") as CanvasItem
	if overlay != null:
		overlay.visible = show_reference_overlay
		overlay.modulate = Color(1.0, 1.0, 1.0, reference_overlay_opacity)
	var clockwise_preview := get_node_or_null("ClockwisePreview") as CanvasItem
	if clockwise_preview != null:
		clockwise_preview.visible = show_clockwise_preview
