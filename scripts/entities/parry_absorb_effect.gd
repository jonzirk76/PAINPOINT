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
var _arc_seed: float = 0.0


func initialize(from_position: Vector2, to_position: Vector2, perfect: bool, projectile_radius: float = 7.0, arc_seed: float = 0.0) -> void:
	start_position = from_position
	end_position = to_position
	is_perfect = perfect
	radius = max(projectile_radius, 3.0)
	_arc_seed = arc_seed
	global_position = Vector2.ZERO
	if is_perfect:
		lifetime_seconds = 0.46
	var delta: Vector2 = end_position - start_position
	var normal: Vector2 = delta.orthogonal().normalized() if delta.length_squared() > 0.001 else Vector2.UP
	var seed_basis: float = start_position.x * 0.37 + start_position.y * 0.61 + end_position.x * 0.19 + end_position.y * 0.43 + _arc_seed
	var side: float = -1.0 if _hash01(seed_basis) < 0.5 else 1.0
	var bend_ratio: float = lerp(0.25, 0.48, _hash01(seed_basis + 17.0))
	var mid_ratio: float = lerp(0.38, 0.66, _hash01(seed_basis + 41.0))
	var swoop_distance: float = clamp(delta.length() * bend_ratio, 42.0, 176.0)
	if is_perfect:
		swoop_distance *= 1.22
	_control_position = start_position.lerp(end_position, mid_ratio) + normal * swoop_distance * side
	queue_redraw()


func offset_world_position(offset: Vector2) -> void:
	if offset == Vector2.ZERO:
		return
	start_position += offset
	end_position += offset
	_control_position += offset
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


func _draw_perfect_shine(shine_position: Vector2, fade: float, progress: float) -> void:
	var pulse: float = 0.5 + 0.5 * sin(progress * TAU * 2.0)
	var shine_radius: float = radius * (2.1 + pulse * 0.7)
	draw_circle(shine_position, radius * (1.35 + pulse * 0.3), Color(1.0, 1.0, 0.92, 0.82 * fade))
	draw_arc(shine_position, shine_radius, 0.0, TAU, 28, Color(1.0, 0.95, 0.46, 0.78 * fade), 3.0)
	for index in range(8):
		var direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(index) / 8.0 + progress * TAU * 0.5)
		var inner: Vector2 = shine_position + direction * radius * 0.75
		var outer: Vector2 = shine_position + direction * shine_radius * 1.25
		draw_line(inner, outer, Color(1.0, 1.0, 0.72, 0.86 * fade), 2.0)
	draw_circle(shine_position, radius * 0.64, Color(1.0, 1.0, 1.0, fade))


func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var one_minus_t: float = 1.0 - t
	return a * one_minus_t * one_minus_t + b * 2.0 * one_minus_t * t + c * t * t


func _hash01(value: float) -> float:
	var raw: float = sin(value * 12.9898 + 78.233) * 43758.5453
	return raw - floor(raw)
