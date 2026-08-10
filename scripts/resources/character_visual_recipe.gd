@tool
extends Resource
class_name CharacterVisualRecipe

const PALETTE_SCRIPT := preload("res://scripts/resources/character_palette.gd")
const ANCHOR_MAP_SCRIPT := preload("res://scripts/resources/character_anchor_map.gd")
const MODULE_SPEC_SCRIPT := preload("res://scripts/resources/character_module_spec.gd")

const MODULE_HAIR_BACK_MASS := "hair_back_mass"
const MODULE_HAIR_SIDE_LOCK_LEFT := "hair_side_lock_left"
const MODULE_HAIR_SIDE_LOCK_RIGHT := "hair_side_lock_right"
const MODULE_HAIR_BANGS := "hair_bangs"
const MODULE_HAIR_PONYTAIL := "hair_ponytail"
const MODULE_HAIR_TOP_LOOP := "hair_top_loop"
const MODULE_HEAD_BASE := "head_base"
const VIEW_FRONT := "front"
const VIEW_SIDE := "side"
const VIEW_BACK := "back"

@export_enum("curtain", "swept", "straight") var bang_shape: String = "curtain":
	set(value):
		bang_shape = value
		emit_changed()

@export_enum("soft", "long", "sharp") var sideburn_type: String = "long":
	set(value):
		sideburn_type = value
		emit_changed()

@export_enum("high_sweep", "low_tail", "wide_tail") var ponytail_shape: String = "high_sweep":
	set(value):
		ponytail_shape = value
		emit_changed()

@export_enum("sharp", "soft", "round") var eye_shape: String = "sharp":
	set(value):
		eye_shape = value
		emit_changed()

## Stable id used in generated file names and output folders.
@export var character_id: String = "velora":
	set(value):
		character_id = value
		emit_changed()

## Seed used by procedural templates so generated variants are repeatable.
@export var seed: int = 1001:
	set(value):
		seed = value
		emit_changed()

## Output folder for generated SVG hair modules.
@export_dir var output_svg_dir: String = "res://art/generated/characters/velora/base":
	set(value):
		output_svg_dir = value
		emit_changed()

## Output visual-set resource path generated for runtime consumers.
@export_file("*.tres") var output_visual_set_path: String = "res://resources/characters/velora_hair_visual_set.tres":
	set(value):
		output_visual_set_path = value
		emit_changed()

## Enables subtle runtime offsets for modules tagged as bounce hair.
@export var hair_bounce_enabled: bool = true:
	set(value):
		hair_bounce_enabled = value
		emit_changed()

## Scales procedural hair mass without changing gameplay collision.
@export_range(0.75, 1.35, 0.01) var hair_volume: float = 1.0:
	set(value):
		hair_volume = value
		emit_changed()

## Controls ponytail length for generated top-down hair silhouettes.
@export_range(0.65, 1.45, 0.01) var ponytail_length: float = 1.0:
	set(value):
		ponytail_length = value
		emit_changed()

## Controls overall hair length across back hair, sideburns, and ponytail locks.
@export_range(0.65, 1.55, 0.01) var hair_length: float = 1.0:
	set(value):
		hair_length = value
		emit_changed()

## Controls wider, curlier, less uniform primitive locks and fringes.
@export_range(0.0, 1.0, 0.01) var hair_wildness: float = 0.35:
	set(value):
		hair_wildness = value
		emit_changed()

## Number of primitive locks drawn through the back hair component.
@export_range(2, 8, 1) var back_lock_count: int = 4:
	set(value):
		back_lock_count = value
		emit_changed()

## Number of primitive fringes drawn through the bangs component.
@export_range(2, 8, 1) var bang_fringe_count: int = 4:
	set(value):
		bang_fringe_count = value
		emit_changed()

## Number of primitive locks drawn through the ponytail component.
@export_range(1, 7, 1) var ponytail_lock_count: int = 3:
	set(value):
		ponytail_lock_count = value
		emit_changed()

