extends Resource
class_name LevelDefinition

enum ArenaShape {
	RECTANGLE,
	DIAMOND,
	HEXAGON,
	CROSS,
	CIRCLE
}

@export var id: String = "level"
@export var display_name: String = "Level"
@export var difficulty_label: String = "Easy"
@export var arena_shape: ArenaShape = ArenaShape.RECTANGLE
@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var spawner_positions: Array[Vector2] = []
@export var spawner_placements: Array[Resource] = []
@export var wall_rects: Array[Rect2] = []
@export var max_active_enemies: int = 12
@export var spawner_health: int = 16
@export var spawner_radius: float = 32.0
@export var spawn_interval: float = 3.2
@export var boss_profile: Resource = null
@export var boss_spawn_position: Vector2 = Vector2.ZERO


func get_summary() -> String:
	return "%s - %s spawners" % [difficulty_label, get_spawner_count()]


func get_spawner_count() -> int:
	if not spawner_placements.is_empty():
		return spawner_placements.size()
	return spawner_positions.size()
