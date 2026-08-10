@tool
extends Control
class_name NativeHeadWorkbench

const VIEW_FRONT := "front"
const VIEW_SIDE_LEFT := "side_left"
const VIEW_SIDE_RIGHT := "side_right"
const VIEW_SIDE := VIEW_SIDE_LEFT
const VIEW_SIDE_LEGACY := "side"
const VIEW_BACK := "back"
const SKIN_FILL := Color(0.982, 0.798, 0.681, 1.0)
const SKIN_LIGHT := Color(1.0, 0.925, 0.851, 1.0)
const SKIN_SHADOW := Color(0.64, 0.28, 0.18, 0.22)
const OUTLINE := Color(0.02, 0.02, 0.025, 1.0)
const EYE_FILL := Color(0.94, 0.95, 1.0, 1.0)
const EYE_PUPIL := Color(0.38, 0.12, 0.68, 1.0)
const HAIR_FILL := Color(0.42, 0.161, 0.761, 1.0)
const HAIR_SHADOW := Color(0.16, 0.04, 0.3, 1.0)
const HAIR_HIGHLIGHT := Color(0.78, 0.48, 1.0, 0.82)
const LAYER_NECK := "neck"
const LAYER_BACK_HAIR := "back_hair"
const LAYER_EARS := "ears"
const LAYER_HEAD := "head"
const LAYER_EYES := "eyes"
const LAYER_MOUTH := "mouth"
const LAYER_SCALP := "scalp"
const LAYER_SIDEBURNS := "sideburns"
const LAYER_BANGS := "bangs"
const HAIR_LAYERS := [
	LAYER_BACK_HAIR,
	LAYER_SCALP,
	LAYER_SIDEBURNS,
	LAYER_BANGS,
]
const SIDE_ONLY_PROPERTIES := [
	"side_cranium_x_offset",
	"side_cranium_width",
	"side_face_projection",
	"side_jaw_adjustment",
	"side_jaw_height",
	"side_chin_tip_x_offset",
	"side_cranium_front_x_offset",
	"side_cranium_front_y_offset",
	"side_cranium_front_top_curve",
	"side_cranium_front_face_curve",
	"side_nose_x_offset",
	"side_nose_y_offset",
	"side_nose_bridge_x_offset",
	"side_nose_bridge_y_offset",
	"side_nose_tip_x_offset",
	"side_nose_tip_y_offset",
	"side_upper_lip_x_offset",
	"side_upper_lip_y_offset",
	"side_ear_angle_degrees",
	"side_ear_size",
	"side_ear_y_offset",
	"side_ear_x_offset",
	"side_eye_width",
	"side_eye_height",
	"side_eye_roundness",
	"side_eye_angle_degrees",
	"side_eye_y_offset",
	"side_eye_x_offset",
	"side_brow_front_x_offset",
	"side_brow_front_y_offset",
	"side_brow_rear_x_offset",
	"side_brow_rear_y_offset",
	"side_pupil_x_offset",
	"side_pupil_y_offset",
	"side_pupil_width",
	"side_pupil_height",
	"side_mouth_x_offset",
	"side_mouth_y_offset",
	"side_mouth_width",
	"side_mouth_angle_degrees",
	"side_mouth_curve",
	"side_mouth_line_width",
	"side_mouth_taper",
	"side_scalp_x_offset",
	"side_scalp_width",
	"side_scalp_height",
	"side_scalp_y_offset",
	"side_back_hair_x_offset",
	"side_back_hair_top_width",
	"side_back_hair_bottom_width",
	"side_back_hair_length",
	"side_back_hair_y_offset",
]
const PAIRED_VIEW_PROPERTIES := [
	"ear_x_offset",
	"ear_spacing",
	"eye_spacing",
]
const BACK_ONLY_PROPERTIES := [
	"back_ear_y_offset",
]
const LEGACY_SIDE_CRANIUM_FRONT_PROPERTIES := [
	"side_forehead_x_offset",
	"side_forehead_y_offset",
	"side_brow_join_x_offset",
	"side_brow_join_y_offset",
]
const SIDE_REPLACED_PROPERTIES := [
	"ear_angle_degrees",
	"ear_size",
	"ear_y_offset",
	"eye_x_offset",
	"eye_width",
	"eye_height",
	"eye_roundness",
	"eye_angle_degrees",
	"eye_y_offset",
	"pupil_x_offset",
	"pupil_y_offset",
	"pupil_width",
	"pupil_height",
	"mouth_y_offset",
	"mouth_width",
	"mouth_angle_degrees",
	"mouth_curve",
	"mouth_line_width",
	"mouth_taper",
]
const EAR_PROPERTIES := [
	"ear_x_offset",
	"ear_angle_degrees",
	"ear_size",
	"ear_spacing",
	"ear_y_offset",
	"side_ear_x_offset",
]
const FACE_ONLY_PROPERTIES := [
	"eye_width",
	"eye_height",
	"eye_roundness",
	"eye_angle_degrees",
	"eye_x_offset",
	"eye_spacing",
	"eye_y_offset",
	"side_eye_x_offset",
	"pupil_x_offset",
	"pupil_y_offset",
	"pupil_width",
	"pupil_height",
	"mouth_y_offset",
	"mouth_width",
	"mouth_angle_degrees",
	"mouth_curve",
	"mouth_line_width",
	"mouth_taper",
]

@export_group("View")
## Directional view to preview.
@export_enum("front", "side_left", "side_right", "back") var view_direction: String = VIEW_FRONT:
	set(value):
		view_direction = value
		notify_property_list_changed()
		queue_redraw()

## Scales the 128x128 source-space preview.
@export_range(1.0, 5.0, 0.1) var preview_scale: float = 3.0:
	set(value):
		preview_scale = value
		queue_redraw()

@export_group("Layer Order")
## Draws or hides all hair masses while keeping head, ears, face, and neck visible.
@export var show_hair: bool = true:
	set(value):
		show_hair = value
		queue_redraw()

## Comma-separated layer order for front view. Valid layers: neck, back_hair, ears, head, eyes, mouth, scalp, sideburns, bangs.
@export var front_draw_order: String = "back_hair,neck,ears,head,scalp,eyes,mouth,sideburns,bangs":
	set(value):
		front_draw_order = value
		queue_redraw()

## Comma-separated layer order for side views. Valid layers: neck, back_hair, ears, head, eyes, mouth, scalp, sideburns, bangs.
@export var side_draw_order: String = "neck,head,ears,eyes,mouth,back_hair,scalp,sideburns,bangs":
	set(value):
		side_draw_order = value
		queue_redraw()

## Comma-separated layer order for back view. Valid layers: neck, back_hair, ears, head, eyes, mouth, scalp, sideburns, bangs.
@export var back_draw_order: String = "neck,ears,head,bangs,scalp,sideburns,back_hair":
	set(value):
		back_draw_order = value
		queue_redraw()

@export_group("Head - Shared")
## Overall horizontal scale of the native head shape.
@export_range(0.78, 1.22, 0.01) var head_width: float = 1.0:
	set(value):
		head_width = value
		queue_redraw()

## Overall vertical scale of the native head shape.
@export_range(0.78, 1.22, 0.01) var head_height: float = 1.0:
	set(value):
		head_height = value
		queue_redraw()

## Extends or shortens the chin from the traced reference.
@export_range(0.75, 1.3, 0.01) var chin_length: float = 1.0:
	set(value):
		chin_length = value
		queue_redraw()

## Controls how subtle and rounded the chin point is.
@export_range(0.0, 1.0, 0.01) var chin_roundness: float = 0.68:
	set(value):
		chin_roundness = value
		queue_redraw()

@export_group("Side Profile")
## Moves the side-view cranium anchor shape horizontally.
@export_range(-18.0, 18.0, 0.1) var side_cranium_x_offset: float = -3.4:
	set(value):
		side_cranium_x_offset = value
		queue_redraw()

## Scales the side-view cranium width while keeping its height stable.
@export_range(0.75, 1.35, 0.01) var side_cranium_width: float = 1.12:
	set(value):
		side_cranium_width = value
		queue_redraw()

## Extends or retracts the triangular side face.
@export_range(-12.0, 18.0, 0.1) var side_face_projection: float = -8.0:
	set(value):
		side_face_projection = value
		queue_redraw()

## Moves the side jaw hinge forward or backward.
@export_range(-14.0, 14.0, 0.1) var side_jaw_adjustment: float = 0.8:
	set(value):
		side_jaw_adjustment = value
		queue_redraw()

## Sets the side jaw height as it runs back toward the cranium.
@export_range(26.0, 58.0, 0.1) var side_jaw_height: float = 47.5:
	set(value):
		side_jaw_height = value
		queue_redraw()

## Moves the side chin tip forward or backward while keeping its height aligned.
@export_range(-14.0, 14.0, 0.1) var side_chin_tip_x_offset: float = 2.3:
	set(value):
		side_chin_tip_x_offset = value
		queue_redraw()

## Moves the single front cranium control forward or backward.
@export_range(-24.0, 24.0, 0.1) var side_cranium_front_x_offset: float = 0.0:
	set(value):
		side_cranium_front_x_offset = value
		queue_redraw()

## Moves the single front cranium control vertically.
@export_range(-24.0, 24.0, 0.1) var side_cranium_front_y_offset: float = 0.0:
	set(value):
		side_cranium_front_y_offset = value
		queue_redraw()

## Controls how strongly the upper cranium bends into the front control.
@export_range(-24.0, 24.0, 0.1) var side_cranium_front_top_curve: float = 0.0:
	set(value):
		side_cranium_front_top_curve = value
		queue_redraw()

