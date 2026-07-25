extends Area2D
class_name FloorExitPortalEntity

signal entered(portal)
signal focused(portal, body: Node)
signal focus_exited(portal, body: Node)

@export var portal_radius: float = 44.0

var _age: float = 0.0
var _active: bool = true
var _triggered: bool = false
var _focused_body: Node = null
var _collision_shape: CollisionShape2D = null
var _collision_add_deferred: bool = false


func _init() -> void:
	_add_collision()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_set_area_property("collision_layer", 0)
	_set_area_property("collision_mask", 1)
	_set_area_property("monitorable", false)
	add_to_group("floor_portals")
	_add_collision()
	_sync_active_state()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func initialize(spawn_position: Vector2, radius: float = 44.0, starts_active: bool = true) -> void:
	global_position = spawn_position
	portal_radius = max(radius, 18.0)
	_active = starts_active
	_triggered = false
	_focused_body = null
	_update_collision_radius()
	_sync_active_state()
	queue_redraw()


func set_active(value: bool) -> void:
	_active = value
	_triggered = false
	if not _active:
		clear_focus()
	_sync_active_state()
	queue_redraw()


func is_active() -> bool:
	return _active


func confirm_enter() -> void:
	if not _active or _triggered or _focused_body == null or not is_instance_valid(_focused_body):
		return
	_triggered = true
	entered.emit(self)
	queue_redraw()


func clear_focus() -> void:
	if _focused_body == null:
		return
	var previous_body := _focused_body
	_focused_body = null
	focus_exited.emit(self, previous_body)
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()


func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_age * 8.0)
	var swirl := _age * 2.2
	var alpha_scale := 1.0 if _active else 0.34
	var spin_scale := 1.0 if _active else 0.22
	draw_circle(Vector2.ZERO, portal_radius * (0.72 + pulse * 0.06), Color(0.22, 0.82, 1.0, (0.18 if _active else 0.06)))
	draw_circle(Vector2.ZERO, portal_radius * 0.38, Color(0.82, 1.0, 1.0, (0.2 + pulse * 0.12) * alpha_scale))
	draw_arc(Vector2.ZERO, portal_radius, swirl * spin_scale, swirl * spin_scale + TAU * 0.72, 54, Color(0.55, 1.0, 1.0, 0.88 * alpha_scale), 5.0)
	draw_arc(Vector2.ZERO, portal_radius * 0.66, -swirl * 1.3 * spin_scale, -swirl * 1.3 * spin_scale + TAU * 0.58, 42, Color(1.0, 0.92, 0.36, 0.72 * alpha_scale), 3.2)
	draw_arc(Vector2.ZERO, portal_radius * 1.18, -swirl * 0.7 * spin_scale, -swirl * 0.7 * spin_scale + TAU * 0.42, 42, Color(0.75, 0.45, 1.0, 0.58 * alpha_scale), 2.6)
	for index in range(6):
		var angle: float = swirl * spin_scale + TAU * float(index) / 6.0
		var start := Vector2.RIGHT.rotated(angle) * portal_radius * 0.34
		var end := Vector2.RIGHT.rotated(angle) * portal_radius * (0.84 + pulse * 0.12)
		draw_line(start, end, Color(1.0, 1.0, 1.0, (0.34 + pulse * 0.16) * alpha_scale), 2.0)
	if not _active:
		draw_arc(Vector2.ZERO, portal_radius * 0.48, 0.0, TAU, 36, Color(0.42, 0.58, 0.72, 0.62), 3.0)
		draw_line(Vector2(-portal_radius * 0.24, 0.0), Vector2(portal_radius * 0.24, 0.0), Color(0.42, 0.58, 0.72, 0.62), 3.0)
	elif _focused_body != null:
		draw_arc(Vector2.ZERO, portal_radius * 1.28 + pulse * 5.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.78), 4.0)


func _on_body_entered(body: Node) -> void:
	if not _active or _triggered or body == null or not body.is_in_group("player"):
		return
	_focused_body = body
	focused.emit(self, body)
	queue_redraw()


func _on_body_exited(body: Node) -> void:
	if body == null or body != _focused_body:
		return
	clear_focus()


func _add_collision() -> void:
	if _collision_shape != null:
		_update_collision_radius()
		_sync_active_state()
		return
	if is_inside_tree() and Engine.is_in_physics_frame():
		if not _collision_add_deferred:
			_collision_add_deferred = true
			call_deferred("_add_collision")
		return
	_collision_add_deferred = false
	var shape := CircleShape2D.new()
	shape.radius = portal_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	collision_shape.disabled = not _active
	add_child(collision_shape)
	_collision_shape = collision_shape
	_sync_active_state()


func _update_collision_radius() -> void:
	if _collision_shape == null or _collision_shape.shape == null:
		return
	_collision_shape.shape.radius = portal_radius


func _sync_active_state() -> void:
	_set_area_property("monitoring", _active)
	if _collision_shape != null:
		_set_collision_shape_disabled(not _active)


func _set_collision_shape_disabled(value: bool) -> void:
	if _collision_shape == null:
		return
	if is_inside_tree() and Engine.is_in_physics_frame():
		_collision_shape.set_deferred("disabled", value)
		return
	_collision_shape.disabled = value


func _set_area_property(property_name: StringName, value: Variant) -> void:
	if is_inside_tree() and Engine.is_in_physics_frame():
		set_deferred(property_name, value)
		return
	set(property_name, value)
