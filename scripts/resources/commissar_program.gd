extends Resource
class_name CommissarProgram

## [Description] Identifies the veteran ability tier selected for this Commissar profile.
@export_range(1, 8, 1) var tier: int = 1
## [Description] Controls how long the reactive personal projectile shield remains active.
@export var reactive_shield_seconds: float = 1.0
## [Description] Controls how soon the Commissar can raise its reactive shield again.
@export var reactive_shield_cooldown: float = 3.8
## [Description] Controls how far the Commissar tries to reposition after raising its shield.
@export var reposition_distance: float = 180.0
## [Description] Multiplies movement speed while the Commissar performs a defensive reposition.
@export var reposition_speed_multiplier: float = 1.65
## [Description] Controls how soon the Commissar can begin another pushing charge.
@export var charge_cooldown: float = 4.8
## [Description] Controls the player distance at which the Commissar considers a pushing charge.
@export var charge_trigger_distance: float = 185.0
## [Description] Controls the warning time before a Commissar charge begins.
@export var charge_telegraph_seconds: float = 0.62
## [Description] Controls the Commissar's movement speed during its pushing charge.
@export var charge_speed: float = 820.0
## [Description] Controls the longest time a Commissar charge may remain active.
@export var charge_duration: float = 0.46
## [Description] Controls how strongly a successful Commissar charge pushes the player.
@export var charge_push_force: float = 520.0
## [Description] Controls the knockback carried by the Commissar's heavy ranged shot.
@export var heavy_shot_knockback: float = 220.0
## [Description] Controls the opening delay before the first repair-drone discipline event.
@export var first_discipline_delay: float = 4.5
## [Description] Controls the delay between repair-drone discipline events.
@export var discipline_interval: float = 9.0
## [Description] Controls how long the Commissar telegraphs an execution attempt.
@export var execution_telegraph_seconds: float = 1.2
## [Description] Controls how sharply a Commissar execution bullet can correct its aim while pursuing a rogue drone.
@export_range(90.0, 1440.0, 15.0) var execution_homing_turn_speed_degrees: float = 720.0
## [Description] Controls how long a Commissar execution bullet may pursue a rogue drone before expiring.
@export var execution_projectile_lifetime_seconds: float = 3.0
## [Description] Controls how long a rogue repair drone has to escape an execution attempt.
@export var rogue_escape_seconds: float = 4.8
## [Description] Prevents discipline events until the corps has at least this many coordinated repair drones.
@export_range(1, 8, 1) var minimum_corps_for_discipline: int = 2
## [Description] Controls how long an orphaned repair drone without a nearby repair target panics before retreating from combat.
@export var orphan_retreat_delay: float = 3.2
