extends Node2D
class_name ProjectileVisual

const REFERENCE_RADIUS := 6.0

var glow: Polygon2D = null
var body: Polygon2D = null
var outline: Line2D = null
var highlight: Line2D = null
var direction_streak: Line2D = null


func _ready() -> void:
	_cache_nodes()


func configure(projectile_team: String, projectile_kind: String, radius: float) -> void:
	_cache_nodes()
	if body == null or glow == null or direction_streak == null:
		return
	var colors: Dictionary = _get_palette(projectile_team, projectile_kind)
	body.color = colors["fill"]
	glow.color = Color(colors["fill"], 0.22)
	direction_streak.default_color = colors["streak"]
	set_radius(radius)


func _cache_nodes() -> void:
	if glow == null:
		glow = get_node_or_null("Glow") as Polygon2D
	if body == null:
		body = get_node_or_null("Body") as Polygon2D
	if outline == null:
		outline = get_node_or_null("Outline") as Line2D
	if highlight == null:
		highlight = get_node_or_null("Highlight") as Line2D
	if direction_streak == null:
		direction_streak = get_node_or_null("DirectionStreak") as Line2D


func set_radius(radius: float) -> void:
	var visual_scale: float = max(radius, 0.1) / REFERENCE_RADIUS
	scale = Vector2.ONE * visual_scale


func _get_palette(projectile_team: String, projectile_kind: String) -> Dictionary:
	if projectile_team == "hostile":
		match projectile_kind:
			"agent_grenade":
				return {"fill": Color(1.0, 0.52, 0.12), "streak": Color(1.0, 0.92, 0.24)}
			"agent_mine":
				return {"fill": Color(1.0, 0.18, 0.08), "streak": Color(1.0, 0.78, 0.16)}
		return {"fill": Color(0.9, 0.18, 1.0), "streak": Color(0.34, 0.95, 1.0)}
	match projectile_kind:
		"fire":
			return {"fill": Color(1.0, 0.26, 0.08), "streak": Color(1.0, 0.82, 0.16)}
		"water":
			return {"fill": Color(0.18, 0.62, 1.0), "streak": Color(0.75, 0.95, 1.0)}
		"lightning":
			return {"fill": Color(0.74, 0.48, 1.0), "streak": Color(0.72, 1.0, 1.0)}
		"super":
			return {"fill": Color(1.0, 0.86, 0.18), "streak": Color(0.28, 1.0, 1.0)}
	return {"fill": Color(1.0, 0.92, 0.24), "streak": Color(1.0, 0.42, 0.08)}
