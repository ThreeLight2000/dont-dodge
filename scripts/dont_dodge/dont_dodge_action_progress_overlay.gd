class_name DontDodgeActionProgressOverlay
extends Control

const ARC_POINT_COUNT: int = 36

var _accent_color: Color = Color.WHITE
var _cooldown_ratio: float = 0.0
var _charge_ratio: float = 0.0
var _show_charge_ring: bool = false
var _ready_stacks: int = 0
var _max_stacks: int = 0
var _recovery_progresses: Array[float] = []


func configure(accent_color: Color) -> void:
	if _accent_color == accent_color:
		return
	_accent_color = accent_color
	queue_redraw()


func set_cooldown_ratio(ratio: float) -> void:
	var next_ratio: float = clampf(ratio, 0.0, 1.0)
	if is_equal_approx(_cooldown_ratio, next_ratio):
		return
	_cooldown_ratio = next_ratio
	queue_redraw()


func set_charge_ring(ratio: float, is_visible: bool) -> void:
	var next_ratio: float = clampf(ratio, 0.0, 1.0)
	if is_equal_approx(_charge_ratio, next_ratio) and _show_charge_ring == is_visible:
		return
	_charge_ratio = next_ratio
	_show_charge_ring = is_visible
	queue_redraw()


func set_stack_state(ready_stacks: int, max_stacks: int, recovery_progresses: Array[float]) -> void:
	var next_max_stacks: int = maxi(0, max_stacks)
	var next_ready_stacks: int = clampi(ready_stacks, 0, next_max_stacks)
	if _ready_stacks == next_ready_stacks and _max_stacks == next_max_stacks and _recovery_progresses == recovery_progresses:
		return
	_ready_stacks = next_ready_stacks
	_max_stacks = next_max_stacks
	_recovery_progresses = recovery_progresses
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - 4.0
	_draw_charge_ring(center, radius)
	_draw_cooldown_sector(center, radius)
	_draw_stack_pips()


func _draw_charge_ring(center: Vector2, radius: float) -> void:
	if not _show_charge_ring:
		return
	draw_arc(center, radius, -PI * 0.5, TAU - PI * 0.5, ARC_POINT_COUNT, Color(_accent_color, 0.22), 3.0, true)
	if _charge_ratio > 0.0:
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * _charge_ratio, ARC_POINT_COUNT, Color(_accent_color, 0.96), 3.0, true)


func _draw_cooldown_sector(center: Vector2, radius: float) -> void:
	if _cooldown_ratio <= 0.0:
		return
	if _cooldown_ratio >= 0.999:
		draw_circle(center, radius + 3.0, Color(0.01, 0.02, 0.05, 0.7))
		draw_arc(center, radius, -PI * 0.5, TAU - PI * 0.5, ARC_POINT_COUNT, Color(_accent_color, 0.7), 2.0, true)
		return
	var points := PackedVector2Array([center])
	for point_index: int in ARC_POINT_COUNT + 1:
		var angle: float = -PI * 0.5 + TAU * _cooldown_ratio * float(point_index) / float(ARC_POINT_COUNT)
		points.append(center + Vector2.RIGHT.rotated(angle) * (radius + 3.0))
	draw_colored_polygon(points, Color(0.01, 0.02, 0.05, 0.7))
	draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * _cooldown_ratio, ARC_POINT_COUNT, Color(_accent_color, 0.7), 2.0, true)


func _draw_stack_pips() -> void:
	if _max_stacks <= 0:
		return
	var pip_gap: float = 14.0
	var first_x: float = size.x * 0.5 - pip_gap * float(_max_stacks - 1) * 0.5
	for stack_index: int in _max_stacks:
		var pip_center := Vector2(first_x + pip_gap * stack_index, size.y - 9.0)
		var progress: float = 1.0 if stack_index < _ready_stacks else _get_recovery_progress(stack_index - _ready_stacks)
		draw_circle(pip_center, 4.5, Color(0.015, 0.03, 0.08, 0.96))
		if progress >= 1.0:
			draw_circle(pip_center, 3.0, Color(_accent_color, 0.98))
		elif progress > 0.0:
			draw_arc(pip_center, 3.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 12, Color(_accent_color, 0.92), 2.0, true)
		draw_arc(pip_center, 4.5, 0.0, TAU, 12, Color(_accent_color, 0.82), 1.0, true)


func _get_recovery_progress(index: int) -> float:
	if index < 0 or index >= _recovery_progresses.size():
		return 0.0
	return clampf(_recovery_progresses[index], 0.0, 1.0)
