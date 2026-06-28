extends Resource
class_name DamagePacket

@export var damage: int = 1
@export var pierce_count: int = 0
@export var chain_count: int = 0
@export var chain_radius: float = 0.0
@export var explosion_radius: float = 0.0
@export var explosion_damage_multiplier: float = 0.0
@export var knockback: float = 85.0
@export var projectile_size_multiplier: float = 1.0
@export var projectile_growth_per_second: float = 0.0
@export var projectile_max_size_multiplier: float = 1.0

var source: Node = null
var source_position: Vector2 = Vector2.ZERO
var knockback_direction: Vector2 = Vector2.ZERO
var projectile_kind: String = "normal"
var hit_targets: Array[Node] = []


func copy_for_chain():
	var packet = preload("res://scripts/resources/damage_packet.gd").new()
	packet.damage = damage
	packet.pierce_count = 0
	packet.chain_count = max(chain_count - 1, 0)
	packet.chain_radius = chain_radius
	packet.explosion_radius = 0.0
	packet.explosion_damage_multiplier = 0.0
	packet.knockback = knockback
	packet.projectile_size_multiplier = projectile_size_multiplier
	packet.projectile_growth_per_second = projectile_growth_per_second
	packet.projectile_max_size_multiplier = projectile_max_size_multiplier
	packet.source = source
	packet.source_position = source_position
	packet.knockback_direction = knockback_direction
	packet.projectile_kind = projectile_kind
	packet.hit_targets = hit_targets.duplicate()
	return packet


func copy_for_explosion():
	var packet = preload("res://scripts/resources/damage_packet.gd").new()
	packet.damage = max(roundi(float(damage) * explosion_damage_multiplier), 1)
	packet.pierce_count = 0
	packet.chain_count = 0
	packet.chain_radius = 0.0
	packet.explosion_radius = 0.0
	packet.explosion_damage_multiplier = 0.0
	packet.knockback = knockback * 1.4
	packet.source = source
	packet.source_position = source_position
	packet.projectile_kind = "fire"
	packet.hit_targets = hit_targets.duplicate()
	return packet


func copy_with_damage_bonus(bonus: int):
	var packet = preload("res://scripts/resources/damage_packet.gd").new()
	packet.damage = max(damage + bonus, 0)
	packet.pierce_count = pierce_count
	packet.chain_count = chain_count
	packet.chain_radius = chain_radius
	packet.explosion_radius = explosion_radius
	packet.explosion_damage_multiplier = explosion_damage_multiplier
	packet.knockback = knockback
	packet.projectile_size_multiplier = projectile_size_multiplier
	packet.projectile_growth_per_second = projectile_growth_per_second
	packet.projectile_max_size_multiplier = projectile_max_size_multiplier
	packet.source = source
	packet.source_position = source_position
	packet.knockback_direction = knockback_direction
	packet.projectile_kind = projectile_kind
	packet.hit_targets = hit_targets.duplicate()
	return packet
