extends SceneTree

const OUTPUT_PATH := "res://scenes/tools/warehouse_tile_workbench.tscn"
const WORKBENCH_SCRIPT := preload("res://scripts/tools/warehouse_tile_workbench.gd")
const REFERENCE_TEXTURE := preload("res://art/concept_art/warehousetiles.png")
const TILE_SIZE := 40.0
const PREVIEW_SCALE := 3.0
const COLUMN_PITCH := 174.0
const ROW_PITCH := 174.0

var _tiles_root: Node2D
var _tile_index := 0


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	var workbench := Node2D.new()
	workbench.name = "WarehouseTileWorkbench"
	workbench.set_script(WORKBENCH_SCRIPT)
	root.add_child(workbench)

	_tiles_root = Node2D.new()
	_tiles_root.name = "Tiles"
	_tiles_root.position = Vector2(80.0, 100.0)
	workbench.add_child(_tiles_root)

	_build_floor_tiles()
	_build_overlay_tiles()
	_build_path_tiles()
	_build_perimeter_tiles()
	_build_wall_tiles()
	_build_door_tiles()
	_build_structure_tiles()

	var reference := Sprite2D.new()
	reference.name = "ReferenceMockup"
	reference.texture = REFERENCE_TEXTURE
	reference.position = Vector2(1760.0, 650.0)
	reference.scale = Vector2.ONE * 0.78
	workbench.add_child(reference)

	var guide := Line2D.new()
	guide.name = "CanonicalTileGuide"
	guide.position = Vector2(1515.0, 95.0)
	guide.points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(TILE_SIZE * PREVIEW_SCALE, 0.0),
		Vector2(TILE_SIZE * PREVIEW_SCALE, TILE_SIZE * PREVIEW_SCALE),
		Vector2(0.0, TILE_SIZE * PREVIEW_SCALE),
		Vector2.ZERO,
	])
	guide.width = 2.0
	guide.default_color = Color(0.1, 0.95, 1.0, 0.9)
	workbench.add_child(guide)

	var guide_label := Label.new()
	guide_label.name = "CanonicalTileLabel"
	guide_label.position = Vector2(1515.0, 225.0)
	guide_label.text = "40×40 CANONICAL TILE\nshown at 3× preview scale"
	guide_label.add_theme_font_size_override("font_size", 18)
	workbench.add_child(guide_label)

	_set_owner_recursive(workbench, workbench)
	var packed := PackedScene.new()
	var pack_error := packed.pack(workbench)
	if pack_error != OK:
		push_error("Could not pack warehouse tile workbench: %s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(packed, OUTPUT_PATH)
	if save_error != OK:
		push_error("Could not save warehouse tile workbench: %s" % error_string(save_error))
		quit(1)
		return
	print("Built %s with %d editable tile blocks." % [OUTPUT_PATH, _tile_index])
	quit()


func _build_floor_tiles() -> void:
	_floor_tile("floor_concrete", "FLOOR / CONCRETE", [])
	_floor_tile("floor_worn", "FLOOR / WORN", [
		_layer("WearA", "floor_worn", [Vector2(3, 5), Vector2(18, 2), Vector2(29, 7), Vector2(36, 18), Vector2(30, 34), Vector2(12, 37), Vector2(4, 28)]),
	])
	_floor_tile("floor_cracked", "FLOOR / CRACKED", [
		_layer("CrackA", "metal_dark", [Vector2(18, 0), Vector2(20, 12), Vector2(16, 19), Vector2(22, 25), Vector2(19, 40), Vector2(17, 27), Vector2(12, 20), Vector2(17, 11)]),
		_layer("CrackB", "metal_dark", [Vector2(18, 18), Vector2(6, 14), Vector2(1, 9), Vector2(8, 16), Vector2(17, 21)]),
	])
	_floor_tile("floor_metal_plate", "FLOOR / METAL PLATE", [
		_rect_layer("Plate", "metal", 2, 2, 36, 36),
		_layer("DiamondA", "metal_light", [Vector2(10, 5), Vector2(14, 10), Vector2(10, 15), Vector2(6, 10)]),
		_layer("DiamondB", "metal_dark", [Vector2(28, 22), Vector2(33, 27), Vector2(28, 32), Vector2(23, 27)]),
	])
	_floor_tile("floor_grate", "FLOOR / GRATE", [
		_rect_layer("GrateInset", "metal_dark", 3, 3, 34, 34),
		_rect_layer("RailA", "metal", 7, 4, 3, 32),
		_rect_layer("RailB", "metal", 15, 4, 3, 32),
		_rect_layer("RailC", "metal", 23, 4, 3, 32),
		_rect_layer("RailD", "metal", 31, 4, 3, 32),
	])
	_floor_tile("floor_painted", "FLOOR / PAINTED", [
		_rect_layer("Paint", "accent", 2, 2, 36, 36),
		_layer("ChipA", "floor", [Vector2(3, 7), Vector2(12, 4), Vector2(10, 9), Vector2(4, 12)]),
		_layer("ChipB", "floor_worn", [Vector2(29, 29), Vector2(38, 25), Vector2(37, 36), Vector2(25, 38)]),
	])


func _build_overlay_tiles() -> void:
	_overlay_tile("overlay_dirt", "OVERLAY / DIRT", [
		_layer("Dirt", "grime", [Vector2(3, 22), Vector2(8, 9), Vector2(18, 4), Vector2(34, 11), Vector2(38, 27), Vector2(27, 36), Vector2(10, 34)]),
	])
	_overlay_tile("overlay_scratches", "OVERLAY / SCRATCHES", [
		_layer("ScratchA", "metal_light", [Vector2(5, 31), Vector2(28, 7), Vector2(30, 8), Vector2(7, 33)]),
		_layer("ScratchB", "metal_light", [Vector2(12, 36), Vector2(35, 14), Vector2(36, 16), Vector2(14, 38)]),
	])
	_overlay_tile("overlay_oil", "OVERLAY / OIL", [
		_layer("Oil", "grime", [Vector2(5, 24), Vector2(9, 12), Vector2(20, 6), Vector2(33, 11), Vector2(38, 22), Vector2(30, 35), Vector2(14, 37)]),
		_layer("OilHighlight", "metal_dark", [Vector2(12, 14), Vector2(20, 10), Vector2(27, 14), Vector2(20, 16)]),
	])
	_overlay_tile("overlay_wet", "OVERLAY / WET", [
		_layer("Water", "liquid", [Vector2(3, 25), Vector2(8, 12), Vector2(20, 6), Vector2(35, 14), Vector2(38, 27), Vector2(29, 36), Vector2(12, 35)]),
		_layer("Reflection", "metal_light", [Vector2(11, 14), Vector2(25, 9), Vector2(30, 12), Vector2(16, 17)]),
	])
	_overlay_tile("overlay_leak", "OVERLAY / LEAK", [
		_layer("LeakA", "grime", [Vector2(5, 0), Vector2(11, 0), Vector2(13, 18), Vector2(18, 27), Vector2(14, 40), Vector2(8, 40), Vector2(10, 27), Vector2(7, 17)]),
		_layer("LeakB", "grime", [Vector2(28, 0), Vector2(34, 0), Vector2(31, 14), Vector2(35, 26), Vector2(31, 40), Vector2(25, 40), Vector2(29, 26), Vector2(27, 14)]),
	])
	_overlay_tile("overlay_moss", "OVERLAY / MOSS", [
		_layer("Moss", "accent", [Vector2(0, 17), Vector2(8, 9), Vector2(14, 13), Vector2(20, 5), Vector2(29, 10), Vector2(40, 7), Vector2(40, 25), Vector2(31, 20), Vector2(24, 31), Vector2(13, 25), Vector2(0, 34)]),
	])


func _build_path_tiles() -> void:
	_path_tile("path_straight", "PATH / STRAIGHT", [
		_rect_layer("Lane", "warning", 0, 17, 40, 6),
	])
	_path_tile("path_corner", "PATH / CORNER", [
		_rect_layer("LaneHorizontal", "warning", 0, 17, 23, 6),
		_rect_layer("LaneVertical", "warning", 17, 17, 6, 23),
		_layer("CornerFill", "warning", [Vector2(17, 17), Vector2(28, 17), Vector2(23, 23), Vector2(17, 28)]),
	])
	_path_tile("path_t_junction", "PATH / T-JUNCTION", [
		_rect_layer("LaneHorizontal", "warning", 0, 17, 40, 6),
		_rect_layer("LaneVertical", "warning", 17, 17, 6, 23),
	])
	_path_tile("path_cross", "PATH / CROSS", [
		_rect_layer("LaneHorizontal", "warning", 0, 17, 40, 6),
		_rect_layer("LaneVertical", "warning", 17, 0, 6, 40),
	])
	_path_tile("path_end", "PATH / END CAP", [
		_rect_layer("Lane", "warning", 0, 17, 28, 6),
		_rect_layer("End", "warning", 25, 12, 6, 16),
	])
	_path_tile("path_hazard", "PATH / HAZARD", [
		_rect_layer("HazardBase", "warning", 0, 0, 40, 40),
		_layer("StripeA", "warning_dark", [Vector2(0, 0), Vector2(9, 0), Vector2(40, 31), Vector2(40, 40)]),
		_layer("StripeB", "warning_dark", [Vector2(0, 18), Vector2(0, 30), Vector2(10, 40), Vector2(22, 40)]),
		_layer("StripeC", "warning_dark", [Vector2(18, 0), Vector2(30, 0), Vector2(40, 10), Vector2(40, 22)]),
	])


func _build_perimeter_tiles() -> void:
	_path_tile("perimeter_inner_edge", "PERIMETER / INNER EDGE", [
		_rect_layer("EdgeShadow", "shadow", 0, 26, 40, 14),
		_rect_layer("EdgeFace", "wall_face", 0, 18, 40, 12),
		_rect_layer("EdgeTop", "wall_top", 0, 14, 40, 8),
	])
	_path_tile("perimeter_outer_edge", "PERIMETER / OUTER EDGE", [
		_rect_layer("EdgeShadow", "shadow", 0, 0, 40, 14),
		_rect_layer("EdgeFace", "wall_face", 0, 10, 40, 12),
		_rect_layer("EdgeTop", "wall_top", 0, 18, 40, 8),
	])
	_path_tile("perimeter_inner_corner", "PERIMETER / INNER CORNER", [
		_layer("ShadowL", "shadow", [Vector2(0, 26), Vector2(26, 26), Vector2(26, 0), Vector2(40, 0), Vector2(40, 40), Vector2(0, 40)]),
		_layer("FaceL", "wall_face", [Vector2(0, 18), Vector2(22, 18), Vector2(22, 0), Vector2(32, 0), Vector2(32, 30), Vector2(0, 30)]),
		_layer("TopL", "wall_top", [Vector2(0, 13), Vector2(27, 13), Vector2(27, 0), Vector2(35, 0), Vector2(35, 21), Vector2(0, 21)]),
	])
	_path_tile("perimeter_outer_corner", "PERIMETER / OUTER CORNER", [
		_layer("ShadowL", "shadow", [Vector2(0, 0), Vector2(40, 0), Vector2(40, 40), Vector2(26, 40), Vector2(26, 14), Vector2(0, 14)]),
		_layer("FaceL", "wall_face", [Vector2(0, 8), Vector2(32, 8), Vector2(32, 40), Vector2(22, 40), Vector2(22, 18), Vector2(0, 18)]),
		_layer("TopL", "wall_top", [Vector2(0, 15), Vector2(25, 15), Vector2(25, 40), Vector2(17, 40), Vector2(17, 23), Vector2(0, 23)]),
	])


func _build_wall_tiles() -> void:
	_wall_tile("wall_straight", "WALL / STRAIGHT", "straight")
	_wall_tile("wall_corner", "WALL / CORNER", "corner")
	_wall_tile("wall_t_junction", "WALL / T-JUNCTION", "t")
	_wall_tile("wall_cross", "WALL / CROSS", "cross")
	_wall_tile("wall_low", "WALL / LOW COVER", "low")


func _build_door_tiles() -> void:
	_floor_tile("door_frame", "DOOR / FRAME", [
		_rect_layer("LeftPost", "metal_dark", 2, 4, 7, 36),
		_rect_layer("RightPost", "metal_dark", 31, 4, 7, 36),
		_rect_layer("Header", "metal", 2, 2, 36, 8),
		_rect_layer("LeftEdge", "metal_light", 4, 5, 2, 32),
		_rect_layer("RightEdge", "metal_light", 33, 5, 2, 32),
	])
	_floor_tile("door_personnel", "DOOR / PERSONNEL", [
		_rect_layer("DoorShadow", "shadow", 5, 3, 30, 37),
		_rect_layer("Door", "metal", 7, 4, 26, 36),
		_rect_layer("Inset", "metal_dark", 11, 9, 18, 24),
		_rect_layer("Handle", "warning", 25, 21, 3, 5),
	])
	_floor_tile("door_double", "DOOR / DOUBLE", [
		_rect_layer("DoorShadow", "shadow", 2, 3, 36, 37),
		_rect_layer("LeftDoor", "metal", 3, 4, 17, 36),
		_rect_layer("RightDoor", "metal", 20, 4, 17, 36),
		_rect_layer("Seam", "metal_dark", 19, 4, 2, 36),
		_rect_layer("WindowLeft", "accent", 7, 9, 9, 7),
		_rect_layer("WindowRight", "accent", 24, 9, 9, 7),
	])
	_floor_tile("door_rollup", "DOOR / ROLL-UP", [
		_rect_layer("Frame", "metal_dark", 2, 2, 36, 38),
		_rect_layer("Shutter", "metal", 5, 7, 30, 30),
		_rect_layer("SlatA", "metal_dark", 5, 14, 30, 2),
		_rect_layer("SlatB", "metal_dark", 5, 22, 30, 2),
		_rect_layer("SlatC", "metal_dark", 5, 30, 30, 2),
	])


func _build_structure_tiles() -> void:
	_floor_tile("structure_pillar", "STRUCTURE / PILLAR", [
		_layer("Shadow", "shadow", [Vector2(11, 12), Vector2(33, 12), Vector2(38, 34), Vector2(16, 40), Vector2(7, 31)]),
		_layer("Pillar", "wall_face", [Vector2(10, 7), Vector2(29, 5), Vector2(34, 28), Vector2(15, 35), Vector2(6, 27)]),
		_layer("PillarTop", "wall_top", [Vector2(10, 7), Vector2(25, 2), Vector2(33, 9), Vector2(18, 15)]),
	])
	_floor_tile("structure_barrier", "STRUCTURE / BARRIER", [
		_layer("Shadow", "shadow", [Vector2(2, 24), Vector2(38, 24), Vector2(36, 35), Vector2(4, 37)]),
		_layer("Barrier", "wall_face", [Vector2(1, 16), Vector2(39, 16), Vector2(35, 30), Vector2(5, 31)]),
		_layer("Top", "wall_top", [Vector2(1, 16), Vector2(6, 10), Vector2(39, 10), Vector2(39, 16)]),
		_rect_layer("WarningMark", "warning", 16, 13, 8, 10),
	])
	_floor_tile("structure_guard_rail", "STRUCTURE / GUARD RAIL", [
		_rect_layer("PostLeft", "warning_dark", 4, 8, 4, 28),
		_rect_layer("PostRight", "warning_dark", 32, 8, 4, 28),
		_rect_layer("RailShadow", "shadow", 4, 23, 32, 7),
		_rect_layer("Rail", "warning", 4, 16, 32, 6),
	])
	_floor_tile("structure_fence", "STRUCTURE / FENCE", [
		_rect_layer("FrameTop", "metal", 2, 4, 36, 3),
		_rect_layer("FrameBottom", "metal", 2, 34, 36, 3),
		_rect_layer("FrameLeft", "metal", 2, 4, 3, 33),
		_rect_layer("FrameRight", "metal", 35, 4, 3, 33),
		_layer("MeshA", "metal_light", [Vector2(6, 8), Vector2(9, 8), Vector2(34, 32), Vector2(31, 32)]),
		_layer("MeshB", "metal_light", [Vector2(31, 8), Vector2(34, 8), Vector2(9, 32), Vector2(6, 32)]),
	])


func _floor_tile(tile_id: String, label: String, layers: Array) -> void:
	var all_layers: Array = [_rect_layer("Base", "floor", 0, 0, 40, 40)]
	all_layers.append_array(layers)
	_add_tile(tile_id, label, all_layers)


func _overlay_tile(tile_id: String, label: String, layers: Array) -> void:
	var all_layers: Array = [_rect_layer("TransparentGuide", "floor", 0, 0, 40, 40)]
	all_layers.append_array(layers)
	_add_tile(tile_id, label, all_layers)


func _path_tile(tile_id: String, label: String, layers: Array) -> void:
	var all_layers: Array = [_rect_layer("Base", "floor", 0, 0, 40, 40)]
	all_layers.append_array(layers)
	_add_tile(tile_id, label, all_layers)


func _wall_tile(tile_id: String, label: String, variant: String) -> void:
	var layers: Array = [_rect_layer("Base", "floor", 0, 0, 40, 40)]
	match variant:
		"straight":
			layers.append_array([
				_rect_layer("Shadow", "shadow", 0, 22, 40, 18),
				_rect_layer("Face", "wall_face", 0, 13, 40, 18),
				_rect_layer("Top", "wall_top", 0, 7, 40, 10),
				_rect_layer("TopEdge", "metal_light", 0, 7, 40, 2),
			])
		"corner":
			layers.append_array([
				_layer("Shadow", "shadow", [Vector2(0, 22), Vector2(22, 22), Vector2(22, 0), Vector2(40, 0), Vector2(40, 40), Vector2(0, 40)]),
				_layer("Face", "wall_face", [Vector2(0, 13), Vector2(29, 13), Vector2(29, 0), Vector2(40, 0), Vector2(40, 31), Vector2(0, 31)]),
				_layer("Top", "wall_top", [Vector2(0, 7), Vector2(35, 7), Vector2(35, 0), Vector2(40, 0), Vector2(40, 17), Vector2(0, 17)]),
			])
		"t":
			layers.append_array([
				_rect_layer("ShadowHorizontal", "shadow", 0, 22, 40, 18),
				_rect_layer("ShadowVertical", "shadow", 13, 0, 14, 40),
				_rect_layer("FaceHorizontal", "wall_face", 0, 13, 40, 18),
				_rect_layer("FaceVertical", "wall_face", 13, 0, 14, 40),
				_rect_layer("TopHorizontal", "wall_top", 0, 7, 40, 10),
				_rect_layer("TopVertical", "wall_top", 16, 0, 8, 40),
			])
		"cross":
			layers.append_array([
				_rect_layer("ShadowHorizontal", "shadow", 0, 22, 40, 18),
				_rect_layer("ShadowVertical", "shadow", 13, 0, 14, 40),
				_rect_layer("FaceHorizontal", "wall_face", 0, 13, 40, 18),
				_rect_layer("FaceVertical", "wall_face", 13, 0, 14, 40),
				_rect_layer("TopHorizontal", "wall_top", 0, 7, 40, 10),
				_rect_layer("TopVertical", "wall_top", 16, 0, 8, 40),
			])
		"low":
			layers.append_array([
				_rect_layer("Shadow", "shadow", 0, 27, 40, 13),
				_rect_layer("Face", "wall_face", 0, 20, 40, 12),
				_rect_layer("Top", "wall_top", 0, 15, 40, 8),
			])
	_add_tile(tile_id, label, layers)


func _add_tile(tile_id: String, label_text: String, layers: Array) -> void:
	var tile := Node2D.new()
	tile.name = _pascal_case(tile_id)
	tile.position = Vector2(
		float(_tile_index % 8) * COLUMN_PITCH,
		float(_tile_index / 8) * ROW_PITCH
	)
	tile.scale = Vector2.ONE * PREVIEW_SCALE
	tile.set_meta("tile_id", tile_id)
	tile.set_meta("canonical_size", Vector2(TILE_SIZE, TILE_SIZE))
	tile.set_meta("layer_order", _layer_order_string(layers))
	_tiles_root.add_child(tile)

	for layer_data in layers:
		var polygon := Polygon2D.new()
		polygon.name = String(layer_data["name"])
		polygon.polygon = PackedVector2Array(layer_data["points"])
		polygon.color = _default_role_color(String(layer_data["role"]))
		polygon.set_meta("palette_role", String(layer_data["role"]))
		tile.add_child(polygon)

	var outline := Line2D.new()
	outline.name = "TileBounds"
	outline.points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(40, 0),
		Vector2(40, 40),
		Vector2(0, 40),
		Vector2.ZERO,
	])
	outline.width = 0.6
	outline.default_color = Color(0.1, 0.9, 1.0, 0.48)
	tile.add_child(outline)

	var label := Label.new()
	label.name = "Label"
	label.position = Vector2(0, 43)
	label.scale = Vector2.ONE / PREVIEW_SCALE
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	tile.add_child(label)
	_tile_index += 1


