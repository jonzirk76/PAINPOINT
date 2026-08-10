extends SceneTree

const OUTPUT_DIR := "res://scenes/tools/anatomy/generated_anatomy_previews"
const CAPTURES := [
	{
		"scene": "res://scenes/tools/anatomy/skull_studies/01_three_quarter_neutral_skull.tscn",
		"file": "01_three_quarter_neutral_skull.png",
	},
	{
		"scene": "res://scenes/tools/anatomy/skull_studies/02_looking_up_skull.tscn",
		"file": "02_looking_up_skull.png",
	},
	{
		"scene": "res://scenes/tools/anatomy/skull_studies/03_looking_down_left_skull.tscn",
		"file": "03_looking_down_left_skull.png",
	},
	{
		"scene": "res://scenes/tools/anatomy/skull_studies/04_rolled_three_quarter_skull.tscn",
		"file": "04_rolled_three_quarter_skull.png",
	},
	{
		"scene": "res://scenes/tools/experiment_polygon_comparison_v2.tscn",
		"file": "05_portrait_comparison.png",
	},
]


func _initialize() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIR)
	)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error("Could not create anatomy preview directory (error %d)." % directory_error)
		quit(1)
		return

	root.size = Vector2i(1280, 720)
	for capture: Dictionary in CAPTURES:
		var packed: PackedScene = load(capture["scene"])
		if packed == null:
			push_error("Could not load preview scene: %s" % capture["scene"])
			quit(1)
			return
		var instance := packed.instantiate()
		root.add_child(instance)
		await process_frame
		await process_frame
		RenderingServer.force_draw(true)
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			push_error("Captured an empty image for %s." % capture["scene"])
			instance.queue_free()
			quit(1)
			return
		var output_path := "%s/%s" % [OUTPUT_DIR, capture["file"]]
		var save_error := image.save_png(ProjectSettings.globalize_path(output_path))
		if save_error != OK:
			push_error("Could not save %s (error %d)." % [output_path, save_error])
			instance.queue_free()
			quit(1)
			return
		print("Captured %s" % output_path)
		instance.queue_free()
		await process_frame
	quit(0)
