extends RefCounted
class_name CharacterHairGenerationRunner

const RECIPE_SCRIPT := preload("res://scripts/resources/character_visual_recipe.gd")
const VISUAL_SET_SCRIPT := preload("res://scripts/resources/character_visual_set.gd")
const SVG_WRITER := preload("res://scripts/resources/character_svg_template_writer.gd")

var generated_svg_paths: PackedStringArray = []


func load_or_create_recipe(path: String) -> Resource:
	var loaded := load(path)
	if loaded != null and loaded.get_script() == RECIPE_SCRIPT:
		return loaded
	var recipe: Resource = RECIPE_SCRIPT.new()
	_ensure_dir_for_path(path)
	var error := ResourceSaver.save(recipe, path)
	if error != OK:
		push_error("Failed to save default character visual recipe: %s" % error)
	return recipe


func generate_hair_modules(recipe: Resource, recipe_path: String = "") -> Resource:
	if recipe == null:
		return null
	generated_svg_paths.clear()
	if recipe.hair_modules.is_empty() and recipe.has_method("create_default_hair_modules"):
		recipe.hair_modules = recipe.create_default_hair_modules()
	if not recipe_path.is_empty():
		ResourceSaver.save(recipe, recipe_path)
	_ensure_dir(recipe.output_svg_dir)
	_ensure_dir_for_path(recipe.output_visual_set_path)
	var visual_set: Resource = VISUAL_SET_SCRIPT.new()
	visual_set.character_id = recipe.character_id
	visual_set.hair_bounce_enabled = recipe.hair_bounce_enabled
	var writer := SVG_WRITER.new()
	var module_paths := {}
	var head_module_paths := {}
	var animation_tags := {}
	var views: PackedStringArray = recipe.get_generated_views() if recipe.has_method("get_generated_views") else PackedStringArray(["front"])
	for view in views:
		for module in recipe.hair_modules:
			if module == null or String(module.role).is_empty():
				continue
			var role := String(module.role)
			var key := "%s/%s" % [view, role]
			var svg: String = writer.build_hair_module_svg(recipe, module, view)
			var output_path: String = String(recipe.output_svg_dir).path_join("%s_%s_%s.svg" % [recipe.character_id, view, role])
			_write_text_file(output_path, svg)
			generated_svg_paths.append(output_path)
			module_paths[key] = output_path
			animation_tags[key] = module.animation_tag
			if view == "front":
				module_paths[role] = output_path
				animation_tags[role] = module.animation_tag
			print("Generated character hair module: %s" % output_path)
		var head_roles: PackedStringArray = recipe.get_generated_head_roles() if recipe.has_method("get_generated_head_roles") else PackedStringArray(["head_base"])
		for head_role in head_roles:
			var head_svg: String = writer.build_head_module_svg(recipe, head_role, view)
			var head_output_path: String = String(recipe.output_svg_dir).path_join("%s_%s_%s.svg" % [recipe.character_id, view, head_role])
			_write_text_file(head_output_path, head_svg)
			generated_svg_paths.append(head_output_path)
			head_module_paths["%s/%s" % [view, head_role]] = head_output_path
			if view == "front":
				head_module_paths[head_role] = head_output_path
			print("Generated character head module: %s" % head_output_path)
	visual_set.hair_module_paths = module_paths
	visual_set.head_module_paths = head_module_paths
	visual_set.animation_tags = animation_tags
	var error := ResourceSaver.save(visual_set, recipe.output_visual_set_path)
	if error != OK:
		push_error("Failed to save character visual set: %s" % error)
	else:
		print("Generated character visual set: %s" % recipe.output_visual_set_path)
	return visual_set


func _write_text_file(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open generated file for writing: %s" % path)
		return
	file.store_string(text)


func _ensure_dir(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	var error := DirAccess.make_dir_recursive_absolute(absolute)
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("Failed to create directory %s: %s" % [path, error])


func _ensure_dir_for_path(path: String) -> void:
	_ensure_dir(path.get_base_dir())
