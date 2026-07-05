extends Node2D
class_name GameOrchestrator

const LEVELS := [
	preload("res://resources/levels/level_01_square.tres"),
	preload("res://resources/levels/level_02_diamond.tres"),
	preload("res://resources/levels/level_03_hexagon.tres"),
	preload("res://resources/levels/level_04_cross.tres"),
	preload("res://resources/levels/level_05_circle.tres"),
	preload("res://resources/levels/level_06_maze.tres"),
	preload("res://resources/levels/boss_test_chamber.tres")
]
const FLOOR_EXIT_PORTAL_SCENE := preload("res://scenes/entities/floor_exit_portal_entity.tscn")

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
@onready var destructible_manager = $Managers/DestructibleManager
@onready var audio_manager = $Managers/AudioManager
@onready var arena_view = $World/Arena
@onready var gameplay_camera: Camera2D = $Camera2D
@onready var hud_background: ColorRect = $UI/HUDBackground
@onready var hud_label: Label = $UI/HUDLabel
@onready var score_panel: Control = $UI/ScorePanel
@onready var score_label: Label = $UI/ScorePanel/ScoreLabel
@onready var dungeon_minimap: Control = $UI/DungeonMinimap
@onready var combat_panel: Control = $UI/CombatPanel
@onready var character_ui: CanvasItem = $UI/CharacterUi
@onready var health_bar_back: ColorRect = $UI/CombatPanel/HealthBarBack
@onready var health_fill: ColorRect = $UI/CombatPanel/HealthBarBack/HealthBarFill
@onready var health_tick_layer: Control = $UI/CombatPanel/HealthBarBack/HealthTickLayer
@onready var health_label: Label = $UI/CombatPanel/HealthLabel
@onready var invulnerability_bar_back: ColorRect = $UI/CombatPanel/InvulnerabilityBarBack
@onready var invulnerability_fill: ColorRect = $UI/CombatPanel/InvulnerabilityBarBack/InvulnerabilityBarFill
@onready var overdrive_label: Label = $UI/CombatPanel/OverdriveLabel
@onready var overdrive_bar_back: ColorRect = $UI/CombatPanel/OverdriveBarBack
@onready var overdrive_fill: ColorRect = $UI/CombatPanel/OverdriveBarBack/OverdriveBarFill
@onready var overdrive_tick_layer: Control = $UI/CombatPanel/OverdriveBarBack/OverdriveTickLayer
@onready var super_label: Label = $UI/CombatPanel/SuperLabel
@onready var super_bar_back: ColorRect = $UI/CombatPanel/SuperBarBack
@onready var super_fill: ColorRect = $UI/CombatPanel/SuperBarBack/SuperBarFill
@onready var attribute_label: Label = $UI/CombatPanel/AttributeLabel
@onready var stats_label: Label = $UI/CombatPanel/StatsLabel
@onready var ammo_counter_panel: Control = $UI/AmmoCounterPanel
@onready var pause_panel: Control = $UI/PausePanel
@onready var pause_stats_label: Label = $UI/PausePanel/PauseStatsLabel
@onready var pause_prompt_label: Label = $UI/PausePanel/PausePromptLabel
@onready var pause_confirm_panel: Control = $UI/PausePanel/PauseConfirmPanel
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
var _last_parry_cooldown_remaining: float = 0.0
var _last_parry_cooldown_duration: float = 0.0
var _last_super_meter: float = 0.0
var _last_super_meter_max: float = 100.0
var _last_super_is_charging: bool = false
var _last_super_charge_ratio: float = 0.0
var _last_overdrive_ammo: int = 40
var _last_overdrive_max_ammo: int = 40
var _last_overdrive_is_held: bool = false
var _last_overdrive_is_active: bool = false
var _last_overdrive_has_effects: bool = false
var _last_overdrive_effects: Array = []
var _status: String = "RUNNING"
var _latest_modifiers: Dictionary = {}
var _attribute_modifiers: Dictionary = {}
var _permanent_stats: Array = []
var _selected_level_index: int = 0
var _current_level = null
var _is_dungeon_run: bool = false
var _is_main_loop_run: bool = false
var _is_loading_room: bool = false
var _paused_previous_status: String = ""
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
var _tree_pause_requested: bool = false
var _boss_clear_delay_remaining: float = 0.0
var _boss_clear_pending_status: String = ""
var _floor_exit_portal = null
var _rewarded_room_ids: Dictionary = {}
var _reward_prompt_text: String = ""
var _ammo_refill_flash_remaining: float = 0.0
var _ammo_refill_flash_duration: float = 0.48
var _ammo_refill_perfect_flash_remaining: float = 0.0
var _ammo_refill_perfect_flash_duration: float = 0.58
var _super_meter_flash_remaining: float = 0.0
var _super_meter_flash_duration: float = 0.42
var _super_meter_ready_flash_remaining: float = 0.0
var _super_meter_ready_flash_duration: float = 0.62
var _super_ready_pulse_time: float = 0.0
var _super_crackle_remaining: float = 0.0
var _super_crackle_interval_remaining: float = 0.0
var _super_crackle_rng := RandomNumberGenerator.new()
var _character_hud_damage_flash_remaining: float = 0.0
var _character_hud_shake_remaining: float = 0.0
var _character_hud_base_captured: bool = false
var _combat_panel_base_position := Vector2.ZERO
var _character_ui_base_position := Vector2.ZERO
var _combat_panel_base_modulate := Color.WHITE
var _character_ui_base_modulate := Color.WHITE
var _meter_full_rects: Dictionary = {}
var _meter_authoring_state_captured: bool = false
var _meter_active_segment_counts: Dictionary = {}
var _perfect_parry_slowmo_until_msec: int = 0
var _perfect_parry_slowmo_restore_scale: float = 1.0

