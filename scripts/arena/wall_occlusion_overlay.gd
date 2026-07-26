extends CanvasLayer
class_name WallOcclusionOverlay

const OCCLUSION_LAYERS := preload("res://scripts/arena/wall_occlusion_layers.gd")
const OCCLUSION_MASK_SCRIPT := preload("res://scripts/arena/wall_occlusion_mask.gd")

var _source_viewport: Viewport = null
var _entity_viewport: SubViewport = null
var _mask = null
var _entity_texture: TextureRect = null


func configure(rects: Array[Rect2], source_viewport: Viewport, opacity: float = 0.5) -> void:
	_source_viewport = source_viewport
	if _source_viewport == null:
		visible = false
		return
	_ensure_nodes()
	_mask.configure(rects)
	_entity_texture.modulate = Color(1.0, 1.0, 1.0, clamp(opacity, 0.0, 1.0))
	visible = not rects.is_empty()
	_sync_viewport()


func clear() -> void:
	visible = false
	if _mask != null:
		_mask.configure([])


func _process(_delta: float) -> void:
	if not visible or _source_viewport == null:
		return
	_sync_viewport()


func _ensure_nodes() -> void:
	if _entity_viewport != null:
		return
	layer = 1
	_entity_viewport = SubViewport.new()
	_entity_viewport.name = "EntityOnlyViewport"
	_entity_viewport.transparent_bg = true
	_entity_viewport.disable_3d = true
	_entity_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
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
	if _entity_viewport.size != visible_size:
		_entity_viewport.size = visible_size
		_mask.position = Vector2.ZERO
		_mask.size = Vector2(visible_size)
		_entity_texture.position = Vector2.ZERO
		_entity_texture.size = Vector2(visible_size)
	if _entity_viewport.world_2d != _source_viewport.world_2d:
		_entity_viewport.world_2d = _source_viewport.world_2d
	var source_transform := _source_viewport.canvas_transform
	_entity_viewport.canvas_transform = source_transform
	_mask.update_canvas_transform(source_transform)
