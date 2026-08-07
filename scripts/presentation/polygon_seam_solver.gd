class_name PolygonSeamSolver
extends RefCounted


static func bind_point(point: Vector2, source_seam: PackedVector2Array) -> Vector2:
	if source_seam.size() < 2:
		return Vector2.ZERO
	var total_length := _seam_length(source_seam)
	if total_length <= 0.0001:
		return Vector2.ZERO
	var traveled := 0.0
	var best_distance_squared := INF
	var best_t := 0.0
	var best_normal_offset := 0.0
	for index in range(source_seam.size() - 1):
		var start := source_seam[index]
		var finish := source_seam[index + 1]
		var segment := finish - start
		var segment_length := segment.length()
		if segment_length <= 0.0001:
			continue
		var tangent := segment / segment_length
		var projection := clampf((point - start).dot(tangent) / segment_length, 0.0, 1.0)
		var closest := start + segment * projection
		var distance_squared := point.distance_squared_to(closest)
		if distance_squared < best_distance_squared:
			var normal := Vector2(-tangent.y, tangent.x)
			best_distance_squared = distance_squared
			best_t = (traveled + segment_length * projection) / total_length
			best_normal_offset = (point - closest).dot(normal)
		traveled += segment_length
	return Vector2(best_t, best_normal_offset)


static func resolve_binding(
	binding: Vector2,
	target_seam: PackedVector2Array,
	overlap: float
) -> Vector2:
	var sample := _sample_seam(target_seam, clampf(binding.x, 0.0, 1.0))
	var point: Vector2 = sample[0]
	var tangent: Vector2 = sample[1]
	var normal := Vector2(-tangent.y, tangent.x)
	return point + normal * (binding.y + overlap)


static func _sample_seam(seam: PackedVector2Array, normalized_distance: float) -> Array[Vector2]:
	if seam.size() < 2:
		return [Vector2.ZERO, Vector2.RIGHT]
	var total_length := _seam_length(seam)
	if total_length <= 0.0001:
		return [seam[0], Vector2.RIGHT]
	var target_distance := total_length * normalized_distance
	var traveled := 0.0
	for index in range(seam.size() - 1):
		var start := seam[index]
		var finish := seam[index + 1]
		var segment := finish - start
		var segment_length := segment.length()
		if segment_length <= 0.0001:
			continue
		if traveled + segment_length >= target_distance:
			var local_distance := target_distance - traveled
			var tangent := segment / segment_length
			return [start + tangent * local_distance, tangent]
		traveled += segment_length
	var final_segment := seam[seam.size() - 1] - seam[seam.size() - 2]
	return [seam[seam.size() - 1], final_segment.normalized()]


static func _seam_length(seam: PackedVector2Array) -> float:
	var total := 0.0
	for index in range(seam.size() - 1):
		total += seam[index].distance_to(seam[index + 1])
	return total
