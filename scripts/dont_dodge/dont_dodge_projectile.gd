class_name DontDodgeProjectile
extends Node2D

const PROJECTILE_VISUAL_SCRIPT: Script = preload("res://scripts/dont_dodge/visuals/dont_dodge_projectile_visual.gd")

const SPEED: float = 420.0
const RADIUS: float = 10.0
const MAX_LIFETIME: float = 3.0
const VISUAL_TYPE_ID: StringName = &"enemy_projectile"
const VISUAL_STATE_FLYING: StringName = &"flying"
const VISUAL_STATE_REFLECTED: StringName = &"reflected"

var _direction: Vector2 = Vector2.RIGHT
var _remaining_lifetime: float = MAX_LIFETIME
var _is_reflected: bool = false
var _visual: Node2D


func _ready() -> void:
	_visual = PROJECTILE_VISUAL_SCRIPT.new()
	_visual.name = "Visual"
	add_child(_visual)
	_sync_visual()


func setup(origin: Vector2, target_position: Vector2) -> void:
	global_position = origin
	_direction = (target_position - origin).normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT
	_remaining_lifetime = MAX_LIFETIME
	_is_reflected = false
	_sync_visual()


func advance(delta: float) -> bool:
	global_position += _direction * SPEED * delta
	_remaining_lifetime -= delta
	_sync_visual()
	return _remaining_lifetime > 0.0 and Rect2(Vector2.ZERO, DontDodgeTuning.ARENA_SIZE).grow(40.0).has_point(global_position)


func is_moving_away_from(position: Vector2) -> bool:
	return _direction.dot(global_position - position) > 0.0


func get_direction() -> Vector2:
	return _direction


func mark_reflected() -> void:
	_is_reflected = true
	_sync_visual()


func is_reflected() -> bool:
	return _is_reflected


func get_visual_type_id() -> StringName:
	return VISUAL_TYPE_ID


func get_visual_state_id() -> StringName:
	return VISUAL_STATE_REFLECTED if _is_reflected else VISUAL_STATE_FLYING


func _sync_visual() -> void:
	if is_instance_valid(_visual):
		_visual.call("set_presentation", get_visual_type_id(), get_visual_state_id(), _direction, RADIUS)
