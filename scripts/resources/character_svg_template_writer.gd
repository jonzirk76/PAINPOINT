extends RefCounted
class_name CharacterSvgTemplateWriter

const SVG_HEADER := "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 128 128\">\n"
const SVG_FOOTER := "</svg>\n"
const MODULE_HAIR_BACK_MASS := "hair_back_mass"
const MODULE_HAIR_SIDE_LOCK_LEFT := "hair_side_lock_left"
const MODULE_HAIR_SIDE_LOCK_RIGHT := "hair_side_lock_right"
const MODULE_HAIR_BANGS := "hair_bangs"
const MODULE_HAIR_PONYTAIL := "hair_ponytail"
const MODULE_HAIR_TOP_LOOP := "hair_top_loop"
const MODULE_HEAD_BASE := "head_base"


static func build_hair_module_svg(recipe: Resource, module: Resource, view_direction: String = "front") -> String:
	var palette: Resource = recipe.palette
	var primary: String = "#" + _to_svg_color(_palette_color(palette, "hair_primary", Color("#6b2cc2")))
	var shadow: String = "#" + _to_svg_color(_palette_color(palette, "hair_shadow", Color("#2a0d4d")))
	var highlight: String = "#" + _to_svg_color(_palette_color(palette, "hair_highlight", Color("#d39cff")))
	var energy: String = "#" + _to_svg_color(_palette_color(palette, "energy", Color("#21c8f6")))
	var random := RandomNumberGenerator.new()
	random.seed = recipe.seed + int(module.role.hash()) + int(view_direction.hash())
	var profile := _hair_profile(recipe, view_direction)
	var title := "%s %s" % [_title_for_role(module.role), view_direction.capitalize()]
	var body := ""
	match module.role:
		MODULE_HAIR_BACK_MASS:
			body = _hair_back_mass(primary, shadow, highlight, profile, random)
		MODULE_HAIR_SIDE_LOCK_LEFT:
			body = _hair_side_lock(primary, shadow, highlight, profile, false, random)
		MODULE_HAIR_SIDE_LOCK_RIGHT:
			body = _hair_side_lock(primary, shadow, highlight, profile, true, random)
		MODULE_HAIR_BANGS:
			body = _hair_bangs(primary, shadow, highlight, profile, random)
		MODULE_HAIR_PONYTAIL:
			body = _hair_ponytail(primary, shadow, highlight, energy, profile, random)
		MODULE_HAIR_TOP_LOOP:
			body = _hair_top_loop(primary, shadow, highlight, profile, random)
		_:
			body = _empty_marker(primary)
	return SVG_HEADER + "  <title>%s</title>\n" % title + body + SVG_FOOTER


static func build_head_module_svg(recipe: Resource, role: String = MODULE_HEAD_BASE, view_direction: String = "front") -> String:
	var profile := _head_profile(recipe, view_direction)
	var title := "Generated Head Base %s" % view_direction.capitalize()
	var body := _head_base(profile)
	return SVG_HEADER + "  <title>%s</title>\n" % title + body + SVG_FOOTER


static func _palette_color(palette: Resource, property_name: String, fallback: Color) -> Color:
	if palette == null:
		return fallback
	var value = palette.get(property_name)
	return value if value is Color else fallback


static func _to_svg_color(color: Color) -> String:
	return color.to_html(false)


static func _title_for_role(role: String) -> String:
	return "Generated %s" % role.replace("_", " ").capitalize()


static func _hair_profile(recipe: Resource, view_direction: String) -> Dictionary:
	var side_factor := 0.0
	if view_direction == "side":
		side_factor = 1.0
	elif view_direction == "back":
		side_factor = 0.35
	return {
		"view": view_direction,
		"side_factor": side_factor,
		"volume": float(recipe.get("hair_volume")),
		"length": float(recipe.get("hair_length")),
		"wildness": float(recipe.get("hair_wildness")),
		"ponytail_length": float(recipe.get("ponytail_length")),
		"back_lock_count": int(recipe.get("back_lock_count")),
		"bang_fringe_count": int(recipe.get("bang_fringe_count")),
		"ponytail_lock_count": int(recipe.get("ponytail_lock_count")),
		"bang_shape": String(recipe.get("bang_shape")),
		"sideburn_type": String(recipe.get("sideburn_type")),
		"ponytail_shape": String(recipe.get("ponytail_shape"))
	}


