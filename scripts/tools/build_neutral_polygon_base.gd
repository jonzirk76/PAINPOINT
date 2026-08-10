@tool
extends SceneTree

const OUTPUT_DIRECTORY := "res://scenes/characters/neutral_polygon_base"

const VIEW_SPECS := [
	{
		"id": "south",
		"source": "res://scenes/characters/neutral_cutout/neutral_humanoid_south.tscn",
	},
	{
		"id": "south_west",
		"source": "res://scenes/characters/neutral_cutout/neutral_humanoid_south_west.tscn",
	},
	{
		"id": "west",
		"source": "res://scenes/characters/neutral_cutout/neutral_humanoid_west.tscn",
	},
	{
		"id": "north_east",
		"source": "res://scenes/characters/neutral_cutout/neutral_humanoid_north_east.tscn",
	},
	{
		"id": "north",
		"source": "res://scenes/characters/neutral_cutout/neutral_humanoid_north.tscn",
	},
]

const HEAD_COLOR := Color("d8afa0")
const TORSO_COLOR := Color("1556a6")
const HIPS_COLOR := Color("09264f")
const UPPER_LIMB_COLOR := Color("175fba")
const LOWER_LIMB_COLOR := Color("123f7d")
const EXTREMITY_COLOR := Color("07162c")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	for spec: Dictionary in VIEW_SPECS:
		var source_scene: PackedScene = load(spec["source"])
		if source_scene == null:
			push_error("Could not load polygon reference %s." % spec["source"])
			quit(1)
			return
		var root := source_scene.instantiate()
		root.name = "NeutralPolygon%s" % _pascal_case(spec["id"])
		root.set_meta("canonical_direction", spec["id"])
		root.set_meta("reference_scene", spec["source"])
		_promote_polygons(root)
		_set_scene_owner(root, root)

		var packed := PackedScene.new()
		var pack_error := packed.pack(root)
		if pack_error != OK:
			push_error("Could not pack neutral polygon base %s." % spec["id"])
			quit(1)
			return
		var output_path := "%s/neutral_polygon_%s.tscn" % [OUTPUT_DIRECTORY, spec["id"]]
		var save_error := ResourceSaver.save(packed, output_path)
		if save_error != OK:
			push_error("Could not save %s." % output_path)
			quit(1)
			return
		print("Generated %s" % output_path)
		root.free()
	quit()


func _promote_polygons(root: Node) -> void:
	for candidate in root.find_children("*", "Polygon2D", true, false):
		var polygon := candidate as Polygon2D
		polygon.texture = null
		polygon.uv = PackedVector2Array()
		polygon.color = _semantic_color(polygon)
		polygon.antialiased = true
		polygon.set_meta("editable_polygon_base", true)


func _semantic_color(polygon: Polygon2D) -> Color:
	match polygon.name:
		&"HeadMass":
			return HEAD_COLOR
		&"TorsoMass":
			return TORSO_COLOR
		&"HipsMass":
			return HIPS_COLOR
		&"UpperArm", &"Thigh":
			return UPPER_LIMB_COLOR
		&"ForearmMass", &"ShinMass":
			return LOWER_LIMB_COLOR
		&"HandMass":
			return HEAD_COLOR
		&"FootMass":
			return EXTREMITY_COLOR
		_:
			return Color.WHITE


func _set_scene_owner(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		_set_scene_owner(child, scene_root)


func _pascal_case(value: String) -> String:
	var result := ""
	for piece in value.split("_"):
		result += piece.capitalize()
	return result
