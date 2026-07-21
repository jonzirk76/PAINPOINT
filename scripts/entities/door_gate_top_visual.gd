extends Node2D
class_name DoorGateTopVisual

var _rects: Array[Rect2] = []
var _fill_color: Color = Color(0.09, 0.1, 0.12)
var _outline_color: Color = Color(0.16, 0.17, 0.18)
var _outline_width: float = 2.0


func configure(rects: Array[Rect2], fill_color: Color, outline_color: Color, outline_width: float) -> void:
	_rects.clear()
	for rect in rects:
		if rect.size.x > 0.0 and rect.size.y > 0.0:
			_rects.append(rect)
	_fill_color = fill_color
	_outline_color = outline_color
	_outline_width = outline_width
	visible = not _rects.is_empty()
	queue_redraw()


func clear() -> void:
	_rects.clear()
	visible = false
	queue_redraw()


func _draw() -> void:
	for rect in _rects:
		draw_rect(rect, _fill_color, true)
		draw_rect(rect, _outline_color, false, _outline_width)
