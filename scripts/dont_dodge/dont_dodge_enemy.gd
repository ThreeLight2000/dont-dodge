class_name DontDodgeEnemy
extends Node2D

const ENEMY_VISUAL_SCRIPT: Script = preload("res://scripts/dont_dodge/visuals/dont_dodge_enemy_visual.gd")

enum EnemyType { MELEE, RANGED, CHARGER, VOLLEY, ELITE }
enum State { SPAWN_LOCK, CHASE, WINDUP, CHARGING, ATTACKED, INTERRUPTED, DEFEATED }

const VISUAL_TYPE_MELEE: StringName = &"melee"
const VISUAL_TYPE_RANGED: StringName = &"ranged"
const VISUAL_TYPE_CHARGER: StringName = &"charger"
const VISUAL_TYPE_VOLLEY: StringName = &"volley"
const VISUAL_TYPE_ELITE: StringName = &"elite"
const VISUAL_STATE_SPAWN_LOCK: StringName = &"spawn_lock"
const VISUAL_STATE_CHASE: StringName = &"chase"
const VISUAL_STATE_WINDUP: StringName = &"windup"
const VISUAL_STATE_CHARGING: StringName = &"charging"
const VISUAL_STATE_ATTACKED: StringName = &"attacked"
const VISUAL_STATE_INTERRUPTED: StringName = &"interrupted"
const VISUAL_STATE_DEFEATED: StringName = &"defeated"

signal strike_landed(enemy: DontDodgeEnemy, impact_position: Vector2, impact_radius: float)
signal projectile_fired(enemy: DontDodgeEnemy, origin: Vector2, target_position: Vector2, projectile_count: int, total_spread_degrees: float)
signal charge_started(enemy: DontDodgeEnemy, origin: Vector2, target_position: Vector2)
signal defeated(enemy: DontDodgeEnemy)
signal interrupted(enemy: DontDodgeEnemy)

var _type: EnemyType = EnemyType.MELEE
var _state: State = State.CHASE
var _target: DontDodgePlayer
var _health: int = DontDodgeTuning.MELEE_HEALTH
var _move_speed: float = 105.0
var _windup_remaining: float = 0.0
var _cooldown_remaining: float = 0.0
var _state_remaining: float = 0.0
var _impact_position: Vector2 = Vector2.ZERO
var _impact_radius: float = 0.0
var _knockback_remaining: float = 0.0
var _knockback_direction: Vector2 = Vector2.ZERO
var _slow_remaining: float = 0.0
var _slow_multiplier: float = 1.0
var _charge_target_position: Vector2 = Vector2.ZERO
var _charge_direction: Vector2 = Vector2.RIGHT
var _spawn_lock_remaining: float = 0.0
var _pattern_id: String = ""
var _pattern_instance_id: String = ""
var _pattern_role: String = "secondary"
var _hazard_id: String = ""
var _visual: Node2D


func _ready() -> void:
	_visual = ENEMY_VISUAL_SCRIPT.new()
	_visual.name = "Visual"
	add_child(_visual)
	_sync_visual()


func setup(enemy_type: EnemyType, target: DontDodgePlayer, pattern_context: Dictionary = {}) -> void:
	_type = enemy_type
	_target = target
	match _type:
		EnemyType.MELEE:
			_health = DontDodgeTuning.MELEE_HEALTH
			_move_speed = 120.0
		EnemyType.RANGED:
			_health = DontDodgeTuning.RANGED_HEALTH
			_move_speed = 92.0
		EnemyType.CHARGER:
			_health = DontDodgeTuning.CHARGER_HEALTH
			_move_speed = 130.0
		EnemyType.VOLLEY:
			_health = DontDodgeTuning.VOLLEY_HEALTH
			_move_speed = DontDodgeTuning.VOLLEY_MOVE_SPEED
		EnemyType.ELITE:
			_health = DontDodgeTuning.ELITE_HEALTH
			_move_speed = 78.0
	_pattern_id = str(pattern_context.get("pattern_id", ""))
	_pattern_instance_id = str(pattern_context.get("pattern_instance_id", ""))
	_pattern_role = str(pattern_context.get("role", "secondary"))
	_hazard_id = str(pattern_context.get("hazard_id", ""))
	_spawn_lock_remaining = maxf(0.0, float(pattern_context.get("spawn_lock", 0.0)))
	if _spawn_lock_remaining > 0.0:
		_state = State.SPAWN_LOCK
	_sync_visual()


