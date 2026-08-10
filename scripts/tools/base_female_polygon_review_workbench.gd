@tool
extends Node2D

## [Description] Shows the cropped female turnaround over the five editable canonical polygon scenes.
@export var show_reference_overlay: bool = true:
	set(value):
		show_reference_overlay = value
		_refresh_review()

## [Description] Controls how strongly the female turnaround is overlaid for silhouette fitting.
@export_range(0.0, 1.0, 0.01) var reference_overlay_opacity := 0.34:
	set(value):
		reference_overlay_opacity = value
		_refresh_review()

## [Description] Shows the compact animated sequence containing all eight runtime directions.
@export var show_eight_way_preview: bool = true:
	set(value):
		show_eight_way_preview = value
		_refresh_review()


func _ready() -> void:
	_refresh_review()


func _refresh_review() -> void:
	var reference_overlay := get_node_or_null("CanonicalReview/ReferenceOverlay") as CanvasItem
	if reference_overlay != null:
		reference_overlay.visible = show_reference_overlay
		reference_overlay.modulate = Color(1.0, 1.0, 1.0, reference_overlay_opacity)
	var eight_way_preview := get_node_or_null("EightWayPreview") as CanvasItem
	if eight_way_preview != null:
		eight_way_preview.visible = show_eight_way_preview
