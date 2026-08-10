extends SceneTree

const LoomisProjectionUtil := preload("res://scripts/tools/construction_lab/loomis_head_projection.gd")

const SKULL_OUTPUT_DIR := "res://scenes/tools/anatomy/skull_studies"
const PORTRAIT_OUTPUT := "res://scenes/tools/experiment_polygon_comparison_v2.tscn"
const SKULL_REFERENCE := preload("res://art/concept_art/skull.webp")
const PORTRAIT_REFERENCE := preload("res://art/concept_art/experiment.png")
const OLD_PORTRAIT_SCENE := preload("res://scenes/tools/experiment_polygon_trace.tscn")
const VIEWPORT_SIZE := Vector2(1280.0, 720.0)


func _initialize() -> void:
	var skull_dir_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(SKULL_OUTPUT_DIR)
	)
	if skull_dir_error != OK and skull_dir_error != ERR_ALREADY_EXISTS:
		push_error("Could not create skull-study directory (error %d)." % skull_dir_error)
		quit(1)
		return

	var batch := LoomisProjectionUtil.build_default_tilt_batch()
	for index in range(batch.size()):
		var case_data: Dictionary = batch[index]
		var skull_path := "%s/%02d_%s_skull.tscn" % [
			SKULL_OUTPUT_DIR,
			index + 1,
			_slugify(String(case_data["name"])),
		]
		if not _save_scene(_build_skull_scene(case_data, index), skull_path):
			return

	if not _save_scene(_build_portrait_comparison(), PORTRAIT_OUTPUT):
		return
	quit(0)


func _build_skull_scene(case_data: Dictionary, case_index: int) -> PackedScene:
	var root := Node2D.new()
	root.name = "PolygonSkullStudy%02d" % (case_index + 1)
	_add_background(root, Color("#101722"))
	_label(
		root,
		root,
		"Title",
		Vector2(30.0, 20.0),
		"%02d  POLYGON SKULL STUDY — %s" % [case_index + 1, case_data["name"]],
		27,
		Color("#f2ead8")
	)
	_label(
		root,
		root,
		"Subtitle",
		Vector2(31.0, 60.0),
		"One projected construction; cranium, orbital recesses, nasal aperture, maxilla, teeth, and mandible.",
		15,
		Color("#aebbd0")
	)

	var study_panel := _panel(root, root, "SkullPanel", Rect2(28.0, 98.0, 785.0, 585.0))
	var skull := Node2D.new()
	skull.name = "ProjectedSkull"
	skull.position = Vector2(392.0, 295.0)
	skull.scale = Vector2(2.45, 2.45)
	_owned(study_panel, skull, root)
	_add_projected_skull(skull, root, case_data["construction"])

	var reference_panel := _panel(root, root, "ReferencePanel", Rect2(838.0, 98.0, 414.0, 585.0))
	_label(
		reference_panel,
		root,
		"ReferenceTitle",
		Vector2(18.0, 16.0),
		"ANATOMY REFERENCE",
		19,
		Color("#f2ead8")
	)
	var reference := Sprite2D.new()
	reference.name = "SkullReference"
	reference.texture = SKULL_REFERENCE
	reference.centered = false
	reference.position = Vector2(20.0, 58.0)
	reference.scale = Vector2(0.61, 0.61)
	_owned(reference_panel, reference, root)
	_label(
		reference_panel,
		root,
		"ReferenceNotes",
		Vector2(18.0, 382.0),
		"Polygon interpretation targets:\n"
		+ "• round cranial vault\n"
		+ "• recessed paired orbits\n"
		+ "• triangular nasal aperture\n"
		+ "• cheekbone bridge into maxilla\n"
		+ "• tooth row above a hinged mandible\n\n"
		+ "ConstructionScaffold can be toggled in the scene tree.",
		14,
		Color("#bcc7d5")
	)
	return _pack(root)


