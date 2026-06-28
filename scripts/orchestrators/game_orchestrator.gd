extends Node2D
class_name GameOrchestrator

const LEVELS := [
	preload("res://resources/levels/level_01_square.tres"),
	preload("res://resources/levels/level_02_diamond.tres"),
	preload("res://resources/levels/level_03_hexagon.tres"),
	preload("res://resources/levels/level_04_cross.tres"),
	preload("res://resources/levels/level_05_circle.tres"),
	preload("res://resources/levels/level_06_maze.tres")
]

@onready var input_manager = $Managers/InputManager
@onready var player_manager = $Managers/PlayerManager
@onready var projectile_manager = $Managers/ProjectileManager
@onready var enemy_manager = $Managers/EnemyManager
@onready var spawner_manager = $Managers/SpawnerManager
@onready var item_manager = $Managers/ItemManager
@onready var upgrade_manager = $Managers/UpgradeManager
@onready var combat_manager = $Managers/CombatManager
@onready var effects_manager = $Managers/EffectsManager
@onready var dungeon_manager = $Managers/DungeonManager
@onready var room_manager = $Managers/RoomManager
@onready var arena_view = $World/Arena
@onready var gameplay_camera: Camera2D = $Camera2D
@onready var hud_label: Label = $UI/HUDLabel
@onready var dungeon_minimap: Control = $UI/DungeonMinimap
@onready var combat_panel: Control = $UI/CombatPanel
@onready var health_fill: ColorRect = $UI/CombatPanel/HealthBarBack/HealthBarFill
@onready var health_label: Label = $UI/CombatPanel/HealthLabel
@onready var invulnerability_fill: ColorRect = $UI/CombatPanel/InvulnerabilityBarBack/InvulnerabilityBarFill
@onready var attribute_label: Label = $UI/CombatPanel/AttributeLabel
@onready var stats_label: Label = $UI/CombatPanel/StatsLabel
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var game_over_title_label: Label = $UI/GameOverPanel/GameOverTitle
@onready var game_over_score_label: Label = $UI/GameOverPanel/GameOverScoreLabel
@onready var game_over_tally_label: Label = $UI/GameOverPanel/GameOverTallyLabel
@onready var game_over_prompt_label: Label = $UI/GameOverPanel/GameOverPromptLabel
@onready var level_select_panel: Control = $UI/LevelSelectPanel
@onready var level_list_label: Label = $UI/LevelSelectPanel/LevelListLabel
@onready var win_panel: Control = $UI/WinPanel
@onready var win_title_label: Label = $UI/WinPanel/WinTitle
@onready var win_score_label: Label = $UI/WinPanel/WinScoreLabel
@onready var win_prompt_label: Label = $UI/WinPanel/WinPromptLabel

var _score: int = 0
var _last_health: int = 0
var _last_max_health: int = 0
var _last_invulnerability_remaining: float = 0.0
var _last_invulnerability_duration: float = 0.0
var _status: String = "RUNNING"
var _latest_modifiers: Dictionary = {}
var _attribute_modifiers: Dictionary = {}
var _permanent_stats: Array = []
var _selected_level_index: int = 0
var _current_level = null
var _is_dungeon_run: bool = false
var _is_main_loop_run: bool = false
var _is_loading_room: bool = false
var _main_loop_floor: int = 1
var _run_seed: int = 0
var _run_enemy_kills: int = 0
var _run_spawner_kills: int = 0
var _run_boss_kills: int = 0
var _run_pickups_collected: int = 0
var _run_ammo_upgrades: int = 0
var _run_permanent_upgrades: int = 0
var _run_heals: int = 0
var _run_floors_cleared: int = 0

const DUNGEON_OPTION_COUNT := 2


func _ready() -> void:
	_connect_manager_signals()
	_initialize_managers()
	_enter_level_select()


func _process(_delta: float) -> void:
	if _is_gameplay_running():
		_update_camera()


