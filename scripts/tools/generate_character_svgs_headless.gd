extends SceneTree

const DEFAULT_RECIPE_PATH := "res://resources/characters/velora_hair_recipe.tres"
const GENERATION_RUNNER := preload("res://scripts/tools/character_hair_generation_runner.gd")


func _init() -> void:
	var runner := GENERATION_RUNNER.new()
	var recipe := runner.load_or_create_recipe(DEFAULT_RECIPE_PATH)
	runner.generate_hair_modules(recipe, DEFAULT_RECIPE_PATH)
	quit()
