extends CharacterBody2D

const DIRECTION_COUNT := 8

## [Description] Movement speed used by the isolated neutral humanoid test drive.
@export_range(40.0, 600.0, 5.0) var speed: float = 260.0
## [Description] Radius of the gameplay collision circle beneath the polygon construction.
@export_range(4.0, 48.0, 1.0) var body_radius: float = 17.0
## [Description] World scale applied to the authored neutral polygon views.
@export_range(0.05, 1.0, 0.01) var visual_scale: float = 0.24
## [Description] Vertical offset that places collision around the body while the node origin remains at the feet for depth sorting.
@export_range(-80.0, 40.0, 1.0) var collision_vertical_offset: float = -22.0

@onready var visual: NativeHumanoidTwistRuntime = $NeutralNativeTwistRuntime
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _move_vector: Vector2 = Vector2.ZERO
var _direction: int = 0
var _aim_direction: Vector2 = Vector2.ZERO
var _has_aim_direction: bool = false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 96
	add_to_group("player")
	_sync_tuning()
	_update_visual_pose()


func _physics_process(_delta: float) -> void:
	velocity = _move_vector * speed
	move_and_slide()


func set_move_vector(value: Vector2) -> void:
	_move_vector = value.limit_length(1.0)
	var is_walking := _move_vector.length_squared() > 0.01
	if is_walking:
		var next_direction := _direction_from_vector(_move_vector)
		if next_direction != _direction:
			_direction = next_direction
	_update_visual_pose()


func set_aim_vector(value: Vector2) -> void:
	if value.length_squared() <= 0.01:
		clear_aim_vector()
		return
	_aim_direction = value.normalized()
	_has_aim_direction = true
	_update_visual_pose()


func clear_aim_vector() -> void:
	if not _has_aim_direction:
		return
	_has_aim_direction = false
	_aim_direction = Vector2.ZERO
	_update_visual_pose()


func has_aim_vector() -> bool:
	return _has_aim_direction


func get_twist_pose_directions() -> PackedInt32Array:
	return visual.get_pose_directions()


func set_torso_hip_seam_enabled(_value: bool) -> void:
	pass


func is_torso_hip_seam_enabled() -> bool:
	return false


func adjust_foreshortening(delta: float) -> void:
	visual.set_foreshortening(visual.get_foreshortening() + delta)


func get_foreshortening() -> float:
	return visual.get_foreshortening()


func get_perspective_world_rect() -> Rect2:
	var visual_extent := Vector2(34.0, 54.0)
	return Rect2(global_position - Vector2(visual_extent.x, visual_extent.y), visual_extent * 2.0)


func _direction_from_vector(value: Vector2) -> int:
	var octant := roundi((value.angle() - PI * 0.5) / (PI * 0.25))
	return wrapi(octant, 0, DIRECTION_COUNT)


func _update_visual_pose() -> void:
	var desired_direction := _direction
	if _has_aim_direction:
		desired_direction = _direction_from_vector(_aim_direction)
	visual.set_pose(
		_direction,
		desired_direction,
		_move_vector.length_squared() > 0.01,
		_aim_direction if _has_aim_direction else Vector2.ZERO
	)


func _sync_tuning() -> void:
	visual.scale = Vector2.ONE * visual_scale
	collision_shape.position.y = collision_vertical_offset
	var circle := collision_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		collision_shape.shape = circle
	circle.radius = body_radius
