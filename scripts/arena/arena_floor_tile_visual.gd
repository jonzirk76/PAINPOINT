extends Node2D
class_name ArenaFloorTileVisual

const TILE_SIZE := 40.0
const FLOOR_TILE_SOURCE := preload("res://scenes/tools/warehouse_floor_tile_source.tscn")

var _mesh_nodes: Array[MultiMeshInstance2D] = []


func configure(
	tile_coordinates: Array[Vector2i],
	world_origin: Vector2,
	background_rect: Rect2,
	wear_seed: int,
	chip_density: float,
	base_color: Color,
	panel_color: Color,
	chip_color: Color
) -> void:
	clear()
	var base_transforms: Array[Transform2D] = []
	var panel_transforms: Array[Transform2D] = []
	var chip_transforms: Array[Array] = [[], [], [], []]
	var source_meshes := _build_source_meshes()
	var base_mesh: Mesh = source_meshes.get("base")
	var panel_mesh: Mesh = source_meshes.get("panels")
	var chip_meshes: Array = source_meshes.get("chips", [])
	_add_instances(
		"FloorVoid",
		_quad_mesh(),
		[_scaled_transform(0.0, background_rect.size, background_rect.get_center())],
		Color.BLACK
	)
	for tile_coord in tile_coordinates:
		var tile_origin := world_origin + Vector2(tile_coord) * TILE_SIZE
		var tile_transform := Transform2D(0.0, tile_origin)
		base_transforms.append(tile_transform)
		panel_transforms.append(tile_transform)
		for chip_index in range(chip_meshes.size()):
			var salt := 101 + chip_index * 37
			if _wear_value(tile_coord, wear_seed, salt) >= chip_density:
				continue
			chip_transforms[chip_index].append(tile_transform)
	_add_instances("FloorBases", base_mesh, base_transforms, base_color)
	_add_instances("FloorPanels", panel_mesh, panel_transforms, panel_color)
	for chip_index in range(chip_meshes.size()):
		_add_instances("FloorChips%d" % chip_index, chip_meshes[chip_index], chip_transforms[chip_index], chip_color)


func clear() -> void:
	for mesh_node in _mesh_nodes:
		if is_instance_valid(mesh_node):
			mesh_node.queue_free()
	_mesh_nodes.clear()


func _exit_tree() -> void:
	clear()


func _add_instances(node_name: String, mesh: Mesh, transforms: Array, color: Color) -> void:
	if transforms.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform_2d(index, transforms[index])
	var mesh_node := MultiMeshInstance2D.new()
	mesh_node.name = node_name
	mesh_node.multimesh = multimesh
	mesh_node.modulate = color
	add_child(mesh_node)
	_mesh_nodes.append(mesh_node)


func _quad_mesh() -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	return mesh


func _build_source_meshes() -> Dictionary:
	var source := FLOOR_TILE_SOURCE.instantiate() as Node2D
	var base_polygons: Array[PackedVector2Array] = []
	var panel_polygons: Array[PackedVector2Array] = []
	var chip_polygons: Array[PackedVector2Array] = []
	for node in source.find_children("*", "Polygon2D", true, false):
		var polygon := node as Polygon2D
		var transformed_points := PackedVector2Array()
		var relative_transform := source.global_transform.affine_inverse() * polygon.global_transform
		for point in polygon.polygon:
			transformed_points.append(relative_transform * point)
		match String(polygon.get_meta("runtime_layer", "")):
			"base":
				base_polygons.append(transformed_points)
			"panel":
				panel_polygons.append(transformed_points)
			"chip":
				chip_polygons.append(transformed_points)
	var chip_meshes: Array[Mesh] = []
	for chip_polygon in chip_polygons:
		chip_meshes.append(_polygon_meshes([chip_polygon]))
	source.free()
	return {
		"base": _polygon_meshes(base_polygons),
		"panels": _polygon_meshes(panel_polygons),
		"chips": chip_meshes
	}


func _polygon_meshes(polygons: Array[PackedVector2Array]) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for polygon in polygons:
		var local_indices := Geometry2D.triangulate_polygon(polygon)
		var vertex_offset := vertices.size()
		for point in polygon:
			vertices.append(Vector3(point.x, point.y, 0.0))
		for index in local_indices:
			indices.append(vertex_offset + index)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _scaled_transform(rotation_radians: float, scale_value: Vector2, position_value: Vector2) -> Transform2D:
	return Transform2D(rotation_radians, scale_value, 0.0, position_value)


func _wear_value(tile_coord: Vector2i, wear_seed: int, salt: int) -> float:
	var value := sin(
		float(tile_coord.x) * 12.9898
		+ float(tile_coord.y) * 78.233
		+ float(wear_seed) * 0.00013
		+ float(salt) * 0.9187
	) * 43758.5453
	return value - floor(value)
