@tool
extends Control
class_name CircularPortrait

@export var texture: Texture2D:
	set(value):
		_texture = value
		queue_redraw()
	get:
		return _texture

@export_range(24, 128, 1) var mask_segments: int = 72:
	set(value):
		_mask_segments = max(value, 24)
		queue_redraw()
	get:
		return _mask_segments

@export var background_color: Color = Color(0.012, 0.014, 0.018, 1.0):
	set(value):
		_background_color = value
		queue_redraw()
	get:
		return _background_color

@export var border_color: Color = Color(0.28, 0.9, 1.0, 0.95):
	set(value):
		_border_color = value
		queue_redraw()
	get:
		return _border_color

@export var rim_color: Color = Color(1.0, 0.93, 0.45, 0.22):
	set(value):
		_rim_color = value
		queue_redraw()
	get:
		return _rim_color

var _texture: Texture2D
var _mask_segments: int = 72
var _background_color: Color = Color(0.012, 0.014, 0.018, 1.0)
var _border_color: Color = Color(0.28, 0.9, 1.0, 0.95)
var _rim_color: Color = Color(1.0, 0.93, 0.45, 0.22)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var diameter: float = min(size.x, size.y)
	if diameter <= 0.0:
		return
	var rect := Rect2((size - Vector2(diameter, diameter)) * 0.5, Vector2(diameter, diameter))
	var center := rect.get_center()
	var radius := diameter * 0.5
	draw_circle(center, radius, _background_color)
	if _texture != null:
		_draw_texture_circle(rect, center, radius)
	draw_arc(center, radius - 1.5, 0.0, TAU, _mask_segments, _border_color, 3.0, true)
	draw_arc(center, radius - 6.0, PI * 0.12, PI * 1.88, _mask_segments, _rim_color, 2.0, true)


func _draw_texture_circle(rect: Rect2, center: Vector2, radius: float) -> void:
	var texture_size := _texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var center_uv := texture_size * 0.5
	var segments: int = max(_mask_segments, 24)
	for index in range(segments):
		var angle_a := TAU * float(index) / float(segments)
		var angle_b := TAU * float(index + 1) / float(segments)
		var point_a := center + Vector2(cos(angle_a), sin(angle_a)) * radius
		var point_b := center + Vector2(cos(angle_b), sin(angle_b)) * radius
		var points := PackedVector2Array([center, point_a, point_b])
		var uvs := PackedVector2Array([
			center_uv,
			_get_uv_for_point(point_a, rect, texture_size),
			_get_uv_for_point(point_b, rect, texture_size)
		])
		draw_polygon(points, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE]), uvs, _texture)


func _get_uv_for_point(point: Vector2, rect: Rect2, texture_size: Vector2) -> Vector2:
	var local := (point - rect.position) / rect.size
	return Vector2(
		clamp(local.x, 0.0, 1.0) * texture_size.x,
		clamp(local.y, 0.0, 1.0) * texture_size.y
	)
