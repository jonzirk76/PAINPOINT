extends SceneTree

const BoxProjectionUtil := preload("res://scripts/tools/construction_lab/box_projection.gd")
const OUTPUT_PATH := "res://docs/art_pipeline/box_construction_sample_batch.json"
const BATCH_SEED := 250


func _initialize() -> void:
	var batch := BoxProjectionUtil.build_default_batch(BATCH_SEED)
	var report := {
		"schema_version": 1,
		"seed": BATCH_SEED,
		"purpose": "Deterministic example output for the box construction scoring workflow.",
		"cases": [],
	}
	print("BOX CONSTRUCTION SAMPLE BATCH")
	for case_data: Dictionary in batch:
		var metrics: Dictionary = case_data["metrics"]
		var entry := {
			"name": case_data["name"],
			"noise_px": case_data["attempt"]["noise_px"],
			"score": snappedf(float(metrics["overall_score"]), 0.01),
			"rating": metrics["rating"],
			"corner_rmse_px": snappedf(float(metrics["corner_rmse_px"]), 0.01),
			"edge_angle_mean_deg": snappedf(float(metrics["edge_angle_mean_deg"]), 0.01),
			"axis_angle_mean_deg": _rounded_axis_metrics(metrics["axis_angle_mean_deg"]),
			"valid_faces": metrics["valid_faces"],
			"winding_matches": metrics["winding_matches"],
			"face_count": metrics["face_count"],
			"face_area_mean_relative_error": snappedf(
				float(metrics["face_area_mean_relative_error"]),
				0.0001
			),
		}
		report["cases"].append(entry)
		print(
			"  %s | score %.2f | corner %.2f px | convergence %.2f deg | faces %d/%d"
			% [
				entry["name"],
				entry["score"],
				entry["corner_rmse_px"],
				entry["edge_angle_mean_deg"],
				entry["valid_faces"],
				entry["face_count"],
			]
		)

	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write sample batch to %s (error %d)." % [OUTPUT_PATH, FileAccess.get_open_error()])
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("Wrote %s" % OUTPUT_PATH)
	quit(0)


func _rounded_axis_metrics(axis_metrics: Dictionary) -> Dictionary:
	var rounded := {}
	for axis_name: String in BoxProjectionUtil.AXIS_NAMES:
		rounded[axis_name] = snappedf(float(axis_metrics[axis_name]), 0.01)
	return rounded
