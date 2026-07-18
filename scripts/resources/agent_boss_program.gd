extends Resource
class_name AgentBossProgram

const NORMAL_STRAFE := "strafe"
const NORMAL_PUSH_FORWARD := "push_forward"
const NORMAL_ZIG_ZAG := "zig_zag"
const NORMAL_PULL_BACK := "pull_back"

const SPECIAL_MOVEMENT_TELEPORT_LOS := "teleport_los"
const SPECIAL_MOVEMENT_DASH_CHAIN := "dash_chain"
const SPECIAL_MOVEMENT_CHARGE := "charge"

const SPECIAL_ATTACK_SMALL_FAST_BULLET := "small_fast_bullet"
const SPECIAL_ATTACK_ROCKET := "rocket"
const SPECIAL_ATTACK_MINIGUN_SWEEP_TWICE := "minigun_sweep_twice"
const SPECIAL_ATTACK_SPIRAL_CLOCKWISE := "spiral_clockwise"
const SPECIAL_ATTACK_SPIRAL_COUNTER_CLOCKWISE := "spiral_counter_clockwise"

## Records the deterministic seed used to build this agent loadout.
@export var generation_seed: int = 1
## Controls which tactical movement verb the agent uses during normal actions.
@export_enum("strafe", "push_forward", "zig_zag", "pull_back") var normal_movement_verb: String = NORMAL_STRAFE
## Controls which fast movement setup the agent uses before its special attack.
@export_enum("teleport_los", "dash_chain", "charge") var special_movement_verb: String = SPECIAL_MOVEMENT_TELEPORT_LOS
## Controls which hostile special attack the agent uses after its special movement.
@export_enum("small_fast_bullet", "rocket", "minigun_sweep_twice", "spiral_clockwise", "spiral_counter_clockwise") var special_attack_verb: String = SPECIAL_ATTACK_SMALL_FAST_BULLET
## Weighted chance for slow pressure actions after the current action completes.
@export var slow_action_weight: float = 0.45
## Weighted chance for normal movement actions after the current action completes.
@export var normal_action_weight: float = 0.45
## Weighted chance for special movement and special attack actions after the current action completes.
@export var special_action_weight: float = 0.1
## Controls the generated agent's collision and visual body size; defaults to the player body radius.
@export var body_radius: float = 17.0
## Controls the generated agent's contact hit range; player-body overlap still adds both body radii.
@export var contact_radius: float = 24.0
## Modulates the player-like body art used by this agent.
@export var body_modulate: Color = Color(0.78, 0.25, 0.95)
## Modulates muzzle, telegraph, and ring accents used by this agent.
@export var accent_color: Color = Color(0.22, 1.0, 0.92)
## Modulates darker outline and boot details on the agent.
@export var shadow_color: Color = Color(0.08, 0.03, 0.16)
## Controls how long the slow pressure action lasts before choosing a new action.
@export var slow_action_seconds: float = 1.45
## Controls how quickly the agent drifts during slow pressure.
@export var slow_move_speed: float = 58.0
## Controls how quickly the agent fires during slow pressure.
@export var slow_shot_cooldown: float = 0.38
## Controls hostile projectile speed during slow pressure.
@export var slow_projectile_speed: float = 390.0
## Controls hostile projectile radius during slow pressure.
@export var slow_projectile_radius: float = 4.7
## Controls how long the normal movement action lasts before choosing a new action.
@export var normal_action_seconds: float = 1.7
## Controls how quickly the agent moves during its selected normal verb.
@export var normal_move_speed: float = 98.0
## Controls how quickly the agent fires during normal movement.
@export var normal_shot_cooldown: float = 1.05
## Controls hostile projectile speed during normal movement.
@export var normal_projectile_speed: float = 270.0
## Controls hostile projectile radius during normal movement.
@export var normal_projectile_radius: float = 7.0
## Controls how far normal push and pull verbs try to move before steering fallback.
@export var normal_tactical_distance: float = 230.0
## Controls how long the agent telegraphs after fast movement before firing the special.
@export var special_telegraph_seconds: float = 0.58
## Controls how far teleport and dash setup moves can travel.
@export var special_move_distance: float = 330.0
## Controls how quickly dash-chain movement crosses each selected lane.
@export var dash_speed: float = 560.0
## Controls how many valid dash endpoints the dash-chain verb attempts before the special.
@export var dash_count: int = 2
## Controls how long the charge verb warns before moving.
@export var charge_windup_seconds: float = 0.34
## Controls how long the charge verb moves before ending.
@export var charge_seconds: float = 0.62
## Controls charge movement speed.
@export var charge_speed: float = 420.0
## Controls how long the double-sweep minigun stream lasts.
@export var minigun_duration: float = 1.14
## Controls how often the minigun stream emits individual bullets.
@export var minigun_shot_interval: float = 0.055
## Controls the total angular sweep width of the minigun stream.
@export var minigun_sweep_degrees: float = 96.0
## Controls which side the minigun sweep starts from; -1 is left, 1 is right.
@export var minigun_start_side: int = 1
## Controls how long spiral spray lasts.
@export var spiral_duration: float = 1.18
## Controls how often spiral spray emits individual bullets.
@export var spiral_shot_interval: float = 0.075
## Controls how many rotations the spiral spray completes.
@export var spiral_rotations: float = 1.55
## Controls how long the agent keeps its guns raised after firing.
@export var shoot_pose_hold_seconds: float = 0.42


func get_total_action_weight() -> float:
	return max(slow_action_weight, 0.0) + max(normal_action_weight, 0.0) + max(special_action_weight, 0.0)


func is_spiral_attack() -> bool:
	return special_attack_verb == SPECIAL_ATTACK_SPIRAL_CLOCKWISE or special_attack_verb == SPECIAL_ATTACK_SPIRAL_COUNTER_CLOCKWISE