## Controls how strongly the front control bends into the face/nose bridge.
@export_range(-18.0, 18.0, 0.1) var side_cranium_front_face_curve: float = 0.0:
	set(value):
		side_cranium_front_face_curve = value
		queue_redraw()

## Legacy upper forehead control kept for old saved scene overrides.
@export_range(-24.0, 24.0, 0.1) var side_forehead_x_offset: float = 0.0:
	set(value):
		side_forehead_x_offset = value
		queue_redraw()

## Legacy upper forehead control kept for old saved scene overrides.
@export_range(-24.0, 24.0, 0.1) var side_forehead_y_offset: float = 0.0:
	set(value):
		side_forehead_y_offset = value
		queue_redraw()

## Legacy lower brow join control kept for old saved scene overrides.
@export_range(-24.0, 24.0, 0.1) var side_brow_join_x_offset: float = 0.0:
	set(value):
		side_brow_join_x_offset = value
		queue_redraw()

## Legacy lower brow join control kept for old saved scene overrides.
@export_range(-24.0, 24.0, 0.1) var side_brow_join_y_offset: float = 0.0:
	set(value):
		side_brow_join_y_offset = value
		queue_redraw()

## Moves the whole side-view nose and upper lip group horizontally.
@export_range(-28.0, 28.0, 0.1) var side_nose_x_offset: float = 0.0:
	set(value):
		side_nose_x_offset = value
		queue_redraw()

## Moves the whole side-view nose and upper lip group vertically.
@export_range(-28.0, 28.0, 0.1) var side_nose_y_offset: float = 8.0:
	set(value):
		side_nose_y_offset = value
		queue_redraw()

## Moves the side-view nose bridge forward or backward.
@export_range(-18.0, 18.0, 0.1) var side_nose_bridge_x_offset: float = 0.0:
	set(value):
		side_nose_bridge_x_offset = value
		queue_redraw()

## Moves the side-view nose bridge vertically.
@export_range(-24.0, 24.0, 0.1) var side_nose_bridge_y_offset: float = 0.0:
	set(value):
		side_nose_bridge_y_offset = value
		queue_redraw()

## Moves the side-view nose tip forward or backward.
@export_range(-18.0, 18.0, 0.1) var side_nose_tip_x_offset: float = 0.0:
	set(value):
		side_nose_tip_x_offset = value
		queue_redraw()

## Moves the side-view nose tip vertically.
@export_range(-18.0, 18.0, 0.1) var side_nose_tip_y_offset: float = 0.0:
	set(value):
		side_nose_tip_y_offset = value
		queue_redraw()

## Moves the side-view upper lip forward or backward.
@export_range(-18.0, 18.0, 0.1) var side_upper_lip_x_offset: float = 0.0:
	set(value):
		side_upper_lip_x_offset = value
		queue_redraw()

## Moves the side-view upper lip vertically.
@export_range(-18.0, 18.0, 0.1) var side_upper_lip_y_offset: float = 0.0:
	set(value):
		side_upper_lip_y_offset = value
		queue_redraw()

## Rotates the side-view ear without affecting front/back ears.
@export_range(-28.0, 28.0, 0.1) var side_ear_angle_degrees: float = 12.0:
	set(value):
		side_ear_angle_degrees = value
		queue_redraw()

## Scales the side-view ear without affecting front/back ears.
@export_range(0.6, 1.55, 0.01) var side_ear_size: float = 1.0:
	set(value):
		side_ear_size = value
		queue_redraw()

## Moves the side-view ear vertically.
@export_range(-30.0, 30.0, 0.1) var side_ear_y_offset: float = 16.0:
	set(value):
		side_ear_y_offset = value
		queue_redraw()

## Moves the single side-view ear forward or backward.
@export_range(-18.0, 18.0, 0.1) var side_ear_x_offset: float = 0.5:
	set(value):
		side_ear_x_offset = value
		queue_redraw()

## Moves the side-view scalp mass horizontally.
@export_range(-24.0, 24.0, 0.5) var side_scalp_x_offset: float = 0.0:
	set(value):
		side_scalp_x_offset = value
		queue_redraw()

## Controls side-view scalp mass width.
@export_range(24.0, 96.0, 0.5) var side_scalp_width: float = 66.0:
	set(value):
		side_scalp_width = value
		queue_redraw()

## Controls side-view scalp mass height.
@export_range(20.0, 86.0, 0.5) var side_scalp_height: float = 58.0:
	set(value):
		side_scalp_height = value
		queue_redraw()

## Moves the side-view scalp mass vertically.
@export_range(-22.0, 28.0, 0.5) var side_scalp_y_offset: float = -5.0:
	set(value):
		side_scalp_y_offset = value
		queue_redraw()

## Moves the side-view back hair mass horizontally.
@export_range(-28.0, 28.0, 0.5) var side_back_hair_x_offset: float = 0.0:
	set(value):
		side_back_hair_x_offset = value
		queue_redraw()

## Controls side-view back hair top width.
@export_range(20.0, 104.0, 0.5) var side_back_hair_top_width: float = 58.0:
	set(value):
		side_back_hair_top_width = value
		queue_redraw()

## Controls side-view back hair bottom width.
@export_range(18.0, 124.0, 0.5) var side_back_hair_bottom_width: float = 74.0:
	set(value):
		side_back_hair_bottom_width = value
		queue_redraw()

## Controls side-view back hair length.
@export_range(18.0, 132.0, 0.5) var side_back_hair_length: float = 72.0:
	set(value):
		side_back_hair_length = value
		queue_redraw()

## Moves the side-view back hair mass vertically.
@export_range(-24.0, 36.0, 0.5) var side_back_hair_y_offset: float = 0.0:
	set(value):
		side_back_hair_y_offset = value
		queue_redraw()

## Moves the side-view eye along the profile direction.
@export_range(-18.0, 18.0, 0.1) var side_eye_x_offset: float = 4.3:
	set(value):
		side_eye_x_offset = value
		queue_redraw()

## Scales the side-view eye width.
@export_range(0.65, 1.35, 0.01) var side_eye_width: float = 0.76:
	set(value):
		side_eye_width = value
		queue_redraw()

## Scales the side-view eye height.
@export_range(0.2, 1.4, 0.01) var side_eye_height: float = 0.91:
	set(value):
		side_eye_height = value
		queue_redraw()

## Rounds the side-view eye slot.
@export_range(0.0, 1.0, 0.01) var side_eye_roundness: float = 0.0:
	set(value):
		side_eye_roundness = value
		queue_redraw()

## Rotates the side-view eye.
@export_range(-18.0, 18.0, 0.1) var side_eye_angle_degrees: float = -9.6:
	set(value):
		side_eye_angle_degrees = value
		queue_redraw()

## Moves the side-view eye vertically.
@export_range(-10.0, 12.0, 0.1) var side_eye_y_offset: float = 5.9:
	set(value):
		side_eye_y_offset = value
		queue_redraw()

## Moves the front point of the side-view brow forward or backward.
@export_range(-18.0, 18.0, 0.1) var side_brow_front_x_offset: float = 0.0:
	set(value):
		side_brow_front_x_offset = value
		queue_redraw()

## Moves the front point of the side-view brow vertically.
@export_range(-18.0, 18.0, 0.1) var side_brow_front_y_offset: float = 0.0:
	set(value):
		side_brow_front_y_offset = value
		queue_redraw()

## Moves the rear point of the side-view brow forward or backward.
@export_range(-18.0, 18.0, 0.1) var side_brow_rear_x_offset: float = 0.0:
	set(value):
		side_brow_rear_x_offset = value
		queue_redraw()

## Moves the rear point of the side-view brow vertically.
@export_range(-18.0, 18.0, 0.1) var side_brow_rear_y_offset: float = 0.0:
	set(value):
		side_brow_rear_y_offset = value
		queue_redraw()

## Moves the side-view pupil along the eye shape.
@export_range(-8.0, 8.0, 0.1) var side_pupil_x_offset: float = -1.8:
	set(value):
		side_pupil_x_offset = value
		queue_redraw()

## Moves the side-view pupil vertically from the eye center.
@export_range(-8.0, 8.0, 0.1) var side_pupil_y_offset: float = 2.2:
	set(value):
		side_pupil_y_offset = value
		queue_redraw()

## Scales the side-view pupil width.
@export_range(0.35, 1.4, 0.01) var side_pupil_width: float = 1.16:
	set(value):
		side_pupil_width = value
		queue_redraw()

## Scales the side-view pupil height.
@export_range(0.35, 1.4, 0.01) var side_pupil_height: float = 1.1:
	set(value):
		side_pupil_height = value
		queue_redraw()

## Moves the side-view mouth forward or backward.
@export_range(-24.0, 24.0, 0.1) var side_mouth_x_offset: float = 0.0:
	set(value):
		side_mouth_x_offset = value
		queue_redraw()

## Moves the side-view mouth vertically.
@export_range(-16.0, 18.0, 0.1) var side_mouth_y_offset: float = 9.8:
	set(value):
		side_mouth_y_offset = value
		queue_redraw()

## Controls side-view mouth line length.
@export_range(5.0, 44.0, 0.5) var side_mouth_width: float = 10.0:
	set(value):
		side_mouth_width = value
		queue_redraw()

## Rotates the side-view mouth line.
@export_range(-18.0, 18.0, 0.1) var side_mouth_angle_degrees: float = 3.4:
	set(value):
		side_mouth_angle_degrees = value
		queue_redraw()

