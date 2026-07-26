@tool
extends Control
class_name CharacterViewer

const DEFAULT_VISUAL_SET := preload("res://resources/characters/velora_hair_visual_set.tres")
const DEFAULT_RECIPE := preload("res://resources/characters/velora_hair_recipe.tres")
const GENERATION_RUNNER := preload("res://scripts/tools/character_hair_generation_runner.gd")
const BACK_HAIR_ROLES := ["hair_back_mass", "hair_ponytail"]
const FRONT_HAIR_ROLES := ["hair_side_lock_left", "hair_side_lock_right", "hair_bangs", "hair_top_loop"]
const VIEW_FRONT := "front"
const VIEW_SIDE := "side"
const VIEW_BACK := "back"

## Generated visual set to preview in the editor.
@export var visual_set: Resource = DEFAULT_VISUAL_SET:
	set(value):
		visual_set = value
		_texture_cache.clear()
		queue_redraw()

## Hair recipe edited by the viewer's generation controls.
@export var recipe: Resource = DEFAULT_RECIPE:
	set(value):
		recipe = value
		_pull_controls_from_recipe()
		queue_redraw()

## Directional view to preview.
@export_enum("front", "side", "back") var view_direction: String = VIEW_FRONT:
	set(value):
		view_direction = value
		_texture_cache.clear()
		queue_redraw()

## Toggle this on in the inspector to regenerate hair SVGs from the controls below.
@export var generate_hair_now: bool = false:
	set(value):
		generate_hair_now = false
		if value:
			_generate_from_viewer()

## Scales procedural hair mass without changing gameplay collision.
@export_range(0.75, 1.35, 0.01) var hair_volume: float = 1.0:
	set(value):
		hair_volume = value
		_apply_control_to_recipe("hair_volume", value)

## Controls overall generated hair length.
@export_range(0.65, 1.55, 0.01) var hair_length: float = 1.0:
	set(value):
		hair_length = value
		_apply_control_to_recipe("hair_length", value)

## Controls wider, curlier, less uniform locks and fringes.
@export_range(0.0, 1.0, 0.01) var hair_wildness: float = 0.35:
	set(value):
		hair_wildness = value
		_apply_control_to_recipe("hair_wildness", value)

## Controls ponytail length relative to the overall hair length.
@export_range(0.65, 1.45, 0.01) var ponytail_length: float = 1.0:
	set(value):
		ponytail_length = value
		_apply_control_to_recipe("ponytail_length", value)

## Controls bang silhouette and fringe orientation.
@export_enum("curtain", "swept", "straight") var bang_shape: String = "curtain":
	set(value):
		bang_shape = value
		_apply_control_to_recipe("bang_shape", value)

## Controls sideburn silhouette.
@export_enum("soft", "long", "sharp") var sideburn_type: String = "long":
	set(value):
		sideburn_type = value
		_apply_control_to_recipe("sideburn_type", value)

## Controls ponytail mass silhouette.
@export_enum("high_sweep", "low_tail", "wide_tail") var ponytail_shape: String = "high_sweep":
	set(value):
		ponytail_shape = value
		_apply_control_to_recipe("ponytail_shape", value)

## Number of primitive back-hair locks to generate.
@export_range(2, 8, 1) var back_lock_count: int = 4:
	set(value):
		back_lock_count = value
		_apply_control_to_recipe("back_lock_count", value)

## Number of primitive bang fringes to generate.
@export_range(2, 8, 1) var bang_fringe_count: int = 4:
	set(value):
		bang_fringe_count = value
		_apply_control_to_recipe("bang_fringe_count", value)

## Number of primitive ponytail locks to generate.
@export_range(1, 7, 1) var ponytail_lock_count: int = 3:
	set(value):
		ponytail_lock_count = value
		_apply_control_to_recipe("ponytail_lock_count", value)

## Controls transparent eye cutout silhouette.
@export_enum("sharp", "soft", "round") var eye_shape: String = "sharp":
	set(value):
		eye_shape = value
		_apply_control_to_recipe("eye_shape", value)

