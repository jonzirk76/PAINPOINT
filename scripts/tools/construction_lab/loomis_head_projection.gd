class_name LoomisHeadProjection
extends RefCounted

const BoxProjectionUtil := preload("res://scripts/tools/construction_lab/box_projection.gd")

const DEFAULT_SEGMENTS := 64


static func build_step3(spec: Dictionary) -> Dictionary:
	var radius: float = float(spec.get("radius", 1.0))
	var side_cut_ratio: float = float(spec.get("side_cut_ratio", 0.55))
	var rotation_degrees: Vector3 = spec.get("rotation_degrees", Vector3(0.0, 32.0, 0.0))
	var camera_distance: float = float(spec.get("camera_distance", 7.0))
	var focal_length: float = float(spec.get("focal_length", 430.0))
	var screen_center: Vector2 = spec.get("screen_center", Vector2.ZERO)
	var segment_count: int = int(spec.get("segments", DEFAULT_SEGMENTS))
	var nose_drop_ratio: float = float(spec.get("nose_drop_ratio", 0.68))
	var nose_forward_ratio: float = float(spec.get("nose_forward_ratio", 0.96))
	var chin_drop_ratio: float = float(spec.get("chin_drop_ratio", 1.42))
	var chin_forward_ratio: float = float(spec.get("chin_forward_ratio", 0.88))
	var basis := Basis.from_euler(Vector3(
		deg_to_rad(rotation_degrees.x),
		deg_to_rad(rotation_degrees.y),
		deg_to_rad(rotation_degrees.z)
	))

	var silhouette := _build_sphere_silhouette(
		radius,
		camera_distance,
		focal_length,
		screen_center,
		segment_count
	)
	var local_side_axis: Vector3 = basis * Vector3.RIGHT
	var side_sign := 1.0 if local_side_axis.z >= 0.0 else -1.0
	var cut_distance := radius * side_cut_ratio * side_sign
	var cut_radius := sqrt(maxf(radius * radius - cut_distance * cut_distance, 0.0))
	var jaw_hinge_drop_ratio: float = float(spec.get(
		"jaw_hinge_drop_ratio",
		cut_radius / maxf(radius, 0.0001)
	))
	var jaw_hinge_forward_ratio: float = float(spec.get("jaw_hinge_forward_ratio", 0.0))
	var side_plane_local: Array[Vector3] = []
	for index in range(segment_count):
		var angle := TAU * float(index) / float(segment_count)
		side_plane_local.append(Vector3(
			cut_distance,
			cos(angle) * cut_radius,
			sin(angle) * cut_radius
		))
	var side_plane := _project_local_curve(
		side_plane_local,
		basis,
		camera_distance,
		focal_length,
		screen_center,
		true
	)

	var vertical_midline_local: Array[Vector3] = []
	var brow_midline_local: Array[Vector3] = []
	for index in range(segment_count + 1):
		var angle := PI * float(index) / float(segment_count)
		vertical_midline_local.append(Vector3(0.0, cos(angle) * radius, sin(angle) * radius))
		brow_midline_local.append(Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))
	var vertical_midline := _project_local_curve(
		vertical_midline_local,
		basis,
		camera_distance,
		focal_length,
		screen_center,
		false
	)
	var brow_midline := _project_local_curve(
		brow_midline_local,
		basis,
		camera_distance,
		focal_length,
		screen_center,
		false
	)

	var side_center_local := Vector3(cut_distance, 0.0, 0.0)
	var side_vertical := _project_local_curve(
		[
			side_center_local + Vector3(0.0, -cut_radius, 0.0),
			side_center_local + Vector3(0.0, cut_radius, 0.0),
		],
		basis,
		camera_distance,
		focal_length,
		screen_center,
		false
	)
	var side_depth := _project_local_curve(
		[
			side_center_local + Vector3(0.0, 0.0, -cut_radius),
			side_center_local + Vector3(0.0, 0.0, cut_radius),
		],
		basis,
		camera_distance,
		focal_length,
		screen_center,
		false
	)

	var front_face_local: Array[Vector3] = [
		Vector3(-radius, -radius, radius),
		Vector3(radius, -radius, radius),
		Vector3(radius, radius, radius),
		Vector3(-radius, radius, radius),
	]
	var front_face_square := _project_local_curve(
		front_face_local,
		basis,
		camera_distance,
		focal_length,
		screen_center,
		true
	)
	var front_face_vertical := _project_local_curve(
		[Vector3(0.0, -radius, radius), Vector3(0.0, radius, radius)],
		basis,
		camera_distance,
		focal_length,
		screen_center,
		false
	)
	var front_face_horizontal := _project_local_curve(
		[Vector3(-radius, 0.0, radius), Vector3(radius, 0.0, radius)],
		basis,
		camera_distance,
		focal_length,
		screen_center,
		false
	)

	var face_guides := {
		"brow": _project_local_curve(
			[Vector3(-radius, 0.0, radius), Vector3(radius, 0.0, radius)],
			basis,
			camera_distance,
			focal_length,
			screen_center,
			false
		),
		"nose": _project_local_curve(
			[
				Vector3(-radius * 0.72, -radius * nose_drop_ratio, radius * nose_forward_ratio),
				Vector3(radius * 0.72, -radius * nose_drop_ratio, radius * nose_forward_ratio),
			],
			basis,
			camera_distance,
			focal_length,
			screen_center,
			false
		),
		"chin": _project_local_curve(
			[
				Vector3(-radius * 0.24, -radius * chin_drop_ratio, radius * chin_forward_ratio),
				Vector3(radius * 0.24, -radius * chin_drop_ratio, radius * chin_forward_ratio),
			],
			basis,
			camera_distance,
			focal_length,
			screen_center,
			false
		),
	}
	var front_center_local := Vector3(0.0, 0.0, radius)
	var nose_center_local := Vector3(0.0, -radius * nose_drop_ratio, radius * nose_forward_ratio)
	var chin_local := Vector3(0.0, -radius * chin_drop_ratio, radius * chin_forward_ratio)
	var jaw_hinge_local := Vector3(
		cut_distance,
		-radius * jaw_hinge_drop_ratio,
		radius * jaw_hinge_forward_ratio
	)
	var face_center_descent := _project_local_curve(
		[front_center_local, nose_center_local, chin_local],
		basis,
		camera_distance,
		focal_length,
		screen_center,
		false
	)
	var chin_point := _project_local_point(
		chin_local,
		basis,
		camera_distance,
		focal_length,
		screen_center
	)
	var jaw_hinge_point := _project_local_point(
		jaw_hinge_local,
		basis,
		camera_distance,
		focal_length,
		screen_center
	)
	var jawline := PackedVector2Array([jaw_hinge_point, chin_point])

	var cube_spec := {
		"size": Vector3.ONE * radius * 2.0,
		"rotation_degrees": rotation_degrees,
		"camera_distance": camera_distance,
		"focal_length": focal_length,
		"screen_center": screen_center,
	}
	var axis_guides := {}
	for axis_name: String in BoxProjectionUtil.AXIS_NAMES:
		var local_direction := {
			"x": Vector3.RIGHT,
			"y": Vector3.UP,
			"z": Vector3.BACK,
		}[axis_name] as Vector3
		axis_guides[axis_name] = _project_local_curve(
			[Vector3.ZERO, local_direction * radius * 1.35],
			basis,
			camera_distance,
			focal_length,
			screen_center,
			false
		)

	return {
		"spec": spec.duplicate(true),
		"basis": basis,
		"side_sign": side_sign,
		"side_cut_distance": cut_distance,
		"side_cut_radius": cut_radius,
		"sphere_silhouette": silhouette,
		"side_plane": side_plane,
		"side_vertical_axis": side_vertical,
		"side_depth_axis": side_depth,
		"vertical_midline": vertical_midline,
		"brow_midline": brow_midline,
		"front_face_square": front_face_square,
		"front_face_vertical_midline": front_face_vertical,
		"front_face_horizontal_midline": front_face_horizontal,
		"face_guides": face_guides,
		"face_center_descent": face_center_descent,
		"chin_point": chin_point,
		"jaw_hinge_point": jaw_hinge_point,
		"jawline": jawline,
		"jaw_profile": {
			"nose_drop_ratio": nose_drop_ratio,
			"nose_forward_ratio": nose_forward_ratio,
			"chin_drop_ratio": chin_drop_ratio,
			"chin_forward_ratio": chin_forward_ratio,
			"jaw_hinge_drop_ratio": jaw_hinge_drop_ratio,
			"jaw_hinge_forward_ratio": jaw_hinge_forward_ratio,
		},
		"front_center": _project_local_point(
			front_center_local,
			basis,
			camera_distance,
			focal_length,
			screen_center
		),
		"axis_guides": axis_guides,
		"compliance_cube": BoxProjectionUtil.project_box(cube_spec),
	}


