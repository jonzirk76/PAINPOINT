@tool
extends Resource
class_name CharacterModuleSpec

## Stable module role such as hair_bangs, hair_ponytail, or hair_side_lock_left.
@export var role: String = "":
	set(value):
		role = value
		emit_changed()

## Draw order for generated module previews and future layered runtime visuals.
@export var layer_order: int = 0:
	set(value):
		layer_order = value
		emit_changed()

## Named anchor used by the generator when placing this module.
@export var anchor_name: String = "":
	set(value):
		anchor_name = value
		emit_changed()

## Local offset from the named anchor in 128x128 SVG space.
@export var offset: Vector2 = Vector2.ZERO:
	set(value):
		offset = value
		emit_changed()

## Local scale multiplier for this generated module.
@export var scale: Vector2 = Vector2.ONE:
	set(value):
		scale = value
		emit_changed()

## Allows mirrored variants to reuse the same procedural template.
@export var mirror_x: bool = false:
	set(value):
		mirror_x = value
		emit_changed()

## Optional runtime animation tag such as hair_bounce_light or hair_bounce_heavy.
@export var animation_tag: String = "":
	set(value):
		animation_tag = value
		emit_changed()
