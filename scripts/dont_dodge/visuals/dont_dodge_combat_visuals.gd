class_name DontDodgeCombatVisuals
extends Node2D

const PIXEL_SEGMENT_COUNT: int = 16
const ULTIMATE_VISUAL_DURATION: float = 0.78

var _arena_size: Vector2 = DontDodgeTuning.ARENA_SIZE
var _spawn_warnings: Array[Dictionary] = []
var _has_priority_target: bool = false
var _priority_target_player_position: Vector2 = Vector2.ZERO
var _priority_target_position: Vector2 = Vector2.ZERO
var _focus_preview: Dictionary = {}
var _focus_wave_remaining: float = 0.0
var _focus_wave_position: Vector2 = Vector2.ZERO
var _focus_wave_direction: Vector2 = Vector2.RIGHT
var _focus_wave_range: float = 0.0
var _focus_wave_arc_angle: float = 0.0
var _negate_wave_remaining: float = 0.0
var _negate_wave_position: Vector2 = Vector2.ZERO
var _negate_wave_radius: float = 0.0
var _ultimate_wave_remaining: float = 0.0
var _ultimate_wave_position: Vector2 = Vector2.ZERO
var _ultimate_wave_radius: float = 0.0
var _damage_feedbacks: Array[Dictionary] = []
var _melee_impact_feedbacks: Array[Dictionary] = []
var _special_effects: Array[Dictionary] = []
var _is_simulation_paused: bool = false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_arena_size(arena_size: Vector2) -> void:
	_arena_size = arena_size
	queue_redraw()


func set_spawn_warnings(warnings: Array[Dictionary]) -> void:
	_spawn_warnings = warnings
	queue_redraw()


func set_priority_target_line(player_position: Vector2, target_position: Vector2) -> void:
	_has_priority_target = true
	_priority_target_player_position = player_position
	_priority_target_position = target_position
	queue_redraw()


func clear_priority_target_line() -> void:
	if not _has_priority_target:
		return
	_has_priority_target = false
	queue_redraw()


func set_focus_preview(player_position: Vector2, target_position: Vector2, target_radius: float, direction: Vector2, focus_range: float, focus_arc_angle: float) -> void:
	_focus_preview = {
		"player_position": player_position,
		"target_position": target_position,
		"target_radius": target_radius,
		"direction": direction if direction != Vector2.ZERO else Vector2.RIGHT,
		"focus_range": focus_range,
		"focus_arc_angle": focus_arc_angle,
	}
	queue_redraw()


func clear_focus_preview() -> void:
	if _focus_preview.is_empty():
		return
	_focus_preview.clear()
	queue_redraw()


func show_focus_wave(position: Vector2, direction: Vector2, focus_range: float, focus_arc_angle: float) -> void:
	_focus_wave_remaining = 0.26
	_focus_wave_position = position
	_focus_wave_direction = direction if direction != Vector2.ZERO else Vector2.RIGHT
	_focus_wave_range = focus_range
	_focus_wave_arc_angle = focus_arc_angle
	queue_redraw()


func show_negate_wave(position: Vector2, radius: float) -> void:
	_negate_wave_remaining = 0.28
	_negate_wave_position = position
	_negate_wave_radius = radius
	queue_redraw()


func show_ultimate_wave(position: Vector2, radius: float) -> void:
	show_ultimate_burst(position, radius)

func show_ultimate_burst(position: Vector2, radius: float) -> void:
	_ultimate_wave_remaining = ULTIMATE_VISUAL_DURATION
	_ultimate_wave_position = position
	_ultimate_wave_radius = radius
	queue_redraw()


func show_guard_arc(position: Vector2, direction: Vector2, arc_degrees: float) -> void:
	_add_special_effect("guard_arc", {"position": position, "direction": direction, "arc_degrees": arc_degrees, "duration": 0.32})


func show_guard_success(position: Vector2, direction: Vector2) -> void:
	_add_special_effect("guard_success", {"position": position, "direction": direction, "duration": 0.34})


func show_reflect_burst(position: Vector2, direction: Vector2) -> void:
	_add_special_effect("reflect_burst", {"position": position, "direction": direction, "duration": 0.38})


func show_reflect_wave(position: Vector2, radius: float) -> void:
	_add_special_effect("reflect_wave", {"position": position, "radius": radius, "duration": 0.42})


func show_mace_ground_telegraph(position: Vector2, radius: float, duration_value: float) -> void:
	_add_special_effect("mace_ground_telegraph", {"position": position, "radius": radius, "duration": duration_value})


func show_mace_counter_impact(position: Vector2, direction: Vector2) -> void:
	_add_special_effect("mace_counter_impact", {"position": position, "direction": direction, "duration": 0.3})


func show_mace_suppress_impact(position: Vector2, direction: Vector2) -> void:
	_add_special_effect("mace_suppress_impact", {"position": position, "direction": direction, "duration": DontDodgeTuning.MACE_SUPPRESS_IMPACT_DURATION})