## Curves the side-view mouth line.
@export_range(-12.0, 12.0, 0.1) var side_mouth_curve: float = 0.0:
	set(value):
		side_mouth_curve = value
		queue_redraw()

## Controls side-view mouth thickness.
@export_range(0.6, 5.0, 0.1) var side_mouth_line_width: float = 0.7:
	set(value):
		side_mouth_line_width = value
		queue_redraw()

## Controls side-view mouth taper.
@export_range(0.0, 1.0, 0.01) var side_mouth_taper: float = 0.53:
	set(value):
		side_mouth_taper = value
		queue_redraw()

@export_group("Ears")
## Moves ears horizontally in source-space pixels.
@export_range(-18.0, 18.0, 0.1) var ear_x_offset: float = 0.0:
	set(value):
		ear_x_offset = value
		queue_redraw()

## Rotates the ears around their center.
@export_range(-28.0, 28.0, 0.1) var ear_angle_degrees: float = 0.0:
	set(value):
		ear_angle_degrees = value
		queue_redraw()

## Scales both ears from their current source-space centers.
@export_range(0.6, 1.55, 0.01) var ear_size: float = 1.0:
	set(value):
		ear_size = value
		queue_redraw()

## Pushes paired ears farther apart or closer together in source-space pixels.
@export_range(-10.0, 16.0, 0.1) var ear_spacing: float = 0.0:
	set(value):
		ear_spacing = value
		queue_redraw()

## Moves the ears vertically in source-space pixels.
@export_range(-16.0, 16.0, 0.1) var ear_y_offset: float = 0.0:
	set(value):
		ear_y_offset = value
		queue_redraw()

## Moves the back-view ears vertically without changing front or side views.
@export_range(-16.0, 16.0, 0.1) var back_ear_y_offset: float = 0.0:
	set(value):
		back_ear_y_offset = value
		queue_redraw()

@export_group("Eyes")
## Moves visible eyes horizontally in source-space pixels.
@export_range(-18.0, 18.0, 0.1) var eye_x_offset: float = 0.0:
	set(value):
		eye_x_offset = value
		queue_redraw()

## Scales the eye slot width.
@export_range(0.65, 1.35, 0.01) var eye_width: float = 1.0:
	set(value):
		eye_width = value
		queue_redraw()

## Scales the eye slot height.
@export_range(0.2, 1.4, 0.01) var eye_height: float = 1.0:
	set(value):
		eye_height = value
		queue_redraw()

## Rounds the eye slot corners and lower lid.
@export_range(0.0, 1.0, 0.01) var eye_roundness: float = 0.25:
	set(value):
		eye_roundness = value
		queue_redraw()

## Rotates the eye slots in degrees.
@export_range(-18.0, 18.0, 0.1) var eye_angle_degrees: float = 0.0:
	set(value):
		eye_angle_degrees = value
		queue_redraw()

## Pushes paired eyes farther apart or closer together in source-space pixels.
@export_range(-8.0, 18.0, 0.1) var eye_spacing: float = 0.0:
	set(value):
		eye_spacing = value
		queue_redraw()

## Moves the eye slots vertically in source-space pixels.
@export_range(-10.0, 12.0, 0.1) var eye_y_offset: float = 0.0:
	set(value):
		eye_y_offset = value
		queue_redraw()

@export_group("Pupils")
## Moves pupils outward from each eye center in source-space pixels.
@export_range(-8.0, 8.0, 0.1) var pupil_x_offset: float = 0.2:
	set(value):
		pupil_x_offset = value
		queue_redraw()

## Moves pupils vertically from each eye center in source-space pixels.
@export_range(-8.0, 8.0, 0.1) var pupil_y_offset: float = 0.2:
	set(value):
		pupil_y_offset = value
		queue_redraw()

## Scales pupil width relative to eye width.
@export_range(0.35, 1.4, 0.01) var pupil_width: float = 1.0:
	set(value):
		pupil_width = value
		queue_redraw()

## Scales pupil height relative to eye height.
@export_range(0.35, 1.4, 0.01) var pupil_height: float = 1.0:
	set(value):
		pupil_height = value
		queue_redraw()

@export_group("Mouth")
## Moves the small mouth vertically in source-space pixels.
@export_range(-16.0, 18.0, 0.1) var mouth_y_offset: float = 0.0:
	set(value):
		mouth_y_offset = value
		queue_redraw()

## Controls how far the mouth lines reach toward the head edges.
@export_range(5.0, 44.0, 0.5) var mouth_width: float = 20.0:
	set(value):
		mouth_width = value
		queue_redraw()

## Rotates the mirrored mouth line pair.
@export_range(-18.0, 18.0, 0.1) var mouth_angle_degrees: float = 0.0:
	set(value):
		mouth_angle_degrees = value
		queue_redraw()

## Curves the mouth line pair upward or downward.
@export_range(-12.0, 12.0, 0.1) var mouth_curve: float = -2.5:
	set(value):
		mouth_curve = value
		queue_redraw()

## Controls the thickest part of each mouth line.
@export_range(0.6, 5.0, 0.1) var mouth_line_width: float = 2.2:
	set(value):
		mouth_line_width = value
		queue_redraw()

## Controls how thin the mouth lines get near the outer edges.
@export_range(0.0, 1.0, 0.01) var mouth_taper: float = 0.16:
	set(value):
		mouth_taper = value
		queue_redraw()

@export_group("Neck")
## Controls the neck width behind the head.
@export_range(8.0, 38.0, 0.5) var neck_width: float = 22.0:
	set(value):
		neck_width = value
		queue_redraw()

## Controls how far the neck reaches toward the chin baseline.
@export_range(10.0, 42.0, 0.5) var neck_length: float = 28.0:
	set(value):
		neck_length = value
		queue_redraw()

@export_group("Hair - Bangs")
## Scales the full bangs mass uniformly.
@export_range(0.55, 1.65, 0.01) var bangs_size: float = 1.0:
	set(value):
		bangs_size = value
		queue_redraw()

## Controls the bangs mass width.
@export_range(22.0, 88.0, 0.5) var bangs_width: float = 73.0:
	set(value):
		bangs_width = value
		queue_redraw()

## Controls the bangs mass height.
@export_range(20.0, 88.0, 0.5) var bangs_height: float = 81.5:
	set(value):
		bangs_height = value
		queue_redraw()

## Moves the bangs mass vertically.
@export_range(-18.0, 24.0, 0.5) var bangs_y_offset: float = 0.0:
	set(value):
		bangs_y_offset = value
		queue_redraw()

@export_group("Hair - Scalp")
## Scales the scalp helmet mass uniformly.
@export_range(0.55, 1.65, 0.01) var scalp_size: float = 1.11:
	set(value):
		scalp_size = value
		queue_redraw()

## Controls the scalp helmet width.
@export_range(32.0, 104.0, 0.5) var scalp_width: float = 86.5:
	set(value):
		scalp_width = value
		queue_redraw()

## Controls the scalp helmet height.
@export_range(20.0, 82.0, 0.5) var scalp_height: float = 65.5:
	set(value):
		scalp_height = value
		queue_redraw()

## Moves the scalp helmet vertically.
@export_range(-18.0, 24.0, 0.5) var scalp_y_offset: float = -8.0:
	set(value):
		scalp_y_offset = value
		queue_redraw()

@export_group("Hair - Sideburns")
## Moves the sideburn roots vertically.
@export_range(-18.0, 24.0, 0.5) var sideburn_y_offset: float = 18.5:
	set(value):
		sideburn_y_offset = value
		queue_redraw()

## Controls how far apart the paired sideburn roots sit on front/back views.
@export_range(24.0, 88.0, 0.5) var sideburn_width_apart: float = 71.5:
	set(value):
		sideburn_width_apart = value
		queue_redraw()

## Controls sideburn thickness near the top root.
@export_range(4.0, 24.0, 0.5) var sideburn_top_width: float = 11.0:
	set(value):
		sideburn_top_width = value
		queue_redraw()

## Controls sideburn thickness near the bottom tip.
@export_range(2.0, 18.0, 0.5) var sideburn_bottom_width: float = 5.0:
	set(value):
		sideburn_bottom_width = value
		queue_redraw()

## Moves the side-view sideburn forward or backward.
@export_range(-22.0, 22.0, 0.5) var side_sideburn_x_offset: float = -1.0:
	set(value):
		side_sideburn_x_offset = value
		queue_redraw()

## Controls how far sideburns curve toward the chin.
@export_range(26.0, 86.0, 0.5) var sideburn_length: float = 56.5:
	set(value):
		sideburn_length = value
		queue_redraw()

@export_group("Hair - Back Mass")
## Controls the top width of the back hair mass.
@export_range(22.0, 96.0, 0.5) var back_hair_top_width: float = 64.0:
	set(value):
		back_hair_top_width = value
		queue_redraw()

## Controls the bottom width of the back hair mass.
@export_range(18.0, 108.0, 0.5) var back_hair_bottom_width: float = 82.0:
	set(value):
		back_hair_bottom_width = value
		queue_redraw()

## Controls how far the back hair mass falls.
@export_range(18.0, 132.0, 0.5) var back_hair_length: float = 72.0:
	set(value):
		back_hair_length = value
		queue_redraw()

## Moves the back hair mass vertically.
@export_range(-18.0, 28.0, 0.5) var back_hair_y_offset: float = 0.0:
	set(value):
		back_hair_y_offset = value
		queue_redraw()

@export_group("Preview")
## Draws reference anchors used by hair components.
@export var show_anchors: bool = true:
	set(value):
		show_anchors = value
		queue_redraw()