static func build_default_tilt_batch() -> Array:
	var specs := [
		{
			"name": "Three Quarter Neutral",
			"rotation_degrees": Vector3(0.0, 32.0, 0.0),
			"camera_distance": 7.2,
			"focal_length": 450.0,
		},
		{
			"name": "Looking Up",
			"rotation_degrees": Vector3(-24.0, 28.0, -4.0),
			"camera_distance": 7.2,
			"focal_length": 450.0,
		},
		{
			"name": "Looking Down Left",
			"rotation_degrees": Vector3(24.0, -34.0, 8.0),
			"camera_distance": 7.2,
			"focal_length": 450.0,
		},
		{
			"name": "Rolled Three Quarter",
			"rotation_degrees": Vector3(-12.0, 42.0, 22.0),
			"camera_distance": 7.2,
			"focal_length": 450.0,
		},
	]
	var batch: Array = []
	for spec: Dictionary in specs:
		var full_spec := spec.duplicate(true)
		full_spec["radius"] = 1.0
		full_spec["side_cut_ratio"] = 0.55
		full_spec["screen_center"] = Vector2.ZERO
		full_spec["segments"] = DEFAULT_SEGMENTS
		full_spec["nose_drop_ratio"] = 0.68
		full_spec["nose_forward_ratio"] = 0.96
		full_spec["chin_drop_ratio"] = 1.42
		full_spec["chin_forward_ratio"] = 0.88
		full_spec["jaw_hinge_drop_ratio"] = sqrt(1.0 - 0.55 * 0.55)
		full_spec["jaw_hinge_forward_ratio"] = 0.0
		batch.append({
			"name": full_spec["name"],
			"construction": build_step3(full_spec),
		})
	return batch


