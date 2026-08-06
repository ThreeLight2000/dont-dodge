class_name DontDodgeSfxController
extends Node

signal sfx_enabled_changed(is_enabled: bool)

const SETTINGS_PATH: String = "user://dont_dodge_settings.cfg"
const SETTINGS_SECTION: String = "audio"
const SETTINGS_KEY_ENABLED: String = "sfx_enabled"
const PLAYER_POOL_SIZE: int = 8
const SFX_VOLUME_DB: float = -9.0

const METAL_HEAVY: Array[String] = ["res://assets/third_party/kenney/impact_sounds/impactMetal_heavy_000.ogg", "res://assets/third_party/kenney/impact_sounds/impactMetal_heavy_001.ogg", "res://assets/third_party/kenney/impact_sounds/impactMetal_heavy_002.ogg", "res://assets/third_party/kenney/impact_sounds/impactMetal_heavy_003.ogg", "res://assets/third_party/kenney/impact_sounds/impactMetal_heavy_004.ogg"]
const METAL_LIGHT: Array[String] = ["res://assets/third_party/kenney/impact_sounds/impactMetal_light_000.ogg", "res://assets/third_party/kenney/impact_sounds/impactMetal_light_001.ogg", "res://assets/third_party/kenney/impact_sounds/impactMetal_light_002.ogg", "res://assets/third_party/kenney/impact_sounds/impactMetal_light_003.ogg", "res://assets/third_party/kenney/impact_sounds/impactMetal_light_004.ogg"]
const PUNCH_HEAVY: Array[String] = ["res://assets/third_party/kenney/impact_sounds/impactPunch_heavy_000.ogg", "res://assets/third_party/kenney/impact_sounds/impactPunch_heavy_001.ogg", "res://assets/third_party/kenney/impact_sounds/impactPunch_heavy_002.ogg", "res://assets/third_party/kenney/impact_sounds/impactPunch_heavy_003.ogg", "res://assets/third_party/kenney/impact_sounds/impactPunch_heavy_004.ogg"]
const PUNCH_MEDIUM: Array[String] = ["res://assets/third_party/kenney/impact_sounds/impactPunch_medium_000.ogg", "res://assets/third_party/kenney/impact_sounds/impactPunch_medium_001.ogg", "res://assets/third_party/kenney/impact_sounds/impactPunch_medium_002.ogg", "res://assets/third_party/kenney/impact_sounds/impactPunch_medium_003.ogg", "res://assets/third_party/kenney/impact_sounds/impactPunch_medium_004.ogg"]

const STREAMS_BY_EVENT: Dictionary = {
	&"player_attack": METAL_HEAVY,
	&"enemy_hit": PUNCH_HEAVY,
	&"enemy_attack": PUNCH_MEDIUM,
	&"player_hit": PUNCH_HEAVY,
	&"enemy_defeated": PUNCH_MEDIUM,
	&"perfect_dodge": METAL_LIGHT,
	&"ultimate": METAL_HEAVY,
	&"wave_started": METAL_HEAVY,
	&"game_clear": METAL_HEAVY,
	&"game_over": PUNCH_HEAVY,
	&"ui": METAL_LIGHT,
}

const LAYER_STREAMS_BY_EVENT: Dictionary = {
	&"enemy_hit": METAL_LIGHT,
	&"player_hit": METAL_LIGHT,
	&"enemy_defeated": METAL_LIGHT,
}

const VOLUME_OFFSET_BY_EVENT: Dictionary = {
	&"player_attack": 1.0,
	&"enemy_hit": 3.0,
	&"player_hit": 2.0,
	&"enemy_defeated": 0.0,
	&"perfect_dodge": 4.0,
	&"ultimate": 6.0,
	&"ui": -9.0,
}

var _enabled: bool = true
var _activated: bool = false
var _players: Array[AudioStreamPlayer] = []
var _next_player_index: int = 0
var _next_variant_by_event: Dictionary = {}


func _ready() -> void:
	_load_settings()
	for pool_index: int in PLAYER_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.volume_db = SFX_VOLUME_DB
		add_child(player)
		_players.append(player)


func is_enabled() -> bool:
	return _enabled


func activate_from_user_input() -> void:
	_activated = true


func toggle_from_user_input() -> void:
	set_enabled_from_user_input(not _enabled)


func set_enabled_from_user_input(is_enabled: bool) -> void:
	_enabled = is_enabled
	if _enabled:
		activate_from_user_input()
	else:
		for player: AudioStreamPlayer in _players:
			player.stop()
	_save_settings()
	sfx_enabled_changed.emit(_enabled)


func play_event(event_id: StringName, _world_position: Vector2 = Vector2.ZERO) -> void:
	if not _enabled or not _activated or DisplayServer.get_name() == "headless":
		return
	var paths: Array = STREAMS_BY_EVENT.get(event_id, [])
	if paths.is_empty():
		return
	_play_variant(event_id, paths, float(VOLUME_OFFSET_BY_EVENT.get(event_id, 0.0)))
	var layer_paths: Array = LAYER_STREAMS_BY_EVENT.get(event_id, [])
	if not layer_paths.is_empty():
		_play_variant(StringName("%s_layer" % event_id), layer_paths, -7.0)


func _play_variant(event_id: StringName, paths: Array, volume_offset_db: float) -> void:
	var variant_index: int = int(_next_variant_by_event.get(event_id, 0)) % paths.size()
	_next_variant_by_event[event_id] = (variant_index + 1) % paths.size()
	var stream_path: String = str(paths[variant_index])
	var stream := load(stream_path) as AudioStream
	if stream == null:
		push_warning("Could not load SFX stream: %s" % stream_path)
		return
	var player: AudioStreamPlayer = _players[_next_player_index]
	_next_player_index = (_next_player_index + 1) % _players.size()
	player.volume_db = SFX_VOLUME_DB + volume_offset_db
	player.stream = stream
	player.play()


func play_ui() -> void:
	play_event(&"ui")


func _load_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		_enabled = bool(settings.get_value(SETTINGS_SECTION, SETTINGS_KEY_ENABLED, true))


func _save_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		settings = ConfigFile.new()
	settings.set_value(SETTINGS_SECTION, SETTINGS_KEY_ENABLED, _enabled)
	if settings.save(SETTINGS_PATH) != OK:
		push_warning("Could not save DON’T DODGE SFX setting.")
