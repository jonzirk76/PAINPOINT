@tool
extends Resource
class_name CharacterAnchorMap

## Anchor for the head center in 128x128 SVG space.
@export var head_center: Vector2 = Vector2(64.0, 47.0):
	set(value):
		head_center = value
		emit_changed()

## Anchor where the ponytail emerges from the crown.
@export var ponytail_root: Vector2 = Vector2(72.0, 24.0):
	set(value):
		ponytail_root = value
		emit_changed()

## Anchor for bangs and forehead locks.
@export var bangs_root: Vector2 = Vector2(64.0, 36.0):
	set(value):
		bangs_root = value
		emit_changed()

## Anchor for left side hair mass.
@export var side_lock_left_root: Vector2 = Vector2(41.0, 50.0):
	set(value):
		side_lock_left_root = value
		emit_changed()

## Anchor for right side hair mass.
@export var side_lock_right_root: Vector2 = Vector2(87.0, 50.0):
	set(value):
		side_lock_right_root = value
		emit_changed()

## Anchor for the small top loop.
@export var top_loop_root: Vector2 = Vector2(64.0, 18.0):
	set(value):
		top_loop_root = value
		emit_changed()


func get_anchor(name: String) -> Vector2:
	match name:
		"head_center":
			return head_center
		"ponytail_root":
			return ponytail_root
		"bangs_root":
			return bangs_root
		"side_lock_left_root":
			return side_lock_left_root
		"side_lock_right_root":
			return side_lock_right_root
		"top_loop_root":
			return top_loop_root
	return Vector2.ZERO