static func _head_profile(recipe: Resource, view_direction: String) -> Dictionary:
	var side_factor := 0.0
	if view_direction == "side":
		side_factor = 1.0
	elif view_direction == "back":
		side_factor = 0.35
	return {
		"view": view_direction,
		"side_factor": side_factor,
		"eye_shape": String(recipe.get("eye_shape")),
		"eye_width": float(recipe.get("eye_width")),
		"eye_roundness": float(recipe.get("eye_roundness")),
		"eye_angle_degrees": float(recipe.get("eye_angle_degrees")),
		"chin_length": float(recipe.get("chin_length")),
		"chin_roundness": float(recipe.get("chin_roundness"))
	}


static func _head_base(profile: Dictionary) -> String:
	var view := String(profile.view)
	var side_factor: float = float(profile.side_factor)
	var chin_length: float = float(profile.chin_length)
	var chin_roundness: float = float(profile.chin_roundness)
	var bottom_y: float = lerp(116.8, 120.2, clamp(chin_length, 0.75, 1.3) - 0.75)
	var chin_half_width: float = lerp(1.2, 4.8, clamp(chin_roundness, 0.0, 1.0))
	var left_chin_x: float = 64.0 - chin_half_width
	var right_chin_x: float = 64.0 + chin_half_width
	var side_shift: float = side_factor * 6.0
	var eye_cutouts := "" if view == "back" else _head_eye_cutouts(profile, side_shift)
	var eye_rims := "" if view == "back" else _head_eye_rims(profile, side_shift)
	var head_path := _head_outer_path(bottom_y, left_chin_x, right_chin_x, side_shift)
	return (
		"  <defs>\n"
		+ "    <radialGradient id=\"skin_fill\" cx=\"50%\" cy=\"42%\" r=\"70%\">\n"
		+ "      <stop offset=\"0\" stop-color=\"#ffd0aa\"/>\n"
		+ "      <stop offset=\"0.58\" stop-color=\"#f4b284\"/>\n"
		+ "      <stop offset=\"1\" stop-color=\"#e99b6e\"/>\n"
		+ "    </radialGradient>\n"
		+ "    <linearGradient id=\"skin_shadow\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\">\n"
		+ "      <stop offset=\"0\" stop-color=\"#fff1e6\" stop-opacity=\"0.28\"/>\n"
		+ "      <stop offset=\"1\" stop-color=\"#b95f3c\" stop-opacity=\"0.22\"/>\n"
		+ "    </linearGradient>\n"
		+ "  </defs>\n"
		+ "  <g id=\"head_base\">\n"
		+ "    <path id=\"head_with_eye_cutouts\" fill=\"url(#skin_fill)\" fill-rule=\"evenodd\" d=\"%s%s\"/>\n" % [head_path, eye_cutouts]
		+ "    <path d=\"%s\" fill=\"url(#skin_shadow)\" opacity=\"0.55\"/>\n" % head_path
		+ "    <path d=\"%s\" fill=\"none\" stroke=\"#050505\" stroke-width=\"3.2\" stroke-linejoin=\"round\"/>\n" % head_path
		+ "  </g>\n"
		+ eye_rims
		+ "  <g id=\"skin_highlights\">\n"
		+ "    <path d=\"M34.0 44.0 C34.2 33.5 43.5 22.6 49.6 25.4 C54.2 27.5 48.0 36.7 42.6 44.3 C38.6 50.0 35.4 56.3 32.6 64.4 C31.4 57.6 32.2 50.2 34.0 44.0 Z\" fill=\"#fff5f0\" opacity=\"0.62\"/>\n"
		+ "    <path d=\"M94.0 44.0 C93.8 33.5 84.5 22.6 78.4 25.4 C73.8 27.5 80.0 36.7 85.4 44.3 C89.4 50.0 92.6 56.3 95.4 64.4 C96.6 57.6 95.8 50.2 94.0 44.0 Z\" fill=\"#fff5f0\" opacity=\"0.62\"/>\n"
		+ "  </g>\n"
	)