func show_mace_frontline_target(start_position: Vector2, end_position: Vector2, target: Node2D = null, duration_value: float = 0.5) -> void:
	_add_special_effect("mace_frontline_target", {"start": start_position, "end": end_position, "target": target, "duration": duration_value})


func show_dagger_followup(position: Vector2, direction: Vector2, range_value: float) -> void:
	_add_special_effect("dagger_followup", {"position": position, "direction": direction, "range": range_value, "duration": 0.28})


func show_dagger_target_marker(position: Vector2, target: Node2D = null) -> void:
	_add_special_effect("dagger_target_marker", {"position": position, "target": target, "duration": DontDodgeTuning.DAGGER_SHADOW_FRENZY_TARGET_MARK_DURATION})


func show_dagger_range_preview(position: Vector2, radius: float, duration_value: float) -> void:
	_add_special_effect("dagger_range_preview", {"position": position, "radius": radius, "duration": duration_value})


func show_dagger_dash_endpoint(position: Vector2, duration_value: float) -> void:
	_add_special_effect("dagger_dash_endpoint", {"position": position, "duration": duration_value})


func show_spear_pierce(position: Vector2, direction: Vector2, range_value: float, arc_angle: float) -> void:
	_add_special_effect("spear_pierce", {"position": position, "direction": direction, "range": range_value, "arc_angle": arc_angle, "duration": 0.34})


func show_spear_contact(position: Vector2, direction: Vector2) -> void:
	_add_special_effect("spear_contact", {"position": position, "direction": direction, "duration": 0.36})


func show_spear_bullet_cut(position: Vector2, direction: Vector2, range_value: float, lane_width: float, lane_spacing: float) -> void:
	_add_special_effect("spear_bullet_cut", {"position": position, "direction": direction, "range": range_value, "lane_width": lane_width, "lane_spacing": lane_spacing, "duration": 0.42})


func show_spear_edge_pressure(position: Vector2, target: Node2D = null) -> void:
	_add_special_effect("spear_edge_pressure", {"position": position, "target": target, "duration": DontDodgeTuning.SPEAR_EDGE_PRESSURE_DURATION})


func show_spear_target_marker(position: Vector2, target: Node2D = null, duration_value: float = 0.4) -> void:
	_add_special_effect("spear_target_marker", {"position": position, "target": target, "duration": duration_value})


func show_radial_strike(position: Vector2, radius: float) -> void:
	_add_special_effect("radial_strike", {"position": position, "radius": radius, "duration": 0.52})


func show_spear_line(start_position: Vector2, end_position: Vector2, width: float, duration_value: float = 0.7) -> void:
	_add_special_effect("spear_line", {"start": start_position, "end": end_position, "width": width, "duration": duration_value})


func show_spear_formation(start_position: Vector2, end_position: Vector2, width: float, duration_value: float = 0.9) -> void:
	_add_special_effect("spear_formation", {"start": start_position, "end": end_position, "width": width, "duration": duration_value})


func show_spear_formation_pulse(start_position: Vector2, end_position: Vector2, width: float, pulse_index: int) -> void:
	_add_special_effect("spear_formation_pulse", {"start": start_position, "end": end_position, "width": width, "pulse_index": pulse_index, "duration": 0.24})


func show_ultimate_dash(start_position: Vector2, end_position: Vector2, duration_value: float = 0.62) -> void:
	_add_special_effect("ultimate_dash", {"start": start_position, "end": end_position, "duration": duration_value})


func show_assassination_mark(position: Vector2, target: Node2D = null) -> void:
	_add_special_effect("assassination_mark", {"position": position, "target": target, "duration": DontDodgeTuning.DAGGER_ASSASSINATION_MARK_DURATION})


func show_stealth_burst(position: Vector2) -> void:
	_add_special_effect("stealth_burst", {"position": position, "duration": 0.4})


func _add_special_effect(kind: StringName, effect: Dictionary) -> void:
	effect["kind"] = kind
	effect["elapsed"] = 0.0
	_special_effects.append(effect)
	queue_redraw()


func show_enemy_damage(position: Vector2, damage: int, remaining_health: int, was_defeated: bool) -> void:
	_damage_feedbacks.append({"position": position, "damage": damage, "remaining_health": remaining_health, "defeated": was_defeated, "player": false, "elapsed": 0.0, "duration": 0.30})
	queue_redraw()


func show_player_damage(position: Vector2, damage: int, remaining_health: int) -> void:
	_damage_feedbacks.append({"position": position, "damage": damage, "remaining_health": remaining_health, "defeated": false, "player": true, "elapsed": 0.0, "duration": 0.34})
	queue_redraw()


func show_melee_impact(position: Vector2, radius: float) -> void:
	_melee_impact_feedbacks.append({"position": position, "radius": radius, "elapsed": 0.0, "duration": 0.32})
	queue_redraw()


func set_simulation_paused(is_paused: bool) -> void:
	_is_simulation_paused = is_paused


