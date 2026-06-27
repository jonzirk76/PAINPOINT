extends Node2D
class_name ExplosionEffect

signal expired(effect)

@export var lifetime_seconds: float = 0.28

var radius: float = 80.0
var _age: float = 0.0


func initialize(spawn_position: Vector2, effect_radius: float) -> void:
	global_position = spawn_position
	radius = effect_radius
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
	draw_circle(Vector2.ZERO, radius * (0.35 + progress * 0.65), Color(1.0, 0.22, 0.04, alpha * 0.28))
	draw_arc(Vector2.ZERO, radius * (0.45 + progress * 0.55), 0.0, TAU, 40, Color(1.0, 0.8, 0.15, alpha), 5.0)
	draw_arc(Vector2.ZERO, radius * (0.2 + progress * 0.35), 0.0, TAU, 32, Color(1.0, 1.0, 0.8, alpha), 3.0)
