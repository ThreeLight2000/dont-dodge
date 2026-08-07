extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/dont_dodge/dont_dodge.tscn")
const PATTERN_DATA_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_pattern_data.gd")
const ASSET_CATALOG_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_asset_catalog.gd")
const SFX_CONTROLLER_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_sfx_controller.gd")
const CHALLENGE_DATA_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_challenge_data.gd")
const LOADOUT_DATA_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_loadout_data.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var localization: Node = get_root().get_node("Localization")
	localization.call("set_locale", &"ko", false)
	_validate_localization_catalog()
	_validate_pattern_timeline()
	_validate_asset_catalog_and_sfx()
	var title_game: DontDodgeGame = await _new_game(false, false)
	await _validate_title_and_bgm_controls(title_game)
	await _dispose_game(title_game)
	localization.call("set_locale", &"ko", false)
	var action_game: DontDodgeGame = await _new_game()
	await _validate_action_bar_controls(action_game)
	await _dispose_game(action_game)
	await _validate_responsive_ui_layouts()
	var completed_title_game: DontDodgeGame = await _new_game(false, false)
	_validate_completed_guide_skips(completed_title_game)
	await _dispose_game(completed_title_game)
	var onboarding_game: DontDodgeGame = await _new_game(false, false)
	await _validate_first_combat_onboarding(onboarding_game)
	await _dispose_game(onboarding_game)
	var challenge_game: DontDodgeGame = await _new_game(false, false)
	_validate_challenge_mode(challenge_game)
	await _dispose_game(challenge_game)
	var training_game: DontDodgeGame = await _new_game(false, false)
	_validate_training_mode_has_no_combat_hints(training_game)
	await _dispose_game(training_game)
	var game: DontDodgeGame = await _new_game(false)
	_validate_warning_to_materialization(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_visual_fallback_and_gameplay_isolation(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_screen_feedback(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_ui_input_and_terminal_reset(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_compact_survival_hud(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_spawn_lock_and_action_immunity(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_early_pressure_transition(game)
	await _dispose_game(game)
	game = await _new_game(false)
	_validate_late_pattern_event_does_not_gate(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_experience_upgrade_and_wave_flow(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_loadout_rules_and_attack_profile(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_dagger_techniques(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_dagger_ultimates(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_guardian_mace_defense_and_techniques(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_battle_spear_rules_and_techniques(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_reworked_weapon_ultimates(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_spear_formation_auto_aim(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_perfect_dodge_timing(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_gate_freezes_active_time(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_cleanup_and_death(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_rewards_and_hearts(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_empty_negate_preserves_resource(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_pause_timer_policy(game)
	await _dispose_game(game)
	game = await _new_game()
	_validate_ultimate_radius_and_final_margin(game)
	await _dispose_game(game)
	await _dispose_bgm_controller()
	await _dispose_sfx_controller()
	print("DON'T DODGE pattern validation passed.")
	quit()


func _new_game(clear_schedule: bool = true, start_game: bool = true) -> DontDodgeGame:
	var game: DontDodgeGame = GAME_SCENE.instantiate()
	get_root().add_child(game)
	await process_frame
	assert(game.get_node_or_null("TitleLayer") != null)
	assert(game.get_node_or_null("TitleLayer/LobbyRoot/SafeArea/Center/TitleScroller/PixelTitlePanel") != null)
	assert(game.get_node_or_null("TitleLayer/LobbyRoot/SafeArea/Center/TitleScroller/PixelTitlePanel/PanelPadding/TitleLayoutSwitcher") != null)
	assert(game.get_node("TitleLayer/LobbyRoot/SafeArea/Center/TitleScroller/PixelTitlePanel/PanelPadding/TitleLayoutSwitcher/WideLayout/RightColumn/StartButton").text == "게임 시작")
	assert(game.get_node("TitleLayer/LobbyRoot/SafeArea/Center/TitleScroller/PixelTitlePanel/PanelPadding/TitleLayoutSwitcher/WideLayout/RightColumn/ModeRow/ChallengeButton").text == "도전 모드")
	assert(game.get_node_or_null("CombatVisuals") == null)
	assert(not game.get_node("Player").visible)
	if start_game:
		game.call("_start_game")
	if start_game and clear_schedule:
		var spawn_schedule: Array[Dictionary] = game.get("_spawn_schedule")
		spawn_schedule.clear()
		game.set("_next_spawn_index", 0)
		var warnings: Array[Dictionary] = game.get("_spawn_warnings")
		warnings.clear()
	return game


func _validate_localization_catalog() -> void:
	var localization: Node = get_root().get_node("Localization")
	var catalog_errors: PackedStringArray = localization.call("validate_catalog", localization.call("get_catalog_keys"))
	assert(catalog_errors.is_empty(), "Localization catalog errors: %s" % ", ".join(catalog_errors))
	var data_keys: Array[StringName] = []
	_collect_data_translation_keys(LOADOUT_DATA_SCRIPT.WEAPONS, data_keys)
	_collect_data_translation_keys(CHALLENGE_DATA_SCRIPT.DEBUFFS, data_keys)
	for key: StringName in data_keys:
		assert(bool(localization.call("has_key", key, &"ko")))
		assert(bool(localization.call("has_key", key, &"en")))


func _collect_data_translation_keys(value: Variant, keys: Array[StringName]) -> void:
	if value is Dictionary:
		for key: Variant in value.keys():
			if str(key).ends_with("_key"):
				var translation_key := StringName(str(value[key]))
				if not keys.has(translation_key):
					keys.append(translation_key)
			_collect_data_translation_keys(value[key], keys)
	elif value is Array:
		for item: Variant in value:
			_collect_data_translation_keys(item, keys)


func _dispose_game(game: DontDodgeGame) -> void:
	game.queue_free()
	await process_frame


func _dispose_bgm_controller() -> void:
	var bgm_controller: Node = get_root().get_node_or_null("BgmController")
	if is_instance_valid(bgm_controller):
		bgm_controller.call("shutdown")
		await process_frame
		bgm_controller.free()
		await process_frame


func _dispose_sfx_controller() -> void:
	var sfx_controller: Node = get_root().get_node_or_null("SfxController")
	if is_instance_valid(sfx_controller):
		sfx_controller.free()
		await process_frame


func _validate_title_and_bgm_controls(game: DontDodgeGame) -> void:
	var localization: Node = get_root().get_node("Localization")
	await _assert_title_layout_bounds(game, Vector2i(1600, 900))
	await _assert_title_layout_bounds(game, Vector2i(1366, 768))
	await _assert_title_layout_bounds(game, Vector2i(1280, 720))
	var bgm_controller: Node = get_root().get_node("BgmController")
	var sfx_controller: Node = get_root().get_node("SfxController")
	var initially_enabled: bool = bool(bgm_controller.call("is_enabled"))
	var initially_sfx_enabled: bool = bool(sfx_controller.call("is_enabled"))
	var lobby_root: Control = game.get_node("TitleLayer/LobbyRoot") as Control
	if is_instance_valid(lobby_root):
		lobby_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		game.call("_on_title_viewport_size_changed")
		await process_frame
	var title_button_root: String = "TitleLayer/LobbyRoot/SafeArea/Center/TitleScroller/PixelTitlePanel/PanelPadding/TitleLayoutSwitcher/WideLayout/RightColumn"
	var title_bgm_button: Button = game.get_node(title_button_root + "/AudioRow/BgmToggleButton") as Button
	var title_sfx_button: Button = game.get_node(title_button_root + "/AudioRow/SfxToggleButton") as Button
	var title_guide_button: Button = game.get_node(title_button_root + "/GuideButton") as Button
	var title_language_option: OptionButton = game.get_node(title_button_root + "/LanguageRow/LanguageOption") as OptionButton
	assert(title_language_option.get_selected_metadata() == "ko")
	assert(title_bgm_button.text == ("BGM: 켜짐" if initially_enabled else "BGM: 꺼짐"))
	assert(title_sfx_button.text == ("효과음: 켜짐" if initially_sfx_enabled else "효과음: 꺼짐"))
	assert(title_guide_button.text == "전투 가이드")
	title_language_option.emit_signal("item_selected", 1)
	await process_frame
	assert(localization.call("current_locale") == &"en")
	assert(game.get_node(title_button_root + "/StartButton").text == "Start Game")
	_assert_no_hangul_in_ui(game.get_node("TitleLayer"))
	await _assert_title_layout_bounds(game, Vector2i(1600, 900))
	await _assert_title_layout_bounds(game, Vector2i(1366, 768))
	await _assert_title_layout_bounds(game, Vector2i(1280, 720))
	var locale_settings := ConfigFile.new()
	assert(locale_settings.load("user://dont_dodge_settings.cfg") == OK)
	assert(str(locale_settings.get_value("localization", "locale")) == "en")
	localization.call("set_locale", &"ko")
	await process_frame
	assert(title_language_option.get_selected_metadata() == "ko")
	title_bgm_button.emit_signal("pressed")
	assert(bool(bgm_controller.call("is_enabled")) == not initially_enabled)
	assert(title_bgm_button.text == ("BGM: 켜짐" if not initially_enabled else "BGM: 꺼짐"))
	var settings := ConfigFile.new()
	assert(settings.load("user://dont_dodge_settings.cfg") == OK)
	assert(bool(settings.get_value("audio", "bgm_enabled")) == not initially_enabled)
	assert(bool(settings.get_value("audio", "sfx_enabled", initially_sfx_enabled)) == initially_sfx_enabled)
	title_sfx_button.emit_signal("pressed")
	assert(bool(sfx_controller.call("is_enabled")) == not initially_sfx_enabled)
	assert(title_sfx_button.text == ("효과음: 켜짐" if not initially_sfx_enabled else "효과음: 꺼짐"))
	title_sfx_button.emit_signal("pressed")
	assert(bool(sfx_controller.call("is_enabled")) == initially_sfx_enabled)
	assert(title_sfx_button.text == ("효과음: 켜짐" if initially_sfx_enabled else "효과음: 꺼짐"))
	settings = ConfigFile.new()
	assert(settings.load("user://dont_dodge_settings.cfg") == OK)
	assert(bool(settings.get_value("audio", "bgm_enabled")) == not initially_enabled)
	assert(bool(settings.get_value("audio", "sfx_enabled")) == initially_sfx_enabled)
	var tutorial_was_completed: bool = bool(settings.get_value("tutorial", "guide_completed", false))
	settings.set_value("tutorial", "guide_completed", false)
	assert(settings.save("user://dont_dodge_settings.cfg") == OK)
	var start_button: Button = game.get_node(title_button_root + "/StartButton") as Button
	start_button.emit_signal("pressed")
	assert(game.get_node_or_null("TitleLayer/GuidePanel") != null)
	assert(game.get_node_or_null("CombatVisuals") == null)
	var guide_start_button: Button = game.get_node("TitleLayer/GuidePanel/GuideMargin/GuideScroll/GuideContents/GuideStartButton") as Button
	assert(guide_start_button.text == "전투 시작")
	guide_start_button.emit_signal("pressed")
	assert(game.get_node_or_null("CombatVisuals") != null)
	settings = ConfigFile.new()
	assert(settings.load("user://dont_dodge_settings.cfg") == OK)
	assert(bool(settings.get_value("tutorial", "guide_completed", false)))
	settings.set_value("tutorial", "guide_completed", tutorial_was_completed)
	assert(settings.save("user://dont_dodge_settings.cfg") == OK)
	game.call("_start_game")
	var pause_bgm_button: Button = game.get("_pause_bgm_button") as Button
	var pause_sfx_button: Button = game.get("_pause_sfx_button") as Button
	var pause_guide_button: Button = game.get("_pause_guide_button") as Button
	var return_to_title_button: Button = game.get("_pause_main_button") as Button
	assert(is_instance_valid(pause_bgm_button))
	assert(is_instance_valid(pause_sfx_button))
	assert(is_instance_valid(pause_guide_button))
	assert(return_to_title_button.text == "메인으로")
	game.call("_open_manual_pause")
	var pause_language_option: OptionButton = game.get("_pause_language_option") as OptionButton
	pause_language_option.emit_signal("item_selected", 1)
	await process_frame
	assert((game.get("_pause_resume_button") as Button).text == "Resume")
	_assert_no_hangul_in_ui(game.get_node("CombatUILayer"))
	localization.call("set_locale", &"ko")
	await process_frame
	pause_guide_button.emit_signal("pressed")
	assert(game.get_node_or_null("CombatUILayer/GuidePanel") != null)
	game.call("_finish_guide")
	assert(game.get("_guide_panel") == null)
	pause_bgm_button.emit_signal("pressed")
	assert(bool(bgm_controller.call("is_enabled")) == initially_enabled)
	assert(pause_bgm_button.text == ("BGM: 켜짐" if initially_enabled else "BGM: 꺼짐"))
	bgm_controller.call("set_enabled_from_user_input", initially_enabled)
	sfx_controller.call("set_enabled_from_user_input", initially_sfx_enabled)
	if is_instance_valid(lobby_root):
		lobby_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		game.call("_on_title_viewport_size_changed")
		await process_frame


func _validate_action_bar_controls(game: DontDodgeGame) -> void:
	var localization: Node = get_root().get_node("Localization")
	var buttons: Array[Button] = [
		game.get("_attack_button"),
		game.get("_dodge_button"),
		game.get("_negate_button"),
		game.get("_ultimate_button"),
	]
	var shortcuts: Array[String] = ["Q", "W", "E", "R"]
	for index: int in buttons.size():
		var button := buttons[index]
		assert(is_instance_valid(button), "action button missing")
		assert(button.focus_mode == Control.FOCUS_ALL, "action button is not keyboard focusable")
		assert(button.get_theme_stylebox("focus") != null, "action button focus style missing")
		assert((button.get_node("KeyCap") as Label).text == shortcuts[index], "action shortcut mismatch")
		var name_label := button.get_node("ActionNameLabel") as Label
		assert(name_label.visible and not name_label.text.is_empty(), "action name is not always visible")
		assert(not name_label.clip_text, "action name clips text")
		var name_rect := name_label.get_global_rect()
		var button_rect := button.get_global_rect()
		assert(name_rect.position.x >= button_rect.position.x - 0.5)
		assert(name_rect.end.x <= button_rect.end.x + 0.5)
	_assert_focus_chain(buttons, "action bar")
	var dodge_status := (buttons[1].get_node("ActionLabel") as Label).text
	var negate_status := (buttons[2].get_node("ActionLabel") as Label).text
	assert(dodge_status.contains("2/2"), "dodge defense stack display missing")
	assert(negate_status.contains("2/2"), "negate defense stack display missing")
	assert(str(buttons[3].get_meta(&"action_visual_state", "")) == "locked", "ultimate lock state missing")

	var action_tooltip := game.get("_action_tooltip") as PanelContainer
	buttons[0].grab_focus()
	await process_frame
	assert(action_tooltip.visible, "action tooltip did not appear on focus")
	assert(game.get("_tooltip_source") == buttons[0], "focused action tooltip source mismatch")
	buttons[1].grab_focus()
	await process_frame
	assert(action_tooltip.visible, "action tooltip disappeared during focus navigation")
	assert(game.get("_tooltip_source") == buttons[1], "action tooltip did not follow focus")

	game.set("_attack_recovery_remaining", 0.5)
	game.call("_update_action_controls")
	assert(str(buttons[0].get_meta(&"action_visual_state", "")) == "cooldown", "attack cooldown state missing")
	assert((buttons[0].get_node("ActionLabel") as Label).text.contains("0.5"), "attack cooldown display missing")
	game.set("_attack_recovery_remaining", 0.0)
	var ultimate_options: Array[Dictionary] = LOADOUT_DATA_SCRIPT.get_ultimate_options("dagger")
	assert(not ultimate_options.is_empty(), "ultimate test data missing")
	game.set("_ultimate_id", str(ultimate_options[0].get("id", "")))
	game.set("_ultimate_charge", int(DontDodgeTuning.ULTIMATE_MAX / 2))
	game.call("_update_action_controls")
	assert((buttons[3].get_node("ActionLabel") as Label).text.contains("%"), "ultimate charge display missing")
	assert(str(buttons[3].get_meta(&"action_visual_state", "")) == "empty", "ultimate charge state missing")
	game.set("_ultimate_charge", DontDodgeTuning.ULTIMATE_MAX)
	game.call("_update_action_controls")
	assert((buttons[3].get_node("ActionLabel") as Label).text == "준비 완료", "ultimate ready display missing")
	assert(str(buttons[3].get_meta(&"action_visual_state", "")) == "ready", "ultimate ready state missing")

	localization.call("set_locale", &"en", false)
	await process_frame
	assert((buttons[0].get_node("ActionNameLabel") as Label).text == "Attack")
	assert((buttons[1].get_node("ActionNameLabel") as Label).text == "Dodge")
	assert((buttons[2].get_node("ActionNameLabel") as Label).text == "Nullify")
	assert((buttons[3].get_node("ActionNameLabel") as Label).text == "Ultimate")
	_assert_no_hangul_in_ui(buttons[0].get_parent())
	localization.call("set_locale", &"ko", false)
	await process_frame


func _assert_focus_chain(controls: Array, label: String) -> void:
	assert(not controls.is_empty(), "%s focus chain is empty" % label)
	for index: int in controls.size():
		var control := controls[index] as Control
		assert(is_instance_valid(control), "%s focus control missing" % label)
		assert(control.focus_mode == Control.FOCUS_ALL, "%s focus control is disabled" % label)
		assert(control.get_theme_stylebox("focus") != null, "%s focus outline missing" % label)
		var self_path := control.get_path_to(control)
		var expected_previous := self_path if index == 0 else control.get_path_to(controls[index - 1])
		var expected_next := self_path if index + 1 == controls.size() else control.get_path_to(controls[index + 1])
		assert(control.focus_previous == expected_previous, "%s previous order mismatch at %d" % [label, index])
		assert(control.focus_next == expected_next, "%s next order mismatch at %d" % [label, index])
func _assert_title_layout_bounds(game: DontDodgeGame, viewport_size: Vector2i) -> void:
	var lobby_root: Control = game.get_node("TitleLayer/LobbyRoot") as Control
	lobby_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	lobby_root.position = Vector2.ZERO
	lobby_root.size = Vector2(viewport_size)
	game.call("_set_title_layout_for_width", float(viewport_size.x))
	await process_frame
	var safe_right: float = float(viewport_size.x) - 24.0
	var safe_bottom: float = float(viewport_size.y) - 24.0
	var layout_root: String = "TitleLayer/LobbyRoot/SafeArea/Center/TitleScroller/PixelTitlePanel/PanelPadding/TitleLayoutSwitcher"
	var wide_layout: Control = game.get_node(layout_root + "/WideLayout") as Control
	var compact_layout: Control = game.get_node(layout_root + "/CompactLayout") as Control
	assert(wide_layout.visible == (viewport_size.x >= 1100))
	assert(compact_layout.visible == (viewport_size.x < 1100))
	var scroller: ScrollContainer = game.get_node("TitleLayer/LobbyRoot/SafeArea/Center/TitleScroller") as ScrollContainer
	assert(scroller.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	var title_panel: Control = game.get_node("TitleLayer/LobbyRoot/SafeArea/Center/TitleScroller/PixelTitlePanel") as Control
	var active_layout_name: String = "WideLayout" if viewport_size.x >= 1100 else "CompactLayout"
	var button_root: String = layout_root + "/" + active_layout_name + "/RightColumn"
	var title_controls: Array[Control] = [
		title_panel,
		game.get_node(button_root + "/StartButton") as Control,
		game.get_node(button_root + "/ModeRow/ChallengeButton") as Control,
		game.get_node(button_root + "/ModeRow/TrainingButton") as Control,
		game.get_node(button_root + "/GuideButton") as Control,
		game.get_node(button_root + "/AudioRow/BgmToggleButton") as Control,
		game.get_node(button_root + "/AudioRow/SfxToggleButton") as Control,
		game.get_node(button_root + "/LanguageRow/LanguageOption") as Control,
	]
	for title_control: Control in title_controls:
		var rect: Rect2 = title_control.get_global_rect()
		assert(rect.size.x > 0.0)
		assert(rect.size.y > 0.0)
		assert(rect.position.x >= 24.0)
		assert(rect.position.x + rect.size.x <= safe_right)
		if viewport_size.x >= 1100:
			assert(rect.position.y >= 24.0)
			assert(rect.position.y + rect.size.y <= safe_bottom)
	assert((title_controls[1] as Control).focus_next == (title_controls[1] as Control).get_path_to(title_controls[2]))
	assert((title_controls[2] as Control).focus_next == (title_controls[2] as Control).get_path_to(title_controls[3]))
	assert((title_controls[3] as Control).focus_next == (title_controls[3] as Control).get_path_to(title_controls[4]))
	assert((title_controls[4] as Control).focus_next == (title_controls[4] as Control).get_path_to(title_controls[5]))
	assert((title_controls[5] as Control).focus_next == (title_controls[5] as Control).get_path_to(title_controls[6]))
	assert((title_controls[6] as Control).focus_next == (title_controls[6] as Control).get_path_to(title_controls[7]))
	_assert_focus_chain(title_controls.slice(1), "title")


func _validate_responsive_ui_layouts() -> void:
	var localization: Node = get_root().get_node("Localization")
	localization.call("set_locale", &"ko", false)

	var training_game: DontDodgeGame = await _new_game(false, false)
	training_game.call("_create_training_setup")
	await process_frame
	await _assert_responsive_ui_element(
		training_game,
		training_game.get("_training_setup_layer").get_node("TrainingSetupPanel") as PanelContainer,
		"TrainingSetupMargin/TrainingSetupScroll",
		training_game,
		training_game.get("_training_form") as GridContainer,
		2,
		false,
		"training setup"
	)
	_validate_training_setup_choices(training_game)
	await _validate_training_setup_card_layout(training_game)
	training_game.call("_start_training_from_setup")
	await process_frame
	await _assert_responsive_ui_element(
		training_game,
		training_game.get("_training_controls_panel") as PanelContainer,
		"TrainingControlsMargin/TrainingControlsScroll",
		training_game,
		training_game.get("_training_enemy_grid") as GridContainer,
		2,
		false,
		"training controls"
	)
	_assert_training_controls_are_focusable(training_game)
	_validate_training_control_actions(training_game)
	await _dispose_game(training_game)

	var guide_game: DontDodgeGame = await _new_game(false, false)
	guide_game.call("_show_title_guide", &"normal", false)
	await process_frame
	await _assert_responsive_ui_element(
		guide_game,
		guide_game.get("_guide_panel") as PanelContainer,
		"GuideMargin/GuideScroll",
		guide_game,
		guide_game.get("_guide_card_grid") as GridContainer,
		-1,
		false,
		"combat guide"
	)
	await _dispose_game(guide_game)

	var challenge_game: DontDodgeGame = await _new_game(false, false)
	challenge_game.call("_start_game", &"challenge")
	await process_frame
	await _assert_responsive_ui_element(
		challenge_game,
		challenge_game.get("_challenge_roulette_panel") as PanelContainer,
		"ChallengeMargin/ChallengeScroll",
		challenge_game,
		challenge_game.get("_challenge_card_grid") as GridContainer,
		-1,
		false,
		"challenge roulette"
	)
	await _dispose_game(challenge_game)

	var pause_game: DontDodgeGame = await _new_game(false)
	pause_game.call("_open_manual_pause")
	await process_frame
	var pause_scroll := (pause_game.get("_pause_panel") as PanelContainer).get_node("PauseMargin/PauseScroll") as ScrollContainer
	var pause_contents := pause_scroll.get_child(0) as VBoxContainer
	var pause_restart_button: Button
	for child: Node in pause_contents.get_children():
		if child is Button and (child as Button).text == "다시 시작":
			pause_restart_button = child as Button
			break
	assert(is_instance_valid(pause_restart_button), "pause restart button missing")
	_assert_focus_chain([
		pause_game.get("_pause_resume_button"),
		pause_game.get("_pause_guide_button"),
		pause_restart_button,
		pause_game.get("_pause_bgm_button"),
		pause_game.get("_pause_sfx_button"),
		pause_game.get("_pause_language_option"),
		pause_game.get("_pause_main_button"),
	], "pause")
	assert((pause_game.get("_pause_button") as Button).focus_mode == Control.FOCUS_NONE, "pause button escaped modal focus chain")
	await _assert_responsive_ui_element(
		pause_game,
		pause_game.get("_pause_panel") as PanelContainer,
		"PauseMargin/PauseScroll",
		pause_game,
		null,
		-1,
		false,
		"pause"
	)
	pause_game.call("_resume_manual_pause")
	pause_game.call("_open_experience_upgrade", 1)
	await process_frame
	await _assert_responsive_ui_element(
		pause_game,
		pause_game.get("_upgrade_panel") as PanelContainer,
		"UpgradeMargin/UpgradeScroll",
		pause_game,
		pause_game.get("_upgrade_card_grid") as GridContainer,
		-1,
		false,
		"upgrade selection"
	)
	var upgrade_focusables: Array = []
	for card_value: Variant in pause_game.get("_upgrade_cards"):
		upgrade_focusables.append(card_value)
	_assert_focus_chain(upgrade_focusables, "upgrade selection")
	assert((pause_game.get("_upgrade_cards") as Array)[0].has_focus(), "upgrade selection did not focus first card")
	await _dispose_game(pause_game)

	var result_game: DontDodgeGame = await _new_game(false)
	result_game.call("_finish_run", &"result.death", [], "death")
	await process_frame
	await _assert_responsive_ui_element(
		result_game,
		result_game.get("_end_panel") as PanelContainer,
		"ResultMargin/ResultScroll",
		result_game,
		null,
		-1,
		true,
		"result"
	)
	await _resize_test_viewport(result_game, Vector2i(1600, 900))
	await _dispose_game(result_game)
	localization.call("set_locale", &"ko", false)


func _validate_training_setup_choices(game: DontDodgeGame) -> void:
	var weapon_cards: Array = game.get("_training_weapon_cards")
	var level_cards: Array = game.get("_training_level_cards")
	var technique_cards: Array = game.get("_training_technique_cards")
	var ultimate_cards: Array = game.get("_training_ultimate_cards")
	assert(weapon_cards.size() == 3, "training weapon cards incomplete")
	assert(level_cards.size() == 4, "training level cards incomplete")
	assert(technique_cards.size() == 3, "training technique cards incomplete")
	assert(ultimate_cards.size() == 2, "training ultimate cards incomplete")
	_assert_training_focusable_cards(weapon_cards)
	_assert_training_focusable_cards(level_cards)
	_assert_training_focusable_cards(technique_cards)
	_assert_training_focusable_cards(ultimate_cards)
	var setup_focusables: Array = []
	setup_focusables.append_array(weapon_cards)
	setup_focusables.append_array(level_cards)
	setup_focusables.append_array(technique_cards)
	setup_focusables.append_array(ultimate_cards)
	setup_focusables.append(game.get("_training_back_button"))
	setup_focusables.append(game.get("_training_start_button"))
	_assert_focus_chain(setup_focusables, "training setup")
	var weapon_card := weapon_cards[0] as Button
	var technique_card := technique_cards[0] as Button
	var ultimate_card := ultimate_cards[0] as Button
	assert(is_instance_valid(weapon_card.get_node("CardMargin/CardContents/CardIcon")), "weapon card icon missing")
	assert(not (weapon_card.get_node("CardMargin/CardContents/DescriptionLabel") as Label).text.is_empty(), "weapon card description missing")
	assert(not (weapon_card.get_node("CardMargin/CardContents/DescriptionLabel") as Label).visible, "weapon card description should be tooltip-only")
	assert(not (weapon_card.get_node("CardMargin/CardContents/DetailLabel") as Label).visible, "weapon card detail should be tooltip-only")
	assert(not str(weapon_card.get_meta(&"training_tooltip_text", "")).is_empty(), "weapon card tooltip missing")
	assert(weapon_card.custom_minimum_size.y <= 126.0, "weapon card remains too tall")
	assert(is_instance_valid(technique_card.get_node("CardMargin/CardContents/CardIcon")), "technique card icon missing")
	assert(not (technique_card.get_node("CardMargin/CardContents/DescriptionLabel") as Label).text.is_empty(), "technique card description missing")
	assert(not (technique_card.get_node("CardMargin/CardContents/DescriptionLabel") as Label).visible, "technique description should be tooltip-only")
	assert(not (technique_card.get_node("CardMargin/CardContents/DetailLabel") as Label).visible, "technique detail should be tooltip-only")
	assert(not str(technique_card.get_meta(&"training_tooltip_text", "")).is_empty(), "technique card tooltip missing")
	assert(technique_card.custom_minimum_size.y <= 126.0, "technique card remains too tall")
	assert(is_instance_valid(ultimate_card.get_node("CardMargin/CardContents/CardIcon")), "ultimate card icon missing")
	assert(not (ultimate_card.get_node("CardMargin/CardContents/DescriptionLabel") as Label).visible, "ultimate description should be tooltip-only")
	assert(not (ultimate_card.get_node("CardMargin/CardContents/DetailLabel") as Label).visible, "ultimate detail should be tooltip-only")
	assert(not str(ultimate_card.get_meta(&"training_tooltip_text", "")).is_empty(), "ultimate card tooltip missing")
	assert(ultimate_card.custom_minimum_size.y <= 126.0, "ultimate card remains too tall")
	var hover_modal := game.get("_training_hover_modal") as PanelContainer
	assert(is_instance_valid(hover_modal), "training hover modal missing")
	weapon_card.emit_signal("mouse_entered")
	assert(hover_modal.visible, "training hover modal did not appear immediately")
	var hover_style := hover_modal.get_theme_stylebox("panel") as StyleBoxFlat
	assert(is_instance_valid(hover_style), "training hover modal style missing")
	assert(is_zero_approx(hover_style.bg_color.a - 1.0), "training hover modal is not opaque")
	assert(hover_modal.size.y >= 230.0, "training hover modal is not vertically stacked")
	assert(not (hover_modal.get_node("TooltipMargin/TooltipContents/TooltipDescription") as Label).text.is_empty(), "training hover description missing")
	weapon_card.emit_signal("mouse_exited")
	assert(not hover_modal.visible, "training hover modal did not hide")
	weapon_card.grab_focus()
	await process_frame
	assert(hover_modal.visible, "training hover modal did not appear on focus")
	(game.get("_training_start_button") as Button).grab_focus()
	await process_frame
	assert(not hover_modal.visible, "training hover modal did not hide after focus moved")

	(level_cards[1] as Button).emit_signal("pressed")
	assert(int(game.get("_training_starting_level")) == 1)
	var locked_technique_id: String = str((technique_cards[0] as Button).get_meta(&"training_option_id", ""))
	for card_value: Variant in technique_cards:
		var card := card_value as Button
		assert(not card.disabled, "locked technique card must remain focusable")
		assert((card.get_node("CardMargin/CardContents/LockLabel") as Label).visible, "technique lock missing")
		assert(str(card.get_meta(&"training_tooltip_text", "")).contains("잠김"), "locked technique tooltip missing lock state")
	(technique_cards[0] as Button).emit_signal("pressed")
	assert(str(game.get("_training_technique_id")) == locked_technique_id, "locked technique changed selection")

	(level_cards[3] as Button).emit_signal("pressed")
	assert(int(game.get("_training_starting_level")) == 3)
	for card_value: Variant in technique_cards:
		assert(not (card_value as Button).get_node("CardMargin/CardContents/LockLabel").visible, "technique remained locked at LV3")
	for card_value: Variant in ultimate_cards:
		assert(not (card_value as Button).get_node("CardMargin/CardContents/LockLabel").visible, "ultimate remained locked at LV3")
	var selected_technique_id: String = str((technique_cards[1] as Button).get_meta(&"training_option_id", ""))
	var selected_ultimate_id: String = str((ultimate_cards[1] as Button).get_meta(&"training_option_id", ""))
	(technique_cards[1] as Button).emit_signal("pressed")
	(ultimate_cards[1] as Button).emit_signal("pressed")
	assert(str(game.get("_training_technique_id")) == selected_technique_id)
	assert(str(game.get("_training_ultimate_id")) == selected_ultimate_id)

	var selected_weapon_id: String = str((weapon_cards[1] as Button).get_meta(&"training_option_id", ""))
	(weapon_cards[1] as Button).emit_signal("pressed")
	assert(str(game.get("_training_weapon_id")) == selected_weapon_id)
	var summary_label := game.get("_training_summary_label") as Label
	assert(not summary_label.text.is_empty(), "training summary card is empty")
	assert(is_instance_valid(game.get("_training_summary_icon")), "training summary icon missing")


func _assert_training_focusable_cards(cards: Array) -> void:
	for card_value: Variant in cards:
		var card := card_value as Button
		assert(is_instance_valid(card), "training card missing")
		assert(card.focus_mode == Control.FOCUS_ALL, "training card is not keyboard focusable")
		assert(card.get_theme_stylebox("focus") != null, "training card focus style missing")
		var self_path := card.get_path_to(card)
		assert(card.focus_neighbor_left == self_path, "training card left arrow navigation is not blocked")
		assert(card.focus_neighbor_right == self_path, "training card right arrow navigation is not blocked")
		assert(card.focus_neighbor_top == self_path, "training card up arrow navigation is not blocked")
		assert(card.focus_neighbor_bottom == self_path, "training card down arrow navigation is not blocked")


func _validate_training_setup_card_layout(game: DontDodgeGame) -> void:
	var localization: Node = get_root().get_node("Localization")
	var weapon_grid := game.get("_training_weapon_grid") as GridContainer
	var level_grid := game.get("_training_level_grid") as GridContainer
	var technique_grid := game.get("_training_technique_grid") as GridContainer
	var ultimate_grid := game.get("_training_ultimate_grid") as GridContainer
	for locale: StringName in [&"ko", &"en"]:
		localization.call("set_locale", locale, false)
		await process_frame
		if locale == &"en":
			_assert_no_hangul_in_ui(game.get("_training_setup_layer"))
		for viewport_size: Vector2i in [Vector2i(1600, 900), Vector2i(1366, 768), Vector2i(1280, 720), Vector2i(1024, 768)]:
			await _resize_test_viewport(game, viewport_size)
			var expected_cards: int = 3 if viewport_size.x >= 1280 else 2 if viewport_size.x >= 800 else 1
			var expected_levels: int = 4 if viewport_size.x >= 1280 else 2 if viewport_size.x >= 800 else 1
			assert(weapon_grid.columns == expected_cards, "training weapon card columns mismatch")
			assert(level_grid.columns == expected_levels, "training level card columns mismatch")
			assert(technique_grid.columns == expected_cards, "training technique card columns mismatch")
			assert(ultimate_grid.columns == expected_cards, "training ultimate card columns mismatch")
	localization.call("set_locale", &"ko", false)
	await process_frame


func _assert_training_controls_are_focusable(game: DontDodgeGame) -> void:
	var panel := game.get("_training_controls_panel") as PanelContainer
	var enemy_grid := game.get("_training_enemy_grid") as GridContainer
	assert(is_instance_valid(panel), "training controls panel missing for focus validation")
	assert(is_instance_valid(enemy_grid), "training enemy grid missing for focus validation")
	for child: Node in enemy_grid.get_children():
		assert(child is Button, "training enemy control is not a button")
		assert((child as Button).focus_mode == Control.FOCUS_ALL, "training enemy button is not focusable")
		assert((child as Button).get_theme_stylebox("focus") != null, "training enemy focus style missing")
		assert(is_instance_valid((child as Button).get_node_or_null("CardMargin/CardContents/CardIcon")), "training enemy icon missing")
		assert(not ((child as Button).get_node("CardMargin/CardContents/RoleLabel") as Label).text.is_empty(), "training enemy role missing")
		var enemy_self_path := (child as Button).get_path_to(child)
		assert((child as Button).focus_neighbor_left == enemy_self_path, "training enemy left arrow navigation is not blocked")
		assert((child as Button).focus_neighbor_right == enemy_self_path, "training enemy right arrow navigation is not blocked")
		assert((child as Button).focus_neighbor_top == enemy_self_path, "training enemy up arrow navigation is not blocked")
		assert((child as Button).focus_neighbor_bottom == enemy_self_path, "training enemy down arrow navigation is not blocked")
	var scroll := panel.get_node("TrainingControlsMargin/TrainingControlsScroll") as ScrollContainer
	assert(is_instance_valid(scroll), "training controls scroll missing for focus validation")
	var contents := scroll.get_child(0) as VBoxContainer
	assert(is_instance_valid(contents), "training controls contents missing for focus validation")
	assert(contents.get_child_count() >= 8, "training controls contents incomplete")
	for button: Button in [game.get("_training_clear_button"), game.get("_training_reset_button"), game.get("_training_exit_button")]:
		assert(button.focus_mode == Control.FOCUS_ALL, "training action button is not focusable")
		assert(button.get_theme_stylebox("focus") != null, "training action focus style missing")
		assert(button.get_signal_connection_list("pressed").size() > 0, "training action button is not connected")
		var self_path := button.get_path_to(button)
		assert(button.focus_neighbor_left == self_path, "training action left arrow navigation is not blocked")
		assert(button.focus_neighbor_right == self_path, "training action right arrow navigation is not blocked")
		assert(button.focus_neighbor_top == self_path, "training action up arrow navigation is not blocked")
		assert(button.focus_neighbor_bottom == self_path, "training action down arrow navigation is not blocked")
	var focusables: Array = []
	for child: Node in enemy_grid.get_children():
		focusables.append(child)
	focusables.append(game.get("_training_clear_button"))
	focusables.append(game.get("_training_reset_button"))
	focusables.append(game.get("_training_exit_button"))
	_assert_focus_chain(focusables, "training controls")


func _validate_training_control_actions(game: DontDodgeGame) -> void:
	assert((game.get("_training_clear_button") as Button).text == "필드 정리")
	assert((game.get("_training_reset_button") as Button).text == "훈련 초기화")
	assert((game.get("_training_enemy_grid") as GridContainer).get_child(0) is Button)
	var enemy_grid := game.get("_training_enemy_grid") as GridContainer
	(enemy_grid.get_child(0) as Button).emit_signal("pressed")
	assert((game.get("_enemies") as Array).size() == 1, "training summon button did not spawn an enemy")
	(game.get("_training_clear_button") as Button).emit_signal("pressed")
	assert((game.get("_enemies") as Array).is_empty(), "training clear button did not clear enemies")
	(game.get("_training_reset_button") as Button).emit_signal("pressed")
	assert(is_zero_approx(float(game.get("_elapsed"))), "training reset did not reset elapsed time")
	assert(game.get_game_state() == DontDodgeGame.GameState.COMBAT, "training reset changed combat state")


func _assert_responsive_ui_element(
	game: DontDodgeGame,
	panel: PanelContainer,
	scroll_path: String,
	root: Node,
	grid: GridContainer,
	expected_columns_override: int,
	centered: bool,
	label: String
) -> void:
	assert(is_instance_valid(panel), "%s panel missing" % label)
	assert(panel.visible, "%s panel not visible" % label)
	var scroll := panel.get_node(scroll_path) as ScrollContainer
	assert(is_instance_valid(scroll), "%s scroll missing" % label)
	assert(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	assert(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO)
	var viewport_sizes: Array[Vector2i] = [
		Vector2i(1600, 900),
		Vector2i(1366, 768),
		Vector2i(1280, 720),
		Vector2i(1024, 768),
	]
	var locales: Array[StringName] = [&"ko", &"en"]
	var localization: Node = get_root().get_node("Localization")
	for locale: StringName in locales:
		localization.call("set_locale", locale, false)
		await process_frame
		if locale == &"en":
			_assert_no_hangul_in_ui(root)
		for viewport_size: Vector2i in viewport_sizes:
			await _resize_test_viewport(game, viewport_size)
			var rect := _get_test_viewport_rect(panel, viewport_size)
			assert(rect.size.x > 0.0 and rect.size.y > 0.0, "%s has no size" % label)
			assert(rect.position.x >= -0.5, "%s clipped left: %s" % [label, rect])
			assert(rect.position.y >= -0.5, "%s clipped top: %s" % [label, rect])
			assert(rect.end.x <= float(viewport_size.x) + 0.5, "%s clipped right: %s" % [label, rect])
			assert(rect.end.y <= float(viewport_size.y) + 0.5, "%s clipped bottom: %s" % [label, rect])
			if centered:
				var expected_center := Vector2(viewport_size) * 0.5
				assert(rect.get_center().distance_to(expected_center) < 1.0, "%s is not centered: %s" % [label, rect])
			if is_instance_valid(grid):
				var expected_columns: int = expected_columns_override if expected_columns_override > 0 else 3 if viewport_size.x >= 1280 else 2 if viewport_size.x >= 800 else 1
				assert(grid.columns == expected_columns, "%s columns: %d != %d" % [label, grid.columns, expected_columns])
	localization.call("set_locale", &"ko", false)
	await process_frame


func _get_test_viewport_rect(control: Control, viewport_size: Vector2i) -> Rect2:
	var position := Vector2(
		float(viewport_size.x) * control.anchor_left + control.offset_left,
		float(viewport_size.y) * control.anchor_top + control.offset_top
	)
	var size := Vector2(
		float(viewport_size.x) * (control.anchor_right - control.anchor_left) + control.offset_right - control.offset_left,
		float(viewport_size.y) * (control.anchor_bottom - control.anchor_top) + control.offset_bottom - control.offset_top
	)
	return Rect2(position, size)


func _resize_test_viewport(game: DontDodgeGame, viewport_size: Vector2i) -> void:
	game.call("_on_responsive_ui_viewport_size_changed", Vector2(viewport_size))
	await process_frame


func _assert_no_hangul_in_ui(root: Node) -> void:
	var hangul := RegEx.new()
	assert(hangul.compile("[가-힣]") == OK)
	_assert_no_hangul_in_node(root, hangul)


func _assert_no_hangul_in_node(node: Node, hangul: RegEx) -> void:
	if node is Control:
		var control := node as Control
		var visible_text: String = ""
		if control is Label:
			visible_text = (control as Label).text
		elif control is Button:
			visible_text = (control as Button).text
		assert(hangul.search(visible_text) == null, "Hangul remained in %s: %s" % [control.get_path(), visible_text])
		assert(hangul.search(control.tooltip_text) == null, "Hangul remained in tooltip %s: %s" % [control.get_path(), control.tooltip_text])
	for child: Node in node.get_children():
		_assert_no_hangul_in_node(child, hangul)


func _validate_completed_guide_skips(game: DontDodgeGame) -> void:
	var settings := ConfigFile.new()
	if settings.load("user://dont_dodge_settings.cfg") != OK:
		settings = ConfigFile.new()
	var previous_value: bool = bool(settings.get_value("tutorial", "guide_completed", false))
	settings.set_value("tutorial", "guide_completed", true)
	assert(settings.save("user://dont_dodge_settings.cfg") == OK)
	var start_button: Button = game.get_node("TitleLayer/LobbyRoot/SafeArea/Center/TitleScroller/PixelTitlePanel/PanelPadding/TitleLayoutSwitcher/WideLayout/RightColumn/StartButton") as Button
	start_button.emit_signal("pressed")
	assert(game.get_node_or_null("TitleLayer/GuidePanel") == null)
	assert(game.get_node_or_null("CombatVisuals") != null)
	settings = ConfigFile.new()
	assert(settings.load("user://dont_dodge_settings.cfg") == OK)
	settings.set_value("tutorial", "guide_completed", previous_value)
	assert(settings.save("user://dont_dodge_settings.cfg") == OK)


func _validate_first_combat_onboarding(game: DontDodgeGame) -> void:
	var settings := ConfigFile.new()
	if settings.load("user://dont_dodge_settings.cfg") != OK:
		settings = ConfigFile.new()
	var previous_version: int = int(settings.get_value("tutorial", "combat_hints_version", 0))
	settings.set_value("tutorial", "combat_hints_version", 0)
	assert(settings.save("user://dont_dodge_settings.cfg") == OK)

	game.call("_start_game")
	assert(bool(game.get("_combat_hints_enabled")))
	settings = ConfigFile.new()
	assert(settings.load("user://dont_dodge_settings.cfg") == OK)
	assert(int(settings.get_value("tutorial", "combat_hints_version", 0)) == 1)

	var panel: PanelContainer = game.get("_combat_hint_panel") as PanelContainer
	var hint_label: Label = game.get("_combat_hint_label") as Label
	assert(is_instance_valid(panel))
	var hint_font: Font = hint_label.get_theme_font("font")
	assert(hint_font != null)
	assert(hint_font.has_char("가".unicode_at(0)))
	assert(not panel.visible)
	var player: DontDodgePlayer = game.get_node("Player") as DontDodgePlayer
	var melee: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(90.0, 0.0))
	melee.set("_state", DontDodgeEnemy.State.WINDUP)
	game.call("_detect_combat_hint_triggers")
	assert(panel.visible)
	assert(hint_label.text == "가까운 적은 Q로 처치할 수 있습니다.")
	assert(game.perform_attack_for_test())
	game.call("_update_combat_hints", 0.0)
	assert(panel.visible)
	game.call("_update_combat_hints", 1.25)
	assert(not panel.visible)

	var second_enemy: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(100.0, 0.0))
	game.call("_queue_combat_hint", DontDodgeGame.CombatHint.NEGATE)
	game.call("_queue_combat_hint", DontDodgeGame.CombatHint.DODGE)
	assert(panel.visible)
	assert(hint_label.text == "탄환이나 혼전은 E로 위험을 지울 수 있습니다.")
	game.call("_try_negate")
	game.call("_update_combat_hints", 0.0)
	assert(panel.visible)
	assert(hint_label.text == "탄환이나 혼전은 E로 위험을 지울 수 있습니다.")
	game.call("_update_combat_hints", 1.25)
	assert(panel.visible)
	assert(hint_label.text == "강한 공격 예고가 보이면 W로 이동하며 회피하세요.")
	game.call("_update_combat_hints", 5.0)
	assert(panel.visible)
	assert(hint_label.text == "W와 E는 방어 스택을 공유합니다.")
	game.call("_update_combat_hints", 5.0)
	assert(not panel.visible)
	assert(is_instance_valid(second_enemy))

	game.set("_experience_level", 3)
	game.set("_ultimate_id", "ult_dagger_shadow_frenzy")
	game.call("_queue_combat_hint", DontDodgeGame.CombatHint.ULTIMATE)
	assert(panel.visible)
	assert(hint_label.text == "레벨 3 궁극기가 해금되었습니다. R로 사용하세요.")
	var stats: Dictionary = game.get("_stats")
	stats["ultimates"] = int(stats["ultimates"]) + 1
	game.call("_update_combat_hints", 0.0)
	assert(not panel.visible)

	var localization: Node = get_root().get_node("Localization")
	localization.call("set_locale", &"en", false)
	game.set("_combat_hints_enabled", true)
	(game.get("_combat_hint_seen") as Dictionary).clear()
	(game.get("_combat_hint_queue") as Array).clear()
	game.set("_combat_hint_active", DontDodgeGame.CombatHint.NONE)
	game.call("_queue_combat_hint", DontDodgeGame.CombatHint.MELEE)
	assert(hint_label.text == "A close enemy can be cut down with Q.")
	_assert_no_hangul_in_ui(game.get_node("CombatUILayer"))
	await _validate_combat_hint_layout(game)
	game.call("_skip_combat_hints")
	localization.call("set_locale", &"ko", false)
	settings = ConfigFile.new()
	assert(settings.load("user://dont_dodge_settings.cfg") == OK)
	settings.set_value("tutorial", "combat_hints_version", previous_version)
	assert(settings.save("user://dont_dodge_settings.cfg") == OK)


func _validate_combat_hint_layout(game: DontDodgeGame) -> void:
	var panel: PanelContainer = game.get("_combat_hint_panel") as PanelContainer
	for viewport_size: Vector2i in [Vector2i(1600, 900), Vector2i(1366, 768), Vector2i(1280, 720)]:
		assert(panel.offset_left >= 0.0)
		assert(panel.offset_right <= float(viewport_size.x))
		assert(panel.custom_minimum_size.y <= float(viewport_size.y) + panel.offset_bottom)


func _validate_training_mode_has_no_combat_hints(game: DontDodgeGame) -> void:
	game.call("_start_game", &"training")
	assert(str(game.get("_mode")) == "training")
	assert(not bool(game.get("_combat_hints_enabled")))
	assert(not (game.get("_combat_hint_panel") as PanelContainer).visible)


func _validate_challenge_mode(game: DontDodgeGame) -> void:
	game.call("_start_game", &"challenge")
	assert(str(game.get("_mode")) == "challenge")
	assert(not bool(game.get("_combat_hints_enabled")))
	assert(game.get_game_state() == DontDodgeGame.GameState.CHALLENGE_REVEAL)
	assert(game.get_node_or_null("CombatUILayer/ChallengeRoulettePanel") != null)
	assert((game.get("_challenge_roulette_panel") as PanelContainer).visible)
	assert(float(game.get("_elapsed")) == 0.0)
	assert(game.get("_spawn_schedule").size() == 82)
	game.call("_process", 1.4)
	assert(bool(game.get("_challenge_roulette_finished")))
	var selected_id: StringName = game.get("_challenge_debuff_id")
	var found_selected: bool = false
	for debuff: Dictionary in CHALLENGE_DATA_SCRIPT.get_pool():
		if debuff["id"] == selected_id:
			found_selected = true
	assert(found_selected)
	var challenge_start_button: Button = game.get("_challenge_start_button") as Button
	assert(challenge_start_button.text == "도전 시작")
	assert(not challenge_start_button.disabled)
	challenge_start_button.emit_signal("pressed")
	assert(game.get_game_state() == DontDodgeGame.GameState.COMBAT)
	assert(int(game.get("_active_slot_index")) == 0)

	game.set("_mode", &"challenge")
	game.set("_challenge_debuff_id", &"slow_defense")
	game.set("_challenge_debuff", CHALLENGE_DATA_SCRIPT.get_debuff(&"slow_defense"))
	assert(is_equal_approx(float(game.call("_get_challenge_defense_recovery_seconds")), 7.0))
	game.set("_challenge_debuff_id", &"ultimate_famine")
	game.set("_challenge_debuff", CHALLENGE_DATA_SCRIPT.get_debuff(&"ultimate_famine"))
	game.set("_ultimate_id", "ult_dagger_shadow_frenzy")
	game.set("_ultimate_charge", 0)
	game.call("_grant_ultimate", 3, "validation")
	assert(int(game.get("_ultimate_charge")) == 2)
	game.set("_ultimate_id", "")

	game.set("_challenge_debuff_id", &"dry_dungeon")
	game.set("_challenge_debuff", CHALLENGE_DATA_SCRIPT.get_debuff(&"dry_dungeon"))
	game.set("_elapsed", 30.0)
	game.set("_next_heart_spawn_at", 30.0)
	game.call("_spawn_due_hearts")
	assert((game.get("_hearts") as Array).is_empty())

	game.set("_challenge_debuff_id", &"bullet_overload")
	game.set("_challenge_debuff", CHALLENGE_DATA_SCRIPT.get_debuff(&"bullet_overload"))
	var player: DontDodgePlayer = game.get_node("Player") as DontDodgePlayer
	var volley: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.VOLLEY, player.global_position + Vector2(380.0, 0.0))
	game.call("_on_enemy_projectile_fired", volley, volley.global_position, player.global_position, 3, 28.0)
	assert((game.get("_projectiles") as Array).size() == 4)


func _validate_asset_catalog_and_sfx() -> void:
	var atlas_size := Vector2(DontDodgeAssetCatalog.ATLAS.get_size())
	assert(atlas_size.x > 0.0 and atlas_size.y > 0.0)
	for tile_id: int in DontDodgeAssetCatalog.required_tile_ids():
		assert(DontDodgeAssetCatalog.has_tile(tile_id))
		var region: Rect2 = DontDodgeAssetCatalog.tile_region(tile_id)
		assert(region.size == Vector2(DontDodgeAssetCatalog.TILE_SIZE, DontDodgeAssetCatalog.TILE_SIZE))
		assert(region.position.x >= 0.0 and region.position.y >= 0.0)
		assert(region.end.x <= atlas_size.x and region.end.y <= atlas_size.y)
		var texture: AtlasTexture = DontDodgeAssetCatalog.make_tile_texture(tile_id)
		assert(texture.atlas == DontDodgeAssetCatalog.ATLAS)
		assert(texture.region == region)
	var sound_event_ids: PackedStringArray = PackedStringArray([
		DontDodgeGame.SOUND_EVENT_PLAYER_ATTACK,
		DontDodgeGame.SOUND_EVENT_PLAYER_HIT,
		DontDodgeGame.SOUND_EVENT_ENEMY_ATTACK,
		DontDodgeGame.SOUND_EVENT_ENEMY_HIT,
		DontDodgeGame.SOUND_EVENT_ENEMY_DEFEATED,
		DontDodgeGame.SOUND_EVENT_WAVE_STARTED,
		DontDodgeGame.SOUND_EVENT_ULTIMATE,
		DontDodgeGame.SOUND_EVENT_GAME_CLEAR,
		DontDodgeGame.SOUND_EVENT_GAME_OVER,
		&"ui",
	])
	for event_id: StringName in sound_event_ids:
		var paths: Array = DontDodgeSfxController.STREAMS_BY_EVENT.get(event_id, [])
		assert(paths.size() == 5)
		for stream_path: String in paths:
			assert(ResourceLoader.exists(stream_path, "AudioStream"))
	var hit_layer_paths: Array = DontDodgeSfxController.LAYER_STREAMS_BY_EVENT.get(DontDodgeGame.SOUND_EVENT_ENEMY_HIT, [])
	assert(hit_layer_paths.size() == 5)
	for stream_path: String in hit_layer_paths:
		assert(ResourceLoader.exists(stream_path, "AudioStream"))
	var sfx_controller: Node = get_root().get_node("SfxController")
	sfx_controller.call("play_event", DontDodgeGame.SOUND_EVENT_PLAYER_ATTACK)


func _validate_pattern_timeline() -> void:
	var pattern_data: Variant = PATTERN_DATA_SCRIPT.new()
	var timeline: Array[Dictionary] = pattern_data.build_timeline()
	assert(timeline.size() == 20)
	var wave_counts: Array[int] = [0, 0, 0, 0]
	var total: int = 0
	var pattern_ids: Dictionary = {}
	for slot: Dictionary in timeline:
		if str(slot["kind"]) == "pattern":
			pattern_ids[str(slot["id"])] = true
		for event: Dictionary in slot["events"]:
			wave_counts[int(slot["wave_id"]) - 1] += 1
			total += 1
	assert(wave_counts == [15, 15, 28, 24])
	assert(total == 82)
	assert(pattern_ids.size() == 10)
	assert(is_equal_approx(float(timeline[13]["start_time"]), 59.0))
	assert(str(timeline[13]["kind"]) == "recovery")
	assert(is_equal_approx(float(timeline[19]["start_time"]), 84.45))
	var final_pattern: Dictionary = pattern_data.get_pattern("final_relay_01")
	var validation: Dictionary = final_pattern["validation"]
	var reference_window: Vector2 = validation["reference_e_window"]
	assert(reference_window.y + 84.45 <= 89.70)
	assert(reference_window.y + 84.45 <= 89.85)
	assert(float(validation["minimum_verified_window"]) >= 0.30)
	assert(not bool(timeline[0]["allow_early_advance"]))
	assert(bool(timeline[5]["allow_early_advance"]))
	var fan_pattern: Dictionary = pattern_data.get_pattern("erase_fan_01")
	assert(int(fan_pattern["advance"]["max_alive_enemies"]) == 1)
	assert(int(fan_pattern["advance"]["max_total_enemies"]) == 2)
	assert(str(fan_pattern["events"][2]["role"]) == "secondary")
	assert(is_equal_approx(float(pattern_data.get_pattern("cut_tell_01")["events"][2]["time"]), 3.10))
	assert(is_equal_approx(float(pattern_data.get_pattern("dash_the_line_01")["events"][3]["time"]), 3.70))


func _validate_warning_to_materialization(game: DontDodgeGame) -> void:
	assert(game.get("_spawn_schedule").size() == 82)
	game.call("_process", 0.05)
	assert(game.get("_spawn_warnings").size() >= 1)
	game.call("_process", DontDodgeTuning.SPAWN_WARNING_MELEE + 0.01)
	assert(game.get("_actual_spawn_events").size() >= 1)
	var enemies: Array[DontDodgeEnemy] = game.get("_enemies")
	assert(enemies.size() >= 1)
	assert(enemies[0].is_materializing())
	enemies[0].advance(DontDodgeTuning.SPAWN_MATERIALIZE_LOCK + 0.01)
	assert(enemies[0].is_combat_active())


func _validate_spawn_lock_and_action_immunity(game: DontDodgeGame) -> void:
	var player: DontDodgePlayer = game.get_node("Player")
	var locked: DontDodgeEnemy = game.call("_spawn_enemy", DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(100.0, 0.0), {"pattern_id": "validation", "pattern_instance_id": "validation_0", "role": "primary", "hazard_id": "validation_enemy", "spawn_lock": DontDodgeTuning.SPAWN_MATERIALIZE_LOCK})
	assert(locked.is_materializing())
	assert(not locked.is_combat_active())
	assert(game.perform_attack_for_test()) # The input is consumed, but the locked enemy cannot be hit.
	assert(locked.get_health() == DontDodgeTuning.MELEE_HEALTH)
	game.advance_attack_recovery_for_test(1.0)
	game.call("_try_negate")
	assert(locked.is_materializing())
	locked.advance(DontDodgeTuning.SPAWN_MATERIALIZE_LOCK + 0.01)
	assert(locked.is_combat_active())
	assert(game.perform_attack_for_test())
	assert(locked.get_health() <= 0)


func _validate_early_pressure_transition(game: DontDodgeGame) -> void:
	game.set("_waves_cleared", 1)
	game.set("_active_slot_index", 5)
	game.set("_elapsed", 25.0)
	game.call("_start_slot", 5)
	var schedule: Array[Dictionary] = game.get("_spawn_schedule")
	for schedule_index: int in schedule.size():
		var entry: Dictionary = schedule[schedule_index]
		if int(entry["slot_index"]) == 5:
			entry["dispatched"] = true
			schedule[schedule_index] = entry
	game.set("_elapsed", 27.8)
	game.call("_process", 0.0)
	assert(int(game.get("_active_slot_index")) == 6)
	var carry_context: Dictionary = game.get("_pattern_contexts")[6]
	var player: DontDodgePlayer = game.get_node("Player")
	game.call("_spawn_enemy", DontDodgeEnemy.EnemyType.RANGED, player.global_position + Vector2(300.0, 0.0), {"pattern_id": carry_context["pattern_id"], "pattern_instance_id": carry_context["instance_id"], "role": "secondary", "hazard_id": "carry_validation"})
	var active_enemies: Array[DontDodgeEnemy] = game.get("_enemies")
	active_enemies[active_enemies.size() - 1].set("_state", DontDodgeEnemy.State.INTERRUPTED)
	for schedule_index: int in schedule.size():
		var entry: Dictionary = schedule[schedule_index]
		if int(entry["slot_index"]) == 6:
			entry["dispatched"] = true
			schedule[schedule_index] = entry
	game.set("_elapsed", 31.6)
	game.call("_process", 0.0)
	assert(int(game.get("_active_slot_index")) == 7)


func _validate_late_pattern_event_does_not_gate(game: DontDodgeGame) -> void:
	game.set("_waves_cleared", 1)
	game.set("_active_slot_index", 5)
	game.set("_elapsed", 25.0)
	game.call("_start_slot", 5)
	game.call("_process", 2.8)
	assert(game.get_game_state() == DontDodgeGame.GameState.COMBAT)
	assert(int(game.get("_active_slot_index")) == 5)


func _validate_experience_upgrade_and_wave_flow(game: DontDodgeGame) -> void:
	var upgrade_cards: Array[Button] = game.get("_upgrade_cards")
	for card: Button in upgrade_cards:
		assert(card.get_node("CardContents/RoleLabel").text != "")
	var player: DontDodgePlayer = game.get_node("Player")
	for _index: int in DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS[0]:
		assert(game.spawn_experience_orb_for_test(player.global_position, 1) != null)
		game.call("_process", 0.0)
	assert(int(game.get("_experience")) == DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS[0])
	assert(int(game.get("_experience_level")) == 1)
	assert(game.get_game_state() == DontDodgeGame.GameState.UPGRADE)
	assert(game.get("_upgrade_options").size() == 3)
	assert(game.get("_upgrade_options")[0]["title_key"] == &"data.dagger.title")
	assert(game.get("_upgrade_options")[1]["title_key"] == &"data.guardian_mace.title")
	assert(game.get("_upgrade_options")[2]["title_key"] == &"data.battle_spear.title")
	for card: Button in upgrade_cards:
		assert(card.get_node("CardContents/EffectLabel").text.begins_with("효과 · "))
	assert(game.select_upgrade_for_test("weapon_dagger"))
	assert(game.get_game_state() == DontDodgeGame.GameState.COMBAT)
	assert(game.get_loadout()["weapon_id"] == "dagger")
	assert(game.get_loadout()["ultimate_id"] == "")
	assert(int(game.get("_ultimate_charge")) == 0)
	assert((game.get("_ultimate_button") as Button).get_node("ActionLabel").text == "잠김")
	for _index: int in DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS[1] - DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS[0]:
		assert(game.spawn_experience_orb_for_test(player.global_position, 1) != null)
		game.call("_process", 0.0)
	assert(int(game.get("_experience_level")) == 2)
	assert(game.get("_upgrade_options").size() == 3)
	assert(game.get("_upgrade_options")[0]["title_key"] == &"data.tech_dagger_draw.title")
	assert(game.get("_upgrade_options")[1]["title_key"] == &"data.tech_dagger_flurry.title")
	assert(game.get("_upgrade_options")[2]["title_key"] == &"data.tech_dagger_ghost_step.title")
	assert(game.select_upgrade_for_test("tech_dagger_draw"))
	for _index: int in DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS[2] - DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS[1]:
		assert(game.spawn_experience_orb_for_test(player.global_position, 1) != null)
		game.call("_process", 0.0)
	assert(int(game.get("_experience_level")) == 3)
	assert(game.get("_upgrade_options").size() == 2)
	assert(game.get("_upgrade_options")[0]["title_key"] == &"data.ult_dagger_shadow_frenzy.title")
	assert(game.get("_upgrade_options")[1]["title_key"] == &"data.ult_dagger_assassination_mark.title")
	var ultimate_cards: Array[Button] = game.get("_upgrade_cards")
	assert(ultimate_cards[0].visible and ultimate_cards[1].visible and not ultimate_cards[2].visible)
	game.call("_move_upgrade_cursor", 1)
	assert(int(game.get("_upgrade_cursor")) == 1)
	assert(ultimate_cards[1].has_focus())
	game.call("_move_upgrade_cursor", -1)
	assert(game.select_upgrade_for_test("ult_dagger_shadow_frenzy"))
	assert(game.get_loadout()["technique_id"] == "tech_dagger_draw")
	assert(game.get_loadout()["ultimate_id"] == "ult_dagger_shadow_frenzy")
	assert(int(game.get("_ultimate_charge")) == DontDodgeTuning.ULTIMATE_MAX)
	assert((game.get("_ultimate_button") as Button).get_node("ActionLabel").text == "준비 완료")
	assert(not (game.get("_ultimate_button") as Button).disabled)
	assert(LOADOUT_DATA_SCRIPT.get_ultimate_options("dagger").size() == 2)
	game.set("_active_slot_index", 9)
	game.call("_start_slot", 9)
	game.call("_process", 0.0)
	assert(int(game.get("_active_slot_index")) == 10)
	game.set("_active_slot_index", 19)
	game.set("_elapsed", 60.0)
	game.call("_start_slot", 19)
	game.set("_elapsed", 65.0)
	game.call("_process", 0.0)
	assert(int(game.get("_active_slot_index")) == 18)


func _validate_loadout_rules_and_attack_profile(game: DontDodgeGame) -> void:
	assert(game.get_attack_profile()["attack_speed_percent"] == 0)
	assert(is_equal_approx(float(game.get_attack_profile()["attack_interval"]), DontDodgeTuning.FOCUS_RECOVERY))
	game.call("_open_experience_upgrade", 1)
	assert(game.select_upgrade_for_test("weapon_dagger"))
	var dagger_profile: Dictionary = game.get_attack_profile()
	assert(dagger_profile["attack_speed_percent"] == 35)
	assert(is_equal_approx(float(dagger_profile["attack_interval"]), DontDodgeTuning.FOCUS_RECOVERY / 1.35))
	assert(dagger_profile["negate_enabled"] == false)
	assert(dagger_profile["max_health"] == 2)
	assert(dagger_profile["defense_max_charges"] == 3)
	assert(dagger_profile["dodge_cost"] == 1)
	assert(dagger_profile["attack_target_limit"] == 1)
	assert(dagger_profile["attack_pierces"] == false)
	var defense: DefenseResource = game.get_defense_resource()
	var charges_before: int = defense.get_charges()
	game.call("_try_negate")
	assert(defense.get_charges() == charges_before)


func _validate_dagger_techniques(game: DontDodgeGame) -> void:
	game.call("_open_experience_upgrade", 1)
	assert(game.select_upgrade_for_test("weapon_dagger"))
	game.call("_open_experience_upgrade", 2)
	assert(game.select_upgrade_for_test("tech_dagger_draw"))
	var player: DontDodgePlayer = game.get_node("Player")
	var defense: DefenseResource = game.get_defense_resource()
	defense.reset()
	game.call("_try_dodge", Vector2.RIGHT)
	assert(defense.get_charges() == 2)
	game.call("_process", DontDodgeTuning.DODGE_DURATION + 0.01)
	assert(player.is_stealthed())
	assert(player.consume_stealth_attack_bonus())

	var first: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(76.0, 0.0))
	var second: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(92.0, 0.0))
	game.advance_attack_recovery_for_test(1.0)
	assert(game.perform_attack_for_test())
	assert(first.get_health() <= 0 or second.get_health() <= 0)
	assert(first.get_health() == DontDodgeTuning.MELEE_HEALTH or second.get_health() == DontDodgeTuning.MELEE_HEALTH)
	first.global_position = player.global_position - Vector2(400.0, 0.0)
	second.global_position = player.global_position - Vector2(400.0, 0.0)

	game.set("_technique_id", "tech_dagger_flurry")
	game.set("_attack_sequence", 2)
	game.advance_attack_recovery_for_test(1.0)
	var flurry_first: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(70.0, 0.0))
	var flurry_second: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(102.0, 0.0))
	assert(game.perform_attack_for_test())
	assert(flurry_first.get_health() <= 0)
	assert(flurry_second.get_health() <= 0)

	game.set("_technique_id", "tech_dagger_ghost_step")
	game.advance_attack_recovery_for_test(1.0)
	var ghost_target: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(80.0, 0.0))
	ghost_target.set("_health", 1)
	assert(game.perform_attack_for_test())
	assert(float(game.get("_ghost_step_remaining")) > 0.0)


func _validate_dagger_ultimates(game: DontDodgeGame) -> void:
	var player: DontDodgePlayer = game.get_node("Player")
	var origin: Vector2 = player.global_position
	game.set("_ultimate_id", "ult_dagger_shadow_frenzy")
	var shadow_targets: Array[DontDodgeEnemy] = []
	for target_index: int in 3:
		shadow_targets.append(game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.ELITE, origin + Vector2(150.0 + target_index * 175.0, 0.0)))
	game.call("_perform_dagger_shadow_frenzy")
	assert(shadow_targets[0].get_health() == DontDodgeTuning.ELITE_HEALTH)
	assert(shadow_targets[1].get_health() == DontDodgeTuning.ELITE_HEALTH)
	assert(shadow_targets[2].get_health() == DontDodgeTuning.ELITE_HEALTH)
	assert(float(game.get("_damage_guard_remaining")) >= DontDodgeTuning.DAGGER_SHADOW_FRENZY_INVULNERABILITY)
	var combat_visuals: DontDodgeCombatVisuals = game.get_node("CombatVisuals")
	game.call("_process", 0.0)
	var shadow_marker_found: bool = false
	var shadow_path_found: bool = false
	var shadow_range_found: bool = false
	var shadow_endpoint_found: bool = false
	for effect: Dictionary in combat_visuals.get("_special_effects"):
		if str(effect.get("kind", "")) == "dagger_target_marker":
			shadow_marker_found = true
		if str(effect.get("kind", "")) == "ultimate_dash":
			shadow_path_found = true
		if str(effect.get("kind", "")) == "dagger_range_preview":
			shadow_range_found = true
			assert(is_equal_approx(float(effect["radius"]), DontDodgeTuning.DAGGER_SHADOW_FRENZY_RADIUS))
		if str(effect.get("kind", "")) == "dagger_dash_endpoint":
			shadow_endpoint_found = true
	assert(shadow_marker_found)
	assert(shadow_path_found)
	assert(shadow_range_found)
	assert(shadow_endpoint_found)
	assert(player.global_position == origin)
	game.call("_process", 0.1)
	assert(shadow_targets[0].get_health() == DontDodgeTuning.ELITE_HEALTH)
	assert(player.global_position == origin)
	game.call("_process", 0.1)
	assert(shadow_targets[0].get_health() == DontDodgeTuning.ELITE_HEALTH - DontDodgeTuning.DAGGER_SHADOW_FRENZY_DAMAGE)
	assert(player.global_position != origin)
	for _frame: int in 30:
		game.call("_process", 0.1)
	assert(shadow_targets[0].get_health() == DontDodgeTuning.ELITE_HEALTH - DontDodgeTuning.DAGGER_SHADOW_FRENZY_DAMAGE)
	assert(shadow_targets[1].get_health() == DontDodgeTuning.ELITE_HEALTH - DontDodgeTuning.DAGGER_SHADOW_FRENZY_DAMAGE)
	assert(shadow_targets[2].get_health() == DontDodgeTuning.ELITE_HEALTH - DontDodgeTuning.DAGGER_SHADOW_FRENZY_DAMAGE)
	assert(player.global_position != origin)

	for shadow_target: DontDodgeEnemy in shadow_targets:
		shadow_target.set("_state", DontDodgeEnemy.State.DEFEATED)
	game.set("_ultimate_id", "ult_dagger_assassination_mark")
	player.global_position = origin
	var marked_target: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.ELITE, origin + Vector2(260.0, 0.0))
	game.call("_perform_dagger_assassination_mark")
	assert(marked_target.get_health() == DontDodgeTuning.ELITE_HEALTH)
	assert(player.global_position == origin)
	assert(float(game.get("_damage_guard_remaining")) >= DontDodgeTuning.DAGGER_ASSASSINATION_INVULNERABILITY)
	game.call("_process", 0.0)
	var mark_found: bool = false
	var assassination_path_found: bool = false
	for effect: Dictionary in combat_visuals.get("_special_effects"):
		if str(effect.get("kind", "")) == "assassination_mark":
			mark_found = true
			assert(effect.get("target") == marked_target)
		if str(effect.get("kind", "")) == "ultimate_dash":
			assassination_path_found = true
	assert(mark_found)
	assert(assassination_path_found)
	game.call("_process", 0.2)
	assert(marked_target.get_health() == DontDodgeTuning.ELITE_HEALTH)
	assert(player.global_position == origin)
	game.call("_process", 0.1)
	assert(marked_target.get_health() == DontDodgeTuning.ELITE_HEALTH - DontDodgeTuning.DAGGER_ASSASSINATION_HIT_DAMAGE)
	assert(player.global_position != origin)
	for _frame: int in 20:
		game.call("_process", 0.1)
	assert(marked_target.get_health() == 0)
	assert(player.global_position != origin)


func _validate_guardian_mace_defense_and_techniques(game: DontDodgeGame) -> void:
	game.call("_open_experience_upgrade", 1)
	assert(game.select_upgrade_for_test("weapon_guardian_mace"))
	var mace_profile: Dictionary = game.get_attack_profile()
	assert(mace_profile["dodge_cost"] == 2)
	assert(mace_profile["max_health"] == 3)
	assert(mace_profile["defense_max_charges"] == 3)
	assert(mace_profile["negate_enabled"] == true)
	var defense: DefenseResource = game.get_defense_resource()
	defense.reset()
	game.call("_open_experience_upgrade", 2)
	assert(game.select_upgrade_for_test("tech_mace_counter"))
	var player: DontDodgePlayer = game.get_node("Player")
	var charger: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.CHARGER, player.global_position + Vector2(100.0, 0.0))
	charger.set("_state", DontDodgeEnemy.State.WINDUP)
	game.call("_try_negate")
	assert(defense.get_charges() == 2)
	game.call("_on_enemy_strike_landed", charger, player.global_position + Vector2(60.0, 0.0), 72.0)
	assert(charger.get_visual_state_id() == DontDodgeEnemy.VISUAL_STATE_INTERRUPTED)
	assert(bool(game.get("_guard_successful")))
	assert(float(game.get("_mace_counter_remaining")) > 0.0)
	assert(game.perform_attack_for_test())
	assert(not bool(game.get("_guard_successful")))

	game.call("_process", DontDodgeTuning.MACE_COUNTER_HIT_STOP)
	game.call("_process", 0.0)
	defense.reset()
	var projectile := DontDodgeProjectile.new()
	projectile.setup(player.global_position + Vector2(100.0, 0.0), player.global_position)
	game.add_child(projectile)
	game.get("_projectiles").append(projectile)
	game.call("_try_negate")
	game.call("_process", 0.01)
	var reflected_found: bool = false
	for active_projectile: DontDodgeProjectile in game.get("_projectiles"):
		if is_instance_valid(active_projectile) and active_projectile.is_reflected():
			reflected_found = true
	assert(reflected_found)

	game.set("_technique_id", "tech_mace_suppress")
	game.advance_attack_recovery_for_test(1.0)
	game.call("_open_experience_upgrade", 2)
	charger.global_position = player.global_position - Vector2(100.0, 0.0)
	var melee: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(90.0, 0.0))
	melee.set("_state", DontDodgeEnemy.State.WINDUP)
	assert(game.perform_attack_for_test())
	assert(melee.get_visual_state_id() == DontDodgeEnemy.VISUAL_STATE_INTERRUPTED or melee.get_health() <= 0)
	assert(int(game.get("_break_cooldown_remaining")) > 0)


func _validate_battle_spear_rules_and_techniques(game: DontDodgeGame) -> void:
	game.call("_open_experience_upgrade", 1)
	assert(game.select_upgrade_for_test("weapon_battle_spear"))
	var spear_profile: Dictionary = game.get_attack_profile()
	assert(spear_profile["arc_degrees"] >= 20.0 and spear_profile["arc_degrees"] <= 25.0)
	assert(spear_profile["range"] > DontDodgeTuning.FOCUS_RANGE)
	assert(spear_profile["attack_pierces"] == true)
	assert(spear_profile["max_health"] == 3)
	game.call("_open_experience_upgrade", 2)
	assert(game.select_upgrade_for_test("tech_spear_breakthrough"))
	var player: DontDodgePlayer = game.get_node("Player")
	var enemy: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(24.0, 0.0))
	player.set("_dash_remaining", 0.1)
	game.call("_update_spear_dodge_contact")
	assert(float(game.get("_spear_breakthrough_remaining")) > 0.0)
	game.set("_technique_id", "tech_spear_bullet_cut")
	var defense: DefenseResource = game.get_defense_resource()
	defense.reset()
	for index: int in 2:
		var projectile := DontDodgeProjectile.new()
		projectile.setup(player.global_position + Vector2(80.0 + index * 20.0, 0.0), player.global_position)
		game.add_child(projectile)
		game.get("_projectiles").append(projectile)
	game.call("_try_negate")
	assert(bool(game.get("_spear_radial_attack_ready")))
	game.set("_technique_id", "tech_spear_edge_pressure")
	enemy.global_position = player.global_position + Vector2(170.0, 0.0)
	game.advance_attack_recovery_for_test(1.0)
	assert(game.perform_attack_for_test())
	assert(enemy.get_health() < DontDodgeTuning.MELEE_HEALTH or float(enemy.get("_slow_remaining")) > 0.0)
	assert(float(game.get("_spear_edge_pressure_remaining")) > 0.0)


func _validate_reworked_weapon_ultimates(game: DontDodgeGame) -> void:
	var player: DontDodgePlayer = game.get_node("Player")
	var combat_visuals: DontDodgeCombatVisuals = game.get_node("CombatVisuals")
	game.set("_weapon_id", "guardian_mace")
	game.set("_ultimate_id", "ult_mace_frontline_break")
	game.call("_apply_weapon_loadout")
	player.set("_last_move_direction", Vector2.RIGHT)
	game.set("_ultimate_charge", DontDodgeTuning.ULTIMATE_MAX)
	game.call("_try_ultimate")
	assert(game.get("_weapon_ultimate_sequence").size() == 2)
	assert(player.global_position == DontDodgeTuning.ARENA_SIZE * 0.5)
	game.call("_process", DontDodgeTuning.ULTIMATE_FREEZE_DURATION)
	game.call("_process", 0.0)
	var frontline_telegraph_found: bool = false
	for effect: Dictionary in combat_visuals.get("_special_effects"):
		if str(effect.get("kind", "")) == "mace_frontline_target":
			frontline_telegraph_found = true
	assert(frontline_telegraph_found)
	game.call("_process", DontDodgeTuning.MACE_FRONTLINE_BREAK_TELEGRAPH + 0.01)
	assert(player.global_position != DontDodgeTuning.ARENA_SIZE * 0.5)

	game.call("_clear_training_entities")
	game.set("_weapon_id", "battle_spear")
	game.set("_ultimate_id", "ult_spear_sky_pierce")
	game.call("_apply_weapon_loadout")
	player.global_position = DontDodgeTuning.ARENA_SIZE * 0.5
	var sky_target: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.ELITE, player.global_position + Vector2(260.0, 0.0))
	var sky_far_target: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(640.0, 0.0))
	var sky_rear_target: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(-640.0, 0.0))
	game.set("_ultimate_charge", DontDodgeTuning.ULTIMATE_MAX)
	game.call("_try_ultimate")
	assert(sky_target.get_health() == DontDodgeTuning.ELITE_HEALTH)
	var sky_sequence: Array[Dictionary] = game.get("_weapon_ultimate_sequence")
	var sky_telegraph: Dictionary = sky_sequence[0]
	var sky_start: Vector2 = sky_telegraph["start"]
	var sky_end: Vector2 = sky_telegraph["end"]
	assert(is_equal_approx(sky_start.x, DontDodgeTuning.PLAYER_RADIUS))
	assert(is_equal_approx(sky_end.x, DontDodgeTuning.ARENA_SIZE.x - DontDodgeTuning.PLAYER_RADIUS))
	game.call("_process", DontDodgeTuning.ULTIMATE_FREEZE_DURATION)
	game.call("_process", 0.0)
	assert(sky_target.get_health() == DontDodgeTuning.ELITE_HEALTH)
	game.call("_process", DontDodgeTuning.SPEAR_SKY_PIERCE_TELEGRAPH + 0.01)
	assert(sky_target.get_health() == DontDodgeTuning.ELITE_HEALTH - DontDodgeTuning.SPEAR_SKY_PIERCE_DAMAGE)
	assert(sky_far_target.get_health() <= 0)
	assert(sky_rear_target.get_health() <= 0)
	for _frame: int in 20:
		game.call("_process", 0.1)
	assert(sky_target.get_health() == DontDodgeTuning.ELITE_HEALTH - DontDodgeTuning.SPEAR_SKY_PIERCE_DAMAGE * DontDodgeTuning.SPEAR_SKY_PIERCE_PULSES)
	assert(sky_far_target.get_health() <= 0)
	assert(sky_rear_target.get_health() <= 0)

	game.set("_ultimate_id", "ult_spear_formation")
	game.call("_clear_training_entities")
	var formation_target: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.ELITE, player.global_position + Vector2(220.0, 0.0))
	var formation_rear_target: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(-220.0, 0.0))
	game.set("_ultimate_charge", DontDodgeTuning.ULTIMATE_MAX)
	game.call("_try_ultimate")
	assert(formation_target.get_health() == DontDodgeTuning.ELITE_HEALTH)
	assert(formation_rear_target.get_health() == DontDodgeTuning.MELEE_HEALTH)
	for _frame: int in 20:
		game.call("_process", 0.1)
	assert(formation_target.get_health() == 0 or formation_target.get_health() <= DontDodgeTuning.ELITE_HEALTH - DontDodgeTuning.SPEAR_FORMATION_DAMAGE * DontDodgeTuning.SPEAR_FORMATION_PULSES)
	assert(formation_rear_target.get_health() <= DontDodgeTuning.MELEE_HEALTH - DontDodgeTuning.SPEAR_FORMATION_DAMAGE * DontDodgeTuning.SPEAR_FORMATION_PULSES)


func _validate_spear_formation_auto_aim(game: DontDodgeGame) -> void:
	var player: DontDodgePlayer = game.get_node("Player")
	game.set("_weapon_id", "battle_spear")
	game.set("_ultimate_id", "ult_spear_formation")
	game.call("_apply_weapon_loadout")
	player.global_position = DontDodgeTuning.ARENA_SIZE * 0.5
	player.set("_last_move_direction", Vector2.RIGHT)
	var nearest_target: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(120.0, 0.0))
	var marked_target: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.CHARGER, player.global_position + Vector2(0.0, -240.0))
	marked_target.set("_state", DontDodgeEnemy.State.WINDUP)
	marked_target.set("_windup_remaining", 0.4)
	game.call("_perform_spear_formation")
	var sequence: Array[Dictionary] = game.get("_weapon_ultimate_sequence")
	var telegraph: Dictionary = sequence[0]
	assert(nearest_target.is_combat_active())
	assert(telegraph["direction"].dot(Vector2.UP) > 0.99)
	var formation_line_start: Vector2 = telegraph["line_start"]
	var formation_line_end: Vector2 = telegraph["line_end"]
	assert(is_equal_approx(minf(formation_line_start.y, formation_line_end.y), DontDodgeTuning.PLAYER_RADIUS))
	assert(is_equal_approx(maxf(formation_line_start.y, formation_line_end.y), DontDodgeTuning.ARENA_SIZE.y - DontDodgeTuning.PLAYER_RADIUS))

	nearest_target.set("_state", DontDodgeEnemy.State.DEFEATED)
	marked_target.set("_state", DontDodgeEnemy.State.DEFEATED)
	var fallback_target: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(-140.0, 0.0))
	game.call("_perform_spear_formation")
	sequence = game.get("_weapon_ultimate_sequence")
	telegraph = sequence[0]
	assert(fallback_target.is_combat_active())
	assert(telegraph["direction"].dot(Vector2.LEFT) > 0.99)


func _validate_perfect_dodge_timing(game: DontDodgeGame) -> void:
	var player: DontDodgePlayer = game.get_node("Player")
	var stats_before: int = int(game.get_stats()["perfect_dodges"])
	game.call("_resolve_hazard_contact", "walking_contact")
	assert(int(game.get_stats()["perfect_dodges"]) == stats_before)
	player.set("_dash_remaining", DontDodgeTuning.DODGE_DURATION)
	player.set("_dash_elapsed", DontDodgeTuning.PERFECT_DODGE_WINDOW * 0.5)
	player.set("_perfect_registered_for_dash", false)
	game.call("_resolve_hazard_contact", "perfect_contact")
	assert(int(game.get_stats()["perfect_dodges"]) == stats_before + 1)
	player.set("_dash_remaining", DontDodgeTuning.DODGE_DURATION)
	player.set("_dash_elapsed", DontDodgeTuning.PERFECT_DODGE_WINDOW + 0.01)
	player.set("_perfect_registered_for_dash", false)
	game.call("_resolve_hazard_contact", "late_contact")
	assert(int(game.get_stats()["perfect_dodges"]) == stats_before + 1)


func _validate_visual_fallback_and_gameplay_isolation(game: DontDodgeGame) -> void:
	assert(game.get_node_or_null("CombatVisuals") != null)
	var player: DontDodgePlayer = game.get_node("Player")
	var player_visual: Node2D = player.get_node("Visual")
	assert(player_visual.call("get_visual_variant") == &"fallback")
	player_visual.call("set_visual_mapping", {DontDodgePlayer.VISUAL_TYPE_ID: {DontDodgePlayer.VISUAL_STATE_IDLE: &"player_idle"}})
	assert(player_visual.call("get_visual_variant") == &"player_idle")
	player_visual.call("set_visual_mapping", {})
	assert(player_visual.call("get_visual_variant") == &"fallback")
	var sound_events: Array[StringName] = []
	game.sound_event_requested.connect(func(event_id: StringName, _world_position: Vector2) -> void: sound_events.append(event_id))
	var enemy: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(100.0, 0.0))
	var enemy_visual: Node2D = enemy.get_node("Visual")
	assert(enemy.get_visual_type_id() == DontDodgeEnemy.VISUAL_TYPE_MELEE)
	assert(enemy.get_visual_state_id() == DontDodgeEnemy.VISUAL_STATE_CHASE)
	assert(enemy_visual.call("get_visual_variant") == &"fallback")
	enemy_visual.call("set_visual_mapping", {DontDodgeEnemy.VISUAL_TYPE_MELEE: {DontDodgeEnemy.VISUAL_STATE_CHASE: &"melee_chase"}})
	assert(enemy_visual.call("get_visual_variant") == &"melee_chase")
	enemy_visual.scale = Vector2(3.0, 3.0)
	assert(game.perform_attack_for_test())
	assert(enemy.get_health() <= 0) # Visual scale must not change the fixed focus range or damage.
	assert(sound_events.has(DontDodgeGame.SOUND_EVENT_PLAYER_ATTACK))
	assert(sound_events.has(DontDodgeGame.SOUND_EVENT_ENEMY_HIT))
	assert(sound_events.has(DontDodgeGame.SOUND_EVENT_ENEMY_DEFEATED))
	var projectile := DontDodgeProjectile.new()
	projectile.setup(player.global_position + Vector2(100.0, 0.0), player.global_position)
	game.add_child(projectile)
	var projectile_visual: Node2D = projectile.get_node("Visual")
	assert(projectile.get_visual_type_id() == DontDodgeProjectile.VISUAL_TYPE_ID)
	assert(projectile.get_visual_state_id() == DontDodgeProjectile.VISUAL_STATE_FLYING)
	assert(projectile_visual.call("get_visual_variant") == &"fallback")
	var heart: DontDodgeHeart = game.spawn_heart_for_test(player.global_position + Vector2(200.0, 0.0))
	assert(heart.get_node_or_null("Visual") != null)


