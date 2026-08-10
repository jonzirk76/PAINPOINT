extends SceneTree

const EXTRACTION_RUNNER := preload("res://scripts/tools/character_blockout_extraction_runner.gd")


func _init() -> void:
	var runner := EXTRACTION_RUNNER.new()
	runner.extract_default()
	quit()
