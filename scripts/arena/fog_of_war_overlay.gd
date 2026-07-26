extends CanvasLayer
class_name FogOfWarOverlay

const FOG_MASK_SCRIPT := preload("res://scripts/arena/fog_of_war_mask.gd")

var _source_viewport: Viewport = null
var _mask = null


func configure(rects: Array[Rect2], source_viewport: Viewport) -> void:
	_source_viewport = source_viewport
	if _source_viewport == null:
		visible = false
		return
	_ensure_mask()
	_mask.configure(rects)
	visible = not rects.is_empty()
	_sync_viewport()


func clear() -> void:
	visible = false
	if _mask != null:
		var empty_rects: Array[Rect2] = []
		_mask.configure(empty_rects)


func _process(_delta: float) -> void:
	if not visible or _source_viewport == null:
		return
	_sync_viewport()


func _ensure_mask() -> void:
	if _mask != null:
		return
	# Opaque undiscovered fog must cover the translucent wall-occlusion composite.
	layer = 1
	_mask = FOG_MASK_SCRIPT.new()
	_mask.name = "FogMask"
	add_child(_mask)


func _sync_viewport() -> void:
	var visible_size := _source_viewport.get_visible_rect().size
	if visible_size.x <= 0.0 or visible_size.y <= 0.0:
		return
	_mask.position = Vector2.ZERO
	_mask.size = visible_size
	_mask.update_canvas_transform(_source_viewport.canvas_transform)
