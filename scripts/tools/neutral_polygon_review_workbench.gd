@tool
extends Node2D

## Shows the raster cutouts over the editable polygon bases for proportion review.
@export var show_reference_overlay: bool = true:
	set(value):
		show_reference_overlay = value
		_refresh_review()

## Controls the opacity of the raster references over the polygon results.
@export_range(0.0, 1.0, 0.01) var reference_overlay_opacity := 0.38:
	set(value):
		reference_overlay_opacity = value
		_refresh_review()

## Shows the compact animated eight-direction polygon sequence.
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