func _connect_manager_signals() -> void:
	input_manager.move_changed.connect(player_manager.set_move_vector)
	input_manager.aim_changed.connect(player_manager.set_aim_direction)
	input_manager.aim_fire_requested.connect(_on_aim_fire_requested)
	input_manager.restart_requested.connect(_on_restart_requested)
	input_manager.menu_up_requested.connect(_on_menu_up_requested)
	input_manager.menu_down_requested.connect(_on_menu_down_requested)
	input_manager.menu_confirm_requested.connect(_on_menu_confirm_requested)
	input_manager.menu_back_requested.connect(_on_menu_back_requested)

	player_manager.player_health_changed.connect(_on_player_health_changed)
	player_manager.player_invulnerability_changed.connect(_on_player_invulnerability_changed)
	player_manager.player_defeated.connect(_on_player_defeated)
	player_manager.shoot_requested.connect(_on_player_shoot_requested)

	projectile_manager.projectile_hit.connect(_on_projectile_hit)
	combat_manager.damage_resolved.connect(_on_damage_resolved)
	combat_manager.player_damage_resolved.connect(_on_player_damage_resolved)
	combat_manager.chain_requested.connect(_on_chain_requested)
	combat_manager.explosion_requested.connect(_on_explosion_requested)

	enemy_manager.enemy_defeated.connect(_on_enemy_defeated)
	enemy_manager.enemy_count_changed.connect(spawner_manager.set_enemy_count)
	enemy_manager.enemy_count_changed.connect(_on_enemy_count_changed)
	enemy_manager.player_contact_requested.connect(_on_player_contact_requested)
	enemy_manager.hostile_shot_requested.connect(_on_hostile_shot_requested)

	spawner_manager.spawn_requested.connect(_on_spawn_requested)
	spawner_manager.spawner_destroyed.connect(_on_spawner_destroyed)
	spawner_manager.spawner_count_changed.connect(_on_spawner_count_changed)
	spawner_manager.hostile_shot_requested.connect(_on_hostile_shot_requested)
	item_manager.pickup_collected.connect(_on_pickup_collected)
	item_manager.pickup_count_changed.connect(_on_pickup_count_changed)
	upgrade_manager.upgrade_changed.connect(_on_upgrade_changed)
	upgrade_manager.permanent_upgrades_changed.connect(_on_permanent_upgrades_changed)
	room_manager.door_entered.connect(_on_room_door_entered)


func _initialize_managers() -> void:
	input_manager.initialize({
		"aim_origin_provider": Callable(player_manager, "get_player_position")
	})
	player_manager.initialize({
		"player_layer": $World/PlayerLayer
	})
	projectile_manager.initialize({
		"projectile_layer": $World/ProjectileLayer
	})
	enemy_manager.initialize({
		"enemy_layer": $World/EnemyLayer,
		"player_position_provider": Callable(player_manager, "get_player_position"),
		"player_ref_provider": Callable(self, "_get_player_ref")
	})
	spawner_manager.initialize({
		"spawner_layer": $World/SpawnerLayer,
		"player_position_provider": Callable(player_manager, "get_player_position")
	})
	item_manager.initialize({
		"pickup_layer": $World/PickupLayer
	})
	upgrade_manager.initialize({})
	combat_manager.initialize({})
	effects_manager.initialize({
		"effect_layer": $World/EffectLayer
	})
	dungeon_manager.initialize({})
	room_manager.initialize({
		"door_layer": $World/DoorLayer
	})


func _start_selected_level() -> void:
	if _selected_level_index < LEVELS.size():
		_start_level(LEVELS[_selected_level_index])
	elif _selected_level_index == LEVELS.size():
		_start_dungeon_run()
	else:
		_start_main_loop_run()


func _start_level(level_definition) -> void:
	_is_dungeon_run = false
	_is_main_loop_run = false
	_current_level = level_definition
	_score = 0
	_run_seed = 0
	_reset_run_tally()
	_status = "STARTING"
	_last_health = 0
	_last_max_health = 0
	_last_invulnerability_remaining = 0.0
	_last_invulnerability_duration = 0.0
	_attribute_modifiers = {}
	_permanent_stats = []
	if level_select_panel != null:
		level_select_panel.visible = false
	if game_over_panel != null:
		game_over_panel.visible = false
	if win_panel != null:
		win_panel.visible = false
	if combat_panel != null:
		combat_panel.visible = true
	room_manager.reset_run()
	_clear_minimap()
	if arena_view != null:
		arena_view.configure(level_definition)
	player_manager.set_arena_definition(level_definition)
	projectile_manager.set_arena_definition(level_definition)
	enemy_manager.set_arena_definition(level_definition)
	spawner_manager.set_arena_definition(level_definition)
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	spawner_manager.reset_run(level_definition)
	item_manager.reset_run()
	upgrade_manager.reset_run()
	combat_manager.reset_run()
	effects_manager.reset_run()
	input_manager.reset_run()
	player_manager.reset_run()
	_set_all_enabled(true)
	_status = "RUNNING"
	_on_upgrade_changed(upgrade_manager.get_modifiers(), upgrade_manager.get_active_effects())
	_update_hud()


