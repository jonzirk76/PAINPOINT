extends Area2D
class_name PickupEntity

signal collected(pickup, collector: Node, upgrade_effect)
signal expired(pickup)
signal focused(pickup, collector: Node, upgrade_effect)
signal focus_exited(pickup, collector: Node, upgrade_effect)

@export var body_radius: float = 14.0
@export var lifetime_seconds: float = 18.0

var upgrade_effect = null
var requires_confirm: bool = false
var choice_group_id: String = ""
var persistent_until_floor_change: bool = false
var _age: float = 0.0
var _is_expired: bool = false
var _focused_body: Node = null
var _collision_shape: CollisionShape2D = null
var _collision_add_deferred: bool = false


func _init() -> void:
	_add_collision()


func _ready() -> void:
	_set_area_collision_property("collision_layer", 8)
	_set_area_collision_property("collision_mask", 1)
	_set_area_collision_property("monitoring", true)
	_set_area_collision_property("monitorable", false)
	_add_collision()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func initialize(effect, spawn_position: Vector2, confirm_required: bool = false, reward_choice_group_id: String = "", persist_for_floor: bool = false) -> void:
	upgrade_effect = effect
	global_position = spawn_position
	requires_confirm = confirm_required
	choice_group_id = reward_choice_group_id
	persistent_until_floor_change = persist_for_floor
	queue_redraw()


func _process(delta: float) -> void:
	if _is_expired:
		return
	if persistent_until_floor_change or lifetime_seconds <= 0.0:
		return
	_age += delta
	if _age >= lifetime_seconds:
		expire()


func _on_body_entered(body: Node) -> void:
	if _is_expired:
		return
	if not body.is_in_group("player"):
		return
	if requires_confirm:
		_focused_body = body
		focused.emit(self, body, upgrade_effect)
		queue_redraw()
		return
	_collect(body)


func _on_body_exited(body: Node) -> void:
	if _is_expired or not requires_confirm or body != _focused_body:
		return
	focus_exited.emit(self, body, upgrade_effect)
	_focused_body = null
	queue_redraw()


func confirm_collect() -> void:
	if _is_expired or not requires_confirm or _focused_body == null:
		return
	_collect(_focused_body)


func _collect(body: Node) -> void:
	_is_expired = true
	_disable_collision_state()
	collected.emit(self, body, upgrade_effect)
	queue_free()


func expire() -> void:
	if _is_expired:
		return
	_is_expired = true
	_disable_collision_state()
	expired.emit(self)
	queue_free()


func _disable_collision_state() -> void:
	_collision_add_deferred = false
	if is_inside_tree() and Engine.is_in_physics_frame():
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		return
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0


