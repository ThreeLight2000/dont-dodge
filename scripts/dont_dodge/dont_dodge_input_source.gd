class_name DontDodgeInputSource
extends Node

var _command: DontDodgeCommand = DontDodgeCommand.new()
var _ui_attack_requested: bool = false
var _ui_dodge_requested: bool = false
var _ui_negate_requested: bool = false
var _ui_ultimate_requested: bool = false


func read_command() -> DontDodgeCommand:
	_command.move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_command.attack_pressed = Input.is_action_just_pressed("attack") or _ui_attack_requested
	_command.dodge_pressed = Input.is_action_just_pressed("dodge") or _ui_dodge_requested
	_command.negate_pressed = Input.is_action_just_pressed("negate") or _ui_negate_requested
	_command.ultimate_pressed = Input.is_action_just_pressed("ultimate") or _ui_ultimate_requested
	_ui_attack_requested = false
	_ui_dodge_requested = false
	_ui_negate_requested = false
	_ui_ultimate_requested = false
	return _command


func request_ui_attack() -> void:
	_ui_attack_requested = true


func request_ui_dodge() -> void:
	_ui_dodge_requested = true


func request_ui_negate() -> void:
	_ui_negate_requested = true


func request_ui_ultimate() -> void:
	_ui_ultimate_requested = true


func clear_requests() -> void:
	_ui_attack_requested = false
	_ui_dodge_requested = false
	_ui_negate_requested = false
	_ui_ultimate_requested = false
