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
const AGENT_BOSS_GENERATOR := preload("res://scripts/resources/agent_boss_generator.gd")
const BOLD_PIXELS_FONT := preload("res://art/fonts/BoldPixels.ttf")

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
@onready var loading_screen: Control = $UI/LoadingScreen

## Multiplies player movement speed while walking through the composed cleared-floor traversal map.
@export var cleared_floor_speed_multiplier: float = 1.45

var _score: int = 0
var _last_health: int = 0
var _last_max_health: int = 0
var _last_invulnerability_remaining: float = 0.0
var _last_invulnerability_duration: float = 0.0
var _last_parry_cooldown_remaining: float = 0.0
var _last_parry_cooldown_duration: float = 0.0
var _last_parry_chain_count: int = 0
var _last_parry_chain_grace_remaining: float = 0.0
var _last_parry_chain_grace_duration: float = 0.0
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
var _is_cleared_floor_map_active: bool = false
var _is_loading_room: bool = false
var _loading_transition_pending: bool = false
var _loading_completion_floor_start_pending: bool = false
var _paused_previous_status: String = ""
var _main_loop_floor: int = 1
var _run_seed: int = 0
var _agent_boss_generation_nonce: int = 0
var _run_enemy_kills: int = 0
var _run_spawner_kills: int = 0
var _run_boss_kills: int = 0
var _run_pickups_collected: int = 0
var _run_ammo_upgrades: int = 0
var _run_permanent_upgrades: int = 0
var _run_heals: int = 0
var _run_floors_cleared: int = 0
var _run_longest_parry_chain: int = 0
var _tree_pause_requested: bool = false
var _boss_clear_delay_remaining: float = 0.0
var _boss_clear_pending_status: String = ""
var _floor_exit_portal = null
var _rewarded_room_ids: Dictionary = {}
var _reward_prompt_text: String = ""
var _last_minimap_player_cell: Vector2i = Vector2i.ZERO
var _has_last_minimap_player_cell: bool = false
var _last_minimap_player_position: Vector2 = Vector2.ZERO
var _has_last_minimap_player_position: bool = false
var _last_minimap_room_id: String = ""
var _minimap_player_cell_check_remaining: float = 0.0
var _camera_recenter_remaining: float = 0.0
var _is_room_entry_transition_active: bool = false
var _entry_transition_target_room_id: String = ""
var _entry_transition_entry_direction: String = ""
var _entry_transition_floor_entry_position: Vector2 = Vector2.ZERO
var _entry_transition_camera_target_position: Vector2 = Vector2.ZERO
var _entry_transition_player_target_position: Vector2 = Vector2.INF
var _entry_transition_auto_walk_elapsed: float = 0.0
var _ammo_refill_flash_remaining: float = 0.0
var _ammo_refill_flash_duration: float = 0.48
var _ammo_refill_perfect_flash_remaining: float = 0.0
var _ammo_refill_perfect_flash_duration: float = 0.58
var _ammo_segment_refill_flash_remaining: float = 0.0
var _ammo_segment_refill_flash_duration: float = 0.0
var _ammo_segment_refill_start_ammo: int = 0
var _ammo_segment_refill_end_ammo: int = 0
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
var _agent_debug_panel: ColorRect = null
var _agent_debug_label: Label = null
var _boss_health_panel: Control = null
var _boss_health_label: Label = null
var _boss_health_bar_back: ColorRect = null
var _boss_health_fill: ColorRect = null
var _boss_health_tick_layer: Control = null
var _boss_alert_overlay: ColorRect = null
var _boss_alert_label: Label = null
var _active_boss: EnemyEntity = null
var _pending_agent_boss_presentation: EnemyEntity = null
var _last_boss_health: int = 0
var _last_boss_max_health: int = 0
var _boss_health_display_count: int = 0
var _boss_health_reveal_remaining: float = 0.0
var _boss_health_reveal_duration: float = 0.0
var _boss_alert_remaining: float = 0.0
var _boss_alert_duration: float = 0.0
var _boss_alert_flash_count: int = 2
var _boss_health_hide_remaining: float = 0.0

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
const BOSS_METER_SEGMENT_EJECT_OFFSET := Vector2(20.0, -30.0)
const BOSS_HEALTH_BAR_WIDTH := 840.0
const BOSS_HEALTH_BAR_HEIGHT := 28.0
const BOSS_HEALTH_HIDE_SECONDS := 1.05
const BOSS_ALERT_DEFAULT_SECONDS := 2.35
const BOSS_ALERT_HEALTH_FILL_SECONDS := 1.45
const BOSS_ALERT_DEFAULT_FLASH_COUNT := 3
const AMMO_SEGMENT_REFILL_STEP_SECONDS := 0.06
const AMMO_SEGMENT_REFILL_MIN_SECONDS := 0.22
const AMMO_SEGMENT_REFILL_MAX_SECONDS := 0.72
const MINIMAP_PLAYER_CELL_CHECK_SECONDS := 0.1
const CLEARED_FLOOR_CAMERA_RECENTER_SECONDS := 1.05
const CLEARED_FLOOR_CAMERA_RECENTER_RESPONSE := 3.6
const ROOM_ENTRY_CAMERA_RESPONSE := 3.2
const ROOM_ENTRY_COMPLETE_DISTANCE := 96.0
const ROOM_ENTRY_CAMERA_DISTANCE := 8.0
const ROOM_ENTRY_AUTO_WALK_ARRIVE_DISTANCE := 14.0
const ROOM_ENTRY_AUTO_WALK_TIMEOUT := 2.4
const ROOM_ENTRY_INSIDE_NUDGE_DISTANCE := 96.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_super_crackle_rng.randomize()
	_capture_hud_authoring_state()
	_ensure_agent_debug_panel()
	_ensure_boss_health_hud()
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
		if _ammo_segment_refill_flash_remaining > 0.0:
			_ammo_segment_refill_flash_remaining = max(_ammo_segment_refill_flash_remaining - delta, 0.0)
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
	if _update_boss_health_feedback(delta):
		_update_boss_health_panel()
	if _is_gameplay_running():
		_update_camera(delta)
		if _is_room_entry_transition_active:
			_update_room_entry_transition(delta)
		if _is_dungeon_run:
			_minimap_player_cell_check_remaining -= delta
			if _minimap_player_cell_check_remaining <= 0.0:
				_minimap_player_cell_check_remaining = MINIMAP_PLAYER_CELL_CHECK_SECONDS
				_update_minimap_player_cell_if_changed()


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
	_connect_once(player_manager, &"parry_chain_changed", _on_player_parry_chain_changed)
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
	_connect_once(enemy_manager, &"enemy_health_changed", _on_enemy_health_changed)
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
	if loading_screen != null:
		_connect_once(loading_screen, &"continue_requested", _on_loading_continue_requested)


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


func _ensure_agent_debug_panel() -> void:
	if _agent_debug_panel != null and is_instance_valid(_agent_debug_panel):
		return
	var ui_layer: CanvasLayer = get_node_or_null("UI") as CanvasLayer
	if ui_layer == null:
		return
	var panel: ColorRect = ColorRect.new()
	panel.name = "AgentDebugPanel"
	panel.visible = false
	panel.color = Color(0.012, 0.014, 0.018, 0.78)
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 24.0
	panel.offset_top = 230.0
	panel.offset_right = 284.0
	panel.offset_bottom = 378.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(panel)
	var label: Label = Label.new()
	label.name = "AgentDebugLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.offset_left = 8.0
	label.offset_top = 7.0
	label.offset_right = 252.0
	label.offset_bottom = 140.0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", BOLD_PIXELS_FONT)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0, 1.0))
	panel.add_child(label)
	_agent_debug_panel = panel
	_agent_debug_label = label


func _set_agent_debug_panel_visible(value: bool) -> void:
	if _agent_debug_panel == null or not is_instance_valid(_agent_debug_panel):
		return
	_agent_debug_panel.visible = value


func _update_agent_debug_panel(level_definition, boss) -> void:
	_ensure_agent_debug_panel()
	if _agent_debug_panel == null or _agent_debug_label == null:
		return
	if level_definition == null or String(level_definition.id) != "boss_test_chamber" or boss == null or not is_instance_valid(boss):
		_set_agent_debug_panel_visible(false)
		return
	var program: AgentBossProgram = boss.agent_program as AgentBossProgram
	if program == null:
		_set_agent_debug_panel_visible(false)
		return
	_agent_debug_label.text = "AGENT DEBUG\nSeed %d\nType %s\nSlow %s\nMove %s + %s\nSpec %s / %s\nAtk %s\nW %.2f %.2f %.2f\nCD HE %.1f  SP %.1f\nSize %.1f" % [
		int(program.generation_seed),
		String(program.personality_verb),
		String(program.slow_attack_verb),
		String(program.normal_movement_verb),
		String(program.high_explosive_verb),
		String(program.special_movement_verb),
		String(program.special_reposition_verb),
		String(program.special_attack_verb),
		float(program.slow_action_weight),
		float(program.normal_action_weight),
		float(program.special_action_weight),
		float(program.high_explosive_cooldown_seconds),
		float(program.special_base_cooldown_seconds),
		float(program.body_radius)
	]
	_set_agent_debug_panel_visible(true)