static func _head_outer_path(bottom_y: float, left_chin_x: float, right_chin_x: float, side_shift: float) -> String:
	return (
		"M%.1f 5.0 " % (64.0 + side_shift * 0.4)
		+ "C%.1f 5.2 %.1f 23.5 %.1f 55.4 " % [37.0 + side_shift, 22.0 + side_shift, 21.7 + side_shift]
		+ "C%.1f 68.0 %.1f 80.8 %.1f 91.9 " % [21.6 + side_shift, 24.3 + side_shift, 30.3 + side_shift]
		+ "C%.1f 103.2 %.1f 113.0 %.1f %.1f " % [36.4 + side_shift, 49.0 + side_shift * 0.75, left_chin_x + side_shift * 0.35, bottom_y - 0.9]
		+ "C%.1f %.1f %.1f %.1f %.1f %.1f " % [63.2 + side_shift * 0.2, bottom_y, 64.8 + side_shift * 0.2, bottom_y, right_chin_x + side_shift * 0.35, bottom_y - 0.9]
		+ "C%.1f 113.0 %.1f 103.2 %.1f 91.9 " % [79.0 + side_shift * 0.75, 91.6 + side_shift, 97.7 + side_shift]
		+ "C%.1f 80.8 %.1f 68.0 %.1f 55.4 " % [103.7 + side_shift, 106.4 + side_shift, 106.3 + side_shift]
		+ "C%.1f 23.5 %.1f 5.2 %.1f 5.0 Z " % [106.0 + side_shift, 91.0 + side_shift, 64.0 + side_shift * 0.4]
	)


static func _head_eye_cutouts(profile: Dictionary, side_shift: float) -> String:
	var eye_width: float = float(profile.eye_width)
	var roundness: float = _effective_eye_roundness(profile)
	var angle: float = deg_to_rad(float(profile.eye_angle_degrees))
	var left := _eye_path(Vector2(43.0 + side_shift, 82.0), -1.0, eye_width, roundness, angle)
	var right := _eye_path(Vector2(85.0 + side_shift, 82.0), 1.0, eye_width, roundness, angle)
	return left + right


static func _head_eye_rims(profile: Dictionary, side_shift: float) -> String:
	var eye_width: float = float(profile.eye_width)
	var roundness: float = _effective_eye_roundness(profile)
	var angle: float = deg_to_rad(float(profile.eye_angle_degrees))
	var left_top := _eye_lid_path(Vector2(43.0 + side_shift, 82.0), -1.0, eye_width, roundness, angle, true)
	var right_top := _eye_lid_path(Vector2(85.0 + side_shift, 82.0), 1.0, eye_width, roundness, angle, true)
	var left_bottom := _eye_lid_path(Vector2(43.0 + side_shift, 82.0), -1.0, eye_width, roundness, angle, false)
	var right_bottom := _eye_lid_path(Vector2(85.0 + side_shift, 82.0), 1.0, eye_width, roundness, angle, false)
	return (
		"  <g id=\"eye_cutout_rims\">\n"
		+ "    <path d=\"%s\" fill=\"none\" stroke=\"#050505\" stroke-width=\"3.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>\n" % left_top
		+ "    <path d=\"%s\" fill=\"none\" stroke=\"#050505\" stroke-width=\"3.5\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>\n" % right_top
		+ "    <path d=\"%s\" fill=\"none\" stroke=\"#050505\" stroke-width=\"2.3\" stroke-linecap=\"round\" opacity=\"0.85\"/>\n" % left_bottom
		+ "    <path d=\"%s\" fill=\"none\" stroke=\"#050505\" stroke-width=\"2.3\" stroke-linecap=\"round\" opacity=\"0.85\"/>\n" % right_bottom
		+ "  </g>\n"
	)


