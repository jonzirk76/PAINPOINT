@tool
extends EditorScript

const DEFAULT_RECIPE_PATH := "res://resources/characters/velora_hair_recipe.tres"
const GENERATION_RUNNER := preload("res://scripts/tools/character_hair_generation_runner.gd")


func _run() -> void:
	if not Engine.is_editor_hint():
		push_warning("Character SVG generation is editor-only.")
		return
	var runner := GENERATION_RUNNER.new()
	var recipe := runner.load_or_create_recipe(DEFAULT_RECIPE_PATH)
	runner.generate_hair_modules(recipe, DEFAULT_RECIPE_PATH)
