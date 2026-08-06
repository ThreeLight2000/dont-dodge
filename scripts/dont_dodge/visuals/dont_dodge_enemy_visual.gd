class_name DontDodgeEnemyVisual
extends Node2D

const VISUAL_MAPPING_SCRIPT: Script = preload("res://scripts/dont_dodge/visuals/dont_dodge_visual_mapping.gd")
const HIT_FLASH_DURATION: float = 0.18
const HIT_RECOIL_PIXELS: float = 12.0

var _enemy_type: int = DontDodgeEnemy.EnemyType.MELEE
var _state: int = DontDodgeEnemy.State.CHASE
var _health: int = DontDodgeTuning.MELEE_HEALTH
var _maximum_health: int = DontDodgeTuning.MELEE_HEALTH
var _windup_remaining: float = 0.0
var _impact_position: Vector2 = Vector2.ZERO
var _impact_radius: float = 0.0
var _spawn_lock_ratio: float = 0.0
var _defeat_ratio: float = 0.0
var _charge_direction: Vector2 = Vector2.RIGHT
var _hit_flash_remaining: float = 0.0
var _hit_recoil: Vector2 = Vector2.ZERO
var _type_id: StringName = &"melee"
var _state_id: StringName = &"chase"
var _variant_id: StringName = DontDodgeVisualMapping.FALLBACK_VARIANT
var _mapping: DontDodgeVisualMapping = VISUAL_MAPPING_SCRIPT.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_presentation(type_id: StringName, state_id: StringName, enemy_type: int, state: int, health: int, maximum_health: int, windup_remaining: float, impact_position: Vector2, impact_radius: float, spawn_lock_ratio: float, defeat_ratio: float, charge_direction: Vector2) -> void:
	_type_id = type_id
	_state_id = state_id
	_enemy_type = enemy_type
	_state = state
	_health = health
	_maximum_health = maximum_health
	_windup_remaining = windup_remaining
	_impact_position = impact_position
	_impact_radius = impact_radius
	_spawn_lock_ratio = spawn_lock_ratio
	_defeat_ratio = defeat_ratio
	_charge_direction = charge_direction if charge_direction != Vector2.ZERO else Vector2.RIGHT
	_variant_id = _mapping.resolve(_type_id, _state_id)
	queue_redraw()


func set_visual_mapping(variants_by_type: Dictionary) -> void:
	_mapping.set_variants(variants_by_type)
	_variant_id = _mapping.resolve(_type_id, _state_id)
	queue_redraw()


func get_visual_variant() -> StringName:
	return _variant_id


func play_hit(direction: Vector2 = Vector2.RIGHT) -> void:
	_hit_flash_remaining = HIT_FLASH_DURATION
	_hit_recoil = direction.normalized() * HIT_RECOIL_PIXELS if direction != Vector2.ZERO else Vector2.ZERO
	queue_redraw()


func advance(delta: float) -> void:
	_hit_recoil = _hit_recoil.move_toward(Vector2.ZERO, 420.0 * delta)
	if _hit_flash_remaining <= 0.0 and _hit_recoil == Vector2.ZERO:
		return
	_hit_flash_remaining = maxf(0.0, _hit_flash_remaining - delta)
	queue_redraw()