func advance(delta: float) -> void:
	_slow_remaining = maxf(0.0, _slow_remaining - delta)
	if _slow_remaining <= 0.0:
		_slow_multiplier = 1.0
	if is_instance_valid(_visual):
		_visual.call("advance", delta)
	if _state == State.DEFEATED:
		_state_remaining -= delta
		_sync_visual()
		if _state_remaining <= 0.0:
			queue_free()
		return
	if _state == State.SPAWN_LOCK:
		_spawn_lock_remaining = maxf(0.0, _spawn_lock_remaining - delta)
		if _spawn_lock_remaining <= 0.0:
			_state = State.CHASE
		_sync_visual()
		return
	if _knockback_remaining > 0.0:
		var knockback_step: float = minf(_knockback_remaining, 540.0 * delta)
		global_position += _knockback_direction * knockback_step
		_knockback_remaining -= knockback_step
		_clamp_to_arena()
	if _state == State.INTERRUPTED or _state == State.ATTACKED:
		_state_remaining -= delta
		if _state_remaining <= 0.0:
			_state = State.CHASE
		_sync_visual()
		return
	if _state == State.CHARGING:
		_advance_charge(delta)
		_sync_visual()
		return
	if not is_instance_valid(_target):
		_sync_visual()
		return
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	if _state == State.WINDUP:
		_windup_remaining -= delta
		if _windup_remaining <= 0.0:
			_resolve_attack()
		_sync_visual()
		return
	_update_chase_or_windup(delta)
	_sync_visual()


func receive_hit(damage: int, direction: Vector2, knockback: float) -> bool:
	if _state == State.DEFEATED or _state == State.SPAWN_LOCK:
		return false
	_health -= damage
	_knockback_direction = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	_knockback_remaining = maxf(_knockback_remaining, knockback)
	if is_instance_valid(_visual):
		_visual.call("play_hit", _knockback_direction)
	if _health > 0:
		_sync_visual()
		return false
	_state = State.DEFEATED
	_state_remaining = 0.42
	defeated.emit(self)
	_sync_visual()
	return true


func repel(direction: Vector2, knockback: float) -> bool:
	if _state == State.DEFEATED or _state == State.SPAWN_LOCK:
		return false
	_knockback_direction = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	_knockback_remaining = maxf(_knockback_remaining, knockback)
	_sync_visual()
	return true


func apply_slow(duration: float, multiplier: float = 0.65) -> void:
	_slow_remaining = maxf(_slow_remaining, duration)
	_slow_multiplier = minf(_slow_multiplier, clampf(multiplier, 0.1, 1.0))
	_sync_visual()


func interrupt() -> bool:
	if _state != State.WINDUP:
		return false
	_state = State.INTERRUPTED
	_state_remaining = 1.0
	_windup_remaining = 0.0
	_cooldown_remaining = 0.65
	interrupted.emit(self)
	_sync_visual()
	return true


func force_interrupt() -> void:
	if _state == State.DEFEATED or _state == State.SPAWN_LOCK:
		return
	_state = State.INTERRUPTED
	_state_remaining = 1.0
	_windup_remaining = 0.0
	_cooldown_remaining = 0.65
	_sync_visual()


func is_winding_up() -> bool:
	return _state == State.WINDUP


func is_charging() -> bool:
	return _state == State.CHARGING


func is_charge_counterable() -> bool:
	return _type == EnemyType.CHARGER and (_state == State.WINDUP or _state == State.CHARGING)


func is_combat_active() -> bool:
	return _state != State.SPAWN_LOCK and _state != State.DEFEATED and not is_queued_for_deletion()


func is_materializing() -> bool:
	return _state == State.SPAWN_LOCK


func get_pattern_id() -> String:
	return _pattern_id


func get_pattern_instance_id() -> String:
	return _pattern_instance_id


func get_pattern_role() -> String:
	return _pattern_role


func get_hazard_id() -> String:
	return _hazard_id


func get_threat_time() -> float:
	return _windup_remaining if _state == State.WINDUP else INF


func get_enemy_type() -> EnemyType:
	return _type


func get_visual_type_id() -> StringName:
	match _type:
		EnemyType.MELEE:
			return VISUAL_TYPE_MELEE
		EnemyType.RANGED:
			return VISUAL_TYPE_RANGED
		EnemyType.CHARGER:
			return VISUAL_TYPE_CHARGER
		EnemyType.VOLLEY:
			return VISUAL_TYPE_VOLLEY
		_:
			return VISUAL_TYPE_ELITE


func get_visual_state_id() -> StringName:
	match _state:
		State.SPAWN_LOCK:
			return VISUAL_STATE_SPAWN_LOCK
		State.CHASE:
			return VISUAL_STATE_CHASE
		State.WINDUP:
			return VISUAL_STATE_WINDUP
		State.CHARGING:
			return VISUAL_STATE_CHARGING
		State.ATTACKED:
			return VISUAL_STATE_ATTACKED
		State.INTERRUPTED:
			return VISUAL_STATE_INTERRUPTED
		_:
			return VISUAL_STATE_DEFEATED


func get_health() -> int:
	return _health


