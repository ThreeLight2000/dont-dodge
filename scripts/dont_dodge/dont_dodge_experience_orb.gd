class_name DontDodgeExperienceOrb
extends Node2D

var _value: int = 1
var _remaining_lifetime: float = DontDodgeTuning.EXPERIENCE_LIFETIME_SECONDS
var _pulse_elapsed: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func setup(value: int) -> void:
	_value = maxi(1, value)


func advance(delta: float) -> bool:
	_pulse_elapsed += delta
	_remaining_lifetime -= delta
	queue_redraw()
	return _remaining_lifetime > 0.0


func get_value() -> int:
	return _value


func _draw() -> void:
	var pulse: float = 1.0 + sin(_pulse_elapsed * 6.0) * 0.10
	var glow_alpha: float = 0.15 + sin(_pulse_elapsed * 6.0) * 0.05
	draw_rect(Rect2(Vector2.ONE * -18.0 * pulse, Vector2.ONE * 36.0 * pulse), Color(0.3, 0.88, 1.0, glow_alpha), false, 2.0)
	var outline := Color(0.04, 0.1, 0.16, 0.9)
	var fill := Color(0.32, 0.86, 1.0)
	draw_rect(Rect2(-8.0, -14.0, 16.0, 28.0), outline)
	draw_rect(Rect2(-14.0, -8.0, 28.0, 16.0), outline)
	draw_rect(Rect2(-5.0, -11.0, 10.0, 22.0), fill)
	draw_rect(Rect2(-11.0, -5.0, 22.0, 10.0), fill)
	draw_rect(Rect2(-2.0, -8.0, 4.0, 8.0), Color(0.9, 0.98, 1.0))
