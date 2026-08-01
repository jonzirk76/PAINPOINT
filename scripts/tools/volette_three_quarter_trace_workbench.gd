@tool
extends Node2D

## Shows the bald concept cell used to align the body assembly.
@export var show_structure_reference: bool = true:
	set(value):
		show_structure_reference = value
		_refresh_workbench()

## Opacity of the concept image beneath the editable polygons.
@export_range(0.0, 1.0, 0.01) var structure_reference_opacity := 0.52:
	set(value):
		structure_reference_opacity = value
		_refresh_workbench()

## Shows the matching haired concept cell beside the editing area.
@export var show_hair_comparison: bool = true:
	set(value):
		show_hair_comparison = value
		_refresh_workbench()

## Shows or hides the entire editable polygon assembly without affecting the reference.
@export var show_editable_assembly: bool = true:
	set(value):
		show_editable_assembly = value
		_refresh_workbench()


func _ready() -> void:
	_refresh_workbench()


func _refresh_workbench() -> void:
	for path in ["References/ForwardStructureReference", "References/RearStructureReference"]:
		var structure_reference := get_node_or_null(path) as CanvasItem
		if structure_reference != null:
			structure_reference.visible = show_structure_reference
			structure_reference.modulate = Color(1.0, 1.0, 1.0, structure_reference_opacity)
	for path in ["References/ForwardHairComparison", "References/RearHairComparison"]:
		var hair_comparison := get_node_or_null(path) as CanvasItem
		if hair_comparison != null:
			hair_comparison.visible = show_hair_comparison
	for path in ["ThreeQuarterDownRight", "ThreeQuarterUpRight"]:
		var assembly := get_node_or_null(path) as CanvasItem
		if assembly != null:
			assembly.visible = show_editable_assembly
