@tool
extends Node2D
class_name WarehouseTileWorkbench

## Canonical world-space size consumed by RoomGeometryBuilder.
@export var tile_size: float = 40.0

## Editor-only enlargement applied to every tile block.
@export_range(1.0, 6.0, 0.25) var preview_scale: float = 3.0:
	set(value):
		preview_scale = value
		_apply_preview_scale()

## Shows the uploaded warehouse tile mockup beside the editable blocks.
@export var show_reference: bool = true:
	set(value):
		show_reference = value
		var reference := get_node_or_null("ReferenceMockup") as CanvasItem
		if reference != null:
			reference.visible = value

@export_group("Warehouse Palette")
## Deepest shadow beneath raised structures.
@export var shadow_color := Color("#15171b"):
	set(value):
		shadow_color = value
		_apply_palette()

## Primary concrete and neutral floor tone.
@export var floor_color := Color("#34373a"):
	set(value):
		floor_color = value
		_apply_palette()

## Secondary worn concrete tone.
@export var floor_worn_color := Color("#44443f"):
	set(value):
		floor_worn_color = value
		_apply_palette()

## Main vertical wall face.
@export var wall_face_color := Color("#55565a"):
	set(value):
		wall_face_color = value
		_apply_palette()

## Brighter top-facing wall surface.
@export var wall_top_color := Color("#85827a"):
	set(value):
		wall_top_color = value
		_apply_palette()

## Dark metal used for grates, doors, and edge trim.
@export var metal_dark_color := Color("#252a2d"):
	set(value):
		metal_dark_color = value
		_apply_palette()

## Mid-tone metal panels and rails.
@export var metal_color := Color("#596064"):
	set(value):
		metal_color = value
		_apply_palette()

## Bright exposed metal edge.
@export var metal_light_color := Color("#a5a7a3"):
	set(value):
		metal_light_color = value
		_apply_palette()

## Industrial yellow used for paths and hazard markings.
@export var warning_color := Color("#c29b21"):
	set(value):
		warning_color = value
		_apply_palette()

## Dark companion color for hazard stripes.
@export var warning_dark_color := Color("#242528"):
	set(value):
		warning_dark_color = value
		_apply_palette()

## Oil, grime, and deep floor stains.
@export var grime_color := Color("#1d211d"):
	set(value):
		grime_color = value
		_apply_palette()

## Moss, chemical residue, and painted-floor accents.
@export var accent_color := Color("#536341"):
	set(value):
		accent_color = value
		_apply_palette()

## Wet-floor and coolant highlights.
@export var liquid_color := Color("#304b63"):
	set(value):
		liquid_color = value
		_apply_palette()

## Toggle this in the inspector after changing several colors at once.
@export var refresh_palette: bool = false:
	set(value):
		refresh_palette = false
		_apply_palette()


func _ready() -> void:
	_apply_preview_scale()
	_apply_palette()
	var reference := get_node_or_null("ReferenceMockup") as CanvasItem
	if reference != null:
		reference.visible = show_reference


func _apply_preview_scale() -> void:
	var tiles := get_node_or_null("Tiles")
	if tiles == null:
		return
	for child in tiles.get_children():
		if child is Node2D:
			(child as Node2D).scale = Vector2.ONE * preview_scale


func _apply_palette() -> void:
	if not is_inside_tree():
		return
	for node in find_children("*", "Polygon2D", true, false):
		var polygon := node as Polygon2D
		var role := String(polygon.get_meta("palette_role", ""))
		if role.is_empty():
			continue
		polygon.color = _color_for_role(role)


func _color_for_role(role: String) -> Color:
	match role:
		"shadow":
			return shadow_color
		"floor":
			return floor_color
		"floor_worn":
			return floor_worn_color
		"wall_face":
			return wall_face_color
		"wall_top":
			return wall_top_color
		"metal_dark":
			return metal_dark_color
		"metal":
			return metal_color
		"metal_light":
			return metal_light_color
		"warning":
			return warning_color
		"warning_dark":
			return warning_dark_color
		"grime":
			return grime_color
		"accent":
			return accent_color
		"liquid":
			return liquid_color
		_:
			return Color.WHITE
