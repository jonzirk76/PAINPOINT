extends Resource
class_name EnemyProfile

const BEHAVIOR_CHASER := "chaser"
const BEHAVIOR_SHOOTER := "shooter"
const BEHAVIOR_BOSS := "boss"

@export_enum("chaser", "shooter", "boss") var behavior_kind: String = BEHAVIOR_CHASER
@export var max_health: int = 3
@export var speed: float = 85.0
@export var contact_damage: int = 1
@export var contact_radius: float = 34.0
@export var contact_cooldown: float = 0.7
@export var score_value: int = 10
@export var body_radius: float = 18.0
@export var knockback_multiplier: float = 1.0
@export var body_color: Color = Color(1.0, 0.27, 0.22)
@export var accent_color: Color = Color(1.0, 0.72, 0.18)
@export var preferred_distance: float = 280.0
@export var distance_band: float = 70.0
@export var strafe_speed: float = 95.0
@export var shot_cooldown: float = 1.2
@export var projectile_speed: float = 250.0
@export var projectile_damage: int = 1
@export var projectile_radius: float = 7.0
@export var shot_projectile_count: int = 1
@export var shot_spread_degrees: float = 0.0
## Enables procedural agent boss behavior when this profile is spawned as a boss.
@export var agent_program: Resource = null