func _validate_screen_feedback(game: DontDodgeGame) -> void:
	var screen_feedback: Node = game.get("_screen_feedback")
	assert(is_instance_valid(screen_feedback))
	var camera: Camera2D = screen_feedback.get_node("CombatCamera") as Camera2D
	var flash_layer: CanvasLayer = screen_feedback.get_node("ScreenFlashLayer") as CanvasLayer
	var ui_layer: CanvasLayer = game.get_node("CombatUILayer") as CanvasLayer
	assert(is_instance_valid(camera))
	assert(camera.position == DontDodgeTuning.ARENA_SIZE * 0.5)
	assert(flash_layer.layer < ui_layer.layer)
	screen_feedback.call("trigger_shake", 4.0, 0.08)
	assert(is_equal_approx(float(screen_feedback.call("get_active_shake_pixels")), 4.0))
	screen_feedback.call("trigger_shake", 12.0, 0.18)
	assert(is_equal_approx(float(screen_feedback.call("get_active_shake_pixels")), 12.0))
	screen_feedback.call("trigger_shake", 7.0, 0.12)
	assert(is_equal_approx(float(screen_feedback.call("get_active_shake_pixels")), 12.0))
	screen_feedback.call("_process", 0.01)
	assert(screen_feedback.call("get_camera_offset") != Vector2.ZERO)
	screen_feedback.call("_process", 1.0)
	game.call("_on_player_took_damage", 2)
	assert(is_equal_approx(float(screen_feedback.call("get_active_shake_pixels")), 4.0))
	assert(is_equal_approx(float(game.get("_hit_stop_remaining")), DontDodgeTuning.HIT_STOP_PLAYER_DAMAGE))
	game.call("_process", DontDodgeTuning.HIT_STOP_PLAYER_DAMAGE)
	screen_feedback.call("_process", 1.0)
	var elite: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.ELITE, Vector2(400.0, 300.0))
	game.call("_on_enemy_defeated", elite)
	assert(is_equal_approx(float(screen_feedback.call("get_active_shake_pixels")), 7.0))
	assert(float(screen_feedback.call("get_active_flash_alpha")) > 0.0)
	assert(is_equal_approx(float(game.get("_hit_stop_remaining")), DontDodgeTuning.HIT_STOP_ELITE_DEFEAT))
	screen_feedback.call("_process", 1.0)
	var normal: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, Vector2(460.0, 300.0))
	game.call("_on_enemy_defeated", normal)
	assert(is_equal_approx(float(screen_feedback.call("get_active_shake_pixels")), 0.0))
	var localization: Node = get_root().get_node("Localization")
	localization.call("set_locale", &"en", false)
	game.call("_show_feedback_key", &"feedback.title_challenge", [&"data.dagger.title"], 1.0)
	assert((game.get("_feedback_label") as Label).text == "CHALLENGE · Dagger")
	localization.call("set_locale", &"ko", false)
	assert((game.get("_feedback_label") as Label).text == "도전 · 단검")


