extends Control

var cooldown_remaining: float = 0.0
var cooldown_duration: float = 1.0
var graze_active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_parry_state(remaining: float, duration: float, is_grazing: bool) -> void:
	cooldown_remaining = max(remaining, 0.0)
	cooldown_duration = max(duration, 0.01)
	graze_active = is_grazing and cooldown_remaining > 0.0
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var diameter: float = min(size.x, size.y)
	var center: Vector2 = size * 0.5
	var radius: float = max(diameter * 0.5 - 5.0, 4.0)
	var ready_ratio: float = 1.0
	if cooldown_remaining > 0.0:
		ready_ratio = 1.0 - clamp(cooldown_remaining / cooldown_duration, 0.0, 1.0)
	var start_angle := -PI * 0.5
	var end_angle := start_angle + TAU * ready_ratio
	var back_color := Color(0.01, 0.06, 0.07, 0.84)
	var ready_color := Color(0.52, 1.0, 0.9, 0.96)
	var cooldown_color := Color(0.28, 0.82, 1.0, 0.96)
	var graze_color := Color(1.0, 0.9, 0.28, 0.98)
	var fill_color := ready_color if cooldown_remaining <= 0.0 else cooldown_color
	if graze_active:
		fill_color = graze_color
	draw_arc(center, radius, 0.0, TAU, 72, back_color, 4.0)
	draw_arc(center, radius, start_angle, end_angle, 72, fill_color, 5.0)
	if cooldown_remaining <= 0.0:
		draw_arc(center, radius - 6.0, PI * 0.12, PI * 1.88, 72, Color(1.0, 1.0, 0.72, 0.62), 2.0)
	elif graze_active:
		draw_arc(center, radius - 6.0, start_angle, end_angle, 72, Color(1.0, 1.0, 0.74, 0.7), 2.0)