func _start_dungeon_run() -> void:
	_is_dungeon_run = true
	_is_main_loop_run = false
	_score = 0
	_main_loop_floor = 1
	_run_seed = _generate_run_seed()
	_reset_run_tally()
	_status = "STARTING"
	_last_health = 0
	_last_max_health = 0
	_last_invulnerability_remaining = 0.0
	_last_invulnerability_duration = 0.0
	_attribute_modifiers = {}
	_permanent_stats = []
	if level_select_panel != null:
		level_select_panel.visible = false
	if game_over_panel != null:
		game_over_panel.visible = false
	if win_panel != null:
		win_panel.visible = false
	if combat_panel != null:
		combat_panel.visible = true
	dungeon_manager.reset_run(_main_loop_floor, _run_seed)
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	spawner_manager.clear_spawners()
	item_manager.clear_pickups()
	upgrade_manager.reset_run()
	combat_manager.reset_run()
	effects_manager.reset_run()
	room_manager.reset_run()
	input_manager.reset_run()
	_status = "DUNGEON"
	_load_dungeon_current_room("", true)
	_on_upgrade_changed(upgrade_manager.get_modifiers(), upgrade_manager.get_active_effects())
	_update_hud()


func _start_main_loop_run() -> void:
	_is_dungeon_run = true
	_is_main_loop_run = true
	_score = 0
	_main_loop_floor = 1
	_run_seed = _generate_run_seed()
	_reset_run_tally()
	_status = "STARTING"
	_last_health = 0
	_last_max_health = 0
	_last_invulnerability_remaining = 0.0
	_last_invulnerability_duration = 0.0
	_attribute_modifiers = {}
	_permanent_stats = []
	if level_select_panel != null:
		level_select_panel.visible = false
	if game_over_panel != null:
		game_over_panel.visible = false
	if win_panel != null:
		win_panel.visible = false
	if combat_panel != null:
		combat_panel.visible = true
	dungeon_manager.reset_run(_main_loop_floor, _run_seed)
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	spawner_manager.clear_spawners()
	item_manager.clear_pickups()
	upgrade_manager.reset_run()
	combat_manager.reset_run()
	effects_manager.reset_run()
	room_manager.reset_run()
	input_manager.reset_run()
	_status = "DUNGEON"
	_load_dungeon_current_room("", true)
	_on_upgrade_changed(upgrade_manager.get_modifiers(), upgrade_manager.get_active_effects())
	_update_hud()


func _advance_main_loop_floor() -> void:
	if not _is_main_loop_run:
		return
	_main_loop_floor += 1
	_status = "STARTING"
	if win_panel != null:
		win_panel.visible = false
	dungeon_manager.reset_run(_main_loop_floor, _run_seed)
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	spawner_manager.clear_spawners()
	item_manager.clear_pickups()
	effects_manager.reset_run()
	room_manager.reset_run()
	input_manager.reset_run()
	_status = "DUNGEON"
	_load_dungeon_current_room("", false)
	_update_hud()


func _enter_level_select() -> void:
	_status = "LEVEL_SELECT"
	_current_level = null
	_is_dungeon_run = false
	_is_main_loop_run = false
	_run_seed = 0
	_set_all_enabled(false)
	_clear_gameplay()
	_clear_minimap()
	if gameplay_camera != null:
		gameplay_camera.global_position = Vector2.ZERO
	if combat_panel != null:
		combat_panel.visible = false
	if game_over_panel != null:
		game_over_panel.visible = false
	if win_panel != null:
		win_panel.visible = false
	if level_select_panel != null:
		level_select_panel.visible = true
	_update_level_select_ui()
	_update_hud()


func _clear_gameplay() -> void:
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	spawner_manager.clear_spawners()
	item_manager.clear_pickups()
	upgrade_manager.reset_run()
	combat_manager.reset_run()
	effects_manager.reset_run()
	room_manager.reset_run()
	player_manager.clear_player()


