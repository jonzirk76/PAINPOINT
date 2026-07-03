extends Node2D
class_name ProjectileImpactEffect

signal expired(effect)

@export var lifetime_seconds: float = 0.18
@export var spark_count: int = 7

var impact_radius: float = 7.0
var impact_direction: Vector2 = Vector2.RIGHT
var blocked: bool = false

var _age: float = 0.0
var _spark_directions: Array[Vector2] = []


func initialize(spawn_position: Vector2, direction: Vector2, projectile_radius: float = 7.0, is_blocked: bool = false) -> void:
	global_position = spawn_position
	impact_direction = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	impact_radius = max(projectile_radius, 3.0)
	blocked = is_blocked
	lifetime_seconds = 0.24 if blocked else 0.16
	_build_sparks()
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
	var fade: float = 1.0 - progress
	var core_color := Color(1.0, 0.92, 0.42, fade)
	var ring_color := Color(1.0, 0.46, 0.12, fade * 0.82)
	var spark_color := Color(1.0, 0.86, 0.32, fade * 0.86)
	if blocked:
		core_color = Color(0.9, 1.0, 1.0, fade)
		ring_color = Color(0.42, 0.95, 1.0, fade * 0.92)
		spark_color = Color(0.72, 1.0, 1.0, fade * 0.95)
	var radius: float = impact_radius * (1.3 + progress * (2.3 if blocked else 1.4))
	draw_circle(Vector2.ZERO, impact_radius * (0.95 + progress * 0.35), Color(core_color.r, core_color.g, core_color.b, core_color.a * 0.55))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, ring_color, 3.4 if blocked else 2.5)
	var splash_start := -impact_direction * impact_radius * 0.55
	for direction in _spark_directions:
		var length: float = impact_radius * (1.8 + progress * (3.0 if blocked else 2.0))
		var start := splash_start + direction * impact_radius * progress * 0.5
		var end := splash_start + direction * length
		draw_line(start, end, spark_color, 2.2 if blocked else 1.6)


func _build_sparks() -> void:
	_spark_directions.clear()
	var spread_angle := PI * 0.92
	for index in range(spark_count):
		var ratio := 0.0 if spark_count <= 1 else float(index) / float(spark_count - 1)
		var offset: float = lerp(-spread_angle * 0.5, spread_angle * 0.5, ratio)
		var length_jitter: float = 0.82 + _hash01(float(index) * 13.0 + global_position.x * 0.11 + global_position.y * 0.17) * 0.36
		_spark_directions.append((-impact_direction).rotated(offset) * length_jitter)


func _hash01(value: float) -> float:
	var raw: float = sin(value * 12.9898 + 78.233) * 43758.5453
	return raw - floor(raw)