func _process(delta: float) -> void:
	if _is_simulation_paused:
		return
	_focus_wave_remaining = maxf(0.0, _focus_wave_remaining - delta)
	_negate_wave_remaining = maxf(0.0, _negate_wave_remaining - delta)
	_ultimate_wave_remaining = maxf(0.0, _ultimate_wave_remaining - delta)
	for feedback: Dictionary in _damage_feedbacks:
		feedback["elapsed"] = float(feedback["elapsed"]) + delta
	for feedback: Dictionary in _melee_impact_feedbacks:
		feedback["elapsed"] = float(feedback["elapsed"]) + delta
	for effect: Dictionary in _special_effects:
		effect["elapsed"] = float(effect["elapsed"]) + delta
	_damage_feedbacks = _damage_feedbacks.filter(func(feedback: Dictionary) -> bool: return float(feedback["elapsed"]) < float(feedback["duration"]))
	_melee_impact_feedbacks = _melee_impact_feedbacks.filter(func(feedback: Dictionary) -> bool: return float(feedback["elapsed"]) < float(feedback["duration"]))
	_special_effects = _special_effects.filter(func(effect: Dictionary) -> bool: return float(effect["elapsed"]) < float(effect["duration"]))
	queue_redraw()


func _draw() -> void:
	_draw_spawn_warnings()
	if _has_priority_target:
		draw_dashed_line(_priority_target_player_position, _priority_target_position, Color(1.0, 0.82, 0.3, 0.46), 2.0, 10.0)
	_draw_focus_preview()
	if _focus_wave_remaining > 0.0:
		_draw_focus_wave(_focus_wave_position, _focus_wave_direction, _focus_wave_range, _focus_wave_arc_angle, 1.0 - _focus_wave_remaining / 0.26)
	if _negate_wave_remaining > 0.0:
		var negate_alpha: float = _negate_wave_remaining / 0.28
		_draw_pixel_ring(_negate_wave_position, _negate_wave_radius * (1.0 - negate_alpha * 0.16), Color(0.38, 0.94, 1.0, negate_alpha), 5.0)
	if _ultimate_wave_remaining > 0.0:
		var ultimate_elapsed: float = ULTIMATE_VISUAL_DURATION - _ultimate_wave_remaining
		_draw_ultimate_burst(_ultimate_wave_position, _ultimate_wave_radius, ultimate_elapsed)
	_draw_special_effects()
	_draw_combat_feedback()


func _draw_spawn_warnings() -> void:
	for warning: Dictionary in _spawn_warnings:
		var position: Vector2 = warning["position"]
		var remaining: float = float(warning["remaining"])
		var full_duration: float = _spawn_warning_duration(int(warning["enemy_type"]))
		var progress: float = 1.0 - remaining / full_duration
		var radius: float = 28.0 + progress * 18.0
		var color: Color = Color(1.0, 0.48, 0.2, 0.72) if int(warning["enemy_type"]) != DontDodgeEnemy.EnemyType.ELITE else Color(0.72, 0.38, 1.0, 0.82)
		draw_rect(Rect2(position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), Color(color, 0.08))
		_draw_pixel_ring_arc(position, radius, progress, color, 3.0)


func _draw_focus_preview() -> void:
	if _focus_preview.is_empty():
		return
	var player_position: Vector2 = _focus_preview["player_position"]
	var target_position: Vector2 = _focus_preview["target_position"]
	_draw_focus_wedge(player_position, _focus_preview["direction"], float(_focus_preview["focus_range"]), float(_focus_preview["focus_arc_angle"]), 0.1)
	_draw_pixel_ring(target_position, float(_focus_preview["target_radius"]) + 10.0, Color(1.0, 0.84, 0.32, 0.9), 3.0)


