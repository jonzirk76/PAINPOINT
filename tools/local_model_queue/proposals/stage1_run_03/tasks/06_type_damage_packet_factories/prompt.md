Edit only scripts/managers/projectile_manager.gd.

Make exactly these replacements:
- Replace `func _create_damage_packet(modifiers: Dictionary, origin: Vector2, direction: Vector2):` with `func _create_damage_packet(modifiers: Dictionary, origin: Vector2, direction: Vector2) -> DamagePacket:`
- Replace `func _create_super_damage_packet(origin: Vector2, direction: Vector2, charge_ratio: float):` with `func _create_super_damage_packet(origin: Vector2, direction: Vector2, charge_ratio: float) -> DamagePacket:`
- Replace `func _create_hostile_damage_packet(shot_config: Dictionary, origin: Vector2, direction: Vector2):` with `func _create_hostile_damage_packet(shot_config: Dictionary, origin: Vector2, direction: Vector2) -> DamagePacket:`

Do not change any other code, formatting, comments, ordering, or whitespace.
Do not run commands, tests, or create new files.
Make no changes if any exact original line is absent.
