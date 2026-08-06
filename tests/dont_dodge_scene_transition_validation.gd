extends SceneTree

const MAIN_SCENE_PATH: String = "res://scenes/dont_dodge/dont_dodge.tscn"
const TRAINING_SCENE_PATH: String = "res://scenes/dont_dodge/training_arena.tscn"

var _transition: DontDodgeSceneTransition


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_transition = get_root().get_node("SceneTransition") as DontDodgeSceneTransition
	assert(is_instance_valid(_transition), "SceneTransition autoload missing")
	assert(not _transition.is_transitioning(), "SceneTransition started locked")
	assert(not paused, "SceneTree was paused before scene transition validation")

	await _load_scene(MAIN_SCENE_PATH)
	var title_game := current_scene as DontDodgeGame
	assert(is_instance_valid(title_game), "title scene did not load")
	assert(title_game.get_node_or_null("TitleLayer") != null)

	# Title -> guide -> combat.
	title_game.call("_show_title_guide", &"normal", true)
	await process_frame
	assert(title_game.get_node_or_null("TitleLayer/GuidePanel") != null)
	title_game.call("_finish_guide")
	assert(title_game.get_node_or_null("CombatVisuals") != null)

	# Combat -> pause -> resume, with no stale UI action request.
	title_game.call("_open_manual_pause")
	assert(title_game.get_game_state() == DontDodgeGame.GameState.MANUAL_PAUSE)
	title_game.call("_resume_manual_pause")
	assert(title_game.get_game_state() == DontDodgeGame.GameState.COMBAT)
	var input_source: DontDodgeInputSource = title_game.get("_input_source")
	input_source.request_ui_attack()
	title_game.call("_return_to_title")
	assert(_transition.is_transitioning(), "return-to-title did not lock transition")
	assert(not paused, "scene transition paused SceneTree")
	assert(not input_source.read_command().attack_pressed, "stale UI action survived transition preparation")
	title_game.call("_return_to_title")
	await _wait_for_scene(MAIN_SCENE_PATH)
	assert(current_scene.get_node_or_null("TitleLayer") != null)
	assert(current_scene.get_node_or_null("CombatVisuals") == null)

	# Title -> training -> combat -> title.
	var title_again := current_scene as DontDodgeGame
	var training_button := title_again.get_node("TitleLayer/LobbyRoot/SafeArea/Center/TitleScroller/PixelTitlePanel/PanelPadding/TitleLayoutSwitcher/WideLayout/RightColumn/ModeRow/TrainingButton") as Button
	training_button.emit_signal("pressed")
	assert(_transition.is_transitioning(), "training entry did not start transition")
	training_button.emit_signal("pressed")
	await _wait_for_scene(TRAINING_SCENE_PATH)
	var training_game := current_scene as DontDodgeGame
	assert(str(training_game.launch_mode) == "training")
	training_game.call("_start_training_from_setup")
	assert(str(training_game.get("_mode")) == "training")
	training_game.call("_return_to_title")
	await _wait_for_scene(MAIN_SCENE_PATH)
	assert(current_scene.get_node_or_null("TitleLayer") != null)

	# Normal restart preserves a normal run and cannot be triggered twice.
	var normal_game := current_scene as DontDodgeGame
	normal_game.call("_start_game", &"normal")
	normal_game.call("_open_manual_pause")
	normal_game.call("_restart")
	assert(_transition.is_transitioning(), "normal restart did not start transition")
	normal_game.call("_restart")
	await _wait_for_scene(MAIN_SCENE_PATH)
	var restarted_normal := current_scene as DontDodgeGame
	await _wait_for_game_start(restarted_normal)
	assert(str(restarted_normal.get("_mode")) == "normal")
	assert(not bool(restarted_normal.get("_start_game_after_reload")))

	# Challenge restart preserves challenge mode.
	restarted_normal.call("_return_to_title")
	await _wait_for_scene(MAIN_SCENE_PATH)
	var challenge_title := current_scene as DontDodgeGame
	challenge_title.call("_start_game", &"challenge")
	challenge_title.call("_restart")
	await _wait_for_scene(MAIN_SCENE_PATH)
	var restarted_challenge := current_scene as DontDodgeGame
	await _wait_for_game_start(restarted_challenge)
	assert(str(restarted_challenge.get("_mode")) == "challenge")
	assert(restarted_challenge.get_game_state() == DontDodgeGame.GameState.CHALLENGE_REVEAL)

	# Result -> restart and result -> title.
	restarted_challenge.call("_finish_run", &"result.death", [], "death")
	var restart_button := (restarted_challenge.get("_end_panel") as PanelContainer).get_node("ResultMargin/ResultScroll/Contents/RestartButton") as Button
	restart_button.emit_signal("pressed")
	await _wait_for_scene(MAIN_SCENE_PATH)
	var restarted_from_result := current_scene as DontDodgeGame
	await _wait_for_game_start(restarted_from_result)
	assert(str(restarted_from_result.get("_mode")) == "challenge")
	restarted_from_result.call("_finish_run", &"result.clear", [4], "clear")
	var title_button := (restarted_from_result.get("_end_panel") as PanelContainer).get_node("ResultMargin/ResultScroll/Contents/ReturnToTitleButton") as Button
	title_button.emit_signal("pressed")
	await _wait_for_scene(MAIN_SCENE_PATH)
	assert(current_scene.get_node_or_null("TitleLayer") != null)
	assert(current_scene.get_node_or_null("CombatVisuals") == null)

	print("DON'T DODGE scene transition validation passed.")
	quit()


func _load_scene(scene_path: String) -> void:
	var result: int = change_scene_to_file(scene_path)
	assert(result == OK, "could not load scene: %s" % scene_path)
	await scene_changed
	await _wait_for_transition()


func _wait_for_scene(scene_path: String) -> void:
	await scene_changed
	assert(current_scene.scene_file_path == scene_path, "unexpected scene: %s" % current_scene.scene_file_path)
	await _wait_for_transition()


func _wait_for_transition() -> void:
	for _frame: int in 12:
		await process_frame
	assert(not _transition.is_transitioning(), "scene transition did not unlock")


func _wait_for_game_start(game: DontDodgeGame) -> void:
	for _frame: int in 12:
		await process_frame
	assert(bool(game.get("_started")), "reloaded game did not start")