const DUNGEON_OPTION_COUNT := 2
const BOSS_CLEAR_DELAY_SECONDS := 0.85
const PERFECT_PARRY_TIME_SCALE := 0.24
const PERFECT_PARRY_SLOWMO_SECONDS := 0.16
const OVERDRIVE_BAR_BACK_COLOR := Color(0.004, 0.005, 0.008, 1.0)
const CHARACTER_HUD_DAMAGE_FLASH_SECONDS := 0.34
const CHARACTER_HUD_DAMAGE_SHAKE_SECONDS := 0.28
const CHARACTER_HUD_DAMAGE_SHAKE_PIXELS := 5.0
const SUPER_CRACKLE_SECONDS := 0.16
const SUPER_CRACKLE_MIN_INTERVAL := 0.52
const SUPER_CRACKLE_MAX_INTERVAL := 0.9
const METER_SEGMENT_GAP_PIXELS := .1
const METER_SEGMENT_MIN_WIDTH := 0.45
const METER_SEGMENT_SKEW_DEGREES := 10.0
const METER_SEGMENT_EJECT_SECONDS := 0.28
const METER_SEGMENT_EJECT_OFFSET := Vector2(12.0, -16.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_super_crackle_rng.randomize()
	_capture_hud_authoring_state()
	_configure_pause_process_modes()
	_set_tree_paused(false)
	_connect_manager_signals()
	_initialize_managers()
	_enter_level_select()


func _exit_tree() -> void:
	_stop_perfect_parry_slowmo()


func _process(delta: float) -> void:
	if _status == "BOSS_CLEARING":
		_update_boss_clear_transition(delta)
	_update_perfect_parry_slowmo()
	var hud_feedback_changed := false
	if _should_advance_gameplay_feedback():
		if _ammo_refill_flash_remaining > 0.0:
			_ammo_refill_flash_remaining = max(_ammo_refill_flash_remaining - delta, 0.0)
			hud_feedback_changed = true
		if _ammo_refill_perfect_flash_remaining > 0.0:
			_ammo_refill_perfect_flash_remaining = max(_ammo_refill_perfect_flash_remaining - delta, 0.0)
			hud_feedback_changed = true
		if _super_meter_flash_remaining > 0.0:
			_super_meter_flash_remaining = max(_super_meter_flash_remaining - delta, 0.0)
			hud_feedback_changed = true
		if _super_meter_ready_flash_remaining > 0.0:
			_super_meter_ready_flash_remaining = max(_super_meter_ready_flash_remaining - delta, 0.0)
			hud_feedback_changed = true
		if _update_super_ready_feedback(delta):
			hud_feedback_changed = true
	if _update_character_hud_damage_feedback(delta):
		hud_feedback_changed = true
	if hud_feedback_changed:
		_update_hud()
	if _is_gameplay_running():
		_update_camera()


func _connect_manager_signals() -> void:
	_connect_once(input_manager, &"move_changed", player_manager.set_move_vector)
	_connect_once(input_manager, &"aim_changed", player_manager.set_aim_direction)
	_connect_once(input_manager, &"aim_fire_requested", _on_aim_fire_requested)
	_connect_once(input_manager, &"restart_requested", _on_restart_requested)
	_connect_once(input_manager, &"menu_up_requested", _on_menu_up_requested)
	_connect_once(input_manager, &"menu_down_requested", _on_menu_down_requested)
	_connect_once(input_manager, &"menu_confirm_requested", _on_menu_confirm_requested)
	_connect_once(input_manager, &"menu_back_requested", _on_menu_back_requested)
	_connect_once(input_manager, &"parry_requested", _on_input_parry_requested)
	_connect_once(input_manager, &"pause_requested", _on_pause_requested)
	_connect_once(input_manager, &"super_charge_pressed", _on_input_super_charge_pressed)
	_connect_once(input_manager, &"super_charge_released", _on_input_super_charge_released)
	_connect_once(input_manager, &"overdrive_changed", _on_input_overdrive_changed)

	_connect_once(player_manager, &"player_health_changed", _on_player_health_changed)
	_connect_once(player_manager, &"player_invulnerability_changed", _on_player_invulnerability_changed)
	_connect_once(player_manager, &"parry_cooldown_changed", _on_player_parry_cooldown_changed)
	_connect_once(player_manager, &"player_defeated", _on_player_defeated)
	_connect_once(player_manager, &"shoot_requested", _on_player_shoot_requested)
	_connect_once(player_manager, &"parry_requested", _on_player_parry_requested)
	_connect_once(player_manager, &"super_meter_changed", _on_player_super_meter_changed)
	_connect_once(player_manager, &"super_shot_requested", _on_player_super_shot_requested)

	_connect_once(projectile_manager, &"projectile_hit", _on_projectile_hit)
	_connect_once(projectile_manager, &"projectile_expired", _on_projectile_expired)
	_connect_once(combat_manager, &"damage_resolved", _on_damage_resolved)
	_connect_once(combat_manager, &"player_damage_resolved", _on_player_damage_resolved)
	_connect_once(combat_manager, &"chain_requested", _on_chain_requested)
	_connect_once(combat_manager, &"explosion_requested", _on_explosion_requested)

	_connect_once(enemy_manager, &"enemy_defeated", _on_enemy_defeated)
	_connect_once(enemy_manager, &"enemy_count_changed", spawner_manager.set_enemy_count)
	_connect_once(enemy_manager, &"enemy_count_changed", _on_enemy_count_changed)
	_connect_once(enemy_manager, &"player_contact_requested", _on_player_contact_requested)
	_connect_once(enemy_manager, &"hostile_shot_requested", _on_hostile_shot_requested)

	_connect_once(spawner_manager, &"spawn_requested", _on_spawn_requested)
	_connect_once(spawner_manager, &"spawner_destroyed", _on_spawner_destroyed)
	_connect_once(spawner_manager, &"spawner_count_changed", _on_spawner_count_changed)
	_connect_once(spawner_manager, &"hostile_shot_requested", _on_hostile_shot_requested)
	_connect_once(destructible_manager, &"prop_destroyed", _on_destructible_prop_destroyed)
	_connect_once(item_manager, &"pickup_collected", _on_pickup_collected)
	_connect_once(item_manager, &"pickup_count_changed", _on_pickup_count_changed)
	_connect_once(item_manager, &"reward_focus_changed", _on_reward_focus_changed)
	_connect_once(upgrade_manager, &"upgrade_changed", _on_upgrade_changed)
	_connect_once(upgrade_manager, &"permanent_upgrades_changed", _on_permanent_upgrades_changed)
	_connect_once(upgrade_manager, &"overdrive_changed", _on_overdrive_changed)
	_connect_once(room_manager, &"door_entered", _on_room_door_entered)


func _connect_once(source: Object, signal_name: StringName, target: Callable) -> void:
	if source != null and not source.is_connected(signal_name, target):
		source.connect(signal_name, target)


func _initialize_managers() -> void:
	_capture_hud_authoring_state()
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
	destructible_manager.initialize({
		"destructible_layer": $World/DestructibleLayer
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
	audio_manager.initialize({})


func _configure_pause_process_modes() -> void:
	$World.process_mode = Node.PROCESS_MODE_PAUSABLE
	$Managers.process_mode = Node.PROCESS_MODE_PAUSABLE
	$UI.process_mode = Node.PROCESS_MODE_ALWAYS
	input_manager.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _capture_hud_authoring_state() -> void:
	_capture_character_hud_base_state()
	if _meter_authoring_state_captured:
		return
	var captured_any := false
	if health_fill != null:
		_capture_meter_fill_rect(health_fill)
		captured_any = true
	if invulnerability_fill != null:
		_capture_meter_fill_rect(invulnerability_fill)
		captured_any = true
	if overdrive_fill != null:
		_capture_meter_fill_rect(overdrive_fill)
		captured_any = true
	if super_fill != null:
		_capture_meter_fill_rect(super_fill)
		captured_any = true
	if captured_any:
		_meter_authoring_state_captured = true


func _capture_character_hud_base_state() -> void:
	if _character_hud_base_captured:
		return
	if combat_panel != null:
		_combat_panel_base_position = combat_panel.position
		_combat_panel_base_modulate = combat_panel.modulate
	if character_ui != null:
		_character_ui_base_position = character_ui.position
		_character_ui_base_modulate = character_ui.modulate
	_character_hud_base_captured = true


func _get_meter_cache_key(fill: Control) -> int:
	return fill.get_instance_id()


func _capture_meter_fill_rect(fill: Control) -> void:
	if fill == null:
		return
	_meter_full_rects[_get_meter_cache_key(fill)] = Rect2(fill.position, fill.size)


func _set_character_hud_visible(value: bool) -> void:
	if combat_panel != null:
		combat_panel.visible = value
	if character_ui != null:
		character_ui.visible = value
	if not value:
		_clear_super_crackle()
		_reset_character_hud_feedback()


func _trigger_character_hud_damage_feedback() -> void:
	_capture_character_hud_base_state()
	_character_hud_damage_flash_remaining = CHARACTER_HUD_DAMAGE_FLASH_SECONDS
	_character_hud_shake_remaining = CHARACTER_HUD_DAMAGE_SHAKE_SECONDS
	_apply_character_hud_feedback()


func _update_character_hud_damage_feedback(delta: float) -> bool:
	if _character_hud_damage_flash_remaining <= 0.0 and _character_hud_shake_remaining <= 0.0:
		return false
	_character_hud_damage_flash_remaining = max(_character_hud_damage_flash_remaining - delta, 0.0)
	_character_hud_shake_remaining = max(_character_hud_shake_remaining - delta, 0.0)
	_apply_character_hud_feedback()
	return true


func _apply_character_hud_feedback() -> void:
	_capture_character_hud_base_state()
	var shake_offset := Vector2.ZERO
	if _character_hud_shake_remaining > 0.0 and CHARACTER_HUD_DAMAGE_SHAKE_SECONDS > 0.0:
		var shake_ratio: float = clamp(_character_hud_shake_remaining / CHARACTER_HUD_DAMAGE_SHAKE_SECONDS, 0.0, 1.0)
		var ticks: float = float(Time.get_ticks_msec())
		shake_offset = Vector2(sin(ticks * 0.095), cos(ticks * 0.123)) * CHARACTER_HUD_DAMAGE_SHAKE_PIXELS * shake_ratio
	var flash_ratio := 0.0
	if _character_hud_damage_flash_remaining > 0.0 and CHARACTER_HUD_DAMAGE_FLASH_SECONDS > 0.0:
		flash_ratio = clamp(_character_hud_damage_flash_remaining / CHARACTER_HUD_DAMAGE_FLASH_SECONDS, 0.0, 1.0)
	var flash_color := Color(1.0, 0.38, 0.34, 1.0).lerp(Color.WHITE, 1.0 - flash_ratio)
	if combat_panel != null:
		combat_panel.position = _combat_panel_base_position + shake_offset
		combat_panel.modulate = _combat_panel_base_modulate * flash_color
	if character_ui != null:
		character_ui.position = _character_ui_base_position + shake_offset
		character_ui.modulate = _character_ui_base_modulate * flash_color


func _reset_character_hud_feedback() -> void:
	_character_hud_damage_flash_remaining = 0.0
	_character_hud_shake_remaining = 0.0
	if combat_panel != null:
		combat_panel.position = _combat_panel_base_position
		combat_panel.modulate = _combat_panel_base_modulate
	if character_ui != null:
		character_ui.position = _character_ui_base_position
		character_ui.modulate = _character_ui_base_modulate


func _update_super_ready_feedback(delta: float) -> bool:
	var is_ready := _is_super_meter_ready_for_feedback()
	if not is_ready:
		if _super_ready_pulse_time > 0.0 or _super_crackle_remaining > 0.0:
			_super_ready_pulse_time = 0.0
			_super_crackle_remaining = 0.0
			_super_crackle_interval_remaining = 0.0
			_clear_super_crackle()
			return true
		return false
	_super_ready_pulse_time += delta
	_super_crackle_interval_remaining -= delta
	if _super_crackle_interval_remaining <= 0.0:
		_super_crackle_remaining = SUPER_CRACKLE_SECONDS
		_super_crackle_interval_remaining = _super_crackle_rng.randf_range(SUPER_CRACKLE_MIN_INTERVAL, SUPER_CRACKLE_MAX_INTERVAL)
	if _super_crackle_remaining > 0.0:
		_super_crackle_remaining = max(_super_crackle_remaining - delta, 0.0)
	return true


func _is_super_meter_ready_for_feedback() -> bool:
	return _status != "LEVEL_SELECT" and not _last_super_is_charging and _last_super_meter_max > 0.0 and _last_super_meter >= _last_super_meter_max


func _clear_super_crackle() -> void:
	if super_bar_back == null:
		return
	var crackle := super_bar_back.get_node_or_null("SuperCrackle")
	if crackle != null:
		crackle.queue_free()


func _start_selected_level() -> void:
	if _selected_level_index < LEVELS.size():
		_start_level(LEVELS[_selected_level_index])
	elif _selected_level_index == LEVELS.size():
		_start_dungeon_run()
	else:
		_start_main_loop_run()


func _start_level(level_definition) -> void:
	_set_tree_paused(false)
	_is_dungeon_run = false
	_is_main_loop_run = false
	_current_level = level_definition
	_score = 0
	_run_seed = 0
	_paused_previous_status = ""
	_reset_run_tally()
	_status = "STARTING"
	_last_health = 0
	_last_max_health = 0
	_last_invulnerability_remaining = 0.0
	_last_invulnerability_duration = 0.0
	_last_parry_cooldown_remaining = 0.0
	_last_parry_cooldown_duration = 0.0
	_last_super_meter = 0.0
	_last_super_meter_max = player_manager.get_super_meter_max()
	_last_super_is_charging = false
	_last_super_charge_ratio = 0.0
	_reset_overdrive_hud_state()
	_ammo_refill_flash_remaining = 0.0
	_ammo_refill_perfect_flash_remaining = 0.0
	_super_meter_flash_remaining = 0.0
	_super_meter_ready_flash_remaining = 0.0
	_stop_perfect_parry_slowmo()
	_clear_floor_exit_portal()
	_attribute_modifiers = {}
	_permanent_stats = []
	_rewarded_room_ids.clear()
	_reward_prompt_text = ""
	if level_select_panel != null:
		level_select_panel.visible = false
	if game_over_panel != null:
		game_over_panel.visible = false
	if win_panel != null:
		win_panel.visible = false
	_set_character_hud_visible(true)
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
	destructible_manager.reset_run(level_definition)
	item_manager.reset_run()
	upgrade_manager.reset_run()
	combat_manager.reset_run()
	effects_manager.reset_run()
	input_manager.reset_run()
	player_manager.reset_run()
	_set_all_enabled(true)
	if level_definition.boss_profile != null:
		enemy_manager.spawn_enemy(level_definition.boss_profile, level_definition.boss_spawn_position)
	audio_manager.play_floor_start()
	_status = "RUNNING"
	_on_upgrade_changed(upgrade_manager.get_modifiers(), upgrade_manager.get_active_effects())
	_update_hud()


func _start_dungeon_run() -> void:
	_set_tree_paused(false)
	_is_dungeon_run = true
	_is_main_loop_run = false
	_score = 0
	_main_loop_floor = 1
	_run_seed = _generate_run_seed()
	_paused_previous_status = ""
	_reset_run_tally()
	_status = "STARTING"
	_last_health = 0
	_last_max_health = 0
	_last_invulnerability_remaining = 0.0
	_last_invulnerability_duration = 0.0
	_last_parry_cooldown_remaining = 0.0
	_last_parry_cooldown_duration = 0.0
	_last_super_meter = 0.0
	_last_super_meter_max = player_manager.get_super_meter_max()
	_last_super_is_charging = false
	_last_super_charge_ratio = 0.0
	_reset_overdrive_hud_state()
	_ammo_refill_flash_remaining = 0.0
	_ammo_refill_perfect_flash_remaining = 0.0
	_super_meter_flash_remaining = 0.0
	_super_meter_ready_flash_remaining = 0.0
	_stop_perfect_parry_slowmo()
	_clear_floor_exit_portal()
	_attribute_modifiers = {}
	_permanent_stats = []
	_rewarded_room_ids.clear()
	_reward_prompt_text = ""
	if level_select_panel != null:
		level_select_panel.visible = false
	if game_over_panel != null:
		game_over_panel.visible = false
	if win_panel != null:
		win_panel.visible = false
	_set_character_hud_visible(true)
	dungeon_manager.reset_run(_main_loop_floor, _run_seed)
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	spawner_manager.clear_spawners()
	destructible_manager.clear_destructibles()
	item_manager.clear_pickups()
	upgrade_manager.reset_run()
	combat_manager.reset_run()
	effects_manager.reset_run()
	room_manager.reset_run()
	input_manager.reset_run()
	_status = "DUNGEON"
	_load_dungeon_current_room("", true)
	audio_manager.play_floor_start()
	_on_upgrade_changed(upgrade_manager.get_modifiers(), upgrade_manager.get_active_effects())
	_update_hud()


func _start_main_loop_run() -> void:
	_set_tree_paused(false)
	_is_dungeon_run = true
	_is_main_loop_run = true
	_score = 0
	_main_loop_floor = 1
	_run_seed = _generate_run_seed()
	_paused_previous_status = ""
	_reset_run_tally()
	_status = "STARTING"
	_last_health = 0
	_last_max_health = 0
	_last_invulnerability_remaining = 0.0
	_last_invulnerability_duration = 0.0
	_last_parry_cooldown_remaining = 0.0
	_last_parry_cooldown_duration = 0.0
	_last_super_meter = 0.0
	_last_super_meter_max = player_manager.get_super_meter_max()
	_last_super_is_charging = false
	_last_super_charge_ratio = 0.0
	_reset_overdrive_hud_state()
	_ammo_refill_flash_remaining = 0.0
	_ammo_refill_perfect_flash_remaining = 0.0
	_super_meter_flash_remaining = 0.0
	_super_meter_ready_flash_remaining = 0.0
	_stop_perfect_parry_slowmo()
	_clear_floor_exit_portal()
	_attribute_modifiers = {}
	_permanent_stats = []
	_rewarded_room_ids.clear()
	_reward_prompt_text = ""
	if level_select_panel != null:
		level_select_panel.visible = false
	if game_over_panel != null:
		game_over_panel.visible = false
	if win_panel != null:
		win_panel.visible = false
	_set_character_hud_visible(true)
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
	audio_manager.play_floor_start()
	_on_upgrade_changed(upgrade_manager.get_modifiers(), upgrade_manager.get_active_effects())
	_update_hud()


func _advance_main_loop_floor() -> void:
	if not _is_main_loop_run:
		return
	_set_tree_paused(false)
	_main_loop_floor += 1
	_status = "STARTING"
	_clear_floor_exit_portal()
	_rewarded_room_ids.clear()
	_reward_prompt_text = ""
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
	audio_manager.play_floor_start()
	_update_hud()


func _enter_level_select() -> void:
	_set_tree_paused(false)
	_status = "LEVEL_SELECT"
	_current_level = null
	_is_dungeon_run = false
	_is_main_loop_run = false
	_run_seed = 0
	_paused_previous_status = ""
	_ammo_refill_flash_remaining = 0.0
	_ammo_refill_perfect_flash_remaining = 0.0
	_super_meter_flash_remaining = 0.0
	_super_meter_ready_flash_remaining = 0.0
	_last_super_meter = 0.0
	_last_super_meter_max = player_manager.get_super_meter_max()
	_last_super_is_charging = false
	_last_super_charge_ratio = 0.0
	_reset_overdrive_hud_state()
	_stop_perfect_parry_slowmo()
	_clear_floor_exit_portal()
	_rewarded_room_ids.clear()
	_reward_prompt_text = ""
	_set_all_enabled(false)
	_clear_gameplay()
	_clear_minimap()
	if gameplay_camera != null:
		gameplay_camera.global_position = Vector2.ZERO
	_set_character_hud_visible(false)
	if game_over_panel != null:
		game_over_panel.visible = false
	if win_panel != null:
		win_panel.visible = false
	if level_select_panel != null:
		level_select_panel.visible = true
	_update_level_select_ui()
	_update_hud()


func _clear_gameplay() -> void:
	_clear_floor_exit_portal()
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
	destructible_manager.set_enabled(value)
	item_manager.set_enabled(value)
	upgrade_manager.set_enabled(value)
	combat_manager.set_enabled(value)
	effects_manager.set_enabled(value)
	dungeon_manager.set_enabled(value and _is_dungeon_run)
	room_manager.set_enabled(value and _is_dungeon_run)
	audio_manager.set_enabled(value)


func _set_tree_paused(value: bool) -> void:
	if value:
		_stop_perfect_parry_slowmo()
	_tree_pause_requested = value
	if is_inside_tree():
		get_tree().paused = value


func _reset_overdrive_hud_state() -> void:
	_last_overdrive_ammo = upgrade_manager.get_overdrive_ammo() if upgrade_manager != null else 40
	_last_overdrive_max_ammo = upgrade_manager.get_overdrive_max_ammo() if upgrade_manager != null else 40
	_last_overdrive_is_held = false
	_last_overdrive_is_active = false
	_last_overdrive_has_effects = false
	_last_overdrive_effects = []


func _should_advance_gameplay_feedback() -> bool:
	return not _tree_pause_requested and (_is_gameplay_running() or _status == "DOWN")


func _on_aim_fire_requested(direction: Vector2) -> void:
	player_manager.request_fire(direction)


func _on_input_super_charge_pressed() -> void:
	if not _is_gameplay_running():
		return
	player_manager.request_super_charge_start()


func _on_input_super_charge_released(direction: Vector2) -> void:
	if not _is_gameplay_running():
		return
	player_manager.request_super_charge_release(direction)


func _on_input_overdrive_changed(is_held: bool) -> void:
	upgrade_manager.set_overdrive_active(is_held and _is_gameplay_running())


func _on_player_shoot_requested(origin: Vector2, direction: Vector2) -> void:
	audio_manager.play_player_shot()
	var shot_modifiers: Dictionary = upgrade_manager.get_modifiers()
	projectile_manager.fire(origin, direction, shot_modifiers)
	upgrade_manager.consume_overdrive_shot()


func _on_player_super_shot_requested(origin: Vector2, direction: Vector2, charge_ratio: float) -> void:
	audio_manager.play_player_shot()
	projectile_manager.fire_super_shot(origin, direction, charge_ratio)


func _on_projectile_hit(projectile, target: Node, packet) -> void:
	var projectile_kind := String(packet.projectile_kind) if packet != null else "normal"
	if projectile_kind != "rocket":
		audio_manager.play_bullet_impact()
	var impact_position := Vector2.ZERO
	var impact_direction := Vector2.RIGHT
	var impact_radius := 7.0
	if projectile != null and is_instance_valid(projectile):
		impact_position = projectile.global_position
		impact_radius = float(projectile.body_radius)
		if projectile.direction.length_squared() > 0.001:
			impact_direction = projectile.direction
	elif target != null and is_instance_valid(target):
		impact_position = target.global_position
	if target != null and target.is_in_group("player"):
		effects_manager.play_projectile_impact(impact_position, impact_direction, impact_radius, false)
		_apply_player_projectile_hit_effects(packet, impact_position, impact_radius)
		combat_manager.resolve_projectile_hit(projectile, target, packet)
		return
	var damage_landed := _apply_damage_to_target(target, packet)
	var blocked := not damage_landed and _target_has_active_projectile_shield(target)
	effects_manager.play_projectile_impact(impact_position, impact_direction, impact_radius, blocked)
	if damage_landed:
		_request_projectile_damage_side_effects(target, packet)


func _on_projectile_expired(_projectile, expire_info: Dictionary) -> void:
	var reason := String(expire_info.get("reason", ""))
	if reason.is_empty() or reason == "hit" or reason == "absorbed":
		return
	var impact_position: Vector2 = expire_info.get("position", Vector2.ZERO)
	var impact_direction: Vector2 = expire_info.get("direction", Vector2.RIGHT)
	var impact_radius: float = float(expire_info.get("radius", 7.0))
	var projectile_kind := String(expire_info.get("kind", ""))
	if (reason == "wall" or reason == "bounds") and projectile_kind != "rocket":
		audio_manager.play_bullet_wall_hit()
	effects_manager.play_projectile_impact(impact_position, impact_direction, impact_radius, false)
	if projectile_kind == "rocket":
		_detonate_hostile_rocket(impact_position, impact_radius, expire_info.get("damage_packet", null), false)
	elif projectile_kind == "super":
		var packet = expire_info.get("damage_packet", null)
		if packet != null and packet.explosion_radius > 0.0 and packet.explosion_damage_multiplier > 0.0:
			_on_explosion_requested(impact_position, packet)


func _apply_player_projectile_hit_effects(packet, impact_position: Vector2, impact_radius: float = 7.0) -> void:
	if packet == null:
		return
	if String(packet.projectile_kind) == "rocket":
		_detonate_hostile_rocket(impact_position, impact_radius, packet, true)
		return
	if float(packet.knockback) > 0.0:
		player_manager.apply_pushback(packet.knockback_direction, float(packet.knockback))


func _detonate_hostile_rocket(origin: Vector2, projectile_radius: float, packet, skip_player_damage: bool) -> void:
	var explosion_radius: float = max(projectile_radius * 5.2, 58.0)
	if packet != null and float(packet.explosion_radius) > 0.0:
		explosion_radius = max(explosion_radius, float(packet.explosion_radius))
	audio_manager.play_rocket_explosion()
	effects_manager.play_explosion(origin, explosion_radius)
	if packet == null:
		return
	var player = _get_player_ref()
	if player != null and is_instance_valid(player):
		var player_radius: float = float(player.body_radius)
		var player_effect_radius := explosion_radius + player_radius
		if player.global_position.distance_squared_to(origin) <= player_effect_radius * player_effect_radius:
			var push_direction: Vector2 = player.global_position - origin
			if push_direction.length_squared() <= 0.001:
				push_direction = packet.knockback_direction
			if push_direction.length_squared() <= 0.001:
				push_direction = Vector2.RIGHT
			if float(packet.knockback) > 0.0:
				player_manager.apply_pushback(push_direction.normalized(), float(packet.knockback))
			if not skip_player_damage:
				player_manager.apply_damage(max(int(packet.damage), 1))
	var explosion_packet = packet.copy_with_damage_bonus(0)
	explosion_packet.projectile_kind = "hostile"
	explosion_packet.source_position = origin
	explosion_packet.knockback = max(float(packet.knockback) * 0.65, 120.0)
	var excluded: Array[Node] = []
	var candidates = enemy_manager.get_nearby_enemies(origin, explosion_radius, excluded)
	candidates.append_array(spawner_manager.get_nearby_spawners(origin, explosion_radius, excluded))
	candidates.append_array(destructible_manager.get_nearby_destructibles(origin, explosion_radius, excluded))
	for target in candidates:
		explosion_packet.knockback_direction = (target.global_position - origin).normalized()
		_on_damage_resolved(target, explosion_packet)


func _on_damage_resolved(target: Node, packet) -> bool:
	return _apply_damage_to_target(target, packet)


func _apply_damage_to_target(target: Node, packet) -> bool:
	if target == null or packet == null or not is_instance_valid(target):
		return false
	if target.is_in_group("enemies"):
		return bool(enemy_manager.apply_damage(target, packet))
	elif target.is_in_group("spawners"):
		return bool(spawner_manager.apply_damage(target, packet))
	elif target.is_in_group("destructible_props"):
		return bool(destructible_manager.apply_damage(target, packet))
	return false


func _request_projectile_damage_side_effects(target: Node, packet) -> void:
	if target == null or packet == null or not is_instance_valid(target):
		return
	if packet.explosion_radius > 0.0 and packet.explosion_damage_multiplier > 0.0:
		_on_explosion_requested(target.global_position, packet)
	if packet.chain_count > 0 and packet.chain_radius > 0.0:
		_on_chain_requested(target, packet)


func _target_has_active_projectile_shield(target: Node) -> bool:
	if target == null or not is_instance_valid(target) or not target.has_method("is_projectile_shield_active"):
		return false
	return bool(target.is_projectile_shield_active())


func _on_chain_requested(origin_target: Node, packet) -> void:
	if origin_target == null or packet == null or not is_instance_valid(origin_target):
		return
	var excluded: Array[Node] = [origin_target]
	excluded.append_array(packet.hit_targets)
	var candidates = enemy_manager.get_nearby_enemies(origin_target.global_position, packet.chain_radius, excluded)
	candidates.append_array(spawner_manager.get_nearby_spawners(origin_target.global_position, packet.chain_radius, excluded))
	if candidates.is_empty():
		var overload_packet = packet.copy_for_chain()
		overload_packet.chain_count = 0
		overload_packet.damage = max(roundi(float(packet.damage) * 0.65), 1)
		_on_damage_resolved(origin_target, overload_packet)
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
	if String(packet.projectile_kind) == "super":
		audio_manager.play_rocket_explosion()
	effects_manager.play_explosion(origin, packet.explosion_radius)
	var explosion_packet = packet.copy_for_explosion()
	explosion_packet.source_position = origin
	var excluded: Array[Node] = []
	var candidates = enemy_manager.get_nearby_enemies(origin, packet.explosion_radius, excluded)
	candidates.append_array(spawner_manager.get_nearby_spawners(origin, packet.explosion_radius, excluded))
	candidates.append_array(destructible_manager.get_nearby_destructibles(origin, packet.explosion_radius, excluded))
	for target in candidates:
		explosion_packet.knockback_direction = (target.global_position - origin).normalized()
		_on_damage_resolved(target, explosion_packet)


func _on_player_contact_requested(enemy, player, damage: int) -> void:
	combat_manager.resolve_contact_damage(enemy, player, damage)


func _on_player_damage_resolved(amount: int) -> void:
	player_manager.apply_damage(amount)


func _on_spawn_requested(spawn_position: Vector2, profile) -> void:
	enemy_manager.spawn_enemy(profile, spawn_position, {"birth": true})


func _on_hostile_shot_requested(origin: Vector2, direction: Vector2, shot_config: Dictionary) -> void:
	audio_manager.play_enemy_shot()
	projectile_manager.fire_hostile(origin, direction, shot_config)


func _on_enemy_defeated(_enemy, score_value: int) -> void:
	_score += score_value
	player_manager.add_super_meter(player_manager.super_meter_enemy_kill_gain)
	if _enemy != null and is_instance_valid(_enemy):
		if _enemy.behavior_kind == "boss":
			_run_boss_kills += 1
			if _is_main_loop_run:
				_score += _get_boss_floor_bonus()
				_spawn_floor_overdrive_reward_choices(_enemy.global_position)
				_activate_boss_exit_portal(_enemy.global_position, float(_enemy.body_radius))
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


func _on_destructible_prop_destroyed(prop, score_value: int, drop_kind: String) -> void:
	if prop != null and is_instance_valid(prop):
		_score += max(score_value, 0)
		item_manager.drop_destructible_reward(prop.global_position, drop_kind)
		effects_manager.play_projectile_impact(prop.global_position, Vector2.UP, 10.0, true)
	_update_hud()


func _on_player_health_changed(old_value: int, new_value: int) -> void:
	if new_value < old_value:
		_trigger_character_hud_damage_feedback()
	_last_health = new_value
	_last_max_health = player_manager.get_player_max_health()
	_update_hud()


func _on_player_invulnerability_changed(remaining: float, duration: float) -> void:
	_last_invulnerability_remaining = remaining
	_last_invulnerability_duration = duration
	_update_hud()


func _on_input_parry_requested() -> void:
	player_manager.request_parry()


func _on_player_parry_cooldown_changed(remaining: float, duration: float) -> void:
	var was_on_cooldown := _last_parry_cooldown_remaining > 0.0
	_last_parry_cooldown_remaining = remaining
	_last_parry_cooldown_duration = duration
	if was_on_cooldown and remaining <= 0.0:
		audio_manager.play_parry_ready()
	_update_hud()


func _on_player_super_meter_changed(current: float, maximum: float, is_charging: bool, charge_ratio: float) -> void:
	var previous_meter := _last_super_meter
	var previous_ready := _last_super_meter_max > 0.0 and _last_super_meter >= _last_super_meter_max
	_last_super_meter = clamp(current, 0.0, max(maximum, 1.0))
	_last_super_meter_max = max(maximum, 1.0)
	_last_super_is_charging = is_charging
	_last_super_charge_ratio = clamp(charge_ratio, 0.0, 1.0)
	if _last_super_meter > previous_meter:
		_super_meter_flash_remaining = _super_meter_flash_duration
	var is_ready := _last_super_meter >= _last_super_meter_max
	if is_ready and not previous_ready:
		_super_meter_ready_flash_remaining = _super_meter_ready_flash_duration
	_update_hud()


func _on_player_parry_requested(origin: Vector2, effect_radius: float, perfect_radius: float, enemy_knockback: float) -> void:
	if not _is_gameplay_running():
		return
	audio_manager.play_parry()
	var absorbed: Dictionary = projectile_manager.absorb_hostile_projectiles(origin, effect_radius, perfect_radius)
	var absorbed_projectiles: Array = absorbed.get("absorbed_projectiles", [])
	var ammo_awarded := int(absorbed.get("ammo_awarded", 0))
	var absorbed_count := int(absorbed.get("absorbed_count", 0))
	var perfect_count := int(absorbed.get("perfect_count", 0))
	var was_perfect := perfect_count > 0
	var ammo_added := 0
	if absorbed_count > 0:
		var regular_count: int = max(absorbed_count - perfect_count, 0)
		var meter_gain: float = float(regular_count) * player_manager.super_meter_parried_bullet_gain + float(perfect_count) * player_manager.super_meter_perfect_bullet_gain
		player_manager.add_super_meter(meter_gain)
	if ammo_awarded > 0:
		ammo_added = upgrade_manager.add_overdrive_ammo(ammo_awarded)
	if ammo_added > 0:
		_ammo_refill_flash_remaining = _ammo_refill_flash_duration
		if was_perfect:
			_ammo_refill_perfect_flash_remaining = _ammo_refill_perfect_flash_duration
		_update_hud()
	if was_perfect:
		audio_manager.play_perfect_parry()
		player_manager.play_perfect_parry_response(effect_radius, perfect_radius)
		_start_perfect_parry_slowmo()
	if not absorbed_projectiles.is_empty():
		_target_parry_absorbs_at_ammo_counters(absorbed_projectiles)
		effects_manager.play_parry_absorbs(absorbed_projectiles, origin)
	enemy_manager.apply_parry_pushback(origin, effect_radius, enemy_knockback)
	_update_hud()


func _target_parry_absorbs_at_ammo_counters(absorbed_projectiles: Array) -> void:
	var targets := _get_ammo_counter_world_targets()
	if targets.is_empty():
		return
	var seed_base: float = float(Time.get_ticks_msec() % 10000)
	for index in range(absorbed_projectiles.size()):
		var info = absorbed_projectiles[index]
		if not (info is Dictionary):
			continue
		var target_position: Vector2 = targets[index % targets.size()]
		var perfect := bool(info.get("perfect", false))
		var jitter_angle: float = float(index) * 2.399963 + seed_base * 0.017
		var jitter_distance: float = 4.0 + fposmod(seed_base + float(index) * 11.0, 10.0)
		if perfect:
			jitter_distance *= 0.55
		info["target_position"] = target_position + Vector2.RIGHT.rotated(jitter_angle) * jitter_distance
		info["arc_seed"] = seed_base + float(index) * 23.0
		absorbed_projectiles[index] = info


func _get_ammo_counter_world_targets() -> Array[Vector2]:
	var targets: Array[Vector2] = []
	if overdrive_fill != null:
		targets.append(_screen_to_world_position(overdrive_fill.get_global_rect().get_center()))
		return targets
	var viewport_size := Vector2(1280.0, 720.0)
	if is_inside_tree():
		viewport_size = get_viewport_rect().size
		if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
			viewport_size = Vector2(1280.0, 720.0)
	targets.append(_screen_to_world_position(Vector2(viewport_size.x - 178.0, 64.0)))
	return targets


func _screen_to_world_position(screen_position: Vector2) -> Vector2:
	if not is_inside_tree():
		return screen_position
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


func _start_perfect_parry_slowmo() -> void:
	if _perfect_parry_slowmo_until_msec <= 0:
		_perfect_parry_slowmo_restore_scale = Engine.time_scale
	Engine.time_scale = min(max(_perfect_parry_slowmo_restore_scale, 0.01), PERFECT_PARRY_TIME_SCALE)
	_perfect_parry_slowmo_until_msec = Time.get_ticks_msec() + roundi(PERFECT_PARRY_SLOWMO_SECONDS * 1000.0)


func _update_perfect_parry_slowmo() -> void:
	if _perfect_parry_slowmo_until_msec > 0 and Time.get_ticks_msec() >= _perfect_parry_slowmo_until_msec:
		_stop_perfect_parry_slowmo()


func _stop_perfect_parry_slowmo() -> void:
	if _perfect_parry_slowmo_until_msec <= 0:
		return
	_perfect_parry_slowmo_until_msec = 0
	Engine.time_scale = max(_perfect_parry_slowmo_restore_scale, 0.01)
	_perfect_parry_slowmo_restore_scale = 1.0


func _on_player_defeated(_player) -> void:
	_stop_perfect_parry_slowmo()
	_status = "DOWN"
	_set_all_enabled(false)
	audio_manager.play_game_over()
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


func _on_overdrive_changed(state: Dictionary) -> void:
	var previous_ammo := _last_overdrive_ammo
	_last_overdrive_ammo = int(state.get("ammo", 0))
	_last_overdrive_max_ammo = max(int(state.get("max_ammo", 1)), 1)
	_last_overdrive_is_held = bool(state.get("is_held", false))
	_last_overdrive_is_active = bool(state.get("is_active", false))
	_last_overdrive_has_effects = bool(state.get("has_effects", false))
	_last_overdrive_effects = state.get("effects", [])
	if _last_overdrive_ammo > previous_ammo:
		_ammo_refill_flash_remaining = _ammo_refill_flash_duration
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
	audio_manager.play_pickup()
	_run_pickups_collected += 1
	var pickup_kind := String(pickup_resource.get_pickup_kind()) if pickup_resource.has_method("get_pickup_kind") else "overdrive_effect"
	match pickup_kind:
		"heal":
			_run_heals += 1
			player_manager.apply_healing(int(pickup_resource.heal_amount))
		"overdrive_ammo":
			_run_ammo_upgrades += 1
			var added: int = upgrade_manager.add_overdrive_ammo(int(pickup_resource.amount))
			if added > 0:
				_ammo_refill_flash_remaining = _ammo_refill_flash_duration
		"permanent":
			_run_permanent_upgrades += 1
			upgrade_manager.activate_pickup(pickup_resource)
		_:
			_run_ammo_upgrades += 1
			upgrade_manager.activate_pickup(pickup_resource)
	_update_hud()


func _on_reward_focus_changed(_effect, description: String) -> void:
	_reward_prompt_text = description
	_update_hud()


func _get_player_ref():
	return player_manager.player


func _on_room_door_entered(direction: String) -> void:
	if not _is_dungeon_run or _status != "DUNGEON":
		return
	if dungeon_manager.enter_direction(direction):
		_load_dungeon_current_room(direction, false)
		audio_manager.play_room_entry()


func _on_pause_requested() -> void:
	if _is_gameplay_running():
		_stop_perfect_parry_slowmo()
		_paused_previous_status = _status
		_status = "PAUSED"
		_set_all_enabled(false)
		_set_tree_paused(true)
		_update_hud()
	elif _status == "DOWN":
		_on_restart_requested()
	elif _status == "PAUSED":
		_resume_from_pause()
	elif _status == "PAUSE_EXIT_CONFIRM":
		_status = "PAUSED"
		_set_tree_paused(true)
		_update_hud()
	elif _status == "WON" or _status == "FLOOR_CLEARED":
		_enter_level_select()


func _resume_from_pause() -> void:
	if _status != "PAUSED":
		return
	_set_tree_paused(false)
	_status = _paused_previous_status if not _paused_previous_status.is_empty() else "RUNNING"
	_paused_previous_status = ""
	_set_all_enabled(true)
	_update_hud()


func _update_hud() -> void:
	if hud_label == null:
		return
	_update_score_panel()
	if _status == "LEVEL_SELECT":
		hud_label.text = "SHOOTY  |  LEVEL SELECT"
		_update_minimap()
		_update_combat_panel([])
		_update_game_over_panel()
		_update_pause_panel()
		return
	var active_effects: Array = upgrade_manager.get_active_effects()
	var footer: String = "Aim-change fire  |  Shift/L-Trigger overdrive  |  Q/R-Shoulder parry  |  Hold E/R-Trigger super"
	if _status == "DOWN":
		footer = "DOWN. Press R or Start/A on controller to restart."
	elif _status == "BOSS_CLEARING":
		footer = "BOSS DEFEATED. Hold steady..."
	elif _status == "FLOOR_CLEARED":
		footer = "FLOOR CLEARED. Press Enter/A for next floor, or R/Start to return to level select."
	elif _is_main_loop_run and _floor_exit_portal_active():
		footer = "BOSS DEFEATED. Enter the portal to finish the mission."
	elif _status == "PAUSED":
		footer = "PAUSED. Esc/Start resumes. Enter/A opens exit prompt."
	elif _status == "PAUSE_EXIT_CONFIRM":
		footer = "EXIT TO MAIN MENU? Enter/A confirms. R/Esc cancels."
	if not _reward_prompt_text.is_empty() and _is_gameplay_running():
		footer = "%s  |  %s  Press Enter/A to take." % [footer, _reward_prompt_text]
	hud_label.text = "%s\nEnemies: %d  Pickups: %d\n%s" % [
		_get_status_label(),
		enemy_manager.get_enemy_count(),
		item_manager.get_pickup_count(),
		footer
	]
	if _is_dungeon_run and _status == "DUNGEON":
		hud_label.text += _get_dungeon_hud_suffix()
	_update_minimap()
	_update_combat_panel(active_effects)
	_update_game_over_panel()
	_update_pause_panel()


func _update_score_panel() -> void:
	if score_panel != null:
		score_panel.visible = _status != "LEVEL_SELECT"
	if score_label != null:
		score_label.text = "SCORE %06d" % _score


func _update_combat_panel(active_effects: Array) -> void:
	var max_health: int = max(_last_max_health, 1)
	var health_ratio: float = clamp(float(_last_health) / float(max_health), 0.0, 1.0)
	var health_fill_rect := _get_meter_full_rect(health_fill, health_bar_back, 342.0)
	if health_fill != null:
		_set_meter_fill_width(health_fill, health_fill_rect.size.x * health_ratio)
		health_fill.visible = false
	if health_label != null:
		health_label.text = "LIFE  %d / %d" % [_last_health, max_health]
	_update_health_segments(max_health, _last_health, health_fill_rect)
	if invulnerability_fill != null:
		var invulnerability_fill_rect := _get_meter_full_rect(invulnerability_fill, invulnerability_bar_back, health_fill_rect.size.x)
		var invulnerability_ratio: float = 0.0
		if _last_invulnerability_duration > 0.0:
			invulnerability_ratio = clamp(_last_invulnerability_remaining / _last_invulnerability_duration, 0.0, 1.0)
		_set_meter_fill_width(invulnerability_fill, invulnerability_fill_rect.size.x * invulnerability_ratio)
	if invulnerability_bar_back != null:
		invulnerability_bar_back.visible = _last_invulnerability_remaining > 0.0
	_update_overdrive_bar(_get_meter_full_rect(overdrive_fill, overdrive_bar_back, health_fill_rect.size.x))
	_update_super_bar(_get_meter_full_rect(super_fill, super_bar_back, health_fill_rect.size.x))
	if stats_label != null:
		stats_label.visible = false
		var parry_text := "READY"
		if _last_parry_cooldown_remaining > 0.0:
			parry_text = "%.1fs" % _last_parry_cooldown_remaining
		stats_label.text = "Shot x%d  Pierce %d  Chain %d  AoE %d  Size %d%%\nParry %s" % [
			int(_latest_modifiers.get("projectile_count", 1)),
			int(_latest_modifiers.get("pierce_count", 0)),
			int(_latest_modifiers.get("chain_count", 0)),
			roundi(float(_latest_modifiers.get("explosion_radius", 0.0))),
			roundi(float(_latest_modifiers.get("projectile_size_multiplier", 1.0)) * 100.0),
			parry_text
		]
	if attribute_label != null:
		attribute_label.visible = false
		attribute_label.text = _get_attribute_text()
	_update_ammo_counter_panel(active_effects)


func _get_meter_full_rect(fill: Control, bar_back: Control, fallback_width: float) -> Rect2:
	if fill != null:
		var key := _get_meter_cache_key(fill)
		if not _meter_full_rects.has(key):
			_capture_meter_fill_rect(fill)
		if _meter_full_rects.has(key):
			return _meter_full_rects[key]
	if bar_back != null and bar_back.size.x > 0.0:
		return Rect2(Vector2.ZERO, bar_back.size)
	return Rect2(Vector2.ZERO, Vector2(fallback_width, 20.0))


func _set_meter_fill_width(fill: Control, width: float) -> void:
	if fill == null:
		return
	fill.offset_right = fill.offset_left + max(width, 0.0)


func _update_health_segments(max_health: int, health: int, fill_rect: Rect2) -> void:
	if health_tick_layer == null:
		return
	var health_ratio: float = clamp(float(health) / float(max(max_health, 1)), 0.0, 1.0)
	_update_meter_segments(
		health_tick_layer,
		max_health,
		clampi(health, 0, max_health),
		fill_rect,
		_get_health_meter_color(health_ratio),
		"HealthSegment"
	)


func _update_overdrive_bar(fill_rect: Rect2) -> void:
	var max_ammo: int = max(_last_overdrive_max_ammo, 1)
	var ratio: float = clamp(float(_last_overdrive_ammo) / float(max_ammo), 0.0, 1.0)
	var flash_ratio := 0.0
	if _ammo_refill_flash_duration > 0.0:
		flash_ratio = clamp(_ammo_refill_flash_remaining / _ammo_refill_flash_duration, 0.0, 1.0)
	if overdrive_bar_back != null:
		overdrive_bar_back.color = OVERDRIVE_BAR_BACK_COLOR
	var fill_color := Color(0.16, 0.52, 1.0, 1.0)
	if _last_overdrive_is_active:
		fill_color = Color(0.36, 0.78, 1.0, 1.0)
	if flash_ratio > 0.0:
		fill_color = fill_color.lerp(Color(1.0, 1.0, 1.0, 1.0), flash_ratio * 0.55)
	_update_overdrive_segments(max_ammo, _last_overdrive_ammo, fill_rect, fill_color)
	if overdrive_fill != null:
		_set_meter_fill_width(overdrive_fill, fill_rect.size.x * ratio)
		overdrive_fill.color = fill_color
		overdrive_fill.visible = false
	if overdrive_label != null:
		var state_text := "ON" if _last_overdrive_is_active else ("HELD" if _last_overdrive_is_held else "READY")
		overdrive_label.text = "OVERDRIVE  %d / %d  %s" % [_last_overdrive_ammo, max_ammo, state_text]


func _update_overdrive_segments(max_ammo: int, ammo: int, fill_rect: Rect2, fill_color: Color) -> void:
	if overdrive_tick_layer == null:
		return
	_update_meter_segments(
		overdrive_tick_layer,
		max_ammo,
		clampi(ammo, 0, max_ammo),
		fill_rect,
		fill_color,
		"OverdriveSegment"
	)


func _get_health_meter_color(health_ratio: float) -> Color:
	var red := Color(1.0, 0.12, 0.08, 1.0)
	var orange := Color(1.0, 0.54, 0.12, 1.0)
	var green := Color(0.18, 0.92, 0.28, 1.0)
	if health_ratio <= 0.5:
		return red.lerp(orange, clamp(health_ratio / 0.5, 0.0, 1.0))
	return orange.lerp(green, clamp((health_ratio - 0.5) / 0.5, 0.0, 1.0))


func _update_meter_segments(layer: Control, segment_count: int, active_count: int, fill_rect: Rect2, fill_color: Color, segment_prefix: String) -> void:
	var layer_key := layer.get_instance_id()
	var previous_active_count: int = int(_meter_active_segment_counts.get(layer_key, -1))
	if previous_active_count > active_count:
		_spawn_meter_segment_ejections(layer, segment_count, active_count, previous_active_count, fill_rect, fill_color, segment_prefix)
	_meter_active_segment_counts[layer_key] = active_count
	for child in layer.get_children():
		if bool(child.get_meta("meter_active_segment", false)):
			child.free()
	if segment_count <= 0 or active_count <= 0:
		return
	var segment_height: float = fill_rect.size.y
	if segment_height <= 0.0:
		segment_height = 20.0
	var segment_span: float = fill_rect.size.x / float(segment_count)
	var gap_width: float = min(METER_SEGMENT_GAP_PIXELS, segment_span * 0.34)
	var segment_width: float = max(segment_span - gap_width, METER_SEGMENT_MIN_WIDTH)
	var visible_count: int = min(active_count, segment_count)
	for index in range(visible_count):
		var segment := _create_meter_segment(
			"%s%d" % [segment_prefix, index + 1],
			Vector2(fill_rect.position.x + segment_span * float(index), fill_rect.position.y),
			Vector2(segment_width, segment_height),
			fill_color
		)
		segment.set_meta("meter_active_segment", true)
		layer.add_child(segment)


func _spawn_meter_segment_ejections(layer: Control, segment_count: int, active_count: int, previous_active_count: int, fill_rect: Rect2, fill_color: Color, segment_prefix: String) -> void:
	if segment_count <= 0:
		return
	var segment_height: float = fill_rect.size.y
	if segment_height <= 0.0:
		segment_height = 20.0
	var segment_span: float = fill_rect.size.x / float(segment_count)
	var gap_width: float = min(METER_SEGMENT_GAP_PIXELS, segment_span * 0.34)
	var segment_width: float = max(segment_span - gap_width, METER_SEGMENT_MIN_WIDTH)
	var first_removed: int = clampi(active_count, 0, segment_count)
	var last_removed: int = clampi(previous_active_count, 0, segment_count)
	for index in range(first_removed, last_removed):
		var segment := _create_meter_segment(
			"%sEject%d" % [segment_prefix, index + 1],
			Vector2(fill_rect.position.x + segment_span * float(index), fill_rect.position.y),
			Vector2(segment_width, segment_height),
			fill_color
		)
		segment.z_index = 4
		segment.set_meta("meter_ejected_segment", true)
		layer.add_child(segment)
		if not is_inside_tree():
			continue
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(segment, "position", segment.position + METER_SEGMENT_EJECT_OFFSET, METER_SEGMENT_EJECT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(segment, "modulate:a", 0.0, METER_SEGMENT_EJECT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.finished.connect(func() -> void:
			if is_instance_valid(segment):
				segment.queue_free()
		)


func _create_meter_segment(segment_name: String, segment_position: Vector2, segment_size: Vector2, fill_color: Color) -> Polygon2D:
	var segment := Polygon2D.new()
	segment.name = segment_name
	segment.position = segment_position
	segment.color = fill_color
	var skew_offset: float = min(tan(deg_to_rad(METER_SEGMENT_SKEW_DEGREES)) * segment_size.y, segment_size.x * 0.45)
	segment.polygon = PackedVector2Array([
		Vector2(skew_offset, 0.0),
		Vector2(segment_size.x, 0.0),
		Vector2(segment_size.x - skew_offset, segment_size.y),
		Vector2(0.0, segment_size.y)
	])
	segment.set_meta("meter_size", segment_size)
	segment.set_meta("skew_degrees", METER_SEGMENT_SKEW_DEGREES)
	return segment


func _update_super_bar(fill_rect: Rect2) -> void:
	var ratio: float = clamp(_last_super_meter / max(_last_super_meter_max, 1.0), 0.0, 1.0)
	var charge_ratio: float = _last_super_charge_ratio if _last_super_is_charging else 0.0
	var fill_ratio: float = max(ratio, charge_ratio)
	var is_ready := _is_super_meter_ready_for_feedback()
	var ready_flash_ratio := 0.0
	if _super_meter_ready_flash_duration > 0.0:
		ready_flash_ratio = clamp(_super_meter_ready_flash_remaining / _super_meter_ready_flash_duration, 0.0, 1.0)
	if super_fill != null:
		_set_meter_fill_width(super_fill, fill_rect.size.x * fill_ratio)
		var fill_color := Color(1.0, 0.76, 0.16, 1.0)
		if _last_super_is_charging:
			fill_color = fill_color.lerp(Color(0.42, 1.0, 1.0, 1.0), charge_ratio * 0.45)
		if is_ready:
			var ready_pulse := 0.5 + 0.5 * sin(_super_ready_pulse_time * TAU * 2.25)
			fill_color = fill_color.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.18 + ready_pulse * 0.38)
		if ready_flash_ratio > 0.0:
			fill_color = fill_color.lerp(Color(1.0, 1.0, 1.0, 1.0), ready_flash_ratio)
		super_fill.color = fill_color
	_update_super_crackle(fill_rect, is_ready)
	if super_label != null:
		var super_text := "READY" if ratio >= 1.0 and not _last_super_is_charging else "%d%%" % roundi(fill_ratio * 100.0)
		if _last_super_is_charging:
			super_text = "CHARGE %d%%" % roundi(charge_ratio * 100.0)
		super_label.text = "SPECIAL  %s" % super_text


func _update_super_crackle(fill_rect: Rect2, is_ready: bool) -> void:
	if super_bar_back == null:
		return
	if not is_ready or _super_crackle_remaining <= 0.0:
		_clear_super_crackle()
		return
	var crackle: Line2D = super_bar_back.get_node_or_null("SuperCrackle") as Line2D
	if crackle == null:
		crackle = Line2D.new()
		crackle.name = "SuperCrackle"
		crackle.antialiased = true
		super_bar_back.add_child(crackle)
	var alpha: float = clamp(_super_crackle_remaining / SUPER_CRACKLE_SECONDS, 0.0, 1.0)
	crackle.default_color = Color(1.0, 1.0, 1.0, 0.35 + alpha * 0.65)
	crackle.width = 1.2 + alpha * 1.8
	crackle.points = _build_super_crackle_points(fill_rect)


func _build_super_crackle_points(fill_rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var point_count: int = 7
	var start_x: float = fill_rect.position.x + 2.0
	var end_x: float = fill_rect.position.x + max(fill_rect.size.x - 2.0, 2.0)
	var center_y: float = fill_rect.position.y + fill_rect.size.y * 0.5
	var amplitude: float = max(fill_rect.size.y * 0.38, 2.0)
	for index in range(point_count):
		var ratio: float = float(index) / float(point_count - 1)
		var x: float = lerp(start_x, end_x, ratio)
		var y: float = center_y
		if index > 0 and index < point_count - 1:
			y += _super_crackle_rng.randf_range(-amplitude, amplitude)
		points.append(Vector2(x, y))
	return points


func _update_ammo_counter_panel(active_effects: Array) -> void:
	if ammo_counter_panel == null:
		return
	for child in ammo_counter_panel.get_children():
		child.free()
	ammo_counter_panel.visible = false


func _add_ammo_counter_square(display_name: String, ammo: int, max_ammo: int, fill_color: Color, icon_text: String, index: int, refill_flash_ratio: float = 0.0, perfect_flash_ratio: float = 0.0) -> void:
	var row := Control.new()
	row.name = "AmmoCounter%d" % index
	row.size = Vector2(56.0, 56.0)
	row.pivot_offset = Vector2(28.0, 28.0)
	var jump_wave: float = max(sin((1.0 - refill_flash_ratio) * PI), 0.0)
	var perfect_jump_wave: float = max(sin((1.0 - perfect_flash_ratio) * PI), 0.0)
	var jump: float = jump_wave * 10.0 * refill_flash_ratio + perfect_jump_wave * 20.0 * perfect_flash_ratio
	row.position = Vector2(0.0, float(index) * 62.0 - jump)
	row.scale = Vector2.ONE * (1.0 + refill_flash_ratio * 0.12 + perfect_flash_ratio * 0.18)
	ammo_counter_panel.add_child(row)

	var back := ColorRect.new()
	back.name = "Back"
	back.position = Vector2.ZERO
	back.size = Vector2(56.0, 56.0)
	back.color = Color(0.045, 0.05, 0.06, 0.92)
	if refill_flash_ratio > 0.0:
		back.color = back.color.lerp(Color(0.18, 0.17, 0.08, 0.98), refill_flash_ratio)
	if perfect_flash_ratio > 0.0:
		back.color = back.color.lerp(Color(1.0, 1.0, 1.0, 0.98), perfect_flash_ratio * 0.62)
	row.add_child(back)

	var ratio: float = clamp(float(ammo) / float(max_ammo), 0.0, 1.0)
	var is_low := ratio <= 0.2 or ammo <= 10
	if is_low:
		var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.018)
		back.color = Color(0.18 + pulse * 0.12, 0.055, 0.04, 0.96)
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.position = Vector2(4.0, 52.0 - 48.0 * ratio)
	fill.size = Vector2(48.0, 48.0 * ratio)
	fill.color = Color(fill_color.r, fill_color.g, fill_color.b, 0.62 + refill_flash_ratio * 0.22 + perfect_flash_ratio * 0.16)
	row.add_child(fill)

	if refill_flash_ratio > 0.0:
		var flash := ColorRect.new()
		flash.name = "RefillFlash"
		flash.position = Vector2.ZERO
		flash.size = Vector2(56.0, 56.0)
		flash.color = Color(1.0, 1.0, 0.74, 0.28 * refill_flash_ratio)
		row.add_child(flash)
	if perfect_flash_ratio > 0.0:
		var perfect_flash := ColorRect.new()
		perfect_flash.name = "PerfectRefillFlash"
		perfect_flash.position = Vector2.ZERO
		perfect_flash.size = Vector2(56.0, 56.0)
		perfect_flash.color = Color(1.0, 1.0, 1.0, 0.48 * perfect_flash_ratio)
		row.add_child(perfect_flash)

	var icon := Label.new()
	icon.name = "Icon"
	icon.position = Vector2(4.0, 5.0)
	icon.size = Vector2(48.0, 26.0)
	icon.text = icon_text
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 17 + roundi(refill_flash_ratio * 3.0 + perfect_flash_ratio * 3.0))
	if refill_flash_ratio > 0.0 or perfect_flash_ratio > 0.0:
		icon.add_theme_color_override("font_color", Color(1.0, 1.0, lerp(0.72, 1.0, perfect_flash_ratio), 1.0))
	row.add_child(icon)

	var count := Label.new()
	count.name = "Count"
	count.position = Vector2(4.0, 32.0)
	count.size = Vector2(48.0, 20.0)
	count.text = "%d" % ammo
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.add_theme_font_size_override("font_size", 13 + roundi(refill_flash_ratio * 2.0 + perfect_flash_ratio * 2.0))
	if refill_flash_ratio > 0.0 or perfect_flash_ratio > 0.0:
		count.add_theme_color_override("font_color", Color(1.0, 1.0, lerp(0.82, 1.0, perfect_flash_ratio), 1.0))
	row.add_child(count)

	if is_low:
		var border := ColorRect.new()
		border.name = "LowAmmoEdge"
		border.position = Vector2.ZERO
		border.size = Vector2(56.0, 4.0)
		border.color = Color(1.0, 0.9, 0.18, 0.92)
		row.add_child(border)

	row.tooltip_text = "%s  %d/%d" % [display_name, ammo, max_ammo]


func _should_show_super_counter() -> bool:
	return _status != "LEVEL_SELECT" and _last_super_meter_max > 0.0 and _last_max_health > 0


func _add_super_counter_square(index: int) -> void:
	var ratio: float = clamp(_last_super_meter / max(_last_super_meter_max, 1.0), 0.0, 1.0)
	var charge_ratio: float = _last_super_charge_ratio if _last_super_is_charging else 0.0
	var meter_flash_ratio: float = 0.0
	if _super_meter_flash_duration > 0.0:
		meter_flash_ratio = clamp(_super_meter_flash_remaining / _super_meter_flash_duration, 0.0, 1.0)
	var ready_flash_ratio: float = 0.0
	if _super_meter_ready_flash_duration > 0.0:
		ready_flash_ratio = clamp(_super_meter_ready_flash_remaining / _super_meter_ready_flash_duration, 0.0, 1.0)
	var row := Control.new()
	row.name = "SuperCounter"
	row.size = Vector2(56.0, 56.0)
	row.pivot_offset = Vector2(28.0, 28.0)
	var jump_wave: float = max(sin((1.0 - max(meter_flash_ratio, ready_flash_ratio)) * PI), 0.0)
	row.position = Vector2(0.0, float(index) * 62.0 - jump_wave * (8.0 * meter_flash_ratio + 16.0 * ready_flash_ratio))
	row.scale = Vector2.ONE * (1.0 + meter_flash_ratio * 0.1 + ready_flash_ratio * 0.18 + charge_ratio * 0.08)
	ammo_counter_panel.add_child(row)

	var back := ColorRect.new()
	back.name = "Back"
	back.position = Vector2.ZERO
	back.size = Vector2(56.0, 56.0)
	back.color = Color(0.045, 0.05, 0.06, 0.94)
	if ratio >= 1.0:
		back.color = back.color.lerp(Color(0.18, 0.14, 0.035, 0.98), 0.7)
	if ready_flash_ratio > 0.0:
		back.color = back.color.lerp(Color(1.0, 1.0, 1.0, 0.98), ready_flash_ratio * 0.58)
	row.add_child(back)

	var fill_ratio: float = max(ratio, charge_ratio)
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.position = Vector2(4.0, 52.0 - 48.0 * fill_ratio)
	fill.size = Vector2(48.0, 48.0 * fill_ratio)
	fill.color = Color(1.0, 0.82, 0.2, 0.62 + meter_flash_ratio * 0.2 + ready_flash_ratio * 0.22)
	if _last_super_is_charging:
		fill.color = fill.color.lerp(Color(0.35, 1.0, 1.0, 0.86), charge_ratio * 0.55)
	row.add_child(fill)

	if meter_flash_ratio > 0.0 or ready_flash_ratio > 0.0 or _last_super_is_charging:
		var flash := ColorRect.new()
		flash.name = "SuperFlash"
		flash.position = Vector2.ZERO
		flash.size = Vector2(56.0, 56.0)
		flash.color = Color(1.0, 1.0, 0.72, 0.22 * meter_flash_ratio + 0.42 * ready_flash_ratio + 0.18 * charge_ratio)
		row.add_child(flash)

	var icon := Label.new()
	icon.name = "Icon"
	icon.position = Vector2(4.0, 5.0)
	icon.size = Vector2(48.0, 26.0)
	icon.text = "SU"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 17 + roundi(ready_flash_ratio * 3.0 + charge_ratio * 2.0))
	if ratio >= 1.0 or _last_super_is_charging:
		icon.add_theme_color_override("font_color", Color(1.0, 1.0, 0.72, 1.0))
	row.add_child(icon)

	var count := Label.new()
	count.name = "Count"
	count.position = Vector2(2.0, 32.0)
	count.size = Vector2(52.0, 20.0)
	if _last_super_is_charging:
		count.text = "%d" % roundi(charge_ratio * 100.0)
	else:
		count.text = "%d" % roundi(ratio * 100.0)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.add_theme_font_size_override("font_size", 12 + roundi(ready_flash_ratio * 2.0 + charge_ratio * 2.0))
	if ratio >= 1.0 or _last_super_is_charging:
		count.add_theme_color_override("font_color", Color(1.0, 0.96, 0.68, 1.0))
	row.add_child(count)

	if ratio >= 1.0 and not _last_super_is_charging:
		var ready_edge := ColorRect.new()
		ready_edge.name = "ReadyEdge"
		ready_edge.position = Vector2.ZERO
		ready_edge.size = Vector2(56.0, 4.0)
		ready_edge.color = Color(0.42, 1.0, 1.0, 0.95)
		row.add_child(ready_edge)

	row.tooltip_text = "Super Shot  %d/%d" % [roundi(_last_super_meter), roundi(_last_super_meter_max)]


func _get_ammo_counter_color(effect) -> Color:
	match String(effect.id):
		"spread_shot":
			return Color(1.0, 0.82, 0.24)
		"piercing_shot":
			return Color(0.72, 0.95, 1.0)
		"chain_lightning":
			return Color(0.7, 0.45, 1.0)
		"fire_burst":
			return Color(1.0, 0.28, 0.08)
		"water_swell":
			return Color(0.18, 0.62, 1.0)
	return Color(0.48, 1.0, 0.62)


func _get_ammo_counter_icon(effect) -> String:
	match String(effect.id):
		"spread_shot":
			return "SP"
		"piercing_shot":
			return "PI"
		"chain_lightning":
			return "CH"
		"fire_burst":
			return "F"
		"water_swell":
			return "W"
	return "AM"


func _update_game_over_panel() -> void:
	if game_over_panel == null:
		return
	game_over_panel.visible = _status == "DOWN"
	if game_over_score_label != null:
		game_over_score_label.text = "Score: %d" % _score
	if win_panel != null:
		win_panel.visible = _status == "WON" or _status == "FLOOR_CLEARED"
	if win_title_label != null:
		win_title_label.text = "MISSION RESULTS" if _is_main_loop_run and _status == "FLOOR_CLEARED" else ("FLOOR CLEARED" if _status == "FLOOR_CLEARED" else "LEVEL CLEARED")
	if win_score_label != null:
		win_score_label.text = "Score: %d\n%s" % [_score, _get_tally_text()] if _is_main_loop_run and _status == "FLOOR_CLEARED" else "Score: %d" % _score
	if win_prompt_label != null:
		win_prompt_label.text = "Press Enter/A for next floor" if _status == "FLOOR_CLEARED" else "Press R or Start to return to level select"
	if game_over_title_label != null:
		game_over_title_label.text = "RUN ENDED" if _is_main_loop_run and _status == "DOWN" else "GAME OVER"
	if game_over_tally_label != null:
		game_over_tally_label.text = _get_tally_text()
	if game_over_prompt_label != null:
		game_over_prompt_label.text = "Press R or Start/A to restart"


func _update_pause_panel() -> void:
	if pause_panel == null:
		return
	var is_paused: bool = _status == "PAUSED" or _status == "PAUSE_EXIT_CONFIRM"
	pause_panel.visible = is_paused
	if not is_paused:
		return
	if pause_stats_label != null:
		pause_stats_label.text = _get_pause_stats_text()
	if pause_prompt_label != null:
		pause_prompt_label.text = "Esc/Start resumes. Enter/A opens exit prompt." if _status == "PAUSED" else "Exit confirmation is open."
	if pause_confirm_panel != null:
		pause_confirm_panel.visible = _status == "PAUSE_EXIT_CONFIRM"


func _get_pause_stats_text() -> String:
	var active_effects: Array = upgrade_manager.get_active_effects()
	var overdrive_lines: Array[String] = []
	for state in active_effects:
		var effect = state["effect"]
		overdrive_lines.append("%s x%d" % [effect.display_name, int(state.get("stacks", 0))])
	var overdrive_text: String = "No effect stacks yet. Held overdrive doubles regular bullet size." if overdrive_lines.is_empty() else ", ".join(overdrive_lines)
	var parry_text: String = "READY" if _last_parry_cooldown_remaining <= 0.0 else "%.1fs" % _last_parry_cooldown_remaining
	var super_text: String = "READY" if _last_super_meter >= _last_super_meter_max else "%d%%" % roundi((_last_super_meter / max(_last_super_meter_max, 1.0)) * 100.0)
	if _last_super_is_charging:
		super_text = "Charging %d%%" % roundi(_last_super_charge_ratio * 100.0)
	var overdrive_state := "ON" if _last_overdrive_is_active else ("HELD" if _last_overdrive_is_held else "READY")
	return "Score: %d\nHealth: %d / %d\nEnemies: %d  Spawners: %d  Pickups: %d\nParry: %s  Super: %s\nOverdrive: %d / %d  %s\n\n%s\n\nOverdrive Effects: %s" % [
		_score,
		_last_health,
		max(_last_max_health, 1),
		enemy_manager.get_enemy_count(),
		spawner_manager.get_spawner_count(),
		item_manager.get_pickup_count(),
		parry_text,
		super_text,
		_last_overdrive_ammo,
		_last_overdrive_max_ammo,
		overdrive_state,
		_get_attribute_text(),
		overdrive_text
	]


func _get_upgrade_lines(active_effects: Array) -> Array[String]:
	var lines: Array[String] = []
	for state in active_effects:
		var effect = state["effect"]
		lines.append("%s x%d" % [effect.display_name, int(state.get("stacks", 0))])
	return lines


func _get_attribute_text() -> String:
	if _permanent_stats.is_empty():
		return "Attributes\nFire Rate +0%  Move +0%  Damage +0%  Size +0%  OD Cap +0"
	var fire_bonus := float(_attribute_modifiers.get("fire_rate_bonus", 0.0))
	var move_bonus := float(_attribute_modifiers.get("move_speed_bonus", 0.0))
	var damage_bonus := float(_attribute_modifiers.get("damage_bonus", 0.0))
	var size_bonus := float(_attribute_modifiers.get("projectile_size_bonus", 0.0))
	var overdrive_capacity_bonus := float(_attribute_modifiers.get("overdrive_capacity_bonus", 0.0))
	var stack_lines: Array[String] = []
	for stat in _permanent_stats:
		stack_lines.append("%s x%d" % [stat["display_name"], int(stat["stacks"])])
	return "Attributes\nFire Rate +%d%%  Move +%d%%  Damage +%d%%  Size +%d%%  OD Cap +%d\n%s" % [
		roundi(fire_bonus * 100.0),
		roundi(move_bonus * 100.0),
		roundi(damage_bonus * 100.0),
		roundi(size_bonus * 100.0),
		roundi(overdrive_capacity_bonus),
		", ".join(stack_lines)
	]


func _maybe_spawn_current_room_reward_choices() -> void:
	if not _is_dungeon_run:
		return
	var state: Dictionary = dungeon_manager.get_current_room_state()
	if state.is_empty():
		return
	var room_kind := String(state["piece"].room_kind)
	if room_kind != "treasure" and room_kind != "challenge":
		return
	if not dungeon_manager.is_current_room_cleared():
		return
	var reward_key := _get_current_room_reward_key()
	if _rewarded_room_ids.has(reward_key):
		return
	_rewarded_room_ids[reward_key] = true
	var reward_position := Vector2.ZERO
	if _current_level != null:
		reward_position = _find_safe_room_position(_current_level.arena_bounds.get_center(), _current_level)
	if room_kind == "treasure":
		item_manager.spawn_treasure_reward_choices(reward_position)
	else:
		item_manager.spawn_overdrive_reward_choices(reward_position)
	_update_hud()


func _spawn_floor_overdrive_reward_choices(origin: Vector2) -> void:
	if not _is_main_loop_run:
		return
	var reward_key := "floor_%d_boss_reward" % _main_loop_floor
	if _rewarded_room_ids.has(reward_key):
		return
	_rewarded_room_ids[reward_key] = true
	var reward_position := origin
	if _current_level != null:
		reward_position = _find_safe_room_position(origin + Vector2(0.0, 86.0), _current_level)
	item_manager.spawn_overdrive_reward_choices(reward_position)


func _get_current_room_reward_key() -> String:
	return "floor_%d_room_%s_reward" % [dungeon_manager.floor_number, dungeon_manager.current_room_id]


func _check_level_clear() -> void:
	if _is_loading_room:
		return
	if not _is_gameplay_running():
		return
	if spawner_manager.get_spawner_count() > 0 or enemy_manager.get_enemy_count() > 0:
		return
	if _is_dungeon_run:
		if _is_main_loop_run and dungeon_manager.is_current_boss_room() and _floor_exit_portal_active():
			room_manager.set_doors_unlocked(false)
			_update_hud()
			return
		dungeon_manager.mark_current_room_cleared()
		room_manager.set_doors_unlocked(true)
		_maybe_spawn_current_room_reward_choices()
		if dungeon_manager.is_current_boss_room() and not _is_main_loop_run:
			_status = "WON"
			_set_all_enabled(false)
			_set_tree_paused(true)
			if win_panel != null:
				win_panel.visible = true
		_update_hud()
		return
	_status = "WON"
	_set_all_enabled(false)
	_set_tree_paused(true)
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
	if _is_gameplay_running() and item_manager.collect_focused_reward():
		_update_hud()
		return
	if _status == "LEVEL_SELECT":
		_start_selected_level()
	elif _status == "PAUSED":
		_status = "PAUSE_EXIT_CONFIRM"
		_update_hud()
	elif _status == "PAUSE_EXIT_CONFIRM":
		_enter_level_select()
	elif _status == "FLOOR_CLEARED":
		_advance_main_loop_floor()
	elif _status == "WON":
		_enter_level_select()


func _on_menu_back_requested() -> void:
	if _status == "PAUSED":
		_resume_from_pause()
	elif _status == "PAUSE_EXIT_CONFIRM":
		_status = "PAUSED"
		_update_hud()
	elif _status == "WON" or _status == "FLOOR_CLEARED":
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
	_clear_floor_exit_portal()
	if arena_view != null:
		arena_view.configure(level_definition)
	player_manager.set_arena_definition(level_definition)
	projectile_manager.set_arena_definition(level_definition)
	enemy_manager.set_arena_definition(level_definition)
	spawner_manager.set_arena_definition(level_definition)
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	spawner_manager.clear_spawners()
	destructible_manager.clear_destructibles()
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
	destructible_manager.reset_run(level_definition)
	room_manager.load_room(level_definition, dungeon_manager.get_current_door_infos(), room_is_cleared)
	_set_all_enabled(true)
	if not room_is_cleared and level_definition.boss_profile != null:
		enemy_manager.spawn_enemy(level_definition.boss_profile, level_definition.boss_spawn_position)
		if _is_main_loop_run and dungeon_manager.is_current_boss_room():
			_show_boss_exit_portal_preview(level_definition)
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
	for void_rect in level_definition.void_rects:
		if void_rect.grow(34.0).has_point(position):
			return false
	return true


func _is_gameplay_running() -> bool:
	return _status == "RUNNING" or _status == "DUNGEON"


func _get_status_label() -> String:
	if _is_main_loop_run and _status == "DUNGEON" and _floor_exit_portal_active():
		return "FLOOR %d EXIT OPEN" % _main_loop_floor
	if _is_main_loop_run and _status == "DUNGEON":
		return "FLOOR %d" % _main_loop_floor
	if _is_main_loop_run and _status == "FLOOR_CLEARED":
		return "FLOOR %d CLEARED" % _main_loop_floor
	if _status == "BOSS_CLEARING":
		return "BOSS DEFEATED"
	if _is_dungeon_run and _status == "DUNGEON":
		return "DUNGEON"
	return _status


func _get_dungeon_hud_suffix() -> String:
	var state: Dictionary = dungeon_manager.get_current_room_state()
	if state.is_empty():
		return ""
	var piece = state["piece"]
	var door_text := "doors open" if dungeon_manager.is_current_room_cleared() else "clear room to open doors"
	if _is_main_loop_run and _floor_exit_portal_active():
		door_text = "exit portal open"
	var floor_text := "  |  Floor %d" % _main_loop_floor if _is_main_loop_run else ""
	var seed_text := "  |  Seed %d" % _run_seed if _run_seed > 0 else ""
	return "\nRoom: %s%s%s  |  %s" % [piece.display_name, floor_text, seed_text, door_text]


func _get_select_option_count() -> int:
	return LEVELS.size() + DUNGEON_OPTION_COUNT


func _update_minimap() -> void:
	if dungeon_minimap == null:
		return
	if _is_dungeon_run and (_status == "DUNGEON" or _status == "DOWN" or _status == "WON" or _status == "FLOOR_CLEARED" or _status == "BOSS_CLEARING"):
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


func _activate_boss_exit_portal(boss_position: Vector2, boss_radius: float) -> void:
	if _floor_exit_portal_active():
		return
	var explosion_radius: float = max(boss_radius * 4.4, 180.0)
	effects_manager.play_explosion(boss_position, explosion_radius, 0.72)
	if _floor_exit_portal != null and is_instance_valid(_floor_exit_portal):
		if _floor_exit_portal.has_method("set_active"):
			_floor_exit_portal.set_active(true)
	else:
		var portal = FLOOR_EXIT_PORTAL_SCENE.instantiate()
		var portal_layer: Node = $World/DoorLayer
		if portal_layer != null:
			portal_layer.add_child(portal)
		else:
			add_child(portal)
		var portal_position := _get_boss_exit_portal_position(boss_position)
		if portal.has_method("initialize"):
			portal.initialize(portal_position, max(boss_radius * 1.05, 48.0), true)
		_connect_once(portal, &"entered", _on_floor_exit_portal_entered)
		_floor_exit_portal = portal
	_update_minimap()


func _show_boss_exit_portal_preview(level_definition) -> void:
	if level_definition == null:
		return
	if _floor_exit_portal != null and is_instance_valid(_floor_exit_portal):
		return
	var portal = FLOOR_EXIT_PORTAL_SCENE.instantiate()
	var portal_layer: Node = $World/DoorLayer
	if portal_layer != null:
		portal_layer.add_child(portal)
	else:
		add_child(portal)
	var portal_radius := 48.0
	if level_definition.boss_profile != null:
		portal_radius = max(float(level_definition.boss_profile.body_radius) * 1.05, 48.0)
	if portal.has_method("initialize"):
		portal.initialize(_get_boss_exit_portal_position(level_definition.boss_spawn_position), portal_radius, false)
	_connect_once(portal, &"entered", _on_floor_exit_portal_entered)
	_floor_exit_portal = portal


func _get_boss_exit_portal_position(boss_position: Vector2) -> Vector2:
	if _current_level == null:
		return boss_position
	var bounds: Rect2 = _current_level.arena_bounds
	var center := bounds.get_center()
	var candidates := [
		center + Vector2(-260.0, 0.0),
		center + Vector2(260.0, 0.0),
		center + Vector2(0.0, -220.0),
		center + Vector2(0.0, 220.0),
		center + Vector2(-360.0, -240.0),
		center + Vector2(360.0, -240.0),
		center + Vector2(-360.0, 240.0),
		center + Vector2(360.0, 240.0),
		boss_position + Vector2(-320.0, 0.0),
		boss_position + Vector2(320.0, 0.0),
		boss_position + Vector2(0.0, -260.0),
		boss_position + Vector2(0.0, 260.0)
	]
	for radius in [220.0, 320.0, 440.0]:
		for index in range(12):
			candidates.append(center + Vector2.RIGHT.rotated(TAU * float(index) / 12.0) * radius)
	for candidate in candidates:
		var safe_candidate := ArenaGeometry.constrain_point(candidate, bounds, int(_current_level.arena_shape))
		if safe_candidate.distance_squared_to(boss_position) < 140.0 * 140.0:
			continue
		if not ArenaGeometry.contains_point(safe_candidate, bounds, int(_current_level.arena_shape)):
			continue
		if _position_is_clear_of_room_walls(safe_candidate, _current_level):
			return safe_candidate
	return _find_safe_room_position(boss_position + Vector2(-320.0, 0.0), _current_level)


func _on_floor_exit_portal_entered(portal) -> void:
	if portal != _floor_exit_portal or not _floor_exit_portal_active() or not _is_main_loop_run or _status != "DUNGEON":
		return
	_clear_floor_exit_portal()
	_complete_main_loop_floor()
	_update_hud()


func _floor_exit_portal_active() -> bool:
	if _floor_exit_portal == null or not is_instance_valid(_floor_exit_portal):
		return false
	if _floor_exit_portal.has_method("is_active"):
		return bool(_floor_exit_portal.is_active())
	return true


func _clear_floor_exit_portal() -> void:
	if _floor_exit_portal != null and is_instance_valid(_floor_exit_portal):
		_floor_exit_portal.queue_free()
	_floor_exit_portal = null


func _complete_main_loop_floor() -> void:
	if _status == "FLOOR_CLEARED":
		return
	_clear_floor_exit_portal()
	_run_floors_cleared = max(_run_floors_cleared, _main_loop_floor)
	_status = "FLOOR_CLEARED"
	_set_all_enabled(false)
	_set_tree_paused(true)
	if win_panel != null:
		win_panel.visible = true
	_update_minimap()
	_update_game_over_panel()


func _begin_boss_clear_transition(boss_position: Vector2, boss_radius: float, pending_status: String) -> void:
	if _status == "BOSS_CLEARING" or _status == "FLOOR_CLEARED" or _status == "WON":
		return
	_status = "BOSS_CLEARING"
	_boss_clear_pending_status = pending_status
	_boss_clear_delay_remaining = BOSS_CLEAR_DELAY_SECONDS
	var explosion_radius: float = max(boss_radius * 5.6, 220.0)
	effects_manager.play_explosion(boss_position, explosion_radius, BOSS_CLEAR_DELAY_SECONDS, true)
	_set_all_enabled(false)
	_set_tree_paused(true)
	if win_panel != null:
		win_panel.visible = false
	_update_minimap()
	_update_hud()


func _update_boss_clear_transition(delta: float) -> void:
	_boss_clear_delay_remaining = max(_boss_clear_delay_remaining - delta, 0.0)
	if _boss_clear_delay_remaining > 0.0:
		return
	var pending_status := _boss_clear_pending_status
	_boss_clear_pending_status = ""
	if pending_status == "FLOOR_CLEARED":
		_complete_main_loop_floor()
	elif pending_status == "WON":
		_status = "WON"
		_set_all_enabled(false)
		_set_tree_paused(true)
		if win_panel != null:
			win_panel.visible = true
		_update_hud()


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
	return "Seed: %d\nFloors cleared: %d\nEnemies: %d  Bosses: %d\nSpawners: %d\nPickups: %d\nAmmo: %d  Permanent: %d  Heals: %d" % [
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
