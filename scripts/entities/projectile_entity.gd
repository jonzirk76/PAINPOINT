extends Area2D
class_name ProjectileEntity

signal hit_detected(projectile, target: Node)
signal expired(projectile)

@export var speed: float = 560.0
@export var lifetime_seconds: float = 1.2
@export var body_radius: float = 6.0

var direction: Vector2 = Vector2.RIGHT
var damage_packet = null
var pierce_remaining: int = 0
var hit_targets: Array[Node] = []
var _age: float = 0.0
var _is_expired: bool = false
var _base_body_radius: float = 6.0
var _collision_shape: CollisionShape2D = null


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false
	_add_collision()
	body_entered.connect(_on_body_entered)
	queue_redraw()


func initialize(origin: Vector2, shot_direction: Vector2, packet, projectile_speed: float) -> void:
	global_position = origin
	if shot_direction.length_squared() > 0.001:
		direction = shot_direction.normalized()
	damage_packet = packet
	speed = projectile_speed
	pierce_remaining = packet.pierce_count if packet != null else 0
	_base_body_radius = body_radius * max(packet.projectile_size_multiplier if packet != null else 1.0, 0.1)
	body_radius = _base_body_radius
	_update_collision_radius()
	rotation = direction.angle()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _is_expired:
		return
	_age += delta
	global_position += direction * speed * delta
	_update_growth(delta)
	if _age >= lifetime_seconds:
		expire()


func _on_body_entered(body: Node) -> void:
	if _is_expired:
		return
	if not body.is_in_group("enemies"):
		return
	if hit_targets.has(body):
		return
	hit_targets.append(body)
	if damage_packet != null:
		damage_packet.hit_targets = hit_targets.duplicate()
	hit_detected.emit(self, body)
	if pierce_remaining <= 0:
		expire()
	else:
		pierce_remaining -= 1


func expire() -> void:
	if _is_expired:
		return
	_is_expired = true
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	expired.emit(self)
	queue_free()


func _draw() -> void:
	var fill_color := Color(1.0, 0.92, 0.24)
	var streak_color := Color(1.0, 0.42, 0.08)
	if damage_packet != null:
		match damage_packet.projectile_kind:
			"fire":
				fill_color = Color(1.0, 0.26, 0.08)
				streak_color = Color(1.0, 0.82, 0.16)
			"water":
				fill_color = Color(0.18, 0.62, 1.0)
				streak_color = Color(0.75, 0.95, 1.0)
	draw_circle(Vector2.ZERO, body_radius, fill_color)
	draw_line(Vector2.ZERO, Vector2(body_radius + 8.0, 0.0), streak_color, 3.0)


func _add_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = body_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)
	_collision_shape = collision_shape


func _update_growth(_delta: float) -> void:
	if damage_packet == null or damage_packet.projectile_growth_per_second <= 0.0:
		return
	var max_radius: float = _base_body_radius * max(damage_packet.projectile_max_size_multiplier, 1.0)
	body_radius = min(_base_body_radius + _base_body_radius * damage_packet.projectile_growth_per_second * _age, max_radius)
	_update_collision_radius()
	queue_redraw()


func _update_collision_radius() -> void:
	if _collision_shape == null or _collision_shape.shape == null:
		return
	_collision_shape.shape.radius = body_radius