static func _effective_eye_roundness(profile: Dictionary) -> float:
	var roundness: float = float(profile.eye_roundness)
	match String(profile.eye_shape):
		"soft":
			roundness = max(roundness, 0.45)
		"round":
			roundness = max(roundness, 0.78)
	return clamp(roundness, 0.0, 1.0)


static func _eye_path(center: Vector2, side: float, width_scale: float, roundness: float, angle: float) -> String:
	var width: float = 28.0 * clamp(width_scale, 0.65, 1.35)
	var top_lift: float = lerp(7.8, 4.8, roundness)
	var lower_drop: float = lerp(7.4, 5.2, roundness)
	var sharp: float = lerp(4.5, 10.0, roundness)
	var outer := center + Vector2(side * width * 0.5, -5.0).rotated(angle)
	var inner := center + Vector2(-side * width * 0.42, -2.2).rotated(angle)
	var lower_inner := center + Vector2(-side * width * 0.34, lower_drop).rotated(angle)
	var lower_outer := center + Vector2(side * width * 0.36, lower_drop * 0.6).rotated(angle)
	var upper_mid := center + Vector2(side * width * 0.06, -top_lift).rotated(angle)
	var lower_mid := center + Vector2(side * width * 0.02, lower_drop + 1.2).rotated(angle)
	return "M%.1f %.1f C%.1f %.1f %.1f %.1f %.1f %.1f C%.1f %.1f %.1f %.1f %.1f %.1f C%.1f %.1f %.1f %.1f %.1f %.1f Z " % [
		inner.x, inner.y,
		inner.x + side * sharp, inner.y - top_lift,
		upper_mid.x - side * 8.0, upper_mid.y,
		outer.x, outer.y,
		outer.x - side * 2.0, outer.y + 8.0,
		lower_outer.x + side * 2.0, lower_outer.y,
		lower_mid.x, lower_mid.y,
		lower_inner.x + side * 5.0, lower_inner.y,
		inner.x + side * 2.0, inner.y + 5.0,
		inner.x, inner.y
	]


static func _eye_lid_path(center: Vector2, side: float, width_scale: float, roundness: float, angle: float, top: bool) -> String:
	var width: float = 28.0 * clamp(width_scale, 0.65, 1.35)
	var lift: float = lerp(8.5, 5.0, roundness)
	var drop: float = lerp(8.2, 5.8, roundness)
	var start := center + Vector2(-side * width * 0.46, -2.4 if top else drop).rotated(angle)
	var end := center + Vector2(side * width * 0.5, -5.0 if top else drop * 0.55).rotated(angle)
	var mid := center + Vector2(side * width * 0.04, -lift if top else drop + 1.4).rotated(angle)
	return "M%.1f %.1f C%.1f %.1f %.1f %.1f %.1f %.1f" % [
		start.x, start.y,
		(start.x + mid.x) * 0.5, mid.y,
		(mid.x + end.x) * 0.5, mid.y,
		end.x, end.y
	]