## Draws the dark preview background behind the character.
@export var show_backdrop: bool = false:
	set(value):
		show_backdrop = value
		queue_redraw()

## Draws the 128x128 preview bounds and center guides.
@export var show_guides: bool = true:
	set(value):
		show_guides = value
		queue_redraw()

## Draws simple native hair-lock primitives over the generated head.
@export var show_test_locks: bool = false:
	set(value):
		show_test_locks = value
		queue_redraw()

## Number of sample lock primitives to draw from the hairline.
@export_range(1, 9, 1) var test_lock_count: int = 5:
	set(value):
		test_lock_count = value
		queue_redraw()

## Length of sample hair locks in source-space pixels.
@export_range(8.0, 42.0, 0.5) var test_lock_length: float = 24.0:
	set(value):
		test_lock_length = value
		queue_redraw()

## Bends and separates sample locks.
@export_range(0.0, 1.0, 0.01) var test_lock_wildness: float = 0.35:
	set(value):
		test_lock_wildness = value
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(560.0, 560.0)


func _validate_property(property: Dictionary) -> void:
	var property_name := str(property.get("name", ""))
	if property_name in LEGACY_SIDE_CRANIUM_FRONT_PROPERTIES:
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
		return
	if not _is_side_view() and property_name in SIDE_ONLY_PROPERTIES:
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
		return
	if view_direction != VIEW_BACK and property_name in BACK_ONLY_PROPERTIES:
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
		return
	if _is_side_view() and property_name in PAIRED_VIEW_PROPERTIES:
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
		return
	if _is_side_view() and property_name in SIDE_REPLACED_PROPERTIES:
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
		return
	if view_direction == VIEW_BACK and property_name in FACE_ONLY_PROPERTIES:
		property["usage"] = PROPERTY_USAGE_NO_EDITOR


func _draw() -> void:
	var center := size * 0.5
	if center == Vector2.ZERO:
		center = Vector2(280.0, 280.0)
	_draw_backdrop(center)
	_draw_ordered_layers(center)
	if show_test_locks:
		_draw_test_locks(center)
	if show_anchors:
		_draw_anchors(center)


func _draw_backdrop(center: Vector2) -> void:
	var canvas_size := Vector2(128.0, 128.0) * preview_scale
	var rect := Rect2(center - canvas_size * 0.5, canvas_size)
	if show_backdrop:
		draw_rect(rect.grow(16.0), Color(0.035, 0.045, 0.065, 1.0), true)
	if not show_guides:
		return
	draw_rect(rect, Color(0.35, 0.55, 0.82, 0.28), false, 2.0)
	draw_line(center + Vector2(-canvas_size.x * 0.5, 0.0), center + Vector2(canvas_size.x * 0.5, 0.0), Color(0.35, 0.55, 0.82, 0.18), 1.0)
	draw_line(center + Vector2(0.0, -canvas_size.y * 0.5), center + Vector2(0.0, canvas_size.y * 0.5), Color(0.35, 0.55, 0.82, 0.18), 1.0)


func _draw_safe_colored_polygon(points: PackedVector2Array, color: Color) -> void:
	if points.size() < 3:
		return
	if abs(_polygon_signed_area(points)) <= 0.01:
		return
	if _polygon_has_self_intersection(points):
		return
	draw_colored_polygon(points, color)


func _polygon_signed_area(points: PackedVector2Array) -> float:
	var area := 0.0
	for index in range(points.size()):
		var current := points[index]
		var next := points[(index + 1) % points.size()]
		area += current.x * next.y - next.x * current.y
	return area * 0.5


func _polygon_has_self_intersection(points: PackedVector2Array) -> bool:
	for first_index in range(points.size()):
		var first_start := points[first_index]
		var first_end := points[(first_index + 1) % points.size()]
		for second_index in range(first_index + 1, points.size()):
			if abs(first_index - second_index) <= 1:
				continue
			if first_index == 0 and second_index == points.size() - 1:
				continue
			var second_start := points[second_index]
			var second_end := points[(second_index + 1) % points.size()]
			if _segments_intersect(first_start, first_end, second_start, second_end):
				return true
	return false


func _segments_intersect(first_start: Vector2, first_end: Vector2, second_start: Vector2, second_end: Vector2) -> bool:
	var first_delta := first_end - first_start
	var second_delta := second_end - second_start
	var denominator := first_delta.cross(second_delta)
	if abs(denominator) <= 0.0001:
		return false
	var offset := second_start - first_start
	var first_t := offset.cross(second_delta) / denominator
	var second_t := offset.cross(first_delta) / denominator
	return first_t > 0.001 and first_t < 0.999 and second_t > 0.001 and second_t < 0.999


func _draw_head(center: Vector2) -> void:
	var points := _head_points(center)
	_draw_safe_colored_polygon(points, SKIN_FILL)
	_draw_lower_head_shadow(center)
	draw_polyline(points, OUTLINE, 3.2 * preview_scale, true)
	_draw_skin_highlights(center)


func _draw_neck(center: Vector2) -> void:
	var top_y := 91.0
	var bottom_y: float = min(_chin_bottom_y(), top_y + neck_length)
	var half_top: float = neck_width * 0.42
	var half_bottom: float = neck_width * 0.56
	var x_shift := 0.0
	if _is_side_view():
		x_shift = -_profile_dir() * 8.0
	var source := PackedVector2Array([
		Vector2(64.0 + x_shift - half_top, top_y),
		Vector2(64.0 + x_shift + half_top, top_y),
		Vector2(64.0 + x_shift + half_bottom, bottom_y),
		Vector2(64.0 + x_shift - half_bottom, bottom_y),
	])
	var points := _transform_points(center, source)
	_draw_safe_colored_polygon(points, SKIN_FILL.darkened(0.04))
	draw_polyline(_closed_points(points), OUTLINE, 2.4 * preview_scale, true)


func _draw_eye_slots(center: Vector2) -> void:
	if view_direction == VIEW_BACK:
		return
	for side in _visible_face_sides():
		var eye_points := _eye_points(center, side)
		_draw_safe_colored_polygon(eye_points, EYE_FILL)
		_draw_eye_pupil(center, side)
		var top_lid := _eye_lid_points(center, side, true)
		draw_polyline(top_lid, OUTLINE, 3.5 * preview_scale, false)


func _draw_skin_highlights(center: Vector2) -> void:
	if _is_side_view():
		_draw_oval(center, Vector2(64.0 + _profile_dir() * 21.0, 44.0), Vector2(5.0, 14.0), _profile_dir() * -0.32, Color(1.0, 0.95, 0.9, 0.5))
		return
	if view_direction == VIEW_BACK:
		_draw_oval(center, Vector2(47.0, 42.0), Vector2(5.0, 16.0), -0.32, Color(1.0, 0.95, 0.9, 0.38))
		return
	_draw_oval(center, Vector2(39.0, 43.0), Vector2(5.4, 17.0), -0.46, Color(1.0, 0.95, 0.9, 0.58))
	if not _is_side_view():
		_draw_oval(center, Vector2(89.0, 43.0), Vector2(5.4, 17.0), 0.46, Color(1.0, 0.95, 0.9, 0.58))


func _draw_lower_head_shadow(center: Vector2) -> void:
	if _is_side_view():
		_draw_oval(center, Vector2(64.0 - _profile_dir() * 5.0, 101.0), Vector2(25.0, 12.0), 0.0, SKIN_SHADOW)
		return
	if view_direction == VIEW_BACK:
		_draw_oval(center, Vector2(64.0, 92.0), Vector2(29.0, 12.0), 0.0, SKIN_SHADOW)
		return
	_draw_oval(center, Vector2(64.0 + _side_shift() * 0.35, 101.0), Vector2(31.0, 13.0), 0.0, SKIN_SHADOW)


func _draw_ears(center: Vector2) -> void:
	var y_offset := Vector2(0.0, _active_ear_y_offset())
	if _is_side_view():
		var profile_dir := _profile_dir()
		var ear_side := -profile_dir
		var ear_x: float = 64.0 + ear_side * (27.5 + side_ear_x_offset)
		_draw_ear(center, Vector2(ear_x, 62.5) + y_offset, Vector2(7.4, 18.0) * _active_ear_size(), ear_side, true)
		return
	if view_direction == VIEW_BACK:
		_draw_ear(center, Vector2(22.2 + ear_x_offset - ear_spacing, 61.0) + y_offset, Vector2(8.6, 18.0) * _active_ear_size(), -1.0, false)
		_draw_ear(center, Vector2(105.8 + ear_x_offset + ear_spacing, 61.0) + y_offset, Vector2(8.6, 18.0) * _active_ear_size(), 1.0, false)
		return
	_draw_ear(center, Vector2(23.0 + ear_x_offset - ear_spacing, 61.5) + y_offset, Vector2(8.0, 17.4) * _active_ear_size(), -1.0, true)
	_draw_ear(center, Vector2(105.0 + ear_x_offset + ear_spacing, 61.5) + y_offset, Vector2(8.0, 17.4) * _active_ear_size(), 1.0, true)


func _draw_ear(center: Vector2, source_center: Vector2, source_radius: Vector2, side: float, draw_inner: bool) -> void:
	var rotation: float = side * (0.08 + deg_to_rad(_active_ear_angle_degrees()))
	var points := _ellipse_points(center, source_center, source_radius, rotation, 22)
	_draw_safe_colored_polygon(points, SKIN_FILL)
	draw_polyline(_closed_points(points), OUTLINE, 2.8 * preview_scale, true)
	if not draw_inner:
		return
	var inner_top := source_center + Vector2(side * -1.4, -7.2)
	var inner_mid := source_center + Vector2(side * -4.0, 0.0)
	var inner_bottom := source_center + Vector2(side * -0.8, 7.6)
	draw_polyline(_sample_quadratic(center, inner_top, inner_mid, inner_bottom, 12), SKIN_SHADOW.darkened(0.35), 1.6 * preview_scale, true)
	draw_circle(_preview_point(center, source_center + Vector2(side * -1.8, 4.8)), 1.7 * preview_scale, SKIN_SHADOW)


