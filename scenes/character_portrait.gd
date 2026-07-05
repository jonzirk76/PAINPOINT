@tool
extends TextureRect
class_name CircularPortrait

@export var portrait: Texture2D:
	set(value):
		portrait = value
		texture = value
