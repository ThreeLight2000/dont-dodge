class_name DontDodgePlayerVisual
extends Node2D

const VISUAL_MAPPING_SCRIPT: Script = preload("res://scripts/dont_dodge/visuals/dont_dodge_visual_mapping.gd")
const ATTACK_VISUAL_DURATION: float = 0.22
const IDLE_BOB_SPEED: float = 3.8
const IDLE_BOB_AMPLITUDE: float = 2.0

var _radius: float = DontDodgeTuning.PLAYER_RADIUS
var _health: int = DontDodgeTuning.PLAYER_MAX_HEALTH
var _maximum_health: int = DontDodgeTuning.PLAYER_MAX_HEALTH
var _facing_direction: Vector2 = Vector2.RIGHT
var _is_invulnerable: bool = false
var _is_dashing: bool = false
var _is_stealthed: bool = false
var _hit_flash_remaining: float = 0.0
var _motion_time: float = 0.0
var _attack_visual_remaining: float = 0.0
var _type_id: StringName = &"player"
var _state_id: StringName = &"idle"
var _variant_id: StringName = DontDodgeVisualMapping.FALLBACK_VARIANT
var _mapping: DontDodgeVisualMapping = VISUAL_MAPPING_SCRIPT.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_presentation(type_id: StringName, state_id: StringName, radius: float, health: int, maximum_health: int, facing_direction: Vector2, is_invulnerable: bool, is_dashing: bool, is_stealthed: bool = false) -> void:
	_type_id = type_id
	_state_id = state_id
	_radius = radius
	_health = health
	_maximum_health = maximum_health
	_facing_direction = facing_direction if facing_direction != Vector2.ZERO else Vector2.RIGHT
	_is_invulnerable = is_invulnerable
	_is_dashing = is_dashing
	_is_stealthed = is_stealthed
	_variant_id = _mapping.resolve(_type_id, _state_id)
	queue_redraw()


func set_visual_mapping(variants_by_type: Dictionary) -> void:
	_mapping.set_variants(variants_by_type)
	_variant_id = _mapping.resolve(_type_id, _state_id)
	queue_redraw()


func get_visual_variant() -> StringName:
	return _variant_id


func play_hit() -> void:
	_hit_flash_remaining = 0.42
	queue_redraw()


func play_attack() -> void:
	_attack_visual_remaining = ATTACK_VISUAL_DURATION
	queue_redraw()


func advance(delta: float) -> void:
	_motion_time += delta
	_hit_flash_remaining = maxf(0.0, _hit_flash_remaining - delta)
	_attack_visual_remaining = maxf(0.0, _attack_visual_remaining - delta)
	queue_redraw()