static func _hair_back_mass(primary: String, shadow: String, highlight: String, profile: Dictionary, random: RandomNumberGenerator) -> String:
	var volume: float = float(profile.volume)
	var length: float = float(profile.length)
	var wildness: float = float(profile.wildness)
	var side_factor: float = float(profile.side_factor)
	var side_lift: float = random.randf_range(-2.0, 2.0)
	var crown_height: float = 18.0 - volume * 3.0
	var left_x: float = lerp(30.0, 43.0, side_factor)
	var right_x: float = lerp(99.0, 94.0, side_factor)
	var bottom_y: float = 89.0 + length * 7.0
	var lock_paths: String = _back_hair_locks(shadow, highlight, int(profile.back_lock_count), wildness, side_factor, length, random)
	return (
		"  <g id=\"hair_back_mass\">\n"
		+ "    <path d=\"M%.1f %.1f C%.1f 31 43 17 64 17 C86 17 100 32 %.1f %.1f C%.1f 72 84 %.1f 64 %.1f C43 %.1f 29 73 %.1f %.1f Z\" fill=\"%s\"/>\n" % [left_x, 53.0 + side_lift, left_x, right_x, 55.0 - side_lift, right_x, bottom_y, bottom_y, bottom_y, left_x, 53.0 + side_lift, shadow]
		+ "    <path d=\"M%.1f %.1f C38 33 50 %.1f 64 %.1f C80 %.1f 92 36 %.1f 56 C91 75 78 %.1f 64 %.1f C48 %.1f 37 73 %.1f %.1f Z\" fill=\"%s\" opacity=\"0.92\"/>\n" % [left_x + 6.0, 55.0 + side_lift, crown_height, crown_height, crown_height + 2.0, right_x - 5.0, bottom_y - 6.0, bottom_y - 6.0, bottom_y - 9.0, left_x + 6.0, 55.0 + side_lift, primary]
		+ "    <path d=\"M45 38 C54 26 72 25 86 36\" fill=\"none\" stroke=\"%s\" stroke-width=\"3.2\" stroke-linecap=\"round\" opacity=\"0.72\"/>\n" % highlight
		+ lock_paths
		+ "  </g>\n"
	)


static func _hair_side_lock(primary: String, shadow: String, highlight: String, profile: Dictionary, mirror: bool, random: RandomNumberGenerator) -> String:
	var sign: float = -1.0 if mirror else 1.0
	var volume: float = float(profile.volume)
	var length: float = float(profile.length)
	var wildness: float = float(profile.wildness)
	var side_factor: float = float(profile.side_factor)
	var root_x: float = lerp(39.0 if not mirror else 89.0, 51.0 if not mirror else 83.0, side_factor)
	var sideburn_bonus: float = 8.0 if String(profile.sideburn_type) == "long" else (-4.0 if String(profile.sideburn_type) == "soft" else 2.0)
	var tip_x: float = root_x - sign * (15.0 + volume * 3.0 + wildness * 4.0 + random.randf_range(-1.0, 1.5))
	var curl_x: float = root_x - sign * (22.0 + random.randf_range(-1.5, 1.5))
	var tip_y: float = 78.0 + length * 8.0 + sideburn_bonus
	var side: String = "right" if mirror else "left"
	return (
		"  <g id=\"hair_side_lock_%s\">\n" % side
		+ "    <path d=\"M%.1f 43 C%.1f 53 %.1f 67 %.1f %.1f C%.1f %.1f %.1f %.1f %.1f %.1f C%.1f 72 %.1f 61 %.1f 50 Z\" fill=\"%s\"/>\n" % [root_x, root_x - sign * 7.0, tip_x, tip_x, tip_y, curl_x, tip_y + 8.0, curl_x - sign * 1.0, tip_y + 9.0, curl_x + sign * 6.0, tip_y + 2.0, tip_x + sign * 4.0, root_x - sign * 2.0, root_x, shadow]
		+ "    <path d=\"M%.1f 45 C%.1f 55 %.1f 66 %.1f %.1f C%.1f 70 %.1f 58 %.1f 49 Z\" fill=\"%s\" opacity=\"0.9\"/>\n" % [root_x + sign * 3.0, root_x - sign * 3.0, tip_x + sign * 4.0, tip_x + sign * 5.0, tip_y - 2.0, tip_x + sign * 8.0, root_x - sign * 1.0, root_x + sign * 4.0, primary]
		+ "    <path d=\"M%.1f 51 C%.1f 62 %.1f 69 %.1f %.1f\" fill=\"none\" stroke=\"%s\" stroke-width=\"2.4\" stroke-linecap=\"round\" opacity=\"0.66\"/>\n" % [root_x - sign * 1.0, root_x - sign * 5.0, tip_x + sign * 5.0, tip_x + sign * 7.0, tip_y - 3.0, highlight]
		+ "  </g>\n"
	)


