@tool
extends RefCounted

signal state_changed(message: String)

const Session := preload("res://addons/raster_region_polygon/polygon_edit_session.gd")
const Controller := preload("res://addons/raster_region_polygon/polygon_edit_controller.gd")

const HANDLE_RADIUS := 6.0
const DRAG_THRESHOLD := 4.0

var session: RefCounted = Session.new()
var controller: RefCounted = Controller.new()
var editor_interface: EditorInterface
var active := false
var selection_start := Vector2.ZERO
var selection_end := Vector2.ZERO
var selecting := false
var moving := false
var move_start := Vector2.ZERO
var move_preview_delta := Vector2.ZERO


func initialize(
	p_editor_interface: EditorInterface,
	undo_redo: EditorUndoRedoManager
) -> void:
	editor_interface = p_editor_interface
	controller.initialize(undo_redo)


func begin(node: Polygon2D) -> bool:
	if not is_instance_valid(node) or not node.has_meta(&"raster_region_trace"):
		state_changed.emit("Select a plugin-generated Polygon2D before entering vertex edit mode.")
		return false
	session.begin(node)
	active = true
	state_changed.emit("Vertex edit: drag empty space to box-select; drag a selected vertex to move the group.")
	return true


func end() -> void:
	active = false
	selecting = false
	moving = false
	move_preview_delta = Vector2.ZERO
	session.end()
	state_changed.emit("Vertex editing disabled.")


func delete_selected() -> bool:
	if not active:
		return false
	var plan: RefCounted = controller.propose_delete(session)
	if not plan.allowed:
		state_changed.emit(plan.reason)
		return false
	if not controller.apply(session, plan):
		state_changed.emit("The scene changed before deletion could be applied. Reload the polygon.")
		return false
	state_changed.emit("Deleted selected vertices. The polygon is now manually edited.")
	return true


func get_image_vertices(image_size: Vector2i) -> PackedVector2Array:
	var result := PackedVector2Array()
	if not active or not is_instance_valid(session.target):
		return result
	var sprite := session.target.get_parent() as Sprite2D
	if sprite == null:
		return result
	var size := Vector2(image_size)
	var origin := sprite.offset - (size * 0.5 if sprite.centered else Vector2.ZERO)
	for local_point in session.target.polygon:
		var image_point := local_point - origin
		if sprite.flip_h:
			image_point.x = size.x - image_point.x
		if sprite.flip_v:
			image_point.y = size.y - image_point.y
		result.append(image_point)
	return result


func get_selected_indices() -> PackedInt32Array:
	return session.selected_indices.duplicate()


func select_vertex(index: int, additive: bool) -> void:
	if not active or index < 0 or index >= session.target.polygon.size():
		return
	if not additive:
		session.selected_indices.clear()
	if not session.selected_indices.has(index):
		session.selected_indices.append(index)
	state_changed.emit("Selected %d vertices." % session.selected_indices.size())


func select_image_rect(rect: Rect2, image_size: Vector2i, additive: bool) -> void:
	if not active:
		return
	var selected := {}
	if additive:
		for index in session.selected_indices:
			selected[index] = true
	var points := get_image_vertices(image_size)
	for index in points.size():
		if rect.has_point(points[index]):
			selected[index] = true
	var indices: Array = selected.keys()
	indices.sort()
	session.selected_indices = PackedInt32Array(indices)
	state_changed.emit("Selected %d vertices." % session.selected_indices.size())


func move_selected_image_delta(delta: Vector2) -> bool:
	if not active or not session.has_selection():
		return false
	var sprite := session.target.get_parent() as Sprite2D
	if sprite == null:
		return false
	var local_delta := delta
	if sprite.flip_h:
		local_delta.x = -local_delta.x
	if sprite.flip_v:
		local_delta.y = -local_delta.y
	var plan: RefCounted = controller.propose_move(session, local_delta)
	if not plan.allowed:
		state_changed.emit(plan.reason)
		return false
	if not controller.apply(session, plan):
		state_changed.emit("The scene changed before movement could be applied. Reload the polygon.")
		return false
	state_changed.emit("Moved selected vertices. The polygon is now manually edited.")
	return true


