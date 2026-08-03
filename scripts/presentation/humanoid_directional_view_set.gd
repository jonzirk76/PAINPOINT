class_name HumanoidDirectionalViewSet
extends Resource

enum Direction {
	SOUTH,
	SOUTH_WEST,
	WEST,
	NORTH_WEST,
	NORTH,
	NORTH_EAST,
	EAST,
	SOUTH_EAST,
}

## [Description] Editable authored scene for the south-facing view.
@export var south: PackedScene
## [Description] Editable authored scene for the south-west-facing view.
@export var south_west: PackedScene
## [Description] Editable authored scene for the west-facing profile view.
@export var west: PackedScene
## [Description] Editable authored scene for the north-east-facing view.
@export var north_east: PackedScene
## [Description] Editable authored scene for the north-facing view.
@export var north: PackedScene


func get_selection(direction: int) -> Dictionary:
	match wrapi(direction, 0, 8):
		Direction.SOUTH_WEST:
			return {"scene": south_west, "mirror": false}
		Direction.WEST:
			return {"scene": west, "mirror": false}
		Direction.NORTH_WEST:
			return {"scene": north_east, "mirror": true}
		Direction.NORTH:
			return {"scene": north, "mirror": false}
		Direction.NORTH_EAST:
			return {"scene": north_east, "mirror": false}
		Direction.EAST:
			return {"scene": west, "mirror": true}
		Direction.SOUTH_EAST:
			return {"scene": south_west, "mirror": true}
		_:
			return {"scene": south, "mirror": false}


func is_complete() -> bool:
	return south != null and south_west != null and west != null and north_east != null and north != null
