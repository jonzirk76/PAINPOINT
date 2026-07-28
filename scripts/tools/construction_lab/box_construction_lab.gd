extends Node2D

const BoxProjectionUtil := preload("res://scripts/tools/construction_lab/box_projection.gd")

const AXIS_COLORS := {
	"x": Color("#ef6a69"),
	"y": Color("#66c88a"),
	"z": Color("#62a8ef"),
}
const FACE_COLORS := [
	Color(0.38, 0.58, 0.86, 0.12),
	Color(0.72, 0.46, 0.82, 0.10),
	Color(0.35, 0.76, 0.66, 0.10),
	Color(0.91, 0.63, 0.35, 0.09),
	Color(0.50, 0.67, 0.92, 0.08),
	Color(0.84, 0.48, 0.58, 0.08),
]

## [Description] Seed used for deterministic reconstruction offsets.
@export var batch_seed: int = 250
## [Description] Shows the exact projected faces and edges behind each attempt.
@export var show_ground_truth: bool = true
## [Description] Extends attempted edge families to make convergence drift visible.
@export var show_line_extensions: bool = true
## [Description] Length in pixels added to both ends of diagnostic edge extensions.
@export_range(20.0, 240.0, 1.0) var extension_length: float = 72.0

var _batch: Array = []
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	_batch = BoxProjectionUtil.build_default_batch(batch_seed)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		batch_seed += 1
		_batch = BoxProjectionUtil.build_default_batch(batch_seed)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color("#111723"))
	draw_string(_font, Vector2(28.0, 34.0), "BOX CONSTRUCTION LAB", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color("#e8edf6"))
	draw_string(
		_font,
		Vector2(28.0, 57.0),
		"Ground truth fill + white cage | attempted X / Y / Z edges | faint line extensions | Space: new deterministic offsets",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		15,
		Color("#aeb9ca")
	)

	var panel_size := Vector2(602.0, 300.0)
	for index in range(_batch.size()):
		var column := index % 2
		var row := index / 2
		var panel := Rect2(Vector2(28.0 + column * 622.0, 76.0 + row * 316.0), panel_size)
		_draw_case(panel, _batch[index], index)


func _draw_case(panel: Rect2, case_data: Dictionary, case_index: int) -> void:
	draw_rect(panel, Color("#192231"), true)
	draw_rect(panel, Color("#344258"), false, 1.5)
	var metrics: Dictionary = case_data["metrics"]
	var title := "%d. %s  |  noise %.1f px  |  score %.1f (%s)" % [
		case_index + 1,
		case_data["name"],
		float(case_data["attempt"]["noise_px"]),
		float(metrics["overall_score"]),
		metrics["rating"],
	]
	draw_string(_font, panel.position + Vector2(14.0, 25.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color("#f1f4f8"))

	var origin := panel.get_center() + Vector2(0.0, 8.0)
	var projection: Dictionary = case_data["projection"]
	var attempt: Dictionary = case_data["attempt"]
	if show_ground_truth:
		_draw_ground_truth(origin, projection)
	if show_line_extensions:
		_draw_extensions(origin, attempt)
	_draw_attempt(origin, attempt)

	var summary := "corner RMSE %.2f px   convergence %.2f deg   faces %d/%d   area err %.1f%%" % [
		float(metrics["corner_rmse_px"]),
		float(metrics["edge_angle_mean_deg"]),
		int(metrics["valid_faces"]),
		int(metrics["face_count"]),
		float(metrics["face_area_mean_relative_error"]) * 100.0,
	]
	draw_string(
		_font,
		panel.position + Vector2(14.0, panel.size.y - 14.0),
		summary,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		14,
		Color("#b9c4d5")
	)


func _draw_ground_truth(origin: Vector2, projection: Dictionary) -> void:
	var face_index := 0
	for face: Dictionary in projection["faces"]:
		var points := _translated_points(face["points"], origin)
		draw_colored_polygon(points, FACE_COLORS[face_index % FACE_COLORS.size()])
		face_index += 1
	for axis_name: String in BoxProjectionUtil.AXIS_NAMES:
		for edge: Dictionary in projection["edges"][axis_name]:
			draw_line(origin + edge["a"], origin + edge["b"], Color(0.92, 0.95, 1.0, 0.34), 2.0, true)


func _draw_extensions(origin: Vector2, attempt: Dictionary) -> void:
	for axis_name: String in BoxProjectionUtil.AXIS_NAMES:
		var color: Color = AXIS_COLORS[axis_name]
		color.a = 0.16
		for edge: Dictionary in attempt["edges"][axis_name]:
			var direction: Vector2 = (edge["b"] - edge["a"]).normalized()
			draw_line(
				origin + edge["a"] - direction * extension_length,
				origin + edge["b"] + direction * extension_length,
				color,
				1.0,
				true
			)


func _draw_attempt(origin: Vector2, attempt: Dictionary) -> void:
	for axis_name: String in BoxProjectionUtil.AXIS_NAMES:
		var color: Color = AXIS_COLORS[axis_name]
		for edge: Dictionary in attempt["edges"][axis_name]:
			draw_line(origin + edge["a"], origin + edge["b"], color, 2.6, true)
	for corner: Vector2 in attempt["corners"]:
		draw_circle(origin + corner, 3.2, Color("#f7f9fc"))


func _translated_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var translated := PackedVector2Array()
	for point: Vector2 in points:
		translated.append(point + offset)
	return translated
