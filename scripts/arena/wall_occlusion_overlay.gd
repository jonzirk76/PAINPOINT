extends CanvasLayer
class_name WallOcclusionOverlay

const OCCLUSION_LAYERS := preload("res://scripts/arena/wall_occlusion_layers.gd")
const OCCLUSION_MASK_SCRIPT := preload("res://scripts/arena/wall_occlusion_mask.gd")

var _source_viewport: Viewport = null
var _entity_viewport: SubViewport = null
var _mask = null
var _entity_texture: TextureRect = null
var _wall_rects: Array[Rect2] = []
var _candidate_margin: float = 180.0
var _viewport_scale: float = 0.5
var _active_room_id: String = ""
var _candidate_capture_states: Dictionary = {}
var _candidate_cell_size: float = 180.0
var _candidate_cell_lookup: Dictionary = {}


func configure(
	rects: Array[Rect2],
	source_viewport: Viewport,
	opacity: float = 0.5,
	candidate_margin: float = 180.0,
	viewport_scale: float = 0.5,
	active_room_id: String = ""
) -> void:
	_source_viewport = source_viewport
	if _source_viewport == null:
		visible = false
		return
	_ensure_nodes()
	_wall_rects = rects.duplicate()
	_candidate_margin = max(candidate_margin, 0.0)
	_viewport_scale = clamp(viewport_scale, 0.25, 1.0)
	_active_room_id = active_room_id
	_rebuild_candidate_cell_lookup()
	_mask.configure(rects)
	_entity_texture.modulate = Color(1.0, 1.0, 1.0, clamp(opacity, 0.0, 1.0))
	_sync_candidates()
	if visible:
		_sync_viewport()


func clear() -> void:
	visible = false
	_wall_rects.clear()
	_candidate_cell_lookup.clear()
	_disable_all_candidates()
	if _mask != null:
		var empty_rects: Array[Rect2] = []
		_mask.configure(empty_rects)
	if _entity_viewport != null:
		_entity_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _process(_delta: float) -> void:
	if _source_viewport == null:
		return
	_sync_candidates()
	if not visible:
		return
	_sync_viewport()


func _ensure_nodes() -> void:
	if _entity_viewport != null:
		return
	# The translucent entity composite sits above opaque fog and below UI.
	layer = 1
	_entity_viewport = SubViewport.new()
	_entity_viewport.name = "EntityOnlyViewport"
	_entity_viewport.transparent_bg = true
	_entity_viewport.disable_3d = true
	_entity_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_entity_viewport.canvas_cull_mask = OCCLUSION_LAYERS.ENTITY_VISIBILITY_LAYER
	add_child(_entity_viewport)
	_mask = OCCLUSION_MASK_SCRIPT.new()
	_mask.name = "WallMask"
	_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	add_child(_mask)
	_entity_texture = TextureRect.new()
	_entity_texture.name = "OccludedEntities"
	_entity_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_entity_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_entity_texture.texture = _entity_viewport.get_texture()
	_mask.add_child(_entity_texture)


func _sync_viewport() -> void:
	var visible_size := Vector2i(_source_viewport.get_visible_rect().size)
	if visible_size.x <= 0 or visible_size.y <= 0:
		return
	var render_size := Vector2i(
		max(int(round(float(visible_size.x) * _viewport_scale)), 1),
		max(int(round(float(visible_size.y) * _viewport_scale)), 1)
	)
	if _entity_viewport.size != render_size:
		_entity_viewport.size = render_size
		_mask.position = Vector2.ZERO
		_mask.size = Vector2(visible_size)
		_entity_texture.position = Vector2.ZERO
		_entity_texture.size = Vector2(visible_size)
	if _entity_viewport.world_2d != _source_viewport.world_2d:
		_entity_viewport.world_2d = _source_viewport.world_2d
	var source_transform := _source_viewport.canvas_transform
	var render_scale_transform := Transform2D.IDENTITY.scaled(Vector2(_viewport_scale, _viewport_scale))
	_entity_viewport.canvas_transform = render_scale_transform * source_transform
	_mask.update_canvas_transform(source_transform)


func _sync_candidates() -> void:
	if _entity_viewport == null:
		return
	var active_count := 0
	var seen_ids: Dictionary = {}
	for candidate in get_tree().get_nodes_in_group(OCCLUSION_LAYERS.CANDIDATE_GROUP):
		if candidate == null or not is_instance_valid(candidate):
			continue
		var candidate_id: int = candidate.get_instance_id()
		seen_ids[candidate_id] = true
		var should_capture := _candidate_overlaps_wall(candidate)
		if should_capture:
			active_count += 1
		if not _candidate_capture_states.has(candidate_id) or bool(_candidate_capture_states[candidate_id]) != should_capture:
			OCCLUSION_LAYERS.set_entity_capture_enabled(candidate, should_capture)
			_candidate_capture_states[candidate_id] = should_capture
	for candidate_id in _candidate_capture_states.keys():
		if not seen_ids.has(candidate_id):
			_candidate_capture_states.erase(candidate_id)
	visible = active_count > 0 and not _wall_rects.is_empty()
	_entity_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS
		if visible
		else SubViewport.UPDATE_DISABLED
	)


func _candidate_overlaps_wall(candidate: Node) -> bool:
	if _wall_rects.is_empty() or not candidate is Node2D:
		return false
	if not _candidate_belongs_to_active_room(candidate):
		return false
	var candidate_position: Vector2 = (candidate as Node2D).global_position
	return _candidate_cell_lookup.has(_candidate_cell_key(candidate_position))


func _candidate_belongs_to_active_room(candidate: Node) -> bool:
	if candidate.is_in_group("player"):
		return true
	if _active_room_id.is_empty():
		return true
	var candidate_room_id := String(candidate.get_meta(OCCLUSION_LAYERS.ROOM_ID_META, ""))
	return not candidate_room_id.is_empty() and candidate_room_id == _active_room_id


func _rebuild_candidate_cell_lookup() -> void:
	_candidate_cell_lookup.clear()
	_candidate_cell_size = max(_candidate_margin, 80.0)
	for wall_rect in _wall_rects:
		var eligibility_rect := wall_rect.grow(_candidate_margin)
		var min_cell := _candidate_cell_coord(eligibility_rect.position)
		var max_cell := _candidate_cell_coord(eligibility_rect.end)
		for cell_y in range(min_cell.y, max_cell.y + 1):
			for cell_x in range(min_cell.x, max_cell.x + 1):
				_candidate_cell_lookup[_candidate_cell_key_from_coord(Vector2i(cell_x, cell_y))] = true


func _candidate_cell_coord(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / _candidate_cell_size),
		floori(world_position.y / _candidate_cell_size)
	)


func _candidate_cell_key(world_position: Vector2) -> String:
	return _candidate_cell_key_from_coord(_candidate_cell_coord(world_position))


func _candidate_cell_key_from_coord(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]


func _disable_all_candidates() -> void:
	if not is_inside_tree():
		_candidate_capture_states.clear()
		return
	for candidate in get_tree().get_nodes_in_group(OCCLUSION_LAYERS.CANDIDATE_GROUP):
		if candidate != null and is_instance_valid(candidate):
			OCCLUSION_LAYERS.set_entity_capture_enabled(candidate, false)
	_candidate_capture_states.clear()