func _draw() -> void:
	_draw_pixel_shadow()
	var visual_offset := Vector2(0.0, _get_idle_bob_offset())
	var visual_scale := Vector2.ONE
	var visual_rotation: float = 0.0
	if _attack_visual_remaining > 0.0:
		var attack_progress: float = _get_attack_visual_progress()
		var strike_progress: float = sin(attack_progress * PI)
		var attack_lunge: float = strike_progress * 6.0 - (1.0 - attack_progress) * 2.0
		visual_offset += _facing_direction * attack_lunge
		visual_rotation = strike_progress * 0.045
		visual_scale = Vector2(1.0 + strike_progress * 0.06, 1.0 - strike_progress * 0.05)
	draw_set_transform(visual_offset, visual_rotation, visual_scale)
	var color: Color = Color(1.0, 0.5, 0.38) if _hit_flash_remaining > 0.0 else Color(0.48, 0.9, 1.0) if _is_stealthed else Color(0.76, 0.94, 0.72) if not _is_invulnerable else Color.WHITE
	if _hit_flash_remaining > 0.0:
		var hit_alpha: float = _hit_flash_remaining / 0.42
		draw_rect(Rect2(Vector2.ONE * -(_radius + 12.0 * hit_alpha), Vector2.ONE * (_radius * 2.0 + 24.0 * hit_alpha)), Color(1.0, 0.2, 0.08, hit_alpha * 0.22), false, 3.0)
	_draw_adventurer(color)
	_draw_health_indicator()
	draw_line(Vector2.ZERO, _facing_direction * 35.0, Color(1.0, 0.86, 0.32), 3.0)
	if _is_dashing:
		draw_rect(Rect2(Vector2(-36.0, -36.0), Vector2(72.0, 72.0)), Color(0.76, 1.0, 0.68, 0.72), false, 3.0)
	if _is_stealthed:
		draw_circle(Vector2.ZERO, _radius + 12.0, Color(0.36, 0.86, 1.0, 0.55), false, 3.0)
		draw_arc(Vector2.ZERO, _radius + 20.0, -PI * 0.5, PI * 1.5, 16, Color(0.7, 0.94, 1.0, 0.75), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_pixel_shadow() -> void:
	draw_rect(Rect2(-19.0, 28.0, 38.0, 5.0), Color(0.025, 0.02, 0.016, 0.68))
	draw_rect(Rect2(-13.0, 27.0, 26.0, 6.0), Color(0.055, 0.04, 0.025, 0.52))


func _get_idle_bob_offset() -> float:
	if _state_id != &"idle" or _is_dashing or _attack_visual_remaining > 0.0:
		return 0.0
	return sin(_motion_time * IDLE_BOB_SPEED) * IDLE_BOB_AMPLITUDE


func _get_attack_visual_progress() -> float:
	return clampf(1.0 - _attack_visual_remaining / ATTACK_VISUAL_DURATION, 0.0, 1.0)


func _draw_health_indicator() -> void:
	var pip_size := Vector2(14.0, 7.0)
	var pip_gap: float = 5.0
	var total_width: float = pip_size.x * float(_maximum_health) + pip_gap * float(maxi(0, _maximum_health - 1))
	var start_x: float = -total_width * 0.5
	var health_color: Color = Color(1.0, 0.3, 0.2) if _health <= 1 else Color(1.0, 0.76, 0.34)
	for health_index: int in _maximum_health:
		var pip_position := Vector2(start_x + (pip_size.x + pip_gap) * health_index, -_radius - 22.0)
		draw_rect(Rect2(pip_position - Vector2.ONE * 2.0, pip_size + Vector2.ONE * 4.0), Color(0.04, 0.03, 0.02, 0.94))
		draw_rect(Rect2(pip_position, pip_size), health_color if health_index < _health else Color(0.25, 0.12, 0.09, 0.9))


func _draw_adventurer(armor_color: Color) -> void:
	var outline := Color(0.08, 0.065, 0.04, 0.98)
	var skin := Color(1.0, 0.72, 0.48)
	var cloak := Color(0.18, 0.32, 0.2) if _hit_flash_remaining <= 0.0 else Color(0.7, 0.16, 0.08)
	draw_rect(Rect2(-18.0, 22.0, 36.0, 5.0), Color(0.04, 0.035, 0.025, 0.75))
	draw_rect(Rect2(-10.0, 14.0, 8.0, 12.0), outline)
	draw_rect(Rect2(2.0, 14.0, 8.0, 12.0), outline)
	draw_rect(Rect2(-8.0, 15.0, 5.0, 10.0), Color(0.24, 0.18, 0.11))
	draw_rect(Rect2(3.0, 15.0, 5.0, 10.0), Color(0.24, 0.18, 0.11))
	draw_rect(Rect2(-14.0, -5.0, 28.0, 22.0), outline)
	draw_rect(Rect2(-11.0, -2.0, 22.0, 17.0), armor_color)
	draw_rect(Rect2(-13.0, 1.0, 4.0, 13.0), cloak)
	draw_rect(Rect2(9.0, 1.0, 4.0, 13.0), cloak)
	draw_rect(Rect2(-16.0, 0.0, 5.0, 12.0), outline)
	draw_rect(Rect2(11.0, 0.0, 5.0, 12.0), outline)
	draw_rect(Rect2(-15.0, 2.0, 3.0, 8.0), armor_color)
	draw_rect(Rect2(12.0, 2.0, 3.0, 8.0), armor_color)
	draw_rect(Rect2(-11.0, -22.0, 22.0, 20.0), outline)
	draw_rect(Rect2(-8.0, -19.0, 16.0, 15.0), skin)
	draw_rect(Rect2(-10.0, -25.0, 20.0, 8.0), outline)
	draw_rect(Rect2(-8.0, -23.0, 16.0, 5.0), Color(0.3, 0.38, 0.3))
	draw_rect(Rect2(-6.0, -13.0, 3.0, 3.0), outline)
	draw_rect(Rect2(3.0, -13.0, 3.0, 3.0), outline)
	draw_rect(Rect2(-2.0, -9.0, 4.0, 2.0), Color(0.56, 0.22, 0.16))
	var sword_direction: Vector2 = _get_sword_direction()
	draw_line(Vector2(8.0, 6.0), Vector2(8.0, 6.0) + sword_direction * 29.0, outline, 6.0)
	draw_line(Vector2(8.0, 6.0), Vector2(8.0, 6.0) + sword_direction * 29.0, Color(1.0, 0.9, 0.54), 2.0)


func _get_sword_direction() -> Vector2:
	var sword_direction: Vector2 = _facing_direction.normalized()
	if _attack_visual_remaining <= 0.0:
		return sword_direction
	var attack_progress: float = _get_attack_visual_progress()
	var swing_angle: float
	if attack_progress < 0.45:
		swing_angle = lerpf(-0.62, 0.42, attack_progress / 0.45)
	else:
		swing_angle = lerpf(0.42, 0.0, (attack_progress - 0.45) / 0.55)
	return sword_direction.rotated(swing_angle)