func _add_projected_skull(parent: Node2D, root: Node, construction: Dictionary) -> void:
	var cranium_points: PackedVector2Array = construction["sphere_silhouette"]
	var facial_points: PackedVector2Array = construction["facial_plane"]
	var side_points: PackedVector2Array = construction["side_plane"]
	var far_side_points: PackedVector2Array = construction["far_side_plane"]
	var nose_points := _without_close(construction["nose_block"])
	var mouth_points: PackedVector2Array = construction["mouth_bottom_guide"]
	var nose_guide: PackedVector2Array = construction["face_guides"]["nose"]
	var eye_planes: Array = construction["eye_cavity_planes"]

	_poly(parent, root, "CranialVault", cranium_points, Color("#d8c8a4"))
	_poly(parent, root, "NearTemporalMass", side_points, Color(0.61, 0.51, 0.34, 0.52))
	_poly(parent, root, "FacialPlate", facial_points, Color("#c9b68c"))

	var mandible := PackedVector2Array([
		construction["far_jaw_hinge_point"],
		construction["far_chin_point"],
		construction["near_chin_point"],
		construction["jaw_hinge_point"],
	])
	_poly(parent, root, "Mandible", mandible, Color("#b9a477"))

	var maxilla := PackedVector2Array([
		nose_guide[0],
		nose_guide[1],
		mouth_points[1] + Vector2(0.0, 10.0),
		mouth_points[0] + Vector2(0.0, 10.0),
	])
	_poly(parent, root, "Maxilla", maxilla, Color("#dbcba7"))

	var left_lower := _without_close(eye_planes[1])
	var right_lower := _without_close(eye_planes[3])
	var left_cheek_anchor: Vector2 = construction["far_chin_point"].lerp(
		construction["far_jaw_hinge_point"],
		0.34
	)
	var right_cheek_anchor: Vector2 = construction["near_chin_point"].lerp(
		construction["jaw_hinge_point"],
		0.34
	)
	var left_cheek := PackedVector2Array([
		left_lower[3],
		left_lower[2],
		nose_points[2],
		mouth_points[0],
		left_cheek_anchor,
	])
	var right_cheek := PackedVector2Array([
		right_lower[3],
		right_lower[2],
		right_cheek_anchor,
		mouth_points[1],
		nose_points[1],
	])
	_poly(parent, root, "LeftZygomaticAndCheek", left_cheek, Color("#e0d2b1"))
	_poly(parent, root, "RightZygomaticAndCheek", right_cheek, Color("#c2ae80"))
	_line(
		parent,
		root,
		"LeftZygomaticArch",
		PackedVector2Array([left_lower[3], construction["far_jaw_hinge_point"]]),
		Color("#e6d7b7"),
		2.0
	)
	_line(
		parent,
		root,
		"RightZygomaticArch",
		PackedVector2Array([right_lower[2], construction["jaw_hinge_point"]]),
		Color("#d7c39a"),
		2.0
	)

	for cavity_index in range(2):
		var upper: PackedVector2Array = eye_planes[cavity_index * 2]
		var lower: PackedVector2Array = eye_planes[cavity_index * 2 + 1]
		_poly(parent, root, "Orbit%dUpperRecess" % (cavity_index + 1), upper, Color("#2b2926"))
		_poly(parent, root, "Orbit%dLowerRecess" % (cavity_index + 1), lower, Color("#17191a"))
		_line(
			parent,
			root,
			"Orbit%dRim" % (cavity_index + 1),
			_closed(upper),
			Color("#eee2c5"),
			1.45
		)

	_poly(parent, root, "NasalAperture", construction["nose_block"], Color("#17191a"))
	var nasal_bridge := PackedVector2Array([
		nose_points[0] + Vector2(-4.0, -8.0),
		nose_points[0] + Vector2(4.0, -8.0),
		nose_points[1],
		nose_points[2],
	])
	_poly(parent, root, "NasalBridge", nasal_bridge, Color(0.91, 0.84, 0.69, 0.68))

	_add_teeth(parent, root, mouth_points)

	_line(parent, root, "CraniumContour", _closed(cranium_points), Color("#f5ead2"), 1.6)
	_line(parent, root, "FacialContour", _closed(facial_points), Color("#f5ead2"), 1.5)
	_line(parent, root, "MandibleContour", _closed(mandible), Color("#f5ead2"), 1.6)
	_line(parent, root, "NearJaw", construction["jawline"], Color("#f0dfbd"), 2.0)
	_line(parent, root, "FarJaw", construction["far_jawline"], Color(0.94, 0.86, 0.70, 0.55), 1.4)

	var scaffold := Node2D.new()
	scaffold.name = "ConstructionScaffold"
	scaffold.visible = false
	_owned(parent, scaffold, root)
	_line(scaffold, root, "Brow", construction["face_guides"]["brow"], Color("#f09ac0"), 1.3)
	_line(scaffold, root, "Nose", nose_guide, Color("#e8b778"), 1.3)
	_line(scaffold, root, "MouthBottomThroughTeeth", mouth_points, Color("#e87086"), 1.3)
	_line(scaffold, root, "Chin", construction["face_guides"]["chin"], Color("#f4d78a"), 1.3)
	_line(scaffold, root, "Center", construction["face_center_descent"], Color("#62dce9"), 1.4)
	_line(scaffold, root, "NearSideEllipse", side_points, Color("#f2a06f"), 1.2)
	_line(scaffold, root, "FarSideEllipse", far_side_points, Color(0.95, 0.49, 0.39, 0.34), 1.0)