static func _hair_bangs(primary: String, shadow: String, highlight: String, profile: Dictionary, random: RandomNumberGenerator) -> String:
	var wildness: float = float(profile.wildness)
	var side_factor: float = float(profile.side_factor)
	var shape: String = String(profile.bang_shape)
	var center_drop: float = 55.0 + wildness * 5.0 + random.randf_range(-1.0, 2.0)
	var left_root: float = lerp(38.0, 51.0, side_factor)
	var right_root: float = lerp(96.0, 88.0, side_factor)
	var fringe_paths: String = _bang_fringes(shadow, highlight, int(profile.bang_fringe_count), shape, wildness, side_factor, center_drop, random)
	return (
		"  <g id=\"hair_bangs\">\n"
		+ "    <path d=\"M%.1f 47 C43 31 57 24 73 25 C88 27 %.1f 38 %.1f 50 C83 43 73 43 64 %.1f C54 55 45 56 %.1f 47 Z\" fill=\"%s\"/>\n" % [left_root, right_root, right_root, center_drop, left_root, shadow]
		+ "    <path d=\"M%.1f 45 C48 31 62 27 77 30 C87 33 %.1f 40 %.1f 49 C80 45 71 45 64 %.1f C55 53 48 53 %.1f 45 Z\" fill=\"%s\"/>\n" % [left_root + 4.0, right_root - 3.0, right_root - 3.0, center_drop - 1.0, left_root + 4.0, primary]
		+ "    <path d=\"M51 37 C57 31 69 29 80 34\" fill=\"none\" stroke=\"%s\" stroke-width=\"3\" stroke-linecap=\"round\" opacity=\"0.78\"/>\n" % highlight
		+ fringe_paths
		+ "  </g>\n"
	)


static func _hair_ponytail(primary: String, shadow: String, highlight: String, energy: String, profile: Dictionary, random: RandomNumberGenerator) -> String:
	var length: float = float(profile.ponytail_length) * float(profile.length)
	var wildness: float = float(profile.wildness)
	var side_factor: float = float(profile.side_factor)
	var shape: String = String(profile.ponytail_shape)
	var root_x: float = lerp(70.0, 78.0, side_factor)
	var tip_y: float = 76.0 + length * 22.0 + random.randf_range(-2.0, 2.0)
	var wide_bonus: float = 10.0 if shape == "wide_tail" else 0.0
	var low_bonus: float = 12.0 if shape == "low_tail" else 0.0
	var tip_x: float = lerp(103.0, 96.0, side_factor) + wide_bonus + random.randf_range(-2.0, 3.0)
	var lock_paths: String = _ponytail_locks(shadow, highlight, int(profile.ponytail_lock_count), wildness, root_x, tip_x, tip_y + low_bonus, random)
	return (
		"  <g id=\"hair_ponytail\">\n"
		+ "    <path d=\"M%.1f 24 C86 21 103 33 105 51 C108 70 %.1f %.1f %.1f %.1f C84 %.1f 72 69 72 50 C72 38 69 31 %.1f 24 Z\" fill=\"%s\"/>\n" % [root_x, tip_x, tip_y - 14.0 + low_bonus, tip_x - 18.0, tip_y + low_bonus, tip_y - 3.0 + low_bonus, root_x, shadow]
		+ "    <path d=\"M%.1f 28 C89 29 99 40 99 54 C101 69 %.1f %.1f %.1f %.1f C88 %.1f 77 68 76 51 C77 39 74 33 %.1f 28 Z\" fill=\"%s\" opacity=\"0.93\"/>\n" % [root_x + 5.0, tip_x - 5.0, tip_y - 16.0 + low_bonus, tip_x - 20.0, tip_y - 7.0 + low_bonus, tip_y - 12.0 + low_bonus, root_x + 5.0, primary]
		+ "    <path d=\"M82 31 C93 39 96 55 91 73\" fill=\"none\" stroke=\"%s\" stroke-width=\"3.2\" stroke-linecap=\"round\" opacity=\"0.72\"/>\n" % highlight
		+ "    <path d=\"M72 29 C77 26 83 27 87 31\" fill=\"none\" stroke=\"%s\" stroke-width=\"5\" stroke-linecap=\"round\" opacity=\"0.82\"/>\n" % shadow
		+ "    <path d=\"M73 27 C78 25 84 26 88 30\" fill=\"none\" stroke=\"%s\" stroke-width=\"2.2\" stroke-linecap=\"round\" opacity=\"0.9\"/>\n" % energy
		+ lock_paths
		+ "  </g>\n"
	)