func _validate_ui_input_and_terminal_reset(game: DontDodgeGame) -> void:
	var input_source: DontDodgeInputSource = game.get("_input_source")
	input_source.request_ui_attack()
	assert(input_source.read_command().attack_pressed)
	input_source.request_ui_dodge()
	assert(input_source.read_command().dodge_pressed)
	input_source.request_ui_negate()
	assert(input_source.read_command().negate_pressed)
	input_source.request_ui_ultimate()
	assert(input_source.read_command().ultimate_pressed)
	game.call("_open_manual_pause")
	game.call("_resume_manual_pause")
	input_source.request_ui_attack()
	game.call("_finish_run", &"result.clear", [DontDodgeTuning.WAVE_COUNT], "clear")
	assert(not input_source.read_command().attack_pressed)
	var end_panel: PanelContainer = game.get("_end_panel") as PanelContainer
	assert(end_panel.get_node("ResultMargin/ResultScroll/Contents/RestartButton").text == "다시 시작")
	assert(end_panel.get_node("ResultMargin/ResultScroll/Contents/ReturnToTitleButton").text == "로비로 가기")


func _validate_compact_survival_hud(game: DontDodgeGame) -> void:
	game.set("_elapsed", 12.4)
	game.set("_experience", 5)
	game.set("_experience_level", 1)
	game.call("_update_hud")
	var hud: Label = game.get("_hud")
	var timer_label: Label = game.get("_timer_label")
	var wave_status_label: Label = game.get("_wave_status_label")
	var xp_label: Label = game.get("_xp_label")
	var player_state_label: Label = game.get("_player_state_label")
	assert(hud.text == "웨이브 1 / 4")
	assert(timer_label.text == "01:18")
	assert(wave_status_label.text == "진행 중")
	assert(xp_label.text == "LV 1  ·  XP 5 / 19")
	assert(player_state_label.text == "♥♥♥")
	assert(not hud.text.contains("적 탄환"))
	assert(not hud.text.contains("DEF"))
	assert(not hud.text.contains("베기  피해"))
	assert(not hud.text.contains("강화  칼날"))
	var player: DontDodgePlayer = game.get_node("Player")
	assert(player.receive_damage())
	game.call("_update_hud")
	assert(player_state_label.text == "♥♥♡")

	game.set("_pause_mode", DontDodgeGame.PauseMode.UPGRADE)
	game.set("_waves_cleared", 1)
	game.call("_update_hud")
	assert(hud.text == "웨이브 1 / 4")
	assert(wave_status_label.text == "강화 선택")

	game.set("_pause_mode", DontDodgeGame.PauseMode.NONE)
	game.set("_state", DontDodgeGame.GameState.THREAT_GATE)
	game.set("_threat_gate_elapsed", 1.2)
	game.call("_update_hud")
	assert(hud.text == "웨이브 1 / 4")
	assert(wave_status_label.text == "정리 대기")

	game.set("_state", DontDodgeGame.GameState.FINAL_CLEANUP)
	game.call("_update_hud")
	assert(hud.text == "웨이브 1 / 4")
	assert(wave_status_label.text == "소탕 중")

	game.set("_state", DontDodgeGame.GameState.PLAYER_DEAD)
	game.call("_update_hud")
	assert(hud.text == "웨이브 1 / 4")
	assert(wave_status_label.text == "전투 불능")