func _draw_eye_pupil(center: Vector2, side: float) -> void:
	var source_center: Vector2 = _eye_source_center(side) + Vector2(side * _active_pupil_x_offset(), _active_pupil_y_offset())
	var radius: Vector2 = Vector2(max(2.4, 6.0 * _active_eye_width() * _active_pupil_width()), max(1.6, 6.0 * _active_eye_height() * _active_pupil_height()))
	_draw_oval(center, source_center, radius, _eye_angle(side), EYE_PUPIL)


func _draw_mouth(center: Vector2) -> void:
	if view_direction == VIEW_BACK:
		return
	if _is_side_view():
		var side := _profile_dir()
		var source_center := _side_mouth_center()
		var angle: float = deg_to_rad(_active_mouth_angle_degrees()) * side
		var inner := source_center + Vector2(side * 1.25, 0.0).rotated(angle)
		var mouth_width_value: float = _active_mouth_width()
		var outer := source_center + Vector2(side * mouth_width_value, side * sin(angle) * 5.0).rotated(angle)
		var control := source_center + Vector2(side * mouth_width_value * 0.48, _active_mouth_curve()).rotated(angle)
		var line_width: float = _active_mouth_line_width()
		_draw_tapered_stroke(center, inner, control, outer, line_width, max(0.1, line_width * _active_mouth_taper()), OUTLINE)
		return
	var source_center := Vector2(64.0 + _side_shift() * 0.35, 95.5 + mouth_y_offset)
	for side in [-1.0, 1.0]:
		var angle: float = deg_to_rad(mouth_angle_degrees) * side
		var inner := source_center + Vector2(side * 1.25, 0.0).rotated(angle)
		var outer := source_center + Vector2(side * mouth_width, side * sin(angle) * 5.0).rotated(angle)
		var control := source_center + Vector2(side * mouth_width * 0.48, mouth_curve).rotated(angle)
		_draw_tapered_stroke(center, inner, control, outer, mouth_line_width, max(0.1, mouth_line_width * mouth_taper), OUTLINE)


func _draw_ordered_layers(center: Vector2) -> void:
	for layer_name in _active_draw_order():
		_draw_layer(center, layer_name)


func _active_draw_order() -> PackedStringArray:
	if view_direction == VIEW_BACK:
		return _parse_draw_order(back_draw_order)
	if _is_side_view():
		return _parse_draw_order(side_draw_order)
	return _parse_draw_order(front_draw_order)


func _parse_draw_order(raw_order: String) -> PackedStringArray:
	var parsed := PackedStringArray()
	for raw_layer in raw_order.split(",", false):
		var layer_name := raw_layer.strip_edges()
		if layer_name.is_empty():
			continue
		if not _is_known_layer(layer_name):
			continue
		if not show_hair and layer_name in HAIR_LAYERS:
			continue
		parsed.append(layer_name)
	return parsed


func _is_known_layer(layer_name: String) -> bool:
	return layer_name in [
		LAYER_NECK,
		LAYER_BACK_HAIR,
		LAYER_EARS,
		LAYER_HEAD,
		LAYER_EYES,
		LAYER_MOUTH,
		LAYER_SCALP,
		LAYER_SIDEBURNS,
		LAYER_BANGS,
	]


func _draw_layer(center: Vector2, layer_name: String) -> void:
	match layer_name:
		LAYER_NECK:
			_draw_neck(center)
		LAYER_BACK_HAIR:
			_draw_back_hair(center)
		LAYER_EARS:
			_draw_ears(center)
		LAYER_HEAD:
			_draw_head(center)
		LAYER_EYES:
			_draw_eye_slots(center)
		LAYER_MOUTH:
			_draw_mouth(center)
		LAYER_SCALP:
			_draw_scalp_hair(center)
		LAYER_SIDEBURNS:
			_draw_sideburns(center)
		LAYER_BANGS:
			_draw_bangs(center)


func _draw_bangs(center: Vector2) -> void:
	if view_direction == VIEW_BACK:
		_draw_hair_polygon(center, _back_bangs_points())
		return
	if _is_side_view():
		_draw_hair_polygon(center, _side_bangs_points())
		return
	_draw_hair_polygon(center, _front_bangs_points())


func _draw_scalp_hair(center: Vector2) -> void:
	if view_direction == VIEW_BACK:
		_draw_hair_polygon(center, _back_scalp_points())
		return
	if _is_side_view():
		_draw_hair_polygon(center, _side_scalp_points())
		return
	_draw_hair_polygon(center, _front_scalp_points())


func _draw_sideburns(center: Vector2) -> void:
	if _is_side_view():
		var profile_dir := _profile_dir()
		var burn_side := -profile_dir
		var root := Vector2(64.0 + burn_side * (28.0 + side_sideburn_x_offset), 45.0 + sideburn_y_offset)
		var tip_y: float = min(_chin_bottom_y(), root.y + sideburn_length)
		var tip := Vector2(64.0 + burn_side * (10.0 + side_sideburn_x_offset * 0.4), tip_y)
		var control := Vector2(64.0 + burn_side * (25.0 + side_sideburn_x_offset * 0.7), lerp(root.y, tip.y, 0.5))
		_draw_hair_tapered_stroke(center, root, control, tip, sideburn_top_width, sideburn_bottom_width)
		return
	for side in [-1.0, 1.0]:
		var root_x: float = 64.0 + side * sideburn_width_apart * 0.5
		var root := Vector2(root_x, 42.0 + sideburn_y_offset)
		var tip_y: float = min(_chin_bottom_y(), root.y + sideburn_length)
		var tip := Vector2(64.0 + side * 18.0, tip_y)
		var control := Vector2(64.0 + side * 36.0, lerp(root.y, tip.y, 0.48))
		var start_width: float = sideburn_top_width + 2.0 if view_direction == VIEW_BACK else sideburn_top_width
		var end_width: float = sideburn_bottom_width + 1.5 if view_direction == VIEW_BACK else sideburn_bottom_width
		_draw_hair_tapered_stroke(center, root, control, tip, start_width, end_width)


func _draw_back_hair(center: Vector2) -> void:
	if view_direction == VIEW_BACK:
		_draw_hair_polygon(center, _back_back_hair_points())
		return
	if _is_side_view():
		_draw_hair_polygon(center, _side_back_hair_points())
		return
	_draw_hair_polygon(center, _front_back_hair_points())


func _draw_test_locks(center: Vector2) -> void:
	var count: int = max(test_lock_count, 1)
	for index in range(count):
		var ratio: float = 0.5 if count == 1 else float(index) / float(count - 1)
		var root := Vector2(42.0 + ratio * 44.0, 35.0 + sin(ratio * PI) * 2.0)
		var side_bias: float = ratio - 0.5
		var tip := root + Vector2(side_bias * (10.0 + test_lock_wildness * 18.0), test_lock_length)
		var bend := Vector2(side_bias * (12.0 + test_lock_wildness * 16.0), test_lock_length * 0.42)
		var width: float = lerp(8.0, 4.0, ratio) if index < count / 2 else lerp(4.0, 8.0, ratio)
		_draw_lock(center, root, root + bend, tip, max(width, 4.0), HAIR_FILL)
		var highlight_root := root + Vector2(1.5, 2.0)
		var highlight_tip := root.lerp(tip, 0.68)
		draw_polyline(_sample_quadratic(center, highlight_root, root + bend * 0.55, highlight_tip, 10), HAIR_HIGHLIGHT, 1.4 * preview_scale, false)


func _draw_anchors(center: Vector2) -> void:
	var anchors := {
		"crown": Vector2(64.0, 18.0),
		"hairline_l": Vector2(40.0, 39.0),
		"hairline_c": Vector2(64.0, 34.0),
		"hairline_r": Vector2(88.0, 39.0),
		"temple_l": Vector2(31.0, 66.0),
		"temple_r": Vector2(97.0, 66.0),
		"chin": Vector2(64.0, _chin_bottom_y())
	}
	if _is_side_view():
		var profile_dir := _profile_dir()
		var cranium_center := _side_cranium_center()
		anchors = {
			"cranium": cranium_center,
			"crown": cranium_center + Vector2(0.0, -45.0),
			"cranium_front": _side_cranium_front(),
			"nose_bridge": _side_nose_bridge(),
			"nose_tip": _side_nose_tip(),
			"upper_lip": _side_upper_lip(),
			"jaw": _side_jaw_back(),
			"chin": _side_chin_tip(),
			"brow_front": _side_brow_front_point(),
			"brow_rear": _side_brow_rear_point(),
			"ear": Vector2(64.0 - profile_dir * (27.5 + side_ear_x_offset), 62.5 + _active_ear_y_offset()),
			"eye": _eye_source_center(_profile_eye_side())
		}
	for anchor_name in anchors:
		var point: Vector2 = anchors[anchor_name]
		var screen_point := _preview_point(center, point)
		draw_circle(screen_point, 2.6, Color(0.1, 0.95, 0.8, 0.95))


