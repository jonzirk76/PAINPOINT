extends Resource
class_name AgentBossProgram

const NORMAL_STRAFE := "strafe"
const NORMAL_PUSH_FORWARD := "push_forward"
const NORMAL_ZIG_ZAG := "zig_zag"
const NORMAL_PULL_BACK := "pull_back"

const PERSONALITY_HUNTER := "hunter"
const PERSONALITY_BULLY := "bully"
const PERSONALITY_COWARD := "coward"
const PERSONALITY_DUELIST := "duelist"

const SLOW_ATTACK_FAST_SINGLE := "fast_single"
const SLOW_ATTACK_SHORT_SCATTER := "short_scatter"
const SLOW_ATTACK_WIDE_SCATTER := "wide_scatter"
const SLOW_ATTACK_ASSAULT_BURST := "assault_burst"

const SPECIAL_MOVEMENT_TELEPORT_LOS := "teleport_los"
const SPECIAL_MOVEMENT_DASH_CHAIN := "dash_chain"
const SPECIAL_MOVEMENT_CHARGE := "charge"

const SPECIAL_REPOSITION_APPROACH := "approach"
const SPECIAL_REPOSITION_RETREAT := "retreat"
const SPECIAL_REPOSITION_STRAFE := "strafe"

const HIGH_EXPLOSIVE_ROCKET := "rocket"
const HIGH_EXPLOSIVE_GRENADE := "grenade"
const HIGH_EXPLOSIVE_MINES := "mines"

const SPECIAL_ATTACK_SMALL_FAST_BULLET := "small_fast_bullet"
const SPECIAL_ATTACK_ROCKET := "rocket"
const SPECIAL_ATTACK_MINIGUN_SWEEP_TWICE := "minigun_sweep_twice"
const SPECIAL_ATTACK_SPIRAL_CLOCKWISE := "spiral_clockwise"
const SPECIAL_ATTACK_SPIRAL_COUNTER_CLOCKWISE := "spiral_counter_clockwise"
const SPECIAL_ATTACK_RING_PULSE := "ring_pulse_three_waves"
const SPECIAL_ATTACK_PINWHEEL_BURST := "pinwheel_burst"