func _draw_special_effects() -> void:
	for effect: Dictionary in _special_effects:
		var progress: float = clampf(float(effect["elapsed"]) / float(effect["duration"]), 0.0, 1.0)
		var alpha: float = 1.0 - progress
		var kind: StringName = StringName(effect["kind"])
		match kind:
			&"guard_arc":
				var guard_position: Vector2 = effect["position"]
				var guard_direction: Vector2 = effect["direction"]
				_draw_focus_wedge(guard_position, guard_direction, 150.0 + progress * 20.0, deg_to_rad(float(effect["arc_degrees"])), alpha * 0.8)
				_draw_pixel_ring(guard_position, 34.0 + progress * 16.0, Color(0.38, 0.94, 1.0, alpha), 4.0)
			&"guard_success":
				var success_position: Vector2 = effect["position"]
				var success_direction: Vector2 = effect["direction"]
				_draw_focus_wedge(success_position, success_direction, 170.0, deg_to_rad(150.0), alpha * 0.55)
				for ray_index: int in 5:
					var ray_direction: Vector2 = success_direction.rotated(lerpf(-0.8, 0.8, float(ray_index) / 4.0))
					draw_line(success_position + ray_direction * 38.0, success_position + ray_direction * (72.0 + progress * 48.0), Color(0.8, 1.0, 1.0, alpha), 4.0)
			&"reflect_burst":
				var reflect_position: Vector2 = effect["position"]
				var reflect_direction: Vector2 = effect["direction"]
				_draw_pixel_ring(reflect_position, 18.0 + progress * 28.0, Color(0.36, 0.94, 1.0, alpha), 5.0)
				draw_line(reflect_position, reflect_position + reflect_direction * (34.0 + progress * 50.0), Color(0.86, 1.0, 1.0, alpha), 5.0)
			&"reflect_wave":
				_draw_pixel_ring(effect["position"], float(effect["radius"]) * (0.25 + progress * 0.75), Color(0.42, 0.94, 1.0, alpha), 5.0)
			&"mace_ground_telegraph":
				var ground_position: Vector2 = effect["position"]
				var ground_radius: float = float(effect["radius"])
				var ground_pulse: float = 0.5 + sin(progress * TAU * 2.0) * 0.5
				var ground_preview_radius: float = ground_radius * (0.72 + progress * 0.28)
				draw_circle(ground_position, ground_preview_radius, Color(0.72, 0.3, 0.08, alpha * 0.08))
				draw_arc(ground_position, ground_preview_radius, 0.0, TAU, 48, Color(1.0, 0.7, 0.28, alpha * (0.45 + ground_pulse * 0.25)), 4.0)
				_draw_pixel_ring(ground_position, 34.0 + ground_pulse * 12.0, Color(1.0, 0.9, 0.48, alpha), 5.0)
			&"mace_counter_impact":
				var counter_position: Vector2 = effect["position"]
				var counter_direction: Vector2 = effect["direction"]
				_draw_focus_wedge(counter_position, counter_direction, 190.0 + progress * 30.0, deg_to_rad(150.0), alpha * 0.6)
				_draw_pixel_ring(counter_position, 26.0 + progress * 42.0, Color(1.0, 0.72, 0.26, alpha), 7.0)
				for ray_index: int in 7:
					var ray_direction: Vector2 = counter_direction.rotated(lerpf(-0.9, 0.9, float(ray_index) / 6.0))
					draw_line(counter_position + ray_direction * 34.0, counter_position + ray_direction * (80.0 + progress * 52.0), Color(1.0, 0.94, 0.62, alpha), 4.0)
			&"mace_suppress_impact":
				var suppress_position: Vector2 = effect["position"]
				var suppress_direction: Vector2 = effect["direction"]
				_draw_focus_wedge(suppress_position, suppress_direction, 130.0 + progress * 24.0, deg_to_rad(90.0), alpha * 0.72)
				_draw_pixel_ring(suppress_position, 20.0 + progress * 28.0, Color(1.0, 0.62, 0.2, alpha), 6.0)
			&"mace_frontline_target":
				var frontline_start: Vector2 = effect["start"]
				var frontline_end: Vector2 = effect["end"]
				var frontline_target: Node2D = effect.get("target") as Node2D
				var frontline_marker: Vector2 = frontline_end
				if is_instance_valid(frontline_target):
					frontline_marker = frontline_target.global_position
				draw_dashed_line(frontline_start, frontline_end, Color(1.0, 0.74, 0.28, alpha), 6.0, 12.0)
				_draw_pixel_ring(frontline_marker, 26.0 + sin(progress * TAU * 2.0) * 5.0, Color(1.0, 0.86, 0.42, alpha), 5.0)
			&"dagger_followup":
				var dagger_position: Vector2 = effect["position"]
				var dagger_direction: Vector2 = effect["direction"]
				var dagger_range: float = float(effect["range"])
				draw_line(dagger_position + dagger_direction * 18.0, dagger_position + dagger_direction * dagger_range, Color(0.56, 0.96, 1.0, alpha), 5.0)
				_draw_pixel_ring(dagger_position + dagger_direction * dagger_range, 10.0 + progress * 12.0, Color(0.84, 1.0, 1.0, alpha), 3.0)
			&"spear_pierce":
				_draw_focus_wedge(effect["position"], effect["direction"], float(effect["range"]) * (0.85 + progress * 0.15), float(effect["arc_angle"]), alpha * 0.7)
			&"spear_contact":
				var contact_position: Vector2 = effect["position"]
				var contact_direction: Vector2 = effect["direction"]
				_draw_pixel_ring(contact_position, 24.0 + progress * 26.0, Color(0.62, 0.86, 1.0, alpha), 4.0)
				draw_line(contact_position - contact_direction * 38.0, contact_position + contact_direction * 60.0, Color(0.9, 0.98, 1.0, alpha), 5.0)
			&"spear_bullet_cut":
				var bullet_cut_position: Vector2 = effect["position"]
				var bullet_cut_direction: Vector2 = effect["direction"].normalized()
				if bullet_cut_direction == Vector2.ZERO:
					bullet_cut_direction = Vector2.RIGHT
				var bullet_cut_perpendicular: Vector2 = bullet_cut_direction.orthogonal()
				var bullet_cut_range: float = float(effect["range"]) * (0.55 + progress * 0.45)
				var bullet_cut_spacing: float = float(effect["lane_spacing"])
				for lane_offset: float in [-bullet_cut_spacing, 0.0, bullet_cut_spacing]:
					var lane_start: Vector2 = bullet_cut_position + bullet_cut_perpendicular * lane_offset
					draw_line(lane_start, lane_start + bullet_cut_direction * bullet_cut_range, Color(0.72, 0.94, 1.0, alpha), float(effect["lane_width"]) * 0.35)
					_draw_pixel_ring(lane_start + bullet_cut_direction * bullet_cut_range, 8.0 + progress * 8.0, Color(0.92, 1.0, 1.0, alpha), 3.0)
			&"spear_edge_pressure":
				var edge_position: Vector2 = effect["position"]
				var edge_target: Node2D = effect.get("target") as Node2D
				if is_instance_valid(edge_target):
					edge_position = edge_target.global_position
				_draw_pixel_ring(edge_position, 24.0 + sin(progress * TAU * 2.0) * 5.0, Color(0.42, 0.9, 1.0, alpha), 4.0)
				draw_line(edge_position - Vector2(18.0, 0.0), edge_position + Vector2(18.0, 0.0), Color(0.84, 1.0, 1.0, alpha), 3.0)
				draw_line(edge_position - Vector2(0.0, 18.0), edge_position + Vector2(0.0, 18.0), Color(0.84, 1.0, 1.0, alpha), 3.0)
			&"spear_target_marker":
				var spear_marker_position: Vector2 = effect["position"]
				var spear_marker_target: Node2D = effect.get("target") as Node2D
				if is_instance_valid(spear_marker_target):
					spear_marker_position = spear_marker_target.global_position
				_draw_pixel_ring(spear_marker_position, 28.0 + sin(progress * TAU * 2.0) * 5.0, Color(0.48, 0.9, 1.0, alpha), 5.0)
				_draw_pixel_ring(spear_marker_position, 38.0, Color(0.82, 1.0, 1.0, alpha * 0.7), 3.0)
			&"radial_strike":
				var radial_position: Vector2 = effect["position"]
				var radial_radius: float = float(effect["radius"])
				_draw_pixel_ring(radial_position, radial_radius * (0.25 + progress * 0.75), Color(1.0, 0.72, 0.3, alpha), 7.0)
				for ray_index: int in 12:
					var radial_direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(ray_index) / 12.0)
					draw_line(radial_position + radial_direction * radial_radius * 0.35, radial_position + radial_direction * radial_radius * (0.5 + progress * 0.5), Color(1.0, 0.9, 0.58, alpha * 0.72), 4.0)
			&"spear_line":
				var line_start: Vector2 = effect["start"]
				var line_end: Vector2 = effect["end"]
				draw_line(line_start, line_end, Color(0.62, 0.88, 1.0, alpha * 0.4), float(effect["width"]) * 2.0)
				draw_line(line_start, line_end, Color(0.92, 1.0, 1.0, alpha), 5.0)
			&"spear_formation":
				var formation_start: Vector2 = effect["start"]
				var formation_end: Vector2 = effect["end"]
				var formation_width: float = float(effect["width"])
				var formation_direction: Vector2 = (formation_end - formation_start).normalized()
				var formation_length: float = formation_start.distance_to(formation_end)
				if formation_direction == Vector2.ZERO:
					formation_direction = Vector2.RIGHT
				draw_line(formation_start, formation_end, Color(0.54, 0.78, 1.0, alpha * 0.3), formation_width)
				for pulse_index: int in DontDodgeTuning.SPEAR_FORMATION_PULSES:
					var pulse_progress: float = clampf(progress * float(DontDodgeTuning.SPEAR_FORMATION_PULSES) - float(pulse_index), 0.0, 1.0)
					var pulse_offset: Vector2 = formation_direction * formation_length * (0.18 + float(pulse_index) * 0.28)
					var line_center: Vector2 = (formation_start + formation_end) * 0.5
					_draw_pixel_ring(line_center + pulse_offset, 18.0 + pulse_progress * 24.0, Color(0.86, 0.98, 1.0, alpha), 4.0)
					_draw_pixel_ring(line_center - pulse_offset, 18.0 + pulse_progress * 24.0, Color(0.86, 0.98, 1.0, alpha), 4.0)
			&"spear_formation_pulse":
				var formation_pulse_start: Vector2 = effect["start"]
				var formation_pulse_end: Vector2 = effect["end"]
				var formation_pulse_direction: Vector2 = (formation_pulse_end - formation_pulse_start).normalized()
				var formation_pulse_length: float = formation_pulse_start.distance_to(formation_pulse_end)
				if formation_pulse_direction == Vector2.ZERO:
					formation_pulse_direction = Vector2.RIGHT
				var pulse_edge_offset: Vector2 = formation_pulse_direction * formation_pulse_length * (0.45 + progress * 0.55)
				draw_line(formation_pulse_start, formation_pulse_end, Color(0.84, 0.98, 1.0, alpha), float(effect["width"]))
				_draw_pixel_ring(formation_pulse_start + pulse_edge_offset, 22.0 + progress * 18.0, Color(0.94, 1.0, 1.0, alpha), 5.0)
				_draw_pixel_ring(formation_pulse_end - pulse_edge_offset, 22.0 + progress * 18.0, Color(0.94, 1.0, 1.0, alpha), 5.0)
			&"ultimate_dash":
				draw_dashed_line(effect["start"], effect["end"], Color(0.88, 1.0, 0.72, alpha), 7.0, 12.0)
			&"dagger_range_preview":
				var range_position: Vector2 = effect["position"]
				var range_radius: float = float(effect["radius"])
				var range_color: Color = Color(0.42, 0.9, 1.0, alpha * 0.46)
				draw_arc(range_position, range_radius, 0.0, TAU, 64, range_color, 2.0)
				_draw_pixel_ring(range_position, range_radius, Color(0.72, 1.0, 1.0, alpha * 0.32), 3.0)
				for tick_index: int in 8:
					var tick_direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(tick_index) / 8.0)
					draw_line(
						range_position + tick_direction * (range_radius - 8.0),
						range_position + tick_direction * (range_radius + 8.0),
						Color(0.64, 0.96, 1.0, alpha * 0.44),
						2.0,
					)
			&"dagger_dash_endpoint":
				var endpoint_position: Vector2 = effect["position"]
				var endpoint_pulse: float = 1.0 + sin(progress * TAU * 2.0) * 0.16
				var endpoint_radius: float = 16.0 * endpoint_pulse
				var endpoint_color: Color = Color(1.0, 0.9, 0.42, alpha)
				_draw_pixel_ring(endpoint_position, endpoint_radius, endpoint_color, 4.0)
				draw_line(endpoint_position - Vector2(24.0, 0.0), endpoint_position - Vector2(9.0, 0.0), Color(1.0, 0.96, 0.7, alpha), 3.0)
				draw_line(endpoint_position + Vector2(9.0, 0.0), endpoint_position + Vector2(24.0, 0.0), Color(1.0, 0.96, 0.7, alpha), 3.0)
				draw_line(endpoint_position - Vector2(0.0, 24.0), endpoint_position - Vector2(0.0, 9.0), Color(1.0, 0.96, 0.7, alpha), 3.0)
				draw_line(endpoint_position + Vector2(0.0, 9.0), endpoint_position + Vector2(0.0, 24.0), Color(1.0, 0.96, 0.7, alpha), 3.0)
			&"dagger_target_marker":
				var target_marker_position: Vector2 = effect["position"]
				var target_marker: Node2D = effect.get("target") as Node2D
				if is_instance_valid(target_marker):
					target_marker_position = target_marker.global_position
				var marker_pulse: float = 1.0 + sin(progress * TAU * 2.0) * 0.14
				var marker_radius: float = 30.0 * marker_pulse
				var marker_color: Color = Color(0.48, 0.96, 1.0, alpha)
				_draw_pixel_ring(target_marker_position, marker_radius, marker_color, 5.0)
				_draw_pixel_ring(target_marker_position, marker_radius + 8.0, Color(0.78, 1.0, 1.0, alpha * 0.72), 3.0)
				for marker_index: int in 4:
					var marker_direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(marker_index) / 4.0)
					draw_line(
						target_marker_position + marker_direction * (marker_radius + 12.0),
						target_marker_position + marker_direction * (marker_radius + 25.0),
						Color(0.72, 1.0, 1.0, alpha),
						4.0,
					)
			&"assassination_mark":
				var mark_position: Vector2 = effect["position"]
				var mark_target: Node2D = effect.get("target") as Node2D
				if is_instance_valid(mark_target):
					mark_position = mark_target.global_position
				var pulse: float = 1.0 + sin(progress * TAU * 2.0) * 0.12
				var mark_radius: float = 34.0 * pulse
				var mark_color: Color = Color(0.82, 0.28, 1.0, alpha)
				_draw_pixel_ring(mark_position, mark_radius, mark_color, 6.0)
				_draw_pixel_ring(mark_position, mark_radius + 9.0, Color(1.0, 0.72, 0.94, alpha * 0.72), 3.0)
				for corner_index: int in 4:
					var corner_direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(corner_index) / 4.0)
					var corner_perpendicular: Vector2 = corner_direction.orthogonal()
					var corner_start: Vector2 = mark_position + corner_direction * (mark_radius + 15.0)
					draw_line(corner_start - corner_perpendicular * 9.0, corner_start, Color(1.0, 0.82, 0.98, alpha), 5.0)
					draw_line(corner_start, corner_start + corner_direction * 9.0, Color(1.0, 0.82, 0.98, alpha), 5.0)
				draw_line(mark_position - Vector2(13.0, 0.0), mark_position + Vector2(13.0, 0.0), Color(1.0, 0.92, 1.0, alpha), 3.0)
				draw_line(mark_position - Vector2(0.0, 13.0), mark_position + Vector2(0.0, 13.0), Color(1.0, 0.92, 1.0, alpha), 3.0)
			&"stealth_burst":
				_draw_pixel_ring(effect["position"], 22.0 + progress * 26.0, Color(0.42, 0.94, 1.0, alpha), 5.0)