## Scales generated eye cutout width.
@export_range(0.65, 1.35, 0.01) var eye_width: float = 1.0:
	set(value):
		eye_width = value
		_apply_control_to_recipe("eye_width", value)

## Rounds the generated eye cutout corners and lower lid.
@export_range(0.0, 1.0, 0.01) var eye_roundness: float = 0.2:
	set(value):
		eye_roundness = value
		_apply_control_to_recipe("eye_roundness", value)

## Rotates the generated eye cutouts in degrees.
@export_range(-18.0, 18.0, 0.1) var eye_angle_degrees: float = 0.0:
	set(value):
		eye_angle_degrees = value
		_apply_control_to_recipe("eye_angle_degrees", value)

## Extends or shortens the generated chin.
@export_range(0.75, 1.3, 0.01) var chin_length: float = 1.0:
	set(value):
		chin_length = value
		_apply_control_to_recipe("chin_length", value)

## Rounds the generated chin point.
@export_range(0.0, 1.0, 0.01) var chin_roundness: float = 0.65:
	set(value):
		chin_roundness = value
		_apply_control_to_recipe("chin_roundness", value)

## Scales the 128x128 character preview canvas.
@export_range(1.0, 5.0, 0.1) var preview_scale: float = 3.0:
	set(value):
		preview_scale = value
		queue_redraw()

## Plays module offsets for hair roles tagged with bounce animation metadata.
@export var animate_hair_bounce: bool = true:
	set(value):
		animate_hair_bounce = value
		queue_redraw()

## Draws a light 128x128 preview boundary behind the character.
@export var show_preview_bounds: bool = true:
	set(value):
		show_preview_bounds = value
		queue_redraw()

## Draws translucent module boxes so SVG alignment problems are easy to spot.
@export var show_module_bounds: bool = false:
	set(value):
		show_module_bounds = value
		queue_redraw()

var _preview_time: float = 0.0
var _texture_cache: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(520.0, 520.0)
	_pull_controls_from_recipe()
	if Engine.is_editor_hint():
		set_process(true)


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if animate_hair_bounce:
		_preview_time += delta
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	if center == Vector2.ZERO:
		center = Vector2(260.0, 260.0)
	_draw_backdrop(center)
	_draw_hair_modules(BACK_HAIR_ROLES, center)
	_draw_body_proxy(center)
	_draw_hair_modules(FRONT_HAIR_ROLES, center)


func _draw_backdrop(center: Vector2) -> void:
	var canvas_size := Vector2(128.0, 128.0) * preview_scale
	var rect := Rect2(center - canvas_size * 0.5, canvas_size)
	draw_rect(rect.grow(16.0), Color(0.035, 0.045, 0.065, 1.0), true)
	if show_preview_bounds:
		draw_rect(rect, Color(0.35, 0.55, 0.82, 0.28), false, 2.0)
		draw_line(center + Vector2(-canvas_size.x * 0.5, 0.0), center + Vector2(canvas_size.x * 0.5, 0.0), Color(0.35, 0.55, 0.82, 0.18), 1.0)
		draw_line(center + Vector2(0.0, -canvas_size.y * 0.5), center + Vector2(0.0, canvas_size.y * 0.5), Color(0.35, 0.55, 0.82, 0.18), 1.0)


