extends Node2D
class_name ArenaFloorTileVisual

const TILE_SIZE := 40.0
const PANEL_SIZE := 19.0
const PANEL_INSET := 0.67
const PANEL_STEP := 19.67

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
	_add_instances(
		"FloorVoid",
		_quad_mesh(),
		[_scaled_transform(0.0, background_rect.size, background_rect.get_center())],
		Color.BLACK
	)
	for tile_coord in tile_coordinates:
		var tile_origin := world_origin + Vector2(tile_coord) * TILE_SIZE
		base_transforms.append(_scaled_transform(0.0, Vector2.ONE * TILE_SIZE, tile_origin + Vector2.ONE * TILE_SIZE * 0.5))
		for panel_index in range(4):
			var panel_coord := Vector2i(panel_index % 2, floori(float(panel_index) / 2.0))
			var panel_origin := tile_origin + Vector2(
				PANEL_INSET + float(panel_coord.x) * PANEL_STEP,
				PANEL_INSET + float(panel_coord.y) * PANEL_STEP
			)
			panel_transforms.append(_scaled_transform(
				0.0,
				Vector2.ONE * PANEL_SIZE,
				panel_origin + Vector2.ONE * PANEL_SIZE * 0.5
			))
			var salt := 101 + panel_index * 37
			if _wear_value(tile_coord, wear_seed, salt) >= chip_density:
				continue
			var edge := int(floor(_wear_value(tile_coord, wear_seed, salt + 1) * 4.0)) % 4
			var edge_offset := 3.0 + _wear_value(tile_coord, wear_seed, salt + 2) * 11.0
			var size := 1.4 + _wear_value(tile_coord, wear_seed, salt + 3) * 1.8
			var chip_position := _chip_position(panel_origin, edge, edge_offset, size)
			chip_transforms[edge].append(_scaled_transform(
				float(edge) * PI * 0.5,
				Vector2.ONE * size,
				chip_position
			))
	_add_instances("FloorBases", _quad_mesh(), base_transforms, base_color)
	_add_instances("FloorPanels", _quad_mesh(), panel_transforms, panel_color)
	var chip_mesh := _chip_mesh()
	for edge in range(4):
		_add_instances("FloorChips%d" % edge, chip_mesh, chip_transforms[edge], chip_color)


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


func _chip_mesh() -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(-0.5, 0.0, 0.0),
		Vector3(0.5, 0.0, 0.0),
		Vector3(0.0, 1.0, 0.0)
	])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _chip_position(panel_origin: Vector2, edge: int, edge_offset: float, size: float) -> Vector2:
	match edge:
		0:
			return panel_origin + Vector2(edge_offset + size * 0.5, 0.0)
		1:
			return panel_origin + Vector2(PANEL_SIZE, edge_offset + size * 0.5)
		2:
			return panel_origin + Vector2(edge_offset + size * 0.5, PANEL_SIZE)
		_:
			return panel_origin + Vector2(0.0, edge_offset + size * 0.5)


func _scaled_transform(rotation: float, scale_value: Vector2, position_value: Vector2) -> Transform2D:
	return Transform2D(rotation, scale_value, 0.0, position_value)


func _wear_value(tile_coord: Vector2i, wear_seed: int, salt: int) -> float:
	var value := sin(
		float(tile_coord.x) * 12.9898
		+ float(tile_coord.y) * 78.233
		+ float(wear_seed) * 0.00013
		+ float(salt) * 0.9187
	) * 43758.5453
	return value - floor(value)
