extends Node
class_name AudioManager

const PLAYER_BULLET_SHOT := preload("res://audio/player_bullet_shot.wav")
const ENEMY_BULLET_SHOT := preload("res://audio/enemy_bullet_shot.wav")
const BULLET_IMPACT := preload("res://audio/bullet_impact.wav")
const BULLET_HITS_WALL := preload("res://audio/bullet_hits_wall.wav")
const ROCKET_EXPLOSION := preload("res://audio/rocket_explosion.wav")
const PARRY := preload("res://audio/parry.wav")
const PARRY_READY := preload("res://audio/parry_ready.wav")
const PERFECT_PARRY_FOLLOW_UP := preload("res://audio/perfect_parry_follow_up.wav")
const ITEM_PICK_UP := preload("res://audio/item_pick_up.wav")
const FLOOR_START := preload("res://audio/floor_start.wav")
const ROOM_ENTRY := preload("res://audio/room_entry.wav")
const GAME_OVER := preload("res://audio/game_over.wav")

@export var max_active_players: int = 24

var enabled: bool = false
var _rng := RandomNumberGenerator.new()
var _active_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_rng.randomize()


func initialize(_context: Dictionary) -> void:
	pass


func reset_run() -> void:
	for player in _active_players:
		if is_instance_valid(player):
			player.queue_free()
	_active_players.clear()


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		reset_run()


func play_player_shot() -> void:
	_play(PLAYER_BULLET_SHOT, 0.92, 1.08, -10.0)


func play_enemy_shot() -> void:
	_play(ENEMY_BULLET_SHOT, 0.9, 1.1, -8.0)


func play_bullet_impact() -> void:
	_play(BULLET_IMPACT, 0.88, 1.12, -7.0)


func play_bullet_wall_hit() -> void:
	_play(BULLET_HITS_WALL, 0.40, 0.60, -20.0)


func play_rocket_explosion() -> void:
	_play(ROCKET_EXPLOSION, 0.92, 1.06, -4.0)


func play_parry() -> void:
	_play(PARRY, 0.94, 1.06, -4.0)


func play_parry_ready() -> void:
	_play(PARRY_READY, 0.96, 1.08, -5.0)


func play_perfect_parry() -> void:
	_play(PERFECT_PARRY_FOLLOW_UP, 0.96, 1.04, -2.0)


func play_pickup() -> void:
	_play(ITEM_PICK_UP, 0.9, 1.12, -5.0)


func play_floor_start() -> void:
	_play(FLOOR_START, 0.98, 1.03, -4.0)


func play_room_entry() -> void:
	_play(ROOM_ENTRY, 0.96, 1.05, -5.0)


func play_game_over() -> void:
	_play(GAME_OVER, 0.97, 1.03, -3.0, true)


func _play(stream: AudioStream, pitch_min: float, pitch_max: float, volume_db: float, force: bool = false) -> void:
	if (not enabled and not force) or stream == null:
		return
	_trim_players()
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = _rng.randf_range(pitch_min, pitch_max)
	player.volume_db = volume_db
	player.finished.connect(_on_player_finished.bind(player))
	add_child(player)
	_active_players.append(player)
	if player.is_inside_tree():
		player.play()


func _on_player_finished(player: AudioStreamPlayer) -> void:
	_active_players.erase(player)
	if is_instance_valid(player):
		player.queue_free()


func _trim_players() -> void:
	while _active_players.size() >= max_active_players:
		var oldest: AudioStreamPlayer = _active_players.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