func _set_all_enabled(value: bool) -> void:
	input_manager.set_enabled(value)
	player_manager.set_enabled(value)
	projectile_manager.set_enabled(value)
	enemy_manager.set_enabled(value)
	spawner_manager.set_enabled(value)
	item_manager.set_enabled(value)
	upgrade_manager.set_enabled(value)
	combat_manager.set_enabled(value)
	effects_manager.set_enabled(value)
	dungeon_manager.set_enabled(value and _is_dungeon_run)
	room_manager.set_enabled(value and _is_dungeon_run)


func _on_aim_fire_requested(direction: Vector2) -> void:
	player_manager.request_fire(direction)


func _on_player_shoot_requested(origin: Vector2, direction: Vector2) -> void:
	projectile_manager.fire(origin, direction, _latest_modifiers)
	upgrade_manager.consume_shot()


func _on_projectile_hit(projectile, target: Node, packet) -> void:
	combat_manager.resolve_projectile_hit(projectile, target, packet)


func _on_damage_resolved(target: Node, packet) -> void:
	if target == null or packet == null or not is_instance_valid(target):
		return
	if target.is_in_group("enemies"):
		enemy_manager.apply_damage(target, packet)
	elif target.is_in_group("spawners"):
		spawner_manager.apply_damage(target, packet)


func _on_chain_requested(origin_target: Node, packet) -> void:
	if origin_target == null or packet == null or not is_instance_valid(origin_target):
		return
	var excluded: Array[Node] = [origin_target]
	excluded.append_array(packet.hit_targets)
	var candidates = enemy_manager.get_nearby_enemies(origin_target.global_position, packet.chain_radius, excluded)
	candidates.append_array(spawner_manager.get_nearby_spawners(origin_target.global_position, packet.chain_radius, excluded))
	if candidates.is_empty():
		return
	var next_target = candidates[0]
	var chain_packet = packet.copy_for_chain()
	chain_packet.source_position = origin_target.global_position
	chain_packet.knockback_direction = (next_target.global_position - origin_target.global_position).normalized()
	chain_packet.hit_targets.append(next_target)
	effects_manager.play_chain_lightning(origin_target.global_position, next_target.global_position)
	combat_manager.resolve_chain_hit(next_target, chain_packet)


func _on_explosion_requested(origin: Vector2, packet) -> void:
	if packet == null or packet.explosion_radius <= 0.0:
		return
	effects_manager.play_explosion(origin, packet.explosion_radius)
	var explosion_packet = packet.copy_for_explosion()
	explosion_packet.source_position = origin
	var excluded: Array[Node] = packet.hit_targets.duplicate()
	var candidates = enemy_manager.get_nearby_enemies(origin, packet.explosion_radius, excluded)
	candidates.append_array(spawner_manager.get_nearby_spawners(origin, packet.explosion_radius, excluded))
	for target in candidates:
		explosion_packet.knockback_direction = (target.global_position - origin).normalized()
		_on_damage_resolved(target, explosion_packet)


func _on_player_contact_requested(enemy, player, damage: int) -> void:
	combat_manager.resolve_contact_damage(enemy, player, damage)


func _on_player_damage_resolved(amount: int) -> void:
	player_manager.apply_damage(amount)


func _on_spawn_requested(spawn_position: Vector2, profile) -> void:
	enemy_manager.spawn_enemy(profile, spawn_position)


func _on_hostile_shot_requested(origin: Vector2, direction: Vector2, shot_config: Dictionary) -> void:
	projectile_manager.fire_hostile(origin, direction, shot_config)


func _on_enemy_defeated(_enemy, score_value: int) -> void:
	_score += score_value
	if _enemy != null and is_instance_valid(_enemy):
		if _enemy.behavior_kind == "boss":
			_run_boss_kills += 1
			if _is_main_loop_run:
				_score += _get_boss_floor_bonus()
				_complete_main_loop_floor()
				_update_hud()
				return
		else:
			_run_enemy_kills += 1
		item_manager.roll_enemy_drop(_enemy.global_position)
	_update_hud()
	_check_level_clear()


func _on_spawner_destroyed(_spawner, score_value: int) -> void:
	if _spawner != null and is_instance_valid(_spawner):
		var explosion_radius: float = max(float(_spawner.body_radius) * 4.8, 150.0)
		effects_manager.play_spawner_explosion(_spawner.global_position, explosion_radius)
		item_manager.drop_spawner_reward(_spawner.global_position)
	_run_spawner_kills += 1
	_score += score_value
	_update_hud()
	_check_level_clear()


func _on_player_health_changed(_old_value: int, new_value: int) -> void:
	_last_health = new_value
	_last_max_health = player_manager.get_player_max_health()
	_update_hud()