func _add_teeth(parent: Node, root: Node, mouth_points: PackedVector2Array) -> void:
	var left := mouth_points[0]
	var right := mouth_points[1]
	var tooth_count := 8
	for index in range(tooth_count):
		var t0 := float(index) / float(tooth_count)
		var t1 := float(index + 1) / float(tooth_count)
		var top_left := left.lerp(right, t0) + Vector2(0.0, -6.0)
		var top_right := left.lerp(right, t1) + Vector2(0.0, -6.0)
		var bottom_right := left.lerp(right, t1) + Vector2(0.0, 6.0)
		var bottom_left := left.lerp(right, t0) + Vector2(0.0, 6.0)
		_poly(
			parent,
			root,
			"Tooth%02d" % (index + 1),
			PackedVector2Array([top_left, top_right, bottom_right, bottom_left]),
			Color("#eee5cf") if index % 2 == 0 else Color("#d8cdb5")
		)
		_line(
			parent,
			root,
			"ToothSeam%02d" % (index + 1),
			PackedVector2Array([top_right, bottom_right]),
			Color(0.34, 0.29, 0.23, 0.68),
			0.7
		)


func _build_portrait_comparison() -> PackedScene:
	var root := Node2D.new()
	root.name = "ExperimentPolygonComparisonV2"
	_add_background(root, Color("#111722"))
	_label(
		root,
		root,
		"Title",
		Vector2(28.0, 18.0),
		"ANIME PORTRAIT POLYGON STUDY — SOURCE / OLD / CONSTRUCTION-DRIVEN",
		25,
		Color("#edf2fa")
	)
	_label(
		root,
		root,
		"Subtitle",
		Vector2(29.0, 55.0),
		"The new attempt uses anime proportions over the brow, orbit, nose, mouth, and jaw construction.",
		15,
		Color("#aebbd0")
	)

	var source_panel := _panel(root, root, "SourcePanel", Rect2(22.0, 92.0, 390.0, 600.0))
	var old_panel := _panel(root, root, "OldAttemptPanel", Rect2(445.0, 92.0, 390.0, 600.0))
	var new_panel := _panel(root, root, "NewAttemptPanel", Rect2(868.0, 92.0, 390.0, 600.0))
	_label(source_panel, root, "PanelTitle", Vector2(18.0, 15.0), "SOURCE — experiment.png", 17, Color("#aebbd0"))
	_label(old_panel, root, "PanelTitle", Vector2(18.0, 15.0), "OLD POLYGON ATTEMPT", 17, Color("#f0a7bd"))
	_label(new_panel, root, "PanelTitle", Vector2(18.0, 15.0), "NEW CONSTRUCTION ATTEMPT", 17, Color("#6fe0ea"))

	var source := Sprite2D.new()
	source.name = "ExperimentReference"
	source.texture = PORTRAIT_REFERENCE
	source.centered = false
	source.position = Vector2(23.0, 72.0)
	source.scale = Vector2(0.25, 0.25)
	_owned(source_panel, source, root)

	var old_scene := OLD_PORTRAIT_SCENE.instantiate()
	var old_artwork := old_scene.get_node("Artwork")
	old_scene.remove_child(old_artwork)
	_clear_owner_recursive(old_artwork)
	old_artwork.name = "OldArtwork"
	old_artwork.position = Vector2(28.0, 73.0)
	_owned(old_panel, old_artwork, root)
	_set_owner_recursive(old_artwork, root)
	old_scene.free()

	var new_artwork := Node2D.new()
	new_artwork.name = "NewArtwork"
	new_artwork.position = Vector2(28.0, 73.0)
	_owned(new_panel, new_artwork, root)
	_add_new_portrait(new_artwork, root)

	_label(
		source_panel,
		root,
		"Notes",
		Vector2(18.0, 380.0),
		"Reference proportions:\nlarge anime orbits, compact nose,\nsmall mouth, tapered jaw,\nlarge cranial and hair mass.",
		14,
		Color("#bac5d4")
	)
	_label(
		old_panel,
		root,
		"Notes",
		Vector2(18.0, 380.0),
		"Earlier direct polygon trace.\nFeatures follow the image,\nbut do not share an explicit\nunderlying facial-plane model.",
		14,
		Color("#bac5d4")
	)
	_label(
		new_panel,
		root,
		"Notes",
		Vector2(18.0, 380.0),
		"Near eye enlarged by perspective;\nfar eye compressed; nose follows\nthe center plane; mouth sits midway\nto the anime-shortened chin.",
		14,
		Color("#bac5d4")
	)
	return _pack(root)


