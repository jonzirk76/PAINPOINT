@tool
extends RefCounted

const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN,
]


static func trace_region(
	image: Image,
	seed: Vector2i,
	tolerance: float = 0.08,
	vertex_error: float = 1.5,
	include_alpha: bool = true
) -> Dictionary:
	if image == null or image.is_empty():
		return {"ok": false, "error": "Image is empty."}
	if (
		seed.x < 0
		or seed.y < 0
		or seed.x >= image.get_width()
		or seed.y >= image.get_height()
	):
		return {
			"ok": false,
			"error": "Seed pixel is outside the image.",
			"image_size": image.get_size(),
		}
	if tolerance < 0.0 or tolerance > 1.0:
		return {"ok": false, "error": "Tolerance must be between 0 and 1."}
	if vertex_error < 0.0:
		return {"ok": false, "error": "Vertex error cannot be negative."}

	var sample: Color = image.get_pixelv(seed)
	var mask := _flood_fill_mask(
		image,
		seed,
		sample,
		tolerance,
		include_alpha
	)
	var polygons: Array[PackedVector2Array] = mask.opaque_to_polygons(
		Rect2i(Vector2i.ZERO, mask.get_size()),
		vertex_error
	)
	var polygon := _find_seed_polygon(
		polygons,
		Vector2(seed) + Vector2(0.5, 0.5)
	)
	if polygon.size() < 3:
		return {
			"ok": false,
			"error": "The selected region did not produce a usable polygon.",
			"sample": sample,
			"selected_pixel_count": mask.get_true_bit_count(),
		}
	var triangle_indices := Geometry2D.triangulate_polygon(polygon)
	var pieces: Array[PackedVector2Array] = [polygon]
	if triangle_indices.is_empty():
		pieces = _repair_polygon(polygon)
	if pieces.is_empty():
		return {
			"ok": false,
			"error": "The selected region could not be converted into renderable pieces.",
			"sample": sample,
			"selected_pixel_count": mask.get_true_bit_count(),
		}
	var vertex_count := 0
	for piece in pieces:
		vertex_count += piece.size()

	return {
		"ok": true,
		"polygon": polygon,
		"pieces": pieces,
		"sample": sample,
		"selected_pixel_count": mask.get_true_bit_count(),
		"vertex_count": vertex_count,
		"piece_count": pieces.size(),
		"used_contour_repair": triangle_indices.is_empty(),
		"image_size": image.get_size(),
		"seed": seed,
		"tolerance": tolerance,
		"vertex_error": vertex_error,
		"include_alpha": include_alpha,
	}


static func build_polygon_data(
	image_pieces: Array[PackedVector2Array],
	image_size: Vector2i,
	offset: Vector2,
	centered: bool,
	flip_h: bool,
	flip_v: bool
) -> Dictionary:
	var vertices := PackedVector2Array()
	var polygon_indices: Array[PackedInt32Array] = []
	for image_piece in image_pieces:
		var local_piece := image_points_to_sprite_local(
			image_piece,
			image_size,
			offset,
			centered,
			flip_h,
			flip_v
		)
		var indices := PackedInt32Array()
		for point in local_piece:
			indices.append(vertices.size())
			vertices.append(point)
		polygon_indices.append(indices)
	return {
		"vertices": vertices,
		"polygons": polygon_indices,
	}


static func image_points_to_sprite_local(
	image_points: PackedVector2Array,
	image_size: Vector2i,
	offset: Vector2,
	centered: bool,
	flip_h: bool,
	flip_v: bool
) -> PackedVector2Array:
	var size := Vector2(image_size)
	var origin := offset
	if centered:
		origin -= size * 0.5

	var result := PackedVector2Array()
	for image_point in image_points:
		var point := image_point
		if flip_h:
			point.x = size.x - point.x
		if flip_v:
			point.y = size.y - point.y
		result.append(origin + point)
	return result


static func _repair_polygon(polygon: PackedVector2Array) -> Array[PackedVector2Array]:
	# Clipper's offset pass resolves doubled-back edges and one-pixel pinches
	# produced by bitmap contours. Prefer the smallest change that yields only
	# polygons Godot can triangulate.
	for repair_distance in [0.25, 0.5, 1.0, 2.0]:
		var candidates: Array[PackedVector2Array] = Geometry2D.offset_polygon(
			polygon,
			repair_distance,
			Geometry2D.JOIN_SQUARE
		)
		var valid: Array[PackedVector2Array] = []
		var all_renderable := not candidates.is_empty()
		for candidate in candidates:
			if candidate.size() < 3:
				continue
			if Geometry2D.triangulate_polygon(candidate).is_empty():
				all_renderable = false
				break
			valid.append(candidate)
		if all_renderable and not valid.is_empty():
			return valid
	return []


static func _flood_fill_mask(
	image: Image,
	seed: Vector2i,
	sample: Color,
	tolerance: float,
	include_alpha: bool
) -> BitMap:
	var image_size := image.get_size()
	var mask := BitMap.new()
	mask.create(image_size)
	var visited := PackedByteArray()
	visited.resize(image_size.x * image_size.y)
	var pending: Array[Vector2i] = [seed]
	visited[seed.y * image_size.x + seed.x] = 1

	while not pending.is_empty():
		var point: Vector2i = pending.pop_back()
		var color: Color = image.get_pixelv(point)
		if not _colors_match(color, sample, tolerance, include_alpha):
			continue
		mask.set_bitv(point, true)

		for offset: Vector2i in NEIGHBOR_OFFSETS:
			var neighbor: Vector2i = point + offset
			if (
				neighbor.x < 0
				or neighbor.y < 0
				or neighbor.x >= image_size.x
				or neighbor.y >= image_size.y
			):
				continue
			var index := neighbor.y * image_size.x + neighbor.x
			if visited[index] != 0:
				continue
			visited[index] = 1
			pending.append(neighbor)

	return mask


static func _colors_match(
	color: Color,
	sample: Color,
	tolerance: float,
	include_alpha: bool
) -> bool:
	if (
		absf(color.r - sample.r) > tolerance
		or absf(color.g - sample.g) > tolerance
		or absf(color.b - sample.b) > tolerance
	):
		return false
	return not include_alpha or absf(color.a - sample.a) <= tolerance


static func _find_seed_polygon(
	polygons: Array[PackedVector2Array],
	seed_point: Vector2
) -> PackedVector2Array:
	for polygon in polygons:
		if Geometry2D.is_point_in_polygon(seed_point, polygon):
			return polygon

	var largest := PackedVector2Array()
	var largest_area := 0.0
	for polygon in polygons:
		var area := absf(_signed_area(polygon))
		if area > largest_area:
			largest_area = area
			largest = polygon
	return largest


static func _signed_area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	for index in polygon.size():
		var next_index := (index + 1) % polygon.size()
		area += (
			polygon[index].x * polygon[next_index].y
			- polygon[next_index].x * polygon[index].y
		)
	return area * 0.5
