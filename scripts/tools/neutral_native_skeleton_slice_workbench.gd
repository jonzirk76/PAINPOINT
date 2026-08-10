extends Node2D

const DIRECTIONS := [
	NativeHumanoidSkeletonRuntime.Direction.SOUTH,
	NativeHumanoidSkeletonRuntime.Direction.SOUTH_WEST,
	NativeHumanoidSkeletonRuntime.Direction.WEST,
]
const DIRECTION_LABELS := ["SOUTH", "SOUTH WEST", "WEST"]

## [Description] Automatically cycles the three compiled directions to expose turn-time behavior.
@export var auto_cycle: bool = true
## [Description] Seconds each direction remains visible during automatic cycling.
@export_range(0.25, 4.0, 0.05) var cycle_interval: float = 1.0

@onready var rig: NativeHumanoidSkeletonRuntime = $NativeHumanoidSkeleton
@onready var status_label: Label = $UI/Status

var _direction_index: int = 0
var _elapsed: float = 0.0


func _ready() -> void:
	_refresh_pose()


func _process(delta: float) -> void:
	if not auto_cycle:
		return
	_elapsed += delta
	if _elapsed < cycle_interval:
		return
	_elapsed = 0.0
	_direction_index = wrapi(_direction_index + 1, 0, DIRECTIONS.size())
	_refresh_pose()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			_direction_index = 0
		KEY_2:
			_direction_index = 1
		KEY_3:
			_direction_index = 2
		KEY_SPACE:
			rig.set_walking(not rig.is_walking())
		KEY_C:
			auto_cycle = not auto_cycle
		KEY_ESCAPE:
			get_tree().quit()
		_:
			return
	_elapsed = 0.0
	_refresh_pose()


func _refresh_pose() -> void:
	if not rig.is_node_ready():
		return
	rig.set_direction(DIRECTIONS[_direction_index])
	var stats := rig.get_compiled_stats()
	status_label.text = "%s  •  %s  •  1 SKELETON / %d BONES / 1 PLAYER / 1 TREE  •  %d SKIN POLYGONS  •  AUTO %s" % [
		DIRECTION_LABELS[_direction_index],
		"WALK" if rig.is_walking() else "IDLE",
		int(stats.get("semantic_bones", 0)),
		int(stats.get("polygons", 0)),
		"ON" if auto_cycle else "OFF",
	]