func _draw() -> void:
	var radius: float = 34.0 if _enemy_type == DontDodgeEnemy.EnemyType.ELITE else 22.0 if _enemy_type == DontDodgeEnemy.EnemyType.VOLLEY else 18.0
	var hit_alpha: float = _hit_flash_remaining / HIT_FLASH_DURATION if _hit_flash_remaining > 0.0 else 0.0
	var defeat_progress: float = 1.0 - _defeat_ratio if _state == DontDodgeEnemy.State.DEFEATED else 0.0
	var body_scale: Vector2 = Vector2.ONE
	if _state == DontDodgeEnemy.State.DEFEATED:
		body_scale = Vector2(1.0 + defeat_progress * 0.18, 1.0 - defeat_progress * 0.45)
	elif hit_alpha > 0.0:
		body_scale = Vector2(1.0 + hit_alpha * 0.1, 1.0 - hit_alpha * 0.08)
	var body_color: Color = Color(1.0, 0.42, 0.34) if _enemy_type == DontDodgeEnemy.EnemyType.MELEE else Color(1.0, 0.72, 0.32) if _enemy_type == DontDodgeEnemy.EnemyType.RANGED else Color(1.0, 0.32, 0.7) if _enemy_type == DontDodgeEnemy.EnemyType.CHARGER else Color(0.42, 0.78, 1.0) if _enemy_type == DontDodgeEnemy.EnemyType.VOLLEY else Color(0.84, 0.48, 1.0)
	if _state == DontDodgeEnemy.State.SPAWN_LOCK:
		body_color = Color(body_color, 0.38)
	if _state == DontDodgeEnemy.State.INTERRUPTED:
		body_color = Color(0.36, 0.94, 1.0)
	elif _state == DontDodgeEnemy.State.DEFEATED:
		body_color = Color(1.0, 0.92, 0.42)
	_draw_pixel_shadow(radius, defeat_progress)
	draw_set_transform(_hit_recoil * (0.75 + hit_alpha * 0.25), 0.0, body_scale)
	if hit_alpha > 0.0:
		body_color = body_color.lerp(Color(1.0, 1.0, 0.92, body_color.a), hit_alpha * 0.82)
		draw_rect(Rect2(Vector2.ONE * -(radius + 14.0 * hit_alpha), Vector2.ONE * (radius * 2.0 + 28.0 * hit_alpha)), Color(1.0, 0.98, 0.76, hit_alpha * 0.9), false, 5.0)
	_draw_enemy_silhouette(body_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _state == DontDodgeEnemy.State.SPAWN_LOCK:
		draw_arc(Vector2.ZERO, radius + 10.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - _spawn_lock_ratio), 24, Color(0.94, 0.96, 1.0, 0.9), 3.0)
	_draw_health_indicator(radius)
	if _state == DontDodgeEnemy.State.DEFEATED:
		draw_arc(Vector2.ZERO, radius + 17.0 * (1.0 - _defeat_ratio), 0.0, TAU, 28, Color(1.0, 0.78, 0.24, _defeat_ratio), 4.0)
		_draw_defeat_burst(radius, defeat_progress)
	_draw_attack_tell(radius)
	if _state == DontDodgeEnemy.State.INTERRUPTED:
		draw_rect(Rect2(Vector2.ONE * -(radius + 10.0), Vector2.ONE * (radius * 2.0 + 20.0)), Color(0.35, 0.95, 1.0), false, 3.0)
	if _state == DontDodgeEnemy.State.CHARGING:
		draw_line(Vector2.ZERO, -_charge_direction * 44.0, Color(1.0, 0.48, 0.82), 6.0)


func _draw_pixel_shadow(radius: float, defeat_progress: float) -> void:
	var shadow_width: float = radius * 1.7 * (1.0 + defeat_progress * 0.3)
	var shadow_y: float = radius + 4.0
	draw_rect(Rect2(Vector2(-shadow_width * 0.5, shadow_y), Vector2(shadow_width, 5.0)), Color(0.025, 0.02, 0.016, 0.68))
	draw_rect(Rect2(Vector2(-shadow_width * 0.32, shadow_y - 1.0), Vector2(shadow_width * 0.64, 6.0)), Color(0.055, 0.04, 0.025, 0.52))


func _draw_defeat_burst(radius: float, defeat_progress: float) -> void:
	var burst_alpha: float = _defeat_ratio * 0.9
	var burst_start: float = radius * 0.55 + defeat_progress * 5.0
	var burst_end: float = radius * 0.72 + defeat_progress * 22.0
	for shard_index: int in 4:
		var shard_direction: Vector2 = Vector2.RIGHT.rotated(PI * 0.25 + float(shard_index) * PI * 0.5)
		draw_line(shard_direction * burst_start, shard_direction * burst_end, Color(1.0, 0.78, 0.24, burst_alpha), 3.0)


