extends Node
class_name CombatManager

signal damage_resolved(target: Node, damage_packet)
signal player_damage_resolved(amount: int)
signal chain_requested(origin_target: Node, damage_packet)
signal explosion_requested(origin: Vector2, damage_packet)

var enabled: bool = false


func initialize(_context: Dictionary) -> void:
	pass


func reset_run() -> void:
	pass


func set_enabled(value: bool) -> void:
	enabled = value


func resolve_projectile_hit(_projectile, target: Node, packet) -> void:
	if not enabled or target == null or packet == null:
		return
	damage_resolved.emit(target, packet)
	if packet.explosion_radius > 0.0 and packet.explosion_damage_multiplier > 0.0:
		explosion_requested.emit(target.global_position, packet)
	if packet.chain_count > 0 and packet.chain_radius > 0.0:
		chain_requested.emit(target, packet)


func resolve_chain_hit(target: Node, packet) -> void:
	if not enabled or target == null or packet == null:
		return
	damage_resolved.emit(target, packet)
	if packet.chain_count > 0 and packet.chain_radius > 0.0:
		chain_requested.emit(target, packet)


func resolve_contact_damage(_enemy, _player, amount: int) -> void:
	if not enabled or amount <= 0:
		return
	player_damage_resolved.emit(amount)