func _draw_combat_feedback() -> void:
	for impact: Dictionary in _melee_impact_feedbacks:
		var impact_progress: float = float(impact["elapsed"]) / float(impact["duration"])
		var impact_position: Vector2 = impact["position"]
		var radius: float = float(impact["radius"]) * (0.35 + impact_progress * 0.7)
		var impact_alpha: float = 1.0 - impact_progress
		draw_rect(Rect2(impact_position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), Color(1.0, 0.24, 0.12, impact_alpha * 0.12))
		_draw_pixel_ring(impact_position, radius, Color(1.0, 0.62, 0.22, impact_alpha), 6.0)
		for ray_index: int in 8:
			var ray_direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(ray_index) / 8.0)
			draw_line(impact_position + ray_direction * radius * 0.55, impact_position + ray_direction * radius * 1.12, Color(1.0, 0.78, 0.3, impact_alpha), 3.0)
	for feedback: Dictionary in _damage_feedbacks:
		var feedback_progress: float = float(feedback["elapsed"]) / float(feedback["duration"])
		var feedback_alpha: float = 1.0 - feedback_progress
		var is_player: bool = bool(feedback["player"])
		var was_defeated: bool = bool(feedback["defeated"])
		var burst_position: Vector2 = Vector2(feedback["position"])
		var feedback_color: Color = Color(1.0, 0.22, 0.16, feedback_alpha) if is_player else Color(1.0, 0.78, 0.26, feedback_alpha)
		var burst_alpha: float = clampf(1.0 - feedback_progress * 1.15, 0.0, 1.0)
		var burst_radius: float = 12.0 + feedback_progress * (64.0 if was_defeated else 52.0)
		_draw_pixel_ring(burst_position, burst_radius, Color(1.0, 0.96, 0.76, burst_alpha), 6.0 if was_defeated else 5.0)
		draw_rect(Rect2(burst_position - Vector2.ONE * (8.0 + feedback_alpha * 4.0), Vector2.ONE * (16.0 + feedback_alpha * 8.0)), Color(1.0, 1.0, 0.92, burst_alpha * 0.78))
		for ray_index: int in 8:
			var ray_direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(ray_index) / 8.0)
			var ray_start: float = 20.0 + feedback_progress * 10.0
			var ray_end: float = 42.0 + feedback_progress * 48.0
			draw_line(burst_position + ray_direction * ray_start, burst_position + ray_direction * ray_end, feedback_color, 4.0 if is_player else 3.0)
		if is_player:
			_draw_pixel_ring(burst_position, 28.0 + feedback_progress * 20.0, Color(1.0, 0.28, 0.18, burst_alpha * 0.78), 3.0)