func _ensure_boss_health_hud() -> void:
	if _boss_health_panel != null and is_instance_valid(_boss_health_panel):
		return
	var ui_layer: CanvasLayer = get_node_or_null("UI") as CanvasLayer
	if ui_layer == null:
		return
	if _boss_alert_overlay == null or not is_instance_valid(_boss_alert_overlay):
		var overlay: ColorRect = ColorRect.new()
		overlay.name = "BossAlertOverlay"
		overlay.visible = false
		overlay.color = Color(1.0, 0.04, 0.02, 0.0)
		overlay.anchor_left = 0.0
		overlay.anchor_right = 1.0
		overlay.anchor_top = 0.0
		overlay.anchor_bottom = 1.0
		overlay.offset_left = 0.0
		overlay.offset_right = 0.0
		overlay.offset_top = 0.0
		overlay.offset_bottom = 0.0
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.z_index = -10
		ui_layer.add_child(overlay)
		ui_layer.move_child(overlay, 0)
		var alert_label: Label = Label.new()
		alert_label.name = "BossAlertLabel"
		alert_label.text = "ALERT"
		alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		alert_label.anchor_left = 0.0
		alert_label.anchor_right = 1.0
		alert_label.anchor_top = 0.0
		alert_label.anchor_bottom = 1.0
		alert_label.offset_left = 0.0
		alert_label.offset_right = 0.0
		alert_label.offset_top = -24.0
		alert_label.offset_bottom = 0.0
		alert_label.add_theme_font_override("font", BOLD_PIXELS_FONT)
		alert_label.add_theme_font_size_override("font_size", 58)
		alert_label.add_theme_color_override("font_color", Color(1.0, 0.68, 0.56, 0.0))
		alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(alert_label)
		_boss_alert_overlay = overlay
		_boss_alert_label = alert_label
	var panel: Control = Control.new()
	panel.name = "BossHealthPanel"
	panel.visible = false
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -BOSS_HEALTH_BAR_WIDTH * 0.5
	panel.offset_right = BOSS_HEALTH_BAR_WIDTH * 0.5
	panel.offset_top = -86.0
	panel.offset_bottom = -22.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(panel)
	var name_label: Label = Label.new()
	name_label.name = "BossNameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.offset_left = 0.0
	name_label.offset_right = BOSS_HEALTH_BAR_WIDTH
	name_label.offset_top = 0.0
	name_label.offset_bottom = 28.0
	name_label.add_theme_font_override("font", BOLD_PIXELS_FONT)
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.46, 1.0))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_label)
	var bar_back: ColorRect = ColorRect.new()
	bar_back.name = "BossHealthBarBack"
	bar_back.color = Color(0.08, 0.008, 0.006, 0.92)
	bar_back.offset_left = 0.0
	bar_back.offset_right = BOSS_HEALTH_BAR_WIDTH
	bar_back.offset_top = 32.0
	bar_back.offset_bottom = 32.0 + BOSS_HEALTH_BAR_HEIGHT
	bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bar_back)
	var fill: ColorRect = ColorRect.new()
	fill.name = "BossHealthBarFill"
	fill.color = Color(1.0, 0.18, 0.08, 1.0)
	fill.offset_left = 0.0
	fill.offset_right = BOSS_HEALTH_BAR_WIDTH
	fill.offset_top = 0.0
	fill.offset_bottom = BOSS_HEALTH_BAR_HEIGHT
	fill.visible = false
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_back.add_child(fill)
	var tick_layer: Control = Control.new()
	tick_layer.name = "BossHealthTickLayer"
	tick_layer.offset_left = 0.0
	tick_layer.offset_right = BOSS_HEALTH_BAR_WIDTH
	tick_layer.offset_top = 0.0
	tick_layer.offset_bottom = BOSS_HEALTH_BAR_HEIGHT
	tick_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_back.add_child(tick_layer)
	_boss_health_panel = panel
	_boss_health_label = name_label
	_boss_health_bar_back = bar_back
	_boss_health_fill = fill
	_boss_health_tick_layer = tick_layer


func _clear_boss_health_hud() -> void:
	_active_boss = null
	_pending_agent_boss_presentation = null
	_last_boss_health = 0
	_last_boss_max_health = 0
	_boss_health_display_count = 0
	_boss_health_reveal_remaining = 0.0
	_boss_health_reveal_duration = 0.0
	_boss_alert_remaining = 0.0
	_boss_alert_duration = 0.0
	_boss_health_hide_remaining = 0.0
	if _boss_health_tick_layer != null and is_instance_valid(_boss_health_tick_layer):
		_meter_active_segment_counts.erase(_boss_health_tick_layer.get_instance_id())
		for child in _boss_health_tick_layer.get_children():
			child.free()
	if _boss_health_panel != null and is_instance_valid(_boss_health_panel):
		_boss_health_panel.visible = false
	if _boss_alert_overlay != null and is_instance_valid(_boss_alert_overlay):
		_boss_alert_overlay.visible = false


func _track_level_boss(boss: EnemyEntity) -> void:
	_ensure_boss_health_hud()
	if boss == null or not is_instance_valid(boss):
		_clear_boss_health_hud()
		return
	_active_boss = boss
	_last_boss_max_health = max(int(boss.max_health), 1)
	_last_boss_health = clampi(int(boss.health), 0, _last_boss_max_health)
	_boss_health_display_count = _last_boss_health
	_boss_health_hide_remaining = 0.0
	if boss.agent_program != null:
		if _loading_screen_is_visible() or _is_room_entry_transition_active:
			_pending_agent_boss_presentation = boss
			if boss.has_method("prepare_agent_boss_intro"):
				boss.prepare_agent_boss_intro()
			_boss_health_reveal_remaining = 0.0
			_boss_health_reveal_duration = 0.0
			_boss_alert_remaining = 0.0
			_boss_alert_duration = 0.0
		else:
			_pending_agent_boss_presentation = null
			_start_agent_boss_presentation(boss)
	else:
		_pending_agent_boss_presentation = null
		_boss_health_reveal_remaining = 0.0
		_boss_health_reveal_duration = 0.0
		_boss_alert_remaining = 0.0
		_boss_alert_duration = 0.0
	_update_boss_health_panel()


func _start_pending_agent_boss_presentation() -> void:
	var boss: EnemyEntity = _pending_agent_boss_presentation
	_pending_agent_boss_presentation = null
	if boss == null or not is_instance_valid(boss) or boss != _active_boss or boss.agent_program == null:
		return
	_start_agent_boss_presentation(boss)
	_update_boss_health_panel()


func _start_agent_boss_presentation(boss: EnemyEntity) -> void:
	var program: AgentBossProgram = boss.agent_program as AgentBossProgram
	var intro_seconds: float = BOSS_ALERT_DEFAULT_SECONDS
	var fill_seconds: float = BOSS_ALERT_HEALTH_FILL_SECONDS
	_boss_alert_flash_count = BOSS_ALERT_DEFAULT_FLASH_COUNT
	if program != null:
		intro_seconds = max(float(program.intro_seconds), 0.0)
		fill_seconds = max(float(program.intro_health_fill_seconds), 0.05)
		_boss_alert_flash_count = max(int(program.intro_alert_flash_count), 1)
	_boss_health_display_count = 0
	_boss_health_reveal_duration = max(fill_seconds, 0.05)
	_boss_health_reveal_remaining = _boss_health_reveal_duration
	_boss_alert_duration = max(intro_seconds, 0.05)
	_boss_alert_remaining = _boss_alert_duration
	if boss.has_method("start_agent_boss_intro"):
		boss.start_agent_boss_intro(intro_seconds)
	_update_boss_alert_overlay()


func _update_boss_health_feedback(delta: float) -> bool:
	var changed: bool = false
	if _boss_health_reveal_remaining > 0.0:
		var previous_display_count: int = _boss_health_display_count
		_boss_health_reveal_remaining = max(_boss_health_reveal_remaining - delta, 0.0)
		var progress: float = 1.0 - clamp(_boss_health_reveal_remaining / max(_boss_health_reveal_duration, 0.001), 0.0, 1.0)
		_boss_health_display_count = clampi(ceili(float(_last_boss_max_health) * progress), 0, _last_boss_health)
		if _boss_health_reveal_remaining <= 0.0:
			_boss_health_display_count = _last_boss_health
		changed = changed or previous_display_count != _boss_health_display_count or _boss_health_reveal_remaining > 0.0
	if _boss_alert_remaining > 0.0:
		_boss_alert_remaining = max(_boss_alert_remaining - delta, 0.0)
		_update_boss_alert_overlay()
		changed = true
	elif _boss_alert_overlay != null and is_instance_valid(_boss_alert_overlay) and _boss_alert_overlay.visible:
		_boss_alert_overlay.visible = false
		changed = true
	if _boss_health_hide_remaining > 0.0:
		_boss_health_hide_remaining = max(_boss_health_hide_remaining - delta, 0.0)
		if _boss_health_hide_remaining <= 0.0:
			_clear_boss_health_hud()
		changed = true
	return changed


