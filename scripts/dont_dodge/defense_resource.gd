class_name DefenseResource
extends RefCounted

var _recovery_remaining: Array[float] = []
var _recovery_seconds: float = DontDodgeTuning.DEFENSE_RECOVERY_SECONDS
var _max_charges: int = DontDodgeTuning.DEFENSE_MAX_CHARGES


func _init(recovery_seconds: float = DontDodgeTuning.DEFENSE_RECOVERY_SECONDS, max_charges: int = DontDodgeTuning.DEFENSE_MAX_CHARGES) -> void:
	_recovery_seconds = maxf(0.1, recovery_seconds)
	_max_charges = maxi(1, max_charges)


func consume(cost: int = 1) -> bool:
	if cost <= 0:
		return true
	if get_charges() < cost:
		return false
	for _charge_index: int in cost:
		_recovery_remaining.append(_recovery_seconds)
	return true


func update(delta: float) -> int:
	var recovered: int = 0
	var pending: Array[float] = []
	for remaining: float in _recovery_remaining:
		var next_remaining: float = remaining - delta
		if next_remaining <= 0.0:
			recovered += 1
		else:
			pending.append(next_remaining)
	_recovery_remaining = pending
	return recovered


func get_charges() -> int:
	return _max_charges - _recovery_remaining.size()


func get_max_charges() -> int:
	return _max_charges


func set_max_charges(max_charges: int, refill: bool = false) -> void:
	_max_charges = maxi(1, max_charges)
	if refill:
		_recovery_remaining.clear()


func get_recovery_progresses() -> Array[float]:
	var progresses: Array[float] = []
	for remaining: float in _recovery_remaining:
		progresses.append(clampf(1.0 - remaining / _recovery_seconds, 0.0, 1.0))
	return progresses


func get_recovery_seconds() -> float:
	return _recovery_seconds


func reset() -> void:
	_recovery_remaining.clear()