func _draw_ultimate_burst(position: Vector2, radius: float, elapsed: float) -> void:
	const WINDUP_DURATION: float = 0.2
	if elapsed < WINDUP_DURATION:
		var windup_progress: float = clampf(elapsed / WINDUP_DURATION, 0.0, 1.0)
		var pulse: float = 0.5 + sin(windup_progress * PI * 3.0) * 0.5
		var core_radius: float = lerpf(24.0, 48.0, windup_progress)
		draw_circle(position, core_radius * 1.8, Color(0.36, 0.08, 0.48, 0.10 + pulse * 0.08))
		_draw_pixel_ring(position, core_radius, Color(1.0, 0.64, 0.92, 0.72 + pulse * 0.2), 6.0)
		for ray_index: int in 8:
			var ray_direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(ray_index) / 8.0 + windup_progress * 0.45)
			draw_line(position + ray_direction * core_radius * 0.9, position + ray_direction * (core_radius * (1.25 + pulse * 0.34)), Color(0.92, 0.54, 1.0, 0.68), 4.0)
		return
	var impact_progress: float = clampf((elapsed - WINDUP_DURATION) / (ULTIMATE_VISUAL_DURATION - WINDUP_DURATION), 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - impact_progress, 3.0)
	var impact_alpha: float = 1.0 - impact_progress
	var outer_radius: float = lerpf(52.0, radius, eased)
	var inner_radius: float = lerpf(44.0, radius * 0.42, impact_progress)
	draw_circle(position, outer_radius * 0.72, Color(0.42, 0.08, 0.52, impact_alpha * 0.11))
	_draw_pixel_ring(position, outer_radius, Color(1.0, 0.52, 0.88, 0.96 * impact_alpha), 10.0)
	_draw_pixel_ring(position, inner_radius, Color(1.0, 0.9, 0.98, 0.78 * impact_alpha), 5.0)
	for ray_index: int in 12:
		var ray_direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(ray_index) / 12.0 + PI / 12.0)
		var ray_start: float = maxf(18.0, inner_radius * 0.55)
		var ray_end: float = outer_radius * (0.84 + 0.16 * impact_progress)
		draw_line(position + ray_direction * ray_start, position + ray_direction * ray_end, Color(1.0, 0.72, 0.94, impact_alpha * 0.66), 5.0)
	var core_size: float = 18.0 + impact_alpha * 10.0
	draw_rect(Rect2(position - Vector2.ONE * core_size, Vector2.ONE * core_size * 2.0), Color(1.0, 0.96, 1.0, impact_alpha * 0.82))
	draw_rect(Rect2(position - Vector2.ONE * core_size * 2.0, Vector2.ONE * core_size), Color(1.0, 0.66, 0.92, impact_alpha * 0.7))

