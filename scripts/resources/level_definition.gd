extends Resource
class_name LevelDefinition

enum ArenaShape {
	RECTANGLE,
	DIAMOND,
	HEXAGON,
	CROSS
}

@export var id: String = "level"
@export var display_name: String = "Level"
@export var difficulty_label: String = "Easy"
@export var arena_shape: ArenaShape = ArenaShape.RECTANGLE
@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var spawner_positions: Array[Vector2] = []
@export var max_active_enemies: int = 12
@export var spawner_health: int = 16
@export var spawner_radius: float = 32.0
@export var spawn_interval: float = 3.2


func get_summary() -> String:
	return "%s - %s spawners" % [difficulty_label, spawner_positions.size()]
