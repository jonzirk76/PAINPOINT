class_name BoxProjection
extends RefCounted

## Deterministic perspective projection and scoring helpers for the 2D
## construction lab. The camera sits on +Z and looks toward the origin.

const AXIS_NAMES := ["x", "y", "z"]
const AXIS_EDGE_INDICES := {
	"x": [[0, 1], [2, 3], [4, 5], [6, 7]],
	"y": [[0, 2], [1, 3], [4, 6], [5, 7]],
	"z": [[0, 4], [1, 5], [2, 6], [3, 7]],
}
const FACE_INDICES := {
	"x_near": [1, 3, 7, 5],
	"x_far": [0, 4, 6, 2],
	"y_near": [2, 6, 7, 3],
	"y_far": [0, 1, 5, 4],
	"z_near": [4, 5, 7, 6],
	"z_far": [0, 2, 3, 1],
}


static func project_box(spec: Dictionary) -> Dictionary:
	var size: Vector3 = spec.get("size", Vector3(2.4, 1.8, 2.0))
	var rotation_degrees: Vector3 = spec.get("rotation_degrees", Vector3(18.0, 32.0, 7.0))
	var camera_distance: float = float(spec.get("camera_distance", 7.0))
	var focal_length: float = float(spec.get("focal_length", 430.0))
	var screen_center: Vector2 = spec.get("screen_center", Vector2.ZERO)
	var basis := Basis.from_euler(Vector3(
		deg_to_rad(rotation_degrees.x),
		deg_to_rad(rotation_degrees.y),
		deg_to_rad(rotation_degrees.z)
	))
	var corners_3d: Array[Vector3] = []
	var corners_2d: Array[Vector2] = []
	var depths: Array[float] = []

	for z_bit in range(2):
		for y_bit in range(2):
			for x_bit in range(2):
				var local_corner := Vector3(
					(-0.5 if x_bit == 0 else 0.5) * size.x,
					(-0.5 if y_bit == 0 else 0.5) * size.y,
					(-0.5 if z_bit == 0 else 0.5) * size.z
				)
				var rotated := basis * local_corner
				var depth := camera_distance - rotated.z
				assert(depth > 0.01, "Construction box crossed the camera plane.")
				corners_3d.append(rotated)
				depths.append(depth)
				corners_2d.append(screen_center + Vector2(
					focal_length * rotated.x / depth,
					-focal_length * rotated.y / depth
				))

	return {
		"spec": spec.duplicate(true),
		"basis": basis,
		"corners_3d": corners_3d,
		"corners": corners_2d,
		"depths": depths,
		"edges": _build_edges(corners_2d),
		"faces": _build_faces(corners_2d, depths),
		"vanishing_points": _build_vanishing_points(basis, focal_length, screen_center),
	}


