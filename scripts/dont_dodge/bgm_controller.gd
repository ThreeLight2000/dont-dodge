extends Node

signal bgm_enabled_changed(is_enabled: bool)

const SETTINGS_PATH: String = "user://dont_dodge_settings.cfg"
const SETTINGS_SECTION: String = "audio"
const SETTINGS_KEY_ENABLED: String = "bgm_enabled"
const BGM_STREAM_PATH: String = "res://assets/audio/eight_tension_mastered.mp3"

var _enabled: bool = true
var _player: AudioStreamPlayer


func _ready() -> void:
	_load_settings()
	_player = AudioStreamPlayer.new()
	add_child(_player)


func _ensure_stream() -> bool:
	if _player.stream != null:
		return true
	if DisplayServer.get_name() == "headless":
		return false
	var bgm_stream := load(BGM_STREAM_PATH) as AudioStream
	if bgm_stream == null:
		push_error("Could not load BGM stream.")
		return false
	_player.stream = bgm_stream
	var mp3_stream := bgm_stream as AudioStreamMP3
	if mp3_stream != null:
		mp3_stream.loop = true
	return true


func _exit_tree() -> void:
	shutdown()


func shutdown() -> void:
	if not is_instance_valid(_player):
		return
	_player.stop()
	_player.stream = null
	_player.free()
	_player = null


func is_enabled() -> bool:
	return _enabled


func activate_from_user_input() -> void:
	if _enabled and is_instance_valid(_player) and not _player.playing and _ensure_stream():
		_player.play()


func toggle_from_user_input() -> void:
	set_enabled_from_user_input(not _enabled)


func set_enabled_from_user_input(is_enabled: bool) -> void:
	if _enabled == is_enabled:
		if _enabled:
			activate_from_user_input()
		return
	_enabled = is_enabled
	_save_settings()
	if _enabled:
		activate_from_user_input()
	elif is_instance_valid(_player):
		_player.stop()
	bgm_enabled_changed.emit(_enabled)


func _load_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return
	_enabled = bool(settings.get_value(SETTINGS_SECTION, SETTINGS_KEY_ENABLED, true))


func _save_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		settings = ConfigFile.new()
	settings.set_value(SETTINGS_SECTION, SETTINGS_KEY_ENABLED, _enabled)
	if settings.save(SETTINGS_PATH) != OK:
		push_warning("Could not save BGM setting.")
