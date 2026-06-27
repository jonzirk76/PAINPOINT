extends Node2D
class_name ChainLightningEffect

signal expired(effect)

@export var lifetime_seconds: float = 0.18
@export var branch_count: int = 7
@export var jitter_strength: float = 18.0

var start_position: Vector2 = Vector2.ZERO
var end_position: Vector2 = Vector2.ZERO

var _age: float = 0.0
var _points: PackedVector2Array = PackedVector2Array()
var _side_points: PackedVector2Array = PackedVector2Array()
var _rng := RandomNumberGenerator.new()


func initialize(from_position: Vector2, to_position: Vector2) -> void:
	start_position = from_position
	end_position = to_position
	global_position = Vector2.ZERO
	_rng.seed = int(abs(from_position.x * 71.0 + from_position.y * 131.0 + to_position.x * 173.0 + to_position.y * 199.0))
	_rebuild_points()
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime_seconds:
		expired.emit(self)
		queue_free()
		return
	if int(_age * 60.0) % 2 == 0:
		_rebuild_points()
	queue_redraw()


func _draw() -> void:
	if _points.size() < 2:
		return
	var fade: float = 1.0 - clamp(_age / lifetime_seconds, 0.0, 1.0)
	for index in range(_side_points.size() - 1):
		draw_line(_side_points[index], _side_points[index + 1], Color(0.2, 0.72, 1.0, fade * 0.38), 3.0)
	for index in range(_points.size() - 1):
		draw_line(_points[index], _points[index + 1], Color(0.52, 0.96, 1.0, fade), 5.0)
		draw_line(_points[index], _points[index + 1], Color(1.0, 1.0, 1.0, fade), 2.0)
	draw_circle(start_position, 9.0 + 6.0 * fade, Color(0.55, 0.95, 1.0, fade * 0.75))
	draw_circle(end_position, 12.0 + 10.0 * fade, Color(1.0, 1.0, 1.0, fade * 0.65))


func _rebuild_points() -> void:
	_points.clear()
	_side_points.clear()
	var delta: Vector2 = end_position - start_position
	var normal: Vector2 = delta.orthogonal().normalized() if delta.length_squared() > 0.001 else Vector2.UP
	for index in range(branch_count + 1):
		var t := float(index) / float(branch_count)
		var point := start_position.lerp(end_position, t)
		if index > 0 and index < branch_count:
			point += normal * _rng.randf_range(-jitter_strength, jitter_strength)
		_points.append(point)
		if index % 2 == 0:
			_side_points.append(point + normal * _rng.randf_range(-jitter_strength * 0.7, jitter_strength * 0.7))