func _draw_enemy_silhouette(body_color: Color) -> void:
	var outline := Color(0.07, 0.05, 0.035, 0.98)
	var eye_color := Color(1.0, 0.94, 0.62)
	match _enemy_type:
		DontDodgeEnemy.EnemyType.MELEE:
			draw_rect(Rect2(-15.0, 18.0, 30.0, 5.0), Color(0.04, 0.03, 0.02, 0.75))
			draw_rect(Rect2(-13.0, -5.0, 26.0, 24.0), outline)
			draw_rect(Rect2(-10.0, -2.0, 20.0, 19.0), body_color)
			draw_rect(Rect2(-17.0, -1.0, 5.0, 11.0), outline)
			draw_rect(Rect2(12.0, -1.0, 5.0, 11.0), outline)
			draw_rect(Rect2(-16.0, 1.0, 3.0, 7.0), body_color)
			draw_rect(Rect2(13.0, 1.0, 3.0, 7.0), body_color)
			draw_rect(Rect2(-11.0, -21.0, 22.0, 18.0), outline)
			draw_rect(Rect2(-8.0, -18.0, 16.0, 12.0), Color(0.22, 0.14, 0.11))
			draw_rect(Rect2(-8.0, -23.0, 16.0, 6.0), body_color)
			draw_rect(Rect2(-5.0, -13.0, 3.0, 3.0), eye_color)
			draw_rect(Rect2(2.0, -13.0, 3.0, 3.0), eye_color)
			draw_line(Vector2(10.0, 7.0), Vector2(28.0, -12.0), outline, 6.0)
			draw_line(Vector2(10.0, 7.0), Vector2(28.0, -12.0), Color(0.76, 0.72, 0.64), 2.0)
		DontDodgeEnemy.EnemyType.RANGED:
			draw_rect(Rect2(-14.0, 18.0, 28.0, 5.0), Color(0.04, 0.03, 0.02, 0.75))
			draw_rect(Rect2(-12.0, -6.0, 24.0, 25.0), outline)
			draw_rect(Rect2(-9.0, -3.0, 18.0, 20.0), body_color)
			draw_rect(Rect2(-10.0, -22.0, 20.0, 17.0), outline)
			draw_rect(Rect2(-7.0, -19.0, 14.0, 11.0), Color(0.72, 0.58, 0.38))
			draw_rect(Rect2(-12.0, -8.0, 24.0, 4.0), outline)
			draw_rect(Rect2(-9.0, -7.0, 18.0, 2.0), Color(0.78, 0.48, 0.18))
			draw_rect(Rect2(-5.0, -14.0, 3.0, 3.0), eye_color)
			draw_rect(Rect2(2.0, -14.0, 3.0, 3.0), eye_color)
			draw_line(Vector2(14.0, -5.0), Vector2(25.0, 12.0), Color(0.78, 0.48, 0.18), 3.0)
			draw_arc(Vector2(17.0, 3.0), 10.0, -PI * 0.55, PI * 0.55, 8, Color(0.78, 0.48, 0.18), 2.0)
		DontDodgeEnemy.EnemyType.CHARGER:
			draw_rect(Rect2(-22.0, 15.0, 44.0, 8.0), Color(0.04, 0.03, 0.02, 0.75))
			draw_rect(Rect2(-22.0, -7.0, 44.0, 24.0), outline)
			draw_rect(Rect2(-18.0, -3.0, 36.0, 18.0), body_color)
			draw_rect(Rect2(-16.0, -19.0, 32.0, 15.0), outline)
			draw_rect(Rect2(-12.0, -16.0, 24.0, 10.0), Color(0.22, 0.1, 0.18))
			draw_line(Vector2(-12.0, -15.0), Vector2(-23.0, -27.0), Color(0.94, 0.84, 0.66), 5.0)
			draw_line(Vector2(12.0, -15.0), Vector2(23.0, -27.0), Color(0.94, 0.84, 0.66), 5.0)
			draw_line(Vector2(17.0, -1.0), Vector2(27.0, 5.0), outline, 6.0)
			draw_line(Vector2(18.0, -1.0), Vector2(27.0, 5.0), Color(1.0, 0.42, 0.7), 2.0)
			draw_rect(Rect2(-8.0, -13.0, 4.0, 4.0), eye_color)
			draw_rect(Rect2(4.0, -13.0, 4.0, 4.0), eye_color)
		DontDodgeEnemy.EnemyType.VOLLEY:
			draw_rect(Rect2(-24.0, -8.0, 48.0, 5.0), outline)
			draw_rect(Rect2(-18.0, -7.0, 36.0, 2.0), body_color)
			for orb_index: int in 3:
				var offset_x: float = -17.0 + orb_index * 17.0
				draw_rect(Rect2(offset_x - 8.0, -4.0, 16.0, 20.0), outline)
				draw_rect(Rect2(offset_x - 5.0, -1.0, 10.0, 14.0), body_color)
				draw_rect(Rect2(offset_x - 2.0, 3.0, 4.0, 4.0), eye_color)
				draw_rect(Rect2(offset_x - 5.0, 17.0, 10.0, 3.0), Color(0.12, 0.16, 0.22))
			draw_rect(Rect2(-27.0, 21.0, 54.0, 5.0), Color(0.04, 0.03, 0.02, 0.75))
		_:
			draw_rect(Rect2(-32.0, 25.0, 64.0, 7.0), Color(0.04, 0.03, 0.02, 0.78))
			draw_rect(Rect2(-29.0, -8.0, 58.0, 35.0), outline)
			draw_rect(Rect2(-25.0, -4.0, 50.0, 27.0), body_color)
			draw_rect(Rect2(-34.0, -2.0, 8.0, 16.0), outline)
			draw_rect(Rect2(26.0, -2.0, 8.0, 16.0), outline)
			draw_rect(Rect2(-31.0, 1.0, 5.0, 10.0), Color(0.84, 0.48, 1.0))
			draw_rect(Rect2(26.0, 1.0, 5.0, 10.0), Color(0.84, 0.48, 1.0))
			draw_rect(Rect2(-22.0, -31.0, 44.0, 26.0), outline)
			draw_rect(Rect2(-17.0, -26.0, 34.0, 16.0), Color(0.22, 0.14, 0.18))
			for crown_index: int in 3:
				draw_rect(Rect2(-14.0 + crown_index * 11.0, -37.0 + (0 if crown_index == 1 else 6), 7.0, 14.0), Color(1.0, 0.74, 0.24))
			draw_rect(Rect2(-11.0, -20.0, 6.0, 5.0), eye_color)
			draw_rect(Rect2(5.0, -20.0, 6.0, 5.0), eye_color)