func _update_boss_alert_overlay() -> void:
	if _boss_alert_overlay == null or not is_instance_valid(_boss_alert_overlay):
		return
	if _boss_alert_remaining <= 0.0 or _boss_alert_duration <= 0.0:
		_boss_alert_overlay.visible = false
		return
	var elapsed: float = _boss_alert_duration - _boss_alert_remaining
	var progress: float = clamp(elapsed / _boss_alert_duration, 0.0, 1.0)
	var pulse: float = max(sin(progress * TAU * float(max(_boss_alert_flash_count, 1))), 0.0)
	var alpha: float = pow(pulse, 1.45) * 0.28
	_boss_alert_overlay.visible = alpha > 0.01
	_boss_alert_overlay.color = Color(1.0, 0.04, 0.02, alpha)
	if _boss_alert_label != null and is_instance_valid(_boss_alert_label):
		_boss_alert_label.add_theme_color_override("font_color", Color(1.0, 0.68, 0.56, alpha * 2.5))


func _update_boss_health_panel() -> void:
	_ensure_boss_health_hud()
	if _boss_health_panel == null or _boss_health_tick_layer == null:
		return
	if _last_boss_max_health <= 0 or (_active_boss == null and _boss_health_hide_remaining <= 0.0):
		_boss_health_panel.visible = false
		return
	var visible_health: int = clampi(_boss_health_display_count if _boss_health_reveal_remaining > 0.0 else _last_boss_health, 0, _last_boss_max_health)
	var health_ratio: float = clamp(float(visible_health) / float(max(_last_boss_max_health, 1)), 0.0, 1.0)
	var fill_rect: Rect2 = _get_meter_full_rect(_boss_health_fill, _boss_health_bar_back, BOSS_HEALTH_BAR_WIDTH)
	if _boss_health_fill != null:
		_set_meter_fill_width(_boss_health_fill, fill_rect.size.x * health_ratio)
		_boss_health_fill.visible = false
	if _boss_health_label != null:
		_boss_health_label.text = _get_boss_display_name()
	_update_meter_segments(
		_boss_health_tick_layer,
		_last_boss_max_health,
		visible_health,
		fill_rect,
		_get_boss_health_meter_color(health_ratio),
		"BossHealthSegment",
		_get_boss_health_reveal_flash_config(),
		BOSS_METER_SEGMENT_EJECT_OFFSET
	)
	_boss_health_panel.visible = true


func _get_boss_health_reveal_flash_config() -> Dictionary:
	if _boss_health_reveal_remaining <= 0.0 or _boss_health_reveal_duration <= 0.0:
		return {}
	var end_index: int = clampi(_boss_health_display_count, 0, _last_boss_max_health)
	return {
		"start": max(end_index - 5, 0),
		"end": end_index,
		"remaining": _boss_health_reveal_remaining,
		"duration": _boss_health_reveal_duration
	}


func _get_boss_health_meter_color(health_ratio: float) -> Color:
	var low: Color = Color(1.0, 0.08, 0.04, 1.0)
	var high: Color = Color(1.0, 0.56, 0.16, 1.0)
	return low.lerp(high, clamp(health_ratio, 0.0, 1.0))


func _get_boss_display_name() -> String:
	if _active_boss != null and is_instance_valid(_active_boss) and _active_boss.agent_program != null:
		return String(_active_boss.agent_program.personality_verb).to_upper()
	return "BOSS"


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
	if _loading_transition_pending:
		return
	_loading_transition_pending = true
	if _selected_level_index < LEVELS.size():
		await _show_loading_before_work("LOADING", "Preparing arena", 0.05)
		_start_level(LEVELS[_selected_level_index])
	elif _selected_level_index == LEVELS.size():
		await _show_loading_before_work("LOADING FLOOR", "Generating dungeon", 0.05)
		_start_dungeon_run()
	else:
		await _show_loading_before_work("LOADING FLOOR", "Generating dungeon", 0.05)
		_start_main_loop_run()
	_loading_transition_pending = false


func _start_level(level_definition) -> void:
	_set_tree_paused(false)
	_begin_loading_screen("LOADING", "Preparing arena", 0.05)
	_is_dungeon_run = false
	_is_main_loop_run = false
	_set_room_entry_transition_active(false)
	_set_cleared_floor_map_active(false)
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
	_reset_parry_hud_state()
	_last_super_meter = 0.0
	_last_super_meter_max = player_manager.get_super_meter_max()
	_last_super_is_charging = false
	_last_super_charge_ratio = 0.0
	_reset_overdrive_hud_state()
	_ammo_refill_flash_remaining = 0.0
	_ammo_refill_perfect_flash_remaining = 0.0
	_reset_ammo_segment_refill_flash()
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
	_set_agent_debug_panel_visible(false)
	_clear_boss_health_hud()
	_set_character_hud_visible(true)
	room_manager.reset_run()
	_clear_minimap()
	if arena_view != null:
		arena_view.configure(level_definition)
	_set_loading_progress(0.35, "Configuring managers")
	player_manager.set_arena_definition(level_definition)
	projectile_manager.set_arena_definition(level_definition)
	enemy_manager.set_arena_definition(level_definition)
	spawner_manager.set_arena_definition(level_definition)
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	spawner_manager.reset_run(level_definition)
	destructible_manager.reset_run(level_definition)
	_sync_gate_blockers_into_actors()
	item_manager.reset_run()
	upgrade_manager.reset_run()
	combat_manager.reset_run()
	effects_manager.reset_run()
	input_manager.reset_run()
	player_manager.reset_run()
	_set_all_enabled(true)
	_set_loading_progress(0.9, "Starting encounter")
	if level_definition.boss_profile != null:
		_spawn_level_boss(level_definition)
	_queue_loading_floor_start_feedback()
	_status = "RUNNING"
	_on_upgrade_changed(upgrade_manager.get_modifiers(), upgrade_manager.get_active_effects())
	_update_hud()
	_finish_loading_screen()


func _start_dungeon_run() -> void:
	_set_tree_paused(false)
	_begin_loading_screen("LOADING FLOOR", "Generating dungeon", 0.05)
	_is_dungeon_run = true
	_is_main_loop_run = false
	_set_room_entry_transition_active(false)
	_set_cleared_floor_map_active(false)
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
	_reset_parry_hud_state()
	_last_super_meter = 0.0
	_last_super_meter_max = player_manager.get_super_meter_max()
	_last_super_is_charging = false
	_last_super_charge_ratio = 0.0
	_reset_overdrive_hud_state()
	_ammo_refill_flash_remaining = 0.0
	_ammo_refill_perfect_flash_remaining = 0.0
	_reset_ammo_segment_refill_flash()
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
	_set_loading_progress(0.18, "Preparing start room")
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	_clear_boss_health_hud()
	spawner_manager.clear_spawners()
	destructible_manager.clear_destructibles()
	item_manager.clear_pickups()
	item_manager.clear_floor_persistent_pickups()
	upgrade_manager.reset_run()
	combat_manager.reset_run()
	effects_manager.reset_run()
	room_manager.reset_run()
	input_manager.reset_run()
	_status = "DUNGEON"
	_load_dungeon_current_room("", true)
	_queue_loading_floor_start_feedback()
	_on_upgrade_changed(upgrade_manager.get_modifiers(), upgrade_manager.get_active_effects())
	_update_hud()


func _start_main_loop_run() -> void:
	_set_tree_paused(false)
	_begin_loading_screen("LOADING FLOOR", "Generating dungeon", 0.05)
	_is_dungeon_run = true
	_is_main_loop_run = true
	_set_room_entry_transition_active(false)
	_set_cleared_floor_map_active(false)
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
	_reset_parry_hud_state()
	_last_super_meter = 0.0
	_last_super_meter_max = player_manager.get_super_meter_max()
	_last_super_is_charging = false
	_last_super_charge_ratio = 0.0
	_reset_overdrive_hud_state()
	_ammo_refill_flash_remaining = 0.0
	_ammo_refill_perfect_flash_remaining = 0.0
	_reset_ammo_segment_refill_flash()
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
	_set_loading_progress(0.18, "Preparing start room")
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	spawner_manager.clear_spawners()
	item_manager.clear_pickups()
	item_manager.clear_floor_persistent_pickups()
	upgrade_manager.reset_run()
	combat_manager.reset_run()
	effects_manager.reset_run()
	room_manager.reset_run()
	input_manager.reset_run()
	_status = "DUNGEON"
	_load_dungeon_current_room("", true)
	_queue_loading_floor_start_feedback()
	_on_upgrade_changed(upgrade_manager.get_modifiers(), upgrade_manager.get_active_effects())
	_update_hud()


func _advance_main_loop_floor() -> void:
	if not _is_main_loop_run:
		return
	_set_tree_paused(false)
	await _show_loading_before_work("LOADING FLOOR", "Generating next floor", 0.05)
	_begin_loading_screen("LOADING FLOOR", "Generating next floor", 0.05)
	_main_loop_floor += 1
	_status = "STARTING"
	_set_room_entry_transition_active(false)
	_set_cleared_floor_map_active(false)
	_clear_floor_exit_portal()
	_rewarded_room_ids.clear()
	_reward_prompt_text = ""
	if win_panel != null:
		win_panel.visible = false
	dungeon_manager.reset_run(_main_loop_floor, _run_seed)
	_set_loading_progress(0.18, "Preparing start room")
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	spawner_manager.clear_spawners()
	item_manager.clear_pickups()
	item_manager.clear_floor_persistent_pickups()
	effects_manager.reset_run()
	room_manager.reset_run()
	input_manager.reset_run()
	_status = "DUNGEON"
	_load_dungeon_current_room("", false)
	_queue_loading_floor_start_feedback()
	_update_hud()