func _add_new_portrait(parent: Node2D, root: Node) -> void:
	# Back silhouette and torso.
	_poly(parent, root, "BackHair", _p([
		22, 266, 30, 218, 53, 174, 63, 118, 72, 70, 105, 24, 145, 5,
		193, 7, 232, 31, 258, 70, 272, 116, 283, 166, 304, 222, 321, 269,
		279, 252, 247, 217, 221, 234, 181, 243, 139, 237, 100, 215, 65, 248,
	]), Color("#1a1038"))
	_poly(parent, root, "Shoulders", _p([
		27, 270, 43, 245, 86, 228, 126, 220, 160, 228, 195, 222,
		239, 227, 282, 243, 316, 270,
	]), Color("#07142d"))
	_poly(parent, root, "JacketLeft", _p([
		43, 245, 87, 229, 126, 222, 143, 237, 128, 254, 135, 270, 76, 270,
	]), Color("#0755bd"))
	_poly(parent, root, "JacketRight", _p([
		195, 224, 239, 227, 281, 244, 314, 270, 222, 270, 210, 246,
	]), Color("#064ba9"))
	_poly(parent, root, "ChestArmor", _p([
		125, 222, 150, 208, 181, 210, 207, 222, 229, 244, 219, 270, 135, 270,
	]), Color("#11182b"))
	_poly(parent, root, "NeckShadow", _p([137, 180, 158, 195, 180, 201, 199, 186, 196, 224, 174, 233, 143, 218]), Color("#a65f59"))
	_poly(parent, root, "Neck", _p([153, 188, 176, 202, 195, 189, 193, 218, 176, 226, 154, 214]), Color("#d99784"))
	_poly(parent, root, "HighCollar", _p([
		119, 208, 142, 195, 166, 214, 175, 231, 186, 211, 204, 202,
		225, 242, 202, 235, 176, 240, 145, 235, 121, 248,
	]), Color("#080d1a"))

	# Anime-shortened facial shell and planar shading.
	_poly(parent, root, "FarEar", _p([227, 112, 237, 110, 241, 119, 239, 139, 231, 150, 225, 142]), Color("#c97f72"))
	_poly(parent, root, "NearEar", _p([99, 109, 89, 111, 85, 121, 88, 143, 99, 153, 105, 143]), Color("#df9d87"))
	_poly(parent, root, "FaceBase", _p([
		102, 91, 111, 70, 129, 54, 151, 46, 178, 45, 202, 52, 221, 67,
		232, 89, 235, 113, 231, 139, 220, 160, 204, 180, 184, 198,
		169, 205, 151, 198, 132, 184, 116, 167, 105, 147, 99, 124, 98, 105,
	]), Color("#e3a998"))
	_poly(parent, root, "FarFacePlane", _p([
		176, 47, 202, 53, 221, 68, 232, 90, 234, 116, 226, 140,
		214, 160, 192, 177, 180, 159, 184, 132, 180, 104,
	]), Color(0.67, 0.34, 0.40, 0.18))
	_poly(parent, root, "NearCheekPlane", _p([
		104, 132, 122, 146, 153, 151, 174, 161, 165, 192, 150, 198,
		129, 181, 115, 164,
	]), Color(0.98, 0.73, 0.67, 0.34))
	_poly(parent, root, "MuzzlePlane", _p([
		151, 153, 177, 148, 203, 158, 196, 184, 174, 193, 151, 184,
	]), Color(0.95, 0.68, 0.62, 0.22))
	_poly(parent, root, "JawPlane", _p([
		115, 165, 151, 198, 169, 205, 184, 198, 205, 179, 195, 190,
		173, 211, 150, 202, 130, 187,
	]), Color(0.58, 0.29, 0.36, 0.18))

	# Two-plane socket shadows, then eyes seated on their exit planes.
	_poly(parent, root, "NearOrbitUpperPlane", _p([112, 103, 132, 96, 157, 101, 164, 112, 140, 111, 119, 116]), Color(0.38, 0.16, 0.34, 0.18))
	_poly(parent, root, "NearOrbitLowerPlane", _p([119, 116, 140, 111, 164, 112, 159, 141, 135, 148, 113, 137]), Color(0.56, 0.30, 0.43, 0.15))
	_poly(parent, root, "FarOrbitUpperPlane", _p([188, 105, 205, 100, 225, 104, 233, 114, 214, 113, 194, 117]), Color(0.34, 0.14, 0.32, 0.19))
	_poly(parent, root, "FarOrbitLowerPlane", _p([194, 117, 214, 113, 233, 114, 229, 140, 211, 146, 192, 136]), Color(0.54, 0.28, 0.42, 0.15))
	_poly(parent, root, "NearEyeWhite", _p([
		116, 120, 124, 113, 137, 110, 151, 114, 160, 122, 160, 132,
		153, 141, 140, 146, 126, 142, 117, 133,
	]), Color("#f7eff5"))
	_poly(parent, root, "NearIris", _p([130, 112, 143, 111, 153, 119, 156, 131, 151, 142, 140, 146, 131, 139, 127, 126]), Color("#7445bb"))
	_poly(parent, root, "NearPupil", _p([137, 115, 145, 115, 150, 124, 149, 136, 142, 141, 136, 134, 134, 123]), Color("#251147"))
	_poly(parent, root, "NearEyeHighlight", _p([130, 115, 136, 111, 141, 115, 139, 122, 132, 123]), Color.WHITE)
	_poly(parent, root, "NearUpperLash", _p([
		111, 119, 121, 111, 136, 106, 151, 110, 163, 119, 168, 126,
		159, 123, 151, 115, 138, 111, 125, 114, 117, 122,
	]), Color("#140b22"))
	_poly(parent, root, "FarEyeWhite", _p([
		191, 121, 198, 115, 209, 112, 220, 116, 228, 123, 229, 132,
		223, 140, 213, 145, 202, 141, 194, 134,
	]), Color("#f5edf4"))
	_poly(parent, root, "FarIris", _p([201, 115, 211, 113, 221, 119, 225, 129, 221, 140, 213, 145, 204, 141, 200, 130]), Color("#6e3fb3"))
	_poly(parent, root, "FarPupil", _p([207, 117, 214, 116, 218, 124, 217, 136, 211, 141, 206, 134, 205, 123]), Color("#251147"))
	_poly(parent, root, "FarEyeHighlight", _p([201, 118, 206, 114, 211, 118, 209, 124, 203, 125]), Color.WHITE)
	_poly(parent, root, "FarUpperLash", _p([
		187, 121, 196, 113, 209, 108, 222, 112, 231, 120, 236, 126,
		228, 123, 220, 117, 210, 113, 199, 115, 192, 123,
	]), Color("#140b22"))
	_poly(parent, root, "NearBrow", _p([112, 100, 130, 95, 151, 99, 161, 104, 148, 101, 130, 99, 114, 104]), Color("#25153e"))
	_poly(parent, root, "FarBrow", _p([190, 102, 205, 98, 224, 101, 232, 106, 221, 104, 205, 102, 191, 106]), Color("#211237"))

	# Nose follows the center plane; mouth bottom sits midway to the shortened chin.
	_poly(parent, root, "NoseSidePlane", _p([175, 132, 180, 143, 183, 156, 179, 162, 174, 156, 176, 144]), Color(0.60, 0.28, 0.32, 0.45))
	_poly(parent, root, "NoseFrontPlane", _p([175, 132, 178, 145, 178, 158, 174, 156]), Color(0.98, 0.77, 0.69, 0.52))
	_poly(parent, root, "NoseBase", _p([174, 156, 178, 158, 183, 156, 180, 162, 176, 161]), Color(0.50, 0.23, 0.29, 0.32))
	_poly(parent, root, "Mouth", _p([164, 181, 171, 179, 178, 180, 185, 179, 190, 181, 184, 183, 177, 184, 170, 183]), Color("#6d3947"))
	_poly(parent, root, "LowerLip", _p([169, 187, 177, 188, 185, 186, 181, 190, 174, 191]), Color(0.95, 0.67, 0.65, 0.68))
	_poly(parent, root, "NearBlush", _p([111, 147, 134, 150, 153, 156, 143, 166, 120, 159]), Color(0.97, 0.38, 0.47, 0.17))
	_poly(parent, root, "FarBlush", _p([198, 150, 219, 144, 227, 156, 207, 163]), Color(0.97, 0.38, 0.47, 0.15))

	# Hair follows the enlarged anime cranial mass while preserving the facial anchors.
	_poly(parent, root, "HairCap", _p([
		60, 104, 68, 72, 83, 43, 106, 21, 139, 7, 176, 4,
		210, 14, 237, 35, 256, 64, 267, 96, 254, 91, 241, 78,
		228, 62, 212, 45, 192, 31, 168, 23, 143, 26, 121, 39,
		102, 57, 89, 79, 80, 104,
	]), Color("#33205e"))
	_poly(parent, root, "CenterBangNear", _p([
		125, 35, 145, 21, 163, 17, 155, 39, 152, 63, 153, 87,
		159, 108, 168, 126, 158, 120, 149, 105, 141, 121,
		132, 134, 135, 113, 133, 88, 129, 62,
	]), Color("#49307b"))
	_poly(parent, root, "CenterBangFar", _p([
		170, 18, 187, 25, 200, 43, 204, 66, 203, 89, 207, 108,
		199, 116, 193, 104, 188, 118, 179, 130, 166, 139,
		174, 123, 179, 104, 178, 82, 174, 57,
	]), Color("#382263"))
	_poly(parent, root, "NearSideLock", _p([
		86, 47, 70, 70, 62, 99, 58, 126, 48, 153, 35, 181,
		52, 168, 68, 146, 78, 121, 87, 94, 99, 67,
	]), Color("#392366"))
	_poly(parent, root, "FarSideLock", _p([
		207, 35, 226, 46, 241, 66, 250, 94, 254, 123, 267, 146,
		282, 151, 270, 141, 260, 126, 257, 155, 266, 183, 281, 207,
		265, 196, 249, 176, 239, 153, 232, 127, 226, 96, 217, 63,
	]), Color("#2d1a55"))
	_poly(parent, root, "CrownHighlight", _p([
		83, 54, 108, 28, 139, 14, 174, 12, 202, 22, 177, 24,
		151, 31, 127, 43, 105, 64,
	]), Color("#553791"))

	var scaffold := Node2D.new()
	scaffold.name = "ConstructionOverlay"
	scaffold.visible = false
	_owned(parent, scaffold, root)
	_line(scaffold, root, "BrowGuide", _p([101, 104, 128, 98, 158, 101, 187, 104, 232, 108]), Color("#f09ac0"), 1.5)
	_line(scaffold, root, "NoseGuide", _p([102, 154, 136, 151, 177, 157, 229, 151]), Color("#e8b778"), 1.5)
	_line(scaffold, root, "MouthGuide", _p([113, 181, 146, 180, 176, 182, 213, 181]), Color("#e87086"), 1.3)
	_line(scaffold, root, "CenterLine", _p([171, 47, 173, 92, 174, 126, 178, 160, 176, 183, 169, 205]), Color("#62dce9"), 1.5)
	_line(scaffold, root, "JawGuide", _p([99, 124, 116, 167, 151, 198, 169, 205, 204, 180, 231, 139]), Color("#f2cf83"), 1.5)


