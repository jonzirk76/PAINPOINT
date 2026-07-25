extends StaticBody2D
class_name DestructiblePropEntity

signal health_changed(prop, old_value: int, new_value: int)
signal health_depleted(prop)

@export var prop_kind: String = "crate"
@export var max_health: int = 3
@export var score_value: int = 1
@export var drop_kind: String = "none"
@export var prop_size: Vector2 = Vector2(48.0, 48.0)

var health: int = max_health
var placement_resource = null
var _collision_shape: CollisionShape2D = null
var _collision_update_deferred: bool = false
var _hit_flash_remaining: float = 0.0
var _is_broken: bool = false


func _init() -> void:
	_configure_collision_identity()


func _ready() -> void:
	_configure_collision_identity()
	_add_or_update_collision()
	queue_redraw()


func initialize(placement) -> void:
	placement_resource = placement
	if placement == null:
		return
	global_position = placement.position
	prop_size = placement.size
	prop_kind = String(placement.prop_kind)
	max_health = max(int(placement.max_health), 1)
	health = max_health
	score_value = max(int(placement.score_value), 0)
	drop_kind = String(placement.drop_kind)
	_is_broken = false
	_configure_collision_identity()
	_add_or_update_collision()
	queue_redraw()


func take_damage(packet) -> bool:
	if packet == null or health <= 0 or _is_broken:
		return false
	var damage_amount: int = max(int(packet.damage), 0)
	if damage_amount <= 0:
		return false
	var old_health := health
	health = max(health - damage_amount, 0)
	_hit_flash_remaining = 0.12
	health_changed.emit(self, old_health, health)
	queue_redraw()
	if health <= 0:
		_break()
	return true


func is_super_shot_impact_target() -> bool:
	return true


func _process(delta: float) -> void:
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = max(_hit_flash_remaining - delta, 0.0)
		queue_redraw()


func _configure_collision_identity() -> void:
	_set_body_collision_property("collision_layer", 32)
	_set_body_collision_property("collision_mask", 0)
	add_to_group("arena_walls")
	add_to_group("destructible_props")


func _break() -> void:
	if _is_broken:
		return
	_is_broken = true
	_disable_collision_state()
	remove_from_group("arena_walls")
	remove_from_group("destructible_props")
	health_depleted.emit(self)


func _draw() -> void:
	var health_ratio: float = clamp(float(health) / float(max(max_health, 1)), 0.0, 1.0)
	var flash: float = clamp(_hit_flash_remaining / 0.12, 0.0, 1.0)
	match prop_kind:
		"barrel":
			_draw_barrel(health_ratio, flash)
		"chest":
			_draw_chest(health_ratio, flash)
		_:
			_draw_crate(health_ratio, flash)


func _draw_crate(health_ratio: float, flash: float) -> void:
	var rect := Rect2(-prop_size * 0.5, prop_size)
	var base := Color(0.48, 0.29, 0.13).lerp(Color(1.0, 0.86, 0.62), flash)
	draw_rect(rect, base, true)
	draw_rect(rect, Color(0.12, 0.08, 0.05), false, 3.0)
	draw_line(rect.position + Vector2(7.0, 7.0), rect.position + rect.size - Vector2(7.0, 7.0), Color(0.22, 0.12, 0.06), 3.0)
	draw_line(rect.position + Vector2(rect.size.x - 7.0, 7.0), rect.position + Vector2(7.0, rect.size.y - 7.0), Color(0.22, 0.12, 0.06), 3.0)
	_draw_damage_marks(rect, health_ratio)


func _draw_barrel(health_ratio: float, flash: float) -> void:
	var rect := Rect2(-prop_size * 0.5, prop_size)
	var base := Color(0.5, 0.16, 0.1).lerp(Color(1.0, 0.76, 0.5), flash)
	draw_rect(rect.grow(-3.0), base, true)
	draw_arc(Vector2.ZERO, min(prop_size.x, prop_size.y) * 0.5, 0.0, TAU, 28, Color(0.12, 0.06, 0.04), 3.0)
	draw_line(Vector2(-prop_size.x * 0.36, -prop_size.y * 0.22), Vector2(prop_size.x * 0.36, -prop_size.y * 0.22), Color(0.08, 0.06, 0.05), 3.0)
	draw_line(Vector2(-prop_size.x * 0.36, prop_size.y * 0.22), Vector2(prop_size.x * 0.36, prop_size.y * 0.22), Color(0.08, 0.06, 0.05), 3.0)
	_draw_damage_marks(rect, health_ratio)


func _draw_chest(health_ratio: float, flash: float) -> void:
	var rect := Rect2(-prop_size * 0.5, prop_size)
	var base := Color(0.42, 0.22, 0.08).lerp(Color(1.0, 0.92, 0.58), flash)
	draw_rect(rect, base, true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.38)), Color(0.58, 0.34, 0.12).lerp(Color(1.0, 0.96, 0.68), flash), true)
	draw_rect(rect, Color(0.1, 0.06, 0.03), false, 3.0)
	draw_line(Vector2(rect.position.x, 0.0), Vector2(rect.position.x + rect.size.x, 0.0), Color(0.92, 0.7, 0.18), 3.0)
	draw_rect(Rect2(Vector2(-6.0, -4.0), Vector2(12.0, 12.0)), Color(0.96, 0.78, 0.22), true)
	_draw_damage_marks(rect, health_ratio)


func _draw_damage_marks(rect: Rect2, health_ratio: float) -> void:
	if health_ratio > 0.72:
		return
	draw_line(rect.position + Vector2(rect.size.x * 0.28, rect.size.y * 0.16), rect.position + Vector2(rect.size.x * 0.48, rect.size.y * 0.44), Color(0.06, 0.04, 0.03), 2.0)
	if health_ratio > 0.38:
		return
	draw_line(rect.position + Vector2(rect.size.x * 0.64, rect.size.y * 0.22), rect.position + Vector2(rect.size.x * 0.42, rect.size.y * 0.72), Color(0.06, 0.04, 0.03), 2.0)


func _add_or_update_collision() -> void:
	if _is_broken:
		return
	if is_inside_tree() and Engine.is_in_physics_frame():
		if not _collision_update_deferred:
			_collision_update_deferred = true
			call_deferred("_add_or_update_collision")
		return
	_collision_update_deferred = false
	if _collision_shape == null:
		_collision_shape = CollisionShape2D.new()
		_collision_shape.name = "CollisionShape2D"
		add_child(_collision_shape)
	var shape := RectangleShape2D.new()
	shape.size = prop_size
	_collision_shape.shape = shape


func _disable_collision_state() -> void:
	_collision_update_deferred = false
	_set_body_collision_property("collision_layer", 0)
	_set_body_collision_property("collision_mask", 0)


func _set_body_collision_property(property_name: StringName, value: Variant) -> void:
	if is_inside_tree() and Engine.is_in_physics_frame():
		set_deferred(property_name, value)
		return
	set(property_name, value)
