extends Resource
class_name EnemySpawnProfile

## Selects the enemy profile spawned by a general.
@export var enemy_profile: Resource = null
## Controls the base delay between reinforcement requests.
@export var spawn_interval: float = 3.4
## Controls how many reinforcements are requested in one spawn cycle.
@export var spawn_batch_count: int = 1
## Controls how long the first reinforcement request waits after the general appears.
@export var warmup_seconds: float = 1.0
## Controls how early the general gains a projectile shield before spawning.
@export var projectile_shield_lead_seconds: float = 0.72
## Controls how long the general's projectile shield remains after spawning.
@export var projectile_shield_after_spawn_seconds: float = 0.34
## Identifies the initial tactics policy used for this general's legion.
@export_enum("independent", "fan_out", "concentrate", "intercept") var tactics_kind: String = "independent"
## Allows this general to switch tactics in response to player movement and arena position.
@export var adaptive_tactics: bool = false
## Player speeds at or below this value are treated as stationary and invite a fan-out maneuver.
@export var adaptive_stationary_speed: float = 34.0
## Minimum player speed required before outward movement can trigger an intercept maneuver.
@export var adaptive_intercept_speed: float = 92.0
## Minimum alignment between player velocity and the direction away from arena center for interception.
@export_range(-1.0, 1.0, 0.05) var adaptive_intercept_outward_dot: float = 0.45
## Normalized distance from arena center where outward movement begins triggering interception.
@export_range(0.0, 1.0, 0.05) var adaptive_intercept_edge_ratio: float = 0.48
## Minimum time an adaptive doctrine remains active before another doctrine can replace it.
@export var adaptive_tactic_hold_seconds: float = 0.85
## Selects the legacy-inspired procedural chassis used to distinguish this general from ordinary enemies.
@export_enum("basic", "fast", "shooter", "tank") var visual_kind: String = "basic"
