extends Node2D
class_name EnemySpawnerEntity

signal spawn_ready(spawner, spawn_position: Vector2)

@export var spawn_interval: float = 2.8
@export var warmup_seconds: float = 1.0
@export var active: bool = true
@export var body_radius: float = 22.0

var _timer: float = 0.0


func _ready() -> void:
	_timer = max(warmup_seconds, 0.0)
	queue_redraw()


func _process(delta: float) -> void:
	if not active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = spawn_interval
		spawn_ready.emit(self, global_position)
		queue_redraw()


func set_enabled(value: bool) -> void:
	active = value


func _draw() -> void:
	draw_circle(Vector2.ZERO, body_radius, Color(0.58, 0.16, 0.84, 0.72))
	draw_arc(Vector2.ZERO, body_radius + 3.0, 0.0, TAU, 28, Color(0.95, 0.64, 1.0), 3.0)
	draw_line(Vector2(-body_radius, 0.0), Vector2(body_radius, 0.0), Color(0.95, 0.64, 1.0), 2.0)
	draw_line(Vector2(0.0, -body_radius), Vector2(0.0, body_radius), Color(0.95, 0.64, 1.0), 2.0)