func _draw_focus_wave(position: Vector2, direction: Vector2, focus_range: float, focus_arc_angle: float, progress: float) -> void:
	var start_angle: float = direction.angle() - focus_arc_angle * 0.5
	var points := PackedVector2Array([position])
	for index: int in 15:
		var point: Vector2 = position + Vector2.RIGHT.rotated(start_angle + focus_arc_angle * float(index) / 14.0) * focus_range
		points.append(point)
	points.append(position)
	var wave_alpha: float = 1.0 - progress * 0.82
	draw_colored_polygon(points, Color(1.0, 0.56, 0.12, wave_alpha * 0.24))
	var slash_angle: float = start_angle + focus_arc_angle * (0.18 + progress * 0.64)
	var slash_half_angle: float = maxf(0.12, focus_arc_angle * 0.18)
	var slash_radius: float = focus_range * (0.58 + progress * 0.42)
	var slash_start: float = slash_angle - slash_half_angle
	var slash_end: float = slash_angle + slash_half_angle
	draw_arc(position, slash_radius, slash_start, slash_end, 14, Color(1.0, 0.95, 0.66, wave_alpha), 10.0)
	draw_arc(position, slash_radius, slash_start, slash_end, 14, Color(1.0, 1.0, 0.94, wave_alpha), 4.0)
	var tip_direction: Vector2 = Vector2.RIGHT.rotated(slash_angle)
	var tip_position: Vector2 = position + tip_direction * slash_radius
	draw_rect(Rect2(tip_position - Vector2.ONE * 7.0, Vector2.ONE * 14.0), Color(1.0, 1.0, 0.9, wave_alpha))