func _enter_level_select() -> void:
	_set_tree_paused(false)
	_status = "LEVEL_SELECT"
	_current_level = null
	_is_dungeon_run = false
	_is_main_loop_run = false
	_set_room_entry_transition_active(false)
	_set_cleared_floor_map_active(false)
	_run_seed = 0
	_paused_previous_status = ""
	_loading_completion_floor_start_pending = false
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
	_set_agent_debug_panel_visible(false)
	_clear_boss_health_hud()
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
	_set_agent_debug_panel_visible(false)
	_clear_boss_health_hud()
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	spawner_manager.clear_spawners()
	item_manager.clear_pickups()
	item_manager.clear_floor_persistent_pickups()
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


func _set_room_combat_active(value: bool, materialize_preloaded: bool = false) -> void:
	projectile_manager.set_enabled(value)
	enemy_manager.set_enabled(value)
	enemy_manager.set_entities_active(value, materialize_preloaded)
	spawner_manager.set_enabled(value)
	spawner_manager.set_spawners_active(value, materialize_preloaded)
	destructible_manager.set_enabled(value)
	combat_manager.set_enabled(value)


func _get_opposite_direction(direction: String) -> String:
	match direction:
		"north":
			return "south"
		"south":
			return "north"
		"east":
			return "west"
		"west":
			return "east"
	return ""


func _get_direction_vector(direction: String) -> Vector2:
	match direction:
		"north":
			return Vector2.UP
		"south":
			return Vector2.DOWN
		"east":
			return Vector2.RIGHT
		"west":
			return Vector2.LEFT
	return Vector2.ZERO


func _set_cleared_floor_map_active(value: bool) -> void:
	_is_cleared_floor_map_active = value
	if value and _is_room_entry_transition_active:
		_set_room_entry_transition_active(false)
	if not value:
		_camera_recenter_remaining = 0.0
	if player_manager != null and player_manager.has_method("set_context_speed_multiplier"):
		var multiplier: float = max(cleared_floor_speed_multiplier, 0.1) if value else 1.0
		player_manager.set_context_speed_multiplier(multiplier)


func _set_room_entry_transition_active(value: bool) -> void:
	_is_room_entry_transition_active = value
	if value:
		_entry_transition_auto_walk_elapsed = 0.0
	if not value:
		_entry_transition_target_room_id = ""
		_entry_transition_entry_direction = ""
		_entry_transition_floor_entry_position = Vector2.ZERO
		_entry_transition_camera_target_position = Vector2.ZERO
		_entry_transition_player_target_position = Vector2.INF
		_entry_transition_auto_walk_elapsed = 0.0
	if player_manager != null and player_manager.has_method("set_context_speed_multiplier"):
		player_manager.set_context_speed_multiplier(1.0)


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
	_reset_ammo_segment_refill_flash()


func _reset_parry_hud_state() -> void:
	_last_parry_cooldown_remaining = 0.0
	_last_parry_cooldown_duration = 0.0
	_last_parry_chain_count = 0
	_last_parry_chain_grace_remaining = 0.0
	_last_parry_chain_grace_duration = 0.0


func _reset_ammo_segment_refill_flash() -> void:
	_ammo_segment_refill_flash_remaining = 0.0
	_ammo_segment_refill_flash_duration = 0.0
	_ammo_segment_refill_start_ammo = 0
	_ammo_segment_refill_end_ammo = 0


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
	effects_manager.play_muzzle_flash(origin, direction, 16.0)
	var shot_modifiers: Dictionary = upgrade_manager.get_modifiers()
	projectile_manager.fire(origin, direction, shot_modifiers)
	upgrade_manager.consume_overdrive_shot()


func _on_player_super_shot_requested(origin: Vector2, direction: Vector2, charge_ratio: float) -> void:
	audio_manager.play_player_shot()
	effects_manager.play_muzzle_flash(origin, direction, 22.0)
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
		if _is_hostile_agent_explosive_kind(projectile_kind):
			_detonate_hostile_rocket(impact_position, impact_radius, packet, false)
			return
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
	if (reason == "wall" or reason == "bounds") and not _is_hostile_explosive_kind(projectile_kind):
		audio_manager.play_bullet_wall_hit()
	effects_manager.play_projectile_impact(impact_position, impact_direction, impact_radius, false)
	if _is_hostile_explosive_kind(projectile_kind):
		_detonate_hostile_rocket(impact_position, impact_radius, expire_info.get("damage_packet", null), false)
	elif projectile_kind == "super":
		var packet = expire_info.get("damage_packet", null)
		if packet != null and packet.explosion_radius > 0.0 and packet.explosion_damage_multiplier > 0.0:
			_on_explosion_requested(impact_position, packet)


func _is_hostile_explosive_kind(projectile_kind: String) -> bool:
	return projectile_kind == "rocket" or _is_hostile_agent_explosive_kind(projectile_kind)


func _is_hostile_agent_explosive_kind(projectile_kind: String) -> bool:
	return projectile_kind == "agent_grenade" or projectile_kind == "agent_mine"


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


func _spawn_level_boss(level_definition, spawn_flags: Dictionary = {}):
	if level_definition == null or level_definition.boss_profile == null:
		return null
	var boss_profile: EnemyProfile = _get_level_boss_profile(level_definition) as EnemyProfile
	var boss: EnemyEntity = enemy_manager.spawn_enemy(boss_profile, level_definition.boss_spawn_position, spawn_flags) as EnemyEntity
	_track_level_boss(boss)
	_update_agent_debug_panel(level_definition, boss)
	return boss


func _get_level_boss_profile(level_definition):
	if level_definition == null or level_definition.boss_profile == null:
		return null
	if not bool(level_definition.get("generate_agent_boss")):
		return level_definition.boss_profile
	return AGENT_BOSS_GENERATOR.generate_profile(level_definition.boss_profile, _get_agent_boss_generation_seed(level_definition), int(level_definition.floor_number), String(level_definition.id))


func _get_agent_boss_generation_seed(level_definition) -> int:
	if level_definition == null or not bool(level_definition.get("randomize_agent_boss_each_load")):
		return _run_seed
	_agent_boss_generation_nonce += 1
	var tick_seed: int = int(Time.get_ticks_usec() % 2147483647)
	var nonce_seed: int = _agent_boss_generation_nonce * 104729
	return max(posmod(tick_seed + nonce_seed, 2147483647), 1)


func _on_hostile_shot_requested(origin: Vector2, direction: Vector2, shot_config: Dictionary) -> void:
	audio_manager.play_enemy_shot()
	projectile_manager.fire_hostile(origin, direction, shot_config)


func _on_enemy_defeated(_enemy, score_value: int) -> void:
	_score += score_value
	player_manager.add_super_meter(player_manager.super_meter_enemy_kill_gain)
	if _enemy != null and is_instance_valid(_enemy):
		if _enemy.behavior_kind == "boss":
			if _active_boss == _enemy:
				_pending_agent_boss_presentation = null
				_last_boss_health = 0
				_boss_health_display_count = 0
				_boss_health_reveal_remaining = 0.0
				_boss_alert_remaining = 0.0
				_boss_health_hide_remaining = BOSS_HEALTH_HIDE_SECONDS
				_update_boss_health_panel()
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


func _on_enemy_health_changed(enemy, _old_value: int, new_value: int) -> void:
	if enemy == null or not is_instance_valid(enemy) or enemy != _active_boss:
		return
	_last_boss_max_health = max(int(enemy.max_health), 1)
	_last_boss_health = clampi(new_value, 0, _last_boss_max_health)
	if _boss_health_reveal_remaining <= 0.0:
		_boss_health_display_count = _last_boss_health
	_update_boss_health_panel()


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
	_sync_gate_blockers_into_actors()
	if prop != null and is_instance_valid(prop):
		_score += max(score_value, 0)
		item_manager.drop_destructible_reward(prop.global_position, drop_kind)
		effects_manager.play_projectile_impact(prop.global_position, Vector2.UP, 10.0, true)
	_update_hud()


func _on_player_health_changed(old_value: int, new_value: int) -> void:
	if new_value < old_value:
		_trigger_character_hud_damage_feedback()
		audio_manager.play_player_damage()
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


func _on_player_parry_chain_changed(current_chain: int, longest_chain: int, grace_remaining: float, grace_duration: float) -> void:
	_last_parry_chain_count = max(current_chain, 0)
	_last_parry_chain_grace_remaining = max(grace_remaining, 0.0)
	_last_parry_chain_grace_duration = max(grace_duration, 0.0)
	_run_longest_parry_chain = max(_run_longest_parry_chain, longest_chain)
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
	player_manager.resolve_parry_result(was_perfect)
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
		_target_parry_absorbs_at_character_portrait(absorbed_projectiles)
		effects_manager.play_parry_absorbs(absorbed_projectiles, origin)
	enemy_manager.apply_parry_pushback(origin, effect_radius, enemy_knockback)
	_update_hud()


func _target_parry_absorbs_at_character_portrait(absorbed_projectiles: Array) -> void:
	var targets := _get_character_portrait_world_targets()
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


