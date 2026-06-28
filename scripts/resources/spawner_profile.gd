extends Resource
class_name SpawnerProfile

@export var enemy_profile: Resource = null
@export var max_health: int = 14
@export var spawn_interval: float = 3.4
@export var spawn_batch_count: int = 1
@export var body_radius: float = 31.0
@export var score_value: int = 75
@export var base_color: Color = Color(0.34, 0.28, 0.38)
@export var core_color: Color = Color(0.72, 0.24, 0.92)
@export var accent_color: Color = Color(0.52, 1.0, 0.42)
@export var shape_kind: String = "basic"
@export var shoots_projectiles: bool = false
@export var shot_cooldown: float = 1.8
@export var projectile_speed: float = 250.0
@export var projectile_damage: int = 1
@export var projectile_radius: float = 7.0
@export var shot_projectile_count: int = 1
@export var shot_spread_degrees: float = 0.0
@export var move_speed: float = 18.0
@export var preferred_distance: float = 340.0
@export var distance_band: float = 85.0
@export var strafe_speed: float = 8.0