func _save_scene(packed: PackedScene, path: String) -> bool:
	var error := ResourceSaver.save(packed, path)
	if error != OK:
		push_error("Could not save %s (error %d)." % [path, error])
		quit(1)
		return false
	print("Generated %s" % path)
	return true


func _pack(root: Node) -> PackedScene:
	var packed := PackedScene.new()
	var error := packed.pack(root)
	if error != OK:
		push_error("Could not pack generated anatomy scene (error %d)." % error)
	root.free()
	return packed


func _add_background(root: Node2D, color: Color) -> void:
	_poly(root, root, "Background", _p([
		0, 0, VIEWPORT_SIZE.x, 0, VIEWPORT_SIZE.x, VIEWPORT_SIZE.y, 0, VIEWPORT_SIZE.y,
	]), color)


func _panel(parent: Node, root: Node, node_name: String, rect: Rect2) -> Node2D:
	var panel := Node2D.new()
	panel.name = node_name
	panel.position = rect.position
	_owned(parent, panel, root)
	_poly(panel, root, "Fill", _p([0, 0, rect.size.x, 0, rect.size.x, rect.size.y, 0, rect.size.y]), Color("#182333"))
	_line(panel, root, "Border", _p([0, 0, rect.size.x, 0, rect.size.x, rect.size.y, 0, rect.size.y, 0, 0]), Color("#35445a"), 1.2)
	return panel