static func _hair_top_loop(primary: String, shadow: String, highlight: String, profile: Dictionary, random: RandomNumberGenerator) -> String:
	var curl: float = 58.0 + random.randf_range(-2.0, 2.0)
	var side_factor: float = float(profile.side_factor)
	var root_shift: float = side_factor * 7.0
	return (
		"  <g id=\"hair_top_loop\">\n"
		+ "    <path d=\"M%.1f 20 C%.1f 10 %.1f 5 %.1f 10 C%.1f 15 %.1f 26 %.1f 31 C%.1f 24 %.1f 19 %.1f 20 Z\" fill=\"%s\"/>\n" % [61.0 + root_shift, 58.0 + root_shift, 68.0 + root_shift, 76.0 + root_shift, 83.0 + root_shift, 82.0 + root_shift, 72.0 + root_shift, 73.0 + root_shift, 69.0 + root_shift, 61.0 + root_shift, shadow]
		+ "    <path d=\"M%.1f 18 C%.1f 11 %.1f 9 %.1f 12 C%.1f 16 %.1f 23 %.1f 26 C%.1f 21 %.1f 18 %.1f 18 Z\" fill=\"%s\"/>\n" % [63.0 + root_shift, 62.0 + root_shift, 69.0 + root_shift, 74.0 + root_shift, 79.0 + root_shift, 77.0 + root_shift, 70.0 + root_shift, 70.0 + root_shift, 67.0 + root_shift, 63.0 + root_shift, primary]
		+ "    <path d=\"M%.1f 16 C%.1f 12 %.1f 12 %.1f 15\" fill=\"none\" stroke=\"%s\" stroke-width=\"2.2\" stroke-linecap=\"round\" opacity=\"0.74\"/>\n" % [64.0 + root_shift, 67.0 + root_shift, 72.0 + root_shift, 75.0 + root_shift, highlight]
		+ "    <path d=\"M%.1f 22 C%.1f 25 %.1f 26 %.1f 25\" fill=\"none\" stroke=\"%s\" stroke-width=\"2.2\" stroke-linecap=\"round\" opacity=\"0.45\"/>\n" % [curl + root_shift, 62.0 + root_shift, 59.0 + root_shift, 56.0 + root_shift, shadow]
		+ "  </g>\n"
	)


static func _back_hair_locks(shadow: String, highlight: String, count: int, wildness: float, side_factor: float, length: float, random: RandomNumberGenerator) -> String:
	var output := ""
	var safe_count: int = clamp(count, 2, 8)
	for index in range(safe_count):
		var ratio: float = 0.0 if safe_count <= 1 else float(index) / float(safe_count - 1)
		var x: float = lerp(43.0, 86.0, ratio) + random.randf_range(-2.5, 2.5) * wildness + side_factor * 5.0
		var y2: float = 69.0 + length * 14.0 + random.randf_range(-5.0, 5.0) * wildness
		var sway: float = (ratio - 0.5) * (12.0 + wildness * 14.0)
		output += "    <path d=\"M%.1f 37 C%.1f 50 %.1f 58 %.1f %.1f\" fill=\"none\" stroke=\"%s\" stroke-width=\"%.1f\" stroke-linecap=\"round\" opacity=\"0.46\"/>\n" % [x, x + sway * 0.2, x + sway * 0.8, x + sway, y2, shadow, 2.6 + wildness * 1.4]
		if index % 2 == 0:
			output += "    <path d=\"M%.1f 43 C%.1f 53 %.1f 60 %.1f %.1f\" fill=\"none\" stroke=\"%s\" stroke-width=\"2.0\" stroke-linecap=\"round\" opacity=\"0.62\"/>\n" % [x - 1.5, x + sway * 0.1, x + sway * 0.55, x + sway * 0.75, y2 - 7.0, highlight]
	return output


