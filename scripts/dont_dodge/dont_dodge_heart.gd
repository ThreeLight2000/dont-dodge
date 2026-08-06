class_name DontDodgeHeart
extends Node2D

const HEART_VISUAL_SCRIPT: Script = preload("res://scripts/dont_dodge/visuals/dont_dodge_heart_visual.gd")

var _remaining_lifetime: float = DontDodgeTuning.HEART_LIFETIME_SECONDS
var _visual: Node2D


func _ready() -> void:
	_visual = HEART_VISUAL_SCRIPT.new()
	_visual.name = "Visual"
	add_child(_visual)


func advance(delta: float) -> bool:
	if is_instance_valid(_visual):
		_visual.call("advance", delta)
	_remaining_lifetime -= delta
	return _remaining_lifetime > 0.0