func _draw_lock(center: Vector2, root: Vector2, control: Vector2, tip: Vector2, width: float, color: Color) -> void:
	var centerline := _sample_quadratic_source(root, control, tip, 14)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for index in range(centerline.size()):
		var t: float = float(index) / float(max(centerline.size() - 1, 1))
		var point: Vector2 = centerline[index]
		var prev: Vector2 = centerline[max(index - 1, 0)]
		var next: Vector2 = centerline[min(index + 1, centerline.size() - 1)]
		var tangent: Vector2 = (next - prev).normalized()
		if tangent.length_squared() <= 0.001:
			tangent = Vector2.DOWN
		var normal: Vector2 = tangent.orthogonal()
		var local_width: float = lerp(width, 1.0, t)
		left.append(_preview_point(center, point + normal * local_width * 0.5))
		right.insert(0, _preview_point(center, point - normal * local_width * 0.5))
	var polygon := PackedVector2Array()
	polygon.append_array(left)
	polygon.append_array(right)
	_draw_safe_colored_polygon(polygon, color)
	draw_polyline(polygon, HAIR_SHADOW, 1.2 * preview_scale, true)


func _draw_hair_tapered_stroke(center: Vector2, root: Vector2, control: Vector2, tip: Vector2, start_width: float, end_width: float) -> void:
	_draw_tapered_stroke(center, root, control, tip, start_width + 3.0, end_width + 2.0, HAIR_SHADOW)
	_draw_tapered_stroke(center, root, control, tip, start_width, end_width, HAIR_FILL)


func _draw_hair_polygon(center: Vector2, source: PackedVector2Array) -> void:
	var points := _transform_points(center, source)
	_draw_safe_colored_polygon(points, HAIR_FILL)
	draw_polyline(_closed_points(points), HAIR_SHADOW, 2.2 * preview_scale, true)


func _draw_tapered_stroke(center: Vector2, root: Vector2, control: Vector2, tip: Vector2, start_width: float, end_width: float, color: Color) -> void:
	var centerline := _sample_quadratic_source(root, control, tip, 12)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for index in range(centerline.size()):
		var t: float = float(index) / float(max(centerline.size() - 1, 1))
		var point: Vector2 = centerline[index]
		var prev: Vector2 = centerline[max(index - 1, 0)]
		var next: Vector2 = centerline[min(index + 1, centerline.size() - 1)]
		var tangent: Vector2 = (next - prev).normalized()
		if tangent.length_squared() <= 0.001:
			tangent = Vector2.RIGHT
		var normal: Vector2 = tangent.orthogonal()
		var local_width: float = lerp(start_width, end_width, t)
		left.append(_preview_point(center, point + normal * local_width * 0.5))
		right.insert(0, _preview_point(center, point - normal * local_width * 0.5))
	var polygon := PackedVector2Array()
	polygon.append_array(left)
	polygon.append_array(right)
	_draw_safe_colored_polygon(polygon, color)


func _front_bangs_points() -> PackedVector2Array:
	var size := bangs_size
	var half_width: float = bangs_width * size * 0.5
	var height: float = bangs_height * size
	var top := Vector2(64.0, 6.0 + bangs_y_offset)
	var bottom_y: float = top.y + height
	var notch_y: float = bottom_y - height * 0.18
	return PackedVector2Array([
		top,
		Vector2(64.0 - half_width * 0.72, top.y + height * 0.12),
		Vector2(64.0 - half_width, top.y + height * 0.42),
		Vector2(64.0 - half_width * 0.72, bottom_y),
		Vector2(64.0 - half_width * 0.3, notch_y),
		Vector2(64.0, bottom_y + 4.0 * size),
		Vector2(64.0 + half_width * 0.3, notch_y),
		Vector2(64.0 + half_width * 0.72, bottom_y),
		Vector2(64.0 + half_width, top.y + height * 0.42),
		Vector2(64.0 + half_width * 0.72, top.y + height * 0.12),
	])


func _side_bangs_points() -> PackedVector2Array:
	var profile_dir := _profile_dir()
	var size := bangs_size
	var height: float = bangs_height * size * 0.58
	var width: float = bangs_width * size * 0.42
	var root := Vector2(64.0 + profile_dir * 18.0, 27.0 + bangs_y_offset)
	return PackedVector2Array([
		root,
		root + Vector2(profile_dir * width * 0.72, height * 0.08),
		root + Vector2(profile_dir * width, height * 0.45),
		root + Vector2(profile_dir * width * 0.64, height),
		root + Vector2(profile_dir * width * 0.2, height * 0.82),
		root + Vector2(-profile_dir * width * 0.2, height * 0.38),
	])


func _back_bangs_points() -> PackedVector2Array:
	var size := bangs_size
	var half_width: float = bangs_width * size * 0.32
	var y: float = 1.5 + bangs_y_offset * 0.4
	return PackedVector2Array([
		Vector2(64.0, y),
		Vector2(64.0 - half_width, y + 9.0 * size),
		Vector2(64.0 - half_width * 0.55, y + 18.0 * size),
		Vector2(64.0, y + 21.0 * size),
		Vector2(64.0 + half_width * 0.55, y + 18.0 * size),
		Vector2(64.0 + half_width, y + 9.0 * size),
	])


func _front_scalp_points() -> PackedVector2Array:
	var size := scalp_size
	var half_width: float = scalp_width * size * 0.5
	var height: float = scalp_height * size
	var top := Vector2(64.0, 7.0 + scalp_y_offset)
	var bottom_y: float = top.y + height
	return PackedVector2Array([
		top,
		Vector2(64.0 - half_width * 0.72, top.y + height * 0.08),
		Vector2(64.0 - half_width, top.y + height * 0.48),
		Vector2(64.0 - half_width * 0.82, bottom_y),
		Vector2(64.0 - half_width * 0.28, bottom_y - height * 0.08),
		Vector2(64.0, bottom_y - height * 0.02),
		Vector2(64.0 + half_width * 0.28, bottom_y - height * 0.08),
		Vector2(64.0 + half_width * 0.82, bottom_y),
		Vector2(64.0 + half_width, top.y + height * 0.48),
		Vector2(64.0 + half_width * 0.72, top.y + height * 0.08),
	])


func _side_scalp_points() -> PackedVector2Array:
	var profile_dir := _profile_dir()
	var back_dir := -profile_dir
	var width: float = side_scalp_width * 0.5
	var height: float = side_scalp_height
	var top := Vector2(64.0 + side_scalp_x_offset + back_dir * 4.0, 8.0 + side_scalp_y_offset)
	return PackedVector2Array([
		top,
		top + Vector2(profile_dir * width * 0.42, height * 0.22),
		top + Vector2(profile_dir * width * 0.34, height * 0.62),
		top + Vector2(profile_dir * width * 0.02, height),
		top + Vector2(back_dir * width * 0.76, height * 0.96),
		top + Vector2(back_dir * width, height * 0.48),
		top + Vector2(back_dir * width * 0.62, height * 0.1),
	])


func _back_scalp_points() -> PackedVector2Array:
	var size := scalp_size
	var half_width: float = scalp_width * size * 0.5
	var height: float = scalp_height * size
	var top := Vector2(64.0, 7.0 + scalp_y_offset)
	var bottom_y: float = top.y + height
	return PackedVector2Array([
		top,
		Vector2(64.0 - half_width * 0.72, top.y + height * 0.12),
		Vector2(64.0 - half_width, top.y + height * 0.52),
		Vector2(64.0 - half_width * 0.78, bottom_y),
		Vector2(64.0, bottom_y + height * 0.08),
		Vector2(64.0 + half_width * 0.78, bottom_y),
		Vector2(64.0 + half_width, top.y + height * 0.52),
		Vector2(64.0 + half_width * 0.72, top.y + height * 0.12),
	])


func _front_back_hair_points() -> PackedVector2Array:
	var top_y := 28.0 + back_hair_y_offset
	var bottom_y := top_y + back_hair_length
	var half_top: float = back_hair_top_width * 0.5
	var half_bottom: float = back_hair_bottom_width * 0.5
	return PackedVector2Array([
		Vector2(64.0 - half_top, top_y),
		Vector2(64.0 + half_top, top_y),
		Vector2(64.0 + half_bottom, bottom_y),
		Vector2(64.0 - half_bottom, bottom_y),
	])


func _side_back_hair_points() -> PackedVector2Array:
	var profile_dir := _profile_dir()
	var back_dir := -profile_dir
	var top_y := 24.0 + side_back_hair_y_offset
	var bottom_y := top_y + side_back_hair_length
	var top_x := 64.0 + side_back_hair_x_offset + back_dir * 12.0
	var outer_top_x := 64.0 + side_back_hair_x_offset + back_dir * (side_back_hair_top_width * 0.45)
	var outer_bottom_x := 64.0 + side_back_hair_x_offset + back_dir * (side_back_hair_bottom_width * 0.42)
	return PackedVector2Array([
		Vector2(top_x, top_y),
		Vector2(outer_top_x, top_y + 9.0),
		Vector2(outer_bottom_x, bottom_y),
		Vector2(64.0 + back_dir * 7.0, bottom_y - 6.0),
	])


func _back_back_hair_points() -> PackedVector2Array:
	var top_y := 30.0 + back_hair_y_offset
	var bottom_y := top_y + back_hair_length
	var half_top: float = back_hair_top_width * 0.5
	var half_bottom: float = back_hair_bottom_width * 0.5
	return PackedVector2Array([
		Vector2(64.0 - half_top, top_y),
		Vector2(64.0 + half_top, top_y),
		Vector2(64.0 + half_bottom, bottom_y),
		Vector2(64.0 - half_bottom, bottom_y),
	])