func _draw_hair_modules(roles: Array, center: Vector2) -> void:
	for role in roles:
		var texture := _get_hair_texture(String(role))
		if texture == null:
			continue
		var transform := _get_hair_bounce_transform(String(role))
		draw_set_transform(center + transform.offset * preview_scale, transform.rotation, Vector2(preview_scale, preview_scale))
		draw_texture_rect(texture, Rect2(Vector2(-64.0, -64.0), Vector2(128.0, 128.0)), false, Color.WHITE)
		if show_module_bounds:
			draw_rect(Rect2(Vector2(-64.0, -64.0), Vector2(128.0, 128.0)), Color(0.2, 0.9, 1.0, 0.22), false, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_body_proxy(center: Vector2) -> void:
	var side_offset := 7.0 if view_direction == VIEW_SIDE else 0.0
	var back_view := view_direction == VIEW_BACK
	_draw_oval(center, Vector2(49.0 + side_offset, 101.0), Vector2(10.0, 17.0), Color(0.025, 0.055, 0.09, 1.0))
	_draw_oval(center, Vector2(77.0 + side_offset, 101.0), Vector2(10.0, 17.0), Color(0.025, 0.055, 0.09, 1.0))
	_draw_oval(center, Vector2(49.0 + side_offset, 96.0), Vector2(5.5, 9.0), Color(0.07, 0.34, 0.84, 0.86))
	_draw_oval(center, Vector2(77.0 + side_offset, 96.0), Vector2(5.5, 9.0), Color(0.08, 0.4, 0.92, 0.86))
	draw_colored_polygon(PackedVector2Array([
		_preview_point(center, Vector2(38.0 + side_offset, 68.0)),
		_preview_point(center, Vector2(90.0 + side_offset, 68.0)),
		_preview_point(center, Vector2(84.0 + side_offset, 96.0)),
		_preview_point(center, Vector2(44.0 + side_offset, 96.0))
	]), Color(0.06, 0.23, 0.58, 1.0))
	draw_polyline(PackedVector2Array([
		_preview_point(center, Vector2(40.0 + side_offset, 76.0)),
		_preview_point(center, Vector2(88.0 + side_offset, 76.0))
	]), Color(0.03, 0.06, 0.1, 1.0), 4.0 * preview_scale)
	draw_colored_polygon(PackedVector2Array([
		_preview_point(center, Vector2(43.0 + side_offset, 62.0)),
		_preview_point(center, Vector2(85.0 + side_offset, 62.0)),
		_preview_point(center, Vector2(80.0 + side_offset, 72.0)),
		_preview_point(center, Vector2(48.0 + side_offset, 72.0))
	]), Color(0.035, 0.05, 0.08, 1.0))
	if not back_view:
		_draw_eye_underlay(center, side_offset)
	_draw_head_module(center)
	draw_line(_preview_point(center, Vector2(58.0 + side_offset, 84.0)), _preview_point(center, Vector2(70.0 + side_offset, 84.0)), Color(0.13, 0.82, 1.0, 0.95), 3.0 * preview_scale)


func _draw_eye_underlay(center: Vector2, side_offset: float) -> void:
	var eye_spacing := 15.0 if view_direction == VIEW_FRONT else 8.0
	_draw_oval(center, Vector2(64.0 + side_offset - eye_spacing, 82.0), Vector2(11.0 * eye_width, 6.0), Color(0.11, 0.06, 0.16, 1.0))
	_draw_oval(center, Vector2(64.0 + side_offset + eye_spacing, 82.0), Vector2(11.0 * eye_width, 6.0), Color(0.11, 0.06, 0.16, 1.0))


func _draw_head_module(center: Vector2) -> void:
	var texture := _get_head_texture()
	if texture == null:
		var side_offset := 7.0 if view_direction == VIEW_SIDE else 0.0
		_draw_oval(center, Vector2(64.0 + side_offset, 47.0), Vector2(17.0, 17.0), Color(0.94, 0.71, 0.56, 1.0))
		return
	draw_set_transform(center, 0.0, Vector2(preview_scale, preview_scale))
	draw_texture_rect(texture, Rect2(Vector2(-64.0, -64.0), Vector2(128.0, 128.0)), false, Color.WHITE)
	if show_module_bounds:
		draw_rect(Rect2(Vector2(-64.0, -64.0), Vector2(128.0, 128.0)), Color(1.0, 0.65, 0.22, 0.22), false, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_oval(preview_center: Vector2, point: Vector2, radius: Vector2, color: Color) -> void:
	draw_set_transform(_preview_point(preview_center, point), 0.0, radius * preview_scale)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _preview_point(center: Vector2, point: Vector2) -> Vector2:
	return center + (point - Vector2(64.0, 64.0)) * preview_scale


func _get_hair_texture(role: String) -> Texture2D:
	if _texture_cache.has(role):
		return _texture_cache[role]
	if visual_set == null or not visual_set.has_method("get_hair_module_path"):
		return null
	var path := String(visual_set.get_hair_module_path(role, view_direction))
	if path.is_empty():
		return null
	var texture := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	_texture_cache[role] = texture if texture is Texture2D else null
	return _texture_cache[role]


func _get_head_texture() -> Texture2D:
	var key := "head/%s" % view_direction
	if _texture_cache.has(key):
		return _texture_cache[key]
	if visual_set == null or not visual_set.has_method("get_head_module_path"):
		return null
	var path := String(visual_set.get_head_module_path("head_base", view_direction))
	if path.is_empty():
		return null
	var texture := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	_texture_cache[key] = texture if texture is Texture2D else null
	return _texture_cache[key]


func _get_hair_bounce_transform(role: String) -> Dictionary:
	var tag := ""
	if visual_set != null and visual_set.has_method("get_hair_animation_tag"):
		tag = String(visual_set.get_hair_animation_tag(role, view_direction))
	if not animate_hair_bounce or tag.is_empty():
		return {"offset": Vector2.ZERO, "rotation": 0.0}
	var wave := sin(_preview_time * 5.4)
	if tag == "hair_bounce_heavy":
		return {"offset": Vector2(0.0, wave * 1.2), "rotation": wave * 0.012}
	return {"offset": Vector2(0.0, wave * 0.8), "rotation": wave * 0.018}


func _pull_controls_from_recipe() -> void:
	if recipe == null:
		return
	hair_volume = _recipe_float("hair_volume", hair_volume)
	hair_length = _recipe_float("hair_length", hair_length)
	hair_wildness = _recipe_float("hair_wildness", hair_wildness)
	ponytail_length = _recipe_float("ponytail_length", ponytail_length)
	bang_shape = _recipe_string("bang_shape", bang_shape)
	sideburn_type = _recipe_string("sideburn_type", sideburn_type)
	ponytail_shape = _recipe_string("ponytail_shape", ponytail_shape)
	back_lock_count = _recipe_int("back_lock_count", back_lock_count)
	bang_fringe_count = _recipe_int("bang_fringe_count", bang_fringe_count)
	ponytail_lock_count = _recipe_int("ponytail_lock_count", ponytail_lock_count)
	eye_shape = _recipe_string("eye_shape", eye_shape)
	eye_width = _recipe_float("eye_width", eye_width)
	eye_roundness = _recipe_float("eye_roundness", eye_roundness)
	eye_angle_degrees = _recipe_float("eye_angle_degrees", eye_angle_degrees)
	chin_length = _recipe_float("chin_length", chin_length)
	chin_roundness = _recipe_float("chin_roundness", chin_roundness)


func _apply_control_to_recipe(property_name: String, value) -> void:
	if recipe == null:
		queue_redraw()
		return
	recipe.set(property_name, value)
	queue_redraw()


func _generate_from_viewer() -> void:
	if not Engine.is_editor_hint() or recipe == null:
		return
	var runner := GENERATION_RUNNER.new()
	visual_set = runner.generate_hair_modules(recipe, recipe.resource_path)
	_reimport_generated_svgs(runner.generated_svg_paths)
	_texture_cache.clear()
	call_deferred("queue_redraw")


func _reimport_generated_svgs(paths: PackedStringArray) -> void:
	if paths.is_empty():
		return
	var editor_interface = Engine.get_singleton("EditorInterface")
	if editor_interface == null or not editor_interface.has_method("get_resource_filesystem"):
		return
	var filesystem = editor_interface.get_resource_filesystem()
	if filesystem == null:
		return
	if filesystem.has_method("reimport_files"):
		filesystem.reimport_files(paths)
	elif filesystem.has_method("scan"):
		filesystem.scan()


func _recipe_float(property_name: String, fallback: float) -> float:
	var value = recipe.get(property_name)
	return float(value) if value != null else fallback


func _recipe_int(property_name: String, fallback: int) -> int:
	var value = recipe.get(property_name)
	return int(value) if value != null else fallback


func _recipe_string(property_name: String, fallback: String) -> String:
	var value = recipe.get(property_name)
	return String(value) if value != null else fallback
