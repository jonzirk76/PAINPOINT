extends RefCounted
class_name AgentBossGenerator

const PLAYER_BODY_RADIUS := 17.0
const PLAYER_SIZED_CONTACT_RADIUS := 24.0
const MIN_BODY_SCALE := 0.95
const MAX_BODY_SCALE := 1.12

static func generate_profile(base_profile: Resource, run_seed: int, floor_number: int, level_id: String) -> EnemyProfile:
	var profile: EnemyProfile = EnemyProfile.new()
	if base_profile != null:
		profile = base_profile.duplicate(true) as EnemyProfile
	if profile == null:
		profile = EnemyProfile.new()
	var program: AgentBossProgram = generate_program(run_seed, floor_number, level_id)
	profile.behavior_kind = EnemyProfile.BEHAVIOR_BOSS
	profile.agent_program = program
	profile.body_radius = program.body_radius
	profile.contact_damage = 0
	profile.contact_radius = 0.0
	profile.body_color = program.body_modulate
	profile.accent_color = program.accent_color
	profile.shot_projectile_count = 1
	profile.shot_spread_degrees = 0.0
	profile.shot_cooldown = program.normal_shot_cooldown
	profile.projectile_speed = program.normal_projectile_speed
	profile.projectile_radius = program.normal_projectile_radius
	return profile


static func generate_program(run_seed: int, floor_number: int, level_id: String) -> AgentBossProgram:
	var program: AgentBossProgram = AgentBossProgram.new()
	var seed := _compute_generation_seed(run_seed, floor_number, level_id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	program.generation_seed = seed
	var body_scale: float = rng.randf_range(MIN_BODY_SCALE, MAX_BODY_SCALE)
	program.body_radius = PLAYER_BODY_RADIUS * body_scale
	program.contact_radius = max(PLAYER_SIZED_CONTACT_RADIUS * body_scale, program.body_radius + 5.0)
	program.normal_movement_verb = _pick_string(rng, [
		AgentBossProgram.NORMAL_STRAFE,
		AgentBossProgram.NORMAL_PUSH_FORWARD,
		AgentBossProgram.NORMAL_ZIG_ZAG,
		AgentBossProgram.NORMAL_PULL_BACK
	])
	program.slow_attack_verb = _pick_string(rng, [
		AgentBossProgram.SLOW_ATTACK_FAST_SINGLE,
		AgentBossProgram.SLOW_ATTACK_SHORT_SCATTER,
		AgentBossProgram.SLOW_ATTACK_WIDE_SCATTER,
		AgentBossProgram.SLOW_ATTACK_ASSAULT_BURST
	])
	program.special_movement_verb = _pick_string(rng, [
		AgentBossProgram.SPECIAL_MOVEMENT_TELEPORT_LOS,
		AgentBossProgram.SPECIAL_MOVEMENT_DASH_CHAIN,
		AgentBossProgram.SPECIAL_MOVEMENT_CHARGE
	])
	program.special_reposition_verb = _pick_string(rng, [
		AgentBossProgram.SPECIAL_REPOSITION_APPROACH,
		AgentBossProgram.SPECIAL_REPOSITION_RETREAT,
		AgentBossProgram.SPECIAL_REPOSITION_STRAFE
	])
	program.high_explosive_verb = _pick_string(rng, [
		AgentBossProgram.HIGH_EXPLOSIVE_ROCKET,
		AgentBossProgram.HIGH_EXPLOSIVE_GRENADE,
		AgentBossProgram.HIGH_EXPLOSIVE_MINES
	])
	program.special_attack_verb = _pick_string(rng, [
		AgentBossProgram.SPECIAL_ATTACK_MINIGUN_SWEEP_TWICE,
		AgentBossProgram.SPECIAL_ATTACK_SPIRAL_CLOCKWISE,
		AgentBossProgram.SPECIAL_ATTACK_SPIRAL_COUNTER_CLOCKWISE,
		AgentBossProgram.SPECIAL_ATTACK_RING_PULSE,
		AgentBossProgram.SPECIAL_ATTACK_PINWHEEL_BURST
	])
	var hue := rng.randf()
	program.body_modulate = Color.from_hsv(hue, 0.72, 0.95)
	program.accent_color = Color.from_hsv(fposmod(hue + rng.randf_range(0.28, 0.46), 1.0), 0.78, 1.0)
	program.shadow_color = Color.from_hsv(fposmod(hue + 0.56, 1.0), 0.74, 0.18)
	program.minigun_start_side = -1 if rng.randf() < 0.5 else 1
	return program


static func _pick_string(rng: RandomNumberGenerator, values: Array[String]) -> String:
	if values.is_empty():
		return ""
	return values[rng.randi_range(0, values.size() - 1)]


static func _compute_generation_seed(run_seed: int, floor_number: int, level_id: String) -> int:
	var mixed := int(run_seed) * 1103515245 + int(max(floor_number, 1)) * 1013904223 + _stable_hash(level_id)
	return max(posmod(mixed, 2147483647), 1)


static func _stable_hash(text: String) -> int:
	var hash_value := 2166136261
	for index in range(text.length()):
		hash_value = posmod((hash_value ^ text.unicode_at(index)) * 16777619, 2147483647)
	return hash_value
