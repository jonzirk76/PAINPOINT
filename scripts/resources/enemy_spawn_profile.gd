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
