@tool
extends RefCounted

const Checker := preload("res://addons/raster_region_polygon/polygon_edit_checker.gd")
const Plan := preload("res://addons/raster_region_polygon/polygon_edit_plan.gd")

var undo_redo: EditorUndoRedoManager


func initialize(p_undo_redo: EditorUndoRedoManager) -> void:
	undo_redo = p_undo_redo


func propose_move(session: RefCounted, local_delta: Vector2) -> RefCounted:
	var precondition: Dictionary = Checker.inspect_target(
		session.target,
		session.baseline_polygon
	)
	if not precondition.valid:
		return Plan.reject(precondition.reason)
	if not session.has_selection():
		return Plan.reject("Select one or more vertices first.")
	var after: PackedVector2Array = session.baseline_polygon.duplicate()
	for index in session.selected_indices:
		if index >= 0 and index < after.size():
			after[index] += local_delta
	return _build_plan(
		Plan.Kind.MOVE_VERTICES,
		session.target,
		session.baseline_polygon,
		after,
		session.target.polygons,
		session.target.polygons
	)


func propose_delete(session: RefCounted) -> RefCounted:
	var precondition: Dictionary = Checker.inspect_target(
		session.target,
		session.baseline_polygon
	)
	if not precondition.valid:
		return Plan.reject(precondition.reason)
	if not session.has_selection():
		return Plan.reject("Select one or more vertices first.")

	var removed := {}
	for index in session.selected_indices:
		removed[index] = true
	var remap := PackedInt32Array()
	remap.resize(session.baseline_polygon.size())
	var after := PackedVector2Array()
	for old_index in session.baseline_polygon.size():
		if removed.has(old_index):
			remap[old_index] = -1
		else:
			remap[old_index] = after.size()
			after.append(session.baseline_polygon[old_index])

	var before_pieces: Array[PackedInt32Array] = session.target.polygons.duplicate(true)
	var source_pieces := before_pieces
	if source_pieces.is_empty():
		source_pieces = [PackedInt32Array(range(session.baseline_polygon.size()))]
	var after_pieces: Array[PackedInt32Array] = []
	for piece in source_pieces:
		var rebuilt := PackedInt32Array()
		for old_index in piece:
			if old_index >= 0 and old_index < remap.size() and remap[old_index] >= 0:
				rebuilt.append(remap[old_index])
		after_pieces.append(rebuilt)
	if before_pieces.is_empty() and after_pieces.size() == 1:
		after_pieces.clear()
	return _build_plan(
		Plan.Kind.DELETE_VERTICES,
		session.target,
		session.baseline_polygon,
		after,
		before_pieces,
		after_pieces
	)


func apply(session: RefCounted, plan: RefCounted) -> bool:
	if not plan.allowed or not is_instance_valid(plan.target):
		return false
	var fresh: Dictionary = Checker.inspect_target(plan.target, plan.before)
	if not fresh.valid:
		return false
	undo_redo.create_action(
		"Move raster polygon vertices"
		if plan.kind == Plan.Kind.MOVE_VERTICES
		else "Delete raster polygon vertices"
	)
	undo_redo.add_do_property(plan.target, "polygon", plan.after)
	undo_redo.add_do_property(plan.target, "polygons", plan.after_polygons)
	undo_redo.add_undo_property(plan.target, "polygon", plan.before)
	undo_redo.add_undo_property(plan.target, "polygons", plan.before_polygons)
	undo_redo.commit_action()
	session.synchronize()
	return true


func _build_plan(
	kind: int,
	target: Polygon2D,
	before: PackedVector2Array,
	after: PackedVector2Array,
	before_pieces: Array[PackedInt32Array],
	after_pieces: Array[PackedInt32Array]
) -> RefCounted:
	var validation: Dictionary = Checker.validate_geometry(after, after_pieces)
	if not validation.valid:
		return Plan.reject(validation.reason)
	var plan := Plan.new()
	plan.kind = kind
	plan.allowed = true
	plan.target = target
	plan.before = before.duplicate()
	plan.after = after
	plan.before_polygons = before_pieces.duplicate(true)
	plan.after_polygons = after_pieces.duplicate(true)
	return plan