static func _build_sphere_silhouette(
	radius: float,
	camera_distance: float,
	focal_length: float,
	screen_center: Vector2,
	segment_count: int
) -> PackedVector2Array:
	var contour_depth := radius * radius / camera_distance
	var contour_radius := radius * sqrt(maxf(1.0 - radius * radius / (camera_distance * camera_distance), 0.0))
	var projected := PackedVector2Array()
	for index in range(segment_count):
		var angle := TAU * float(index) / float(segment_count)
		projected.append(_project_world_point(
			Vector3(cos(angle) * contour_radius, sin(angle) * contour_radius, contour_depth),
			camera_distance,
			focal_length,
			screen_center
		))
	return projected


static func _project_local_curve(
	local_points: Array,
	basis: Basis,
	camera_distance: float,
	focal_length: float,
	screen_center: Vector2,
	close_curve: bool
) -> PackedVector2Array:
	var projected := PackedVector2Array()
	for local_point: Vector3 in local_points:
		projected.append(_project_local_point(
			local_point,
			basis,
			camera_distance,
			focal_length,
			screen_center
		))
	if close_curve and not projected.is_empty():
		projected.append(projected[0])
	return projected


static func _project_local_point(
	local_point: Vector3,
	basis: Basis,
	camera_distance: float,
	focal_length: float,
	screen_center: Vector2
) -> Vector2:
	return _project_world_point(
		basis * local_point,
		camera_distance,
		focal_length,
		screen_center
	)


static func _project_world_point(
	world_point: Vector3,
	camera_distance: float,
	focal_length: float,
	screen_center: Vector2
) -> Vector2:
	var depth := camera_distance - world_point.z
	assert(depth > 0.01, "Loomis construction crossed the camera plane.")
	return screen_center + Vector2(
		focal_length * world_point.x / depth,
		-focal_length * world_point.y / depth
	)
