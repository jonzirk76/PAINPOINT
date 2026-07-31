@tool
extends Control

signal image_point_selected(point: Vector2i)

var image: Image
var texture: Texture2D
var polygon := PackedVector2Array()
var selected_point := Vector2i(-1, -1)
var _image_rect := Rect2()


func _ready() -> void:
	custom_minimum_size = Vector2(260.0, 260.0)
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	resized.connect(queue_redraw)


func set_source(source_texture: Texture2D, source_image: Image) -> void:
	texture = source_texture
	image = source_image
	polygon.clear()
	selected_point = Vector2i(-1, -1)
	queue_redraw()


func set_trace(points: PackedVector2Array, seed: Vector2i) -> void:
	polygon = points
	selected_point = seed
	queue_redraw()


func clear_source() -> void:
	texture = null
	image = null
	polygon.clear()
	selected_point = Vector2i(-1, -1)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if image == null or not _image_rect.has_point(event.position):
		return

	var image_size := Vector2(image.get_size())
	var normalized := (event.position - _image_rect.position) / _image_rect.size
	var point := Vector2i(
		clampi(int(normalized.x * image_size.x), 0, image.get_width() - 1),
		clampi(int(normalized.y * image_size.y), 0, image.get_height() - 1)
	)
	image_point_selected.emit(point)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.11), true)
	if texture == null or image == null:
		_draw_empty_message()
		return

	var image_size := Vector2(image.get_size())
	var available := size - Vector2(12.0, 12.0)
	var scale_factor: float = minf(
		available.x / image_size.x,
		available.y / image_size.y
	)
	var draw_size := image_size * scale_factor
	_image_rect = Rect2((size - draw_size) * 0.5, draw_size)
	draw_texture_rect(texture, _image_rect, false)

	if polygon.size() >= 3:
		var preview_points := PackedVector2Array()
		for point in polygon:
			preview_points.append(_image_rect.position + point * scale_factor)
		draw_polyline(preview_points, Color(0.1, 1.0, 0.65), 2.0, true)
		draw_line(
			preview_points[preview_points.size() - 1],
			preview_points[0],
			Color(0.1, 1.0, 0.65),
			2.0,
			true
		)

	if selected_point.x >= 0:
		var marker := _image_rect.position + (Vector2(selected_point) + Vector2(0.5, 0.5)) * scale_factor
		draw_circle(marker, 4.0, Color.WHITE)
		draw_circle(marker, 2.0, Color(0.95, 0.25, 0.25))


func _draw_empty_message() -> void:
	_image_rect = Rect2()
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var message := "Select a Sprite2D, then click\nUse Selected Sprite2D"
	var text_size := font.get_multiline_string_size(
		message,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1.0,
		font_size
	)
	font.draw_multiline_string(
		get_canvas_item(),
		(size - text_size) * 0.5,
		message,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1.0,
		font_size,
		Color(0.7, 0.72, 0.76)
	)
