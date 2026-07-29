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
	var cranium_radii: Vector3 = spec.get(
		"cranium_radii",
		Vector3(radius * 0.94, radius, radius * 1.10)
	)
	var cranium_center := Vector3(0.0, radius * 0.02, -radius * 0.08)
	var basis := Basis.from_euler(Vector3(
		deg_to_rad(rotation_degrees.x),
		deg_to_rad(rotation_degrees.y),
		deg_to_rad(rotation_degrees.z)
	))

	var silhouette := _build_ellipsoid_silhouette(
		cranium_center,
		cranium_radii,
		basis,
		camera_distance,
		focal_length,
		screen_center,
		segment_count
	)
	var local_side_axis: Vector3 = basis * Vector3.RIGHT
	var side_sign := 1.0 if local_side_axis.z >= 0.0 else -1.0
	var cut_distance := cranium_radii.x * side_cut_ratio * side_sign
	var cut_scale := sqrt(maxf(
		1.0 - (cut_distance * cut_distance) / (cranium_radii.x * cranium_radii.x),
		0.0
	))
	var cut_radius_y := cranium_radii.y * cut_scale
	var cut_radius_z := cranium_radii.z * cut_scale
	var cut_radius := (cut_radius_y + cut_radius_z) * 0.5
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
			cranium_center.y + cos(angle) * cut_radius_y,
			cranium_center.z + sin(angle) * cut_radius_z
		))
	var side_plane := _project_local_curve(
		side_plane_local,
		basis,
		camera_distance,
		focal_length,
		screen_center,
		true
	)
	var far_cut_distance := -cut_distance
	var far_side_plane_local: Array[Vector3] = []
	for index in range(segment_count):
		var angle := TAU * float(index) / float(segment_count)
		far_side_plane_local.append(Vector3(
			far_cut_distance,
			cranium_center.y + cos(angle) * cut_radius_y,
			cranium_center.z + sin(angle) * cut_radius_z
		))
	var far_side_plane := _project_local_curve(
		far_side_plane_local,
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
		vertical_midline_local.append(cranium_center + Vector3(
			0.0,
			cos(angle) * cranium_radii.y,
			sin(angle) * cranium_radii.z
		))
		brow_midline_local.append(cranium_center + Vector3(
			cos(angle) * cranium_radii.x,
			0.0,
			sin(angle) * cranium_radii.z
		))
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

	var side_center_local := cranium_center + Vector3(cut_distance, 0.0, 0.0)
	var side_vertical := _project_local_curve(
		[
			side_center_local + Vector3(0.0, -cut_radius_y, 0.0),
			side_center_local + Vector3(0.0, cut_radius_y, 0.0),
		],
		basis,
		camera_distance,
		focal_length,
		screen_center,
		false
	)
	var side_depth := _project_local_curve(
		[
			side_center_local + Vector3(0.0, 0.0, -cut_radius_z),
			side_center_local + Vector3(0.0, 0.0, cut_radius_z),
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
	var chin_half_width := radius * 0.24
	var near_chin_local := Vector3(chin_half_width * side_sign, chin_local.y, chin_local.z)
	var far_chin_local := Vector3(-chin_half_width * side_sign, chin_local.y, chin_local.z)
	var jaw_hinge_local := Vector3(
		cut_distance,
		-radius * jaw_hinge_drop_ratio,
		radius * jaw_hinge_forward_ratio
	)
	var far_jaw_hinge_local := Vector3(
		far_cut_distance,
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
	var far_jaw_hinge_point := _project_local_point(
		far_jaw_hinge_local, basis, camera_distance, focal_length, screen_center
	)
	var near_chin_point := _project_local_point(
		near_chin_local, basis, camera_distance, focal_length, screen_center
	)
	var far_chin_point := _project_local_point(
		far_chin_local, basis, camera_distance, focal_length, screen_center
	)
	var jawline := PackedVector2Array([jaw_hinge_point, near_chin_point])
	var far_jawline := PackedVector2Array([far_jaw_hinge_point, far_chin_point])
	var brow_anchor_x := absf(cut_distance)
	var facial_plane := _project_local_curve(
		[
			Vector3(-brow_anchor_x, 0.0, cut_radius),
			Vector3(brow_anchor_x, 0.0, cut_radius),
			Vector3(chin_half_width, chin_local.y, chin_local.z),
			Vector3(-chin_half_width, chin_local.y, chin_local.z),
		],
		basis, camera_distance, focal_length, screen_center, true
	)
	var eye_center_y := -radius * nose_drop_ratio * 0.5
	var eye_center_z := lerpf(radius, radius * nose_forward_ratio, 0.5)
	var eye_half_span := radius * 0.15
	var eye_inner_half_span := eye_half_span * 0.62
	var eye_center_x_offset := brow_anchor_x * 0.48
	var cavity_inner_y := -radius * nose_drop_ratio * 0.24
	var cavity_inner_z := lerpf(radius, radius * nose_forward_ratio, 0.24) - radius * 0.12
	var eye_cavity_planes: Array[PackedVector2Array] = []
	for eye_sign: float in [-1.0, 1.0]:
		var eye_center_x := eye_sign * eye_center_x_offset
		var brow_left_x := eye_center_x - eye_half_span
		var brow_right_x := eye_center_x + eye_half_span
		var brow_left_z := sqrt(maxf(radius * radius - brow_left_x * brow_left_x, 0.0))
		var brow_right_z := sqrt(maxf(radius * radius - brow_right_x * brow_right_x, 0.0))
		eye_cavity_planes.append(_project_local_curve(
			[
				Vector3(brow_left_x, 0.0, brow_left_z),
				Vector3(brow_right_x, 0.0, brow_right_z),
				Vector3(eye_center_x + eye_inner_half_span, cavity_inner_y, cavity_inner_z),
				Vector3(eye_center_x - eye_inner_half_span, cavity_inner_y, cavity_inner_z),
			],
			basis, camera_distance, focal_length, screen_center, true
		))
		eye_cavity_planes.append(_project_local_curve(
			[
				Vector3(eye_center_x - eye_inner_half_span, cavity_inner_y, cavity_inner_z),
				Vector3(eye_center_x + eye_inner_half_span, cavity_inner_y, cavity_inner_z),
				Vector3(eye_center_x + eye_half_span, eye_center_y, eye_center_z),
				Vector3(eye_center_x - eye_half_span, eye_center_y, eye_center_z),
			],
			basis, camera_distance, focal_length, screen_center, true
		))
	var nose_top_y := -radius * nose_drop_ratio * 0.25
	var nose_top_z := lerpf(radius, radius * nose_forward_ratio, 0.25)
	var nose_half_width := radius * 0.18
	var nose_block := _project_local_curve(
		[
			Vector3(0.0, nose_top_y, nose_top_z),
			Vector3(nose_half_width, nose_center_local.y, nose_center_local.z),
			Vector3(-nose_half_width, nose_center_local.y, nose_center_local.z),
		],
		basis, camera_distance, focal_length, screen_center, true
	)
	var mouth_bottom_y := lerpf(nose_center_local.y, chin_local.y, 0.5)
	var mouth_bottom_z := lerpf(nose_center_local.z, chin_local.z, 0.5)
	var mouth_bottom_guide := _project_local_curve(
		[
			Vector3(-radius * 0.22, mouth_bottom_y, mouth_bottom_z),
			Vector3(radius * 0.22, mouth_bottom_y, mouth_bottom_z),
		],
		basis, camera_distance, focal_length, screen_center, false
	)
	var eye_radius := radius * float(spec.get("eye_radius_ratio", 0.22))
	var primitive_eye_center_x := radius * float(spec.get("eye_center_x_ratio", 0.37))
	var brow_tangent_z := cranium_center.z + cranium_radii.z
	var primitive_eye_center_z := brow_tangent_z - eye_radius
	var primitive_eye_center_y := -radius * float(spec.get("eye_center_drop_ratio", 0.30))
	var eye_spheres: Array[PackedVector2Array] = []
	var eye_centers: Array[Vector2] = []
	for eye_sign: float in [-1.0, 1.0]:
		var eye_center := Vector3(
			eye_sign * primitive_eye_center_x,
			primitive_eye_center_y,
			primitive_eye_center_z
		)
		eye_spheres.append(_build_ellipsoid_silhouette(
			eye_center,
			Vector3.ONE * eye_radius,
			basis,
			camera_distance,
			focal_length,
			screen_center,
			maxi(16, segment_count / 2)
		))
		eye_centers.append(_project_local_point(
			eye_center,
			basis,
			camera_distance,
			focal_length,
			screen_center
		))
	var brow_tangent_plane := _project_local_curve(
		[
			Vector3(-radius * 0.72, radius * 0.12, brow_tangent_z),
			Vector3(radius * 0.72, radius * 0.12, brow_tangent_z),
			Vector3(radius * 0.72, -radius * 0.48, brow_tangent_z),
			Vector3(-radius * 0.72, -radius * 0.48, brow_tangent_z),
		],
		basis, camera_distance, focal_length, screen_center, true
	)
	var teeth_center := Vector3(0.0, -radius * 0.93, radius * 0.78)
	var teeth_cylinder := _build_x_cylinder_silhouette(
		teeth_center,
		radius * 0.43,
		radius * 0.22,
		radius * 0.25,
		basis,
		camera_distance,
		focal_length,
		screen_center,
		maxi(16, segment_count / 2)
	)
	var teeth_axis := _project_local_curve(
		[
			teeth_center - Vector3(radius * 0.43, 0.0, 0.0),
			teeth_center + Vector3(radius * 0.43, 0.0, 0.0),
		],
		basis, camera_distance, focal_length, screen_center, false
	)
	var foramen_center := Vector3(0.0, -radius * 0.91, -radius * 0.28)
	var neck_end := foramen_center + Vector3(0.0, -radius * 0.94, radius * 0.10)
	var neck_cylinder := _build_y_cylinder_silhouette(
		foramen_center,
		neck_end,
		radius * 0.34,
		radius * 0.30,
		basis,
		camera_distance,
		focal_length,
		screen_center,
		maxi(16, segment_count / 2)
	)
	var neck_axis := _project_local_curve(
		[foramen_center, neck_end],
		basis, camera_distance, focal_length, screen_center, false
	)
	var foramen_ellipse := _project_local_curve(
		_build_xz_ellipse(foramen_center, radius * 0.25, radius * 0.19, segment_count),
		basis, camera_distance, focal_length, screen_center, true
	)

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
		"cranium_radii": cranium_radii,
		"sphere_silhouette": silhouette,
		"side_plane": side_plane,
		"far_side_plane": far_side_plane,
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
		"near_chin_point": near_chin_point,
		"far_chin_point": far_chin_point,
		"jaw_hinge_point": jaw_hinge_point,
		"far_jaw_hinge_point": far_jaw_hinge_point,
		"jawline": jawline,
		"far_jawline": far_jawline,
		"facial_plane": facial_plane,
		"eye_cavity_planes": eye_cavity_planes,
		"nose_block": nose_block,
		"mouth_bottom_guide": mouth_bottom_guide,
		"eye_spheres": eye_spheres,
		"eye_centers": eye_centers,
		"brow_tangent_plane": brow_tangent_plane,
		"teeth_cylinder": teeth_cylinder,
		"teeth_axis": teeth_axis,
		"neck_cylinder": neck_cylinder,
		"neck_axis": neck_axis,
		"foramen_ellipse": foramen_ellipse,
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
		full_spec["cranium_radii"] = Vector3(0.94, 1.0, 1.10)
		full_spec["eye_radius_ratio"] = 0.22
		full_spec["eye_center_x_ratio"] = 0.37
		full_spec["eye_center_drop_ratio"] = 0.30
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


static func _build_ellipsoid_silhouette(
	center: Vector3,
	radii: Vector3,
	basis: Basis,
	camera_distance: float,
	focal_length: float,
	screen_center: Vector2,
	segment_count: int
) -> PackedVector2Array:
	var samples := PackedVector2Array()
	var latitude_count := maxi(8, segment_count / 2)
	for latitude_index in range(latitude_count + 1):
		var latitude := -PI * 0.5 + PI * float(latitude_index) / float(latitude_count)
		var latitude_radius := cos(latitude)
		for longitude_index in range(segment_count):
			var longitude := TAU * float(longitude_index) / float(segment_count)
			var local_point := center + Vector3(
				cos(longitude) * latitude_radius * radii.x,
				sin(latitude) * radii.y,
				sin(longitude) * latitude_radius * radii.z
			)
			samples.append(_project_local_point(
				local_point,
				basis,
				camera_distance,
				focal_length,
				screen_center
			))
	return Geometry2D.convex_hull(samples)


static func _build_x_cylinder_silhouette(
	center: Vector3,
	half_length: float,
	radius_y: float,
	radius_z: float,
	basis: Basis,
	camera_distance: float,
	focal_length: float,
	screen_center: Vector2,
	segment_count: int
) -> PackedVector2Array:
	var samples := PackedVector2Array()
	for x_sign: float in [-1.0, 1.0]:
		for index in range(segment_count):
			var angle := TAU * float(index) / float(segment_count)
			samples.append(_project_local_point(
				center + Vector3(
					x_sign * half_length,
					cos(angle) * radius_y,
					sin(angle) * radius_z
				),
				basis,
				camera_distance,
				focal_length,
				screen_center
			))
	return Geometry2D.convex_hull(samples)


static func _build_y_cylinder_silhouette(
	start_center: Vector3,
	end_center: Vector3,
	radius_x: float,
	radius_z: float,
	basis: Basis,
	camera_distance: float,
	focal_length: float,
	screen_center: Vector2,
	segment_count: int
) -> PackedVector2Array:
	var samples := PackedVector2Array()
	for center: Vector3 in [start_center, end_center]:
		for index in range(segment_count):
			var angle := TAU * float(index) / float(segment_count)
			samples.append(_project_local_point(
				center + Vector3(
					cos(angle) * radius_x,
					0.0,
					sin(angle) * radius_z
				),
				basis,
				camera_distance,
				focal_length,
				screen_center
			))
	return Geometry2D.convex_hull(samples)


static func _build_xz_ellipse(
	center: Vector3,
	radius_x: float,
	radius_z: float,
	segment_count: int
) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for index in range(segment_count):
		var angle := TAU * float(index) / float(segment_count)
		points.append(center + Vector3(
			cos(angle) * radius_x,
			0.0,
			sin(angle) * radius_z
		))
	return points


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
