class_name DontDodgeScreenFeedback
extends Node

const SCREEN_FLASH_LAYER: int = 5

var _camera: Camera2D
var _flash_layer: CanvasLayer
var _flash: ColorRect
var _shake_pixels: float = 0.0
var _shake_remaining: float = 0.0
var _shake_duration: float = 0.0
var _shake_clock: float = 0.0
var _flash_color: Color = Color.WHITE
var _flash_alpha: float = 0.0
var _flash_remaining: float = 0.0
var _flash_duration: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera = Camera2D.new()
	_camera.name = "CombatCamera"
	_camera.position = DontDodgeTuning.ARENA_SIZE * 0.5
	_camera.enabled = true
	_camera.position_smoothing_enabled = false
	add_child(_camera)

	_flash_layer = CanvasLayer.new()
	_flash_layer.name = "ScreenFlashLayer"
	_flash_layer.layer = SCREEN_FLASH_LAYER
	add_child(_flash_layer)
	_flash = ColorRect.new()
	_flash.name = "ScreenFlash"
	_flash.color = Color(1.0, 1.0, 1.0, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_layer.add_child(_flash)


func _process(delta: float) -> void:
	_shake_clock += delta
	_update_shake(delta)
	_update_flash(delta)


func trigger_impact(shake_pixels: float, shake_duration: float, flash_color: Color, flash_alpha: float, flash_duration: float = -1.0) -> void:
	trigger_shake(shake_pixels, shake_duration)
	trigger_flash(flash_color, flash_alpha, shake_duration if flash_duration < 0.0 else flash_duration)


func trigger_shake(pixels: float, duration: float) -> void:
	if pixels <= 0.0 or duration <= 0.0:
		return
	if pixels >= _shake_pixels:
		_shake_pixels = pixels
		_shake_duration = duration
		_shake_remaining = duration
	else:
		_shake_remaining = maxf(_shake_remaining, duration)


func trigger_flash(color: Color, alpha: float, duration: float) -> void:
	if alpha <= 0.0 or duration <= 0.0:
		return
	if alpha >= _flash_alpha:
		_flash_color = color
		_flash_alpha = clampf(alpha, 0.0, 1.0)
		_flash_duration = duration
		_flash_remaining = duration
		_flash.color = Color(_flash_color, _flash_alpha)


func get_active_shake_pixels() -> float:
	return _shake_pixels


func get_active_flash_alpha() -> float:
	return _flash.color.a if is_instance_valid(_flash) else 0.0


func get_camera_offset() -> Vector2:
	return _camera.offset if is_instance_valid(_camera) else Vector2.ZERO


func _update_shake(delta: float) -> void:
	if _shake_remaining <= 0.0:
		_shake_pixels = 0.0
		_shake_duration = 0.0
		_camera.offset = Vector2.ZERO
		return
	_shake_remaining = maxf(0.0, _shake_remaining - delta)
	var progress: float = _shake_remaining / _shake_duration if _shake_duration > 0.0 else 0.0
	var falloff: float = pow(clampf(progress, 0.0, 1.0), 0.75)
	var horizontal: float = sin(_shake_clock * 113.0) * 0.82 + sin(_shake_clock * 47.0) * 0.18
	var vertical: float = cos(_shake_clock * 127.0) * 0.82 + cos(_shake_clock * 59.0) * 0.18
	_camera.offset = Vector2(horizontal, vertical) * _shake_pixels * falloff
	if _shake_remaining <= 0.0:
		_shake_pixels = 0.0
		_shake_duration = 0.0
		_camera.offset = Vector2.ZERO


func _update_flash(delta: float) -> void:
	if _flash_remaining <= 0.0:
		_flash.color = Color(_flash_color, 0.0)
		_flash_alpha = 0.0
		return
	_flash_remaining = maxf(0.0, _flash_remaining - delta)
	var progress: float = _flash_remaining / _flash_duration if _flash_duration > 0.0 else 0.0
	_flash.color = Color(_flash_color, _flash_alpha * clampf(progress, 0.0, 1.0))
	if _flash_remaining <= 0.0:
		_flash_alpha = 0.0
