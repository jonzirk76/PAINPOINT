extends Node2D
class_name ParryAbsorbEffect

signal expired(effect)

@export var lifetime_seconds: float = 0.34
@export var trail_samples: int = 7

var start_position: Vector2 = Vector2.ZERO
var end_position: Vector2 = Vector2.ZERO
var is_perfect: bool = false
var radius: float = 7.0

var _age: float = 0.0
var _control_position: Vector2 = Vector2.ZERO


func initialize(from_position: Vector2, to_position: Vector2, perfect: bool, projectile_radius: float = 7.0) -> void:
	start_position = from_position
	end_position = to_position
	is_perfect = perfect
	radius = max(projectile_radius, 3.0)
	global_position = Vector2.ZERO
	if is_perfect:
		lifetime_seconds = 0.42
	var delta: Vector2 = end_position - start_position
	var normal: Vector2 = delta.orthogonal().normalized() if delta.length_squared() > 0.001 else Vector2.UP
	var side: float = -1.0 if int(abs(start_position.x * 31.0 + start_position.y * 17.0)) % 2 == 0 else 1.0
	var swoop_distance: float = clamp(delta.length() * 0.3, 34.0, 96.0)
	_control_position = start_position.lerp(end_position, 0.52) + normal * swoop_distance * side
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime_seconds:
		expired.emit(self)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress: float = clamp(_age / lifetime_seconds, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - progress, 3.0)
	var fade: float = 1.0 - progress
	var current_position: Vector2 = _quadratic_bezier(start_position, _control_position, end_position, eased)
	var trail_color: Color = Color(0.45, 1.0, 0.95, 0.66 * fade)
	var core_color: Color = Color(0.9, 1.0, 1.0, 0.92 * fade)
	if is_perfect:
		trail_color = Color(1.0, 0.84, 0.22, 0.84 * fade)
		core_color = Color(1.0, 1.0, 0.86, 1.0 * fade)
	_draw_swoop_trail(eased, trail_color, core_color, fade)
	if is_perfect:
		_draw_perfect_shine(current_position, fade, progress)
	else:
		draw_circle(current_position, radius * (1.05 + 0.3 * fade), core_color)
		draw_arc(current_position, radius * (1.85 + 0.45 * fade), 0.0, TAU, 20, Color(0.42, 1.0, 0.9, 0.54 * fade), 2.0)


func _draw_swoop_trail(eased: float, trail_color: Color, core_color: Color, fade: float) -> void:
	var previous_point: Vector2 = _quadratic_bezier(start_position, _control_position, end_position, eased)
	for index in range(1, trail_samples + 1):
		var sample_offset: float = 0.05 * float(index)
		var sample_t: float = clamp(eased - sample_offset, 0.0, 1.0)
		var point: Vector2 = _quadratic_bezier(start_position, _control_position, end_position, sample_t)
		var sample_alpha: float = fade * (1.0 - float(index) / float(trail_samples + 1))
		var width: float = max(radius * (0.72 - float(index) * 0.055), 2.0)
		draw_line(point, previous_point, Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a * sample_alpha), width)
		previous_point = point
	draw_circle(_quadratic_bezier(start_position, _control_position, end_position, eased), radius * 1.2, core_color)


func _draw_perfect_shine(position: Vector2, fade: float, progress: float) -> void:
	var pulse: float = 0.5 + 0.5 * sin(progress * TAU * 2.0)
	var shine_radius: float = radius * (2.1 + pulse * 0.7)
	draw_circle(position, radius * (1.35 + pulse * 0.3), Color(1.0, 1.0, 0.92, 0.82 * fade))
	draw_arc(position, shine_radius, 0.0, TAU, 28, Color(1.0, 0.95, 0.46, 0.78 * fade), 3.0)
	for index in range(8):
		var direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(index) / 8.0 + progress * TAU * 0.5)
		var inner: Vector2 = position + direction * radius * 0.75
		var outer: Vector2 = position + direction * shine_radius * 1.25
		draw_line(inner, outer, Color(1.0, 1.0, 0.72, 0.86 * fade), 2.0)
	draw_circle(position, radius * 0.64, Color(1.0, 1.0, 1.0, fade))


func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var one_minus_t: float = 1.0 - t
	return a * one_minus_t * one_minus_t + b * 2.0 * one_minus_t * t + c * t * t