func _on_player_invulnerability_changed(remaining: float, duration: float) -> void:
	_last_invulnerability_remaining = remaining
	_last_invulnerability_duration = duration
	_update_hud()


func _on_player_defeated(_player) -> void:
	_status = "DOWN"
	_set_all_enabled(false)
	_update_hud()


func _on_restart_requested() -> void:
	if _status == "DOWN" and _current_level != null:
		if _is_main_loop_run:
			_start_main_loop_run()
		elif _is_dungeon_run:
			_start_dungeon_run()
		else:
			_start_level(_current_level)


func _on_upgrade_changed(modifiers: Dictionary, _active_effects: Array) -> void:
	_latest_modifiers = modifiers
	player_manager.set_weapon_modifiers(modifiers)
	_update_hud()


func _on_permanent_upgrades_changed(attribute_modifiers: Dictionary, permanent_stats: Array) -> void:
	_attribute_modifiers = attribute_modifiers
	_permanent_stats = permanent_stats
	_update_hud()


func _on_enemy_count_changed(_count: int) -> void:
	_update_hud()
	_check_level_clear()


func _on_spawner_count_changed(_count: int) -> void:
	_update_hud()
	_check_level_clear()


func _on_pickup_count_changed(_count: int) -> void:
	_update_hud()


func _on_pickup_collected(pickup_resource) -> void:
	if pickup_resource == null:
		return
	_run_pickups_collected += 1
	if pickup_resource.has_method("get_pickup_kind") and pickup_resource.get_pickup_kind() == "heal":
		_run_heals += 1
		player_manager.apply_healing(int(pickup_resource.heal_amount))
	else:
		if pickup_resource.has_method("get_pickup_kind") and pickup_resource.get_pickup_kind() == "permanent":
			_run_permanent_upgrades += 1
		else:
			_run_ammo_upgrades += 1
		upgrade_manager.activate_pickup(pickup_resource)
	_update_hud()


func _get_player_ref():
	return player_manager.player


func _on_room_door_entered(direction: String) -> void:
	if not _is_dungeon_run or _status != "DUNGEON":
		return
	if dungeon_manager.enter_direction(direction):
		_load_dungeon_current_room(direction, false)


func _update_hud() -> void:
	if hud_label == null:
		return
	if _status == "LEVEL_SELECT":
		hud_label.text = "SHOOTY  |  LEVEL SELECT"
		return
	var active_effects: Array = upgrade_manager.get_active_effects()
	var upgrade_lines: Array[String] = _get_upgrade_lines(active_effects)
	var upgrade_text: String = "none" if upgrade_lines.is_empty() else "\n".join(upgrade_lines)
	var footer: String = "WASD/Left Stick move. Right Stick, Arrows, or hold LMB and move mouse to fire on aim changes."
	if _status == "DOWN":
		footer = "DOWN. Press R or Start/A on controller to restart."
	elif _status == "FLOOR_CLEARED":
		footer = "FLOOR CLEARED. Press Enter/A for next floor, or R/Start to return to level select."
	hud_label.text = "SHOOTY  |  %s\nScore: %d  Enemies: %d  Pickups: %d\n%s" % [
		_get_status_label(),
		_score,
		enemy_manager.get_enemy_count(),
		item_manager.get_pickup_count(),
		footer
	]
	if _is_dungeon_run and _status == "DUNGEON":
		hud_label.text += _get_dungeon_hud_suffix()
	_update_minimap()
	_update_combat_panel(upgrade_text)
	_update_game_over_panel()


func _update_combat_panel(upgrade_text: String) -> void:
	var max_health: int = max(_last_max_health, 1)
	var health_ratio: float = clamp(float(_last_health) / float(max_health), 0.0, 1.0)
	if health_fill != null:
		health_fill.size.x = 306.0 * health_ratio
	if health_label != null:
		health_label.text = "PC HEALTH  %d / %d" % [_last_health, max_health]
	if invulnerability_fill != null:
		var invulnerability_ratio: float = 0.0
		if _last_invulnerability_duration > 0.0:
			invulnerability_ratio = clamp(_last_invulnerability_remaining / _last_invulnerability_duration, 0.0, 1.0)
		invulnerability_fill.size.x = 306.0 * invulnerability_ratio
	if stats_label != null:
		stats_label.text = "Bullet Upgrade Ammo\n%s\nShot x%d  Pierce %d  Chain %d  AoE %d  Size %d%%" % [
			upgrade_text,
			int(_latest_modifiers.get("projectile_count", 1)),
			int(_latest_modifiers.get("pierce_count", 0)),
			int(_latest_modifiers.get("chain_count", 0)),
			roundi(float(_latest_modifiers.get("explosion_radius", 0.0))),
			roundi(float(_latest_modifiers.get("projectile_size_multiplier", 1.0)) * 100.0)
		]
	if attribute_label != null:
		attribute_label.text = _get_attribute_text()