func _draw_role_glyph(radius: float, color: Color) -> void:
	var glyph_origin := Vector2(0.0, -radius - 18.0)
	var outline := Color(0.06, 0.05, 0.03, 0.92)
	match _enemy_type:
		DontDodgeEnemy.EnemyType.MELEE:
			draw_rect(Rect2(glyph_origin + Vector2(-8.0, -2.0), Vector2(16.0, 4.0)), outline)
			draw_rect(Rect2(glyph_origin + Vector2(-2.0, -8.0), Vector2(4.0, 16.0)), outline)
			draw_rect(Rect2(glyph_origin + Vector2(-6.0, -1.0), Vector2(12.0, 2.0)), color)
			draw_rect(Rect2(glyph_origin + Vector2(-1.0, -6.0), Vector2(2.0, 12.0)), color)
		DontDodgeEnemy.EnemyType.RANGED:
			draw_rect(Rect2(glyph_origin + Vector2(-8.0, -8.0), Vector2(16.0, 16.0)), outline, false, 3.0)
			draw_rect(Rect2(glyph_origin + Vector2(-2.0, -6.0), Vector2(4.0, 12.0)), color)
			draw_rect(Rect2(glyph_origin + Vector2(-6.0, -2.0), Vector2(12.0, 4.0)), color)
		DontDodgeEnemy.EnemyType.CHARGER:
			draw_line(glyph_origin + Vector2(-8.0, -7.0), glyph_origin + Vector2(0.0, 0.0), outline, 6.0)
			draw_line(glyph_origin + Vector2(0.0, 0.0), glyph_origin + Vector2(-8.0, 7.0), outline, 6.0)
			draw_line(glyph_origin + Vector2(-7.0, -6.0), glyph_origin + Vector2(1.0, 0.0), color, 2.0)
			draw_line(glyph_origin + Vector2(1.0, 0.0), glyph_origin + Vector2(-7.0, 6.0), color, 2.0)
		DontDodgeEnemy.EnemyType.VOLLEY:
			for glyph_index: int in 3:
				draw_rect(Rect2(glyph_origin + Vector2(-9.0 + glyph_index * 7.0, -6.0), Vector2(5.0, 12.0)), outline)
				draw_rect(Rect2(glyph_origin + Vector2(-8.0 + glyph_index * 7.0, -5.0), Vector2(3.0, 10.0)), color)
		_:
			draw_rect(Rect2(glyph_origin + Vector2(-10.0, -7.0), Vector2(20.0, 14.0)), outline)
			for crown_index: int in 3:
				draw_rect(Rect2(glyph_origin + Vector2(-8.0 + crown_index * 7.0, -10.0 + (1 if crown_index == 1 else 4)), Vector2(4.0, 12.0)), color)
			draw_rect(Rect2(glyph_origin + Vector2(-8.0, 3.0), Vector2(16.0, 3.0)), color)


