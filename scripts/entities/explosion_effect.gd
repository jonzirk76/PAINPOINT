extends Node2D
class_name ExplosionEffect

signal expired(effect)

@export var lifetime_seconds: float = 0.28

var radius: float = 80.0
var _age: float = 0.0


func initialize(spawn_position: Vector2, effect_radius: float, effect_lifetime: float = -1.0) -> void:
	global_position = spawn_position
	radius = effect_radius
	if effect_lifetime > 0.0:
		lifetime_seconds = effect_lifetime
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
	var alpha: float = 1.0 - progress
	draw_circle(Vector2.ZERO, radius * (0.24 + progress * 0.76), Color(1.0, 0.22, 0.04, alpha * 0.28))
	draw_circle(Vector2.ZERO, radius * (0.1 + progress * 0.22), Color(1.0, 0.95, 0.72, alpha * 0.72))
	draw_arc(Vector2.ZERO, radius * (0.45 + progress * 0.55), 0.0, TAU, 48, Color(1.0, 0.8, 0.15, alpha), 6.0)
	draw_arc(Vector2.ZERO, radius * (0.2 + progress * 0.35), 0.0, TAU, 36, Color(1.0, 1.0, 0.8, alpha), 3.5)
	for index in range(12):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 12.0)
		var start := direction * radius * (0.08 + progress * 0.12)
		var end := direction * radius * (0.42 + progress * 0.7)
		draw_line(start, end, Color(1.0, 0.58, 0.08, alpha * 0.9), 2.0 + alpha * 4.0)
