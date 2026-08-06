class_name DontDodgePlayer
extends Node2D

const PLAYER_VISUAL_SCRIPT: Script = preload("res://scripts/dont_dodge/visuals/dont_dodge_player_visual.gd")

const VISUAL_TYPE_ID: StringName = &"player"
const VISUAL_STATE_IDLE: StringName = &"idle"
const VISUAL_STATE_MOVE: StringName = &"move"
const VISUAL_STATE_DASH: StringName = &"dash"
const VISUAL_STATE_HIT: StringName = &"hit"
const VISUAL_STATE_STEALTH: StringName = &"stealth"
const VISUAL_STATE_DEAD: StringName = &"dead"

signal took_damage(remaining_health: int)
signal stealth_changed(is_stealthed: bool)
signal dodge_finished()

var _health: int = DontDodgeTuning.PLAYER_MAX_HEALTH
var _maximum_health: int = DontDodgeTuning.PLAYER_MAX_HEALTH
var _last_move_direction: Vector2 = Vector2.RIGHT
var _last_move_age: float = INF
var _dash_direction: Vector2 = Vector2.RIGHT
var _dash_remaining: float = 0.0
var _dash_elapsed: float = 0.0
var _damage_invulnerability_remaining: float = 0.0
var _perfect_registered_for_dash: bool = false
var _stealth_remaining: float = 0.0
var _stealth_attack_ready: bool = false
var _visual: Node2D


func _ready() -> void:
	_visual = PLAYER_VISUAL_SCRIPT.new()
	_visual.name = "Visual"
	add_child(_visual)
	_sync_visual()


func advance(delta: float, move_direction: Vector2, move_speed: float = DontDodgeTuning.PLAYER_MOVE_SPEED) -> void:
	_damage_invulnerability_remaining = maxf(0.0, _damage_invulnerability_remaining - delta)
	var was_stealthed: bool = _stealth_remaining > 0.0
	_stealth_remaining = maxf(0.0, _stealth_remaining - delta)
	if was_stealthed and _stealth_remaining <= 0.0:
		stealth_changed.emit(false)
	if is_instance_valid(_visual):
		_visual.call("advance", delta)
	if _dash_remaining > 0.0:
		var step_time: float = minf(delta, _dash_remaining)
		_last_move_direction = _dash_direction
		_last_move_age = 0.0
		global_position += _dash_direction * DontDodgeTuning.DODGE_DISTANCE / DontDodgeTuning.DODGE_DURATION * step_time
		_dash_remaining -= step_time
		_dash_elapsed += step_time
		if _dash_remaining <= 0.0:
			dodge_finished.emit()
	else:
		if move_direction != Vector2.ZERO:
			_last_move_direction = move_direction.normalized()
			_last_move_age = 0.0
		else:
			_last_move_age += delta
		global_position += move_direction.limit_length(1.0) * move_speed * delta
	global_position = global_position.clamp(
		Vector2.ONE * DontDodgeTuning.PLAYER_RADIUS,
		DontDodgeTuning.ARENA_SIZE - Vector2.ONE * DontDodgeTuning.PLAYER_RADIUS,
	)
	_sync_visual()


func begin_dodge(move_direction: Vector2) -> bool:
	if not can_dodge():
		return false
	if move_direction != Vector2.ZERO:
		_last_move_direction = move_direction.normalized()
		_last_move_age = 0.0
	_dash_direction = _last_move_direction
	_dash_remaining = DontDodgeTuning.DODGE_DURATION
	_dash_elapsed = 0.0
	_perfect_registered_for_dash = false
	_sync_visual()
	return true


func begin_stealth(duration: float) -> void:
	var was_stealthed: bool = _stealth_remaining > 0.0
	_stealth_remaining = maxf(_stealth_remaining, duration)
	_stealth_attack_ready = true
	if not was_stealthed:
		stealth_changed.emit(true)
	_sync_visual()


func is_stealthed() -> bool:
	return _stealth_remaining > 0.0


func get_stealth_remaining() -> float:
	return _stealth_remaining


func consume_stealth_attack_bonus() -> bool:
	if not _stealth_attack_ready:
		return false
	_stealth_attack_ready = false
	return true


func play_attack() -> void:
	if is_instance_valid(_visual):
		_visual.call("play_attack")


func can_dodge() -> bool:
	return _dash_remaining <= 0.0


func is_dodging() -> bool:
	return _dash_remaining > 0.0


func is_invulnerable() -> bool:
	return _dash_remaining > 0.0 or _damage_invulnerability_remaining > 0.0


func consume_perfect_dodge() -> bool:
	if _dash_remaining <= 0.0 or _dash_elapsed > DontDodgeTuning.PERFECT_DODGE_WINDOW or _perfect_registered_for_dash:
		return false
	_perfect_registered_for_dash = true
	return true


func receive_damage() -> bool:
	if is_invulnerable():
		return false
	_health = maxi(0, _health - DontDodgeTuning.PLAYER_DAMAGE)
	_damage_invulnerability_remaining = DontDodgeTuning.PLAYER_HIT_INVULNERABILITY
	took_damage.emit(_health)
	if is_instance_valid(_visual):
		_visual.call("play_hit")
	_sync_visual()
	return true


func get_health() -> int:
	return _health


func get_max_health() -> int:
	return _maximum_health


func configure_health(max_health: int, restore_to_full: bool = true) -> void:
	_maximum_health = maxi(1, max_health)
	_health = _maximum_health if restore_to_full else mini(_health, _maximum_health)
	_sync_visual()


func get_visual_type_id() -> StringName:
	return VISUAL_TYPE_ID


func get_visual_state_id() -> StringName:
	if _health <= 0:
		return VISUAL_STATE_DEAD
	if _dash_remaining > 0.0:
		return VISUAL_STATE_DASH
	if _stealth_remaining > 0.0:
		return VISUAL_STATE_STEALTH
	if _damage_invulnerability_remaining > 0.0:
		return VISUAL_STATE_HIT
	if _last_move_age <= 0.0:
		return VISUAL_STATE_MOVE
	return VISUAL_STATE_IDLE


func heal(amount: int) -> int:
	if amount <= 0 or _health >= _maximum_health:
		return 0
	var recovered: int = mini(amount, _maximum_health - _health)
	_health += recovered
	_sync_visual()
	return recovered


func get_last_move_direction() -> Vector2:
	return _last_move_direction


func get_recent_move_direction(maximum_age: float) -> Vector2:
	if _last_move_age <= maximum_age:
		return _last_move_direction
	return Vector2.ZERO


func _sync_visual() -> void:
	if not is_instance_valid(_visual):
		return
	_visual.call("set_presentation", get_visual_type_id(), get_visual_state_id(), DontDodgeTuning.PLAYER_RADIUS, _health, _maximum_health, _last_move_direction, is_invulnerable(), _dash_remaining > 0.0, is_stealthed())