func _update_game_over_panel() -> void:
	if game_over_panel == null:
		return
	game_over_panel.visible = _status == "DOWN"
	if game_over_score_label != null:
		game_over_score_label.text = "Score: %d" % _score
	if win_panel != null:
		win_panel.visible = _status == "WON" or _status == "FLOOR_CLEARED"
	if win_title_label != null:
		win_title_label.text = "FLOOR CLEARED" if _status == "FLOOR_CLEARED" else "LEVEL CLEARED"
	if win_score_label != null:
		win_score_label.text = "Score: %d" % _score
	if win_prompt_label != null:
		win_prompt_label.text = "Press Enter/A for next floor" if _status == "FLOOR_CLEARED" else "Press R or Start to return to level select"
	if game_over_title_label != null:
		game_over_title_label.text = "RUN ENDED" if _is_main_loop_run and _status == "DOWN" else "GAME OVER"
	if game_over_tally_label != null:
		game_over_tally_label.text = _get_tally_text()
	if game_over_prompt_label != null:
		game_over_prompt_label.text = "Press R or Start/A to restart"


func _get_upgrade_lines(active_effects: Array) -> Array[String]:
	var lines: Array[String] = []
	for state in active_effects:
		var effect = state["effect"]
		var remaining := float(state["remaining"])
		var max_ammo := int(state.get("max_ammo", 0))
		var ammo := int(state.get("ammo", max_ammo))
		if max_ammo > 0:
			lines.append("%s  %d/%d" % [effect.display_name, ammo, max_ammo])
		else:
			lines.append("%s  %.1fs" % [effect.display_name, remaining])
	return lines


func _get_attribute_text() -> String:
	if _permanent_stats.is_empty():
		return "Attributes\nFire Rate +0%  Move +0%  Damage +0%  Size +0%"
	var fire_bonus := float(_attribute_modifiers.get("fire_rate_bonus", 0.0))
	var move_bonus := float(_attribute_modifiers.get("move_speed_bonus", 0.0))
	var damage_bonus := float(_attribute_modifiers.get("damage_bonus", 0.0))
	var size_bonus := float(_attribute_modifiers.get("projectile_size_bonus", 0.0))
	var stack_lines: Array[String] = []
	for stat in _permanent_stats:
		stack_lines.append("%s x%d" % [stat["display_name"], int(stat["stacks"])])
	return "Attributes\nFire Rate +%d%%  Move +%d%%  Damage +%d%%  Size +%d%%\n%s" % [
		roundi(fire_bonus * 100.0),
		roundi(move_bonus * 100.0),
		roundi(damage_bonus * 100.0),
		roundi(size_bonus * 100.0),
		", ".join(stack_lines)
	]


func _check_level_clear() -> void:
	if _is_loading_room:
		return
	if not _is_gameplay_running():
		return
	if spawner_manager.get_spawner_count() > 0 or enemy_manager.get_enemy_count() > 0:
		return
	if _is_dungeon_run:
		dungeon_manager.mark_current_room_cleared()
		room_manager.set_doors_unlocked(true)
		if dungeon_manager.is_current_boss_room() and not _is_main_loop_run:
			_status = "WON"
			_set_all_enabled(false)
			if win_panel != null:
				win_panel.visible = true
		_update_hud()
		return
	_status = "WON"
	_set_all_enabled(false)
	if win_panel != null:
		win_panel.visible = true
	_update_hud()


func _on_menu_up_requested() -> void:
	if _status != "LEVEL_SELECT":
		return
	_selected_level_index = wrapi(_selected_level_index - 1, 0, _get_select_option_count())
	_update_level_select_ui()


func _on_menu_down_requested() -> void:
	if _status != "LEVEL_SELECT":
		return
	_selected_level_index = wrapi(_selected_level_index + 1, 0, _get_select_option_count())
	_update_level_select_ui()


