extends SceneTree

const ENTITY_SCRIPT_PATHS := [
	"res://scripts/entities/player_entity.gd",
	"res://scripts/entities/enemy_entity.gd",
	"res://scripts/entities/projectile_entity.gd",
	"res://scripts/entities/enemy_spawner_entity.gd",
	"res://scripts/entities/pickup_entity.gd",
	"res://scripts/entities/chain_lightning_effect.gd",
	"res://scripts/entities/explosion_effect.gd"
]

const FORBIDDEN_ENTITY_SNIPPETS := [
	"/root",
	"Managers",
	"GameOrchestrator",
	"get_tree().root"
]

const SCRIPT_PATHS := [
	"res://scripts/arena/arena_view.gd",
	"res://scripts/entities/player_entity.gd",
	"res://scripts/entities/enemy_entity.gd",
	"res://scripts/entities/projectile_entity.gd",
	"res://scripts/entities/enemy_spawner_entity.gd",
	"res://scripts/entities/pickup_entity.gd",
	"res://scripts/entities/chain_lightning_effect.gd",
	"res://scripts/entities/explosion_effect.gd",
	"res://scripts/managers/input_manager.gd",
	"res://scripts/managers/player_manager.gd",
	"res://scripts/managers/projectile_manager.gd",
	"res://scripts/managers/enemy_manager.gd",
	"res://scripts/managers/spawner_manager.gd",
	"res://scripts/managers/item_manager.gd",
	"res://scripts/managers/upgrade_manager.gd",
	"res://scripts/managers/combat_manager.gd",
	"res://scripts/managers/effects_manager.gd",
	"res://scripts/orchestrators/game_orchestrator.gd",
	"res://scripts/resources/damage_packet.gd",
	"res://scripts/resources/enemy_profile.gd",
	"res://scripts/resources/upgrade_effect.gd",
	"res://scripts/resources/permanent_upgrade.gd"
]