func _validate_empty_negate_preserves_resource(game: DontDodgeGame) -> void:
	var defense: DefenseResource = game.get_defense_resource()
	var charges_before: int = defense.get_charges()
	game.call("_try_negate")
	assert(defense.get_charges() == charges_before)
	assert(game.get("_feedback_key") == &"feedback.no_negate_target")
	assert((game.get("_feedback_label") as Label).text == "무효화할 대상이 없습니다")
	var player: DontDodgePlayer = game.get_node("Player")
	var enemy: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.MELEE, player.global_position + Vector2(100.0, 0.0))
	game.call("_try_negate")
	assert(defense.get_charges() == charges_before - 1)
	assert(int(game.get("_stats")["negates"]) == 1)
	assert(int(game.get("_stats")["enemies_repulsed"]) == 1)
	assert(enemy.get("_knockback_remaining") > 0.0)

func _validate_gate_freezes_active_time(game: DontDodgeGame) -> void:
	var context: Dictionary = game.get("_pattern_contexts")[0]
	var blocker: DontDodgeEnemy = game.call("_spawn_enemy", DontDodgeEnemy.EnemyType.ELITE, Vector2(100.0, 100.0), {"pattern_id": "cut_tell_01", "pattern_instance_id": context["instance_id"], "role": "primary", "hazard_id": "gate_blocker"})
	game.set("_elapsed", 5.0)
	game.call("_process", 0.0)
	assert(game.get_game_state() == DontDodgeGame.GameState.THREAT_GATE)
	var active_at_gate: float = game.get("_elapsed")
	var defense: DefenseResource = game.get_defense_resource()
	assert(defense.consume())
	game.call("_process", 0.25)
	assert(is_equal_approx(float(game.get("_elapsed")), active_at_gate))
	assert(float(game.get("_time_metrics")["threat_gate_seconds"]) >= 0.25)
	blocker.receive_hit(99, Vector2.RIGHT, 0.0)
	game.call("_process", 0.0)
	assert(game.get_game_state() == DontDodgeGame.GameState.COMBAT)
	assert(int(game.get("_active_slot_index")) == 1)
	assert(is_equal_approx(float(game.get("_elapsed")), active_at_gate))


