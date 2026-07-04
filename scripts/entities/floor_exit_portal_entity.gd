extends Area2D
class_name FloorExitPortalEntity

signal entered(portal)

@export var portal_radius: float = 44.0

var _age: float = 0.0
var _triggered: bool = false
var _collision_shape: CollisionShape2D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	add_to_group("floor_portals")
	_add_collision()
	body_entered.connect(_on_body_entered)
	queue_redraw()


func initialize(spawn_position: Vector2, radius: float = 44.0) -> void:
	global_position = spawn_position
	portal_radius = max(radius, 18.0)
	_update_collision_radius()
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()


func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_age * 8.0)
	var swirl := _age * 2.2
	draw_circle(Vector2.ZERO, portal_radius * (0.72 + pulse * 0.06), Color(0.22, 0.82, 1.0, 0.18))
	draw_circle(Vector2.ZERO, portal_radius * 0.38, Color(0.82, 1.0, 1.0, 0.2 + pulse * 0.12))
	draw_arc(Vector2.ZERO, portal_radius, swirl, swirl + TAU * 0.72, 54, Color(0.55, 1.0, 1.0, 0.88), 5.0)
	draw_arc(Vector2.ZERO, portal_radius * 0.66, -swirl * 1.3, -swirl * 1.3 + TAU * 0.58, 42, Color(1.0, 0.92, 0.36, 0.72), 3.2)
	draw_arc(Vector2.ZERO, portal_radius * 1.18, -swirl * 0.7, -swirl * 0.7 + TAU * 0.42, 42, Color(0.75, 0.45, 1.0, 0.58), 2.6)
	for index in range(6):
		var angle: float = swirl + TAU * float(index) / 6.0
		var start := Vector2.RIGHT.rotated(angle) * portal_radius * 0.34
		var end := Vector2.RIGHT.rotated(angle) * portal_radius * (0.84 + pulse * 0.12)
		draw_line(start, end, Color(1.0, 1.0, 1.0, 0.34 + pulse * 0.16), 2.0)


func _on_body_entered(body: Node) -> void:
	if _triggered or body == null or not body.is_in_group("player"):
		return
	_triggered = true
	entered.emit(self)


func _add_collision() -> void:
	if _collision_shape != null:
		return
	var shape := CircleShape2D.new()
	shape.radius = portal_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)
	_collision_shape = collision_shape


func _update_collision_radius() -> void:
	if _collision_shape == null or _collision_shape.shape == null:
		return
	_collision_shape.shape.radius = portal_radius