static func _bang_fringes(shadow: String, highlight: String, count: int, shape: String, wildness: float, side_factor: float, center_drop: float, random: RandomNumberGenerator) -> String:
	var output := ""
	var safe_count: int = clamp(count, 2, 8)
	for index in range(safe_count):
		var ratio: float = float(index) / float(safe_count)
		var x: float = lerp(50.0, 79.0, ratio) + side_factor * 4.0
		var sweep: float = 8.0 if shape == "swept" else 0.0
		var drop: float = center_drop - abs(ratio - 0.45) * (10.0 if shape == "curtain" else 5.0)
		if shape == "straight":
			drop = center_drop - 2.0
		drop += random.randf_range(-3.0, 3.0) * wildness
		output += "    <path d=\"M%.1f 34 C%.1f 43 %.1f 49 %.1f %.1f\" fill=\"none\" stroke=\"%s\" stroke-width=\"%.1f\" stroke-linecap=\"round\" opacity=\"0.62\"/>\n" % [x, x + sweep * 0.35, x + sweep * 0.7, x + sweep, drop, shadow, 2.1 + wildness * 1.0]
		if index == 0 or index == safe_count - 1:
			output += "    <path d=\"M%.1f 38 C%.1f 43 %.1f 47 %.1f %.1f\" fill=\"none\" stroke=\"%s\" stroke-width=\"1.8\" stroke-linecap=\"round\" opacity=\"0.6\"/>\n" % [x + 2.0, x + sweep * 0.3, x + sweep * 0.5, x + sweep * 0.7, drop - 4.0, highlight]
	return output


static func _ponytail_locks(shadow: String, highlight: String, count: int, wildness: float, root_x: float, tip_x: float, tip_y: float, random: RandomNumberGenerator) -> String:
	var output := ""
	var safe_count: int = clamp(count, 1, 7)
	for index in range(safe_count):
		var ratio: float = 0.0 if safe_count <= 1 else float(index) / float(safe_count - 1)
		var spread: float = (ratio - 0.5) * (10.0 + wildness * 20.0)
		var end_x: float = tip_x - 15.0 + spread + random.randf_range(-3.0, 3.0) * wildness
		var end_y: float = tip_y - 8.0 + random.randf_range(-6.0, 4.0) * wildness
		output += "    <path d=\"M%.1f 35 C%.1f 52 %.1f 70 %.1f %.1f\" fill=\"none\" stroke=\"%s\" stroke-width=\"%.1f\" stroke-linecap=\"round\" opacity=\"0.5\"/>\n" % [root_x + 8.0, root_x + 24.0 + spread * 0.2, tip_x - 4.0 + spread * 0.4, end_x, end_y, shadow, 2.4 + wildness * 1.5]
		if index % 2 == 0:
			output += "    <path d=\"M%.1f 38 C%.1f 54 %.1f 66 %.1f %.1f\" fill=\"none\" stroke=\"%s\" stroke-width=\"2.0\" stroke-linecap=\"round\" opacity=\"0.58\"/>\n" % [root_x + 12.0, root_x + 27.0 + spread * 0.2, tip_x + spread * 0.3, end_x + 3.0, end_y - 8.0, highlight]
	return output


static func _empty_marker(primary: String) -> String:
	return "  <circle id=\"empty_marker\" cx=\"64\" cy=\"64\" r=\"3\" fill=\"%s\"/>\n" % primary
