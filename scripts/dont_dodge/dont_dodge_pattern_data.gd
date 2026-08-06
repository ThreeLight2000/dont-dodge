class_name DontDodgePatternData
extends RefCounted

# Runtime data intentionally stays compact.  Explanatory reference solutions live in
# validation metadata so they do not affect the combat runner.

func build_timeline() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	_add_slot(slots, "cut_tell_01", 1, 0.0, 5.0)
	_add_slot(slots, "cut_charge_01", 1, 5.0, 5.0)
	_add_slot(slots, "cut_tell_01", 1, 10.0, 5.0, "mirror")
	_add_slot(slots, "cut_charge_01", 1, 15.0, 5.0, "mirror")
	_add_slot(slots, "cut_tell_01", 1, 20.0, 5.0, "rotate")

	_add_slot(slots, "dash_the_line_01", 2, 25.0, 4.0)
	_add_slot(slots, "erase_fan_01", 2, 29.0, 5.0)
	_add_slot(slots, "erase_pair_02", 2, 34.0, 5.5)
	_add_slot(slots, "dash_the_line_01", 2, 39.5, 4.0, "mirror")
	_add_recovery_slot(slots, 2, 43.5, 1.5)

	_add_slot(slots, "cross_pressure_01", 3, 45.0, 5.0)
	_add_slot(slots, "cross_pressure_02", 3, 50.0, 5.0)
	_add_slot(slots, "hold_the_gap_01", 3, 55.0, 4.0)
	_add_recovery_slot(slots, 3, 59.0, 1.0)
	_add_slot(slots, "cross_pressure_01", 3, 60.0, 5.0, "mirror")
	_add_slot(slots, "cross_pressure_02", 3, 65.0, 5.0, "mirror")

	_add_slot(slots, "ready_or_hold_01", 4, 70.0, 5.0)
	_add_slot(slots, "hold_the_gap_01", 4, 75.0, 4.2, "advanced", false, "hold_the_gap_advanced")
	_add_slot(slots, "final_relay_01", 4, 79.2, 5.25)
	_add_slot(slots, "final_relay_01", 4, 84.45, 5.55, "mirror", true)
	return slots


func get_pattern(pattern_id: String) -> Dictionary:
	match pattern_id:
		"cut_tell_01":
			return _pattern(pattern_id, 3, [
				_e(0.0, "melee", "S:F", 190.0, "primary"),
				_e(1.55, "melee", "P:L", 190.0, "primary"),
				_e(3.10, "melee", "P:R", 190.0, "primary"),
			])
		"cut_charge_01":
			return _pattern(pattern_id, 3, [
				_e(0.0, "charger", "S:F", 220.0, "primary"),
				_e(1.10, "charger", "P:L", 230.0, "primary"),
				_e(2.60, "charger", "P:R", 230.0, "primary"),
			])
		"dash_the_line_01":
			return _pattern(pattern_id, 4, [
				_e(0.0, "charger", "S:F", 220.0, "primary"),
				_e(0.80, "charger", "S:B", 230.0, "primary"),
				_e(2.40, "melee", "P:L", 190.0, "secondary"),
				_e(3.70, "melee", "P:R", 190.0, "secondary"),
			])
		"erase_fan_01":
			return _pattern(pattern_id, 4, [
				_e(0.0, "volley", "S:F", 380.0, "primary"),
				_e(0.30, "ranged", "S:L", 300.0, "primary"),
				_e(0.45, "ranged", "S:R", 300.0, "secondary"),
				_e(2.20, "ranged", "P:B", 300.0, "secondary"),
			], {}, _carry_one_secondary())
		"erase_pair_02":
			return _pattern(pattern_id, 3, [
				_e(0.0, "volley", "S:L", 380.0, "primary"),
				_e(0.20, "volley", "S:R", 380.0, "secondary"),
				_e(2.50, "ranged", "P:F", 300.0, "secondary"),
			], {}, _carry_one_secondary())
		"cross_pressure_01":
			return _pattern(pattern_id, 5, [
				_e(0.0, "charger", "S:F", 220.0, "primary"),
				_e(0.35, "ranged", "S:L", 300.0, "primary"),
				_e(0.50, "ranged", "S:R", 300.0, "secondary"),
				_e(1.40, "melee", "P:L", 190.0, "secondary"),
				_e(1.55, "melee", "P:R", 190.0, "secondary"),
			], {}, _carry_one_secondary())
		"cross_pressure_02":
			return _pattern(pattern_id, 5, [
				_e(0.0, "charger", "S:F", 220.0, "primary"),
				_e(0.25, "ranged", "S:L", 300.0, "primary"),
				_e(0.45, "volley", "S:R", 380.0, "secondary"),
				_e(1.20, "melee", "P:B", 190.0, "secondary"),
				_e(1.35, "melee", "P:F", 190.0, "secondary"),
			], {}, _carry_one_secondary())
		"hold_the_gap_01":
			return _pattern(pattern_id, 8, [
				_e(0.0, "elite", "S:F", 205.0, "anchor"),
				_e(0.0, "charger", "S:L", 220.0, "primary"),
				_e(0.20, "charger", "S:R", 220.0, "primary"),
				_e(0.55, "volley", "S:B", 380.0, "secondary"),
				_e(0.80, "melee", "P:L", 190.0, "secondary"),
				_e(0.95, "melee", "P:R", 190.0, "secondary"),
				_e(1.10, "melee", "P:F", 190.0, "secondary"),
				_e(1.25, "melee", "P:B", 190.0, "secondary"),
			], {}, _carry_one_secondary())
		"ready_or_hold_01":
			return _pattern(pattern_id, 6, [
				_e(0.0, "elite", "S:F", 205.0, "anchor"),
				_e(0.0, "charger", "S:L", 220.0, "primary"),
				_e(0.20, "charger", "S:R", 220.0, "primary"),
				_e(0.55, "ranged", "S:B", 300.0, "secondary"),
				_e(0.70, "ranged", "P:F", 300.0, "primary"),
				_e(1.15, "melee", "P:L", 190.0, "secondary"),
			], {}, _carry_one_secondary())
		"hold_the_gap_advanced":
			return _pattern(pattern_id, 6, [
				_e(0.0, "elite", "S:F", 205.0, "anchor"),
				_e(0.0, "volley", "S:B", 380.0, "secondary"),
				_e(0.20, "charger", "S:L", 220.0, "primary"),
				_e(0.35, "charger", "S:R", 220.0, "primary"),
				_e(0.80, "melee", "P:L", 190.0, "secondary"),
				_e(0.95, "melee", "P:R", 190.0, "secondary"),
			], {}, _carry_one_secondary())
		"final_relay_01":
			return _pattern(pattern_id, 6, [
				_e(0.00, "elite", "S:F", 205.0, "anchor"),
				_e(0.00, "charger", "S:L", 220.0, "primary"),
				_e(0.00, "charger", "S:R", 220.0, "primary"),
				_e(2.30, "volley", "P:B", 380.0, "secondary"),
				_e(2.35, "melee", "P:R", 190.0, "primary"),
				_e(2.95, "ranged", "P:F", 300.0, "primary"),
			], {"reference_solution_id": "r_w_q_e", "reference_e_window": Vector2(4.776, 5.224), "minimum_verified_window": 0.30}, _carry_one_secondary())
	return {}


