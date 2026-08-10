@tool
extends Resource
class_name CharacterVisualSet

## Stable id for this visual set.
@export var character_id: String = "":
	set(value):
		character_id = value
		emit_changed()

## Paths to generated hair SVG modules keyed by role.
@export var hair_module_paths: Dictionary = {}:
	set(value):
		hair_module_paths = value
		emit_changed()

## Paths to generated head SVG modules keyed by view and role.
@export var head_module_paths: Dictionary = {}:
	set(value):
		head_module_paths = value
		emit_changed()

## Runtime animation tags keyed by generated module role.
@export var animation_tags: Dictionary = {}:
	set(value):
		animation_tags = value
		emit_changed()

## Whether runtime consumers should apply subtle hair bounce offsets.
@export var hair_bounce_enabled: bool = true:
	set(value):
		hair_bounce_enabled = value
		emit_changed()


func get_hair_module_path(role: String, view_direction: String = "front") -> String:
	var view_key := "%s/%s" % [view_direction, role]
	if hair_module_paths.has(view_key):
		return String(hair_module_paths.get(view_key, ""))
	return String(hair_module_paths.get(role, ""))


func get_hair_animation_tag(role: String, view_direction: String = "front") -> String:
	var view_key := "%s/%s" % [view_direction, role]
	if animation_tags.has(view_key):
		return String(animation_tags.get(view_key, ""))
	return String(animation_tags.get(role, ""))


func get_hair_texture(role: String, view_direction: String = "front") -> Texture2D:
	var path := get_hair_module_path(role, view_direction)
	if path.is_empty():
		return null
	var texture := load(path)
	return texture if texture is Texture2D else null


func get_head_module_path(role: String = "head_base", view_direction: String = "front") -> String:
	var view_key := "%s/%s" % [view_direction, role]
	if head_module_paths.has(view_key):
		return String(head_module_paths.get(view_key, ""))
	return String(head_module_paths.get(role, ""))


func get_head_texture(role: String = "head_base", view_direction: String = "front") -> Texture2D:
	var path := get_head_module_path(role, view_direction)
	if path.is_empty():
		return null
	var texture := load(path)
	return texture if texture is Texture2D else null