## Records the deterministic seed used to build this agent loadout.
@export var generation_seed: int = 1
## Controls the movement personality used to bias tactical repositioning.
@export_enum("hunter", "bully", "coward", "duelist") var personality_verb: String = PERSONALITY_HUNTER
## Controls which tactical movement verb the agent uses during normal actions.
@export_enum("strafe", "push_forward", "zig_zag", "pull_back") var normal_movement_verb: String = NORMAL_STRAFE
## Controls which weapon pattern the agent uses during slow pressure.
@export_enum("fast_single", "short_scatter", "wide_scatter", "assault_burst") var slow_attack_verb: String = SLOW_ATTACK_FAST_SINGLE
## Controls which fast movement setup the agent uses before its special attack.
@export_enum("teleport_los", "dash_chain", "charge") var special_movement_verb: String = SPECIAL_MOVEMENT_TELEPORT_LOS
## Controls whether special movement approaches, retreats, or strafes around the player.
@export_enum("approach", "retreat", "strafe") var special_reposition_verb: String = SPECIAL_REPOSITION_APPROACH
## Controls which hostile special attack the agent uses after its special movement.
@export_enum("minigun_sweep_twice", "spiral_clockwise", "spiral_counter_clockwise", "ring_pulse_three_waves", "pinwheel_burst") var special_attack_verb: String = SPECIAL_ATTACK_RING_PULSE
## Controls which high-explosive move may trigger during normal movement.
@export_enum("rocket", "grenade", "mines") var high_explosive_verb: String = HIGH_EXPLOSIVE_ROCKET
## Weighted chance for slow pressure actions after the current action completes.
@export var slow_action_weight: float = 0.33
## Weighted chance for normal movement actions after the current action completes.
@export var normal_action_weight: float = 0.33
## Weighted chance for special movement and special attack actions after the current action completes.
@export var special_action_weight: float = 0.33
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
## Controls how long the agent waits shielded during the boss alert intro.
@export var intro_seconds: float = 2.35
## Controls how many red alert pulses play during the boss alert intro.
@export var intro_alert_flash_count: int = 3
## Controls how long the bottom boss healthbar takes to fill during the intro.
@export var intro_health_fill_seconds: float = 1.45
## Controls how long the slow pressure action lasts before choosing a new action.
@export var slow_action_seconds: float = 1.45
## Controls how quickly the agent drifts during slow pressure.
@export var slow_move_speed: float = 58.0
## Controls how quickly the agent fires during slow pressure.
@export var slow_shot_cooldown: float = 0.25
## Controls hostile projectile speed during slow pressure.
@export var slow_projectile_speed: float = 390.0
## Controls hostile projectile radius during slow pressure.
@export var slow_projectile_radius: float = 4.7
## Controls how long short scatter slow-pressure bullets stay alive.
@export var slow_short_scatter_lifetime: float = 0.72
## Controls how quickly the short scatter slow-pressure pattern fires.
@export var slow_short_scatter_cooldown: float = 0.58
## Controls how many bullets the short scatter slow-pressure pattern fires.
@export var slow_short_scatter_projectile_count: int = 4
## Controls the spread width of the short scatter slow-pressure pattern.
@export var slow_short_scatter_degrees: float = 34.0
## Controls how long wide scatter slow-pressure bullets stay alive.
@export var slow_wide_scatter_lifetime: float = 0.62
## Controls how quickly the wide scatter slow-pressure pattern fires.
@export var slow_wide_scatter_cooldown: float = 0.96
## Controls how many bullets the wide scatter slow-pressure pattern fires.
@export var slow_wide_scatter_projectile_count: int = 7
## Controls the spread width of the wide scatter slow-pressure pattern.
@export var slow_wide_scatter_degrees: float = 82.0
## Controls how quickly the assault burst slow-pressure pattern starts another burst.
@export var slow_assault_burst_cooldown: float = 0.82
## Controls how many bullets are emitted by one assault burst.
@export var slow_assault_burst_count: int = 3
## Controls the delay between individual assault burst bullets.
@export var slow_assault_burst_interval: float = 0.075
## Controls how long assault burst bullets stay alive.
@export var slow_assault_burst_lifetime: float = 1.05
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
## Controls the chance to trigger a high-explosive move when normal movement begins and the explosive cooldown is ready.
@export var high_explosive_action_chance: float = 0.25
## Controls the cooldown after a high-explosive move triggers during normal movement.
@export var high_explosive_cooldown_seconds: float = 6.7
## Controls how long high-explosive moves visibly wind up before launching or placing.
@export var high_explosive_windup_seconds: float = 0.42
## Multiplies the shared high-explosive windup when the selected move is rocket.
@export var high_explosive_rocket_windup_multiplier: float = 2.0
## Controls high-explosive rocket projectile speed.
@export var high_explosive_rocket_speed: float = 580.0
## Controls high-explosive rocket blast radius.
@export var high_explosive_rocket_radius: float = 72.0
## Controls high-explosive grenade projectile speed.
@export var high_explosive_grenade_speed: float = 310.0
## Controls high-explosive grenade blast radius.
@export var high_explosive_grenade_radius: float = 68.0
## Controls the longest time a lobbed grenade can stay airborne before landing.
@export var high_explosive_grenade_max_air_seconds: float = 1.22
## Controls how many mines are placed by one high-explosive mine move.
@export var high_explosive_mine_count: int = 3
## Controls the delay between each placed mine.
@export var high_explosive_mine_interval: float = 0.26
## Controls how long placed mines wait before detonating on their own.
@export var high_explosive_mine_lifetime: float = 2.75
## Controls how long each mine spends in its short thrown arc before arming.
@export var high_explosive_mine_throw_seconds: float = 0.32
## Controls how far mine throws land from the agent.
@export var high_explosive_mine_throw_distance: float = 126.0
## Controls the fan width used when placing multiple thrown mines.
@export var high_explosive_mine_spread_degrees: float = 92.0
## Controls how close the player must get to trigger a mine.
@export var high_explosive_mine_trigger_radius: float = 20.0
## Controls high-explosive mine blast radius.
@export var high_explosive_mine_blast_radius: float = 46.0
## Controls how often coward personalities choose a direct aggressive movement instead of retreating or strafing.
@export var coward_aggression_chance: float = 0.18
## Controls the spacing duelist personalities try to maintain from the player.
@export var duelist_preferred_distance: float = 255.0
## Controls how far from preferred spacing duelists can drift before repositioning in or out.
@export var duelist_distance_band: float = 58.0
## Controls how far normal push and pull verbs try to move before steering fallback.
@export var normal_tactical_distance: float = 230.0
## Controls how long the agent telegraphs after fast movement before firing the special.
@export var special_telegraph_seconds: float = 0.58
## Controls how far teleport and dash setup moves can travel.
@export var special_move_distance: float = 330.0
## Controls how long teleport warns before the agent relocates.
@export var teleport_cast_seconds: float = 0.42
## Controls the normal cooldown after one special movement plus special attack.
@export var special_base_cooldown_seconds: float = 5.6
## Adds cooldown for each extra chained special beyond the first.
@export var special_chain_cooldown_bonus_seconds: float = 3.3
## Controls the chance to immediately chain another special after one completes.
@export var special_chain_chance: float = 0.44
## Reduces chain chance for each already completed chained special.
@export var special_chain_chance_decay: float = 0.18
## Controls the maximum number of special movement plus special attack combos in one chain.
@export var max_special_chain_count: int = 3
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
## Controls how many radial waves the ring pulse emits.
@export var pulse_wave_count: int = 3
## Controls how many bullets are emitted in each ring pulse wave.
@export var pulse_shots_per_wave: int = 24
## Controls how long the ring pulse waits between radial waves.
@export var pulse_wave_interval: float = 0.18
## Controls how much each ring pulse wave rotates from the previous wave.
@export var pulse_wave_rotation_degrees: float = 7.5
## Controls how many rotating pinwheel bursts are emitted.
@export var pinwheel_wave_count: int = 6
## Controls how many spokes each pinwheel burst emits.
@export var pinwheel_spoke_count: int = 6
## Controls how long the pinwheel waits between spoke bursts.
@export var pinwheel_wave_interval: float = 0.11
## Controls how far each pinwheel burst rotates from the previous burst.
@export var pinwheel_rotation_degrees: float = 18.0
## Controls how long the agent keeps its guns raised after firing.
@export var shoot_pose_hold_seconds: float = 0.42


func get_total_action_weight() -> float:
	return max(slow_action_weight, 0.0) + max(normal_action_weight, 0.0) + max(special_action_weight, 0.0)


func is_spiral_attack() -> bool:
	return special_attack_verb == SPECIAL_ATTACK_SPIRAL_CLOCKWISE or special_attack_verb == SPECIAL_ATTACK_SPIRAL_COUNTER_CLOCKWISE


func is_stream_or_pattern_attack() -> bool:
	return is_spiral_attack() or special_attack_verb == SPECIAL_ATTACK_MINIGUN_SWEEP_TWICE or special_attack_verb == SPECIAL_ATTACK_RING_PULSE or special_attack_verb == SPECIAL_ATTACK_PINWHEEL_BURST