func _get_character_portrait_world_targets() -> Array[Vector2]:
	var targets: Array[Vector2] = []
	var portrait_mask: Control = null
	if combat_panel != null:
		portrait_mask = combat_panel.get_node_or_null("CircularPortraitMask") as Control
	if portrait_mask != null:
		targets.append(_screen_to_world_position(portrait_mask.get_global_rect().get_center()))
		return targets
	if character_ui != null:
		targets.append(_screen_to_world_position(character_ui.global_position))
		return targets
	var viewport_size := Vector2(1280.0, 720.0)
	if is_inside_tree():
		viewport_size = get_viewport_rect().size
		if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
			viewport_size = Vector2(1280.0, 720.0)
	targets.append(_screen_to_world_position(Vector2(136.0, 82.0)))
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
			await _show_loading_before_work("LOADING FLOOR", "Generating dungeon", 0.05)
			_start_main_loop_run()
		elif _is_dungeon_run:
			await _show_loading_before_work("LOADING FLOOR", "Generating dungeon", 0.05)
			_start_dungeon_run()
		else:
			await _show_loading_before_work("LOADING FLOOR", "Building Level", 0.05)
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
		_trigger_ammo_segment_refill_flash(previous_ammo, _last_overdrive_ammo)
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
	if _maybe_finish_treasure_room_after_reward_collected():
		return
	_update_hud()


func _maybe_finish_treasure_room_after_reward_collected() -> bool:
	if not _is_dungeon_run or _status != "DUNGEON" or _is_cleared_floor_map_active or _is_room_entry_transition_active:
		return false
	if dungeon_manager.get_current_room_kind() != "treasure":
		return false
	if not _rewarded_room_ids.has(_get_current_room_reward_key()):
		return false
	if not dungeon_manager.mark_current_room_cleared_floor_available():
		return false
	return _enter_cleared_floor_map_after_current_room_clear()


func _on_reward_focus_changed(_effect, description: String) -> void:
	_reward_prompt_text = description
	_update_hud()


func _get_player_ref():
	return player_manager.player


func _on_room_door_entered(direction: String, target_room_id: String = "") -> void:
	if not _is_dungeon_run or _status != "DUNGEON":
		return
	if _is_room_entry_transition_active:
		return
	if _is_cleared_floor_map_active:
		_begin_uncleared_room_entry_transition_from_cleared_floor(direction, target_room_id)
		return
	if not target_room_id.is_empty() and dungeon_manager.is_room_cleared_floor_available(target_room_id) and dungeon_manager.is_room_revealed(target_room_id):
		_enter_cleared_floor_map_through_cleared_room(direction, target_room_id)
		return
	if dungeon_manager.enter_direction(direction):
		_set_cleared_floor_map_active(false)
		_load_dungeon_current_room(direction, false)
		audio_manager.play_room_entry()


func _enter_cleared_floor_map_through_cleared_room(entry_direction: String, target_room_id: String) -> void:
	var target_entry_position: Vector2 = dungeon_manager.get_room_entry_position(target_room_id, entry_direction)
	if not dungeon_manager.enter_room(target_room_id):
		return
	var target_position: Vector2 = player_manager.get_player_position()
	if target_entry_position != Vector2.INF:
		target_position = dungeon_manager.get_full_floor_position_for_room_position(target_room_id, target_entry_position)
	if _load_cleared_floor_map(target_position):
		audio_manager.play_room_entry()


func _enter_uncleared_room_from_cleared_floor(entry_direction: String, target_room_id: String) -> void:
	if target_room_id.is_empty():
		return
	if not dungeon_manager.enter_room(target_room_id):
		return
	_set_room_entry_transition_active(false)
	_set_cleared_floor_map_active(false)
	_load_dungeon_current_room(entry_direction, false)
	audio_manager.play_room_entry()


func _begin_uncleared_room_entry_transition_from_cleared_floor(entry_direction: String, target_room_id: String) -> void:
	if target_room_id.is_empty():
		return
	var player_floor_position: Vector2 = player_manager.get_player_position()
	var target_entry_position: Vector2 = dungeon_manager.get_room_entry_position(target_room_id, entry_direction)
	if not dungeon_manager.enter_room(target_room_id):
		return
	if target_entry_position == Vector2.INF:
		target_entry_position = dungeon_manager.get_current_spawn_position()
	var target_floor_entry_position: Vector2 = dungeon_manager.get_full_floor_position_for_room_position(target_room_id, target_entry_position)
	var target_room_bounds: Rect2 = dungeon_manager.get_full_floor_room_bounds(target_room_id)
	_entry_transition_target_room_id = target_room_id
	_entry_transition_entry_direction = entry_direction
	_entry_transition_floor_entry_position = target_floor_entry_position
	_entry_transition_camera_target_position = _get_camera_desired_position_for_bounds(target_room_bounds, target_floor_entry_position)
	input_manager.set_enabled(false)
	player_manager.set_move_vector(Vector2.ZERO)
	_set_room_entry_transition_active(true)
	if not _load_room_entry_transition(player_floor_position):
		_set_room_entry_transition_active(false)
		_set_cleared_floor_map_active(false)
		_load_dungeon_current_room(entry_direction, false, player_floor_position)
		input_manager.set_enabled(true)
		audio_manager.play_room_entry()
		return
	audio_manager.play_room_entry()


func _load_room_entry_transition(player_position: Vector2) -> bool:
	var level_definition = dungeon_manager.get_current_full_floor_level_definition(true)
	if level_definition == null:
		return false
	_is_loading_room = true
	_current_level = level_definition
	_entry_transition_player_target_position = _get_room_entry_transition_player_target_position(level_definition)
	if _entry_transition_player_target_position != Vector2.INF:
		_entry_transition_floor_entry_position = _entry_transition_player_target_position
		var target_room_bounds: Rect2 = dungeon_manager.get_full_floor_room_bounds(dungeon_manager.current_room_id)
		_entry_transition_camera_target_position = _get_camera_desired_position_for_bounds(target_room_bounds, _entry_transition_player_target_position)
	_clear_floor_exit_portal()
	if arena_view != null:
		arena_view.configure(level_definition)
	player_manager.set_arena_definition(level_definition)
	projectile_manager.set_arena_definition(level_definition)
	enemy_manager.set_arena_definition(level_definition)
	spawner_manager.set_arena_definition(level_definition)
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	_clear_boss_health_hud()
	spawner_manager.clear_spawners()
	destructible_manager.clear_destructibles()
	item_manager.set_room_context(dungeon_manager.floor_number, dungeon_manager.current_room_id)
	var room_is_cleared: bool = dungeon_manager.is_current_room_cleared()
	if room_is_cleared:
		_preload_current_treasure_reward_choices()
	if not room_is_cleared:
		spawner_manager.reset_run(level_definition)
		spawner_manager.prepare_spawners_for_preload()
	destructible_manager.reset_run(level_definition)
	room_manager.load_room(level_definition, dungeon_manager.get_full_floor_current_door_infos(), room_is_cleared)
	if not room_is_cleared:
		room_manager.set_only_door_unlocked(_get_opposite_direction(_entry_transition_entry_direction))
	_sync_gate_blockers_into_actors()
	if not room_is_cleared:
		_preload_pending_initial_spawner_enemies()
	if not room_is_cleared and level_definition.boss_profile != null:
		_spawn_level_boss(level_definition, {"inactive": true, "allow_when_disabled": true})
		if _is_main_loop_run and dungeon_manager.is_current_boss_room():
			_show_boss_exit_portal_preview(level_definition)
	_set_room_combat_active(false)
	if not room_is_cleared:
		room_manager.set_only_door_unlocked(_get_opposite_direction(_entry_transition_entry_direction))
	_set_cleared_floor_map_active(false)
	player_manager.set_player_position(player_position)
	_sync_gate_blockers_into_actors()
	_is_loading_room = false
	_update_minimap()
	_update_hud()
	return true


func _preload_pending_initial_spawner_enemies() -> void:
	var spawn_requests: Array[Dictionary] = spawner_manager.consume_initial_spawn_requests()
	for spawn_request in spawn_requests:
		var spawn_position: Vector2 = spawn_request.get("position", Vector2.ZERO)
		var profile: Resource = spawn_request.get("profile", null) as Resource
		enemy_manager.spawn_enemy(profile, spawn_position, {"inactive": true, "allow_when_disabled": true})


func _preload_current_treasure_reward_choices() -> void:
	if not _is_dungeon_run or dungeon_manager.get_current_room_kind() != "treasure":
		return
	var spawn_position: Vector2 = dungeon_manager.get_current_spawn_position()
	var reward_floor_position: Vector2 = dungeon_manager.get_full_floor_position_for_room_position(dungeon_manager.current_room_id, spawn_position)
	_maybe_spawn_current_room_reward_choices(reward_floor_position)