func _init() -> void:
	var failures: Array[String] = []
	_test_architecture_rules(failures)
	_test_presentation_settings(failures)
	_test_scripts_instantiate(failures)
	_test_scene_loads(failures)
	_test_aim_change_logic(failures)
	_test_restart_signal(failures)
	_test_upgrade_modifiers_and_expiry(failures)
	_test_projectile_knockback_packet(failures)

	if failures.is_empty():
		print("Smoke tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_architecture_rules(failures: Array[String]) -> void:
	for path in ENTITY_SCRIPT_PATHS:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			failures.append("Missing entity script: %s" % path)
			continue
		var source := file.get_as_text()
		for snippet in FORBIDDEN_ENTITY_SNIPPETS:
			if source.contains(snippet):
				failures.append("%s contains forbidden upward dependency snippet: %s" % [path, snippet])


func _test_presentation_settings(failures: Array[String]) -> void:
	if int(ProjectSettings.get_setting("display/window/size/viewport_width")) != 1280:
		failures.append("Logical viewport width should stay 1280 for scaled presentation.")
	if int(ProjectSettings.get_setting("display/window/size/viewport_height")) != 720:
		failures.append("Logical viewport height should stay 720 for scaled presentation.")
	if int(ProjectSettings.get_setting("display/window/size/window_width_override")) < 2560:
		failures.append("Window width override should be large enough for 4K displays.")
	if int(ProjectSettings.get_setting("display/window/size/window_height_override")) < 1440:
		failures.append("Window height override should be large enough for 4K displays.")
	if String(ProjectSettings.get_setting("display/window/stretch/mode")) != "canvas_items":
		failures.append("Stretch mode should scale canvas items for high-resolution displays.")


func _test_scripts_instantiate(failures: Array[String]) -> void:
	for path in SCRIPT_PATHS:
		var script = load(path)
		if script == null:
			failures.append("Script failed to load: %s" % path)
			continue
		if script.has_method("can_instantiate") and not script.can_instantiate():
			failures.append("Script failed to compile for instantiation: %s" % path)
			continue
		var instance = script.new()
		if instance == null:
			failures.append("Script failed to instantiate: %s" % path)
			continue
		if instance is Node:
			instance.free()


func _test_scene_loads(failures: Array[String]) -> void:
	var scene_paths := [
		"res://scenes/main.tscn",
		"res://scenes/entities/player_entity.tscn",
		"res://scenes/entities/enemy_entity.tscn",
		"res://scenes/entities/projectile_entity.tscn",
		"res://scenes/entities/enemy_spawner_entity.tscn",
		"res://scenes/entities/pickup_entity.tscn",
		"res://scenes/entities/chain_lightning_effect.tscn",
		"res://scenes/entities/explosion_effect.tscn"
	]
	for path in scene_paths:
		var scene := load(path)
		if scene == null:
			failures.append("Scene failed to load: %s" % path)
			continue
		var instance = scene.instantiate()
		if instance == null:
			failures.append("Scene failed to instantiate: %s" % path)
		elif instance is Node:
			if path.ends_with(".tscn") and instance.get_script() == null and not path.ends_with("main.tscn"):
				failures.append("Scene root script missing after instantiate: %s" % path)
			if path.ends_with("main.tscn") and instance.get_script() == null:
				failures.append("Main scene root script missing after instantiate.")
			if path.ends_with("main.tscn"):
				var required_nodes := [
					"UI/CombatPanel/HealthBarBack/HealthBarFill",
					"UI/CombatPanel/InvulnerabilityBarBack/InvulnerabilityBarFill",
					"UI/CombatPanel/AttributeLabel",
					"UI/CombatPanel/StatsLabel",
					"UI/GameOverPanel/GameOverPromptLabel",
					"World/EffectLayer",
					"Managers/EffectsManager"
				]
				for node_path in required_nodes:
					if not instance.has_node(node_path):
						failures.append("Main scene missing HUD node: %s" % node_path)
			instance.free()


func _test_aim_change_logic(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/input_manager.gd").new()
	manager.stick_deadzone = 0.25
	manager.aim_change_threshold = 0.18
	if not manager.should_fire_for_aim_change(Vector2.RIGHT):
		failures.append("Initial aim state should request fire.")
	if manager.should_fire_for_aim_change(Vector2(1.0, 0.02)):
		failures.append("Tiny aim drift should not request another fire.")
	if not manager.should_fire_for_aim_change(Vector2.UP):
		failures.append("Large aim state change should request fire.")
	manager.free()


func _test_restart_signal(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/input_manager.gd").new()
	var restart_count := [0]
	manager.restart_requested.connect(func() -> void:
		restart_count[0] += 1
	)
	var event := InputEventKey.new()
	event.keycode = KEY_R
	event.physical_keycode = KEY_R
	event.pressed = true
	manager._unhandled_input(event)
	var controller_event := InputEventJoypadButton.new()
	controller_event.button_index = JOY_BUTTON_START
	controller_event.pressed = true
	manager._unhandled_input(controller_event)
	if restart_count[0] != 2:
		failures.append("InputManager did not emit restart_requested for R key.")
	manager.free()


func _test_upgrade_modifiers_and_expiry(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/upgrade_manager.gd").new()
	var spread = load("res://resources/upgrades/spread_shot.tres")
	var pierce = load("res://resources/upgrades/piercing_shot.tres")
	var fire = load("res://resources/upgrades/fire_burst.tres")
	var water = load("res://resources/upgrades/water_swell.tres")
	var fire_rate = load("res://resources/permanent_upgrades/faster_reflexes.tres")
	var move_speed = load("res://resources/permanent_upgrades/runner_legs.tres")
	var damage = load("res://resources/permanent_upgrades/heavy_tears.tres")
	var size = load("res://resources/permanent_upgrades/fat_tears.tres")
	manager.activate_upgrade(spread)
	manager.activate_upgrade(pierce)
	manager.activate_upgrade(fire)
	manager.activate_upgrade(water)
	manager.activate_permanent_upgrade(fire_rate)
	manager.activate_permanent_upgrade(move_speed)
	manager.activate_permanent_upgrade(damage)
	manager.activate_permanent_upgrade(size)
	manager.consume_shot()
	var active_effects: Array = manager.get_active_effects()
	for state in active_effects:
		if int(state["max_ammo"]) > 0 and int(state["ammo"]) >= int(state["max_ammo"]):
			failures.append("Upgrade ammo did not decrement after consume_shot.")
	var modifiers: Dictionary = manager.get_modifiers()
	if int(modifiers["projectile_count"]) < 5:
		failures.append("Spread shot did not increase projectile count.")
	if int(modifiers["pierce_count"]) < 3:
		failures.append("Piercing shot did not increase pierce count.")
	if float(modifiers["fire_cooldown_multiplier"]) >= 1.0:
		failures.append("Permanent fire-rate upgrade did not reduce cooldown multiplier.")
	if float(modifiers["move_speed_multiplier"]) <= 1.0:
		failures.append("Permanent move-speed upgrade did not increase movement multiplier.")
	if float(modifiers["damage_multiplier"]) <= 1.0:
		failures.append("Permanent damage upgrade did not increase damage multiplier.")
	if float(modifiers["projectile_size_multiplier"]) <= 1.0:
		failures.append("Permanent projectile-size upgrade did not increase projectile size.")
	if float(modifiers["explosion_radius"]) <= 0.0:
		failures.append("Fire Burst did not add explosion radius.")
	if float(modifiers["projectile_growth_per_second"]) <= 0.0:
		failures.append("Water Swell did not add projectile growth.")
	if int(modifiers["pierce_count"]) < 99:
		failures.append("Water Swell did not allow projectiles to pass through enemies.")
	if manager.get_permanent_stats().size() != 4:
		failures.append("Permanent upgrade stats were not tracked.")
	manager.set_enabled(true)
	manager._process(99.0)
	if manager.get_active_effects().is_empty():
		failures.append("Ammo upgrades should not expire by timer.")
	manager.free()


func _test_projectile_knockback_packet(failures: Array[String]) -> void:
	var manager = load("res://scripts/managers/projectile_manager.gd").new()
	var packet = manager._create_damage_packet({}, Vector2(10.0, 4.0), Vector2.RIGHT)
	if packet.knockback <= 0.0:
		failures.append("Projectile damage packet did not include knockback.")
	if packet.knockback_direction.distance_to(Vector2.RIGHT) > 0.001:
		failures.append("Projectile damage packet did not preserve knockback direction.")
	manager.free()
