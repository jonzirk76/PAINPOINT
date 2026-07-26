@tool
extends Resource
class_name CharacterPalette

## Primary hair color used by procedural hair module templates.
@export var hair_primary: Color = Color("#6b2cc2"):
	set(value):
		hair_primary = value
		emit_changed()

## Dark hair shadow color used for underside and outline mass.
@export var hair_shadow: Color = Color("#2a0d4d"):
	set(value):
		hair_shadow = value
		emit_changed()

## Bright hair highlight color used for top-down readability.
@export var hair_highlight: Color = Color("#d39cff"):
	set(value):
		hair_highlight = value
		emit_changed()

## Energy accent color shared with Velora's cyan equipment glow.
@export var energy: Color = Color("#21c8f6"):
	set(value):
		energy = value
		emit_changed()

## Returns an SVG-safe #rrggbb color string.
func to_svg_color(color: Color) -> String:
	return color.to_html(false)


func mutated_copy(seed: int, intensity: float) -> Resource:
	var random := RandomNumberGenerator.new()
	random.seed = seed
	var copy: Resource = get_script().new()
	var shift: float = clamp(intensity, 0.0, 1.0) * 0.18
	copy.hair_primary = hair_primary.lightened(random.randf_range(0.0, shift))
	copy.hair_shadow = hair_shadow.darkened(random.randf_range(0.0, shift))
	copy.hair_highlight = hair_highlight.lightened(random.randf_range(0.0, shift * 0.8))
	copy.energy = energy
	return copy