func _update_chase_or_windup(delta: float) -> void:
	if _target.is_stealthed():
		return
	var to_target: Vector2 = _target.global_position - global_position
	var distance: float = to_target.length()
	var move_speed: float = _move_speed * _slow_multiplier
	if _type == EnemyType.RANGED:
		if distance > 330.0:
			global_position += to_target.normalized() * move_speed * delta
			_clamp_to_arena()
		elif distance < 190.0:
			global_position -= to_target.normalized() * move_speed * delta
			_clamp_to_arena()
		elif _cooldown_remaining <= 0.0:
			_begin_windup(0.75, 0.0)
		return
	if _type == EnemyType.VOLLEY:
		if distance > DontDodgeTuning.VOLLEY_MAX_DISTANCE:
			global_position += to_target.normalized() * move_speed * delta
			_clamp_to_arena()
		elif distance < DontDodgeTuning.VOLLEY_MIN_DISTANCE:
			global_position -= to_target.normalized() * move_speed * delta
			_clamp_to_arena()
		elif _cooldown_remaining <= 0.0:
			_begin_windup(DontDodgeTuning.VOLLEY_WINDUP, 0.0)
		return
	if _type == EnemyType.CHARGER:
		if distance > DontDodgeTuning.CHARGER_TRIGGER_DISTANCE:
			global_position += to_target.normalized() * move_speed * delta
			_clamp_to_arena()
		elif _cooldown_remaining <= 0.0:
			_begin_windup(DontDodgeTuning.CHARGER_WINDUP, DontDodgeTuning.CHARGER_IMPACT_RADIUS)
		return
	var attack_distance: float = 100.0 if _type == EnemyType.MELEE else 205.0
	if distance > attack_distance:
		global_position += to_target.normalized() * move_speed * delta
		_clamp_to_arena()
		return
	if _cooldown_remaining <= 0.0:
		_begin_windup(0.65 if _type == EnemyType.MELEE else 1.1, 82.0 if _type == EnemyType.MELEE else 185.0)


func _begin_windup(duration: float, radius: float) -> void:
	_state = State.WINDUP
	_windup_remaining = duration
	_impact_position = _target.global_position
	_impact_radius = radius


func _resolve_attack() -> void:
	if _type == EnemyType.CHARGER:
		_charge_target_position = _impact_position
		_charge_direction = (_charge_target_position - global_position).normalized()
		if _charge_direction == Vector2.ZERO:
			_charge_direction = Vector2.RIGHT
		_state = State.CHARGING
		_cooldown_remaining = DontDodgeTuning.CHARGER_COOLDOWN
		charge_started.emit(self, global_position, _charge_target_position)
		return
	_state = State.ATTACKED
	_state_remaining = 0.18
	_cooldown_remaining = 1.1 if _type == EnemyType.MELEE else 1.75 if _type == EnemyType.RANGED else DontDodgeTuning.VOLLEY_COOLDOWN if _type == EnemyType.VOLLEY else 2.2
	if _type == EnemyType.RANGED:
		projectile_fired.emit(self, global_position, _impact_position, 1, 0.0)
	elif _type == EnemyType.VOLLEY:
		projectile_fired.emit(self, global_position, _impact_position, DontDodgeTuning.VOLLEY_PROJECTILE_COUNT, DontDodgeTuning.VOLLEY_TOTAL_SPREAD_DEGREES)
	else:
		strike_landed.emit(self, _impact_position, _impact_radius)


func _advance_charge(delta: float) -> void:
	var to_target: Vector2 = _charge_target_position - global_position
	var step: float = DontDodgeTuning.CHARGER_SPEED * delta
	if to_target.length() <= step:
		global_position = _charge_target_position
		strike_landed.emit(self, _charge_target_position, DontDodgeTuning.CHARGER_IMPACT_RADIUS)
		_state = State.ATTACKED
		_state_remaining = 0.18
		return
	global_position += _charge_direction * step
	_clamp_to_arena()


func _clamp_to_arena() -> void:
	global_position = global_position.clamp(Vector2.ONE * 18.0, DontDodgeTuning.ARENA_SIZE - Vector2.ONE * 18.0)


func _sync_visual() -> void:
	if not is_instance_valid(_visual):
		return
	var spawn_lock_ratio: float = _spawn_lock_remaining / DontDodgeTuning.SPAWN_MATERIALIZE_LOCK
	var defeat_ratio: float = clampf(_state_remaining / 0.42, 0.0, 1.0) if _state == State.DEFEATED else 0.0
	_visual.call("set_presentation", get_visual_type_id(), get_visual_state_id(), _type, _state, _health, _get_max_health(), _windup_remaining, _impact_position - global_position, _impact_radius, spawn_lock_ratio, defeat_ratio, _charge_direction)


func _get_max_health() -> int:
	match _type:
		EnemyType.MELEE:
			return DontDodgeTuning.MELEE_HEALTH
		EnemyType.RANGED:
			return DontDodgeTuning.RANGED_HEALTH
		EnemyType.CHARGER:
			return DontDodgeTuning.CHARGER_HEALTH
		EnemyType.VOLLEY:
			return DontDodgeTuning.VOLLEY_HEALTH
		_:
			return DontDodgeTuning.ELITE_HEALTH