func _poly(
	parent: Node,
	root: Node,
	node_name: String,
	points: PackedVector2Array,
	color: Color
) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = _without_close(points)
	polygon.color = color
	polygon.antialiased = true
	_owned(parent, polygon, root)
	return polygon


func _line(
	parent: Node,
	root: Node,
	node_name: String,
	points: PackedVector2Array,
	color: Color,
	width: float
) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.default_color = color
	line.width = width
	line.antialiased = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	_owned(parent, line, root)
	return line


func _label(
	parent: Node,
	root: Node,
	node_name: String,
	position: Vector2,
	text_value: String,
	font_size: int,
	color: Color
) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = position
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_owned(parent, label, root)
	return label


func _owned(parent: Node, child: Node, root: Node) -> void:
	parent.add_child(child)
	child.owner = root


func _set_owner_recursive(node: Node, root: Node) -> void:
	node.owner = root
	for child in node.get_children():
		_set_owner_recursive(child, root)


func _clear_owner_recursive(node: Node) -> void:
	node.owner = null
	for child in node.get_children():
		_clear_owner_recursive(child)


func _p(values: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(0, values.size(), 2):
		points.append(Vector2(float(values[index]), float(values[index + 1])))
	return points


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty() and not result[0].is_equal_approx(result[result.size() - 1]):
		result.append(result[0])
	return result


func _without_close(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if result.size() > 1 and result[0].is_equal_approx(result[result.size() - 1]):
		result.remove_at(result.size() - 1)
	return result


func _slugify(value: String) -> String:
	return value.to_lower().replace(" ", "_").replace("-", "_")