func _on_menu_confirm_requested() -> void:
	if _status == "LEVEL_SELECT":
		_start_selected_level()
	elif _status == "FLOOR_CLEARED":
		_advance_main_loop_floor()
	elif _status == "WON":
		_enter_level_select()


func _on_menu_back_requested() -> void:
	if _status == "WON" or _status == "FLOOR_CLEARED":
		_enter_level_select()


func _update_level_select_ui() -> void:
	if level_list_label == null:
		return
	var lines: Array[String] = []
	for index in range(LEVELS.size()):
		var level = LEVELS[index]
		var marker := ">" if index == _selected_level_index else " "
		lines.append("%s %d. %s  [%s]" % [marker, index + 1, level.display_name, level.get_summary()])
	var dungeon_marker := ">" if _selected_level_index == LEVELS.size() else " "
	lines.append("%s %d. Dungeon Prototype  [room pieces + first boss]" % [dungeon_marker, LEVELS.size() + 1])
	var main_loop_marker := ">" if _selected_level_index == LEVELS.size() + 1 else " "
	lines.append("%s %d. Main Game Loop Test  [floor loop + tally]" % [main_loop_marker, LEVELS.size() + 2])
	level_list_label.text = "\n".join(lines)


func _load_dungeon_current_room(entry_direction: String, reset_player: bool) -> void:
	var level_definition = dungeon_manager.get_current_level_definition()
	if level_definition == null:
		return
	_current_level = level_definition
	_is_loading_room = true
	_set_all_enabled(false)
	if arena_view != null:
		arena_view.configure(level_definition)
	player_manager.set_arena_definition(level_definition)
	projectile_manager.set_arena_definition(level_definition)
	enemy_manager.set_arena_definition(level_definition)
	spawner_manager.set_arena_definition(level_definition)
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	spawner_manager.clear_spawners()
	item_manager.clear_pickups()
	effects_manager.reset_run()
	room_manager.reset_run()
	if reset_player or _get_player_ref() == null:
		player_manager.reset_run()
	else:
		player_manager.set_player_position(_get_room_entry_position(level_definition, entry_direction))
	var room_is_cleared: bool = dungeon_manager.is_current_room_cleared()
	if not room_is_cleared:
		spawner_manager.reset_run(level_definition)
	room_manager.load_room(level_definition, dungeon_manager.get_current_door_infos(), room_is_cleared)
	_set_all_enabled(true)
	if not room_is_cleared and level_definition.boss_profile != null:
		enemy_manager.spawn_enemy(level_definition.boss_profile, level_definition.boss_spawn_position)
	room_manager.set_doors_unlocked(room_is_cleared)
	_is_loading_room = false
	_update_camera()
	_update_minimap()
	_check_level_clear()
	_update_hud()


func _get_room_entry_position(level_definition, entry_direction: String) -> Vector2:
	var bounds: Rect2 = level_definition.arena_bounds
	var margin := 96.0
	var position := bounds.get_center()
	match entry_direction:
		"north":
			position = Vector2(bounds.get_center().x, bounds.position.y + bounds.size.y - margin)
		"south":
			position = Vector2(bounds.get_center().x, bounds.position.y + margin)
		"east":
			position = Vector2(bounds.position.x + margin, bounds.get_center().y)
		"west":
			position = Vector2(bounds.position.x + bounds.size.x - margin, bounds.get_center().y)
	return _find_safe_room_position(position, level_definition)


func _find_safe_room_position(preferred_position: Vector2, level_definition) -> Vector2:
	var offsets := [
		Vector2.ZERO,
		Vector2(0.0, -90.0),
		Vector2(0.0, 90.0),
		Vector2(-120.0, 0.0),
		Vector2(120.0, 0.0),
		Vector2(-120.0, -90.0),
		Vector2(120.0, 90.0),
		Vector2.ZERO
	]
	for offset in offsets:
		var candidate := ArenaGeometry.constrain_point(preferred_position + offset, level_definition.arena_bounds, int(level_definition.arena_shape))
		if _position_is_clear_of_room_walls(candidate, level_definition):
			return candidate
	return ArenaGeometry.constrain_point(preferred_position, level_definition.arena_bounds, int(level_definition.arena_shape))


func _position_is_clear_of_room_walls(position: Vector2, level_definition) -> bool:
	for wall_rect in level_definition.wall_rects:
		if wall_rect.grow(34.0).has_point(position):
			return false
	return true