func _layer(name: String, role: String, points: Array[Vector2]) -> Dictionary:
	return {"name": name, "role": role, "points": points}


func _rect_layer(name: String, role: String, x: float, y: float, width: float, height: float) -> Dictionary:
	return _layer(name, role, [
		Vector2(x, y),
		Vector2(x + width, y),
		Vector2(x + width, y + height),
		Vector2(x, y + height),
	])


func _layer_order_string(layers: Array) -> String:
	var names: PackedStringArray = []
	for layer_data in layers:
		names.append(String(layer_data["name"]))
	return ",".join(names)


func _pascal_case(value: String) -> String:
	var result := ""
	for part in value.split("_", false):
		result += part.capitalize()
	return result


func _default_role_color(role: String) -> Color:
	match role:
		"shadow":
			return Color("#15171b")
		"floor":
			return Color("#34373a")
		"floor_worn":
			return Color("#44443f")
		"wall_face":
			return Color("#55565a")
		"wall_top":
			return Color("#85827a")
		"metal_dark":
			return Color("#252a2d")
		"metal":
			return Color("#596064")
		"metal_light":
			return Color("#a5a7a3")
		"warning":
			return Color("#c29b21")
		"warning_dark":
			return Color("#242528")
		"grime":
			return Color("#1d211d")
		"accent":
			return Color("#536341")
		"liquid":
			return Color("#304b63")
		_:
			return Color.WHITE


func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_owner_recursive(child, scene_owner)