func _add_slot(slots: Array[Dictionary], pattern_id: String, wave_id: int, start_time: float, slot_duration: float, variant: String = "", terminal: bool = false, data_id: String = "") -> void:
	var pattern: Dictionary = get_pattern(data_id if not data_id.is_empty() else pattern_id)
	slots.append({
		"kind": "pattern",
		"id": pattern_id,
		"wave_id": wave_id,
		"start_time": start_time,
		"minimum_resolution_time": maxf(2.5, slot_duration - 1.25),
		"allow_early_advance": wave_id >= 2,
		"slot_duration": slot_duration,
		"gate_wall_timeout": 8.0,
		"variant": variant,
		"terminal": terminal,
		"events": pattern["events"].duplicate(true),
		"advance": pattern["advance"].duplicate(true),
		"validation": pattern.get("validation", {}).duplicate(true),
	})


func _add_recovery_slot(slots: Array[Dictionary], wave_id: int, start_time: float, slot_duration: float) -> void:
	slots.append({"kind": "recovery", "id": "recovery", "wave_id": wave_id, "start_time": start_time, "slot_duration": slot_duration, "minimum_resolution_time": 0.0, "gate_wall_timeout": 0.0, "events": [], "advance": {"max_alive_enemies": 999, "max_projectiles": 999, "carry_over_policy": "recovery"}, "validation": {}})


func _pattern(pattern_id: String, enemy_count: int, events: Array[Dictionary], validation: Dictionary = {}, advance: Dictionary = {}) -> Dictionary:
	return {
		"id": pattern_id,
		"enemy_count": enemy_count,
		"events": events,
		"advance": advance if not advance.is_empty() else {"required_roles_cleared": ["primary", "anchor"], "max_alive_enemies": 0, "max_active_tells": 0, "max_projectiles": 0, "max_total_enemies": 0, "carry_over_policy": "none"},
		"validation": validation,
	}


func _carry_one_secondary() -> Dictionary:
	return {"required_roles_cleared": ["primary", "anchor"], "max_alive_enemies": 1, "max_active_tells": 0, "max_projectiles": 0, "max_total_enemies": 2, "carry_over_policy": "secondary"}


func _e(time: float, enemy_type: String, position_rule: String, distance: float, role: String) -> Dictionary:
	return {"time": time, "enemy_type": enemy_type, "position_rule": position_rule, "distance": distance, "role": role}