func _draw_attack_tell(radius: float) -> void:
	if _state != DontDodgeEnemy.State.WINDUP:
		return
	var warning_color: Color = Color(1.0, 0.2, 0.26, 0.22 + sin(_windup_remaining * 17.0) * 0.08)
	var windup_duration: float = 1.1 if _enemy_type != DontDodgeEnemy.EnemyType.MELEE else 0.65
	var windup_ratio: float = clampf(_windup_remaining / windup_duration, 0.0, 1.0)
	draw_arc(Vector2.ZERO, radius + 9.0, -PI * 0.5, -PI * 0.5 + TAU * windup_ratio, 24, Color(1.0, 0.36, 0.24, 0.92), 4.0)
	if _enemy_type == DontDodgeEnemy.EnemyType.RANGED:
		draw_line(Vector2.ZERO, _impact_position, Color(1.0, 0.72, 0.18, 0.9), 3.0)
		draw_circle(_impact_position, 18.0, warning_color)
	elif _enemy_type == DontDodgeEnemy.EnemyType.VOLLEY:
		var volley_direction: Vector2 = _impact_position.normalized() if _impact_position != Vector2.ZERO else Vector2.RIGHT
		for volley_index: int in DontDodgeTuning.VOLLEY_PROJECTILE_COUNT:
			var spread_progress: float = float(volley_index) / float(DontDodgeTuning.VOLLEY_PROJECTILE_COUNT - 1)
			var angle_offset: float = deg_to_rad(lerpf(-DontDodgeTuning.VOLLEY_TOTAL_SPREAD_DEGREES * 0.5, DontDodgeTuning.VOLLEY_TOTAL_SPREAD_DEGREES * 0.5, spread_progress))
			draw_line(Vector2.ZERO, volley_direction.rotated(angle_offset) * 180.0, Color(0.36, 0.74, 1.0, 0.95), 3.0)
	elif _enemy_type == DontDodgeEnemy.EnemyType.CHARGER:
		draw_line(Vector2.ZERO, _impact_position, Color(1.0, 0.2, 0.72, 0.92), 12.0)
		draw_circle(_impact_position, _impact_radius, warning_color)
		draw_arc(_impact_position, _impact_radius, 0.0, TAU, 32, Color(1.0, 0.38, 0.78, 0.95), 3.0)
	else:
		draw_circle(_impact_position, _impact_radius, warning_color)
		draw_arc(_impact_position, _impact_radius, 0.0, TAU, 40, Color(1.0, 0.58, 0.24, 0.95), 3.0)


func _draw_health_indicator(radius: float) -> void:
	var bar_position := Vector2(-radius, -radius - 15.0)
	var health_ratio: float = maxf(0.0, float(_health) / float(_maximum_health))
	draw_rect(Rect2(bar_position - Vector2(2.0, 2.0), Vector2(radius * 2.0 + 4.0, 9.0)), Color(0.08, 0.06, 0.04, 0.96))
	draw_rect(Rect2(bar_position, Vector2(radius * 2.0, 5.0)), Color(0.28, 0.08, 0.08))
	draw_rect(Rect2(bar_position, Vector2(radius * 2.0 * health_ratio, 5.0)), Color(1.0, 0.82, 0.34) if _state != DontDodgeEnemy.State.DEFEATED else Color(1.0, 0.4, 0.22))