func _validate_cleanup_and_death(game: DontDodgeGame) -> void:
	game.set("_elapsed", 25.0)
	game.call("_process", 0.0)
	assert(game.get_game_state() == DontDodgeGame.GameState.COMBAT)
	var projectile := DontDodgeProjectile.new()
	var player: DontDodgePlayer = game.get_node("Player")
	projectile.setup(player.global_position + Vector2(100.0, 0.0), player.global_position + Vector2(900.0, 0.0))
	game.add_child(projectile)
	game.get("_projectiles").append(projectile)
	game.call("_process", DontDodgeTuning.PROJECTILE_CLEANUP_GRACE_SECONDS + 0.01)
	assert(projectile.is_queued_for_deletion())

	game.set("_state", DontDodgeGame.GameState.FINAL_CLEANUP)
	game.set("_elapsed", DontDodgeTuning.SESSION_DURATION)
	game.call("_on_player_took_damage", 0)
	assert(game.get_game_state() == DontDodgeGame.GameState.PLAYER_DEAD)
	game.call("_process", DontDodgeTuning.PLAYER_DEATH_PRESENTATION_SECONDS + 0.01)
	assert(bool(game.get("_ended")))
	assert(str(game.get("_outcome")) == "death")


func _validate_rewards_and_hearts(game: DontDodgeGame) -> void:
	assert(is_equal_approx(DontDodgeTuning.NEGATE_RADIUS, 230.0))
	assert(DontDodgeTuning.ULTIMATE_MAX == 84)
	var player: DontDodgePlayer = game.get_node("Player")
	game.call("_grant_ultimate", 16, "locked_validation")
	assert(int(game.get("_ultimate_charge")) == 0)
	game.set("_weapon_id", "battle_spear")
	game.set("_ultimate_id", "ult_spear_sky_pierce")
	game.call("_apply_weapon_loadout")
	game.call("_try_negate")
	assert(int(game.get("_ultimate_charge")) == 0)
	game.get_defense_resource().reset()
	for index: int in 4:
		var projectile := DontDodgeProjectile.new()
		projectile.setup(player.global_position + Vector2(100.0 + index * 10.0, 0.0), player.global_position)
		game.add_child(projectile)
		game.get("_projectiles").append(projectile)
	game.call("_try_negate")
	assert(int(game.get("_ultimate_charge")) == 6) # Projectile reward caps at +6 per E.
	game.set("_elapsed", 30.0)
	game.call("_spawn_due_hearts")
	assert(game.get("_hearts").size() == 1)
	var heart: DontDodgeHeart = game.get("_hearts")[0]
	assert(not heart.advance(DontDodgeTuning.HEART_LIFETIME_SECONDS + 0.01))


