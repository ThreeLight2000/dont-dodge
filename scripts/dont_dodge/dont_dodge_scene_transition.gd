class_name DontDodgeSceneTransition
extends CanvasLayer

signal transition_started
signal transition_finished(succeeded: bool)

const FADE_OUT_SECONDS: float = 0.1
const FADE_IN_SECONDS: float = 0.1

var _overlay: ColorRect
var _transitioning: bool = false
var _active_tween: Tween


func _ready() -> void:
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = ColorRect.new()
	_overlay.name = "SceneTransitionOverlay"
	_overlay.color = Color.BLACK
	_overlay.modulate.a = 0.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)


func _input(_event: InputEvent) -> void:
	if not _transitioning:
		return
	get_viewport().set_input_as_handled()


func is_transitioning() -> bool:
	return _transitioning


func transition_to_scene(scene_path: String) -> void:
	if _transitioning or scene_path.is_empty():
		return
	_begin_transition(scene_path, false)


func reload_current_scene() -> void:
	if _transitioning:
		return
	_begin_transition("", true)


func _begin_transition(scene_path: String, reload_current: bool) -> void:
	_transitioning = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_started.emit()
	call_deferred("_run_transition", scene_path, reload_current)


func _run_transition(scene_path: String, reload_current: bool) -> void:
	await _fade_overlay(1.0, FADE_OUT_SECONDS)
	var result: int = ERR_UNAVAILABLE
	if reload_current:
		result = get_tree().reload_current_scene()
	else:
		result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		await _fade_overlay(0.0, FADE_IN_SECONDS)
		_finish_transition(false)
		return
	await get_tree().scene_changed
	await _fade_overlay(0.0, FADE_IN_SECONDS)
	_finish_transition(true)


func _fade_overlay(target_alpha: float, duration: float) -> void:
	if not is_instance_valid(_overlay):
		return
	if is_instance_valid(_active_tween):
		_active_tween.kill()
	if is_zero_approx(duration):
		_overlay.modulate.a = target_alpha
		return
	_active_tween = create_tween()
	_active_tween.tween_property(_overlay, "modulate:a", target_alpha, duration)
	await _active_tween.finished


func _finish_transition(succeeded: bool) -> void:
	_transitioning = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_finished.emit(succeeded)
