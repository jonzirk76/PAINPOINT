extends SceneTree

const SOURCE_SCENE := "res://scenes/tools/volette_three_quarter_trace_workbench.tscn"
const OUTPUTS := {
	"ThreeQuarterDownRight/BodyMotion": "res://scenes/characters/rig_parts/humanoid_three_quarter_down_left_body_assembly_prototype.tscn",
	"ThreeQuarterUpRight/BodyMotion": "res://scenes/characters/rig_parts/humanoid_three_quarter_up_right_body_assembly_prototype.tscn",
}


func _initialize() -> void:
	call_deferred("_promote_assemblies")


func _promote_assemblies() -> void:
	var source_resource := load(SOURCE_SCENE) as PackedScene
	if source_resource == null:
		push_error("Could not load diagonal workbench: %s" % SOURCE_SCENE)
		quit(1)
		return
	var source_root := source_resource.instantiate()
	for source_path: String in OUTPUTS:
		var source_assembly := source_root.get_node_or_null(source_path) as Node2D
		if source_assembly == null:
			push_error("Missing diagonal workbench assembly: %s" % source_path)
			source_root.free()
			quit(1)
			return
		var promoted := source_assembly.duplicate() as Node2D
		promoted.name = "BodyMotion"
		_normalize_for_rig(promoted)
		_set_owner_recursive(promoted, promoted)
		var packed := PackedScene.new()
		var pack_error := packed.pack(promoted)
		if pack_error != OK:
			push_error("Could not pack %s: %s" % [source_path, error_string(pack_error)])
			promoted.free()
			source_root.free()
			quit(1)
			return
		var output_path: String = OUTPUTS[source_path]
		var save_error := ResourceSaver.save(packed, output_path)
		promoted.free()
		if save_error != OK:
			push_error("Could not save %s: %s" % [output_path, error_string(save_error)])
			source_root.free()
			quit(1)
			return
		print("Promoted %s to %s" % [source_path, output_path])
	source_root.free()
	quit()


func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_owner_recursive(child, scene_owner)


func _normalize_for_rig(assembly: Node2D) -> void:
	var torso_pivot := assembly.get_node_or_null("TorsoPivot") as Node2D
	if torso_pivot != null:
		torso_pivot.position = Vector2(0.0, 15.0)
	var renames := {
		"TorsoPivot/HipsAnchor/HipsPivot/FarHipSocket_Left": "FarHipSocket",
		"TorsoPivot/HipsAnchor/HipsPivot/FarHipSocket_Left/FarLegPivot_Left": "FarLegPivot",
		"TorsoPivot/HipsAnchor/HipsPivot/NearHipSocket_Right": "NearHipSocket",
		"TorsoPivot/HipsAnchor/HipsPivot/NearHipSocket_Right/NearLegPivot_Right": "NearLegPivot",
		"TorsoPivot/FarShoulderAnchor_Left": "FarShoulderAnchor",
		"TorsoPivot/FarShoulderAnchor_Left/FarArmPivot_Left": "FarArmPivot",
		"TorsoPivot/NearShoulderAnchor_Right": "NearShoulderAnchor",
		"TorsoPivot/NearShoulderAnchor_Right/NearArmPivot_Right": "NearArmPivot",
	}
	var rename_targets: Array[Node] = []
	var rename_values: Array[String] = []
	for path: String in renames:
		var target := assembly.get_node_or_null(path)
		if target != null:
			rename_targets.append(target)
			rename_values.append(String(renames[path]))
	for index in rename_targets.size():
		rename_targets[index].name = rename_values[index]
