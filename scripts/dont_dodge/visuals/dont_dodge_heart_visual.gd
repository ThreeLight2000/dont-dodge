class_name DontDodgeHeartVisual
extends Node2D

var _pulse_elapsed: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func advance(delta: float) -> void:
	_pulse_elapsed += delta
	queue_redraw()


func _draw() -> void:
	var pulse: float = 1.0 + sin(_pulse_elapsed * 5.0) * 0.12
	var glow_alpha: float = 0.16 + sin(_pulse_elapsed * 5.0) * 0.05
	draw_rect(Rect2(Vector2.ONE * -24.0 * pulse, Vector2.ONE * 48.0 * pulse), Color(1.0, 0.26, 0.36, glow_alpha), false, 2.0)
	var pixel: float = 4.0 * pulse
	var outline := Color(0.18, 0.035, 0.04, 0.95)
	var fill := Color(1.0, 0.3, 0.3)
	draw_rect(Rect2(-3.0 * pixel, -3.0 * pixel, 6.0 * pixel, 5.0 * pixel), outline)
	draw_rect(Rect2(-4.0 * pixel, -2.0 * pixel, 8.0 * pixel, 3.0 * pixel), outline)
	draw_rect(Rect2(-2.0 * pixel, 2.0 * pixel, 4.0 * pixel, 3.0 * pixel), outline)
	draw_rect(Rect2(-2.0 * pixel, -2.0 * pixel, 4.0 * pixel, 3.0 * pixel), fill)
	draw_rect(Rect2(-3.0 * pixel, -1.0 * pixel, 6.0 * pixel, 2.0 * pixel), fill)
	draw_rect(Rect2(-1.0 * pixel, 1.0 * pixel, 2.0 * pixel, 3.0 * pixel), fill)