func _head_points(center: Vector2) -> PackedVector2Array:
	if _is_side_view():
		return _side_head_points(center)
	if view_direction == VIEW_BACK:
		return _back_head_points(center)
	var side_shift := _side_shift()
	var top := Vector2(64.0 + side_shift * 0.4, 5.0)
	var bottom_y := _chin_bottom_y()
	var chin_half_width: float = lerp(1.2, 5.2, chin_roundness)
	var points := PackedVector2Array()
	_append_cubic(points, top, Vector2(37.0 + side_shift, 5.2), Vector2(22.0 + side_shift, 23.5), Vector2(21.7 + side_shift, 55.4), 18)
	_append_cubic(points, points[points.size() - 1], Vector2(21.6 + side_shift, 68.0), Vector2(24.3 + side_shift, 80.8), Vector2(30.3 + side_shift, 91.9), 12)
	_append_cubic(points, points[points.size() - 1], Vector2(36.4 + side_shift, 103.2), Vector2(49.0 + side_shift * 0.75, 113.0), Vector2(64.0 - chin_half_width + side_shift * 0.35, bottom_y - 0.9), 12)
	_append_cubic(points, points[points.size() - 1], Vector2(63.2 + side_shift * 0.2, bottom_y), Vector2(64.8 + side_shift * 0.2, bottom_y), Vector2(64.0 + chin_half_width + side_shift * 0.35, bottom_y - 0.9), 8)
	_append_cubic(points, points[points.size() - 1], Vector2(79.0 + side_shift * 0.75, 113.0), Vector2(91.6 + side_shift, 103.2), Vector2(97.7 + side_shift, 91.9), 12)
	_append_cubic(points, points[points.size() - 1], Vector2(103.7 + side_shift, 80.8), Vector2(106.4 + side_shift, 68.0), Vector2(106.3 + side_shift, 55.4), 12)
	_append_cubic(points, points[points.size() - 1], Vector2(106.0 + side_shift, 23.5), Vector2(91.0 + side_shift, 5.2), top, 18)
	return _transform_points(center, points)


func _side_head_points(center: Vector2) -> PackedVector2Array:
	var profile_dir := _profile_dir()
	var cranium_center := _side_cranium_center()
	var radius_x: float = _side_cranium_radius_x()
	var radius_y: float = _side_cranium_radius_y()
	var chin := _side_chin_tip()
	var top := cranium_center + Vector2(0.0, -radius_y)
	var cranium_front := _side_cranium_front()
	var nose_bridge := _side_nose_bridge()
	var nose_tip := _side_nose_tip()
	var upper_lip := _side_upper_lip()
	var jaw := _side_jaw_back()
	var back_lower := cranium_center + Vector2(-profile_dir * radius_x * 0.72, radius_y * 0.62)
	var points := PackedVector2Array()
	_append_cubic(points, top, cranium_center + Vector2(profile_dir * radius_x * 0.22, -radius_y), cranium_front + Vector2(-profile_dir * (18.0 + side_cranium_front_top_curve), -18.0), cranium_front, 18)
	_append_cubic(points, points[points.size() - 1], cranium_front + Vector2(profile_dir * (2.0 + side_cranium_front_face_curve), 7.0), nose_bridge + Vector2(-profile_dir * 4.0, -3.0), nose_bridge, 8)
	_append_cubic(points, points[points.size() - 1], nose_bridge + Vector2(profile_dir * 3.0, 7.0), nose_tip + Vector2(-profile_dir * 2.0, -7.0), nose_tip, 8)
	_append_line(points, points[points.size() - 1], upper_lip, 5)
	_append_cubic(points, points[points.size() - 1], upper_lip.lerp(chin, 0.35) + Vector2(-profile_dir * 0.8, 0.0), upper_lip.lerp(chin, 0.72) + Vector2(-profile_dir * 0.4, 0.0), chin, 10)
	_append_line(points, points[points.size() - 1], jaw, 8)
	_append_line(points, points[points.size() - 1], back_lower, 5)
	_append_side_cranium_back_arc(points, cranium_center, radius_x, radius_y, 14)
	return _transform_points(center, points)