func _draw_focus_wedge(position: Vector2, direction: Vector2, focus_range: float, focus_arc_angle: float, alpha: float) -> void:
	var points := PackedVector2Array([position])
	var outline := PackedVector2Array([position])
	var start_angle: float = direction.angle() - focus_arc_angle * 0.5
	for index: int in 13:
		var point: Vector2 = position + Vector2.RIGHT.rotated(start_angle + focus_arc_angle * float(index) / 12.0) * focus_range
		points.append(point)
		outline.append(point)
	outline.append(position)
	draw_colored_polygon(points, Color(1.0, 0.82, 0.28, alpha * 0.24))
	draw_polyline(outline, Color(1.0, 0.9, 0.42, alpha), 4.0 if alpha > 0.5 else 2.0)


func _draw_pixel_ring(position: Vector2, radius: float, color: Color, thickness: float) -> void:
	for index: int in PIXEL_SEGMENT_COUNT:
		var angle: float = TAU * float(index) / float(PIXEL_SEGMENT_COUNT)
		var segment_position: Vector2 = position + Vector2.RIGHT.rotated(angle) * radius
		draw_rect(Rect2(segment_position - Vector2.ONE * thickness * 0.5, Vector2.ONE * thickness), color)


func _draw_pixel_ring_arc(position: Vector2, radius: float, progress: float, color: Color, thickness: float) -> void:
	var segment_count: int = maxi(1, ceili(PIXEL_SEGMENT_COUNT * progress))
	for index: int in segment_count:
		var angle: float = -PI * 0.5 + TAU * float(index) / float(PIXEL_SEGMENT_COUNT)
		var segment_position: Vector2 = position + Vector2.RIGHT.rotated(angle) * radius
		draw_rect(Rect2(segment_position - Vector2.ONE * thickness * 0.5, Vector2.ONE * thickness), color)


func _spawn_warning_duration(enemy_type: int) -> float:
	match enemy_type:
		DontDodgeEnemy.EnemyType.MELEE:
			return DontDodgeTuning.SPAWN_WARNING_MELEE
		DontDodgeEnemy.EnemyType.RANGED:
			return DontDodgeTuning.SPAWN_WARNING_RANGED
		DontDodgeEnemy.EnemyType.CHARGER:
			return DontDodgeTuning.SPAWN_WARNING_CHARGER
		DontDodgeEnemy.EnemyType.VOLLEY:
			return DontDodgeTuning.SPAWN_WARNING_VOLLEY
		_:
			return DontDodgeTuning.SPAWN_WARNING_ELITE