func _validate_pause_timer_policy(game: DontDodgeGame) -> void:
	var active_before: float = game.get("_elapsed")
	game.call("_open_manual_pause")
	assert(game.get_game_state() == DontDodgeGame.GameState.MANUAL_PAUSE)
	game.call("_process", 1.0)
	assert(is_equal_approx(float(game.get("_elapsed")), active_before))
	assert(float(game.get("_time_metrics")["manual_pause_seconds"]) >= 1.0)
	game.call("_resume_manual_pause")
	var defense: DefenseResource = game.get_defense_resource()
	assert(defense.consume())
	game.set("_attack_recovery_remaining", 1.0)
	game.call("_open_experience_upgrade", 1)
	assert(game.get_game_state() == DontDodgeGame.GameState.UPGRADE)
	game.call("_process", 1.0)
	assert(is_equal_approx(float(game.get("_attack_recovery_remaining")), 1.0))
	assert(defense.get_charges() == 1)
	assert(game.select_upgrade_for_test("weapon_dagger"))
	assert(game.get_game_state() == DontDodgeGame.GameState.COMBAT)


func _validate_ultimate_radius_and_final_margin(game: DontDodgeGame) -> void:
	var player: DontDodgePlayer = game.get_node("Player")
	game.call("_open_experience_upgrade", 1)
	assert(game.select_upgrade_for_test("weapon_guardian_mace"))
	game.call("_open_experience_upgrade", 2)
	assert(game.select_upgrade_for_test("tech_mace_counter"))
	game.call("_open_experience_upgrade", 3)
	assert(game.select_upgrade_for_test("ult_mace_ground_suppression"))
	var charger: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.CHARGER, player.global_position + Vector2(220.0, 0.0))
	var ranged: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.RANGED, player.global_position + Vector2(300.0, 0.0))
	var elite: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.ELITE, player.global_position + Vector2(180.0, 0.0))
	elite.set("_state", DontDodgeEnemy.State.WINDUP)
	var volley: DontDodgeEnemy = game.spawn_enemy_for_test(DontDodgeEnemy.EnemyType.VOLLEY, player.global_position + Vector2(380.0, 0.0))
	game.set("_ultimate_charge", DontDodgeTuning.ULTIMATE_MAX)
	game.call("_try_ultimate")
	assert(charger.get_health() == DontDodgeTuning.CHARGER_HEALTH)
	assert(ranged.get_health() == DontDodgeTuning.RANGED_HEALTH)
	game.call("_process", DontDodgeTuning.ULTIMATE_FREEZE_DURATION)
	game.call("_process", 0.0)
	game.call("_process", DontDodgeTuning.MACE_GROUND_SUPPRESSION_TELEGRAPH + 0.01)
	assert(charger.get_health() == DontDodgeTuning.CHARGER_HEALTH - DontDodgeTuning.ULTIMATE_ELITE_DAMAGE)
	assert(ranged.get_health() <= 0)
	assert(elite.get_health() == DontDodgeTuning.ELITE_HEALTH - DontDodgeTuning.ULTIMATE_ELITE_DAMAGE)
	assert(elite.get_visual_state_id() == DontDodgeEnemy.VISUAL_STATE_INTERRUPTED)
	assert(volley.get_health() == DontDodgeTuning.VOLLEY_HEALTH)
	assert(is_equal_approx(float(game.get("_ultimate_freeze_remaining")), 0.0))
	assert(is_equal_approx(float(game.get("_hit_stop_remaining")), DontDodgeTuning.MACE_ULTIMATE_HIT_STOP))
	var screen_feedback: Node = game.get("_screen_feedback")
	assert(is_equal_approx(float(screen_feedback.call("get_active_shake_pixels")), 12.0))
