@tool
extends TextureRect
class_name CircularPortraitOlder

@export var portrait: Texture2D:
	set(value):
		portrait = value
		texture = value

func _ready() -> void:
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
