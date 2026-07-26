@tool
extends RefCounted
class_name CharacterPartSourceSync

const META_SOURCE_SCENE := "character_part_source_scene"
const LEGACY_META_SOURCE_SCENE := "part_source_scene"
const META_PRESERVE_ROOT_TRANSFORM := "character_part_preserve_source_root_transform"
const DEFAULT_PART_SOURCE_DIR := "res://scenes/characters/parts"


func get_selected_node(editor_interface: EditorInterface) -> Node:
	if editor_interface == null:
		push_error("Character part sync must run from the Godot editor.")
		return null
	var selection := editor_interface.get_selection()
	if selection == null:
		push_error("No editor selection is available.")
		return null
	var nodes: Array[Node] = selection.get_selected_nodes()
	if nodes.size() != 1:
		push_error("Select exactly one character part node. Selected: %d" % nodes.size())
		return null
	return nodes[0]


func push_node_to_source(node: Node) -> String:
	if node == null:
		push_error("No character part node was provided.")
		return ""
	var source_path := get_or_create_source_path(node)
	if source_path.is_empty():
		return ""
	var duplicate_root := _duplicate_for_source(node, source_path)
	if duplicate_root == null:
		return ""
	var packer := PackedScene.new()
	var pack_error := packer.pack(duplicate_root)
	if pack_error != OK:
		duplicate_root.free()
		push_error("Failed to pack character part source '%s': %s" % [source_path, error_string(pack_error)])
		return ""
	var save_error := ResourceSaver.save(packer, source_path)
	duplicate_root.free()
	if save_error != OK:
		push_error("Failed to save character part source '%s': %s" % [source_path, error_string(save_error)])
		return ""
	print("Pushed character part '%s' to %s" % [node.name, source_path])
	return source_path


func replace_node_with_source_instance(node: Node, source_path: String = "") -> Node:
	if node == null:
		push_error("No character part node was provided.")
		return null
	if source_path.is_empty():
		source_path = get_or_create_source_path(node)
	if source_path.is_empty():
		return null
	var packed_scene := load(source_path) as PackedScene
	if packed_scene == null:
		push_error("Could not load character part source scene: %s" % source_path)
		return null
	var parent := node.get_parent()
	if parent == null:
		push_error("Cannot replace the edited scene root with a source instance.")
		return null
	var index := node.get_index()
	var replacement := packed_scene.instantiate()
	if replacement == null:
		push_error("Could not instantiate character part source scene: %s" % source_path)
		return null
	_copy_instance_placement(node, replacement)
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	replacement.owner = node.owner
	node.queue_free()
	print("Replaced selected part with instance of %s" % source_path)
	return replacement


func get_or_create_source_path(node: Node) -> String:
	var source_path := get_source_path(node)
	if not source_path.is_empty():
		node.set_meta(META_SOURCE_SCENE, source_path)
		return source_path
	source_path = "%s/%s.tscn" % [DEFAULT_PART_SOURCE_DIR, _default_source_name(node)]
	node.set_meta(META_SOURCE_SCENE, source_path)
	return source_path


func get_source_path(node: Node) -> String:
	if node == null:
		return ""
	var instance_path := String(node.scene_file_path)
	if instance_path.begins_with("res://") and instance_path.ends_with(".tscn"):
		return instance_path
	for key in [META_SOURCE_SCENE, LEGACY_META_SOURCE_SCENE]:
		if not node.has_meta(key):
			continue
		var path := String(node.get_meta(key)).strip_edges()
		if path.begins_with("res://") and path.ends_with(".tscn"):
			return path
		push_warning("Ignoring invalid character part source path on %s: %s" % [node.name, path])
	return ""


func _duplicate_for_source(node: Node, source_path: String) -> Node:
	_ensure_source_directory(source_path)
	var duplicate_root := node.duplicate(Node.DUPLICATE_SIGNALS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS)
	if duplicate_root == null:
		push_error("Could not duplicate selected character part node: %s" % node.name)
		return null
	duplicate_root.scene_file_path = ""
	duplicate_root.set_meta(META_SOURCE_SCENE, source_path)
	if not _apply_existing_source_root_state(duplicate_root, source_path):
		duplicate_root.name = node.name
	_set_owner_recursive(duplicate_root, duplicate_root)
	return duplicate_root


func _apply_existing_source_root_state(duplicate_root: Node, source_path: String) -> bool:
	var existing_scene := load(source_path) as PackedScene
	if existing_scene == null:
		return false
	var existing_root := existing_scene.instantiate()
	if existing_root == null:
		return false
	duplicate_root.name = existing_root.name
	if not duplicate_root.has_meta(META_PRESERVE_ROOT_TRANSFORM) or bool(duplicate_root.get_meta(META_PRESERVE_ROOT_TRANSFORM)):
		if duplicate_root is Node2D and existing_root is Node2D:
			(duplicate_root as Node2D).transform = (existing_root as Node2D).transform
		elif duplicate_root is Control and existing_root is Control:
			var duplicate_control := duplicate_root as Control
			var existing_control := existing_root as Control
			duplicate_control.position = existing_control.position
			duplicate_control.size = existing_control.size
			duplicate_control.rotation = existing_control.rotation
			duplicate_control.scale = existing_control.scale
	existing_root.free()
	return true


func _copy_instance_placement(source: Node, replacement: Node) -> void:
	replacement.name = source.name
	replacement.set_meta(META_SOURCE_SCENE, get_or_create_source_path(source))
	if source is Node2D and replacement is Node2D:
		(replacement as Node2D).transform = (source as Node2D).transform
	elif source is Control and replacement is Control:
		var source_control := source as Control
		var replacement_control := replacement as Control
		replacement_control.position = source_control.position
		replacement_control.size = source_control.size
		replacement_control.rotation = source_control.rotation
		replacement_control.scale = source_control.scale


func _ensure_source_directory(source_path: String) -> void:
	var global_dir := ProjectSettings.globalize_path(source_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(global_dir)


func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)


func _default_source_name(node: Node) -> String:
	if node.owner != null and node.owner != node:
		return _to_snake_case(String(node.owner.get_path_to(node)))
	return _to_snake_case(String(node.name))


func _to_snake_case(value: String) -> String:
	var result := ""
	var previous_was_separator := true
	for index in value.length():
		var character := value.substr(index, 1)
		var code := character.unicode_at(0)
		var is_upper := code >= 65 and code <= 90
		var is_lower := code >= 97 and code <= 122
		var is_digit := code >= 48 and code <= 57
		if is_upper:
			if not previous_was_separator and not result.ends_with("_"):
				result += "_"
			result += character.to_lower()
			previous_was_separator = false
		elif is_lower or is_digit:
			result += character
			previous_was_separator = false
		elif not previous_was_separator:
			result += "_"
			previous_was_separator = true
	result = result.strip_edges()
	while result.ends_with("_"):
		result = result.substr(0, result.length() - 1)
	return result if not result.is_empty() else "character_part"
