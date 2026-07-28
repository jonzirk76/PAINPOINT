extends SceneTree

const BoxProjectionUtil := preload("res://scripts/tools/construction_lab/box_projection.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var spec := {
		"name": "Targeted validation",
		"size": Vector3(2.4, 1.8, 2.0),
		"rotation_degrees": Vector3(21.0, 37.0, 9.0),
		"camera_distance": 7.0,
		"focal_length": 430.0,
		"screen_center": Vector2.ZERO,
	}
	var projection := BoxProjectionUtil.project_box(spec)
	_expect(projection["corners"].size() == 8, "A cuboid must project eight corners.")
	_expect(_edge_count(projection["edges"]) == 12, "A cuboid must expose twelve edges.")
	_expect(projection["faces"].size() == 6, "A cuboid must expose six faces.")
	_validate_vanishing_points(projection)

	var perfect := BoxProjectionUtil.build_attempt(projection, 0.0, 42)
	var perfect_metrics := BoxProjectionUtil.score_attempt(projection, perfect)
	_expect(is_equal_approx(float(perfect_metrics["overall_score"]), 100.0), "Zero-noise projection must score 100.")
	_expect(is_zero_approx(float(perfect_metrics["corner_rmse_px"])), "Zero-noise corner RMSE must be zero.")
	_expect(int(perfect_metrics["valid_faces"]) == 6, "Zero-noise projection must retain all faces.")

	var moderate := BoxProjectionUtil.build_attempt(projection, 7.0, 42)
	var moderate_metrics := BoxProjectionUtil.score_attempt(projection, moderate)
	_expect(float(moderate_metrics["corner_rmse_px"]) > 0.0, "Noisy reconstruction must produce corner error.")
	_expect(
		float(moderate_metrics["overall_score"]) < float(perfect_metrics["overall_score"]),
		"Noisy reconstruction must score below ground truth."
	)
	_expect(
		float(moderate_metrics["edge_angle_mean_deg"]) > 0.0,
		"Noisy reconstruction must produce convergence error."
	)

	if _failures.is_empty():
		print("BOX CONSTRUCTION LAB TEST: PASS")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("BOX CONSTRUCTION LAB TEST: FAIL (%d)" % _failures.size())
	quit(1)


func _validate_vanishing_points(projection: Dictionary) -> void:
	for axis_name: String in BoxProjectionUtil.AXIS_NAMES:
		var vanishing_point: Variant = projection["vanishing_points"][axis_name]
		_expect(vanishing_point != null, "Validation pose must have a finite %s vanishing point." % axis_name)
		if vanishing_point == null:
			continue
		for edge: Dictionary in projection["edges"][axis_name]:
			var residual := BoxProjectionUtil.point_to_line_distance(vanishing_point, edge["a"], edge["b"])
			_expect(
				residual < 0.01,
				"Projected %s edge must pass through its vanishing point (residual %.4f)." % [axis_name, residual]
			)


func _edge_count(edges: Dictionary) -> int:
	var total := 0
	for axis_name: String in BoxProjectionUtil.AXIS_NAMES:
		total += edges[axis_name].size()
	return total


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