func _draw() -> void:
	var color := Color(0.35, 1.0, 0.45)
	var is_permanent := false
	var is_heal := false
	var is_overdrive_ammo := false
	if upgrade_effect != null:
		var pickup_kind: String = upgrade_effect.get_pickup_kind() if upgrade_effect.has_method("get_pickup_kind") else "temporary"
		if pickup_kind == "permanent":
			is_permanent = true
			match upgrade_effect.get_stat_key():
				"fire_rate":
					color = Color(0.45, 0.95, 1.0)
				"move_speed":
					color = Color(0.35, 1.0, 0.35)
				"damage":
					color = Color(1.0, 0.36, 0.26)
				"projectile_size":
					color = Color(1.0, 0.58, 0.22)
		elif pickup_kind == "heal":
			is_heal = true
			color = Color(0.24, 1.0, 0.36)
		elif pickup_kind == "overdrive_ammo":
			is_overdrive_ammo = true
			color = Color(0.22, 0.58, 1.0)
		else:
			match upgrade_effect.upgrade_type:
				UpgradeEffect.UpgradeType.SPREAD:
					color = Color(1.0, 0.78, 0.25)
				UpgradeEffect.UpgradeType.PIERCING:
					color = Color(0.28, 1.0, 0.86)
				UpgradeEffect.UpgradeType.CHAIN_LIGHTNING:
					color = Color(0.86, 0.58, 1.0)
				UpgradeEffect.UpgradeType.FIRE:
					color = Color(1.0, 0.25, 0.08)
				UpgradeEffect.UpgradeType.WATER:
					color = Color(0.22, 0.66, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.01)
	var flash_radius: float = body_radius + 4.0 + pulse * 5.0
	if requires_confirm:
		flash_radius += 3.0
	draw_arc(Vector2.ZERO, flash_radius, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.28 + pulse * 0.45), 3.0)
	if is_permanent:
		var points := PackedVector2Array([
			Vector2(0.0, -body_radius),
			Vector2(body_radius, 0.0),
			Vector2(0.0, body_radius),
			Vector2(-body_radius, 0.0)
		])
		draw_colored_polygon(points, color)
	elif requires_confirm:
		var points := PackedVector2Array([
			Vector2(0.0, -body_radius),
			Vector2(body_radius * 0.86, -body_radius * 0.22),
			Vector2(body_radius * 0.54, body_radius),
			Vector2(-body_radius * 0.54, body_radius),
			Vector2(-body_radius * 0.86, -body_radius * 0.22)
		])
		draw_colored_polygon(points, color)
	else:
		draw_circle(Vector2.ZERO, body_radius, color)
	draw_arc(Vector2.ZERO, body_radius + 3.0, 0.0, TAU, 20, Color(0.08, 0.08, 0.09), 2.0)
	draw_line(Vector2(-body_radius * 0.65, 0.0), Vector2(body_radius * 0.65, 0.0), Color(0.08, 0.08, 0.09), 2.0)
	if is_permanent:
		draw_line(Vector2(0.0, -body_radius * 0.65), Vector2(0.0, body_radius * 0.65), Color(0.08, 0.08, 0.09), 2.0)
	if is_heal:
		draw_line(Vector2(0.0, -body_radius * 0.62), Vector2(0.0, body_radius * 0.62), Color(0.04, 0.09, 0.05), 3.0)
		draw_line(Vector2(-body_radius * 0.62, 0.0), Vector2(body_radius * 0.62, 0.0), Color(0.04, 0.09, 0.05), 3.0)
	if is_overdrive_ammo:
		draw_arc(Vector2.ZERO, body_radius * 0.55, -PI / 2.0, PI * 1.15, 18, Color(0.82, 0.95, 1.0), 3.0)
	if requires_confirm and _focused_body != null:
		draw_arc(Vector2.ZERO, body_radius + 10.0 + pulse * 4.0, 0.0, TAU, 28, Color(1.0, 1.0, 1.0, 0.72), 3.5)


func get_perspective_world_rect() -> Rect2:
	var visual_extent: float = body_radius + 15.0
	return Rect2(
		global_position - Vector2(visual_extent, visual_extent),
		Vector2.ONE * visual_extent * 2.0
	)


func _add_collision() -> void:
	if _collision_shape != null:
		_sync_collision_radius()
		return
	if _is_expired:
		return
	if is_inside_tree() and Engine.is_in_physics_frame():
		if not _collision_add_deferred:
			_collision_add_deferred = true
			call_deferred("_add_collision")
		return
	_collision_add_deferred = false
	var shape := CircleShape2D.new()
	shape.radius = body_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)
	_collision_shape = collision_shape
	_sync_collision_radius()


func _sync_collision_radius() -> void:
	if _collision_shape == null:
		return
	var shape := _collision_shape.shape as CircleShape2D
	if shape == null:
		shape = CircleShape2D.new()
		_collision_shape.shape = shape
	shape.radius = body_radius


func _set_area_collision_property(property_name: StringName, value: Variant) -> void:
	if is_inside_tree() and Engine.is_in_physics_frame():
		set_deferred(property_name, value)
		return
	set(property_name, value)
