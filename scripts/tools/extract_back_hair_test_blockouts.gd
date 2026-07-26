@tool
extends EditorScript

const EXTRACTION_RUNNER := preload("res://scripts/tools/character_blockout_extraction_runner.gd")


func _run() -> void:
	if not Engine.is_editor_hint():
		push_warning("Character blockout extraction is editor-only.")
		return
	var runner := EXTRACTION_RUNNER.new()
	runner.extract_default()