func _get_room_entry_transition_player_target_position(level_definition) -> Vector2:
	if level_definition == null or dungeon_manager == null:
		return Vector2.INF
	var entry_position: Vector2 = dungeon_manager.get_current_entry_position(_entry_transition_entry_direction)
	if entry_position == Vector2.INF:
		entry_position = dungeon_manager.get_current_spawn_position()
	var floor_entry_position: Vector2 = dungeon_manager.get_full_floor_position_for_room_position(dungeon_manager.current_room_id, entry_position)
	var inward_direction: Vector2 = _get_direction_vector(_entry_transition_entry_direction)
	var preferred_position: Vector2 = floor_entry_position
	if inward_direction.length_squared() > 0.001:
		preferred_position += inward_direction.normalized() * ROOM_ENTRY_INSIDE_NUDGE_DISTANCE
	return _find_safe_room_position(preferred_position, level_definition)


func _enter_cleared_floor_map_after_current_room_clear() -> bool:
	if player_manager == null or dungeon_manager == null:
		return false
	var room_id: String = dungeon_manager.current_room_id
	if room_id.is_empty():
		return false
	var player_floor_position: Vector2 = player_manager.get_player_position()
	var reward_room_position: Vector2 = dungeon_manager.get_current_spawn_position()
	var reward_floor_position: Vector2 = dungeon_manager.get_full_floor_position_for_room_position(room_id, reward_room_position)
	if not _load_cleared_floor_map(player_floor_position, true, true):
		return false
	_maybe_spawn_current_room_reward_choices(reward_floor_position)
	return true


