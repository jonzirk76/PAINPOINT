extends Node2D
class_name MuzzleFlashEffect

signal expired(effect)

@export var lifetime_seconds: float = 0.09
@export var flash_length: float = 34.0
@export var flash_width: float = 18.0
@export var core_color: Color = Color(1.0, 0.96, 0.42, 1.0)
@export var glow_color: Color = Color(1.0, 0.36, 0.08, 0.46)

var _age: float = 0.0


func initialize(spawn_position: Vector2, direction: Vector2, radius: float = 16.0) -> void:
	global_position = spawn_position
	if direction.length_squared() > 0.001:
		rotation = direction.normalized().angle()
	flash_length = max(flash_length, radius * 1.5)
	flash_width = max(flash_width, radius * 0.82)
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime_seconds:
		expired.emit(self)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var ratio: float = 1.0 - clamp(_age / max(lifetime_seconds, 0.001), 0.0, 1.0)
	var length := flash_length * (0.72 + ratio * 0.28)
	var width := flash_width * ratio
	var glow_points := PackedVector2Array([
		Vector2(0.0, -width * 0.55),
		Vector2(length, 0.0),
		Vector2(0.0, width * 0.55),
		Vector2(length * 0.2, 0.0)
	])
	var core_points := PackedVector2Array([
		Vector2(0.0, -width * 0.26),
		Vector2(length * 0.72, 0.0),
		Vector2(0.0, width * 0.26)
	])
	draw_colored_polygon(glow_points, Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * ratio))
	draw_colored_polygon(core_points, Color(core_color.r, core_color.g, core_color.b, core_color.a * ratio))