func _is_gameplay_running() -> bool:
	return _status == "RUNNING" or _status == "DUNGEON"


func _get_status_label() -> String:
	if _is_main_loop_run and _status == "DUNGEON":
		return "FLOOR %d" % _main_loop_floor
	if _is_main_loop_run and _status == "FLOOR_CLEARED":
		return "FLOOR %d CLEARED" % _main_loop_floor
	if _is_dungeon_run and _status == "DUNGEON":
		return "DUNGEON"
	return _status


func _get_dungeon_hud_suffix() -> String:
	var state: Dictionary = dungeon_manager.get_current_room_state()
	if state.is_empty():
		return ""
	var piece = state["piece"]
	var door_text := "doors open" if dungeon_manager.is_current_room_cleared() else "clear room to open doors"
	var floor_text := "  |  Floor %d" % _main_loop_floor if _is_main_loop_run else ""
	var seed_text := "  |  Seed %d" % _run_seed if _run_seed > 0 else ""
	return "\nRoom: %s%s%s  |  %s" % [piece.display_name, floor_text, seed_text, door_text]


func _get_select_option_count() -> int:
	return LEVELS.size() + DUNGEON_OPTION_COUNT


func _update_minimap() -> void:
	if dungeon_minimap == null:
		return
	if _is_dungeon_run and (_status == "DUNGEON" or _status == "DOWN" or _status == "WON" or _status == "FLOOR_CLEARED"):
		if dungeon_minimap.has_method("set_map"):
			dungeon_minimap.call("set_map", dungeon_manager.get_minimap_rooms(), dungeon_manager.current_room_id)
	else:
		_clear_minimap()


func _clear_minimap() -> void:
	if dungeon_minimap != null and dungeon_minimap.has_method("clear_map"):
		dungeon_minimap.call("clear_map")


func _update_camera() -> void:
	if gameplay_camera == null or _current_level == null:
		return
	var bounds: Rect2 = _current_level.arena_bounds
	var desired: Vector2 = player_manager.get_player_position()
	var viewport_size := Vector2(1280.0, 720.0)
	if is_inside_tree():
		viewport_size = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1280.0, 720.0)
	var half_view := viewport_size * 0.5
	if bounds.size.x <= viewport_size.x:
		desired.x = bounds.get_center().x
	else:
		desired.x = clamp(desired.x, bounds.position.x + half_view.x, bounds.position.x + bounds.size.x - half_view.x)
	if bounds.size.y <= viewport_size.y:
		desired.y = bounds.get_center().y
	else:
		desired.y = clamp(desired.y, bounds.position.y + half_view.y, bounds.position.y + bounds.size.y - half_view.y)
	gameplay_camera.global_position = desired


func _complete_main_loop_floor() -> void:
	if _status == "FLOOR_CLEARED":
		return
	_run_floors_cleared = max(_run_floors_cleared, _main_loop_floor)
	_status = "FLOOR_CLEARED"
	_set_all_enabled(false)
	if win_panel != null:
		win_panel.visible = true
	_update_minimap()
	_update_game_over_panel()


func _get_boss_floor_bonus() -> int:
	return 1000 + (_main_loop_floor - 1) * 250


func _generate_run_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(100000, 999999999)


func _reset_run_tally() -> void:
	_run_enemy_kills = 0
	_run_spawner_kills = 0
	_run_boss_kills = 0
	_run_pickups_collected = 0
	_run_ammo_upgrades = 0
	_run_permanent_upgrades = 0
	_run_heals = 0
	_run_floors_cleared = 0


func _get_tally_text() -> String:
	if not _is_main_loop_run:
		var seed_line := "Seed: %d\n" % _run_seed if _is_dungeon_run and _run_seed > 0 else ""
		return "%sEnemies: %d\nSpawners: %d\nPickups: %d" % [
			seed_line,
			_run_enemy_kills,
			_run_spawner_kills,
			_run_pickups_collected
		]
	return "Seed: %d\nFloors cleared: %d\nEnemies: %d  Bosses: %d\nSpawners: %d\nPickups: %d  Ammo: %d  Permanent: %d  Heals: %d" % [
		_run_seed,
		_run_floors_cleared,
		_run_enemy_kills,
		_run_boss_kills,
		_run_spawner_kills,
		_run_pickups_collected,
		_run_ammo_upgrades,
		_run_permanent_upgrades,
		_run_heals
	]