func _load_cleared_floor_map(player_position: Vector2, preserve_pickups: bool = false, smooth_camera: bool = false) -> bool:
	var level_definition = dungeon_manager.get_current_full_floor_level_definition(false)
	if level_definition == null:
		return false
	var preserved_camera_position: Vector2 = Vector2.INF
	if smooth_camera and gameplay_camera != null:
		preserved_camera_position = gameplay_camera.global_position
	_is_loading_room = true
	_current_level = level_definition
	_clear_floor_exit_portal()
	if arena_view != null:
		arena_view.configure(level_definition)
	player_manager.set_arena_definition(level_definition)
	projectile_manager.set_arena_definition(level_definition)
	enemy_manager.set_arena_definition(level_definition)
	spawner_manager.set_arena_definition(level_definition)
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	_clear_boss_health_hud()
	spawner_manager.clear_spawners()
	destructible_manager.clear_destructibles()
	item_manager.set_room_context(dungeon_manager.floor_number, dungeon_manager.current_room_id)
	if not preserve_pickups:
		item_manager.clear_pickups()
		item_manager.rehydrate_floor_permanent_pickups()
	if not preserve_pickups:
		effects_manager.reset_run()
	room_manager.load_room(level_definition, dungeon_manager.get_full_floor_traversal_door_infos(), true)
	room_manager.set_doors_unlocked(true)
	_set_cleared_floor_map_active(true)
	player_manager.set_player_position(player_position)
	if preserved_camera_position != Vector2.INF and gameplay_camera != null:
		gameplay_camera.global_position = preserved_camera_position
		_camera_recenter_remaining = CLEARED_FLOOR_CAMERA_RECENTER_SECONDS
	_sync_gate_blockers_into_actors()
	_is_loading_room = false
	if _camera_recenter_remaining <= 0.0:
		_update_camera()
	_update_minimap()
	_update_hud()
	return true


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
	if _is_room_entry_transition_active:
		input_manager.set_enabled(false)
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
		stats_label.text = "Shot x%d  Pierce %d  Chain %d  AoE %d  Size %d%%\nParry %s" % [
			int(_latest_modifiers.get("projectile_count", 1)),
			int(_latest_modifiers.get("pierce_count", 0)),
			int(_latest_modifiers.get("chain_count", 0)),
			roundi(float(_latest_modifiers.get("explosion_radius", 0.0))),
			roundi(float(_latest_modifiers.get("projectile_size_multiplier", 1.0)) * 100.0),
			_get_parry_status_text()
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
	var flash_config := _get_ammo_segment_refill_flash_config()
	_update_meter_segments(
		overdrive_tick_layer,
		max_ammo,
		clampi(ammo, 0, max_ammo),
		fill_rect,
		fill_color,
		"OverdriveSegment",
		flash_config
	)


func _trigger_ammo_segment_refill_flash(previous_ammo: int, current_ammo: int) -> void:
	var start_ammo: int = clampi(previous_ammo, 0, _last_overdrive_max_ammo)
	var end_ammo: int = clampi(current_ammo, 0, _last_overdrive_max_ammo)
	if end_ammo <= start_ammo:
		return
	var added: int = end_ammo - start_ammo
	_ammo_segment_refill_start_ammo = start_ammo
	_ammo_segment_refill_end_ammo = end_ammo
	_ammo_segment_refill_flash_duration = clamp(float(added) * AMMO_SEGMENT_REFILL_STEP_SECONDS + 0.16, AMMO_SEGMENT_REFILL_MIN_SECONDS, AMMO_SEGMENT_REFILL_MAX_SECONDS)
	_ammo_segment_refill_flash_remaining = _ammo_segment_refill_flash_duration


func _get_ammo_segment_refill_flash_config() -> Dictionary:
	if _ammo_segment_refill_flash_remaining <= 0.0 or _ammo_segment_refill_flash_duration <= 0.0:
		return {}
	return {
		"start": _ammo_segment_refill_start_ammo,
		"end": _ammo_segment_refill_end_ammo,
		"remaining": _ammo_segment_refill_flash_remaining,
		"duration": _ammo_segment_refill_flash_duration
	}


func _get_health_meter_color(health_ratio: float) -> Color:
	var red := Color(1.0, 0.12, 0.08, 1.0)
	var orange := Color(1.0, 0.54, 0.12, 1.0)
	var green := Color(0.18, 0.92, 0.28, 1.0)
	if health_ratio <= 0.5:
		return red.lerp(orange, clamp(health_ratio / 0.5, 0.0, 1.0))
	return orange.lerp(green, clamp((health_ratio - 0.5) / 0.5, 0.0, 1.0))


func _update_meter_segments(layer: Control, segment_count: int, active_count: int, fill_rect: Rect2, fill_color: Color, segment_prefix: String, refill_flash_config: Dictionary = {}, ejection_offset: Vector2 = METER_SEGMENT_EJECT_OFFSET) -> void:
	var layer_key := layer.get_instance_id()
	var previous_active_count: int = int(_meter_active_segment_counts.get(layer_key, -1))
	if previous_active_count > active_count:
		_spawn_meter_segment_ejections(layer, segment_count, active_count, previous_active_count, fill_rect, fill_color, segment_prefix, ejection_offset)
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
		var segment_color := _get_meter_segment_flash_color(fill_color, index, refill_flash_config)
		var segment := _create_meter_segment(
			"%s%d" % [segment_prefix, index + 1],
			Vector2(fill_rect.position.x + segment_span * float(index), fill_rect.position.y),
			Vector2(segment_width, segment_height),
			segment_color
		)
		segment.set_meta("meter_active_segment", true)
		var flash_strength := _get_meter_segment_flash_strength(index, refill_flash_config)
		if flash_strength > 0.0:
			segment.set_meta("refill_flash_strength", flash_strength)
		layer.add_child(segment)


func _get_meter_segment_flash_color(base_color: Color, index: int, refill_flash_config: Dictionary) -> Color:
	var flash_strength := _get_meter_segment_flash_strength(index, refill_flash_config)
	if flash_strength <= 0.0:
		return base_color
	return base_color.lerp(Color(1.0, 1.0, 1.0, base_color.a), flash_strength)


func _get_meter_segment_flash_strength(index: int, refill_flash_config: Dictionary) -> float:
	if refill_flash_config.is_empty():
		return 0.0
	var start_index: int = int(refill_flash_config.get("start", 0))
	var end_index: int = int(refill_flash_config.get("end", 0))
	if index < start_index or index >= end_index:
		return 0.0
	var added_count: int = max(end_index - start_index, 1)
	var duration: float = max(float(refill_flash_config.get("duration", 0.0)), 0.01)
	var remaining: float = clamp(float(refill_flash_config.get("remaining", 0.0)), 0.0, duration)
	var elapsed_ratio: float = clamp((duration - remaining) / duration, 0.0, 1.0)
	var local_index: int = index - start_index
	var sweep_position: float = elapsed_ratio * float(added_count + 1)
	var distance: float = abs(sweep_position - float(local_index + 1))
	return clamp(1.0 - distance * 1.45, 0.0, 1.0)


func _spawn_meter_segment_ejections(layer: Control, segment_count: int, active_count: int, previous_active_count: int, fill_rect: Rect2, fill_color: Color, segment_prefix: String, ejection_offset: Vector2 = METER_SEGMENT_EJECT_OFFSET) -> void:
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
		tween.tween_property(segment, "position", segment.position + ejection_offset, METER_SEGMENT_EJECT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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
		_get_parry_status_text(),
		super_text,
		_last_overdrive_ammo,
		_last_overdrive_max_ammo,
		overdrive_state,
		_get_attribute_text(),
		overdrive_text
	]


func _get_parry_status_text() -> String:
	if _last_parry_cooldown_remaining > 0.0:
		return "%.1fs" % _last_parry_cooldown_remaining
	if _last_parry_chain_count > 0 and _last_parry_chain_grace_remaining > 0.0:
		return "CHAIN x%d  %.1fs" % [_last_parry_chain_count, _last_parry_chain_grace_remaining]
	return "READY"


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


func _maybe_spawn_current_room_reward_choices(preferred_position: Vector2 = Vector2.INF) -> void:
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
	if preferred_position != Vector2.INF and _current_level != null:
		reward_position = _find_safe_room_position(preferred_position, _current_level)
	elif _current_level != null:
		var spawn_position: Vector2 = dungeon_manager.get_current_spawn_position()
		if _is_dungeon_run:
			spawn_position = dungeon_manager.get_full_floor_position_for_room_position(dungeon_manager.current_room_id, spawn_position)
		reward_position = _find_safe_room_position(spawn_position, _current_level)
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
	if _is_room_entry_transition_active:
		return
	if _is_cleared_floor_map_active:
		return
	if spawner_manager.get_spawner_count() > 0 or enemy_manager.get_enemy_count() > 0:
		return
	if _is_dungeon_run:
		if _is_main_loop_run and dungeon_manager.is_current_boss_room() and _floor_exit_portal_active():
			room_manager.set_doors_unlocked(false)
			_sync_gate_blockers_into_actors()
			_update_hud()
			return
		dungeon_manager.mark_current_room_cleared()
		var current_room_kind: String = dungeon_manager.get_current_room_kind()
		if current_room_kind == "treasure":
			room_manager.set_doors_unlocked(true)
			_sync_gate_blockers_into_actors()
			_maybe_spawn_current_room_reward_choices()
			_update_hud()
			return
		if not dungeon_manager.is_current_boss_room() and _enter_cleared_floor_map_after_current_room_clear():
			_update_hud()
			return
		room_manager.set_doors_unlocked(true)
		_sync_gate_blockers_into_actors()
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


func _load_dungeon_current_room(entry_direction: String, reset_player: bool, override_player_position: Vector2 = Vector2.INF) -> void:
	var level_definition = dungeon_manager.get_current_full_floor_level_definition(true)
	if level_definition == null:
		return
	_set_room_entry_transition_active(false)
	_set_cleared_floor_map_active(false)
	_camera_recenter_remaining = 0.0
	var should_update_loading_screen := _loading_screen_is_visible()
	if should_update_loading_screen:
		_set_loading_progress(max(float(loading_screen.get("progress")), 0.2), "Preparing room geometry")
	_current_level = level_definition
	_is_loading_room = true
	_set_all_enabled(false)
	_clear_floor_exit_portal()
	if arena_view != null:
		arena_view.configure(level_definition)
	if should_update_loading_screen:
		_set_loading_progress(0.38, "Configuring arena")
	player_manager.set_arena_definition(level_definition)
	projectile_manager.set_arena_definition(level_definition)
	enemy_manager.set_arena_definition(level_definition)
	spawner_manager.set_arena_definition(level_definition)
	if should_update_loading_screen:
		_set_loading_progress(0.54, "Clearing previous room")
	projectile_manager.reset_run()
	enemy_manager.reset_run()
	_clear_boss_health_hud()
	spawner_manager.clear_spawners()
	destructible_manager.clear_destructibles()
	item_manager.clear_pickups()
	item_manager.set_room_context(dungeon_manager.floor_number, dungeon_manager.current_room_id)
	item_manager.rehydrate_current_room_permanent_pickups()
	effects_manager.reset_run()
	room_manager.reset_run()
	if reset_player or _get_player_ref() == null:
		player_manager.reset_run()
		player_manager.set_player_position(dungeon_manager.get_full_floor_position_for_room_position(dungeon_manager.current_room_id, dungeon_manager.get_current_spawn_position()))
	elif override_player_position != Vector2.INF:
		player_manager.set_player_position(_find_safe_room_position(override_player_position, level_definition))
	else:
		player_manager.set_player_position(_get_room_entry_position(level_definition, entry_direction))
	if should_update_loading_screen:
		_set_loading_progress(0.7, "Creating room contents")
	var room_is_cleared: bool = dungeon_manager.is_current_room_cleared()
	if not room_is_cleared:
		spawner_manager.reset_run(level_definition)
		if should_update_loading_screen:
			spawner_manager.prepare_spawners_for_preload()
	destructible_manager.reset_run(level_definition)
	room_manager.load_room(level_definition, dungeon_manager.get_full_floor_current_door_infos(), room_is_cleared)
	_sync_gate_blockers_into_actors()
	if room_is_cleared:
		_preload_current_treasure_reward_choices()
	if should_update_loading_screen and not room_is_cleared:
		_preload_pending_initial_spawner_enemies()
	if should_update_loading_screen:
		_set_room_combat_active(false)
	else:
		_set_all_enabled(true)
	if not room_is_cleared and level_definition.boss_profile != null:
		var boss_spawn_flags: Dictionary = {}
		if should_update_loading_screen:
			boss_spawn_flags = {"inactive": true, "allow_when_disabled": true}
		_spawn_level_boss(level_definition, boss_spawn_flags)
		if _is_main_loop_run and dungeon_manager.is_current_boss_room():
			_show_boss_exit_portal_preview(level_definition)
	room_manager.set_doors_unlocked(room_is_cleared)
	_sync_gate_blockers_into_actors()
	_is_loading_room = false
	if should_update_loading_screen:
		_set_loading_progress(0.95, "Entering room")
	_update_camera()
	_update_minimap()
	_check_level_clear()
	_update_hud()
	if should_update_loading_screen:
		_finish_loading_screen()


func _sync_gate_blockers_into_actors() -> void:
	var gate_blockers: Array[Rect2] = []
	if room_manager != null and room_manager.has_method("get_gate_blocker_rects"):
		gate_blockers = room_manager.get_gate_blocker_rects()
	if destructible_manager != null and destructible_manager.has_method("get_blocker_rects"):
		gate_blockers.append_array(destructible_manager.get_blocker_rects())
	player_manager.set_dynamic_wall_rects(gate_blockers)
	enemy_manager.set_dynamic_wall_rects(gate_blockers)
	spawner_manager.set_dynamic_wall_rects(gate_blockers)


func _get_room_entry_position(level_definition, entry_direction: String) -> Vector2:
	var derived_entry: Vector2 = dungeon_manager.get_current_entry_position(entry_direction)
	if derived_entry != Vector2.INF:
		var floor_entry: Vector2 = dungeon_manager.get_full_floor_position_for_room_position(dungeon_manager.current_room_id, derived_entry)
		return _find_safe_room_position(floor_entry, level_definition)
	var bounds: Rect2 = dungeon_manager.get_full_floor_room_bounds(dungeon_manager.current_room_id) if _is_dungeon_run else level_definition.arena_bounds
	if bounds.size == Vector2.ZERO:
		bounds = level_definition.arena_bounds
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
	if _is_room_entry_transition_active and _status == "DUNGEON":
		return "FLOOR %d ENTRY" % _main_loop_floor if _is_main_loop_run else "DUNGEON ENTRY"
	if _is_cleared_floor_map_active and _status == "DUNGEON":
		return "FLOOR %d MAP" % _main_loop_floor if _is_main_loop_run else "DUNGEON MAP"
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
			var minimap_current_room_id: String = dungeon_manager.current_room_id
			var player_location: Variant = null
			var player_location_info := _get_current_minimap_player_location()
			if bool(player_location_info.get("ok", false)):
				var location_room_id: String = String(player_location_info.get("room_id", ""))
				if (_is_cleared_floor_map_active or _is_room_entry_transition_active) and not location_room_id.is_empty():
					minimap_current_room_id = location_room_id
				if player_location_info.has("position"):
					var continuous_position: Vector2 = player_location_info.get("position", Vector2.ZERO)
					player_location = continuous_position
					_last_minimap_player_position = continuous_position
					_has_last_minimap_player_position = true
				else:
					_has_last_minimap_player_position = false
				var player_cell: Vector2i = player_location_info.get("cell", Vector2i.ZERO)
				if player_location == null:
					player_location = player_cell
				_last_minimap_player_cell = player_cell
				_has_last_minimap_player_cell = true
			else:
				_has_last_minimap_player_cell = false
				_has_last_minimap_player_position = false
			_last_minimap_room_id = minimap_current_room_id
			dungeon_minimap.call("set_map", dungeon_manager.get_minimap_rooms(), minimap_current_room_id, player_location)
	else:
		_clear_minimap()


func _update_minimap_player_cell_if_changed() -> void:
	if dungeon_minimap == null:
		return
	var player_location_info := _get_current_minimap_player_location()
	var has_location: bool = bool(player_location_info.get("ok", false))
	if has_location != _has_last_minimap_player_cell:
		_update_minimap()
		return
	if not has_location:
		return
	var location_room_id: String = dungeon_manager.current_room_id
	var player_room_id: String = String(player_location_info.get("room_id", ""))
	if (_is_cleared_floor_map_active or _is_room_entry_transition_active) and not player_room_id.is_empty():
		location_room_id = player_room_id
	if location_room_id != _last_minimap_room_id:
		_update_minimap()
		return
	var cell: Vector2i = player_location_info.get("cell", Vector2i.ZERO)
	if cell != _last_minimap_player_cell:
		_update_minimap()
		return
	if player_location_info.has("position"):
		var continuous_position: Vector2 = player_location_info.get("position", Vector2.ZERO)
		if not _has_last_minimap_player_position or continuous_position.distance_squared_to(_last_minimap_player_position) > 0.0004:
			_update_minimap()


func _get_current_minimap_player_location() -> Dictionary:
	if not _is_dungeon_run or dungeon_manager == null or player_manager == null:
		return {"ok": false, "cell": Vector2i.ZERO}
	var player = _get_player_ref()
	if player == null or not is_instance_valid(player):
		return {"ok": false, "cell": Vector2i.ZERO}
	return dungeon_manager.get_full_floor_minimap_position_for_position(player_manager.get_player_position())


func _clear_minimap() -> void:
	_has_last_minimap_player_cell = false
	_has_last_minimap_player_position = false
	_last_minimap_room_id = ""
	_minimap_player_cell_check_remaining = 0.0
	if dungeon_minimap != null and dungeon_minimap.has_method("clear_map"):
		dungeon_minimap.call("clear_map")


func _begin_loading_screen(title: String, message: String, progress: float = 0.0) -> void:
	if player_manager != null and player_manager.has_method("set_spawn_feedback_deferred"):
		player_manager.call("set_spawn_feedback_deferred", true)
	if loading_screen != null and loading_screen.has_method("begin_loading"):
		loading_screen.call("begin_loading", title, message, progress)


func _show_loading_before_work(title: String, message: String, progress: float = 0.0) -> void:
	_begin_loading_screen(title, message, progress)
	await get_tree().process_frame
	await get_tree().process_frame


func _loading_screen_is_visible() -> bool:
	return loading_screen != null and loading_screen.visible


func _set_loading_progress(progress: float, message: String = "") -> void:
	if loading_screen != null and loading_screen.has_method("set_progress"):
		loading_screen.call("set_progress", progress, message)


func _finish_loading_screen(message: String = "READY") -> void:
	if loading_screen != null and loading_screen.has_method("finish_loading"):
		loading_screen.call("finish_loading", message, true)
	if _status == "RUNNING" or _status == "DUNGEON":
		_set_all_enabled(false)
		enemy_manager.set_entities_active(false)


func _on_loading_continue_requested() -> void:
	if _status == "RUNNING" or _status == "DUNGEON":
		_set_all_enabled(true)
		enemy_manager.set_entities_active(true, true)
		spawner_manager.set_spawners_active(true, true)
		_start_pending_agent_boss_presentation()
		_play_loading_completion_feedback()
		_update_hud()


func _queue_loading_floor_start_feedback() -> void:
	if _loading_screen_is_visible():
		_loading_completion_floor_start_pending = true
	else:
		audio_manager.play_floor_start()


func _play_loading_completion_feedback() -> void:
	if player_manager != null and player_manager.has_method("play_queued_spawn_feedback"):
		player_manager.call("play_queued_spawn_feedback")
	if _loading_completion_floor_start_pending:
		_loading_completion_floor_start_pending = false
		audio_manager.play_floor_start()


func _update_room_entry_transition(_delta: float) -> void:
	if not _is_room_entry_transition_active or _entry_transition_target_room_id.is_empty():
		return
	var player_arrived: bool = _update_room_entry_auto_walk(_delta)
	if not player_arrived:
		return
	var player_position: Vector2 = player_manager.get_player_position()
	var player_room_info: Dictionary = dungeon_manager.get_full_floor_room_position_for_position(player_position)
	var player_is_in_target_room: bool = bool(player_room_info.get("ok", false)) and String(player_room_info.get("room_id", "")) == _entry_transition_target_room_id
	if not player_is_in_target_room and player_position.distance_squared_to(_entry_transition_floor_entry_position) > ROOM_ENTRY_COMPLETE_DISTANCE * ROOM_ENTRY_COMPLETE_DISTANCE:
		return
	if gameplay_camera != null:
		if gameplay_camera.global_position.distance_squared_to(_entry_transition_camera_target_position) > ROOM_ENTRY_CAMERA_DISTANCE * ROOM_ENTRY_CAMERA_DISTANCE:
			return
	_finish_room_entry_transition()


func _update_room_entry_auto_walk(delta: float) -> bool:
	if _entry_transition_player_target_position == Vector2.INF:
		return true
	_entry_transition_auto_walk_elapsed += delta
	var player_position: Vector2 = player_manager.get_player_position()
	var to_target: Vector2 = _entry_transition_player_target_position - player_position
	if to_target.length_squared() <= ROOM_ENTRY_AUTO_WALK_ARRIVE_DISTANCE * ROOM_ENTRY_AUTO_WALK_ARRIVE_DISTANCE:
		player_manager.set_move_vector(Vector2.ZERO)
		return true
	if _entry_transition_auto_walk_elapsed >= ROOM_ENTRY_AUTO_WALK_TIMEOUT:
		player_manager.set_player_position(_entry_transition_player_target_position)
		player_manager.set_move_vector(Vector2.ZERO)
		return true
	player_manager.set_move_vector(to_target.normalized())
	return false


func _finish_room_entry_transition() -> void:
	if _entry_transition_target_room_id.is_empty():
		return
	var room_is_cleared: bool = dungeon_manager.is_current_room_cleared()
	var final_player_position: Vector2 = _entry_transition_player_target_position
	if final_player_position != Vector2.INF:
		player_manager.set_player_position(final_player_position)
	player_manager.set_move_vector(Vector2.ZERO)
	_set_room_entry_transition_active(false)
	_set_cleared_floor_map_active(false)
	_set_room_combat_active(true, true)
	room_manager.set_doors_unlocked(room_is_cleared)
	_sync_gate_blockers_into_actors()
	input_manager.set_enabled(true)
	_start_pending_agent_boss_presentation()
	_update_camera()
	_update_minimap()
	_check_level_clear()
	_update_hud()


func _update_camera(delta: float = 0.0) -> void:
	if gameplay_camera == null or _current_level == null:
		return
	var desired: Vector2 = _entry_transition_camera_target_position if _is_room_entry_transition_active else _get_camera_desired_position(_current_level, player_manager.get_player_position())
	if _is_room_entry_transition_active and delta > 0.0:
		var transition_response: float = 1.0 - exp(-ROOM_ENTRY_CAMERA_RESPONSE * delta)
		gameplay_camera.global_position = gameplay_camera.global_position.lerp(desired, clamp(transition_response, 0.0, 1.0))
		return
	if _camera_recenter_remaining > 0.0 and delta > 0.0:
		_camera_recenter_remaining = max(_camera_recenter_remaining - delta, 0.0)
		var response: float = 1.0 - exp(-CLEARED_FLOOR_CAMERA_RECENTER_RESPONSE * delta)
		gameplay_camera.global_position = gameplay_camera.global_position.lerp(desired, clamp(response, 0.0, 1.0))
		if gameplay_camera.global_position.distance_squared_to(desired) <= 1.0:
			gameplay_camera.global_position = desired
			_camera_recenter_remaining = 0.0
		elif _camera_recenter_remaining <= 0.0:
			_camera_recenter_remaining = 0.001
		return
	gameplay_camera.global_position = desired


func _get_camera_desired_position(level_definition, focus_position: Vector2) -> Vector2:
	if level_definition == null:
		return focus_position
	var bounds: Rect2 = _get_current_camera_bounds(level_definition)
	return _get_camera_desired_position_for_bounds(bounds, focus_position)


func _get_camera_desired_position_for_bounds(bounds: Rect2, focus_position: Vector2) -> Vector2:
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return focus_position
	var desired: Vector2 = focus_position
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
	return desired


func _get_current_camera_bounds(level_definition) -> Rect2:
	if level_definition == null:
		return Rect2()
	if _is_dungeon_run and bool(level_definition.get_meta("full_floor", false)):
		if _is_cleared_floor_map_active:
			var visible_bounds: Rect2 = dungeon_manager.get_full_floor_visible_bounds(dungeon_manager.current_room_id)
			if visible_bounds.size != Vector2.ZERO:
				return visible_bounds
		var active_bounds: Rect2 = dungeon_manager.get_full_floor_room_bounds(dungeon_manager.current_room_id)
		if active_bounds.size != Vector2.ZERO:
			return active_bounds
	return level_definition.arena_bounds


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
	var bounds: Rect2 = dungeon_manager.get_full_floor_room_bounds(dungeon_manager.current_room_id) if _is_dungeon_run else _current_level.arena_bounds
	if bounds.size == Vector2.ZERO:
		bounds = _current_level.arena_bounds
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
	_run_longest_parry_chain = 0


func _get_tally_text() -> String:
	if not _is_main_loop_run:
		var seed_line := "Seed: %d\n" % _run_seed if _is_dungeon_run and _run_seed > 0 else ""
		return "%sEnemies: %d\nSpawners: %d\nPickups: %d\nLongest parry chain: %d" % [
			seed_line,
			_run_enemy_kills,
			_run_spawner_kills,
			_run_pickups_collected,
			_run_longest_parry_chain
		]
	return "Seed: %d\nFloors cleared: %d\nEnemies: %d  Bosses: %d\nSpawners: %d\nPickups: %d\nAmmo: %d  Permanent: %d  Heals: %d\nLongest parry chain: %d" % [
		_run_seed,
		_run_floors_cleared,
		_run_enemy_kills,
		_run_boss_kills,
		_run_spawner_kills,
		_run_pickups_collected,
		_run_ammo_upgrades,
		_run_permanent_upgrades,
		_run_heals,
		_run_longest_parry_chain
	]
