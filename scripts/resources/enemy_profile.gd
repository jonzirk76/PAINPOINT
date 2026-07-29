extends Resource
class_name EnemyProfile

const BEHAVIOR_CHASER := "chaser"
const BEHAVIOR_SHOOTER := "shooter"
const BEHAVIOR_BOSS := "boss"
const BEHAVIOR_REPAIR_DRONE := "repair_drone"
const BEHAVIOR_SHIELD_DRONE := "shield_drone"
const BEHAVIOR_POWER_ARMOR := "power_armor"
const BEHAVIOR_CYBER_SOLDIER := "cyber_soldier"

@export_enum("chaser", "shooter", "boss", "repair_drone", "shield_drone", "power_armor", "cyber_soldier") var behavior_kind: String = BEHAVIOR_CHASER
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
## Gives this enemy a general's reinforcement-spawning capability when assigned.
@export var spawn_profile: EnemySpawnProfile = null
## Controls how far repair drones can restore allied enemies.
@export var repair_radius: float = 220.0
## Controls how much health one repair pulse restores.
@export var repair_amount: int = 1
## Controls the delay between repair pulses.
@export var repair_cooldown: float = 1.25
## Controls the health ratio below which repair drones consider an ally worth repairing.
@export_range(0.0, 1.0, 0.01) var repair_target_health_ratio: float = 0.92
## Controls the cooldown between non-boss special attack or reposition phases.
@export var special_cooldown: float = 3.0
## Controls the warning duration before non-boss special attacks fire.
@export var special_telegraph_seconds: float = 0.46
## Selects the primary non-boss special attack pattern for elite enemies.
@export var special_attack_kind: String = ""
## Selects the occasional secondary explosive attack for elite enemies.
@export var secondary_attack_kind: String = ""
## Selects the special movement phase used by tactical enemies.
@export var special_movement_kind: String = ""
## Controls how long minigun-style special streams last.
@export var special_minigun_duration: float = 0.82
## Controls the delay between individual minigun special bullets.
@export var special_minigun_shot_interval: float = 0.065
## Controls the total sweep angle of minigun special streams.
@export var special_minigun_sweep_degrees: float = 76.0
## Controls the fewest shots fired during autocannon special bursts.
@export var special_autocannon_min_shots: int = 2
## Controls the most shots fired during autocannon special bursts.
@export var special_autocannon_max_shots: int = 4
## Controls the delay between individual autocannon special shots.
@export var special_autocannon_shot_interval: float = 0.28
## Enables procedural agent boss behavior when this profile is spawned as a boss.
@export var agent_program: AgentBossProgram = null