static func build_attempt(projection: Dictionary, noise_px: float, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var attempted_corners: Array[Vector2] = []
	for corner: Vector2 in projection["corners"]:
		var unit_offset := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		attempted_corners.append(corner + unit_offset * noise_px)

	return {
		"noise_px": noise_px,
		"seed": seed_value,
		"corners": attempted_corners,
		"edges": _build_edges(attempted_corners),
		"faces": _build_faces(attempted_corners, projection["depths"]),
	}


static func score_attempt(projection: Dictionary, attempt: Dictionary) -> Dictionary:
	var ground_corners: Array = projection["corners"]
	var attempted_corners: Array = attempt["corners"]
	var squared_error := 0.0
	for index in range(ground_corners.size()):
		squared_error += ground_corners[index].distance_squared_to(attempted_corners[index])
	var corner_rmse_px := sqrt(squared_error / maxf(1.0, float(ground_corners.size())))

	var axis_angle_errors := {}
	var all_angle_errors: Array[float] = []
	for axis_name: String in AXIS_NAMES:
		var per_axis: Array[float] = []
		for pair: Array in AXIS_EDGE_INDICES[axis_name]:
			var ground_direction: Vector2 = ground_corners[pair[1]] - ground_corners[pair[0]]
			var attempt_direction: Vector2 = attempted_corners[pair[1]] - attempted_corners[pair[0]]
			var angle_error := absf(rad_to_deg(ground_direction.angle_to(attempt_direction)))
			per_axis.append(angle_error)
			all_angle_errors.append(angle_error)
		axis_angle_errors[axis_name] = _mean(per_axis)
	var edge_angle_mean_deg := _mean(all_angle_errors)

	var valid_faces := 0
	var winding_matches := 0
	var relative_area_errors: Array[float] = []
	for face_name: String in FACE_INDICES:
		var indices: Array = FACE_INDICES[face_name]
		var ground_face := _points_for_indices(ground_corners, indices)
		var attempt_face := _points_for_indices(attempted_corners, indices)
		var ground_area := _signed_area(ground_face)
		var attempt_area := _signed_area(attempt_face)
		if absf(attempt_area) >= 4.0 and _is_convex(attempt_face):
			valid_faces += 1
		if signf(ground_area) == signf(attempt_area):
			winding_matches += 1
		relative_area_errors.append(
			absf(absf(attempt_area) - absf(ground_area)) / maxf(absf(ground_area), 1.0)
		)

	var face_count := float(FACE_INDICES.size())
	var topology_ratio := (float(valid_faces) + float(winding_matches)) / (face_count * 2.0)
	var face_area_mean_relative_error := _mean(relative_area_errors)
	var corner_component := clampf(1.0 - corner_rmse_px / 18.0, 0.0, 1.0)
	var convergence_component := clampf(1.0 - edge_angle_mean_deg / 6.0, 0.0, 1.0)
	var face_area_component := clampf(1.0 - face_area_mean_relative_error / 0.35, 0.0, 1.0)
	var overall_score := 100.0 * (
		corner_component * 0.40
		+ convergence_component * 0.35
		+ topology_ratio * 0.15
		+ face_area_component * 0.10
	)

	return {
		"overall_score": overall_score,
		"rating": _rating_for_score(overall_score),
		"corner_rmse_px": corner_rmse_px,
		"edge_angle_mean_deg": edge_angle_mean_deg,
		"axis_angle_mean_deg": axis_angle_errors,
		"valid_faces": valid_faces,
		"winding_matches": winding_matches,
		"face_count": int(face_count),
		"face_area_mean_relative_error": face_area_mean_relative_error,
		"components": {
			"corner": corner_component,
			"convergence": convergence_component,
			"topology": topology_ratio,
			"face_area": face_area_component,
		},
	}


static func build_default_batch(seed_value: int = 250) -> Array:
	var specs := [
		{
			"name": "Calibration",
			"size": Vector3(2.4, 1.8, 2.0),
			"rotation_degrees": Vector3(14.0, 27.0, 4.0),
			"camera_distance": 7.2,
			"focal_length": 430.0,
			"screen_center": Vector2.ZERO,
			"noise_px": 0.0,
		},
		{
			"name": "Shallow turn",
			"size": Vector3(2.6, 1.6, 1.7),
			"rotation_degrees": Vector3(-8.0, 43.0, -5.0),
			"camera_distance": 8.2,
			"focal_length": 470.0,
			"screen_center": Vector2.ZERO,
			"noise_px": 3.0,
		},
		{
			"name": "Tilt and roll",
			"size": Vector3(2.0, 2.4, 1.8),
			"rotation_degrees": Vector3(31.0, -28.0, 17.0),
			"camera_distance": 7.5,
			"focal_length": 440.0,
			"screen_center": Vector2.ZERO,
			"noise_px": 7.0,
		},
		{
			"name": "Dramatic",
			"size": Vector3(2.8, 1.7, 2.5),
			"rotation_degrees": Vector3(-24.0, 58.0, 13.0),
			"camera_distance": 5.8,
			"focal_length": 390.0,
			"screen_center": Vector2.ZERO,
			"noise_px": 12.0,
		},
	]
	var batch: Array = []
	for index in range(specs.size()):
		var spec: Dictionary = specs[index]
		var projection := project_box(spec)
		var attempt := build_attempt(projection, float(spec["noise_px"]), seed_value + index * 977)
		batch.append({
			"name": spec["name"],
			"projection": projection,
			"attempt": attempt,
			"metrics": score_attempt(projection, attempt),
		})
	return batch


static func point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var direction := line_end - line_start
	if direction.length_squared() <= 0.000001:
		return point.distance_to(line_start)
	return absf(direction.cross(point - line_start)) / direction.length()


static func _build_edges(corners: Array) -> Dictionary:
	var edges := {}
	for axis_name: String in AXIS_NAMES:
		var axis_edges: Array = []
		for pair: Array in AXIS_EDGE_INDICES[axis_name]:
			axis_edges.append({
				"indices": pair.duplicate(),
				"a": corners[pair[0]],
				"b": corners[pair[1]],
			})
		edges[axis_name] = axis_edges
	return edges


static func _build_faces(corners: Array, depths: Array) -> Array:
	var faces: Array = []
	for face_name: String in FACE_INDICES:
		var indices: Array = FACE_INDICES[face_name]
		var average_depth := 0.0
		for index: int in indices:
			average_depth += float(depths[index])
		average_depth /= float(indices.size())
		faces.append({
			"name": face_name,
			"indices": indices.duplicate(),
			"points": _points_for_indices(corners, indices),
			"average_depth": average_depth,
		})
	faces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["average_depth"]) > float(b["average_depth"])
	)
	return faces


static func _build_vanishing_points(basis: Basis, focal_length: float, screen_center: Vector2) -> Dictionary:
	var points := {}
	var directions := {
		"x": basis * Vector3.RIGHT,
		"y": basis * Vector3.UP,
		"z": basis * Vector3.BACK,
	}
	for axis_name: String in AXIS_NAMES:
		var direction: Vector3 = directions[axis_name]
		if absf(direction.z) <= 0.00001:
			points[axis_name] = null
		else:
			points[axis_name] = screen_center + Vector2(
				-focal_length * direction.x / direction.z,
				focal_length * direction.y / direction.z
			)
	return points


static func _points_for_indices(corners: Array, indices: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in indices:
		points.append(corners[index])
	return points


static func _signed_area(points: PackedVector2Array) -> float:
	var area := 0.0
	for index in range(points.size()):
		area += points[index].cross(points[(index + 1) % points.size()])
	return area * 0.5


static func _is_convex(points: PackedVector2Array) -> bool:
	if points.size() < 3:
		return false
	var turn_sign := 0.0
	for index in range(points.size()):
		var edge_a := points[(index + 1) % points.size()] - points[index]
		var edge_b := points[(index + 2) % points.size()] - points[(index + 1) % points.size()]
		var cross := edge_a.cross(edge_b)
		if absf(cross) <= 0.001:
			continue
		if is_zero_approx(turn_sign):
			turn_sign = signf(cross)
		elif signf(cross) != turn_sign:
			return false
	return not is_zero_approx(turn_sign)


static func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value: float in values:
		total += value
	return total / float(values.size())


static func _rating_for_score(score: float) -> String:
	if score >= 90.0:
		return "ready"
	if score >= 75.0:
		return "solid"
	if score >= 60.0:
		return "review"
	return "rebuild"