func _back_head_points(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var source_center := Vector2(64.0, 55.5)
	var radius := Vector2(42.0, 48.0)
	for index in range(34):
		var angle: float = TAU * float(index) / 34.0 - PI * 0.5
		points.append(source_center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return _transform_points(center, points)


func _eye_points(center: Vector2, side: float) -> PackedVector2Array:
	if _is_side_view():
		return _side_eye_points(center)
	var source_center := _eye_source_center(side)
	var eye_height_value: float = _active_eye_height()
	var width: float = 28.0 * _active_eye_width()
	var lift: float = lerp(7.4, 4.4, _active_eye_roundness()) * eye_height_value
	var lower: float = lerp(7.6, 5.0, _active_eye_roundness()) * eye_height_value
	var angle := _eye_angle(side)
	var source := PackedVector2Array([
		source_center + Vector2(-side * width * 0.46, -2.0 * eye_height_value).rotated(angle),
		source_center + Vector2(-side * width * 0.2, -lift).rotated(angle),
		source_center + Vector2(side * width * 0.5, -5.0 * eye_height_value).rotated(angle),
		source_center + Vector2(side * width * 0.38, lower * 0.62).rotated(angle),
		source_center + Vector2(0.0, lower + 0.7 * eye_height_value).rotated(angle),
		source_center + Vector2(-side * width * 0.34, lower).rotated(angle)
	])
	return _transform_points(center, source)


func _eye_lid_points(center: Vector2, side: float, top: bool) -> PackedVector2Array:
	if _is_side_view():
		return _side_eye_lid_points(center)
	var source_center := _eye_source_center(side)
	var eye_height_value: float = _active_eye_height()
	var width: float = 28.0 * _active_eye_width()
	var lift: float = lerp(8.4, 5.0, _active_eye_roundness()) * eye_height_value
	var drop: float = lerp(8.0, 5.5, _active_eye_roundness()) * eye_height_value
	var angle := _eye_angle(side)
	var start := source_center + Vector2(-side * width * 0.48, -2.2 * eye_height_value if top else drop).rotated(angle)
	var control := source_center + Vector2(side * width * 0.02, -lift if top else drop + 1.4 * eye_height_value).rotated(angle)
	var end := source_center + Vector2(side * width * 0.52, -5.0 * eye_height_value if top else drop * 0.56).rotated(angle)
	return _sample_quadratic(center, start, control, end, 14)


func _side_eye_points(center: Vector2) -> PackedVector2Array:
	var profile_dir := _profile_dir()
	var source_center := _eye_source_center(_profile_eye_side())
	var eye_height_value: float = _active_eye_height()
	var width: float = 24.0 * _active_eye_width()
	var height: float = 10.0 * eye_height_value
	var angle := _eye_angle(_profile_eye_side())
	var source := PackedVector2Array([
		source_center + Vector2(profile_dir * width * 0.46, -height * 0.12).rotated(angle),
		source_center + Vector2(profile_dir * width * 0.1, -height * 0.74).rotated(angle),
		source_center + Vector2(-profile_dir * width * 0.42, -height * 0.45).rotated(angle),
		source_center + Vector2(-profile_dir * width * 0.5, height * 0.34).rotated(angle),
		source_center + Vector2(-profile_dir * width * 0.08, height * 0.62).rotated(angle),
		source_center + Vector2(profile_dir * width * 0.4, height * 0.34).rotated(angle),
	])
	return _transform_points(center, source)


func _side_eye_lid_points(center: Vector2) -> PackedVector2Array:
	var profile_dir := _profile_dir()
	var source_center := _eye_source_center(_profile_eye_side())
	var eye_height_value: float = _active_eye_height()
	var width: float = 24.0 * _active_eye_width()
	var height: float = 10.0 * eye_height_value
	var angle := _eye_angle(_profile_eye_side())
	var start := _side_brow_front_point()
	var control := source_center + Vector2(profile_dir * width * 0.02, -height * 0.98).rotated(angle)
	var end := _side_brow_rear_point()
	return _sample_quadratic(center, start, control, end, 14)


func _sample_quadratic(center: Vector2, p0: Vector2, p1: Vector2, p2: Vector2, steps: int) -> PackedVector2Array:
	return _transform_points(center, _sample_quadratic_source(p0, p1, p2, steps))


func _sample_quadratic_source(p0: Vector2, p1: Vector2, p2: Vector2, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps + 1):
		var t := float(index) / float(steps)
		var a := p0.lerp(p1, t)
		var b := p1.lerp(p2, t)
		points.append(a.lerp(b, t))
	return points


func _ellipse_points(center: Vector2, source_center: Vector2, source_radius: Vector2, rotation: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle: float = TAU * float(index) / float(steps)
		var local := Vector2(cos(angle) * source_radius.x, sin(angle) * source_radius.y).rotated(rotation)
		points.append(_preview_point(center, source_center + local))
	return points


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array(points)
	if not closed.is_empty():
		closed.append(closed[0])
	return closed


func _append_cubic(points: PackedVector2Array, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, steps: int) -> void:
	var start_index := 0 if points.is_empty() else 1
	for index in range(start_index, steps + 1):
		var t := float(index) / float(steps)
		var a := p0.lerp(p1, t)
		var b := p1.lerp(p2, t)
		var c := p2.lerp(p3, t)
		var d := a.lerp(b, t)
		var e := b.lerp(c, t)
		points.append(d.lerp(e, t))


func _append_line(points: PackedVector2Array, p0: Vector2, p1: Vector2, steps: int) -> void:
	var start_index := 0 if points.is_empty() else 1
	for index in range(start_index, steps + 1):
		var t := float(index) / float(steps)
		points.append(p0.lerp(p1, t))


func _append_side_cranium_back_arc(points: PackedVector2Array, cranium_center: Vector2, radius_x: float, radius_y: float, steps: int) -> void:
	var profile_dir := _profile_dir()
	var start_angle: float = atan2(0.62, -0.72)
	var end_angle: float = TAU - PI * 0.5
	for index in range(1, steps + 1):
		var t := float(index) / float(steps)
		var angle: float = lerp(start_angle, end_angle, t)
		var forward_x: float = cos(angle) * radius_x
		var source_y: float = sin(angle) * radius_y
		points.append(cranium_center + Vector2(profile_dir * forward_x, source_y))


func _transform_points(center: Vector2, points: PackedVector2Array) -> PackedVector2Array:
	var transformed := PackedVector2Array()
	for point in points:
		transformed.append(_preview_point(center, point))
	return transformed


func _preview_point(center: Vector2, point: Vector2) -> Vector2:
	var local := point - Vector2(64.0, 64.0)
	local.x *= head_width
	local.y *= head_height
	return center + local * preview_scale


func _draw_oval(center: Vector2, source_point: Vector2, source_radius: Vector2, rotation: float, color: Color) -> void:
	draw_set_transform(_preview_point(center, source_point), rotation, source_radius * preview_scale)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _side_shift() -> float:
	if _is_side_view():
		return 0.0
	if view_direction == VIEW_BACK:
		return 2.2
	return 0.0


func _eye_angle(side: float) -> float:
	return deg_to_rad(_active_eye_angle_degrees()) * side


func _eye_source_center(side: float) -> Vector2:
	if _is_side_view():
		var profile_dir := _profile_dir()
		return Vector2(64.0 + profile_dir * (18.0 + side_eye_x_offset), 81.0 + _active_eye_y_offset())
	var base_spacing: float = 15.0 if view_direction == VIEW_FRONT else 9.0
	return Vector2(64.0 + eye_x_offset + _side_shift() + side * (base_spacing + eye_spacing), 81.0 + eye_y_offset)


func _side_brow_front_point() -> Vector2:
	var profile_dir := _profile_dir()
	var source_center := _eye_source_center(_profile_eye_side())
	var width: float = 24.0 * _active_eye_width()
	var height: float = 10.0 * _active_eye_height()
	var angle := _eye_angle(_profile_eye_side())
	return source_center + Vector2(profile_dir * width * 0.48, -height * 0.2).rotated(angle) + Vector2(profile_dir * side_brow_front_x_offset, side_brow_front_y_offset)


func _side_brow_rear_point() -> Vector2:
	var profile_dir := _profile_dir()
	var source_center := _eye_source_center(_profile_eye_side())
	var width: float = 24.0 * _active_eye_width()
	var height: float = 10.0 * _active_eye_height()
	var angle := _eye_angle(_profile_eye_side())
	return source_center + Vector2(-profile_dir * width * 0.48, -height * 0.48).rotated(angle) + Vector2(profile_dir * side_brow_rear_x_offset, side_brow_rear_y_offset)


func _side_mouth_center() -> Vector2:
	var profile_dir := _profile_dir()
	return Vector2(64.0 + profile_dir * (10.0 + side_face_projection * 0.2 + side_chin_tip_x_offset * 0.15 + side_mouth_x_offset), 95.5 + _active_mouth_y_offset())


func _side_cranium_center() -> Vector2:
	var profile_dir := _profile_dir()
	return Vector2(64.0 - profile_dir * (6.0 + side_cranium_x_offset), 55.5)


func _side_cranium_radius_x() -> float:
	return 42.0 * side_cranium_width


func _side_cranium_radius_y() -> float:
	return 42.0


func _side_jaw_back() -> Vector2:
	var profile_dir := _profile_dir()
	var cranium_center := _side_cranium_center()
	return cranium_center + Vector2(profile_dir * side_jaw_adjustment - profile_dir * _side_cranium_radius_x() * 0.32, side_jaw_height)


func _side_chin_tip() -> Vector2:
	var profile_dir := _profile_dir()
	return Vector2(64.0 + profile_dir * (10.0 + side_chin_tip_x_offset), _chin_bottom_y())


func _side_cranium_front() -> Vector2:
	var profile_dir := _profile_dir()
	return _side_forehead().lerp(_side_brow_join(), 0.58) + Vector2(
		profile_dir * side_cranium_front_x_offset,
		side_cranium_front_y_offset
	)


func _side_forehead() -> Vector2:
	var profile_dir := _profile_dir()
	var cranium_center := _side_cranium_center()
	var radius_x := _side_cranium_radius_x()
	var radius_y := _side_cranium_radius_y()
	return cranium_center + Vector2(
		profile_dir * (radius_x * 0.68 + side_forehead_x_offset),
		-radius_y * 0.55 + side_forehead_y_offset
	)


func _side_brow_join() -> Vector2:
	var profile_dir := _profile_dir()
	var cranium_center := _side_cranium_center()
	var radius_x := _side_cranium_radius_x()
	var radius_y := _side_cranium_radius_y()
	return cranium_center + Vector2(
		profile_dir * (radius_x * 0.86 + side_face_projection * 0.03 + side_brow_join_x_offset),
		-radius_y * 0.18 + side_brow_join_y_offset
	)


func _side_nose_bridge() -> Vector2:
	var profile_dir := _profile_dir()
	var cranium_center := _side_cranium_center()
	var radius_x := _side_cranium_radius_x()
	var radius_y := _side_cranium_radius_y()
	return cranium_center + Vector2(
		profile_dir * (radius_x * 0.82 + side_face_projection * 0.05 + side_nose_bridge_x_offset) + side_nose_x_offset,
		-radius_y * 0.2 + side_nose_y_offset + side_nose_bridge_y_offset
	)


func _side_nose_tip() -> Vector2:
	var profile_dir := _profile_dir()
	var cranium_center := _side_cranium_center()
	var radius_x := _side_cranium_radius_x()
	var radius_y := _side_cranium_radius_y()
	return cranium_center + Vector2(
		profile_dir * (radius_x * 0.98 + side_face_projection * 0.16 + side_nose_tip_x_offset) + side_nose_x_offset,
		radius_y * 0.18 + side_nose_y_offset + side_nose_tip_y_offset
	)


func _side_upper_lip() -> Vector2:
	var profile_dir := _profile_dir()
	var cranium_center := _side_cranium_center()
	var radius_x := _side_cranium_radius_x()
	var radius_y := _side_cranium_radius_y()
	return cranium_center + Vector2(
		profile_dir * (radius_x * 0.8 + side_face_projection * 0.32 + side_upper_lip_x_offset) + side_nose_x_offset,
		radius_y * 0.48 + side_nose_y_offset + side_upper_lip_y_offset
	)


func _visible_face_sides() -> Array[float]:
	if _is_side_view():
		return [_profile_eye_side()]
	return [-1.0, 1.0]


func _is_side_view() -> bool:
	return view_direction == VIEW_SIDE_LEFT or view_direction == VIEW_SIDE_RIGHT or view_direction == VIEW_SIDE_LEGACY


func _profile_dir() -> float:
	if view_direction == VIEW_SIDE_RIGHT:
		return 1.0
	return -1.0


func _profile_eye_side() -> float:
	return -_profile_dir()


func _active_ear_angle_degrees() -> float:
	return side_ear_angle_degrees if _is_side_view() else ear_angle_degrees


func _active_ear_size() -> float:
	return side_ear_size if _is_side_view() else ear_size


func _active_ear_y_offset() -> float:
	if view_direction == VIEW_BACK:
		return back_ear_y_offset
	return side_ear_y_offset if _is_side_view() else ear_y_offset


func _active_eye_width() -> float:
	return side_eye_width if _is_side_view() else eye_width


func _active_eye_height() -> float:
	return side_eye_height if _is_side_view() else eye_height


func _active_eye_roundness() -> float:
	return side_eye_roundness if _is_side_view() else eye_roundness


func _active_eye_angle_degrees() -> float:
	return side_eye_angle_degrees if _is_side_view() else eye_angle_degrees


func _active_eye_y_offset() -> float:
	return side_eye_y_offset if _is_side_view() else eye_y_offset


func _active_pupil_x_offset() -> float:
	return side_pupil_x_offset if _is_side_view() else pupil_x_offset


func _active_pupil_y_offset() -> float:
	return side_pupil_y_offset if _is_side_view() else pupil_y_offset


func _active_pupil_width() -> float:
	return side_pupil_width if _is_side_view() else pupil_width


func _active_pupil_height() -> float:
	return side_pupil_height if _is_side_view() else pupil_height


func _active_mouth_y_offset() -> float:
	return side_mouth_y_offset if _is_side_view() else mouth_y_offset


func _active_mouth_width() -> float:
	return side_mouth_width if _is_side_view() else mouth_width


func _active_mouth_angle_degrees() -> float:
	return side_mouth_angle_degrees if _is_side_view() else mouth_angle_degrees


func _active_mouth_curve() -> float:
	return side_mouth_curve if _is_side_view() else mouth_curve


func _active_mouth_line_width() -> float:
	return side_mouth_line_width if _is_side_view() else mouth_line_width


func _active_mouth_taper() -> float:
	return side_mouth_taper if _is_side_view() else mouth_taper


func _chin_bottom_y() -> float:
	return lerp(116.4, 120.2, inverse_lerp(0.75, 1.3, chin_length))
