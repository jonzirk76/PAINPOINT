extends Resource
class_name EncounterEntry

## Enemy profile that can be selected by this encounter table entry.
@export var enemy_profile: Resource = null
## Lowest floor where this entry can be selected.
@export var min_floor: int = 1
## Highest floor where this entry can be selected; zero means no upper limit.
@export var max_floor: int = 0
## Relative weighted chance when this entry is affordable and floor-eligible.
@export var weight: int = 1
## Encounter budget spent for each spawned enemy from this entry.
@export var budget_cost: int = 1
## Minimum number of this enemy spawned when the entry is selected.
@export var min_count: int = 1
## Maximum number of this enemy spawned when the entry is selected.
@export var max_count: int = 1
## Optional room kinds where this entry can appear; empty allows any combat room kind.
@export var room_kinds: PackedStringArray = []


func is_available(floor_number: int, room_kind: String, remaining_budget: int) -> bool:
	if enemy_profile == null:
		return false
	if floor_number < max(min_floor, 1):
		return false
	if max_floor > 0 and floor_number > max_floor:
		return false
	if max(budget_cost, 1) > remaining_budget:
		return false
	if not room_kinds.is_empty() and not room_kinds.has(room_kind):
		return false
	return max(weight, 0) > 0