## Scales the transparent eye cutout width in the generated head.
@export_range(0.65, 1.35, 0.01) var eye_width: float = 1.0:
	set(value):
		eye_width = value
		emit_changed()

## Rounds the transparent eye cutout corners and lower lid.
@export_range(0.0, 1.0, 0.01) var eye_roundness: float = 0.2:
	set(value):
		eye_roundness = value
		emit_changed()

## Rotates the generated eye cutouts in degrees.
@export_range(-18.0, 18.0, 0.1) var eye_angle_degrees: float = 0.0:
	set(value):
		eye_angle_degrees = value
		emit_changed()

## Extends or shortens the generated chin while preserving a rounded point.
@export_range(0.75, 1.3, 0.01) var chin_length: float = 1.0:
	set(value):
		chin_length = value
		emit_changed()

## Controls how subtle and rounded the generated chin point is.
@export_range(0.0, 1.0, 0.01) var chin_roundness: float = 0.65:
	set(value):
		chin_roundness = value
		emit_changed()

## Color palette used by all generated hair modules.
@export var palette: Resource:
	set(value):
		palette = value
		emit_changed()

## Anchor map used by procedural SVG module templates.
@export var anchors: Resource:
	set(value):
		anchors = value
		emit_changed()

## Module definitions emitted by the generator.
@export var hair_modules: Array[Resource] = []:
	set(value):
		hair_modules = value
		emit_changed()


func _init() -> void:
	if palette == null:
		palette = PALETTE_SCRIPT.new()
	if anchors == null:
		anchors = ANCHOR_MAP_SCRIPT.new()
	if hair_modules.is_empty():
		hair_modules = create_default_hair_modules()


func create_default_hair_modules() -> Array[Resource]:
	var modules: Array[Resource] = []
	modules.append(_module(MODULE_HAIR_BACK_MASS, 10, "head_center", Vector2.ZERO, Vector2.ONE, false, "hair_bounce_heavy"))
	modules.append(_module(MODULE_HAIR_PONYTAIL, 20, "ponytail_root", Vector2.ZERO, Vector2.ONE, false, "hair_bounce_heavy"))
	modules.append(_module(MODULE_HAIR_SIDE_LOCK_LEFT, 30, "side_lock_left_root", Vector2.ZERO, Vector2.ONE, false, "hair_bounce_light"))
	modules.append(_module(MODULE_HAIR_SIDE_LOCK_RIGHT, 31, "side_lock_right_root", Vector2.ZERO, Vector2.ONE, true, "hair_bounce_light"))
	modules.append(_module(MODULE_HAIR_BANGS, 40, "bangs_root", Vector2.ZERO, Vector2.ONE, false, "hair_bounce_light"))
	modules.append(_module(MODULE_HAIR_TOP_LOOP, 50, "top_loop_root", Vector2.ZERO, Vector2.ONE, false, "hair_bounce_light"))
	return modules


func required_hair_roles() -> PackedStringArray:
	return PackedStringArray([
		MODULE_HAIR_BACK_MASS,
		MODULE_HAIR_SIDE_LOCK_LEFT,
		MODULE_HAIR_SIDE_LOCK_RIGHT,
		MODULE_HAIR_BANGS,
		MODULE_HAIR_PONYTAIL,
		MODULE_HAIR_TOP_LOOP
	])


func get_generated_views() -> PackedStringArray:
	return PackedStringArray([VIEW_FRONT, VIEW_SIDE, VIEW_BACK])


func get_generated_head_roles() -> PackedStringArray:
	return PackedStringArray([MODULE_HEAD_BASE])


func _module(role: String, layer_order: int, anchor_name: String, offset: Vector2, scale: Vector2, mirror_x: bool, animation_tag: String) -> Resource:
	var module: Resource = MODULE_SPEC_SCRIPT.new()
	module.role = role
	module.layer_order = layer_order
	module.anchor_name = anchor_name
	module.offset = offset
	module.scale = scale
	module.mirror_x = mirror_x
	module.animation_tag = animation_tag
	return module