func forward_input(event: InputEvent) -> bool:
	if not active or not is_instance_valid(session.target):
		return false
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode in [KEY_DELETE, KEY_BACKSPACE]:
			delete_selected()
			return true
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			session.selected_indices.clear()
			state_changed.emit("Vertex selection cleared.")
			return true
		return false
	if event is InputEventMouseButton:
		return _handle_mouse_button(event as InputEventMouseButton)
	if event is InputEventMouseMotion:
		return _handle_mouse_motion(event as InputEventMouseMotion)
	return false


func draw_overlay(overlay: Control) -> void:
	if not active or not is_instance_valid(session.target):
		return
	var selected := {}
	for index in session.selected_indices:
		selected[index] = true
	for index in session.target.polygon.size():
		var point := _local_to_screen(session.target.polygon[index])
		if moving and selected.has(index):
			point += move_preview_delta
		var color := Color(1.0, 0.75, 0.15) if selected.has(index) else Color(0.2, 0.9, 1.0)
		overlay.draw_circle(point, HANDLE_RADIUS, color)
		overlay.draw_circle(point, HANDLE_RADIUS - 2.0, Color(0.08, 0.08, 0.1))
	if selecting:
		var rect := Rect2(selection_start, selection_end - selection_start).abs()
		overlay.draw_rect(rect, Color(0.2, 0.7, 1.0, 0.14), true)
		overlay.draw_rect(rect, Color(0.2, 0.7, 1.0), false, 1.5)


func _handle_mouse_button(event: InputEventMouseButton) -> bool:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return false
	if event.pressed:
		var hit_index := _find_vertex(event.position)
		if hit_index >= 0:
			if not _is_selected(hit_index):
				if not event.shift_pressed:
					session.selected_indices.clear()
				session.selected_indices.append(hit_index)
			moving = true
			move_start = event.position
			move_preview_delta = Vector2.ZERO
		else:
			selecting = true
			selection_start = event.position
			selection_end = event.position
			if not event.shift_pressed:
				session.selected_indices.clear()
		return true
	if moving:
		moving = false
		if move_preview_delta.length() >= DRAG_THRESHOLD:
			var local_start := _screen_to_local(move_start)
			var local_end := _screen_to_local(event.position)
			var plan: RefCounted = controller.propose_move(session, local_end - local_start)
			if not plan.allowed:
				state_changed.emit(plan.reason)
			elif controller.apply(session, plan):
				state_changed.emit("Moved selected vertices. The polygon is now manually edited.")
			else:
				state_changed.emit("The scene changed before movement could be applied. Reload the polygon.")
		move_preview_delta = Vector2.ZERO
		return true
	if selecting:
		selecting = false
		selection_end = event.position
		_select_in_box(Rect2(selection_start, selection_end - selection_start).abs(), event.shift_pressed)
		state_changed.emit("Selected %d vertices." % session.selected_indices.size())
		return true
	return false


func _handle_mouse_motion(event: InputEventMouseMotion) -> bool:
	if moving:
		move_preview_delta = event.position - move_start
		return true
	if selecting:
		selection_end = event.position
		return true
	return false


func _select_in_box(rect: Rect2, add: bool) -> void:
	var selected := {}
	if add:
		for index in session.selected_indices:
			selected[index] = true
	for index in session.target.polygon.size():
		if rect.has_point(_local_to_screen(session.target.polygon[index])):
			selected[index] = true
	var indices: Array = selected.keys()
	indices.sort()
	session.selected_indices = PackedInt32Array(indices)


func _find_vertex(screen_position: Vector2) -> int:
	for index in session.target.polygon.size():
		if _local_to_screen(session.target.polygon[index]).distance_to(screen_position) <= HANDLE_RADIUS + 3.0:
			return index
	return -1


func _is_selected(index: int) -> bool:
	return session.selected_indices.has(index)


func _canvas_transform() -> Transform2D:
	return session.target.get_viewport().get_canvas_transform()


func _local_to_screen(point: Vector2) -> Vector2:
	return _canvas_transform() * (session.target.get_global_transform() * point)


func _screen_to_local(point: Vector2) -> Vector2:
	var canvas_point := _canvas_transform().affine_inverse() * point
	return session.target.get_global_transform().affine_inverse() * canvas_point
