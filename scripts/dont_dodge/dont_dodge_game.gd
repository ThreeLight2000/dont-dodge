class_name DontDodgeGame
extends Node2D

const INPUT_SOURCE_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_input_source.gd")
const DEFENSE_RESOURCE_SCRIPT: Script = preload("res://scripts/dont_dodge/defense_resource.gd")
const ENEMY_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_enemy.gd")
const HEART_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_heart.gd")
const EXPERIENCE_ORB_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_experience_orb.gd")
const PROJECTILE_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_projectile.gd")
const ACTION_PROGRESS_OVERLAY_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_action_progress_overlay.gd")
const PATTERN_DATA_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_pattern_data.gd")
const CHALLENGE_DATA_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_challenge_data.gd")
const LOADOUT_DATA_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_loadout_data.gd")
const COMBAT_VISUALS_SCRIPT: Script = preload("res://scripts/dont_dodge/visuals/dont_dodge_combat_visuals.gd")
const SCREEN_FEEDBACK_SCRIPT: Script = preload("res://scripts/dont_dodge/visuals/dont_dodge_screen_feedback.gd")
const DUNGEON_BACKDROP_SCRIPT: Script = preload("res://scripts/dont_dodge/visuals/dont_dodge_dungeon_backdrop.gd")
const ASSET_CATALOG: Script = preload("res://scripts/dont_dodge/dont_dodge_asset_catalog.gd")
const PIXEL_ICON_SCRIPT: Script = preload("res://scripts/dont_dodge/visuals/dont_dodge_pixel_icon.gd")
const LOGO_TEXTURE_PATH: String = "res://assets/sprites/dont_dodge_logo.png"
const UI_FONT: Font = preload("res://assets/fonts/NotoSansKR-Regular.otf")
const SETTINGS_PATH: String = "user://dont_dodge_settings.cfg"
const SETTINGS_TUTORIAL_SECTION: String = "tutorial"
const SETTINGS_GUIDE_COMPLETED_KEY: String = "guide_completed"
const SETTINGS_COMBAT_HINTS_VERSION_KEY: String = "combat_hints_version"
const COMBAT_HINTS_VERSION: int = 1
const COMBAT_HINT_DURATION: float = 5.0
const COMBAT_HINT_MIN_DISPLAY_DURATION: float = 1.25
const MAIN_SCENE_PATH: String = "res://scenes/dont_dodge/dont_dodge.tscn"
const TRAINING_SCENE_PATH: String = "res://scenes/dont_dodge/training_arena.tscn"
const UI_MODAL_SAFE_MARGIN: float = 24.0
const UI_CARD_TWO_COLUMN_BREAKPOINT: float = 800.0
const UI_CARD_THREE_COLUMN_BREAKPOINT: float = 1280.0

@export var launch_mode: StringName = &"title"

signal sound_event_requested(event_id: StringName, world_position: Vector2)

enum PauseMode { NONE, MANUAL, UPGRADE }
enum GameState { COMBAT, THREAT_GATE, UPGRADE, FINAL_CLEANUP, MANUAL_PAUSE, PLAYER_DEAD, RESULT, CHALLENGE_REVEAL }
enum UpgradeStage { NONE, WEAPON, TECHNIQUE, ULTIMATE }
enum CombatHint { NONE, MELEE, NEGATE, DODGE, DEFENSE, ULTIMATE }
const SOUND_EVENT_PLAYER_ATTACK: StringName = &"player_attack"
const SOUND_EVENT_PLAYER_HIT: StringName = &"player_hit"
const SOUND_EVENT_ENEMY_ATTACK: StringName = &"enemy_attack"
const SOUND_EVENT_ENEMY_HIT: StringName = &"enemy_hit"
const SOUND_EVENT_ENEMY_DEFEATED: StringName = &"enemy_defeated"
const SOUND_EVENT_WAVE_STARTED: StringName = &"wave_started"
const SOUND_EVENT_PERFECT_DODGE: StringName = &"perfect_dodge"
const SOUND_EVENT_ULTIMATE: StringName = &"ultimate"
const SOUND_EVENT_GAME_CLEAR: StringName = &"game_clear"
const SOUND_EVENT_GAME_OVER: StringName = &"game_over"
const HUD_REFRESH_INTERVAL: float = 0.1

static var _start_game_after_reload: bool = false
static var _start_challenge_after_reload: bool = false

@onready var _player: DontDodgePlayer = $Player

var _input_source: DontDodgeInputSource
var _defense: DefenseResource
var _enemies: Array[DontDodgeEnemy] = []
var _hearts: Array[DontDodgeHeart] = []
var _experience_orbs: Array[DontDodgeExperienceOrb] = []
var _projectiles: Array[DontDodgeProjectile] = []
var _spawn_schedule: Array[Dictionary] = []
var _next_spawn_index: int = 0
var _timeline: Array[Dictionary] = []
var _active_slot_index: int = 0
var _pattern_contexts: Dictionary = {}
var _spawn_warnings: Array[Dictionary] = []
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _challenge_random: RandomNumberGenerator = RandomNumberGenerator.new()
var _elapsed: float = 0.0
var _state: GameState = GameState.COMBAT
var _state_before_manual_pause: GameState = GameState.COMBAT
var _cleanup_elapsed: float = 0.0
var _threat_gate_elapsed: float = 0.0
var _death_presentation_remaining: float = 0.0
var _last_hazard_id: String = ""
var _run_seed: int = 0
var _pattern_seed: int = 0
var _challenge_roll_seed: int = 0
var _mode: StringName = &"normal"
var _challenge_debuff_id: StringName = &""
var _challenge_debuff: Dictionary = {}
var _challenge_roulette_elapsed: float = 0.0
var _challenge_roulette_index: int = 0
var _challenge_roulette_finished: bool = false
var _outcome: String = ""
var _death_record: Dictionary = {}
var _time_metrics: Dictionary = {
	"scheduled_combat_seconds": DontDodgeTuning.SESSION_DURATION,
	"active_combat_seconds": 0.0,
	"threat_gate_seconds": 0.0,
	"cleanup_seconds": 0.0,
	"upgrade_seconds": 0.0,
	"unpaused_session_seconds": 0.0,
	"manual_pause_seconds": 0.0,
	"total_wall_seconds": 0.0,
	"app_inactive_seconds": 0.0,
}
var _pattern_events: Array[Dictionary] = []
var _actual_spawn_events: Array[Dictionary] = []
var _input_events: Array[Dictionary] = []
var _state_events: Array[Dictionary] = []
var _attack_recovery_remaining: float = 0.0
var _focus_attack_direction: Vector2 = Vector2.RIGHT
var _attack_sequence: int = 0
var _break_cooldown_remaining: float = 0.0
var _guard_remaining: float = 0.0
var _guard_direction: Vector2 = Vector2.RIGHT
var _guard_successful: bool = false
var _mace_counter_remaining: float = 0.0
var _ghost_step_remaining: float = 0.0
var _damage_guard_remaining: float = 0.0
var _spear_breakthrough_remaining: float = 0.0
var _spear_radial_attack_ready: bool = false
var _spear_bullet_cut_remaining: float = 0.0
var _spear_edge_pressure_remaining: float = 0.0
var _spear_edge_pressure_target: DontDodgeEnemy
var _spear_dodge_contact_registered: bool = false
var _ultimate_charge: int = 0
var _ultimate_freeze_remaining: float = 0.0
var _hit_stop_remaining: float = 0.0
var _dagger_ultimate_sequence: Array[Dictionary] = []
var _dagger_ultimate_sequence_index: int = -1
var _dagger_ultimate_phase_elapsed: float = 0.0
var _dagger_ultimate_sequence_pending_start: bool = false
var _dagger_ultimate_completion_feedback_key: StringName = &""
var _dagger_ultimate_completion_feedback_arguments: Array = []
var _weapon_ultimate_sequence: Array[Dictionary] = []
var _weapon_ultimate_sequence_index: int = -1
var _weapon_ultimate_phase_elapsed: float = 0.0
var _weapon_ultimate_sequence_pending_start: bool = false
var _weapon_ultimate_completion_feedback_key: StringName = &""
var _weapon_ultimate_completion_feedback_arguments: Array = []
var _next_heart_spawn_at: float = DontDodgeTuning.HEART_SPAWN_INTERVAL
var _ended: bool = false
var _pause_mode: PauseMode = PauseMode.NONE
var _waves_cleared: int = 0
var _waves_reached: int = 0
var _experience: int = 0
var _experience_level: int = 0
var _final_relay_cycle: int = 0
var _upgrade_cursor: int = 0
var _upgrade_stage: UpgradeStage = UpgradeStage.NONE
var _upgrade_options: Array[Dictionary] = []
var _weapon_id: String = ""
var _technique_id: String = ""
var _ultimate_id: String = ""
var _upgrade_history: Array[Dictionary] = []
var _upgrade_result_remaining: float = 0.0
var _end_reason_key: StringName = &""
var _end_reason_arguments: Array = []
var _feedback_key: StringName = &""
var _feedback_arguments: Array = []
var _feedback_remaining: float = 0.0
var _combat_hints_enabled: bool = false
var _combat_hint_active: CombatHint = CombatHint.NONE
var _combat_hint_remaining: float = 0.0
var _combat_hint_displayed_elapsed: float = 0.0
var _combat_hint_queue: Array[int] = []
var _combat_hint_seen: Dictionary = {}
var _combat_hint_action_baseline: int = 0
var _hud_refresh_elapsed: float = HUD_REFRESH_INTERVAL
var _hud_refresh_requested: bool = true
var _last_hud_text: String = ""
var _last_action_defense_charges: int = -1
var _stats: Dictionary = {
	"kills": 0,
	"focus_attacks": 0,
	"focus_hits": 0,
	"focus_misses": 0,
	"attack_recovery_rejections": 0,
	"dodges": 0,
	"negates": 0,
	"perfect_dodges": 0,
	"interrupts": 0,
	"enemies_repulsed": 0,
	"projectiles_erased": 0,
	"heart_spawns": 0,
	"hearts_absorbed": 0,
	"elite_heart_drops": 0,
	"experience_spawned": 0,
	"experience_collected": 0,
	"experience_levels": 0,
	"hits_taken": 0,
	"ultimates": 0,
}
var _ultimate_sources: Dictionary = {}
var _started: bool = false
var _title_layer: CanvasLayer
var _ui_theme: Theme = Theme.new()
var _hud: Label
var _timer_label: Label
var _wave_status_label: Label
var _build_hud_label: Label
var _wave_segments: Array[PanelContainer] = []
var _wave_segment_future_style: StyleBoxFlat
var _wave_segment_active_style: StyleBoxFlat
var _wave_segment_completed_style: StyleBoxFlat
var _xp_bar: ProgressBar
var _xp_label: Label
var _player_state_label: Label
var _feedback_label: Label
var _combat_hint_panel: PanelContainer
var _combat_hint_label: Label
var _combat_hint_skip_button: Button
var _end_panel: PanelContainer
var _pause_button: Button
var _pause_backdrop: ColorRect
var _pause_panel: PanelContainer
var _pause_resume_button: Button
var _pause_guide_button: Button
var _pause_challenge_label: Label
var _pause_bgm_button: Button
var _pause_sfx_button: Button
var _pause_main_button: Button
var _pause_language_option: OptionButton
var _title_layout_switcher: VBoxContainer
var _title_wide_layout: HBoxContainer
var _title_compact_layout: VBoxContainer
var _title_left_column: VBoxContainer
var _title_right_column: VBoxContainer
var _title_layout_is_wide: bool = false
var _title_bgm_button: Button
var _title_sfx_button: Button
var _title_training_button: Button
var _title_challenge_button: Button
var _title_guide_button: Button
var _title_language_option: OptionButton
var _upgrade_panel: PanelContainer
var _upgrade_title: Label
var _upgrade_cards: Array[Button] = []
var _upgrade_card_grid: GridContainer
var _upgrade_result_panel: PanelContainer
var _upgrade_result_title: Label
var _upgrade_result_detail: Label
var _upgrade_result_option: Dictionary = {}
var _attack_button: Button
var _dodge_button: Button
var _negate_button: Button
var _ultimate_button: Button
var _action_tooltip: PanelContainer
var _action_tooltip_label: Label
var _tooltip_source: Button
var _challenge_hud_label: Label
var _guide_panel: PanelContainer
var _guide_start_button: Button
var _guide_card_grid: GridContainer
var _guide_return_action: Callable
var _guide_mark_complete: bool = false
var _challenge_roulette_panel: PanelContainer
var _challenge_roulette_cards: Array[Button] = []
var _challenge_card_grid: GridContainer
var _challenge_start_button: Button
var _challenge_result_label: Label
var _combat_visuals: Node2D
var _dungeon_backdrop: Node2D
var _screen_feedback: Node
var _training_setup_layer: CanvasLayer
var _training_weapon_grid: GridContainer
var _training_level_grid: GridContainer
var _training_technique_grid: GridContainer
var _training_ultimate_grid: GridContainer
var _training_weapon_cards: Array[Button] = []
var _training_level_cards: Array[Button] = []
var _training_technique_cards: Array[Button] = []
var _training_ultimate_cards: Array[Button] = []
var _training_weapon_id: String = ""
var _training_technique_id: String = ""
var _training_ultimate_id: String = ""
var _training_starting_level: int = 3
var _training_summary_panel: PanelContainer
var _training_summary_title: Label
var _training_summary_icon: Control
var _training_summary_label: Label
var _training_back_button: Button
var _training_start_button: Button
var _training_clear_button: Button
var _training_reset_button: Button
var _training_exit_button: Button
var _training_hover_modal: PanelContainer
var _training_hover_modal_icon: Control
var _training_hover_modal_role: Label
var _training_hover_modal_title: Label
var _training_hover_modal_description: Label
var _training_hover_modal_detail: Label
var _training_hover_modal_lock: Label
var _training_hover_modal_source: Button
var _training_form: GridContainer
var _training_controls_panel: PanelContainer
var _training_enemy_grid: GridContainer
var _responsive_modal_panels: Array[PanelContainer] = []
var _training_spawn_index: int = 0


func _ready() -> void:
	Engine.max_fps = 60
	_ui_theme.default_font = UI_FONT
	_ui_theme.default_font_size = 16
	_ui_theme.set_stylebox("normal", &"Button", _make_pixel_panel_style(Color(0.14, 0.11, 0.06, 0.98), Color(0.62, 0.5, 0.28, 0.96), 3))
	_ui_theme.set_stylebox("hover", &"Button", _make_pixel_panel_style(Color(0.28, 0.2, 0.08, 1.0), Color(1.0, 0.8, 0.34, 1.0), 3))
	_ui_theme.set_stylebox("pressed", &"Button", _make_pixel_panel_style(Color(0.36, 0.24, 0.06, 1.0), Color(1.0, 0.92, 0.54, 1.0), 4))
	_ui_theme.set_stylebox("disabled", &"Button", _make_pixel_panel_style(Color(0.07, 0.06, 0.04, 0.94), Color(0.28, 0.24, 0.15, 0.86), 3))
	_ui_theme.set_stylebox("focus", &"Button", _make_ui_focus_style())
	_ui_theme.set_color("font_color", &"Button", Color(1.0, 0.92, 0.7))
	_get_bgm_controller().connect(&"bgm_enabled_changed", _on_bgm_enabled_changed)
	_get_sfx_controller().connect(&"sfx_enabled_changed", _on_sfx_enabled_changed)
	_get_localization_controller().connect("locale_changed", _on_locale_changed)
	sound_event_requested.connect(_on_sound_event_requested)
	_player.visible = false
	if launch_mode == &"training":
		_start_game_after_reload = false
		_start_challenge_after_reload = false
		call_deferred("_create_training_setup")
	elif _start_game_after_reload:
		_start_game_after_reload = false
		var reload_mode: StringName = &"challenge" if _start_challenge_after_reload else &"normal"
		_start_challenge_after_reload = false
		call_deferred("_start_game", reload_mode)
	else:
		_create_title_screen()


func _get_localization_controller() -> Node:
	return get_node("/root/Localization")


func _tr(key: StringName, arguments: Array = []) -> String:
	return str(_get_localization_controller().call("translate", key, arguments))


func _localized_data_text(data: Dictionary, field: StringName, fallback_key: StringName) -> String:
	return _tr(_localized_data_key(data, field, fallback_key))


func _localized_data_key(data: Dictionary, field: StringName, fallback_key: StringName) -> StringName:
	return StringName(str(data.get(field, str(fallback_key))))


func _resolve_localized_arguments(arguments: Array) -> Array:
	var resolved: Array = []
	for argument: Variant in arguments:
		if argument is StringName and not StringName(argument).is_empty():
			resolved.append(_tr(StringName(argument)))
		else:
			resolved.append(argument)
	return resolved


func _set_localized_text(control: Control, key: StringName, arguments: Array = []) -> void:
	control.set_meta(&"localization_text_key", key)
	control.set_meta(&"localization_text_arguments", arguments.duplicate())
	_set_control_text(control, _tr(key, arguments))


func _set_localized_tooltip(control: Control, key: StringName, arguments: Array = []) -> void:
	control.set_meta(&"localization_tooltip_key", key)
	control.set_meta(&"localization_tooltip_arguments", arguments.duplicate())
	control.tooltip_text = _tr(key, arguments)


func _set_control_text(control: Control, text_value: String) -> void:
	if control is Label:
		(control as Label).text = text_value
	elif control is Button:
		(control as Button).text = text_value


func _refresh_localized_nodes(root: Node) -> void:
	for node: Node in root.get_children():
		if node is Control:
			var control := node as Control
			var text_key: StringName = StringName(str(control.get_meta(&"localization_text_key", "")))
			if not text_key.is_empty():
				_set_control_text(control, _tr(text_key, control.get_meta(&"localization_text_arguments", [])))
			var tooltip_key: StringName = StringName(str(control.get_meta(&"localization_tooltip_key", "")))
			if not tooltip_key.is_empty():
				control.tooltip_text = _tr(tooltip_key, control.get_meta(&"localization_tooltip_arguments", []))
		_refresh_localized_nodes(node)


func _make_language_option(name_value: StringName) -> OptionButton:
	var option := OptionButton.new()
	option.name = str(name_value)
	option.custom_minimum_size = Vector2(160.0, 36.0)
	option.item_selected.connect(_on_language_option_selected.bind(option))
	_refresh_language_option(option)
	return option


func _refresh_language_option(option: OptionButton) -> void:
	if not is_instance_valid(option):
		return
	var current_locale: StringName = StringName(str(_get_localization_controller().call("current_locale")))
	option.clear()
	var supported_locales: Array[StringName] = _get_localization_controller().call("get_supported_locales")
	for locale: StringName in supported_locales:
		var key: StringName = &"language.ko" if locale == &"ko" else &"language.en"
		var index: int = option.item_count
		option.add_item(_tr(key))
		option.set_item_metadata(index, str(locale))
		if locale == current_locale:
			option.select(index)


func _refresh_language_options() -> void:
	if is_instance_valid(_title_language_option):
		_refresh_language_option(_title_language_option)
	if is_instance_valid(_pause_language_option):
		_refresh_language_option(_pause_language_option)


func _on_language_option_selected(index: int, option: OptionButton) -> void:
	if index < 0 or index >= option.item_count:
		return
	_get_localization_controller().call("set_locale", StringName(str(option.get_item_metadata(index))))


func _on_locale_changed(_locale: StringName) -> void:
	_refresh_localized_nodes(self)
	_refresh_language_options()
	_refresh_audio_buttons()
	_refresh_training_option_labels()
	_refresh_training_tree_options()
	_update_training_summary()
	_refresh_challenge_cards_text()
	if is_instance_valid(_pause_challenge_label):
		_pause_challenge_label.text = _tr(&"pause.challenge", [_localized_data_text(_challenge_debuff, &"title_key", &"hud.challenge_ready")]) if _mode == &"challenge" else ""
	_refresh_upgrade_title()
	_refresh_upgrade_cards()
	_refresh_upgrade_result()
	_refresh_survival_hud()
	_last_action_defense_charges = -1
	_update_action_controls()
	_refresh_feedback_text()
	_refresh_end_panel()


func _on_start_requested(mode: StringName) -> void:
	if _is_guide_completed():
		_start_game(mode)
		return
	_show_title_guide(mode)


func _start_game(mode: StringName = &"normal") -> void:
	if _started:
		return
	_get_bgm_controller().call("activate_from_user_input")
	_get_sfx_controller().call("activate_from_user_input")
	_get_sfx_controller().call("play_ui")
	_started = true
	_mode = mode
	_challenge_debuff_id = &""
	_challenge_debuff = {}
	_challenge_roulette_elapsed = 0.0
	_challenge_roulette_index = 0
	_challenge_roulette_finished = false
	if is_instance_valid(_title_layer):
		_title_layer.visible = false
		_title_layer.queue_free()
	_title_language_option = null
	_title_bgm_button = null
	_title_sfx_button = null
	if is_instance_valid(_training_setup_layer):
		_training_setup_layer.visible = false
		_training_setup_layer.queue_free()
	_player.visible = true
	_random.randomize()
	_run_seed = _random.randi()
	_pattern_seed = _random.randi()
	_random.seed = _pattern_seed
	if _mode == &"challenge":
		_select_challenge_debuff()
	_input_source = INPUT_SOURCE_SCRIPT.new()
	add_child(_input_source)
	_create_combat_visuals()
	_defense = DEFENSE_RESOURCE_SCRIPT.new(_get_challenge_defense_recovery_seconds())
	_player.global_position = DontDodgeTuning.ARENA_SIZE * 0.5
	_player.took_damage.connect(_on_player_took_damage)
	_player.dodge_finished.connect(_on_player_dodge_finished)
	_waves_reached = 1
	if _mode == &"training":
		_timeline.clear()
		_spawn_schedule.clear()
		_active_slot_index = -1
	else:
		var pattern_data: Variant = PATTERN_DATA_SCRIPT.new()
		_timeline = pattern_data.build_timeline()
		_build_spawn_schedule()
	if _mode == &"training":
		_apply_weapon_loadout()
	_create_ui()
	if _mode == &"training":
		_begin_training_combat()
	elif _mode == &"challenge":
		_record_state(GameState.CHALLENGE_REVEAL, "challenge_roulette")
		_show_challenge_roulette()
	else:
		_begin_combat()
	_sync_combat_visuals()


func _begin_combat() -> void:
	_record_state(GameState.COMBAT, "run_started")
	_start_slot(0)
	_start_combat_hints_if_needed()
	if _mode == &"challenge":
		_show_feedback_key(&"feedback.title_challenge", [_localized_data_key(_challenge_debuff, &"title_key", &"hud.challenge_ready")], 1.5)
	else:
		_show_feedback_key(&"feedback.title_normal", [], 1.5)
	_emit_sound_event(SOUND_EVENT_WAVE_STARTED, _player.global_position)
	_update_hud()
	_sync_combat_visuals()


func _begin_training_combat() -> void:
	_record_state(GameState.COMBAT, "training_started")
	_show_feedback_key(&"feedback.training", [], 1.5)
	_emit_sound_event(SOUND_EVENT_WAVE_STARTED, _player.global_position)
	_update_hud()
	_sync_combat_visuals()


func _is_combat_hints_completed() -> bool:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return false
	return int(settings.get_value(SETTINGS_TUTORIAL_SECTION, SETTINGS_COMBAT_HINTS_VERSION_KEY, 0)) >= COMBAT_HINTS_VERSION


func _set_combat_hints_completed() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		settings = ConfigFile.new()
	settings.set_value(SETTINGS_TUTORIAL_SECTION, SETTINGS_COMBAT_HINTS_VERSION_KEY, COMBAT_HINTS_VERSION)
	if settings.save(SETTINGS_PATH) != OK:
		push_warning("Could not save DON’T DODGE combat hint setting.")


func _start_combat_hints_if_needed() -> void:
	_combat_hints_enabled = false
	_combat_hint_active = CombatHint.NONE
	_combat_hint_remaining = 0.0
	_combat_hint_displayed_elapsed = 0.0
	_combat_hint_queue.clear()
	_combat_hint_seen.clear()
	if _mode != &"normal" or _is_combat_hints_completed():
		return
	_combat_hints_enabled = true
	_set_combat_hints_completed()


func _update_combat_hints(delta: float) -> void:
	if not _combat_hints_enabled or _mode != &"normal" or _state != GameState.COMBAT:
		return
	_detect_combat_hint_triggers()
	if _combat_hint_active == CombatHint.NONE:
		_show_next_combat_hint()
		return
	_combat_hint_displayed_elapsed += delta
	if _combat_hint_action_succeeded():
		if _combat_hint_displayed_elapsed >= COMBAT_HINT_MIN_DISPLAY_DURATION:
			_complete_combat_hint()
			return
	_combat_hint_remaining = maxf(0.0, _combat_hint_remaining - delta)
	if _combat_hint_remaining <= 0.0:
		_complete_combat_hint()


func _detect_combat_hint_triggers() -> void:
	var close_enemy_count: int = 0
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy.is_combat_active():
			continue
		if enemy.get_enemy_type() == DontDodgeEnemy.EnemyType.MELEE and enemy.is_winding_up():
			_queue_combat_hint(CombatHint.MELEE)
		if enemy.is_charge_counterable():
			_queue_combat_hint(CombatHint.DODGE)
		if enemy.global_position.distance_to(_player.global_position) <= DontDodgeTuning.NEGATE_RADIUS:
			close_enemy_count += 1
	if close_enemy_count >= 2:
		_queue_combat_hint(CombatHint.NEGATE)
	if not _ultimate_id.is_empty() and _experience_level >= 3:
		_queue_combat_hint(CombatHint.ULTIMATE)
	for projectile: DontDodgeProjectile in _projectiles:
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion() and not projectile.is_reflected():
			if projectile.global_position.distance_to(_player.global_position) <= DontDodgeTuning.NEGATE_RADIUS:
				_queue_combat_hint(CombatHint.NEGATE)


func _queue_combat_hint(hint: CombatHint, start_immediately: bool = true) -> void:
	if not _combat_hints_enabled or hint == CombatHint.NONE:
		return
	var hint_id: int = int(hint)
	if _combat_hint_seen.has(hint_id):
		return
	_combat_hint_seen[hint_id] = true
	_combat_hint_queue.append(hint_id)
	if start_immediately and _combat_hint_active == CombatHint.NONE:
		_show_next_combat_hint()


func _show_next_combat_hint() -> void:
	if not _combat_hints_enabled or _combat_hint_active != CombatHint.NONE:
		return
	while not _combat_hint_queue.is_empty():
		_combat_hint_active = int(_combat_hint_queue.pop_front())
		_combat_hint_remaining = COMBAT_HINT_DURATION
		_combat_hint_displayed_elapsed = 0.0
		_combat_hint_action_baseline = _get_combat_hint_action_value(_combat_hint_active)
		if is_instance_valid(_combat_hint_label):
			_set_localized_text(_combat_hint_label, _get_combat_hint_key(_combat_hint_active))
		if is_instance_valid(_combat_hint_panel):
			_combat_hint_panel.visible = true
		return


func _complete_combat_hint() -> void:
	var completed_hint: CombatHint = _combat_hint_active
	_combat_hint_active = CombatHint.NONE
	_combat_hint_remaining = 0.0
	_combat_hint_displayed_elapsed = 0.0
	_combat_hint_action_baseline = 0
	_hide_combat_hint_panel()
	if completed_hint == CombatHint.DODGE or completed_hint == CombatHint.NEGATE:
		_queue_combat_hint(CombatHint.DEFENSE, false)
	_show_next_combat_hint()


func _skip_combat_hints() -> void:
	if not _combat_hints_enabled:
		return
	_set_combat_hints_completed()
	_combat_hints_enabled = false
	_combat_hint_active = CombatHint.NONE
	_combat_hint_remaining = 0.0
	_combat_hint_displayed_elapsed = 0.0
	_combat_hint_queue.clear()
	_combat_hint_seen.clear()
	_hide_combat_hint_panel()


func _hide_combat_hint_panel() -> void:
	if is_instance_valid(_combat_hint_panel):
		_combat_hint_panel.visible = false


func _combat_hint_action_succeeded() -> bool:
	if _combat_hint_active == CombatHint.DEFENSE:
		return false
	return _get_combat_hint_action_value(_combat_hint_active) > _combat_hint_action_baseline


func _get_combat_hint_action_value(hint: CombatHint) -> int:
	match hint:
		CombatHint.MELEE:
			return int(_stats["focus_hits"])
		CombatHint.NEGATE:
			return int(_stats["negates"])
		CombatHint.DODGE:
			return int(_stats["dodges"])
		CombatHint.ULTIMATE:
			return int(_stats["ultimates"])
		_:
			return 0


func _get_combat_hint_key(hint: CombatHint) -> StringName:
	match hint:
		CombatHint.MELEE:
			return &"tutorial.hint_melee"
		CombatHint.NEGATE:
			return &"tutorial.hint_negate"
		CombatHint.DODGE:
			return &"tutorial.hint_dodge"
		CombatHint.DEFENSE:
			return &"tutorial.hint_defense"
		CombatHint.ULTIMATE:
			return &"tutorial.hint_ultimate"
		_:
			return &"tutorial.hint_melee"


func _select_challenge_debuff() -> void:
	var pool: Array[Dictionary] = CHALLENGE_DATA_SCRIPT.get_pool()
	if pool.is_empty():
		return
	_challenge_roll_seed = _run_seed
	_challenge_random.seed = _challenge_roll_seed
	var selected_index: int = _challenge_random.randi_range(0, pool.size() - 1)
	_challenge_debuff = pool[selected_index].duplicate(true)
	_challenge_debuff_id = _challenge_debuff["id"]


func _is_challenge_debuff(debuff_id: StringName) -> bool:
	return _mode == &"challenge" and _challenge_debuff_id == debuff_id


func _get_challenge_defense_recovery_seconds() -> float:
	return float(_challenge_debuff.get("defense_recovery_seconds", DontDodgeTuning.DEFENSE_RECOVERY_SECONDS))


func _get_challenge_ultimate_amount(amount: int) -> int:
	if amount <= 0:
		return 0
	var multiplier: float = float(_challenge_debuff.get("ultimate_gain_multiplier", 1.0)) if _mode == &"challenge" else 1.0
	return maxi(1, floori(float(amount) * multiplier))


func _challenge_disables_hearts() -> bool:
	return _mode == &"challenge" and bool(_challenge_debuff.get("disable_hearts", false))


func _get_challenge_volley_bonus() -> int:
	return int(_challenge_debuff.get("volley_projectile_bonus", 0)) if _mode == &"challenge" else 0


func _process(delta: float) -> void:
	if not _started or _ended:
		return
	if _state == GameState.CHALLENGE_REVEAL:
		_update_challenge_roulette(delta)
		_update_hud(delta, false)
		_sync_combat_visuals()
		return
	_account_session_time(delta)
	if _state == GameState.MANUAL_PAUSE:
		_update_hud(delta, false)
		_sync_combat_visuals()
		return
	if _state == GameState.UPGRADE:
		_update_upgrade_result(delta)
		_update_hud(delta, false)
		_sync_combat_visuals()
		return
	if _state == GameState.PLAYER_DEAD:
		_hide_combat_hint_panel()
		_update_player_death(delta)
		_update_hud(delta, false)
		_sync_combat_visuals()
		return
	_update_visual_timers(delta)
	if _is_gameplay_state():
		_process_gameplay(delta)
	_update_hud(delta, false)
	_sync_combat_visuals()


func _process_gameplay(delta: float) -> void:
	if _hit_stop_remaining > 0.0:
		_hit_stop_remaining = maxf(0.0, _hit_stop_remaining - delta)
		_ultimate_freeze_remaining = maxf(0.0, _ultimate_freeze_remaining - delta)
		_update_combat_state()
		return
	if not _dagger_ultimate_sequence.is_empty():
		if _dagger_ultimate_sequence_pending_start:
			_dagger_ultimate_sequence_pending_start = false
			_begin_dagger_ultimate_phase()
			return
		_update_dagger_ultimate_sequence(delta)
		return
	if not _weapon_ultimate_sequence.is_empty():
		if _weapon_ultimate_sequence_pending_start:
			_weapon_ultimate_sequence_pending_start = false
			_begin_weapon_ultimate_phase()
			return
		_update_weapon_ultimate_sequence(delta)
		return
	_attack_recovery_remaining = maxf(0.0, _attack_recovery_remaining - delta)
	_break_cooldown_remaining = maxf(0.0, _break_cooldown_remaining - delta)
	_guard_remaining = maxf(0.0, _guard_remaining - delta)
	_mace_counter_remaining = maxf(0.0, _mace_counter_remaining - delta)
	_spear_breakthrough_remaining = maxf(0.0, _spear_breakthrough_remaining - delta)
	_spear_bullet_cut_remaining = maxf(0.0, _spear_bullet_cut_remaining - delta)
	_spear_edge_pressure_remaining = maxf(0.0, _spear_edge_pressure_remaining - delta)
	if _mace_counter_remaining <= 0.0:
		_guard_successful = false
	if _spear_bullet_cut_remaining <= 0.0:
		_spear_radial_attack_ready = false
	if _spear_edge_pressure_remaining <= 0.0:
		_spear_edge_pressure_target = null
	_ghost_step_remaining = maxf(0.0, _ghost_step_remaining - delta)
	_damage_guard_remaining = maxf(0.0, _damage_guard_remaining - delta)
	var command: DontDodgeCommand = _input_source.read_command()
	if _is_scene_transitioning():
		command.move_direction = Vector2.ZERO
		command.attack_pressed = false
		command.dodge_pressed = false
		command.negate_pressed = false
		command.ultimate_pressed = false
	_record_input_event(command)
	_process_attack_input(command)
	_player.advance(delta, command.move_direction, _get_player_move_speed())
	_update_spear_dodge_contact()
	if command.dodge_pressed:
		_try_dodge(command.move_direction)
	if command.negate_pressed:
		_try_negate()
	if command.ultimate_pressed:
		_try_ultimate()
	if _ultimate_freeze_remaining > 0.0:
		return
	_defense.update(delta)
	_update_spawn_warnings(delta)
	if _state == GameState.COMBAT:
		_elapsed = _elapsed + delta if _mode == &"training" else minf(DontDodgeTuning.SESSION_DURATION, _elapsed + delta)
		_time_metrics["active_combat_seconds"] = _elapsed
		if _mode != &"training":
			_spawn_due_enemies()
			_spawn_due_hearts()
	_update_enemies(delta)
	_update_hearts(delta)
	_update_experience_orbs(delta)
	_update_projectiles(delta)
	_cleanup_inactive_nodes()
	_update_combat_state()
	_update_combat_hints(delta)


func _is_gameplay_state() -> bool:
	return _state == GameState.COMBAT or _state == GameState.THREAT_GATE or _state == GameState.FINAL_CLEANUP


func _update_visual_timers(delta: float) -> void:
	_feedback_remaining = maxf(0.0, _feedback_remaining - delta)
	_update_upgrade_result(delta)


func _account_session_time(delta: float) -> void:
	if _state == GameState.RESULT:
		return
	_time_metrics["total_wall_seconds"] = float(_time_metrics["total_wall_seconds"]) + delta
	if _state == GameState.MANUAL_PAUSE:
		_time_metrics["manual_pause_seconds"] = float(_time_metrics["manual_pause_seconds"]) + delta
		return
	_time_metrics["unpaused_session_seconds"] = float(_time_metrics["unpaused_session_seconds"]) + delta
	if _state == GameState.THREAT_GATE:
		_time_metrics["threat_gate_seconds"] = float(_time_metrics["threat_gate_seconds"]) + delta
		_threat_gate_elapsed += delta
	elif _state == GameState.FINAL_CLEANUP:
		_time_metrics["cleanup_seconds"] = float(_time_metrics["cleanup_seconds"]) + delta
		_cleanup_elapsed += delta
	elif _state == GameState.UPGRADE:
		_time_metrics["upgrade_seconds"] = float(_time_metrics["upgrade_seconds"]) + delta


func _record_state(next_state: GameState, reason: String) -> void:
	if _state == next_state:
		return
	_state = next_state
	_state_events.append({"state": GameState.keys()[next_state], "active_time": snappedf(_elapsed, 0.001), "reason": reason})
	_request_hud_refresh()


func _record_input_event(command: DontDodgeCommand) -> void:
	if not command.attack_pressed and not command.dodge_pressed and not command.negate_pressed and not command.ultimate_pressed:
		return
	_input_events.append({
		"active_time": snappedf(_elapsed, 0.001),
		"attack": command.attack_pressed,
		"dodge": command.dodge_pressed,
		"negate": command.negate_pressed,
		"ultimate": command.ultimate_pressed,
		"defense_before": _defense.get_charges(),
	})


func get_game_state() -> GameState:
	return _state


func get_timeline_for_test() -> Array[Dictionary]:
	return _timeline.duplicate(true)


func spawn_enemy_for_test(enemy_type: int, position: Vector2) -> DontDodgeEnemy:
	return _spawn_enemy(enemy_type, position)


func spawn_heart_for_test(position: Vector2) -> DontDodgeHeart:
	return _spawn_heart(position)


func spawn_experience_orb_for_test(position: Vector2, value: int = 1) -> DontDodgeExperienceOrb:
	return _spawn_experience_orb(position, value)


func perform_attack_for_test() -> bool:
	if _attack_recovery_remaining > 0.0:
		_stats["attack_recovery_rejections"] += 1
		return false
	_perform_attack()
	return true


func advance_attack_recovery_for_test(delta: float) -> void:
	_attack_recovery_remaining = maxf(0.0, _attack_recovery_remaining - delta)


func get_defense_resource() -> DefenseResource:
	return _defense


func get_stats() -> Dictionary:
	return _stats.duplicate(true)


func get_loadout() -> Dictionary:
	return {
		"weapon_id": _weapon_id,
		"technique_id": _technique_id,
		"ultimate_id": _ultimate_id,
		"upgrade_stage": int(_upgrade_stage),
	}


func get_attack_profile() -> Dictionary:
	return {
		"damage": _get_focus_damage(),
		"range": _get_focus_range(),
		"arc_degrees": rad_to_deg(_get_focus_arc_angle()),
		"knockback": _get_focus_knockback(),
		"attack_speed_percent": roundi((_get_focus_attack_speed_multiplier() - 1.0) * 100.0),
		"attack_interval": _get_focus_recovery(),
		"move_speed": _get_player_move_speed(),
		"dodge_cost": _get_dodge_cost(),
		"negate_enabled": _is_negate_enabled(),
		"max_health": _player.get_max_health(),
		"defense_max_charges": _defense.get_max_charges(),
		"attack_target_limit": _get_attack_target_limit(),
		"attack_pierces": _attack_pierces(),
	}


func get_pause_mode() -> PauseMode:
	return _pause_mode


func select_upgrade_for_test(upgrade_id: String) -> bool:
	return _select_upgrade(upgrade_id)


func _input(event: InputEvent) -> void:
	if _is_scene_transitioning():
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_guide_panel) and event is InputEventKey and event.is_pressed() and not event.is_echo():
		var guide_key := event as InputEventKey
		if guide_key.keycode == KEY_ENTER or guide_key.keycode == KEY_KP_ENTER or guide_key.keycode == KEY_SPACE:
			_finish_guide()
			get_viewport().set_input_as_handled()
			return
	if not _started or _ended or not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	var key_event := event as InputEventKey
	if _pause_mode == PauseMode.UPGRADE:
		if key_event.keycode == KEY_LEFT or key_event.keycode == KEY_UP:
			_move_upgrade_cursor(-1)
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_RIGHT or key_event.keycode == KEY_DOWN:
			_move_upgrade_cursor(1)
			get_viewport().set_input_as_handled()
		elif key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
			if not _upgrade_options.is_empty():
				_select_upgrade(str(_upgrade_options[_upgrade_cursor].get("option_id", "")))
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		if _pause_mode == PauseMode.MANUAL:
			_resume_manual_pause()
		else:
			_open_manual_pause()
		get_viewport().set_input_as_handled()


func _open_manual_pause() -> void:
	if _ended or _pause_mode != PauseMode.NONE or _state == GameState.PLAYER_DEAD:
		return
	_state_before_manual_pause = _state
	_record_state(GameState.MANUAL_PAUSE, "manual_pause")
	_pause_mode = PauseMode.MANUAL
	_input_source.clear_requests()
	_pause_backdrop.visible = true
	_pause_panel.visible = true
	_pause_button.visible = true
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_resume_button.grab_focus()
	_play_ui_sfx()
	_update_hud()
	_sync_combat_visuals()


func _toggle_manual_pause() -> void:
	if _pause_mode == PauseMode.MANUAL:
		_resume_manual_pause()
	elif _pause_mode == PauseMode.NONE:
		_open_manual_pause()


func _resume_manual_pause() -> void:
	if _pause_mode != PauseMode.MANUAL:
		return
	_pause_mode = PauseMode.NONE
	_record_state(_state_before_manual_pause, "manual_resume")
	_pause_backdrop.visible = false
	_pause_panel.visible = false
	_pause_button.visible = true
	_pause_button.focus_mode = Control.FOCUS_ALL
	_pause_button.grab_focus()
	_input_source.clear_requests()
	_play_ui_sfx()
	_update_hud()
	_sync_combat_visuals()


func _open_experience_upgrade(level: int) -> void:
	_upgrade_stage = UpgradeStage.WEAPON if level == 1 else UpgradeStage.TECHNIQUE if level == 2 else UpgradeStage.ULTIMATE
	_open_upgrade_panel(_tr(&"upgrade.level_title", [level, _get_upgrade_stage_title()]), "experience_level_%d" % level)


func _get_upgrade_stage_title() -> String:
	if _upgrade_stage == UpgradeStage.WEAPON:
		return _tr(&"upgrade.weapon_select")
	if _upgrade_stage == UpgradeStage.TECHNIQUE:
		return _tr(&"upgrade.technique_select", [_get_weapon_title()])
	return _tr(&"upgrade.ultimate_unlock", [_get_weapon_title()])


func _refresh_upgrade_title() -> void:
	if is_instance_valid(_upgrade_title) and _upgrade_stage != UpgradeStage.NONE:
		_upgrade_title.text = _tr(&"upgrade.level_title", [_experience_level, _get_upgrade_stage_title()])


func _open_upgrade_panel(title: String, reason: String) -> void:
	if _ended or _pause_mode != PauseMode.NONE:
		return
	_record_state(GameState.UPGRADE, reason)
	_pause_mode = PauseMode.UPGRADE
	_upgrade_cursor = 0
	_upgrade_options = _get_current_upgrade_options()
	_input_source.clear_requests()
	_pause_backdrop.visible = true
	_upgrade_panel.visible = true
	_pause_button.visible = false
	_pause_button.focus_mode = Control.FOCUS_NONE
	_upgrade_title.text = title
	_refresh_upgrade_cards()
	if not _upgrade_cards.is_empty():
		_upgrade_cards[_upgrade_cursor].grab_focus()
	_play_ui_sfx()
	_update_hud()
	_sync_combat_visuals()


func _move_upgrade_cursor(direction: int) -> void:
	if _pause_mode != PauseMode.UPGRADE:
		return
	if _upgrade_options.is_empty():
		return
	_upgrade_cursor = posmod(_upgrade_cursor + direction, _upgrade_options.size())
	_upgrade_cards[_upgrade_cursor].grab_focus()
	_play_ui_sfx()


func _select_upgrade(upgrade_id: String) -> bool:
	var selected_option: Dictionary = {}
	for option: Dictionary in _upgrade_options:
		if str(option.get("option_id", "")) == upgrade_id:
			selected_option = option
			break
	if selected_option.is_empty():
		return false
	var selected_stage: int = int(selected_option.get("stage", 0))
	if selected_stage != int(_upgrade_stage):
		return false
	var previous_build: Dictionary = get_loadout()
	match _upgrade_stage:
		UpgradeStage.WEAPON:
			_weapon_id = str(selected_option.get("id", ""))
			_technique_id = ""
			_ultimate_id = ""
			_ultimate_charge = 0
			_apply_weapon_loadout()
		UpgradeStage.TECHNIQUE:
			_technique_id = str(selected_option.get("id", ""))
		UpgradeStage.ULTIMATE:
			_ultimate_id = str(selected_option.get("id", ""))
			_ultimate_charge = DontDodgeTuning.ULTIMATE_MAX
	_play_ui_sfx()
	_upgrade_history.append({
		"time_seconds": snappedf(_elapsed, 0.1),
		"stage": int(_upgrade_stage),
		"option_id": upgrade_id,
		"previous_build": previous_build,
		"build": get_loadout(),
		"experience_level": _experience_level,
	})
	_show_upgrade_result(selected_option)
	if selected_stage == int(UpgradeStage.ULTIMATE):
		_queue_combat_hint(CombatHint.ULTIMATE)
	var selected_title_key: StringName = _localized_data_key(selected_option, &"title_key", &"upgrade.fallback")
	var feedback_suffix_key: StringName = &"feedback.ultimate_ready_suffix" if selected_stage == int(UpgradeStage.ULTIMATE) else &""
	_show_feedback_key(&"feedback.upgrade_applied", [selected_title_key, feedback_suffix_key], 1.2)
	if _pause_mode == PauseMode.UPGRADE:
		_pause_mode = PauseMode.NONE
		_record_state(GameState.COMBAT, "upgrade_selected")
		_pause_backdrop.visible = false
		_upgrade_panel.visible = false
		_pause_button.visible = true
		_pause_button.focus_mode = Control.FOCUS_ALL
		_input_source.clear_requests()
		_update_hud()
		_try_open_experience_upgrade()
		if _pause_mode == PauseMode.NONE:
			_pause_button.grab_focus()
	return true


func _get_current_upgrade_options() -> Array[Dictionary]:
	match _upgrade_stage:
		UpgradeStage.WEAPON:
			return LOADOUT_DATA_SCRIPT.get_weapon_options()
		UpgradeStage.TECHNIQUE:
			return LOADOUT_DATA_SCRIPT.get_technique_options(_weapon_id)
		UpgradeStage.ULTIMATE:
			return LOADOUT_DATA_SCRIPT.get_ultimate_options(_weapon_id)
	return []


func _process_attack_input(command: DontDodgeCommand) -> void:
	if not command.attack_pressed:
		return
	if _attack_recovery_remaining > 0.0:
		_stats["attack_recovery_rejections"] += 1
		return
	_perform_attack()


func _perform_attack() -> void:
	_stats["focus_attacks"] += 1
	_attack_sequence += 1
	_attack_recovery_remaining = _get_focus_recovery()
	_player.play_attack()
	_emit_sound_event(SOUND_EVENT_PLAYER_ATTACK, _player.global_position)
	var target: DontDodgeEnemy = _find_priority_enemy(_get_focus_range())
	if not is_instance_valid(target):
		_stats["focus_misses"] += 1
		_focus_attack_direction = _player.get_last_move_direction()
		_call_combat_visual(&"show_focus_wave", [_player.global_position, _focus_attack_direction, _get_focus_range(), _get_focus_arc_angle()])
		_show_feedback_key(&"feedback.attack_miss", [], 0.45)
		if _spear_radial_attack_ready:
			_perform_spear_radial_attack()
			_spear_radial_attack_ready = false
		return
	_focus_attack_direction = (target.global_position - _player.global_position).normalized()
	_call_combat_visual(&"show_focus_wave", [_player.global_position, _focus_attack_direction, _get_focus_range(), _get_focus_arc_angle()])
	var focus_hits: int = 0
	var attack_knockback: float = _get_focus_knockback()
	var target_limit: int = _get_attack_target_limit()
	var stealth_bonus: bool = _player.consume_stealth_attack_bonus()
	var counter_bonus: bool = _guard_successful and _mace_counter_remaining > 0.0 and _has_technique("tech_mace_counter")
	var interrupt_used: bool = false
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_combat_active() or not _is_in_focus_wedge(enemy):
			continue
		if target_limit > 0 and focus_hits >= target_limit:
			break
		var can_suppress: bool = enemy.is_charge_counterable() or (enemy.get_enemy_type() == DontDodgeEnemy.EnemyType.MELEE and enemy.is_winding_up())
		if not interrupt_used and _has_technique("tech_mace_suppress") and _break_cooldown_remaining <= 0.0 and can_suppress:
			if enemy.get_enemy_type() == DontDodgeEnemy.EnemyType.CHARGER or enemy.is_charging():
				enemy.force_interrupt()
			else:
				enemy.interrupt()
			_break_cooldown_remaining = DontDodgeTuning.MACE_SUPPRESS_COOLDOWN
			interrupt_used = true
			_call_combat_visual(&"show_mace_suppress_impact", [enemy.global_position, _focus_attack_direction])
			_request_hit_stop(DontDodgeTuning.MACE_SUPPRESS_HIT_STOP)
		var damage: int = _get_attack_damage_with_bonus(enemy, stealth_bonus)
		if counter_bonus:
			damage += DontDodgeTuning.MACE_COUNTER_DAMAGE
		var final_knockback: float = attack_knockback * DontDodgeTuning.MACE_COUNTER_KNOCKBACK_MULTIPLIER if counter_bonus else attack_knockback
		_hit_enemy(enemy, damage, final_knockback)
		if counter_bonus:
			enemy.force_interrupt()
		focus_hits += 1
	_stats["focus_hits"] += focus_hits
	if interrupt_used:
		_stats["interrupts"] += 1
		_grant_ultimate(DontDodgeTuning.ULTIMATE_INTERRUPT_FIRST, "interrupt")
	if focus_hits > 0 and counter_bonus:
		_guard_successful = false
		_mace_counter_remaining = 0.0
		_call_combat_visual(&"show_mace_counter_impact", [_player.global_position, _focus_attack_direction])
		_request_hit_stop(DontDodgeTuning.MACE_COUNTER_HIT_STOP)
	if _has_technique("tech_dagger_flurry") and _attack_sequence % 3 == 0:
		_perform_dagger_flurry_attack()
	if _has_technique("tech_spear_breakthrough") and _spear_breakthrough_remaining > 0.0:
		_perform_spear_followup_attack()
		_spear_breakthrough_remaining = 0.0
	if _spear_radial_attack_ready:
		_perform_spear_radial_attack()
		_spear_radial_attack_ready = false
		_spear_bullet_cut_remaining = 0.0


func _perform_dagger_flurry_attack() -> void:
	var followup_target: DontDodgeEnemy = _find_priority_enemy(_get_focus_range())
	if not is_instance_valid(followup_target):
		return
	var direction: Vector2 = (followup_target.global_position - _player.global_position).normalized()
	_call_combat_visual(&"show_dagger_followup", [_player.global_position, direction, _get_focus_range()])
	_hit_enemy(followup_target, _get_attack_damage(followup_target), _get_focus_knockback() * 0.5)


func _perform_spear_followup_attack() -> void:
	_call_combat_visual(&"show_spear_pierce", [_player.global_position, _focus_attack_direction, _get_focus_range() + 24.0, deg_to_rad(10.0)])
	_perform_sword_wave(2, 24.0)


func _perform_spear_radial_attack() -> void:
	_call_combat_visual(&"show_spear_bullet_cut", [_player.global_position, _focus_attack_direction, DontDodgeTuning.SPEAR_BULLET_CUT_RANGE, DontDodgeTuning.SPEAR_BULLET_CUT_LANE_WIDTH, DontDodgeTuning.SPEAR_BULLET_CUT_LANE_SPACING])
	var direction: Vector2 = _focus_attack_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var perpendicular: Vector2 = direction.orthogonal()
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_combat_active():
			continue
		var offset: Vector2 = enemy.global_position - _player.global_position
		var forward_distance: float = offset.dot(direction)
		if forward_distance < 0.0 or forward_distance > DontDodgeTuning.SPEAR_BULLET_CUT_RANGE:
			continue
		var lateral_distance: float = absf(offset.dot(perpendicular))
		var nearest_lane: float = minf(lateral_distance, absf(lateral_distance - DontDodgeTuning.SPEAR_BULLET_CUT_LANE_SPACING))
		if nearest_lane <= DontDodgeTuning.SPEAR_BULLET_CUT_LANE_WIDTH:
			_hit_enemy(enemy, DontDodgeTuning.SPEAR_BULLET_CUT_DAMAGE, _get_focus_knockback() * 0.3)


func _perform_sword_wave(damage: int, range_bonus: float) -> void:
	var wave_range: float = _get_focus_range() + range_bonus
	var wave_angle: float = deg_to_rad(14.0)
	_call_combat_visual(&"show_focus_wave", [_player.global_position, _focus_attack_direction, wave_range, wave_angle])
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_combat_active():
			continue
		var to_enemy: Vector2 = enemy.global_position - _player.global_position
		if to_enemy.length() > wave_range or to_enemy == Vector2.ZERO:
			continue
		if absf(_focus_attack_direction.angle_to(to_enemy.normalized())) <= wave_angle * 0.5:
			_hit_enemy(enemy, damage, DontDodgeTuning.FOCUS_KNOCKBACK * 0.4)


func _hit_enemy(enemy: DontDodgeEnemy, damage: int, knockback: float, emit_sound: bool = true) -> void:
	if not is_instance_valid(enemy):
		return
	var direction: Vector2 = (enemy.global_position - _player.global_position).normalized()
	if emit_sound:
		_emit_sound_event(SOUND_EVENT_ENEMY_HIT, enemy.global_position)
	var was_defeated: bool = enemy.receive_hit(damage, direction, knockback)
	_spawn_enemy_damage_feedback(enemy.global_position, damage, enemy.get_health(), was_defeated)


func _try_dodge(move_direction: Vector2) -> void:
	if not _player.can_dodge():
		_show_feedback_key(&"feedback.dodge_pending", [], 0.4)
		return
	if not _defense.consume(_get_dodge_cost()):
		_show_feedback_key(&"feedback.defense_empty", [], 0.6)
		return
	_player.begin_dodge(move_direction)
	_spear_dodge_contact_registered = false
	_stats["dodges"] += 1


func _on_player_dodge_finished() -> void:
	if _has_technique("tech_dagger_draw"):
		_player.begin_stealth(0.4)
		_call_combat_visual(&"show_stealth_burst", [_player.global_position])
		_show_feedback_key(&"feedback.dagger_stealth", [], 0.45)


func _update_spear_dodge_contact() -> void:
	if not _player.is_dodging() or not _has_technique("tech_spear_breakthrough") or _spear_dodge_contact_registered:
		return
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_combat_active():
			continue
		if enemy.global_position.distance_to(_player.global_position) > DontDodgeTuning.PLAYER_RADIUS + 30.0:
			continue
		_spear_dodge_contact_registered = true
		_spear_breakthrough_remaining = DontDodgeTuning.SPEAR_BREAKTHROUGH_DURATION
		_call_combat_visual(&"show_spear_contact", [_player.global_position, _player.get_last_move_direction()])
		_show_feedback_key(&"feedback.spear_breakthrough", [], 0.45)
		return


func _try_negate() -> void:
	if not _is_negate_enabled():
		_show_feedback_key(&"feedback.dagger_negate_locked", [], 0.8)
		return
	var negate_mode: String = str(_get_weapon_data().get("negate_mode", "radial"))
	if negate_mode == "guard":
		if not _defense.consume():
			_show_feedback_key(&"feedback.defense_empty", [], 0.6)
			return
		_stats["negates"] += 1
		_guard_remaining = DontDodgeTuning.GUARD_WINDOW
		_guard_direction = _player.get_last_move_direction().normalized()
		if _guard_direction == Vector2.ZERO:
			_guard_direction = Vector2.RIGHT
		_guard_successful = false
		_mace_counter_remaining = 0.0
		_call_combat_visual(&"show_guard_arc", [_player.global_position, _guard_direction, DontDodgeTuning.GUARD_ARC_DEGREES])
		_show_feedback_key(&"feedback.front_guard", [], DontDodgeTuning.GUARD_WINDOW)
		return
	if negate_mode != "projectile_only":
		if not _has_negate_target():
			_show_feedback_key(&"feedback.no_negate_target", [], 0.5)
			return
		if not _defense.consume():
			_show_feedback_key(&"feedback.defense_empty", [], 0.6)
			return
		_stats["negates"] += 1
		_call_combat_visual(&"show_negate_wave", [_player.global_position, DontDodgeTuning.NEGATE_RADIUS])
		var interrupts: int = 0
		var repulsed: int = 0
		for enemy: DontDodgeEnemy in _enemies:
			if not is_instance_valid(enemy) or not enemy.is_combat_active() or enemy.global_position.distance_to(_player.global_position) > DontDodgeTuning.NEGATE_RADIUS:
				continue
			var direction: Vector2 = (enemy.global_position - _player.global_position).normalized()
			if enemy.repel(direction, DontDodgeTuning.NEGATE_KNOCKBACK):
				repulsed += 1
			if enemy.is_charge_counterable():
				enemy.force_interrupt()
				interrupts += 1
			elif enemy.interrupt():
				interrupts += 1
		var erased: int = 0
		for projectile: DontDodgeProjectile in _projectiles:
			if is_instance_valid(projectile) and not projectile.is_queued_for_deletion() and projectile.global_position.distance_to(_player.global_position) <= DontDodgeTuning.NEGATE_RADIUS:
				projectile.queue_free()
				erased += 1
		_stats["interrupts"] += interrupts
		_stats["enemies_repulsed"] += repulsed
		_stats["projectiles_erased"] += erased
		if interrupts > 0:
			var interrupt_reward: int = DontDodgeTuning.ULTIMATE_INTERRUPT_FIRST + maxi(0, interrupts - 1) * DontDodgeTuning.ULTIMATE_INTERRUPT_ADDITIONAL
			_grant_ultimate(mini(DontDodgeTuning.ULTIMATE_INTERRUPT_CAP_PER_CAST, interrupt_reward), "interrupt")
		if erased > 0:
			_grant_ultimate(mini(DontDodgeTuning.ULTIMATE_PROJECTILE_ERASE_CAP_PER_CAST, erased * DontDodgeTuning.ULTIMATE_PROJECTILE_ERASE), "projectile_erased")
		return
	var has_projectile_target: bool = false
	for projectile: DontDodgeProjectile in _projectiles:
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion() and projectile.global_position.distance_to(_player.global_position) <= DontDodgeTuning.NEGATE_RADIUS:
			has_projectile_target = true
			break
	if not has_projectile_target:
		_show_feedback_key(&"feedback.no_projectile", [], 0.5)
		return
	if not _defense.consume():
		_show_feedback_key(&"feedback.defense_empty", [], 0.6)
		return
	_stats["negates"] += 1
	var erased: int = 0
	for projectile: DontDodgeProjectile in _projectiles:
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion() and projectile.global_position.distance_to(_player.global_position) <= DontDodgeTuning.NEGATE_RADIUS:
			projectile.queue_free()
			erased += 1
	_stats["projectiles_erased"] += erased
	_call_combat_visual(&"show_negate_wave", [_player.global_position, DontDodgeTuning.NEGATE_RADIUS])
	if erased > 0:
		_grant_ultimate(mini(DontDodgeTuning.ULTIMATE_PROJECTILE_ERASE_CAP_PER_CAST, erased * DontDodgeTuning.ULTIMATE_PROJECTILE_ERASE), "projectile_erased")
		if _has_technique("tech_spear_bullet_cut") and erased >= 2:
			_spear_radial_attack_ready = true
			_spear_bullet_cut_remaining = DontDodgeTuning.SPEAR_BULLET_CUT_DURATION
			_show_feedback_key(&"feedback.bullet_cut", [], 0.65)


func _has_negate_target() -> bool:
	for enemy: DontDodgeEnemy in _enemies:
		if is_instance_valid(enemy) and enemy.is_combat_active() and enemy.global_position.distance_to(_player.global_position) <= DontDodgeTuning.NEGATE_RADIUS:
			return true
	for projectile: DontDodgeProjectile in _projectiles:
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion() and projectile.global_position.distance_to(_player.global_position) <= DontDodgeTuning.NEGATE_RADIUS:
			return true
	return false


func _try_ultimate() -> void:
	if _ultimate_id.is_empty():
		_show_feedback_key(&"feedback.ultimate_locked", [], 0.7)
		return
	if _ultimate_charge < DontDodgeTuning.ULTIMATE_MAX:
		_show_feedback_key(&"feedback.ultimate_charge", [_get_ultimate_percent()], 0.5)
		return
	_ultimate_charge = 0
	var opening_freeze: float = DontDodgeTuning.ULTIMATE_FREEZE_DURATION
	if _ultimate_id == "ult_dagger_shadow_frenzy" or _ultimate_id == "ult_dagger_assassination_mark":
		opening_freeze = DontDodgeTuning.DAGGER_ULTIMATE_OPENING_FREEZE
	_ultimate_freeze_remaining = opening_freeze
	_request_hit_stop(opening_freeze)
	_stats["ultimates"] += 1
	_emit_sound_event(SOUND_EVENT_ULTIMATE, _player.global_position)
	_call_screen_feedback(&"trigger_impact", [12.0, 0.16, Color(0.82, 0.36, 1.0), 0.14])
	match _ultimate_id:
		"ult_dagger_shadow_frenzy":
			_perform_dagger_shadow_frenzy()
		"ult_dagger_assassination_mark":
			_perform_dagger_assassination_mark()
		"ult_mace_ground_suppression":
			_perform_mace_ground_suppression()
		"ult_mace_frontline_break":
			_perform_mace_frontline_break()
		"ult_spear_sky_pierce":
			_perform_spear_sky_pierce()
		"ult_spear_formation":
			_perform_spear_formation()
		_:
			_show_feedback_key(&"feedback.ultimate_missing", [], 0.8)


func _get_dagger_dash_route(start_position: Vector2, target: DontDodgeEnemy, arrival_offset: float) -> Dictionary:
	var target_position: Vector2 = target.global_position
	var dash_direction: Vector2 = (target_position - start_position).normalized()
	if dash_direction == Vector2.ZERO:
		dash_direction = _player.get_last_move_direction()
		if dash_direction == Vector2.ZERO:
			dash_direction = Vector2.RIGHT
	var target_distance: float = start_position.distance_to(target_position)
	var actual_arrival_offset: float = minf(arrival_offset, maxf(0.0, target_distance - DontDodgeTuning.PLAYER_RADIUS))
	var dash_end: Vector2 = (target_position - dash_direction * actual_arrival_offset).clamp(
		Vector2.ONE * DontDodgeTuning.PLAYER_RADIUS,
		DontDodgeTuning.ARENA_SIZE - Vector2.ONE * DontDodgeTuning.PLAYER_RADIUS,
	)
	return {
		"target": target,
		"target_position": target_position,
		"start": start_position,
		"end": dash_end,
		"direction": dash_direction,
		"range": actual_arrival_offset + 48.0,
	}


func _start_dagger_ultimate_sequence(sequence: Array[Dictionary], completion_key: StringName, completion_arguments: Array = []) -> void:
	if sequence.is_empty():
		_show_feedback_key(completion_key, completion_arguments, 0.9)
		return
	_dagger_ultimate_sequence = sequence
	_dagger_ultimate_sequence_index = 0
	_dagger_ultimate_phase_elapsed = 0.0
	_dagger_ultimate_sequence_pending_start = true
	_dagger_ultimate_completion_feedback_key = completion_key
	_dagger_ultimate_completion_feedback_arguments = completion_arguments.duplicate()


func _begin_dagger_ultimate_phase() -> void:
	if _dagger_ultimate_sequence_index < 0 or _dagger_ultimate_sequence_index >= _dagger_ultimate_sequence.size():
		_finish_dagger_ultimate_sequence()
		return
	var phase: Dictionary = _dagger_ultimate_sequence[_dagger_ultimate_sequence_index]
	var phase_kind: StringName = StringName(phase["kind"])
	var phase_duration: float = float(phase["duration"])
	_damage_guard_remaining = maxf(_damage_guard_remaining, phase_duration + 0.14)
	var target: DontDodgeEnemy = phase.get("target") as DontDodgeEnemy
	match phase_kind:
		&"shadow_telegraph":
			var shadow_telegraph_duration: float = phase_duration + DontDodgeTuning.DAGGER_SHADOW_FRENZY_STRIKE_PHASE + 0.12
			_call_combat_visual(&"show_dagger_range_preview", [phase["start"], DontDodgeTuning.DAGGER_SHADOW_FRENZY_RADIUS, shadow_telegraph_duration])
			_call_combat_visual(&"show_ultimate_dash", [phase["start"], phase["end"], shadow_telegraph_duration])
			_call_combat_visual(&"show_dagger_dash_endpoint", [phase["end"], shadow_telegraph_duration])
			_call_combat_visual(&"show_dagger_target_marker", [phase["target_position"], target])
		&"shadow_strike":
			_player.global_position = phase["end"]
			_call_combat_visual(&"show_dagger_followup", [_player.global_position, phase["direction"], phase["range"]])
			_call_combat_visual(&"show_stealth_burst", [_player.global_position])
			if is_instance_valid(target) and target.is_combat_active():
				_hit_enemy(target, DontDodgeTuning.DAGGER_SHADOW_FRENZY_DAMAGE, DontDodgeTuning.ULTIMATE_KNOCKBACK, false)
			_request_hit_stop(DontDodgeTuning.DAGGER_ULTIMATE_STRIKE_HIT_STOP)
			_call_screen_feedback(&"trigger_impact", [4.0, 0.05, Color(0.58, 0.94, 1.0), 0.06])
		&"assassination_telegraph":
			var assassination_telegraph_duration: float = phase_duration + DontDodgeTuning.DAGGER_ASSASSINATION_STRIKE_PHASE + 0.12
			_call_combat_visual(&"show_dagger_range_preview", [phase["start"], DontDodgeTuning.ULTIMATE_RADIUS, assassination_telegraph_duration])
			_call_combat_visual(&"show_ultimate_dash", [phase["start"], phase["end"], assassination_telegraph_duration])
			_call_combat_visual(&"show_dagger_dash_endpoint", [phase["end"], assassination_telegraph_duration])
			_call_combat_visual(&"show_assassination_mark", [phase["target_position"], target])
		&"assassination_dash_strike":
			_player.global_position = phase["end"]
			_call_combat_visual(&"show_dagger_followup", [_player.global_position, phase["direction"], phase["range"]])
			_call_combat_visual(&"show_stealth_burst", [_player.global_position])
			if is_instance_valid(target) and target.is_combat_active():
				_hit_enemy(target, DontDodgeTuning.DAGGER_ASSASSINATION_HIT_DAMAGE, 0.0, false)
			_request_hit_stop(DontDodgeTuning.DAGGER_ULTIMATE_STRIKE_HIT_STOP)
			_call_screen_feedback(&"trigger_impact", [4.0, 0.05, Color(0.82, 0.36, 1.0), 0.06])
		&"assassination_strike":
			_player.global_position = phase["end"]
			_call_combat_visual(&"show_dagger_followup", [_player.global_position, phase["direction"], phase["range"]])
			_call_combat_visual(&"show_stealth_burst", [_player.global_position])
			if is_instance_valid(target) and target.is_combat_active():
				_hit_enemy(target, DontDodgeTuning.DAGGER_ASSASSINATION_HIT_DAMAGE, 0.0, false)
			_request_hit_stop(DontDodgeTuning.DAGGER_ULTIMATE_STRIKE_HIT_STOP)
			_call_screen_feedback(&"trigger_impact", [4.0, 0.05, Color(0.82, 0.36, 1.0), 0.06])


func _update_dagger_ultimate_sequence(delta: float) -> void:
	_damage_guard_remaining = maxf(0.0, _damage_guard_remaining - delta)
	if _dagger_ultimate_sequence_index < 0 or _dagger_ultimate_sequence_index >= _dagger_ultimate_sequence.size():
		_finish_dagger_ultimate_sequence()
		return
	var phase: Dictionary = _dagger_ultimate_sequence[_dagger_ultimate_sequence_index]
	var phase_kind: StringName = StringName(phase["kind"])
	var phase_duration: float = float(phase["duration"])
	_dagger_ultimate_phase_elapsed += delta
	if _dagger_ultimate_phase_elapsed < phase_duration:
		return
	_dagger_ultimate_sequence_index += 1
	_dagger_ultimate_phase_elapsed = 0.0
	_begin_dagger_ultimate_phase()


func _finish_dagger_ultimate_sequence() -> void:
	var completion_key: StringName = _dagger_ultimate_completion_feedback_key
	var completion_arguments: Array = _dagger_ultimate_completion_feedback_arguments.duplicate()
	_dagger_ultimate_sequence.clear()
	_dagger_ultimate_sequence_index = -1
	_dagger_ultimate_phase_elapsed = 0.0
	_dagger_ultimate_sequence_pending_start = false
	_dagger_ultimate_completion_feedback_key = &""
	_dagger_ultimate_completion_feedback_arguments.clear()
	if not completion_key.is_empty():
		_show_feedback_key(completion_key, completion_arguments, 0.9)


func _perform_dagger_shadow_frenzy() -> void:
	var targets: Array[DontDodgeEnemy] = []
	while targets.size() < 3:
		var closest: DontDodgeEnemy
		var closest_distance: float = INF
		for enemy: DontDodgeEnemy in _enemies:
			if not is_instance_valid(enemy) or not enemy.is_combat_active() or targets.has(enemy):
				continue
			var distance: float = enemy.global_position.distance_to(_player.global_position)
			if distance <= DontDodgeTuning.DAGGER_SHADOW_FRENZY_RADIUS and distance < closest_distance:
				closest = enemy
				closest_distance = distance
		if not is_instance_valid(closest):
			break
		targets.append(closest)
	var sequence: Array[Dictionary] = []
	var dash_start: Vector2 = _player.global_position
	for target: DontDodgeEnemy in targets:
		var route: Dictionary = _get_dagger_dash_route(dash_start, target, DontDodgeTuning.DAGGER_SHADOW_FRENZY_ARRIVAL_OFFSET)
		sequence.append({
			"kind": &"shadow_telegraph",
			"target": target,
			"target_position": route["target_position"],
			"start": route["start"],
			"end": route["end"],
			"duration": DontDodgeTuning.DAGGER_SHADOW_FRENZY_TELEGRAPH_PHASE,
		})
		sequence.append({
			"kind": &"shadow_strike",
			"target": target,
			"end": route["end"],
			"direction": route["direction"],
			"range": route["range"],
			"duration": DontDodgeTuning.DAGGER_SHADOW_FRENZY_STRIKE_PHASE,
		})
		dash_start = route["end"]
	_damage_guard_remaining = maxf(_damage_guard_remaining, DontDodgeTuning.DAGGER_SHADOW_FRENZY_INVULNERABILITY)
	_start_dagger_ultimate_sequence(sequence, &"feedback.shadow_frenzy_complete", [targets.size()])


func _perform_dagger_assassination_mark() -> void:
	var target: DontDodgeEnemy = _find_strongest_enemy(DontDodgeTuning.ULTIMATE_RADIUS)
	if not is_instance_valid(target):
		_show_feedback_key(&"feedback.assassination_no_target", [], 0.7)
		return
	var route: Dictionary = _get_dagger_dash_route(_player.global_position, target, DontDodgeTuning.DAGGER_ASSASSINATION_ARRIVAL_OFFSET)
	var sequence: Array[Dictionary] = []
	sequence.append({
		"kind": &"assassination_telegraph",
		"target": target,
		"target_position": route["target_position"],
		"start": route["start"],
		"end": route["end"],
		"duration": DontDodgeTuning.DAGGER_ASSASSINATION_TELEGRAPH_PHASE,
	})
	for strike_index: int in DontDodgeTuning.DAGGER_ASSASSINATION_STRIKES:
		sequence.append({
			"kind": &"assassination_dash_strike" if strike_index == 0 else &"assassination_strike",
			"target": target,
			"end": route["end"],
			"direction": route["direction"],
			"range": route["range"],
			"duration": DontDodgeTuning.DAGGER_ASSASSINATION_STRIKE_PHASE,
		})
	_damage_guard_remaining = maxf(_damage_guard_remaining, DontDodgeTuning.DAGGER_ASSASSINATION_INVULNERABILITY)
	_start_dagger_ultimate_sequence(sequence, &"feedback.assassination_complete")


func _start_weapon_ultimate_sequence(sequence: Array[Dictionary], completion_key: StringName, completion_arguments: Array = []) -> void:
	if sequence.is_empty():
		_show_feedback_key(completion_key, completion_arguments, 0.9)
		return
	_weapon_ultimate_sequence = sequence
	_weapon_ultimate_sequence_index = 0
	_weapon_ultimate_phase_elapsed = 0.0
	_weapon_ultimate_sequence_pending_start = true
	_weapon_ultimate_completion_feedback_key = completion_key
	_weapon_ultimate_completion_feedback_arguments = completion_arguments.duplicate()


func _begin_weapon_ultimate_phase() -> void:
	if _weapon_ultimate_sequence_index < 0 or _weapon_ultimate_sequence_index >= _weapon_ultimate_sequence.size():
		_finish_weapon_ultimate_sequence()
		return
	var phase: Dictionary = _weapon_ultimate_sequence[_weapon_ultimate_sequence_index]
	var phase_kind: StringName = StringName(phase["kind"])
	var guard_duration: float = float(phase.get("guard_duration", 0.0))
	if guard_duration > 0.0:
		_damage_guard_remaining = maxf(_damage_guard_remaining, guard_duration)
	match phase_kind:
		&"mace_ground_telegraph":
			_call_combat_visual(&"show_mace_ground_telegraph", [phase["position"], DontDodgeTuning.ULTIMATE_RADIUS, phase["duration"] + DontDodgeTuning.MACE_GROUND_SUPPRESSION_IMPACT])
		&"mace_ground_impact":
			_perform_mace_ground_impact()
		&"mace_frontline_telegraph":
			_call_combat_visual(&"show_mace_frontline_target", [phase["start"], phase["end"], phase.get("target"), phase["duration"] + DontDodgeTuning.MACE_FRONTLINE_BREAK_IMPACT])
			_call_combat_visual(&"show_ultimate_dash", [phase["start"], phase["end"], phase["duration"] + DontDodgeTuning.MACE_FRONTLINE_BREAK_IMPACT])
		&"mace_frontline_impact":
			_perform_mace_frontline_impact(phase)
		&"spear_sky_telegraph":
			var sky_pierce_visual_duration: float = phase["duration"] + (DontDodgeTuning.SPEAR_SKY_PIERCE_IMPACT + DontDodgeTuning.SPEAR_FORMATION_HIT_STOP) * DontDodgeTuning.SPEAR_SKY_PIERCE_PULSES
			_call_combat_visual(&"show_spear_line", [phase["start"], phase["end"], DontDodgeTuning.ULTIMATE_LINE_WIDTH, sky_pierce_visual_duration])
			if is_instance_valid(phase.get("target") as DontDodgeEnemy):
				_call_combat_visual(&"show_spear_target_marker", [phase["end"], phase.get("target"), sky_pierce_visual_duration])
		&"spear_sky_impact":
			_perform_spear_sky_pierce_impact(phase)
		&"spear_formation_telegraph":
			_call_combat_visual(&"show_spear_formation", [phase["line_start"], phase["line_end"], DontDodgeTuning.SPEAR_FORMATION_WIDTH, phase["duration"] + DontDodgeTuning.SPEAR_FORMATION_PULSE_INTERVAL * DontDodgeTuning.SPEAR_FORMATION_PULSES])
		&"spear_formation_pulse":
			_perform_spear_formation_pulse(phase)


func _update_weapon_ultimate_sequence(delta: float) -> void:
	_damage_guard_remaining = maxf(0.0, _damage_guard_remaining - delta)
	if _weapon_ultimate_sequence_index < 0 or _weapon_ultimate_sequence_index >= _weapon_ultimate_sequence.size():
		_finish_weapon_ultimate_sequence()
		return
	var phase: Dictionary = _weapon_ultimate_sequence[_weapon_ultimate_sequence_index]
	var phase_duration: float = float(phase["duration"])
	_weapon_ultimate_phase_elapsed += delta
	if _weapon_ultimate_phase_elapsed < phase_duration:
		return
	_weapon_ultimate_sequence_index += 1
	_weapon_ultimate_phase_elapsed = 0.0
	_begin_weapon_ultimate_phase()


func _finish_weapon_ultimate_sequence() -> void:
	var completion_key: StringName = _weapon_ultimate_completion_feedback_key
	var completion_arguments: Array = _weapon_ultimate_completion_feedback_arguments.duplicate()
	_weapon_ultimate_sequence.clear()
	_weapon_ultimate_sequence_index = -1
	_weapon_ultimate_phase_elapsed = 0.0
	_weapon_ultimate_sequence_pending_start = false
	_weapon_ultimate_completion_feedback_key = &""
	_weapon_ultimate_completion_feedback_arguments.clear()
	if not completion_key.is_empty():
		_show_feedback_key(completion_key, completion_arguments, 0.9)


func _perform_mace_ground_suppression() -> void:
	var position: Vector2 = _player.global_position
	_start_weapon_ultimate_sequence([
		{
			"kind": &"mace_ground_telegraph",
			"position": position,
			"duration": DontDodgeTuning.MACE_GROUND_SUPPRESSION_TELEGRAPH,
			"guard_duration": DontDodgeTuning.MACE_GROUND_SUPPRESSION_TELEGRAPH + 0.18,
		},
		{
			"kind": &"mace_ground_impact",
			"duration": DontDodgeTuning.MACE_GROUND_SUPPRESSION_IMPACT,
			"guard_duration": 0.18,
		},
	], &"feedback.ground_suppression_complete")


func _perform_mace_ground_impact() -> void:
	_call_combat_visual(&"show_radial_strike", [_player.global_position, DontDodgeTuning.ULTIMATE_RADIUS])
	var defeated_normals: int = 0
	var staggered_threats: int = 0
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_combat_active() or enemy.global_position.distance_to(_player.global_position) > DontDodgeTuning.ULTIMATE_RADIUS:
			continue
		var is_threat: bool = enemy.get_enemy_type() == DontDodgeEnemy.EnemyType.ELITE or enemy.get_enemy_type() == DontDodgeEnemy.EnemyType.CHARGER
		if is_threat:
			_hit_enemy(enemy, DontDodgeTuning.ULTIMATE_ELITE_DAMAGE, DontDodgeTuning.ULTIMATE_KNOCKBACK, false)
			enemy.force_interrupt()
			staggered_threats += 1
		else:
			_hit_enemy(enemy, 99, DontDodgeTuning.ULTIMATE_KNOCKBACK, false)
			defeated_normals += 1
	_request_hit_stop(DontDodgeTuning.MACE_ULTIMATE_HIT_STOP)
	_call_screen_feedback(&"trigger_impact", [9.0, 0.1, Color(1.0, 0.62, 0.2), 0.1])
	_show_feedback_key(&"feedback.ground_suppression", [defeated_normals, staggered_threats], 0.9)


func _perform_mace_frontline_break() -> void:
	var target: DontDodgeEnemy = _find_strongest_ranged_enemy()
	var start_position: Vector2 = _player.global_position
	var direction: Vector2 = _player.get_last_move_direction().normalized()
	if is_instance_valid(target):
		direction = (target.global_position - start_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var arrival: Vector2
	if is_instance_valid(target):
		var target_distance: float = start_position.distance_to(target.global_position)
		var arrival_offset: float = minf(DontDodgeTuning.MACE_FRONTLINE_BREAK_ARRIVAL_OFFSET, maxf(0.0, target_distance - DontDodgeTuning.PLAYER_RADIUS))
		arrival = target.global_position - direction * arrival_offset
	else:
		arrival = start_position + direction * DontDodgeTuning.MACE_FRONTLINE_BREAK_FALLBACK_DISTANCE
	arrival = arrival.clamp(Vector2.ONE * DontDodgeTuning.PLAYER_RADIUS, DontDodgeTuning.ARENA_SIZE - Vector2.ONE * DontDodgeTuning.PLAYER_RADIUS)
	_start_weapon_ultimate_sequence([
		{
			"kind": &"mace_frontline_telegraph",
			"target": target,
			"start": start_position,
			"end": arrival,
			"duration": DontDodgeTuning.MACE_FRONTLINE_BREAK_TELEGRAPH,
			"guard_duration": DontDodgeTuning.MACE_FRONTLINE_BREAK_TELEGRAPH + 0.3,
		},
		{
			"kind": &"mace_frontline_impact",
			"target": target,
			"start": start_position,
			"end": arrival,
			"duration": DontDodgeTuning.MACE_FRONTLINE_BREAK_IMPACT,
			"guard_duration": DontDodgeTuning.ULTIMATE_FRONTLINE_INVULNERABILITY,
		},
	], &"feedback.frontline_break_complete")


func _perform_mace_frontline_impact(phase: Dictionary) -> void:
	var start_position: Vector2 = phase["start"]
	var arrival: Vector2 = phase["end"]
	_player.global_position = arrival
	_damage_guard_remaining = maxf(_damage_guard_remaining, DontDodgeTuning.ULTIMATE_FRONTLINE_INVULNERABILITY)
	_clear_projectiles_on_route(start_position, arrival, 64.0)
	_call_combat_visual(&"show_radial_strike", [_player.global_position, DontDodgeTuning.ULTIMATE_FRONTLINE_RADIUS])
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_combat_active():
			continue
		if enemy.global_position.distance_to(_player.global_position) <= DontDodgeTuning.ULTIMATE_FRONTLINE_RADIUS:
			_hit_enemy(enemy, DontDodgeTuning.ULTIMATE_ELITE_DAMAGE, DontDodgeTuning.ULTIMATE_KNOCKBACK, false)
			if enemy.get_enemy_type() == DontDodgeEnemy.EnemyType.ELITE or enemy.get_enemy_type() == DontDodgeEnemy.EnemyType.CHARGER:
				enemy.force_interrupt()
	_request_hit_stop(DontDodgeTuning.MACE_ULTIMATE_HIT_STOP)
	_call_screen_feedback(&"trigger_impact", [8.0, 0.1, Color(1.0, 0.62, 0.2), 0.1])


func _perform_spear_sky_pierce() -> void:
	var origin_position: Vector2 = _player.global_position
	var target: DontDodgeEnemy = _find_strongest_enemy(99999.0)
	var direction: Vector2 = _player.get_last_move_direction().normalized()
	if is_instance_valid(target):
		direction = (target.global_position - origin_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var start_position: Vector2 = _get_arena_boundary_position(origin_position, -direction)
	var end_position: Vector2 = _get_arena_boundary_position(origin_position, direction)
	var sequence: Array[Dictionary] = [{
		"kind": &"spear_sky_telegraph",
		"target": target,
		"start": start_position,
		"end": end_position,
		"duration": DontDodgeTuning.SPEAR_SKY_PIERCE_TELEGRAPH,
		"guard_duration": DontDodgeTuning.SPEAR_SKY_PIERCE_TELEGRAPH + 0.12,
	}]
	for pulse_index: int in DontDodgeTuning.SPEAR_SKY_PIERCE_PULSES:
		sequence.append({
			"kind": &"spear_sky_impact",
			"pulse_index": pulse_index,
			"start": start_position,
			"end": end_position,
			"duration": DontDodgeTuning.SPEAR_SKY_PIERCE_IMPACT,
			"guard_duration": 0.12,
		})
	_start_weapon_ultimate_sequence(sequence, &"feedback.sky_pierce_complete")


func _get_arena_boundary_position(start_position: Vector2, direction: Vector2) -> Vector2:
	var ray_direction: Vector2 = direction.normalized()
	if ray_direction == Vector2.ZERO:
		ray_direction = Vector2.RIGHT
	var arena_min: Vector2 = Vector2.ONE * DontDodgeTuning.PLAYER_RADIUS
	var arena_max: Vector2 = DontDodgeTuning.ARENA_SIZE - Vector2.ONE * DontDodgeTuning.PLAYER_RADIUS
	var distance_to_boundary: float = INF
	if absf(ray_direction.x) > 0.0001:
		var boundary_x: float = arena_max.x if ray_direction.x > 0.0 else arena_min.x
		distance_to_boundary = minf(distance_to_boundary, (boundary_x - start_position.x) / ray_direction.x)
	if absf(ray_direction.y) > 0.0001:
		var boundary_y: float = arena_max.y if ray_direction.y > 0.0 else arena_min.y
		distance_to_boundary = minf(distance_to_boundary, (boundary_y - start_position.y) / ray_direction.y)
	return start_position + ray_direction * maxf(0.0, distance_to_boundary)


func _perform_spear_sky_pierce_impact(phase: Dictionary) -> void:
	var start_position: Vector2 = phase["start"]
	var end_position: Vector2 = phase["end"]
	_clear_projectiles_on_route(start_position, end_position, DontDodgeTuning.ULTIMATE_LINE_WIDTH)
	var segment: Vector2 = end_position - start_position
	var segment_length_squared: float = maxf(1.0, segment.length_squared())
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_combat_active():
			continue
		var progress: float = clampf((enemy.global_position - start_position).dot(segment) / segment_length_squared, 0.0, 1.0)
		var closest_point: Vector2 = start_position + segment * progress
		if enemy.global_position.distance_to(closest_point) > DontDodgeTuning.ULTIMATE_LINE_WIDTH:
			continue
		_hit_enemy(enemy, DontDodgeTuning.SPEAR_SKY_PIERCE_DAMAGE, DontDodgeTuning.ULTIMATE_KNOCKBACK * 0.25, false)
	_request_hit_stop(DontDodgeTuning.SPEAR_FORMATION_HIT_STOP)
	_call_screen_feedback(&"trigger_impact", [8.0, 0.1, Color(0.56, 0.84, 1.0), 0.1])


func _perform_spear_formation() -> void:
	var direction: Vector2 = _get_spear_formation_direction()
	var start_position: Vector2 = _player.global_position
	var line_start: Vector2 = _get_arena_boundary_position(start_position, -direction)
	var line_end: Vector2 = _get_arena_boundary_position(start_position, direction)
	var sequence: Array[Dictionary] = [{
		"kind": &"spear_formation_telegraph",
		"start": start_position,
		"direction": direction,
		"line_start": line_start,
		"line_end": line_end,
		"duration": DontDodgeTuning.SPEAR_FORMATION_TELEGRAPH,
		"guard_duration": DontDodgeTuning.SPEAR_FORMATION_TELEGRAPH + 0.12,
	}]
	for pulse_index: int in DontDodgeTuning.SPEAR_FORMATION_PULSES:
		sequence.append({
			"kind": &"spear_formation_pulse",
			"pulse_index": pulse_index,
			"start": start_position,
			"direction": direction,
			"line_start": line_start,
			"line_end": line_end,
			"duration": DontDodgeTuning.SPEAR_FORMATION_PULSE_INTERVAL,
		})
	_start_weapon_ultimate_sequence(sequence, &"feedback.spear_formation_complete")


func _get_spear_formation_direction() -> Vector2:
	var target: DontDodgeEnemy = _find_priority_enemy(INF)
	if not is_instance_valid(target):
		target = _find_nearest_enemy(INF)
	if is_instance_valid(target):
		var to_target: Vector2 = target.global_position - _player.global_position
		if to_target != Vector2.ZERO:
			return to_target.normalized()
	var direction: Vector2 = _player.get_last_move_direction().normalized()
	return direction if direction != Vector2.ZERO else Vector2.RIGHT


func _perform_spear_formation_pulse(phase: Dictionary) -> void:
	var segment_start: Vector2 = phase["line_start"]
	var segment_end: Vector2 = phase["line_end"]
	_call_combat_visual(&"show_spear_formation_pulse", [segment_start, segment_end, DontDodgeTuning.SPEAR_FORMATION_WIDTH, int(phase["pulse_index"])])
	var segment: Vector2 = segment_end - segment_start
	var segment_length_squared: float = maxf(1.0, segment.length_squared())
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_combat_active():
			continue
		var progress: float = clampf((enemy.global_position - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
		var closest_point: Vector2 = segment_start + segment * progress
		if enemy.global_position.distance_to(closest_point) <= DontDodgeTuning.SPEAR_FORMATION_WIDTH:
			_hit_enemy(enemy, DontDodgeTuning.SPEAR_FORMATION_DAMAGE, DontDodgeTuning.FOCUS_KNOCKBACK * 0.25, false)
	_request_hit_stop(DontDodgeTuning.SPEAR_FORMATION_HIT_STOP)


func _spawn_due_enemies() -> void:
	if _spawn_schedule.is_empty():
		return
	for schedule_index: int in _spawn_schedule.size():
		var entry: Dictionary = _spawn_schedule[schedule_index]
		if bool(entry.get("dispatched", false)) or int(entry["slot_index"]) != _active_slot_index or float(entry["time"]) > _elapsed:
			continue
		_begin_spawn_warning(entry)
		entry["dispatched"] = true
		_spawn_schedule[schedule_index] = entry
		_next_spawn_index += 1


func _spawn_enemy(enemy_type: int, position: Vector2, pattern_context: Dictionary = {}) -> DontDodgeEnemy:
	var enemy: DontDodgeEnemy = ENEMY_SCRIPT.new()
	enemy.global_position = position
	enemy.setup(enemy_type, _player, pattern_context)
	if float(pattern_context.get("spawn_lock", 0.0)) > 0.0:
		enemy.set_meta(&"skip_first_advance", true)
	enemy.strike_landed.connect(_on_enemy_strike_landed)
	enemy.projectile_fired.connect(_on_enemy_projectile_fired)
	enemy.defeated.connect(_on_enemy_defeated)
	add_child(enemy)
	_enemies.append(enemy)
	return enemy


func _update_combat_state() -> void:
	if _mode == &"training":
		return
	if _state == GameState.COMBAT:
		if _elapsed >= DontDodgeTuning.SESSION_DURATION:
			_enter_final_cleanup()
			return
		if _is_current_slot_expired():
			if _can_advance_current_slot():
				_advance_slot()
			else:
				_enter_threat_gate()
		return
	if _state == GameState.THREAT_GATE:
		if _can_advance_current_slot():
			_advance_slot()
		return
	if _state == GameState.FINAL_CLEANUP:
		_cleanup_safe_projectiles()
		if _living_enemy_count() > 0 or _active_projectile_count() > 0:
			return
		_waves_cleared = DontDodgeTuning.WAVE_COUNT
		_finish_run(&"result.clear", [DontDodgeTuning.WAVE_COUNT], "clear")


func _is_current_slot_expired() -> bool:
	if _active_slot_index < 0 or _active_slot_index >= _timeline.size():
		return false
	var slot: Dictionary = _timeline[_active_slot_index]
	if str(slot["kind"]) == "recovery":
		return true
	if _has_undispatched_events_for_slot(_active_slot_index):
		return false
	if not bool(slot.get("allow_early_advance", false)):
		return _elapsed >= float(slot["start_time"]) + float(slot["slot_duration"])
	var context: Dictionary = _pattern_contexts.get(_active_slot_index, {})
	if context.is_empty():
		return false
	return _elapsed >= float(context.get("started_at", _elapsed)) + float(slot["minimum_resolution_time"])


func _has_undispatched_events_for_slot(slot_index: int) -> bool:
	for entry: Dictionary in _spawn_schedule:
		if int(entry["slot_index"]) == slot_index and not bool(entry.get("dispatched", false)):
			return true
	return false


func _can_advance_current_slot() -> bool:
	if _active_slot_index < 0 or _active_slot_index >= _timeline.size():
		return true
	var slot: Dictionary = _timeline[_active_slot_index]
	if str(slot["kind"]) == "recovery":
		return true
	if _has_undispatched_events_for_slot(_active_slot_index):
		return false
	var context: Dictionary = _pattern_contexts.get(_active_slot_index, {})
	var instance_id: String = str(context.get("instance_id", ""))
	if _has_pending_warning_for_instance(instance_id):
		return false
	var advance: Dictionary = slot["advance"]
	var required_roles: Array = advance.get("required_roles_cleared", [])
	for role_value: Variant in required_roles:
		if _has_living_pattern_enemy(instance_id, str(role_value)):
			return false
	if _pattern_living_enemy_count(instance_id) > int(advance.get("max_alive_enemies", 0)):
		return false
	var max_total_enemies: int = int(advance.get("max_total_enemies", 0))
	if _living_enemy_count() > max_total_enemies:
		return false
	if _active_tell_count() > int(advance.get("max_active_tells", 0)):
		return false
	return _active_projectile_count() <= int(advance.get("max_projectiles", 0))


func _has_living_pattern_enemy(instance_id: String, role: String) -> bool:
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.get_health() <= 0:
			continue
		if enemy.get_pattern_instance_id() == instance_id and enemy.get_pattern_role() == role:
			return true
	for warning: Dictionary in _spawn_warnings:
		if str(warning["pattern_instance_id"]) == instance_id and str(warning["role"]) == role:
			return true
	return false


func _pattern_living_enemy_count(instance_id: String) -> int:
	var count: int = 0
	for enemy: DontDodgeEnemy in _enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.get_health() > 0 and enemy.get_pattern_instance_id() == instance_id:
			count += 1
	for warning: Dictionary in _spawn_warnings:
		if str(warning["pattern_instance_id"]) == instance_id:
			count += 1
	return count


func _active_tell_count() -> int:
	var count: int = _spawn_warnings.size()
	for enemy: DontDodgeEnemy in _enemies:
		if is_instance_valid(enemy) and enemy.is_winding_up():
			count += 1
	return count


func _has_pending_warning_for_instance(instance_id: String) -> bool:
	for warning: Dictionary in _spawn_warnings:
		if str(warning["pattern_instance_id"]) == instance_id:
			return true
	return false


func _advance_slot() -> void:
	var completed_wave: int = int(_timeline[_active_slot_index]["wave_id"])
	_active_slot_index += 1
	if _active_slot_index >= _timeline.size():
		if _elapsed >= DontDodgeTuning.SESSION_DURATION:
			_enter_final_cleanup()
			return
		_final_relay_cycle += 1
		_active_slot_index = _timeline.size() - 2
		_start_slot(_active_slot_index)
		_record_state(GameState.COMBAT, "final_relay_repeat")
		return
	var next_wave: int = int(_timeline[_active_slot_index]["wave_id"])
	if next_wave > completed_wave:
		_waves_cleared = maxi(_waves_cleared, completed_wave)
		_waves_reached = maxi(_waves_reached, next_wave)
		_emit_sound_event(SOUND_EVENT_WAVE_STARTED, _player.global_position)
		_show_feedback_key(&"feedback.wave_pressure", [next_wave], 0.9)
	_start_slot(_active_slot_index)
	_record_state(GameState.COMBAT, "slot_advanced")


func _start_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _timeline.size():
		return
	var slot: Dictionary = _timeline[slot_index]
	if str(slot["kind"]) == "recovery":
		_state_events.append({"state": "RECOVERY_SLOT", "active_time": snappedf(_elapsed, 0.001), "slot_index": slot_index})
		return
	var axis: Vector2 = _get_pattern_axis(slot)
	var instance_id: String = "%s_%02d_%02d" % [str(slot["id"]), slot_index, _final_relay_cycle]
	_pattern_contexts[slot_index] = {
		"instance_id": instance_id,
		"pattern_id": str(slot["id"]),
		"axis": axis,
		"origin": _player.global_position,
		"mirror": str(slot.get("variant", "")) == "mirror",
		"slot_index": slot_index,
		"started_at": _elapsed,
	}
	_activate_slot_events(slot_index)
	_state_events.append({"state": "PATTERN_START", "pattern_id": str(slot["id"]), "instance_id": instance_id, "active_time": snappedf(_elapsed, 0.001), "slot_index": slot_index})
	_request_hud_refresh()


func _get_pattern_axis(slot: Dictionary) -> Vector2:
	var axis: Vector2 = _player.get_recent_move_direction(0.4)
	if axis == Vector2.ZERO:
		axis = (DontDodgeTuning.ARENA_SIZE * 0.5 - _player.global_position).normalized()
	if axis == Vector2.ZERO:
		axis = Vector2.UP
	if str(slot.get("variant", "")) == "rotate":
		axis = axis.rotated(_random.randf_range(-deg_to_rad(18.0), deg_to_rad(18.0)))
	return _find_valid_pattern_axis(axis, slot)


func _find_valid_pattern_axis(axis: Vector2, slot: Dictionary) -> Vector2:
	var candidates: Array[float] = [0.0, deg_to_rad(15.0), -deg_to_rad(15.0), deg_to_rad(30.0), -deg_to_rad(30.0), deg_to_rad(45.0), -deg_to_rad(45.0), deg_to_rad(60.0), -deg_to_rad(60.0), PI]
	for angle: float in candidates:
		var candidate: Vector2 = axis.rotated(angle)
		var valid: bool = true
		for event: Dictionary in slot["events"]:
			var rule: String = str(event["position_rule"])
			if rule.begins_with("S:") and not _is_valid_spawn_position(_position_from_rule(_player.global_position, candidate, rule, float(event["distance"]), str(slot.get("variant", "")) == "mirror")):
				valid = false
				break
		if valid:
			return candidate
	return axis


func _enter_threat_gate() -> void:
	_cancel_pending_spawn_warnings("threat_gate")
	_threat_gate_elapsed = 0.0
	_record_state(GameState.THREAT_GATE, "slot_conditions_unmet")


func _enter_final_cleanup() -> void:
	_cancel_pending_spawn_warnings("final_cleanup")
	_cleanup_elapsed = 0.0
	_record_state(GameState.FINAL_CLEANUP, "scheduled_combat_complete")


func _cleanup_safe_projectiles() -> void:
	if _cleanup_elapsed < DontDodgeTuning.PROJECTILE_CLEANUP_GRACE_SECONDS:
		return
	for projectile: DontDodgeProjectile in _projectiles:
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion() and projectile.is_moving_away_from(_player.global_position):
			projectile.queue_free()


func _update_player_death(delta: float) -> void:
	_update_visual_timers(delta)
	_death_presentation_remaining = maxf(0.0, _death_presentation_remaining - delta)
	if _death_presentation_remaining <= 0.0:
		_finish_run(&"result.death", [], "death")


func _enter_player_dead() -> void:
	if _state == GameState.PLAYER_DEAD or _ended:
		return
	_cancel_pending_spawn_warnings("player_dead")
	_input_source.clear_requests()
	_death_record = {
		"death_wave_id": mini(_waves_cleared + 1, DontDodgeTuning.WAVE_COUNT),
		"death_pattern_id": _get_current_pattern_id(),
		"death_active_time": snappedf(_elapsed, 0.001),
		"death_hazard_id": _last_hazard_id,
	}
	_death_presentation_remaining = DontDodgeTuning.PLAYER_DEATH_PRESENTATION_SECONDS
	_record_state(GameState.PLAYER_DEAD, "player_health_zero")


func _get_current_pattern_id() -> String:
	if _active_slot_index >= 0 and _active_slot_index < _timeline.size():
		return str(_timeline[_active_slot_index]["id"])
	return ""


func _living_enemy_count() -> int:
	var count := 0
	for enemy: DontDodgeEnemy in _enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.get_health() > 0:
			count += 1
	return count


func _active_projectile_count() -> int:
	var count := 0
	for projectile: DontDodgeProjectile in _projectiles:
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
			count += 1
	return count


func _spawn_due_hearts() -> void:
	if _challenge_disables_hearts():
		return
	while _next_heart_spawn_at < DontDodgeTuning.SESSION_DURATION and _elapsed >= _next_heart_spawn_at:
		_spawn_heart(_random_heart_spawn_position())
		_next_heart_spawn_at += DontDodgeTuning.HEART_SPAWN_INTERVAL


func _spawn_heart(position: Vector2) -> DontDodgeHeart:
	if _hearts.size() >= DontDodgeTuning.HEART_FIELD_MAX:
		return null
	var heart: DontDodgeHeart = HEART_SCRIPT.new()
	heart.global_position = position.clamp(Vector2.ONE * 28.0, DontDodgeTuning.ARENA_SIZE - Vector2.ONE * 28.0)
	add_child(heart)
	_hearts.append(heart)
	_stats["heart_spawns"] += 1
	return heart


func _spawn_experience_orb(position: Vector2, value: int) -> DontDodgeExperienceOrb:
	if _experience_level >= DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS.size() or _experience_orbs.size() >= DontDodgeTuning.EXPERIENCE_FIELD_MAX:
		return null
	var orb: DontDodgeExperienceOrb = EXPERIENCE_ORB_SCRIPT.new()
	orb.setup(value)
	orb.global_position = position.clamp(Vector2.ONE * 24.0, DontDodgeTuning.ARENA_SIZE - Vector2.ONE * 24.0)
	add_child(orb)
	_experience_orbs.append(orb)
	_stats["experience_spawned"] = int(_stats["experience_spawned"]) + orb.get_value()
	return orb


func _random_heart_spawn_position() -> Vector2:
	var angle: float = _random.randf_range(0.0, TAU)
	var offset: Vector2 = Vector2.RIGHT.rotated(angle) * _random.randf_range(240.0, 380.0)
	return (_player.global_position + offset).clamp(Vector2.ONE * 56.0, DontDodgeTuning.ARENA_SIZE - Vector2.ONE * 56.0)


func _update_enemies(delta: float) -> void:
	for enemy: DontDodgeEnemy in _enemies:
		if is_instance_valid(enemy):
			if bool(enemy.get_meta(&"skip_first_advance", false)):
				enemy.set_meta(&"skip_first_advance", false)
				continue
			enemy.advance(delta)


func _update_hearts(delta: float) -> void:
	for heart: DontDodgeHeart in _hearts:
		if not is_instance_valid(heart) or heart.is_queued_for_deletion():
			continue
		if not heart.advance(delta):
			heart.queue_free()
			continue
		if heart.global_position.distance_squared_to(_player.global_position) > DontDodgeTuning.HEART_PICKUP_RADIUS * DontDodgeTuning.HEART_PICKUP_RADIUS:
			continue
		var recovered: int = _player.heal(DontDodgeTuning.HEART_HEAL_AMOUNT)
		if recovered <= 0:
			continue
		_stats["hearts_absorbed"] += recovered
		heart.queue_free()
		_request_hud_refresh()


func _update_experience_orbs(delta: float) -> void:
	for orb: DontDodgeExperienceOrb in _experience_orbs:
		if not is_instance_valid(orb) or orb.is_queued_for_deletion():
			continue
		if not orb.advance(delta):
			orb.queue_free()
			continue
		if orb.global_position.distance_squared_to(_player.global_position) > DontDodgeTuning.EXPERIENCE_PICKUP_RADIUS * DontDodgeTuning.EXPERIENCE_PICKUP_RADIUS:
			continue
		var value: int = orb.get_value()
		orb.queue_free()
		_grant_experience(value)


func _grant_experience(amount: int) -> void:
	if _mode == &"training" or amount <= 0 or _experience_level >= DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS.size():
		return
	_experience += amount
	_stats["experience_collected"] = int(_stats["experience_collected"]) + amount
	_request_hud_refresh()
	_try_open_experience_upgrade()


func _try_open_experience_upgrade() -> void:
	if _ended or _pause_mode != PauseMode.NONE or _experience_level >= DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS.size():
		return
	var next_threshold: int = int(DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS[_experience_level])
	if _experience < next_threshold:
		return
	_experience_level += 1
	_stats["experience_levels"] = _experience_level
	_open_experience_upgrade(_experience_level)


func _update_projectiles(delta: float) -> void:
	for projectile: DontDodgeProjectile in _projectiles:
		if not is_instance_valid(projectile) or projectile.is_queued_for_deletion():
			continue
		if not projectile.advance(delta):
			projectile.queue_free()
			continue
		if _guard_remaining > 0.0 and not projectile.is_reflected() and _is_in_guard_arc(projectile.global_position) and projectile.global_position.distance_to(_player.global_position) <= DontDodgeTuning.NEGATE_RADIUS:
			_reflect_projectile(projectile)
			continue
		if projectile.is_reflected():
			var reflected_hit: bool = false
			var reflected_target: DontDodgeEnemy
			for enemy: DontDodgeEnemy in _enemies:
				if not is_instance_valid(enemy) or not enemy.is_combat_active():
					continue
				if enemy.global_position.distance_to(projectile.global_position) <= DontDodgeProjectile.RADIUS + DontDodgeTuning.PLAYER_RADIUS:
					_hit_enemy(enemy, 2, DontDodgeTuning.NEGATE_KNOCKBACK * 0.35)
					reflected_hit = true
					reflected_target = enemy
					break
			if reflected_hit:
				if _has_technique("tech_mace_reflect_wave"):
					_call_combat_visual(&"show_reflect_wave", [projectile.global_position, DontDodgeTuning.MACE_REFLECT_WAVE_RADIUS])
					var splash_count: int = 0
					for enemy: DontDodgeEnemy in _enemies:
						if enemy == reflected_target or not is_instance_valid(enemy) or not enemy.is_combat_active():
							continue
						if enemy.global_position.distance_to(projectile.global_position) <= DontDodgeTuning.MACE_REFLECT_WAVE_RADIUS:
							_hit_enemy(enemy, DontDodgeTuning.MACE_REFLECT_WAVE_SPLASH_DAMAGE, DontDodgeTuning.NEGATE_KNOCKBACK * 0.2)
							splash_count += 1
							if splash_count >= DontDodgeTuning.MACE_REFLECT_WAVE_MAX_SPLASH_TARGETS:
								break
				projectile.queue_free()
				continue
		if projectile.global_position.distance_to(_player.global_position) <= DontDodgeProjectile.RADIUS + DontDodgeTuning.PLAYER_RADIUS:
			_resolve_hazard_contact(str(projectile.get_meta(&"hazard_id", "projectile")))
			projectile.queue_free()


func _on_enemy_strike_landed(enemy: DontDodgeEnemy, impact_position: Vector2, impact_radius: float) -> void:
	_emit_sound_event(SOUND_EVENT_ENEMY_ATTACK, enemy.global_position)
	_spawn_melee_impact_feedback(impact_position, impact_radius)
	if _guard_remaining > 0.0 and _is_in_guard_arc(impact_position):
		enemy.force_interrupt()
		_register_guard_success()
		return
	if _player.global_position.distance_to(impact_position) <= impact_radius + DontDodgeTuning.PLAYER_RADIUS:
		_resolve_hazard_contact(enemy.get_hazard_id())


func _is_in_guard_arc(world_position: Vector2) -> bool:
	var to_position: Vector2 = world_position - _player.global_position
	if to_position == Vector2.ZERO:
		return true
	return absf(_guard_direction.angle_to(to_position.normalized())) <= deg_to_rad(DontDodgeTuning.GUARD_ARC_DEGREES) * 0.5


func _register_guard_success() -> void:
	_guard_successful = true
	_mace_counter_remaining = DontDodgeTuning.MACE_COUNTER_DURATION if _has_technique("tech_mace_counter") else 0.0
	_stats["interrupts"] += 1
	_grant_ultimate(DontDodgeTuning.ULTIMATE_INTERRUPT_FIRST, "guard_success")
	_call_combat_visual(&"show_guard_success", [_player.global_position, _guard_direction])
	_show_feedback_key(&"feedback.counter_ready", [], 0.65)


func _reflect_projectile(projectile: DontDodgeProjectile) -> void:
	var target: DontDodgeEnemy = _find_strongest_enemy(99999.0)
	var reflected_direction: Vector2 = _guard_direction
	if is_instance_valid(target):
		reflected_direction = (target.global_position - projectile.global_position).normalized()
		if reflected_direction == Vector2.ZERO:
			reflected_direction = _guard_direction
	var reflected: DontDodgeProjectile = PROJECTILE_SCRIPT.new()
	reflected.setup(projectile.global_position, projectile.global_position + reflected_direction * 800.0)
	reflected.mark_reflected()
	reflected.set_meta(&"reflected", true)
	reflected.set_meta(&"hazard_id", "reflected_projectile")
	add_child(reflected)
	_projectiles.append(reflected)
	projectile.queue_free()
	_stats["projectiles_erased"] += 1
	_register_guard_success()
	_call_combat_visual(&"show_reflect_burst", [projectile.global_position, reflected_direction])


func _on_enemy_projectile_fired(enemy: DontDodgeEnemy, origin: Vector2, target_position: Vector2, projectile_count: int, total_spread_degrees: float) -> void:
	_emit_sound_event(SOUND_EVENT_ENEMY_ATTACK, enemy.global_position)
	_queue_combat_hint(CombatHint.NEGATE)
	if enemy.get_enemy_type() == DontDodgeEnemy.EnemyType.VOLLEY:
		projectile_count += _get_challenge_volley_bonus()
	var target_direction: Vector2 = (target_position - origin).normalized()
	if target_direction == Vector2.ZERO:
		target_direction = Vector2.RIGHT
	for projectile_index: int in projectile_count:
		var angle_offset: float = 0.0
		if projectile_count > 1:
			var spread_progress: float = float(projectile_index) / float(projectile_count - 1)
			angle_offset = deg_to_rad(lerpf(-total_spread_degrees * 0.5, total_spread_degrees * 0.5, spread_progress))
		var projectile: DontDodgeProjectile = PROJECTILE_SCRIPT.new()
		projectile.setup(origin, origin + target_direction.rotated(angle_offset) * 800.0)
		projectile.set_meta(&"hazard_id", "%s_projectile_%d" % [enemy.get_hazard_id(), projectile_index])
		add_child(projectile)
		_projectiles.append(projectile)


func _resolve_hazard_contact(hazard_id: String = "unknown") -> void:
	if _damage_guard_remaining > 0.0:
		return
	if _player.is_invulnerable():
		if _player.consume_perfect_dodge():
			_stats["perfect_dodges"] += 1
			_grant_ultimate(DontDodgeTuning.ULTIMATE_PERFECT_DODGE, "perfect_dodge")
			_on_perfect_dodge()
		return
	_last_hazard_id = hazard_id
	_player.receive_damage()


func _on_perfect_dodge() -> void:
	_emit_sound_event(SOUND_EVENT_PERFECT_DODGE, _player.global_position)
	_show_feedback_key(&"feedback.perfect_dodge", [], 0.75)
	_call_screen_feedback(&"trigger_impact", [3.0, 0.05, Color(1.0, 0.86, 0.34), 0.08])


func _on_player_took_damage(remaining_health: int) -> void:
	_stats["hits_taken"] += 1
	_request_hud_refresh()
	_emit_sound_event(SOUND_EVENT_PLAYER_HIT, _player.global_position)
	_request_hit_stop(DontDodgeTuning.HIT_STOP_PLAYER_DAMAGE)
	_call_screen_feedback(&"trigger_impact", [4.0, 0.08, Color(0.9, 0.16, 0.12), 0.10])
	_spawn_player_damage_feedback(_player.global_position)
	if remaining_health <= 0:
		_enter_player_dead()


func _on_enemy_defeated(enemy: DontDodgeEnemy) -> void:
	_stats["kills"] += 1
	_emit_sound_event(SOUND_EVENT_ENEMY_DEFEATED, enemy.global_position)
	if enemy.get_enemy_type() == DontDodgeEnemy.EnemyType.ELITE:
		_request_hit_stop(DontDodgeTuning.HIT_STOP_ELITE_DEFEAT)
		_call_screen_feedback(&"trigger_impact", [7.0, 0.12, Color(1.0, 0.68, 0.22), 0.10])
	_grant_ultimate(DontDodgeTuning.ULTIMATE_PER_KILL, "kill")
	if _has_technique("tech_dagger_ghost_step"):
		_ghost_step_remaining = DontDodgeTuning.DAGGER_GHOST_STEP_DURATION
		_call_combat_visual(&"show_stealth_burst", [_player.global_position])
		_show_feedback_key(&"feedback.ghost_step", [], 0.5)
	if _is_gameplay_state() and _mode != &"training":
		var experience_value: int = DontDodgeTuning.EXPERIENCE_ELITE_DROP if enemy.get_enemy_type() == DontDodgeEnemy.EnemyType.ELITE else DontDodgeTuning.EXPERIENCE_NORMAL_DROP
		_spawn_experience_orb(enemy.global_position, experience_value)
	if enemy.get_enemy_type() == DontDodgeEnemy.EnemyType.ELITE and _is_gameplay_state() and _mode != &"training" and not _challenge_disables_hearts():
		var heart: DontDodgeHeart = _spawn_heart(enemy.global_position)
		if is_instance_valid(heart):
			_stats["elite_heart_drops"] += 1
			_show_feedback_key(&"feedback.elite_down", [], 1.1)


func _grant_ultimate(amount: int, source: String) -> void:
	if _ultimate_id.is_empty():
		return
	amount = _get_challenge_ultimate_amount(amount)
	if amount <= 0:
		return
	var was_ready: bool = _ultimate_charge >= DontDodgeTuning.ULTIMATE_MAX
	_ultimate_charge = mini(DontDodgeTuning.ULTIMATE_MAX, _ultimate_charge + amount)
	_ultimate_sources[source] = int(_ultimate_sources.get(source, 0)) + amount
	if not was_ready and _ultimate_charge >= DontDodgeTuning.ULTIMATE_MAX:
		_show_feedback_key(&"feedback.ultimate_ready", [], 1.2)


func _get_ultimate_percent() -> int:
	return roundi(float(_ultimate_charge) / float(DontDodgeTuning.ULTIMATE_MAX) * 100.0)


func _with_ultimate_ready(message: String) -> String:
	return message + _tr(&"feedback.ultimate_ready_suffix") if _ultimate_charge >= DontDodgeTuning.ULTIMATE_MAX else message


func _get_focus_damage() -> int:
	return DontDodgeTuning.FOCUS_DAMAGE


func _get_focus_range() -> float:
	var weapon: Dictionary = _get_weapon_data()
	var range_value: float = DontDodgeTuning.FOCUS_RANGE
	range_value *= float(weapon.get("range_multiplier", 1.0))
	range_value += float(weapon.get("range_bonus", 0.0))
	return range_value


func _get_focus_arc_angle() -> float:
	var weapon: Dictionary = _get_weapon_data()
	var arc_degrees: float = rad_to_deg(DontDodgeTuning.FOCUS_ARC_ANGLE) + float(weapon.get("arc_degrees_bonus", 0.0))
	return deg_to_rad(arc_degrees)


func _get_focus_knockback() -> float:
	var weapon: Dictionary = _get_weapon_data()
	return DontDodgeTuning.FOCUS_KNOCKBACK * float(weapon.get("knockback_multiplier", 1.0))


func _get_focus_recovery() -> float:
	return DontDodgeTuning.FOCUS_RECOVERY / _get_focus_attack_speed_multiplier()


func _get_focus_attack_speed_multiplier() -> float:
	var weapon: Dictionary = _get_weapon_data()
	return maxf(0.25, 1.0 + float(weapon.get("attack_speed_bonus", 0.0)))


func _get_player_move_speed() -> float:
	var weapon: Dictionary = _get_weapon_data()
	var bonus: float = float(weapon.get("move_speed_bonus", 0.0))
	if _ghost_step_remaining > 0.0:
		bonus += 0.2
	return DontDodgeTuning.PLAYER_MOVE_SPEED * (1.0 + bonus)


func _get_dodge_cost() -> int:
	var weapon: Dictionary = _get_weapon_data()
	return int(weapon.get("dodge_cost", 1))


func _is_negate_enabled() -> bool:
	if _weapon_id.is_empty():
		return true
	return bool(_get_weapon_data().get("negate_enabled", true))


func _get_weapon_data() -> Dictionary:
	return LOADOUT_DATA_SCRIPT.get_weapon(_weapon_id) if not _weapon_id.is_empty() else {}


func _get_weapon_title() -> String:
	return _localized_data_text(_get_weapon_data(), &"title_key", &"training.weapon_fallback")


func _get_technique_title() -> String:
	return _localized_data_text(_get_technique_data(), &"title_key", &"training.technique_fallback")


func _get_ultimate_title() -> String:
	return _localized_data_text(_get_ultimate_data(), &"title_key", &"training.ultimate_fallback")


func _has_technique(technique_id: String) -> bool:
	return _technique_id == technique_id


func _get_technique_data() -> Dictionary:
	return LOADOUT_DATA_SCRIPT.get_option(_technique_id) if not _technique_id.is_empty() else {}


func _get_ultimate_data() -> Dictionary:
	return LOADOUT_DATA_SCRIPT.get_option(_ultimate_id) if not _ultimate_id.is_empty() else {}


func _has_ultimate(ultimate_id: String) -> bool:
	return _ultimate_id == ultimate_id


func _apply_weapon_loadout() -> void:
	var weapon: Dictionary = _get_weapon_data()
	_player.configure_health(int(weapon.get("max_health", DontDodgeTuning.PLAYER_MAX_HEALTH)))
	_defense.set_max_charges(int(weapon.get("defense_max_charges", DontDodgeTuning.DEFENSE_MAX_CHARGES)), true)
	_last_action_defense_charges = -1
	_update_hud()


func _get_attack_target_limit() -> int:
	return int(_get_weapon_data().get("attack_target_limit", 0))


func _attack_pierces() -> bool:
	return bool(_get_weapon_data().get("attack_pierces", false))


func _get_focus_wedge_count() -> int:
	var count: int = 0
	for enemy: DontDodgeEnemy in _enemies:
		if is_instance_valid(enemy) and enemy.is_combat_active() and _is_in_focus_wedge(enemy):
			count += 1
	return count


func _get_attack_damage(enemy: DontDodgeEnemy) -> int:
	return _get_attack_damage_with_bonus(enemy, false)


func _get_attack_damage_with_bonus(enemy: DontDodgeEnemy, stealth_bonus: bool) -> int:
	var damage: int = DontDodgeTuning.FOCUS_DAMAGE
	if stealth_bonus:
		damage += 2
	if _has_technique("tech_spear_edge_pressure") and _player.global_position.distance_to(enemy.global_position) >= _get_focus_range() * 0.7:
		enemy.apply_slow(DontDodgeTuning.SPEAR_EDGE_PRESSURE_SLOW, DontDodgeTuning.SPEAR_EDGE_PRESSURE_DURATION)
		_spear_edge_pressure_target = enemy
		_spear_edge_pressure_remaining = DontDodgeTuning.SPEAR_EDGE_PRESSURE_DURATION
		if enemy.get_enemy_type() == DontDodgeEnemy.EnemyType.CHARGER or enemy.is_charging():
			enemy.force_interrupt()
		elif enemy.is_winding_up():
			enemy.interrupt()
		_call_combat_visual(&"show_spear_edge_pressure", [enemy.global_position, enemy])
	return damage


func _is_in_focus_wedge(enemy: DontDodgeEnemy) -> bool:
	var to_enemy: Vector2 = enemy.global_position - _player.global_position
	if to_enemy.length() > _get_focus_range() or to_enemy == Vector2.ZERO:
		return false
	return absf(_focus_attack_direction.angle_to(to_enemy.normalized())) <= _get_focus_arc_angle() * 0.5


func _find_priority_enemy(maximum_distance: float) -> DontDodgeEnemy:
	var selected: DontDodgeEnemy
	var best_threat_time: float = INF
	var best_distance: float = INF
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_combat_active():
			continue
		var distance: float = enemy.global_position.distance_to(_player.global_position)
		if distance > maximum_distance:
			continue
		var threat_time: float = enemy.get_threat_time()
		if selected == null or threat_time < best_threat_time or (is_equal_approx(threat_time, best_threat_time) and distance < best_distance):
			selected = enemy
			best_threat_time = threat_time
			best_distance = distance
	return selected


func _find_nearest_enemy(maximum_distance: float) -> DontDodgeEnemy:
	var selected: DontDodgeEnemy
	var best_distance: float = INF
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_combat_active():
			continue
		var distance: float = enemy.global_position.distance_to(_player.global_position)
		if distance > maximum_distance or distance >= best_distance:
			continue
		selected = enemy
		best_distance = distance
	return selected


func _find_strongest_enemy(maximum_distance: float) -> DontDodgeEnemy:
	var selected: DontDodgeEnemy
	var best_rank: int = -1
	var best_threat_time: float = INF
	var best_distance: float = INF
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_combat_active():
			continue
		var distance: float = enemy.global_position.distance_to(_player.global_position)
		if distance > maximum_distance:
			continue
		var rank: int = _get_enemy_threat_rank(enemy)
		var threat_time: float = enemy.get_threat_time()
		if selected == null or rank > best_rank or (rank == best_rank and threat_time < best_threat_time) or (rank == best_rank and is_equal_approx(threat_time, best_threat_time) and distance < best_distance):
			selected = enemy
			best_rank = rank
			best_threat_time = threat_time
			best_distance = distance
	return selected


func _find_strongest_ranged_enemy() -> DontDodgeEnemy:
	var selected: DontDodgeEnemy
	var best_rank: int = -1
	var best_threat_time: float = INF
	var best_distance: float = INF
	for enemy: DontDodgeEnemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_combat_active():
			continue
		var enemy_type: DontDodgeEnemy.EnemyType = enemy.get_enemy_type()
		if enemy_type != DontDodgeEnemy.EnemyType.RANGED and enemy_type != DontDodgeEnemy.EnemyType.VOLLEY and enemy_type != DontDodgeEnemy.EnemyType.ELITE:
			continue
		var threat_time: float = enemy.get_threat_time()
		var distance: float = enemy.global_position.distance_to(_player.global_position)
		var rank: int = _get_enemy_threat_rank(enemy)
		if selected == null or rank > best_rank or (rank == best_rank and threat_time < best_threat_time) or (rank == best_rank and is_equal_approx(threat_time, best_threat_time) and distance < best_distance):
			selected = enemy
			best_rank = rank
			best_threat_time = threat_time
			best_distance = distance
	if is_instance_valid(selected):
		return selected
	return _find_strongest_enemy(99999.0)


func _get_enemy_threat_rank(enemy: DontDodgeEnemy) -> int:
	match enemy.get_enemy_type():
		DontDodgeEnemy.EnemyType.ELITE:
			return 5
		DontDodgeEnemy.EnemyType.CHARGER:
			return 4
		DontDodgeEnemy.EnemyType.VOLLEY:
			return 3
		DontDodgeEnemy.EnemyType.RANGED:
			return 2
		_:
			return 1


func _clear_projectiles_on_route(start_position: Vector2, end_position: Vector2, width: float) -> void:
	var segment: Vector2 = end_position - start_position
	var segment_length_squared: float = maxf(1.0, segment.length_squared())
	for projectile: DontDodgeProjectile in _projectiles:
		if not is_instance_valid(projectile) or projectile.is_queued_for_deletion():
			continue
		var progress: float = clampf((projectile.global_position - start_position).dot(segment) / segment_length_squared, 0.0, 1.0)
		var closest_point: Vector2 = start_position + segment * progress
		if projectile.global_position.distance_to(closest_point) <= width:
			projectile.queue_free()


func _cleanup_inactive_nodes() -> void:
	var active_enemies: Array[DontDodgeEnemy] = []
	for enemy: DontDodgeEnemy in _enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			active_enemies.append(enemy)
	_enemies = active_enemies
	var active_projectiles: Array[DontDodgeProjectile] = []
	for projectile: DontDodgeProjectile in _projectiles:
		if is_instance_valid(projectile) and not projectile.is_queued_for_deletion():
			active_projectiles.append(projectile)
	_projectiles = active_projectiles
	var active_hearts: Array[DontDodgeHeart] = []
	for heart: DontDodgeHeart in _hearts:
		if is_instance_valid(heart) and not heart.is_queued_for_deletion():
			active_hearts.append(heart)
	_hearts = active_hearts
	var active_experience_orbs: Array[DontDodgeExperienceOrb] = []
	for orb: DontDodgeExperienceOrb in _experience_orbs:
		if is_instance_valid(orb) and not orb.is_queued_for_deletion():
			active_experience_orbs.append(orb)
	_experience_orbs = active_experience_orbs


func _spawn_enemy_damage_feedback(position: Vector2, damage: int, remaining_health: int, was_defeated: bool) -> void:
	_call_combat_visual(&"show_enemy_damage", [position, damage, remaining_health, was_defeated])


func _spawn_player_damage_feedback(position: Vector2) -> void:
	_call_combat_visual(&"show_player_damage", [position, DontDodgeTuning.PLAYER_DAMAGE, _player.get_health()])


func _spawn_melee_impact_feedback(position: Vector2, radius: float) -> void:
	_call_combat_visual(&"show_melee_impact", [position, radius])


func _build_spawn_schedule() -> void:
	_spawn_schedule.clear()
	_next_spawn_index = 0
	for slot_index: int in _timeline.size():
		var slot: Dictionary = _timeline[slot_index]
		for event_index: int in slot["events"].size():
			var event: Dictionary = slot["events"][event_index]
			_spawn_schedule.append({
				"time": float(slot["start_time"]) + float(event["time"]),
				"slot_index": slot_index,
				"event_index": event_index,
				"event": event.duplicate(true),
				"dispatched": false,
			})
	_spawn_schedule.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["time"]) < float(b["time"]))


func _activate_slot_events(slot_index: int) -> void:
	for schedule_index: int in _spawn_schedule.size():
		var entry: Dictionary = _spawn_schedule[schedule_index]
		if int(entry["slot_index"]) != slot_index:
			continue
		var event: Dictionary = entry["event"]
		entry["time"] = _elapsed + float(event["time"])
		entry["dispatched"] = false
		_spawn_schedule[schedule_index] = entry


func _begin_spawn_warning(entry: Dictionary) -> void:
	var slot_index: int = int(entry["slot_index"])
	var context: Dictionary = _pattern_contexts.get(slot_index, {})
	if context.is_empty():
		return
	var event: Dictionary = entry["event"]
	var position_result: Dictionary = _resolve_spawn_position(event, context)
	var enemy_type: int = _enemy_type_from_id(str(event["enemy_type"]))
	var hazard_id: String = "%s_%02d_e%02d" % [str(context["instance_id"]), slot_index, int(entry["event_index"])]
	var warning: Dictionary = {
		"remaining": _spawn_warning_duration(enemy_type),
		"position": position_result["position"],
		"enemy_type": enemy_type,
		"role": str(event["role"]),
		"pattern_id": str(context["pattern_id"]),
		"pattern_instance_id": str(context["instance_id"]),
		"hazard_id": hazard_id,
		"slot_index": slot_index,
		"event_index": int(entry["event_index"]),
	}
	_spawn_warnings.append(warning)
	_pattern_events.append({"pattern_id": warning["pattern_id"], "instance_id": warning["pattern_instance_id"], "hazard_id": hazard_id, "warning_start_active_time": snappedf(_elapsed, 0.001), "event_index": warning["event_index"], "position_rule": event["position_rule"], "position": _logged_position(position_result["position"]), "boundary_variant": position_result["boundary_variant"]})


func _update_spawn_warnings(delta: float) -> void:
	var remaining_warnings: Array[Dictionary] = []
	for warning: Dictionary in _spawn_warnings:
		warning["remaining"] = maxf(0.0, float(warning["remaining"]) - delta)
		if float(warning["remaining"]) > 0.0:
			remaining_warnings.append(warning)
			continue
		var context := {"pattern_id": warning["pattern_id"], "pattern_instance_id": warning["pattern_instance_id"], "role": warning["role"], "hazard_id": warning["hazard_id"], "spawn_lock": DontDodgeTuning.SPAWN_MATERIALIZE_LOCK}
		_spawn_enemy(int(warning["enemy_type"]), warning["position"], context)
		_actual_spawn_events.append({"pattern_id": warning["pattern_id"], "instance_id": warning["pattern_instance_id"], "hazard_id": warning["hazard_id"], "active_time": snappedf(_elapsed, 0.001), "position": _logged_position(warning["position"]), "role": warning["role"]})
	_spawn_warnings = remaining_warnings


func _cancel_pending_spawn_warnings(reason: String) -> void:
	if _spawn_warnings.is_empty():
		return
	for warning: Dictionary in _spawn_warnings:
		_pattern_events.append({"pattern_id": warning["pattern_id"], "instance_id": warning["pattern_instance_id"], "hazard_id": warning["hazard_id"], "cancelled": true, "reason": reason, "active_time": snappedf(_elapsed, 0.001)})
	_spawn_warnings.clear()


func _enemy_type_from_id(enemy_id: String) -> int:
	match enemy_id:
		"melee": return DontDodgeEnemy.EnemyType.MELEE
		"ranged": return DontDodgeEnemy.EnemyType.RANGED
		"charger": return DontDodgeEnemy.EnemyType.CHARGER
		"volley": return DontDodgeEnemy.EnemyType.VOLLEY
		"elite": return DontDodgeEnemy.EnemyType.ELITE
	return DontDodgeEnemy.EnemyType.MELEE


func _spawn_warning_duration(enemy_type: int) -> float:
	match enemy_type:
		DontDodgeEnemy.EnemyType.MELEE: return DontDodgeTuning.SPAWN_WARNING_MELEE
		DontDodgeEnemy.EnemyType.RANGED: return DontDodgeTuning.SPAWN_WARNING_RANGED
		DontDodgeEnemy.EnemyType.CHARGER: return DontDodgeTuning.SPAWN_WARNING_CHARGER
		DontDodgeEnemy.EnemyType.VOLLEY: return DontDodgeTuning.SPAWN_WARNING_VOLLEY
		_: return DontDodgeTuning.SPAWN_WARNING_ELITE


func _resolve_spawn_position(event: Dictionary, context: Dictionary) -> Dictionary:
	var base: Vector2 = context["origin"] if str(event["position_rule"]).begins_with("S:") else _player.global_position
	var axis: Vector2 = context["axis"]
	var mirror: bool = bool(context["mirror"])
	var candidate_angles: Array[float] = [0.0, deg_to_rad(15.0), -deg_to_rad(15.0), deg_to_rad(30.0), -deg_to_rad(30.0), deg_to_rad(45.0), -deg_to_rad(45.0), deg_to_rad(60.0), -deg_to_rad(60.0), PI]
	for angle: float in candidate_angles:
		var position: Vector2 = _position_from_rule(base, axis.rotated(angle), str(event["position_rule"]), float(event["distance"]), mirror)
		if _is_valid_spawn_position(position):
			return {"position": position, "boundary_variant": "standard" if is_zero_approx(angle) else "inward_fan"}
	var inward_axis: Vector2 = (DontDodgeTuning.ARENA_SIZE * 0.5 - base).normalized()
	if inward_axis == Vector2.ZERO:
		inward_axis = Vector2.UP
	return {"position": _position_from_rule(base, inward_axis, str(event["position_rule"]), float(event["distance"]), mirror), "boundary_variant": "inward_fan"}


func _position_from_rule(base: Vector2, axis: Vector2, rule: String, distance: float, mirror: bool) -> Vector2:
	var direction_id: String = rule.get_slice(":", 1)
	if mirror:
		if direction_id == "L": direction_id = "R"
		elif direction_id == "R": direction_id = "L"
	var direction: Vector2 = axis
	match direction_id:
		"B": direction = -axis
		"L": direction = axis.rotated(-PI * 0.5)
		"R": direction = axis.rotated(PI * 0.5)
	return base + direction.normalized() * distance


func _is_valid_spawn_position(position: Vector2) -> bool:
	return Rect2(Vector2.ONE * 28.0, DontDodgeTuning.ARENA_SIZE - Vector2.ONE * 56.0).has_point(position)


func _logged_position(position: Vector2) -> Dictionary:
	return {"x": snappedf(position.x, 0.1), "y": snappedf(position.y, 0.1)}


func _create_combat_visuals() -> void:
	_dungeon_backdrop = DUNGEON_BACKDROP_SCRIPT.new()
	_dungeon_backdrop.name = "DungeonBackdrop"
	add_child(_dungeon_backdrop)
	move_child(_dungeon_backdrop, 0)
	_dungeon_backdrop.call("set_arena_size", DontDodgeTuning.ARENA_SIZE)
	_dungeon_backdrop.call("set_training_mode", _mode == &"training")
	_combat_visuals = COMBAT_VISUALS_SCRIPT.new()
	_combat_visuals.name = "CombatVisuals"
	add_child(_combat_visuals)
	move_child(_combat_visuals, 1)
	_combat_visuals.call("set_arena_size", DontDodgeTuning.ARENA_SIZE)
	_screen_feedback = SCREEN_FEEDBACK_SCRIPT.new()
	_screen_feedback.name = "ScreenFeedback"
	add_child(_screen_feedback)


func _create_title_screen() -> void:
	_title_layer = CanvasLayer.new()
	_title_layer.name = "TitleLayer"
	_title_layer.layer = 10
	add_child(_title_layer)
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.055, 0.05, 0.035, 1.0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_layer.add_child(backdrop)
	var lobby_root := Control.new()
	lobby_root.name = "LobbyRoot"
	lobby_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_layer.add_child(lobby_root)
	var safe_area := MarginContainer.new()
	safe_area.name = "SafeArea"
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for margin_side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		safe_area.add_theme_constant_override(margin_side, 24)
	lobby_root.add_child(safe_area)
	var center := Control.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area.add_child(center)
	var title_scroller := ScrollContainer.new()
	title_scroller.name = "TitleScroller"
	title_scroller.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	title_scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	title_scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(title_scroller)
	var title_panel := PanelContainer.new()
	title_panel.name = "PixelTitlePanel"
	_apply_ui_theme(title_panel)
	title_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_panel.add_theme_stylebox_override("panel", _make_pixel_panel_style(Color(0.075, 0.065, 0.045, 0.96), Color(0.58, 0.45, 0.24, 0.78), 3))
	title_scroller.add_child(title_panel)
	var panel_padding := MarginContainer.new()
	panel_padding.name = "PanelPadding"
	for margin_side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		panel_padding.add_theme_constant_override(margin_side, 24)
	panel_padding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_panel.add_child(panel_padding)
	_title_layout_switcher = VBoxContainer.new()
	_title_layout_switcher.name = "TitleLayoutSwitcher"
	_title_layout_switcher.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_layout_switcher.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_title_layout_switcher.add_theme_constant_override("separation", 0)
	panel_padding.add_child(_title_layout_switcher)
	_title_wide_layout = HBoxContainer.new()
	_title_wide_layout.name = "WideLayout"
	_title_wide_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_wide_layout.add_theme_constant_override("separation", 28)
	_title_wide_layout.visible = false
	_title_layout_switcher.add_child(_title_wide_layout)
	_title_compact_layout = VBoxContainer.new()
	_title_compact_layout.name = "CompactLayout"
	_title_compact_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_compact_layout.add_theme_constant_override("separation", 16)
	_title_layout_switcher.add_child(_title_compact_layout)
	_title_left_column = VBoxContainer.new()
	_title_left_column.name = "LeftColumn"
	_title_left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_left_column.add_theme_constant_override("separation", 8)
	_title_right_column = VBoxContainer.new()
	_title_right_column.name = "RightColumn"
	_title_right_column.custom_minimum_size = Vector2(380.0, 0.0)
	_title_right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_right_column.add_theme_constant_override("separation", 8)
	var logo := TextureRect.new()
	logo.name = "Logo"
	if DisplayServer.get_name() != "headless":
		var logo_texture := load(LOGO_TEXTURE_PATH) as Texture2D
		if logo_texture != null:
			var title_art := AtlasTexture.new()
			title_art.atlas = logo_texture
			title_art.region = Rect2(340.0, 150.0, 870.0, 640.0)
			logo.texture = title_art
	logo.custom_minimum_size = Vector2(0.0, 320.0)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_left_column.add_child(logo)
	var subtitle := Label.new()
	_set_localized_text(subtitle, &"title.subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.88, 0.72))
	_title_left_column.add_child(subtitle)
	var ornament_row := HBoxContainer.new()
	ornament_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ornament_row.alignment = BoxContainer.ALIGNMENT_CENTER
	for icon_id: StringName in [&"attack", &"negate", &"ultimate"]:
		ornament_row.add_child(_make_semantic_icon(icon_id, Vector2(48.0, 48.0), Color(1.0, 0.8, 0.36)))
	_title_left_column.add_child(ornament_row)
	var control_hint := Label.new()
	_set_localized_text(control_hint, &"title.controls")
	control_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control_hint.add_theme_font_size_override("font_size", 14)
	control_hint.add_theme_color_override("font_color", Color(0.72, 0.68, 0.54))
	_title_left_column.add_child(control_hint)
	var start_button := Button.new()
	start_button.name = "StartButton"
	_apply_ui_theme(start_button)
	_set_localized_text(start_button, &"title.start")
	_set_localized_tooltip(start_button, &"title.start_tooltip")
	start_button.custom_minimum_size = Vector2(0.0, 68.0)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	start_button.add_theme_stylebox_override("normal", _make_title_button_style(Color(0.36, 0.19, 0.07, 0.98), Color(1.0, 0.72, 0.28, 1.0), 3))
	start_button.add_theme_stylebox_override("hover", _make_title_button_style(Color(0.54, 0.29, 0.08, 1.0), Color(1.0, 0.9, 0.48, 1.0), 3))
	start_button.add_theme_stylebox_override("pressed", _make_title_button_style(Color(0.2, 0.11, 0.04, 1.0), Color(0.86, 0.55, 0.18, 1.0), 3))
	start_button.pressed.connect(_on_start_requested.bind(&"normal"))
	_title_right_column.add_child(start_button)
	var mode_heading := Label.new()
	mode_heading.name = "ModeHeading"
	_set_localized_text(mode_heading, &"title.mode")
	mode_heading.add_theme_font_size_override("font_size", 14)
	mode_heading.add_theme_color_override("font_color", Color(0.78, 0.72, 0.58))
	mode_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_right_column.add_child(mode_heading)
	var mode_row := HBoxContainer.new()
	mode_row.name = "ModeRow"
	mode_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_row.add_theme_constant_override("separation", 8)
	_title_right_column.add_child(mode_row)
	_title_challenge_button = Button.new()
	_title_challenge_button.name = "ChallengeButton"
	_apply_ui_theme(_title_challenge_button)
	_set_localized_text(_title_challenge_button, &"title.challenge")
	_set_localized_tooltip(_title_challenge_button, &"title.challenge_tooltip")
	_title_challenge_button.custom_minimum_size = Vector2(0.0, 54.0)
	_title_challenge_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_challenge_button.add_theme_font_size_override("font_size", 18)
	_title_challenge_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_challenge_button.add_theme_stylebox_override("normal", _make_title_button_style(Color(0.14, 0.07, 0.16, 0.96), Color(0.58, 0.24, 0.58, 0.82), 2))
	_title_challenge_button.add_theme_stylebox_override("hover", _make_title_button_style(Color(0.25, 0.12, 0.28, 1.0), Color(0.92, 0.48, 0.88, 1.0), 2))
	_title_challenge_button.add_theme_stylebox_override("pressed", _make_title_button_style(Color(0.09, 0.04, 0.11, 1.0), Color(0.54, 0.18, 0.54, 0.92), 2))
	_title_challenge_button.pressed.connect(_on_start_requested.bind(&"challenge"))
	mode_row.add_child(_title_challenge_button)
	_title_training_button = Button.new()
	_title_training_button.name = "TrainingButton"
	_apply_ui_theme(_title_training_button)
	_set_localized_text(_title_training_button, &"title.training")
	_set_localized_tooltip(_title_training_button, &"title.training_tooltip")
	_title_training_button.custom_minimum_size = Vector2(0.0, 54.0)
	_title_training_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_training_button.add_theme_font_size_override("font_size", 18)
	_title_training_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_training_button.add_theme_stylebox_override("normal", _make_title_button_style(Color(0.08, 0.085, 0.075, 0.96), Color(0.34, 0.32, 0.26, 0.86), 2))
	_title_training_button.add_theme_stylebox_override("hover", _make_title_button_style(Color(0.22, 0.18, 0.09, 1.0), Color(0.92, 0.72, 0.32, 1.0), 2))
	_title_training_button.add_theme_stylebox_override("pressed", _make_title_button_style(Color(0.06, 0.055, 0.045, 1.0), Color(0.62, 0.46, 0.2, 0.92), 2))
	_title_training_button.pressed.connect(_open_training_scene)
	mode_row.add_child(_title_training_button)
	var menu_separator := HSeparator.new()
	menu_separator.name = "MenuSeparator"
	_title_right_column.add_child(menu_separator)
	_title_bgm_button = Button.new()
	_title_bgm_button.name = "BgmToggleButton"
	_apply_ui_theme(_title_bgm_button)
	_title_bgm_button.custom_minimum_size = Vector2(0.0, 36.0)
	_title_bgm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_bgm_button.add_theme_font_size_override("font_size", 14)
	_title_bgm_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_bgm_button.add_theme_stylebox_override("normal", _make_title_button_style(Color(0.07, 0.075, 0.065, 0.9), Color(0.3, 0.29, 0.24, 0.78), 1))
	_title_bgm_button.add_theme_stylebox_override("hover", _make_title_button_style(Color(0.18, 0.15, 0.08, 1.0), Color(0.78, 0.6, 0.28, 0.96), 2))
	_title_bgm_button.add_theme_stylebox_override("pressed", _make_title_button_style(Color(0.05, 0.05, 0.04, 1.0), Color(0.48, 0.36, 0.18, 0.86), 1))
	_title_bgm_button.pressed.connect(_toggle_bgm_from_user_input)
	_title_sfx_button = Button.new()
	_title_sfx_button.name = "SfxToggleButton"
	_apply_ui_theme(_title_sfx_button)
	_title_sfx_button.custom_minimum_size = Vector2(0.0, 36.0)
	_title_sfx_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_sfx_button.add_theme_font_size_override("font_size", 14)
	_title_sfx_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_sfx_button.add_theme_stylebox_override("normal", _make_title_button_style(Color(0.07, 0.075, 0.065, 0.9), Color(0.3, 0.29, 0.24, 0.78), 1))
	_title_sfx_button.add_theme_stylebox_override("hover", _make_title_button_style(Color(0.18, 0.15, 0.08, 1.0), Color(0.78, 0.6, 0.28, 0.96), 2))
	_title_sfx_button.add_theme_stylebox_override("pressed", _make_title_button_style(Color(0.05, 0.05, 0.04, 1.0), Color(0.48, 0.36, 0.18, 0.86), 1))
	_title_sfx_button.pressed.connect(_toggle_sfx_from_user_input)
	var audio_row := HBoxContainer.new()
	audio_row.name = "AudioRow"
	audio_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	audio_row.add_theme_constant_override("separation", 8)
	_title_guide_button = Button.new()
	_title_guide_button.name = "GuideButton"
	_apply_ui_theme(_title_guide_button)
	_set_localized_text(_title_guide_button, &"title.guide")
	_set_localized_tooltip(_title_guide_button, &"title.guide_tooltip")
	_title_guide_button.custom_minimum_size = Vector2(0.0, 40.0)
	_title_guide_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_guide_button.add_theme_font_size_override("font_size", 14)
	_title_guide_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_guide_button.add_theme_stylebox_override("normal", _make_title_button_style(Color(0.07, 0.075, 0.065, 0.9), Color(0.3, 0.29, 0.24, 0.78), 1))
	_title_guide_button.add_theme_stylebox_override("hover", _make_title_button_style(Color(0.18, 0.15, 0.08, 1.0), Color(0.78, 0.6, 0.28, 0.96), 2))
	_title_guide_button.add_theme_stylebox_override("pressed", _make_title_button_style(Color(0.05, 0.05, 0.04, 1.0), Color(0.48, 0.36, 0.18, 0.86), 1))
	_title_guide_button.pressed.connect(_show_title_guide.bind(&"normal", false))
	_title_right_column.add_child(_title_guide_button)
	audio_row.add_child(_title_bgm_button)
	audio_row.add_child(_title_sfx_button)
	_title_right_column.add_child(audio_row)
	var language_row := HBoxContainer.new()
	language_row.name = "LanguageRow"
	language_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_row.add_theme_constant_override("separation", 8)
	var language_label := Label.new()
	_set_localized_text(language_label, &"title.language")
	language_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	language_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_row.add_child(language_label)
	_title_language_option = _make_language_option(&"LanguageOption")
	language_row.add_child(_title_language_option)
	_title_right_column.add_child(language_row)
	_title_wide_layout.add_child(_title_left_column)
	_title_wide_layout.add_child(_title_right_column)
	_set_focus_chain([
		start_button,
		_title_challenge_button,
		_title_training_button,
		_title_guide_button,
		_title_bgm_button,
		_title_sfx_button,
		_title_language_option,
	])
	_title_layout_is_wide = true
	_title_wide_layout.visible = true
	_title_compact_layout.visible = false
	var viewport: Viewport = get_viewport()
	if not viewport.size_changed.is_connected(_on_title_viewport_size_changed):
		viewport.size_changed.connect(_on_title_viewport_size_changed)
	_on_title_viewport_size_changed()
	_refresh_audio_buttons()
	start_button.call_deferred("grab_focus")


func _on_title_viewport_size_changed() -> void:
	if not is_instance_valid(_title_layout_switcher):
		return
	_set_title_layout_for_width(get_viewport_rect().size.x)


func _set_title_layout_for_width(viewport_width: float) -> void:
	if not is_instance_valid(_title_layout_switcher):
		return
	var use_wide_layout: bool = viewport_width >= 1100.0
	if use_wide_layout != _title_layout_is_wide:
		if use_wide_layout:
			_title_left_column.reparent(_title_wide_layout)
			_title_right_column.reparent(_title_wide_layout)
		else:
			_title_left_column.reparent(_title_compact_layout)
			_title_right_column.reparent(_title_compact_layout)
		_title_layout_is_wide = use_wide_layout
	_title_right_column.custom_minimum_size.x = 380.0 if use_wide_layout else 0.0
	_title_wide_layout.visible = use_wide_layout
	_title_compact_layout.visible = not use_wide_layout
	_title_layout_switcher.queue_sort()


func _open_training_scene() -> void:
	if _is_scene_transitioning():
		return
	_play_ui_sfx()
	_request_scene_transition(TRAINING_SCENE_PATH)


func _create_training_setup() -> void:
	_training_setup_layer = CanvasLayer.new()
	_training_setup_layer.name = "TrainingSetupLayer"
	_training_setup_layer.layer = 10
	add_child(_training_setup_layer)
	_training_weapon_id = ""
	_training_technique_id = ""
	_training_ultimate_id = ""
	_training_starting_level = 3
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.025, 0.07, 0.08, 1.0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_training_setup_layer.add_child(backdrop)
	var panel := _make_modal_panel(Vector2(980.0, 690.0), Color(0.28, 0.82, 0.84, 0.96))
	panel.name = "TrainingSetupPanel"
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 12)
	var title := Label.new()
	_set_localized_text(title, &"training.setup_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.58, 1.0, 0.92))
	contents.add_child(title)
	var subtitle := Label.new()
	_set_localized_text(subtitle, &"training.setup_subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.92, 0.94))
	contents.add_child(subtitle)

	_training_form = GridContainer.new()
	_training_form.name = "TrainingForm"
	_training_form.columns = _get_training_form_columns()
	_training_form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_training_form.add_theme_constant_override("h_separation", 18)
	_training_form.add_theme_constant_override("v_separation", 14)
	_training_weapon_grid = _make_training_choice_grid("TrainingWeaponGrid", _get_responsive_card_columns())
	_training_level_grid = _make_training_choice_grid("TrainingLevelGrid", _get_training_level_columns())
	_training_technique_grid = _make_training_choice_grid("TrainingTechniqueGrid", _get_responsive_card_columns())
	_training_ultimate_grid = _make_training_choice_grid("TrainingUltimateGrid", _get_responsive_card_columns())
	_add_training_section_row(_training_form, &"training.weapon", _training_weapon_grid)
	_add_training_section_row(_training_form, &"training.start_level", _training_level_grid)
	_add_training_section_row(_training_form, &"training.technique", _training_technique_grid)
	_add_training_section_row(_training_form, &"training.ultimate", _training_ultimate_grid)
	contents.add_child(_training_form)

	_training_summary_panel = PanelContainer.new()
	_training_summary_panel.name = "TrainingSummaryPanel"
	_training_summary_panel.custom_minimum_size = Vector2(0.0, 128.0)
	_training_summary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_training_summary_panel.add_theme_stylebox_override("panel", _make_pixel_panel_style(Color(0.08, 0.12, 0.14, 0.98), Color(0.38, 0.82, 0.84, 0.9), 3))
	var summary_row := HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 12)
	summary_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_training_summary_icon = _make_semantic_icon(&"attack", Vector2(58.0, 58.0), Color(0.8, 0.92, 1.0))
	summary_row.add_child(_training_summary_icon)
	var summary_contents := VBoxContainer.new()
	summary_contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_contents.add_theme_constant_override("separation", 4)
	_training_summary_title = Label.new()
	_set_localized_text(_training_summary_title, &"training.summary_title")
	_training_summary_title.add_theme_font_size_override("font_size", 18)
	_training_summary_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48))
	summary_contents.add_child(_training_summary_title)
	_training_summary_label = Label.new()
	_training_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_training_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_training_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_training_summary_label.add_theme_font_size_override("font_size", 15)
	_training_summary_label.add_theme_color_override("font_color", Color(0.86, 0.96, 0.98))
	summary_contents.add_child(_training_summary_label)
	summary_row.add_child(summary_contents)
	_training_summary_panel.add_child(summary_row)
	contents.add_child(_training_summary_panel)

	var hint := Label.new()
	_set_localized_text(hint, &"training.hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.68, 0.82, 0.84))
	contents.add_child(hint)

	var buttons := HBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	_training_back_button = Button.new()
	var cancel_button := _training_back_button
	_set_localized_text(cancel_button, &"training.back")
	cancel_button.custom_minimum_size = Vector2(0.0, 52.0)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_training_button_style(cancel_button, Color(0.42, 0.72, 0.78))
	cancel_button.pressed.connect(_return_to_title)
	buttons.add_child(cancel_button)
	_training_start_button = Button.new()
	var start_button := _training_start_button
	start_button.name = "TrainingStartButton"
	_set_localized_text(start_button, &"training.enter")
	start_button.custom_minimum_size = Vector2(0.0, 52.0)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.add_theme_font_size_override("font_size", 20)
	_apply_training_button_style(start_button, Color(0.28, 0.88, 0.78))
	start_button.pressed.connect(_start_training_from_setup)
	buttons.add_child(start_button)
	contents.add_child(buttons)
	_add_scrollable_contents(panel, contents, 24, 22, 24, 22, &"TrainingSetupScroll")
	_training_setup_layer.add_child(panel)
	_create_training_hover_modal(_training_setup_layer)
	_refresh_training_option_labels()
	_refresh_training_tree_options()
	_refresh_training_focus_chain()
	start_button.call_deferred("grab_focus")


func _add_training_section_row(form: GridContainer, label_key: StringName, section: Control) -> void:
	var label := Label.new()
	_set_localized_text(label, label_key)
	label.custom_minimum_size = Vector2(150.0, 34.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.82, 0.94, 0.94))
	form.add_child(label)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(section)


func _make_training_choice_grid(grid_name: String, columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.name = grid_name
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	return grid


func _refresh_training_option_labels() -> void:
	if not is_instance_valid(_training_weapon_grid):
		return
	_hide_training_hover_modal()
	var weapon_options: Array[Dictionary] = LOADOUT_DATA_SCRIPT.get_weapon_options()
	var valid_weapon_ids: Array[String] = []
	for weapon: Dictionary in weapon_options:
		valid_weapon_ids.append(str(weapon.get("id", "")))
	if not valid_weapon_ids.has(_training_weapon_id):
		_training_weapon_id = valid_weapon_ids[0] if not valid_weapon_ids.is_empty() else ""
	_clear_training_grid(_training_weapon_grid)
	_training_weapon_cards.clear()
	for weapon: Dictionary in LOADOUT_DATA_SCRIPT.get_weapon_options():
		var weapon_id: String = str(weapon.get("id", ""))
		var card := _make_training_data_card(weapon, &"training.weapon_card_role", 126.0, false)
		card.set_meta(&"training_card_kind", &"weapon")
		card.set_meta(&"training_option_id", weapon_id)
		card.pressed.connect(_on_training_weapon_card_pressed.bind(weapon_id))
		_training_weapon_cards.append(card)
		_training_weapon_grid.add_child(card)
	_clear_training_grid(_training_level_grid)
	_training_level_cards.clear()
	var level_keys: Array[StringName] = [&"training.level_0", &"training.level_1", &"training.level_2", &"training.level_3"]
	var level_detail_keys: Array[StringName] = [&"training.level_0_detail", &"training.level_1_detail", &"training.level_2_detail", &"training.level_3_detail"]
	_training_starting_level = clampi(_training_starting_level, 0, level_keys.size() - 1)
	for level_index: int in level_keys.size():
		var level_card := _make_training_level_card(level_index, level_keys[level_index], level_detail_keys[level_index])
		_training_level_cards.append(level_card)
		_training_level_grid.add_child(level_card)
	_update_training_card_states()
	_refresh_training_focus_chain()


func _on_training_weapon_card_pressed(weapon_id: String) -> void:
	_training_weapon_id = weapon_id
	_training_technique_id = ""
	_training_ultimate_id = ""
	_refresh_training_tree_options()


func _on_training_level_card_pressed(level: int) -> void:
	_training_starting_level = clampi(level, 0, 3)
	_update_training_card_states()
	_update_training_summary()
	_refresh_training_focus_chain()


func _on_training_tree_card_pressed(stage: int, option_id: String) -> void:
	if _training_starting_level < stage:
		return
	if stage == 2:
		_training_technique_id = option_id
	elif stage == 3:
		_training_ultimate_id = option_id
	_update_training_card_states()
	_update_training_summary()


func _refresh_training_tree_options() -> void:
	if not is_instance_valid(_training_technique_grid) or not is_instance_valid(_training_ultimate_grid):
		return
	_hide_training_hover_modal()
	var technique_options: Array[Dictionary] = LOADOUT_DATA_SCRIPT.get_technique_options(_training_weapon_id)
	var ultimate_options: Array[Dictionary] = LOADOUT_DATA_SCRIPT.get_ultimate_options(_training_weapon_id)
	var valid_technique_ids: Array[String] = []
	for technique: Dictionary in technique_options:
		valid_technique_ids.append(str(technique.get("id", "")))
	if not valid_technique_ids.has(_training_technique_id):
		_training_technique_id = valid_technique_ids[0] if not valid_technique_ids.is_empty() else ""
	var valid_ultimate_ids: Array[String] = []
	for ultimate: Dictionary in ultimate_options:
		valid_ultimate_ids.append(str(ultimate.get("id", "")))
	if not valid_ultimate_ids.has(_training_ultimate_id):
		_training_ultimate_id = valid_ultimate_ids[0] if not valid_ultimate_ids.is_empty() else ""
	_clear_training_grid(_training_technique_grid)
	_training_technique_cards.clear()
	for technique: Dictionary in technique_options:
		var technique_id: String = str(technique.get("id", ""))
		var technique_card := _make_training_data_card(technique, &"training.technique_card_role", 126.0, _training_starting_level < 2)
		technique_card.set_meta(&"training_card_kind", &"technique")
		technique_card.set_meta(&"training_option_id", technique_id)
		technique_card.set_meta(&"training_unlock_level", 2)
		technique_card.pressed.connect(_on_training_tree_card_pressed.bind(2, technique_id))
		_training_technique_cards.append(technique_card)
		_training_technique_grid.add_child(technique_card)
	_clear_training_grid(_training_ultimate_grid)
	_training_ultimate_cards.clear()
	for ultimate: Dictionary in ultimate_options:
		var ultimate_id: String = str(ultimate.get("id", ""))
		var ultimate_card := _make_training_data_card(ultimate, &"training.ultimate_card_role", 126.0, _training_starting_level < 3)
		ultimate_card.set_meta(&"training_card_kind", &"ultimate")
		ultimate_card.set_meta(&"training_option_id", ultimate_id)
		ultimate_card.set_meta(&"training_unlock_level", 3)
		ultimate_card.pressed.connect(_on_training_tree_card_pressed.bind(3, ultimate_id))
		_training_ultimate_cards.append(ultimate_card)
		_training_ultimate_grid.add_child(ultimate_card)
	_update_training_card_states()
	_refresh_training_focus_chain()
	_update_training_summary()


func _update_training_summary() -> void:
	if not is_instance_valid(_training_summary_label):
		return
	var weapon: Dictionary = LOADOUT_DATA_SCRIPT.get_weapon(_training_weapon_id)
	var weapon_title: String = _localized_data_text(weapon, &"title_key", &"training.weapon_fallback")
	var weapon_detail: String = _localized_data_text(weapon, &"detail_key", &"training.weapon_fallback")
	var level_key: StringName = [&"training.level_0", &"training.level_1", &"training.level_2", &"training.level_3"][_training_starting_level]
	var level_text: String = _tr(level_key)
	var technique_text: String = _tr(&"training.summary_locked", [2])
	if _training_starting_level >= 2:
		var technique: Dictionary = LOADOUT_DATA_SCRIPT.get_option(_training_technique_id)
		technique_text = _tr(&"training.summary_option", [
			_tr(&"training.technique"),
			_localized_data_text(technique, &"title_key", &"training.technique_fallback"),
			_localized_data_text(technique, &"description_key", &"training.technique_fallback"),
		])
	var ultimate_text: String = _tr(&"training.summary_locked", [3])
	if _training_starting_level >= 3:
		var ultimate: Dictionary = LOADOUT_DATA_SCRIPT.get_option(_training_ultimate_id)
		ultimate_text = _tr(&"training.summary_option", [
			_tr(&"training.ultimate"),
			_localized_data_text(ultimate, &"title_key", &"training.ultimate_fallback"),
			_localized_data_text(ultimate, &"description_key", &"training.ultimate_fallback"),
		])
	_training_summary_label.text = _tr(&"training.summary", [
		_tr(&"training.summary_level", [level_text]),
		_tr(&"training.summary_weapon", [weapon_title, weapon_detail]),
		technique_text,
		ultimate_text,
	])
	if is_instance_valid(_training_summary_icon):
		_training_summary_icon.call("configure", StringName(str(weapon.get("icon_id", "attack"))), weapon.get("color", Color(0.8, 0.92, 1.0)))


func _clear_training_grid(grid: GridContainer) -> void:
	for child: Node in grid.get_children():
		child.free()


func _make_training_level_card(level: int, title_key: StringName, detail_key: StringName) -> Button:
	var accent: Color = Color(0.42, 0.78, 0.9) if level < 2 else Color(0.92, 0.68, 0.32) if level < 3 else Color(0.92, 0.36, 0.85)
	var card := _make_training_card_base(accent, 118.0)
	card.set_meta(&"training_card_kind", &"level")
	card.set_meta(&"training_level", level)
	card.set_meta(&"training_color", accent)
	var contents := card.get_node("CardMargin/CardContents") as VBoxContainer
	var badge := Label.new()
	badge.name = "LevelBadge"
	badge.text = _tr(&"training.level_badge", [level])
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 20)
	badge.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48))
	contents.add_child(badge)
	var title := Label.new()
	title.name = "TitleLabel"
	_set_localized_text(title, title_key)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 15)
	contents.add_child(title)
	var detail := Label.new()
	detail.name = "DescriptionLabel"
	_set_localized_text(detail, detail_key)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 13)
	detail.add_theme_color_override("font_color", Color(0.76, 0.9, 0.94))
	contents.add_child(detail)
	card.pressed.connect(_on_training_level_card_pressed.bind(level))
	return card


func _make_training_data_card(option: Dictionary, role_key: StringName, card_height: float, locked: bool) -> Button:
	var accent: Color = option.get("color", Color(0.42, 0.78, 0.9))
	var card := _make_training_card_base(accent, card_height)
	card.set_meta(&"training_locked", locked)
	card.set_meta(&"training_color", accent)
	card.set_meta(&"training_option_data", option.duplicate(true))
	card.set_meta(&"training_role_key", role_key)
	card.set_meta(&"training_icon_id", StringName(str(option.get("icon_id", "attack"))))
	card.mouse_entered.connect(_show_training_hover_modal.bind(card))
	card.mouse_exited.connect(_hide_training_hover_modal.bind(card))
	card.focus_entered.connect(_show_training_hover_modal.bind(card))
	card.focus_exited.connect(_hide_training_hover_modal.bind(card))
	var contents := card.get_node("CardMargin/CardContents") as VBoxContainer
	var icon := _make_semantic_icon(StringName(str(option.get("icon_id", "attack"))), Vector2(42.0, 42.0), accent)
	icon.name = "CardIcon"
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	contents.add_child(icon)
	var role := Label.new()
	role.name = "RoleLabel"
	role.text = _localized_data_text(option, &"subtitle_key", role_key) if option.has("subtitle_key") else _tr(role_key)
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role.custom_minimum_size = Vector2(0.0, 18.0)
	role.clip_text = true
	role.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	role.add_theme_font_size_override("font_size", 12)
	role.add_theme_color_override("font_color", Color(0.54, 0.86, 0.96))
	contents.add_child(role)
	var title := Label.new()
	title.name = "TitleLabel"
	title.text = _localized_data_text(option, &"title_key", &"training.weapon_fallback")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0.0, 22.0)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 18)
	contents.add_child(title)
	var description := Label.new()
	description.name = "DescriptionLabel"
	description.text = _localized_data_text(option, &"description_key", &"training.technique_fallback")
	description.visible = false
	contents.add_child(description)
	var detail := Label.new()
	detail.name = "DetailLabel"
	detail.text = _localized_data_text(option, &"detail_key", &"training.technique_fallback")
	detail.visible = false
	contents.add_child(detail)
	var lock_label := Label.new()
	lock_label.name = "LockLabel"
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_label.add_theme_font_size_override("font_size", 12)
	lock_label.add_theme_color_override("font_color", Color(1.0, 0.68, 0.54))
	contents.add_child(lock_label)
	_refresh_training_data_card_tooltip(card, locked)
	return card


func _refresh_training_data_card_tooltip(card: Button, locked: bool) -> void:
	if not is_instance_valid(card):
		return
	var option: Dictionary = card.get_meta(&"training_option_data", {})
	var role_key := StringName(str(card.get_meta(&"training_role_key", "training.weapon_card_role")))
	var role_text: String = _localized_data_text(option, &"subtitle_key", role_key) if option.has("subtitle_key") else _tr(role_key)
	var title_text: String = _localized_data_text(option, &"title_key", &"training.weapon_fallback")
	var description_text: String = _localized_data_text(option, &"description_key", &"training.technique_fallback")
	var detail_text: String = _localized_data_text(option, &"detail_key", &"training.technique_fallback")
	var tooltip_lines: Array[String] = []
	for text_value: String in [role_text, title_text, description_text, detail_text]:
		if not text_value.is_empty():
			tooltip_lines.append(text_value)
	if locked:
		var unlock_level: int = int(card.get_meta(&"training_unlock_level", 0))
		if unlock_level > 0:
			tooltip_lines.append(_tr(&"training.locked_at_level", [unlock_level]))
	var tooltip_text := "\n".join(tooltip_lines)
	card.set_meta(&"training_tooltip_text", tooltip_text)
	card.tooltip_text = ""
	if _training_hover_modal_source == card and is_instance_valid(_training_hover_modal) and _training_hover_modal.visible:
		_show_training_hover_modal(card)


func _create_training_hover_modal(layer: CanvasLayer) -> void:
	_training_hover_modal = PanelContainer.new()
	_training_hover_modal.name = "TrainingHoverModal"
	_apply_ui_theme(_training_hover_modal)
	_training_hover_modal.custom_minimum_size = Vector2(300.0, 230.0)
	_training_hover_modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_training_hover_modal.z_index = 100
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.045, 0.065, 1.0)
	panel_style.border_color = Color(0.42, 1.0, 0.92, 1.0)
	panel_style.set_border_width_all(3)
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 0
	_training_hover_modal.add_theme_stylebox_override("panel", panel_style)
	var margin := MarginContainer.new()
	margin.name = "TooltipMargin"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	var contents := VBoxContainer.new()
	contents.name = "TooltipContents"
	contents.add_theme_constant_override("separation", 6)
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_training_hover_modal_icon = _make_semantic_icon(&"attack", Vector2(50.0, 50.0), Color(0.8, 0.92, 1.0))
	_training_hover_modal_icon.name = "TooltipIcon"
	_training_hover_modal_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	contents.add_child(_training_hover_modal_icon)
	_training_hover_modal_role = _make_training_hover_modal_label("TooltipRole", 14, Color(0.54, 0.86, 0.96))
	contents.add_child(_training_hover_modal_role)
	_training_hover_modal_title = _make_training_hover_modal_label("TooltipTitle", 22, Color(1.0, 0.92, 0.62))
	contents.add_child(_training_hover_modal_title)
	_training_hover_modal_description = _make_training_hover_modal_label("TooltipDescription", 14, Color(0.9, 0.96, 0.98))
	contents.add_child(_training_hover_modal_description)
	_training_hover_modal_detail = _make_training_hover_modal_label("TooltipDetail", 12, Color(0.7, 0.86, 0.88))
	contents.add_child(_training_hover_modal_detail)
	_training_hover_modal_lock = _make_training_hover_modal_label("TooltipLock", 13, Color(1.0, 0.68, 0.54))
	contents.add_child(_training_hover_modal_lock)
	margin.add_child(contents)
	_training_hover_modal.add_child(margin)
	_training_hover_modal.visible = false
	layer.add_child(_training_hover_modal)


func _make_training_hover_modal_label(label_name: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _show_training_hover_modal(card: Button) -> void:
	if not is_instance_valid(_training_hover_modal) or not is_instance_valid(card):
		return
	var option: Dictionary = card.get_meta(&"training_option_data", {})
	if option.is_empty():
		return
	var role_label := card.get_node_or_null("CardMargin/CardContents/RoleLabel") as Label
	var title_label := card.get_node_or_null("CardMargin/CardContents/TitleLabel") as Label
	var description_label := card.get_node_or_null("CardMargin/CardContents/DescriptionLabel") as Label
	var detail_label := card.get_node_or_null("CardMargin/CardContents/DetailLabel") as Label
	var lock_label := card.get_node_or_null("CardMargin/CardContents/LockLabel") as Label
	_training_hover_modal_role.text = role_label.text if role_label != null else ""
	_training_hover_modal_title.text = title_label.text if title_label != null else ""
	_training_hover_modal_description.text = description_label.text if description_label != null else ""
	_training_hover_modal_detail.text = detail_label.text if detail_label != null else ""
	_training_hover_modal_lock.text = lock_label.text if lock_label != null else ""
	_training_hover_modal_lock.visible = not _training_hover_modal_lock.text.is_empty()
	_training_hover_modal_icon.call("configure", StringName(str(card.get_meta(&"training_icon_id", "attack"))), card.get_meta(&"training_color", Color(0.8, 0.92, 1.0)))
	var viewport_size := get_viewport().get_visible_rect().size
	var modal_width: float = minf(300.0, maxf(220.0, viewport_size.x - 24.0))
	var modal_height: float = maxf(230.0, _training_hover_modal.get_combined_minimum_size().y)
	modal_height = minf(modal_height, maxf(180.0, viewport_size.y - 24.0))
	_training_hover_modal.size = Vector2(modal_width, modal_height)
	var card_rect := card.get_global_rect()
	var right_position := card_rect.end.x + 12.0
	var left_position := card_rect.position.x - modal_width - 12.0
	var modal_x := right_position if right_position + modal_width <= viewport_size.x - 12.0 else left_position
	if modal_x < 12.0:
		modal_x = clampf(card_rect.get_center().x - modal_width * 0.5, 12.0, viewport_size.x - modal_width - 12.0)
	var modal_y := clampf(card_rect.position.y, 12.0, viewport_size.y - modal_height - 12.0)
	_training_hover_modal.position = Vector2(modal_x, modal_y)
	_training_hover_modal_source = card
	_training_hover_modal.visible = true


func _hide_training_hover_modal(card: Button = null) -> void:
	if card != null and _training_hover_modal_source != card:
		return
	if card != null:
		if card.has_focus():
			return
		if card.get_global_rect().has_point(get_viewport().get_mouse_position()):
			return
	if is_instance_valid(_training_hover_modal):
		_training_hover_modal.visible = false
		_training_hover_modal_role.text = ""
		_training_hover_modal_title.text = ""
		_training_hover_modal_description.text = ""
		_training_hover_modal_detail.text = ""
		_training_hover_modal_lock.text = ""
	_training_hover_modal_source = null


func _make_training_card_base(accent: Color, card_height: float) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(0.0, card_height)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.text = ""
	var normal := _make_pixel_panel_style(Color(0.08, 0.11, 0.14, 0.98), Color(accent, 0.82), 3)
	var hover := _make_pixel_panel_style(Color(accent, 0.22), accent, 4)
	var pressed := _make_pixel_panel_style(Color(accent, 0.36), Color(1.0, 0.92, 0.58), 4)
	var focus := _make_ui_focus_style()
	card.add_theme_stylebox_override("normal", normal)
	card.add_theme_stylebox_override("hover", hover)
	card.add_theme_stylebox_override("pressed", pressed)
	card.add_theme_stylebox_override("focus", focus)
	var margin := MarginContainer.new()
	margin.name = "CardMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var contents := VBoxContainer.new()
	contents.name = "CardContents"
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.alignment = BoxContainer.ALIGNMENT_CENTER
	contents.add_theme_constant_override("separation", 2)
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(contents)
	card.add_child(margin)
	return card


func _update_training_card_states() -> void:
	for card: Button in _training_weapon_cards:
		_apply_training_card_state(card, str(card.get_meta(&"training_option_id", "")) == _training_weapon_id, false)
	for card: Button in _training_level_cards:
		_apply_training_card_state(card, int(card.get_meta(&"training_level", -1)) == _training_starting_level, false)
	for card: Button in _training_technique_cards:
		var locked: bool = _training_starting_level < 2
		_apply_training_card_state(card, str(card.get_meta(&"training_option_id", "")) == _training_technique_id and not locked, locked)
	for card: Button in _training_ultimate_cards:
		var locked: bool = _training_starting_level < 3
		_apply_training_card_state(card, str(card.get_meta(&"training_option_id", "")) == _training_ultimate_id and not locked, locked)


func _apply_training_card_state(card: Button, selected: bool, locked: bool) -> void:
	if not is_instance_valid(card):
		return
	var accent: Color = card.get_meta(&"training_color", Color(0.42, 0.78, 0.9))
	var normal_background := Color(0.08, 0.11, 0.14, 0.98) if not locked else Color(0.055, 0.065, 0.08, 0.98)
	var normal_border := Color(accent, 0.82) if not locked else Color(0.28, 0.32, 0.36, 0.9)
	if selected:
		normal_background = Color(accent, 0.3)
		normal_border = accent
	card.add_theme_stylebox_override("normal", _make_pixel_panel_style(normal_background, normal_border, 4 if selected else 3))
	card.add_theme_stylebox_override("hover", _make_pixel_panel_style(Color(accent, 0.22), accent, 4))
	card.add_theme_stylebox_override("pressed", _make_pixel_panel_style(Color(accent, 0.36), Color(1.0, 0.92, 0.58), 4))
	card.add_theme_stylebox_override("focus", _make_ui_focus_style())
	var lock_label := card.get_node_or_null("CardMargin/CardContents/LockLabel") as Label
	if lock_label != null:
		var unlock_level: int = int(card.get_meta(&"training_unlock_level", 0))
		lock_label.visible = locked
		lock_label.text = _tr(&"training.locked_at_level", [unlock_level]) if locked else ""
	var title_label := card.get_node_or_null("CardMargin/CardContents/TitleLabel") as Label
	if title_label != null:
		title_label.add_theme_color_override("font_color", Color(0.58, 0.64, 0.68) if locked else Color(1.0, 0.92, 0.62))
	_refresh_training_data_card_tooltip(card, locked)


func _refresh_training_focus_chain() -> void:
	var focusables: Array[Button] = []
	focusables.append_array(_training_weapon_cards)
	focusables.append_array(_training_level_cards)
	focusables.append_array(_training_technique_cards)
	focusables.append_array(_training_ultimate_cards)
	if is_instance_valid(_training_back_button):
		focusables.append(_training_back_button)
	if is_instance_valid(_training_start_button):
		focusables.append(_training_start_button)
	_set_training_focus_links(focusables)


func _set_training_focus_links(focusables: Array[Button]) -> void:
	for index: int in focusables.size():
		var button := focusables[index]
		button.focus_mode = Control.FOCUS_ALL
		var self_path := button.get_path_to(button)
		button.focus_neighbor_left = self_path
		button.focus_neighbor_right = self_path
		button.focus_neighbor_top = self_path
		button.focus_neighbor_bottom = self_path
		button.focus_previous = button.get_path_to(focusables[index - 1]) if index > 0 else self_path
		button.focus_next = button.get_path_to(focusables[index + 1]) if index + 1 < focusables.size() else self_path


func _set_focus_chain(focusables: Array) -> void:
	var controls: Array[Control] = []
	for item: Variant in focusables:
		if item is Control:
			controls.append(item as Control)
	for index: int in controls.size():
		var control := controls[index]
		control.focus_mode = Control.FOCUS_ALL
		var self_path := control.get_path_to(control)
		control.focus_previous = control.get_path_to(controls[index - 1]) if index > 0 else self_path
		control.focus_next = control.get_path_to(controls[index + 1]) if index + 1 < controls.size() else self_path


func _start_training_from_setup() -> void:
	if not is_instance_valid(_training_setup_layer):
		return
	var starting_level: int = _training_starting_level
	_weapon_id = _training_weapon_id if starting_level >= 1 else ""
	_technique_id = _training_technique_id if starting_level >= 2 else ""
	_ultimate_id = _training_ultimate_id if starting_level >= 3 else ""
	_experience = 0
	_experience_level = starting_level
	_upgrade_stage = UpgradeStage.ULTIMATE if starting_level >= 3 else UpgradeStage.TECHNIQUE if starting_level >= 2 else UpgradeStage.WEAPON if starting_level >= 1 else UpgradeStage.NONE
	_ultimate_charge = DontDodgeTuning.ULTIMATE_MAX if not _ultimate_id.is_empty() else 0
	_start_game(&"training")


func _is_guide_completed() -> bool:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return false
	return bool(settings.get_value(SETTINGS_TUTORIAL_SECTION, SETTINGS_GUIDE_COMPLETED_KEY, false))


func _set_guide_completed() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		settings = ConfigFile.new()
	settings.set_value(SETTINGS_TUTORIAL_SECTION, SETTINGS_GUIDE_COMPLETED_KEY, true)
	if settings.save(SETTINGS_PATH) != OK:
		push_warning("Could not save DON’T DODGE guide setting.")


func _show_title_guide(mode: StringName, start_after: bool = true) -> void:
	if not is_instance_valid(_title_layer) or is_instance_valid(_guide_panel):
		return
	_guide_mark_complete = true
	_guide_return_action = Callable(self, "_on_title_guide_closed").bind(mode, start_after)
	_create_guide_overlay(_title_layer)


func _on_title_guide_closed(mode: StringName, start_after: bool) -> void:
	if start_after:
		_start_game(mode)


func _show_pause_guide() -> void:
	if not _started or _ended or is_instance_valid(_guide_panel):
		return
	_guide_mark_complete = false
	_guide_return_action = Callable(self, "_on_pause_guide_closed")
	_create_guide_overlay(get_node("CombatUILayer"))


func _on_pause_guide_closed() -> void:
	_pause_resume_button.grab_focus()


func _create_guide_overlay(layer: CanvasLayer) -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "GuideBackdrop"
	backdrop.color = Color(0.01, 0.025, 0.07, 0.86)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(backdrop)
	_guide_panel = _make_modal_panel(Vector2(920.0, 520.0), Color(0.5, 0.78, 1.0, 0.96))
	_guide_panel.name = "GuidePanel"
	var contents := VBoxContainer.new()
	contents.name = "GuideContents"
	contents.add_theme_constant_override("separation", 16)
	var title := Label.new()
	_set_localized_text(title, &"guide.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	contents.add_child(title)
	var subtitle := Label.new()
	_set_localized_text(subtitle, &"guide.subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.88, 0.96))
	contents.add_child(subtitle)
	_guide_card_grid = GridContainer.new()
	_guide_card_grid.name = "GuideCardGrid"
	_guide_card_grid.columns = _get_responsive_card_columns()
	_guide_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_guide_card_grid.add_theme_constant_override("h_separation", 12)
	_guide_card_grid.add_theme_constant_override("v_separation", 12)
	var guide_cards: Array[Dictionary] = [
		{"icon": &"attack", "title_key": &"guide.attack_title", "detail_key": &"guide.attack_detail"},
		{"icon": &"dodge", "title_key": &"guide.dodge_title", "detail_key": &"guide.dodge_detail"},
		{"icon": &"negate", "title_key": &"guide.negate_title", "detail_key": &"guide.negate_detail"},
		{"icon": &"ultimate", "title_key": &"guide.ultimate_title", "detail_key": &"guide.ultimate_detail"},
	]
	for card_data: Dictionary in guide_cards:
		var card := PanelContainer.new()
		_apply_ui_theme(card)
		card.custom_minimum_size = Vector2(0.0, 190.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _make_pixel_panel_style(Color(0.07, 0.09, 0.14, 0.98), Color(0.32, 0.62, 0.8, 0.8), 2))
		var card_contents := VBoxContainer.new()
		card_contents.alignment = BoxContainer.ALIGNMENT_CENTER
		card_contents.add_theme_constant_override("separation", 8)
		var icon := _make_semantic_icon(card_data["icon"], Vector2(56.0, 56.0), Color(0.7, 0.9, 1.0))
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_contents.add_child(icon)
		var card_title := Label.new()
		_set_localized_text(card_title, StringName(card_data["title_key"]))
		card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_title.add_theme_font_size_override("font_size", 18)
		card_contents.add_child(card_title)
		var card_detail := Label.new()
		_set_localized_text(card_detail, StringName(card_data["detail_key"]))
		card_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_detail.add_theme_font_size_override("font_size", 14)
		card_detail.add_theme_color_override("font_color", Color(0.78, 0.88, 0.96))
		card_contents.add_child(card_detail)
		card.add_child(card_contents)
		_guide_card_grid.add_child(card)
	contents.add_child(_guide_card_grid)
	var resource_hint := Label.new()
	_set_localized_text(resource_hint, &"guide.resource_hint")
	resource_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resource_hint.add_theme_font_size_override("font_size", 15)
	resource_hint.add_theme_color_override("font_color", Color(1.0, 0.82, 0.42))
	contents.add_child(resource_hint)
	_guide_start_button = Button.new()
	_guide_start_button.name = "GuideStartButton"
	_set_localized_text(_guide_start_button, &"guide.start")
	_guide_start_button.custom_minimum_size = Vector2(0.0, 54.0)
	_guide_start_button.add_theme_font_size_override("font_size", 21)
	_guide_start_button.pressed.connect(_finish_guide)
	contents.add_child(_guide_start_button)
	_add_scrollable_contents(_guide_panel, contents, 24, 22, 24, 22, &"GuideScroll")
	layer.add_child(_guide_panel)
	_guide_start_button.call_deferred("grab_focus")


func _finish_guide() -> void:
	if not is_instance_valid(_guide_panel):
		return
	if _guide_mark_complete:
		_set_guide_completed()
	var callback := _guide_return_action
	var guide_layer := _guide_panel.get_parent()
	var backdrop := guide_layer.get_node_or_null("GuideBackdrop")
	if is_instance_valid(backdrop):
		backdrop.queue_free()
	_guide_panel.queue_free()
	_guide_panel = null
	_guide_start_button = null
	_guide_return_action = Callable()
	if callback.is_valid():
		callback.call()


func _toggle_bgm_from_user_input() -> void:
	_get_sfx_controller().call("play_ui")
	_get_bgm_controller().call("toggle_from_user_input")


func _toggle_sfx_from_user_input() -> void:
	var was_enabled: bool = bool(_get_sfx_controller().call("is_enabled"))
	_get_sfx_controller().call("toggle_from_user_input")
	if not was_enabled:
		_get_sfx_controller().call("play_ui")


func _on_bgm_enabled_changed(_is_enabled: bool) -> void:
	_refresh_audio_buttons()


func _on_sfx_enabled_changed(_is_enabled: bool) -> void:
	_refresh_audio_buttons()


func _refresh_audio_buttons() -> void:
	var button_text: String = _tr(&"audio.bgm_on") if bool(_get_bgm_controller().call("is_enabled")) else _tr(&"audio.bgm_off")
	var sfx_button_text: String = _tr(&"audio.sfx_on") if bool(_get_sfx_controller().call("is_enabled")) else _tr(&"audio.sfx_off")
	if is_instance_valid(_title_bgm_button):
		_title_bgm_button.text = button_text
	if is_instance_valid(_pause_bgm_button):
		_pause_bgm_button.text = button_text
	if is_instance_valid(_title_sfx_button):
		_title_sfx_button.text = sfx_button_text
	if is_instance_valid(_pause_sfx_button):
		_pause_sfx_button.text = sfx_button_text


func _refresh_bgm_buttons() -> void:
	_refresh_audio_buttons()


func _get_bgm_controller() -> Node:
	return get_node("/root/BgmController")


func _get_sfx_controller() -> Node:
	return get_node("/root/SfxController")


func _get_scene_transition() -> Node:
	return get_node_or_null("/root/SceneTransition")


func _is_scene_transitioning() -> bool:
	var transition := _get_scene_transition()
	return is_instance_valid(transition) and bool(transition.call("is_transitioning"))


func _prepare_for_scene_transition() -> void:
	if is_instance_valid(_input_source):
		_input_source.clear_requests()
	_hide_action_tooltip()
	var viewport := get_viewport()
	if is_instance_valid(viewport):
		viewport.gui_release_focus()


func _request_scene_transition(scene_path: String) -> void:
	var transition := _get_scene_transition()
	if not is_instance_valid(transition):
		get_tree().change_scene_to_file(scene_path)
		return
	if bool(transition.call("is_transitioning")):
		return
	_prepare_for_scene_transition()
	transition.call("transition_to_scene", scene_path)


func _request_scene_reload() -> void:
	var transition := _get_scene_transition()
	if not is_instance_valid(transition):
		get_tree().reload_current_scene()
		return
	if bool(transition.call("is_transitioning")):
		return
	_prepare_for_scene_transition()
	transition.call("reload_current_scene")


func _play_ui_sfx() -> void:
	_get_sfx_controller().call("play_ui")


func _make_title_button_style(background: Color, border: Color, border_width: int = 2) -> StyleBoxFlat:
	var style := _make_pixel_panel_style(background, border, border_width)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _make_ui_focus_style() -> StyleBoxFlat:
	return _make_pixel_panel_style(Color(0.08, 0.2, 0.22, 1.0), Color(0.42, 1.0, 0.92, 1.0), 5)


func _make_pixel_panel_style(background: Color, border: Color, border_width: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 14.0
	style.content_margin_top = 10.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 10.0
	return style


func _make_pixel_bar_style(background: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := _make_pixel_panel_style(background, border, border_width)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style


func _make_semantic_icon(icon_id: StringName, size_value: Vector2, tint: Color = Color.WHITE) -> Control:
	var icon: Control = PIXEL_ICON_SCRIPT.new()
	icon.custom_minimum_size = size_value
	icon.size = size_value
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.call("configure", icon_id, tint)
	return icon


func _create_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CombatUILayer"
	layer.layer = 10
	add_child(layer)
	var wave_frame := PanelContainer.new()
	_apply_ui_theme(wave_frame)
	wave_frame.set_anchors_preset(Control.PRESET_CENTER_TOP)
	wave_frame.offset_left = -230.0
	wave_frame.offset_top = 10.0
	wave_frame.offset_right = 230.0
	wave_frame.offset_bottom = 80.0
	wave_frame.add_theme_stylebox_override("panel", _make_pixel_panel_style(Color(0.07, 0.06, 0.04, 0.94), Color(0.78, 0.62, 0.3, 0.92), 3))
	var wave_contents := VBoxContainer.new()
	wave_contents.add_theme_constant_override("separation", 2)
	var wave_heading_row := HBoxContainer.new()
	wave_heading_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_hud = _make_label(Vector2.ZERO, Vector2(200.0, 26.0), 20, Color(0.96, 0.9, 0.68))
	_hud.custom_minimum_size = Vector2(200.0, 26.0)
	_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_heading_row.add_child(_hud)
	wave_contents.add_child(wave_heading_row)
	var wave_rail := HBoxContainer.new()
	wave_rail.alignment = BoxContainer.ALIGNMENT_CENTER
	wave_rail.add_theme_constant_override("separation", 6)
	wave_rail.custom_minimum_size = Vector2(400.0, 10.0)
	_wave_segment_future_style = _make_pixel_bar_style(Color(0.025, 0.035, 0.05, 0.96), Color(0.22, 0.27, 0.32, 0.9), 1)
	_wave_segment_active_style = _make_pixel_bar_style(Color(0.55, 0.3, 0.08, 0.98), Color(1.0, 0.82, 0.36, 1.0), 2)
	_wave_segment_completed_style = _make_pixel_bar_style(Color(0.74, 0.46, 0.12, 0.98), Color(1.0, 0.72, 0.28, 0.95), 1)
	for _wave_index: int in range(DontDodgeTuning.WAVE_COUNT):
		var segment := PanelContainer.new()
		segment.custom_minimum_size = Vector2(94.0, 10.0)
		segment.visible = _mode != &"training"
		segment.add_theme_stylebox_override("panel", _wave_segment_future_style)
		_wave_segments.append(segment)
		wave_rail.add_child(segment)
	wave_contents.add_child(wave_rail)
	_wave_status_label = _make_label(Vector2.ZERO, Vector2(400.0, 16.0), 11, Color(0.72, 0.68, 0.54))
	_wave_status_label.custom_minimum_size = Vector2(400.0, 16.0)
	_wave_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_contents.add_child(_wave_status_label)
	wave_frame.add_child(wave_contents)
	layer.add_child(wave_frame)
	_build_hud_label = _make_label(Vector2.ZERO, Vector2.ZERO, 13, Color(0.82, 0.9, 0.98))
	_build_hud_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_build_hud_label.offset_left = -360.0
	_build_hud_label.offset_top = 144.0
	_build_hud_label.offset_right = 360.0
	_build_hud_label.offset_bottom = 168.0
	_build_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_build_hud_label)
	_challenge_hud_label = _make_label(Vector2.ZERO, Vector2.ZERO, 13, Color(0.92, 0.58, 1.0))
	_challenge_hud_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_challenge_hud_label.offset_left = -360.0
	_challenge_hud_label.offset_top = 86.0
	_challenge_hud_label.offset_right = 360.0
	_challenge_hud_label.offset_bottom = 108.0
	_challenge_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_challenge_hud_label.visible = _mode == &"challenge"
	layer.add_child(_challenge_hud_label)

	var timer_frame := PanelContainer.new()
	_apply_ui_theme(timer_frame)
	timer_frame.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	timer_frame.offset_left = -220.0
	timer_frame.offset_top = 10.0
	timer_frame.offset_right = -88.0
	timer_frame.offset_bottom = 80.0
	timer_frame.add_theme_stylebox_override("panel", _make_pixel_panel_style(Color(0.045, 0.065, 0.09, 0.94), Color(0.32, 0.62, 0.8, 0.86), 2))
	var timer_contents := VBoxContainer.new()
	timer_contents.add_theme_constant_override("separation", 0)
	var timer_caption := _make_label(Vector2.ZERO, Vector2.ZERO, 10, Color(0.56, 0.72, 0.82))
	_set_localized_text(timer_caption, &"hud.training_time" if _mode == &"training" else &"hud.remaining_time")
	timer_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_contents.add_child(timer_caption)
	_timer_label = _make_label(Vector2.ZERO, Vector2.ZERO, 19, Color(0.88, 0.96, 1.0))
	_timer_label.custom_minimum_size = Vector2(0.0, 30.0)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_contents.add_child(_timer_label)
	timer_frame.add_child(timer_contents)
	layer.add_child(timer_frame)

	var xp_frame := PanelContainer.new()
	_apply_ui_theme(xp_frame)
	xp_frame.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	xp_frame.offset_left = -185.0
	xp_frame.offset_top = -162.0
	xp_frame.offset_right = 185.0
	xp_frame.offset_bottom = -142.0
	xp_frame.add_theme_stylebox_override("panel", _make_pixel_bar_style(Color(0.045, 0.07, 0.11, 0.94), Color(0.32, 0.62, 0.8, 0.8), 2))
	var xp_content := Control.new()
	xp_content.custom_minimum_size = Vector2(370.0, 20.0)
	xp_frame.add_child(xp_content)
	_xp_bar = ProgressBar.new()
	_xp_bar.name = "ExperienceBar"
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_xp_bar.show_percentage = false
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bar.add_theme_stylebox_override("background", _make_pixel_bar_style(Color(0.025, 0.04, 0.065, 0.92), Color(0.16, 0.28, 0.38, 0.8), 1))
	_xp_bar.add_theme_stylebox_override("fill", _make_pixel_bar_style(Color(0.12, 0.48, 0.72, 0.96), Color(0.48, 0.86, 1.0, 0.96), 1))
	xp_content.add_child(_xp_bar)
	_xp_label = _make_label(Vector2.ZERO, Vector2.ZERO, 11, Color(0.88, 0.96, 1.0))
	_xp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_content.add_child(_xp_label)
	layer.add_child(xp_frame)
	_feedback_label = _make_label(Vector2.ZERO, Vector2.ZERO, 18, Color(1.0, 0.82, 0.36))
	_feedback_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_feedback_label.offset_left = -300.0
	_feedback_label.offset_top = 112.0
	_feedback_label.offset_right = 300.0
	_feedback_label.offset_bottom = 140.0
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_feedback_label)
	_create_combat_hint_ui(layer)
	_create_upgrade_result_ui(layer)
	_create_action_bar(layer)
	_create_action_tooltip(layer)
	_create_challenge_roulette_ui(layer)
	_create_pause_ui(layer)
	if _mode == &"training":
		_create_training_controls(layer)
	_end_panel = PanelContainer.new()
	_apply_ui_theme(_end_panel)
	_configure_responsive_panel(_end_panel, Vector2(500.0, 320.0))
	var end_style := _make_pixel_panel_style(Color(0.09, 0.075, 0.045, 0.98), Color(0.86, 0.68, 0.3), 4)
	end_style.content_margin_left = 0.0
	end_style.content_margin_top = 0.0
	end_style.content_margin_right = 0.0
	end_style.content_margin_bottom = 0.0
	_end_panel.add_theme_stylebox_override("panel", end_style)
	var contents := VBoxContainer.new()
	contents.name = "Contents"
	contents.add_theme_constant_override("separation", 16)
	var title := Label.new()
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 23)
	contents.add_child(title)
	var restart := Button.new()
	restart.name = "RestartButton"
	_set_localized_text(restart, &"result.restart")
	restart.custom_minimum_size = Vector2(0.0, 54.0)
	restart.pressed.connect(_restart)
	contents.add_child(restart)
	var return_to_title := Button.new()
	return_to_title.name = "ReturnToTitleButton"
	_set_localized_text(return_to_title, &"result.lobby")
	return_to_title.custom_minimum_size = Vector2(0.0, 54.0)
	return_to_title.pressed.connect(_return_to_title)
	contents.add_child(return_to_title)
	_add_scrollable_contents(_end_panel, contents, 20, 12, 20, 12, &"ResultScroll")
	_end_panel.visible = false
	layer.add_child(_end_panel)
	_update_hud()


func _create_training_controls(layer: CanvasLayer) -> void:
	_training_controls_panel = PanelContainer.new()
	_training_controls_panel.name = "TrainingControls"
	_apply_ui_theme(_training_controls_panel)
	_training_controls_panel.anchor_left = 0.0
	_training_controls_panel.anchor_top = 0.0
	_training_controls_panel.anchor_right = 0.0
	_training_controls_panel.anchor_bottom = 0.0
	_training_controls_panel.offset_left = UI_MODAL_SAFE_MARGIN
	_training_controls_panel.offset_top = 112.0
	_training_controls_panel.offset_right = UI_MODAL_SAFE_MARGIN + 360.0
	_training_controls_panel.offset_bottom = 632.0
	var controls_style := _make_pixel_panel_style(Color(0.035, 0.12, 0.14, 0.94), Color(0.28, 0.82, 0.84, 0.9), 3)
	controls_style.content_margin_left = 0.0
	controls_style.content_margin_top = 0.0
	controls_style.content_margin_right = 0.0
	controls_style.content_margin_bottom = 0.0
	_training_controls_panel.add_theme_stylebox_override("panel", controls_style)
	var contents := VBoxContainer.new()
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.add_theme_constant_override("separation", 7)
	var title := Label.new()
	_set_localized_text(title, &"training.controls_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color(0.58, 1.0, 0.92))
	contents.add_child(title)
	var hint := Label.new()
	_set_localized_text(hint, &"training.controls_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.7, 0.86, 0.88))
	contents.add_child(hint)
	contents.add_child(_make_training_group_heading(&"training.summon_group"))
	_training_enemy_grid = GridContainer.new()
	_training_enemy_grid.name = "TrainingEnemyGrid"
	_training_enemy_grid.columns = _get_training_enemy_columns()
	_training_enemy_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_training_enemy_grid.add_theme_constant_override("h_separation", 6)
	_training_enemy_grid.add_theme_constant_override("v_separation", 6)
	var enemy_buttons: Array[Dictionary] = [
		{"label_key": &"training.spawn_melee", "role_key": &"training.enemy_melee_role", "icon_id": &"attack", "color": Color(1.0, 0.67, 0.2), "type": DontDodgeEnemy.EnemyType.MELEE},
		{"label_key": &"training.spawn_ranged", "role_key": &"training.enemy_ranged_role", "icon_id": &"negate", "color": Color(0.3, 0.75, 1.0), "type": DontDodgeEnemy.EnemyType.RANGED},
		{"label_key": &"training.spawn_charger", "role_key": &"training.enemy_charger_role", "icon_id": &"dodge", "color": Color(0.4, 0.84, 1.0), "type": DontDodgeEnemy.EnemyType.CHARGER},
		{"label_key": &"training.spawn_volley", "role_key": &"training.enemy_volley_role", "icon_id": &"sweep", "color": Color(0.28, 0.9, 0.9), "type": DontDodgeEnemy.EnemyType.VOLLEY},
		{"label_key": &"training.spawn_elite", "role_key": &"training.enemy_elite_role", "icon_id": &"ultimate", "color": Color(0.92, 0.36, 0.85), "type": DontDodgeEnemy.EnemyType.ELITE},
	]
	var enemy_cards: Array[Button] = []
	for enemy_data: Dictionary in enemy_buttons:
		var spawn_button := _make_training_enemy_card(enemy_data)
		spawn_button.pressed.connect(_spawn_training_enemy.bind(int(enemy_data["type"])))
		enemy_cards.append(spawn_button)
		_training_enemy_grid.add_child(spawn_button)
	contents.add_child(_training_enemy_grid)
	contents.add_child(_make_training_group_heading(&"training.field_group"))
	var field_actions := HBoxContainer.new()
	field_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_actions.add_theme_constant_override("separation", 6)
	_training_clear_button = _make_training_button(&"training.clear", Color(0.3, 0.82, 0.86), 46.0)
	_training_clear_button.name = "TrainingClearButton"
	var clear_button := _training_clear_button
	clear_button.pressed.connect(_clear_training_entities)
	field_actions.add_child(clear_button)
	_training_reset_button = _make_training_button(&"training.reset", Color(1.0, 0.72, 0.28), 46.0)
	_training_reset_button.name = "TrainingResetButton"
	var reset_button := _training_reset_button
	reset_button.pressed.connect(_reset_training_arena)
	field_actions.add_child(reset_button)
	contents.add_child(field_actions)
	contents.add_child(_make_training_group_heading(&"training.navigation_group"))
	_training_exit_button = _make_training_button(&"training.exit", Color(0.42, 0.72, 0.78), 44.0)
	_training_exit_button.name = "TrainingExitButton"
	var exit_button := _training_exit_button
	exit_button.pressed.connect(_return_to_title)
	contents.add_child(exit_button)
	_add_scrollable_contents(_training_controls_panel, contents, 14, 10, 14, 10, &"TrainingControlsScroll")
	layer.add_child(_training_controls_panel)
	var control_focusables: Array[Button] = []
	control_focusables.append_array(enemy_cards)
	control_focusables.append(clear_button)
	control_focusables.append(reset_button)
	control_focusables.append(exit_button)
	_set_training_focus_links(control_focusables)
	_fit_training_controls_panel()


func _make_training_group_heading(key: StringName) -> Label:
	var heading := Label.new()
	_set_localized_text(heading, key)
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", Color(0.58, 1.0, 0.92))
	heading.custom_minimum_size = Vector2(0.0, 24.0)
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return heading


func _make_training_enemy_card(enemy_data: Dictionary) -> Button:
	var accent: Color = enemy_data.get("color", Color(0.42, 0.78, 0.9))
	var card := _make_training_card_base(accent, 88.0)
	card.set_meta(&"training_color", accent)
	var contents := card.get_node("CardMargin/CardContents") as VBoxContainer
	var icon := _make_semantic_icon(StringName(enemy_data["icon_id"]), Vector2(34.0, 34.0), accent)
	icon.name = "CardIcon"
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	contents.add_child(icon)
	var title := Label.new()
	title.name = "TitleLabel"
	_set_localized_text(title, StringName(enemy_data["label_key"]))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 14)
	contents.add_child(title)
	var role := Label.new()
	role.name = "RoleLabel"
	_set_localized_text(role, StringName(enemy_data["role_key"]))
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role.add_theme_font_size_override("font_size", 11)
	role.add_theme_color_override("font_color", Color(0.72, 0.86, 0.9))
	contents.add_child(role)
	return card


func _make_training_button(label_key: StringName, accent: Color, height: float) -> Button:
	var button := Button.new()
	_set_localized_text(button, label_key)
	button.custom_minimum_size = Vector2(0.0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 14)
	_apply_training_button_style(button, accent)
	return button


func _apply_training_button_style(button: Button, accent: Color) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _make_pixel_panel_style(Color(0.08, 0.11, 0.14, 0.98), Color(accent, 0.82), 3))
	button.add_theme_stylebox_override("hover", _make_pixel_panel_style(Color(accent, 0.22), accent, 4))
	button.add_theme_stylebox_override("pressed", _make_pixel_panel_style(Color(accent, 0.36), Color(1.0, 0.92, 0.58), 4))
	button.add_theme_stylebox_override("focus", _make_ui_focus_style())


func _spawn_training_enemy(enemy_type: int) -> void:
	if _mode != &"training" or _ended:
		return
	var angle: float = float(_training_spawn_index % 8) * TAU / 8.0
	var distance: float = 260.0 if enemy_type != DontDodgeEnemy.EnemyType.ELITE else 330.0
	var spawn_position := (_player.global_position + Vector2.RIGHT.rotated(angle) * distance).clamp(
		Vector2.ONE * 64.0,
		DontDodgeTuning.ARENA_SIZE - Vector2.ONE * 64.0,
	)
	_training_spawn_index += 1
	var enemy_name_key: StringName = _get_enemy_name_key(enemy_type)
	_spawn_enemy(enemy_type, spawn_position, {
		"pattern_id": "training",
		"pattern_instance_id": "training_%03d" % _training_spawn_index,
		"role": "training",
		"hazard_id": "training_%03d" % _training_spawn_index,
	})
	_show_feedback_key(&"training.spawn_feedback", [enemy_name_key], 0.6)


func _get_enemy_name_key(enemy_type: int) -> StringName:
	match enemy_type:
		DontDodgeEnemy.EnemyType.MELEE:
			return &"enemy.melee"
		DontDodgeEnemy.EnemyType.RANGED:
			return &"enemy.ranged"
		DontDodgeEnemy.EnemyType.CHARGER:
			return &"enemy.charger"
		DontDodgeEnemy.EnemyType.VOLLEY:
			return &"enemy.volley"
		DontDodgeEnemy.EnemyType.ELITE:
			return &"enemy.elite"
	return &"enemy.melee"


func _clear_training_entities() -> void:
	if _mode != &"training":
		return
	for enemy: DontDodgeEnemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	for projectile: DontDodgeProjectile in _projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	for heart: DontDodgeHeart in _hearts:
		if is_instance_valid(heart):
			heart.queue_free()
	for orb: DontDodgeExperienceOrb in _experience_orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	_enemies.clear()
	_projectiles.clear()
	_hearts.clear()
	_experience_orbs.clear()
	_spawn_warnings.clear()
	_pattern_contexts.clear()
	_hit_stop_remaining = 0.0
	_ultimate_freeze_remaining = 0.0
	_weapon_ultimate_sequence.clear()
	_weapon_ultimate_sequence_index = -1
	_weapon_ultimate_phase_elapsed = 0.0
	_weapon_ultimate_sequence_pending_start = false
	_weapon_ultimate_completion_feedback_key = &""
	_weapon_ultimate_completion_feedback_arguments.clear()
	_dagger_ultimate_sequence.clear()
	_dagger_ultimate_sequence_index = -1
	_dagger_ultimate_phase_elapsed = 0.0
	_dagger_ultimate_sequence_pending_start = false
	_dagger_ultimate_completion_feedback_key = &""
	_dagger_ultimate_completion_feedback_arguments.clear()
	_clear_projectile_visual_state()


func _clear_projectile_visual_state() -> void:
	if is_instance_valid(_combat_visuals):
		_combat_visuals.call("set_spawn_warnings", _spawn_warnings)


func _reset_training_arena() -> void:
	if _mode != &"training":
		return
	_clear_training_entities()
	_ended = false
	_outcome = ""
	_end_reason_key = &""
	_end_reason_arguments.clear()
	_death_record = {}
	_elapsed = 0.0
	_time_metrics["active_combat_seconds"] = 0.0
	_time_metrics["threat_gate_seconds"] = 0.0
	_time_metrics["cleanup_seconds"] = 0.0
	_time_metrics["upgrade_seconds"] = 0.0
	_time_metrics["unpaused_session_seconds"] = 0.0
	_time_metrics["manual_pause_seconds"] = 0.0
	_time_metrics["total_wall_seconds"] = 0.0
	_stats = {
		"kills": 0,
		"focus_attacks": 0,
		"focus_hits": 0,
		"focus_misses": 0,
		"attack_recovery_rejections": 0,
		"dodges": 0,
		"negates": 0,
		"perfect_dodges": 0,
		"interrupts": 0,
		"enemies_repulsed": 0,
		"projectiles_erased": 0,
		"heart_spawns": 0,
		"hearts_absorbed": 0,
		"elite_heart_drops": 0,
		"experience_spawned": 0,
		"experience_collected": 0,
		"experience_levels": 0,
		"hits_taken": 0,
		"ultimates": 0,
	}
	_ultimate_sources.clear()
	_input_events.clear()
	_state_events.clear()
	_upgrade_history.clear()
	_pause_mode = PauseMode.NONE
	_state_before_manual_pause = GameState.COMBAT
	_record_state(GameState.COMBAT, "training_reset")
	_player.visible = true
	_player.global_position = DontDodgeTuning.ARENA_SIZE * 0.5
	_player.configure_health(int(_get_weapon_data().get("max_health", DontDodgeTuning.PLAYER_MAX_HEALTH)))
	_defense.reset()
	_attack_recovery_remaining = 0.0
	_break_cooldown_remaining = 0.0
	_guard_remaining = 0.0
	_guard_successful = false
	_mace_counter_remaining = 0.0
	_spear_breakthrough_remaining = 0.0
	_ghost_step_remaining = 0.0
	_damage_guard_remaining = 0.0
	_spear_radial_attack_ready = false
	_spear_bullet_cut_remaining = 0.0
	_spear_edge_pressure_remaining = 0.0
	_spear_edge_pressure_target = null
	_spear_dodge_contact_registered = false
	_ultimate_charge = DontDodgeTuning.ULTIMATE_MAX if not _ultimate_id.is_empty() else 0
	_hit_stop_remaining = 0.0
	_ultimate_freeze_remaining = 0.0
	_dagger_ultimate_sequence.clear()
	_dagger_ultimate_sequence_index = -1
	_dagger_ultimate_phase_elapsed = 0.0
	_dagger_ultimate_sequence_pending_start = false
	_dagger_ultimate_completion_feedback_key = &""
	_dagger_ultimate_completion_feedback_arguments.clear()
	_weapon_ultimate_sequence.clear()
	_weapon_ultimate_sequence_index = -1
	_weapon_ultimate_phase_elapsed = 0.0
	_weapon_ultimate_sequence_pending_start = false
	_weapon_ultimate_completion_feedback_key = &""
	_weapon_ultimate_completion_feedback_arguments.clear()
	_attack_sequence = 0
	_waves_cleared = 0
	_waves_reached = 1
	_feedback_key = &""
	_feedback_arguments.clear()
	_feedback_remaining = 0.0
	_last_hud_text = ""
	_hud_refresh_elapsed = HUD_REFRESH_INTERVAL
	_hud_refresh_requested = true
	_training_spawn_index = 0
	_input_source.clear_requests()
	_end_panel.visible = false
	_pause_backdrop.visible = false
	_pause_panel.visible = false
	_upgrade_panel.visible = false
	_upgrade_result_panel.visible = false
	_pause_button.visible = true
	_update_hud()
	_sync_combat_visuals()
	_show_feedback_key(&"training.reset_feedback", [], 0.7)


func _create_challenge_roulette_ui(layer: CanvasLayer) -> void:
	_challenge_roulette_panel = _make_modal_panel(Vector2(920.0, 500.0), Color(0.92, 0.36, 0.85, 0.96))
	_challenge_roulette_panel.name = "ChallengeRoulettePanel"
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 12)
	var title := Label.new()
	_set_localized_text(title, &"challenge.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.96))
	contents.add_child(title)
	var hint := Label.new()
	_set_localized_text(hint, &"challenge.hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.84, 0.88, 0.96))
	contents.add_child(hint)
	_challenge_card_grid = GridContainer.new()
	_challenge_card_grid.name = "ChallengeCardGrid"
	_challenge_card_grid.columns = _get_responsive_card_columns()
	_challenge_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_challenge_card_grid.add_theme_constant_override("h_separation", 10)
	_challenge_card_grid.add_theme_constant_override("v_separation", 10)
	for debuff: Dictionary in CHALLENGE_DATA_SCRIPT.get_pool():
		var card := Button.new()
		card.custom_minimum_size = Vector2(0.0, 220.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.disabled = true
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_theme_font_size_override("font_size", 16)
		card.add_theme_stylebox_override("normal", _make_pixel_panel_style(Color(0.08, 0.07, 0.13, 0.98), Color(0.36, 0.3, 0.48, 0.9), 3))
		card.add_theme_stylebox_override("disabled", _make_pixel_panel_style(Color(0.08, 0.07, 0.13, 0.98), Color(0.36, 0.3, 0.48, 0.9), 3))
		var icon := _make_semantic_icon(debuff["icon_id"], Vector2(58.0, 58.0), debuff["color"])
		icon.position = Vector2(73.0, 16.0)
		card.add_child(icon)
		card.set_meta(&"debuff_id", debuff["id"])
		_set_challenge_card_text(card, debuff)
		_challenge_roulette_cards.append(card)
		_challenge_card_grid.add_child(card)
	contents.add_child(_challenge_card_grid)
	_challenge_result_label = Label.new()
	_challenge_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_challenge_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_challenge_result_label.custom_minimum_size = Vector2(0.0, 42.0)
	_challenge_result_label.add_theme_font_size_override("font_size", 17)
	_challenge_result_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.48))
	contents.add_child(_challenge_result_label)
	_challenge_start_button = Button.new()
	_challenge_start_button.name = "ChallengeStartButton"
	_set_localized_text(_challenge_start_button, &"challenge.spinning")
	_challenge_start_button.custom_minimum_size = Vector2(0.0, 52.0)
	_challenge_start_button.add_theme_font_size_override("font_size", 20)
	_challenge_start_button.disabled = true
	_challenge_start_button.pressed.connect(_begin_challenge_combat)
	contents.add_child(_challenge_start_button)
	_add_scrollable_contents(_challenge_roulette_panel, contents, 24, 22, 24, 22, &"ChallengeScroll")
	_challenge_roulette_panel.visible = false
	layer.add_child(_challenge_roulette_panel)


func _set_challenge_card_text(card: Button, debuff: Dictionary) -> void:
	card.text = "\n\n\n%s\n\n%s" % [
		_localized_data_text(debuff, &"title_key", &"challenge.title"),
		_localized_data_text(debuff, &"description_key", &"challenge.hint"),
	]


func _refresh_challenge_cards_text() -> void:
	for card: Button in _challenge_roulette_cards:
		if not is_instance_valid(card):
			continue
		var debuff: Dictionary = CHALLENGE_DATA_SCRIPT.get_debuff(StringName(str(card.get_meta(&"debuff_id", ""))))
		_set_challenge_card_text(card, debuff)
	if is_instance_valid(_challenge_result_label):
		_challenge_result_label.text = _tr(&"challenge.result", [
			_localized_data_text(_challenge_debuff, &"title_key", &"challenge.title"),
			_localized_data_text(_challenge_debuff, &"description_key", &"challenge.hint"),
		]) if _challenge_roulette_finished else _tr(&"challenge.spinning")
	if is_instance_valid(_challenge_start_button):
		_challenge_start_button.text = _tr(&"challenge.start") if _challenge_roulette_finished else _tr(&"challenge.spinning")


func _show_challenge_roulette() -> void:
	if not is_instance_valid(_challenge_roulette_panel):
		return
	_challenge_roulette_panel.visible = true
	_challenge_roulette_elapsed = 0.0
	_challenge_roulette_index = 0
	_challenge_roulette_finished = false
	_challenge_result_label.text = _tr(&"challenge.spinning")
	_challenge_start_button.text = _tr(&"challenge.spinning")
	_challenge_start_button.disabled = true
	_refresh_challenge_roulette_cards()
	_play_ui_sfx()


func _update_challenge_roulette(delta: float) -> void:
	if _challenge_roulette_finished:
		return
	_challenge_roulette_elapsed += delta
	var spin_step: int = maxi(0, floori(_challenge_roulette_elapsed / 0.12))
	_challenge_roulette_index = spin_step % _challenge_roulette_cards.size()
	_refresh_challenge_roulette_cards()
	if _challenge_roulette_elapsed < 1.35:
		return
	_challenge_roulette_finished = true
	for index: int in _challenge_roulette_cards.size():
		if str(_challenge_roulette_cards[index].get_meta(&"debuff_id")) == str(_challenge_debuff_id):
			_challenge_roulette_index = index
			break
	_refresh_challenge_roulette_cards()
	_challenge_result_label.text = _tr(&"challenge.result", [
		_localized_data_text(_challenge_debuff, &"title_key", &"challenge.title"),
		_localized_data_text(_challenge_debuff, &"description_key", &"challenge.hint"),
	])
	_challenge_start_button.text = _tr(&"challenge.start")
	_challenge_start_button.disabled = false
	_challenge_start_button.grab_focus()
	_play_ui_sfx()


func _refresh_challenge_roulette_cards() -> void:
	for index: int in _challenge_roulette_cards.size():
		var card: Button = _challenge_roulette_cards[index]
		var debuff_id: StringName = card.get_meta(&"debuff_id")
		var debuff: Dictionary = CHALLENGE_DATA_SCRIPT.get_debuff(debuff_id)
		var is_selected: bool = _challenge_roulette_finished and debuff_id == _challenge_debuff_id
		var is_spinning: bool = not _challenge_roulette_finished and index == _challenge_roulette_index
		var border_color: Color = debuff["color"] if is_selected or is_spinning else Color(0.36, 0.3, 0.48, 0.9)
		var background_color: Color = Color(debuff["color"], 0.34) if is_selected else Color(debuff["color"], 0.18) if is_spinning else Color(0.08, 0.07, 0.13, 0.98)
		card.add_theme_stylebox_override("disabled", _make_pixel_panel_style(background_color, border_color, 4 if is_selected else 3))


func _begin_challenge_combat() -> void:
	if not _challenge_roulette_finished or not is_instance_valid(_challenge_roulette_panel):
		return
	_challenge_roulette_panel.visible = false
	_begin_combat()


func _create_upgrade_result_ui(layer: CanvasLayer) -> void:
	_upgrade_result_panel = PanelContainer.new()
	_apply_ui_theme(_upgrade_result_panel)
	_upgrade_result_panel.anchor_left = 0.5
	_upgrade_result_panel.anchor_right = 0.5
	_upgrade_result_panel.offset_left = -280.0
	_upgrade_result_panel.offset_top = 188.0
	_upgrade_result_panel.offset_right = 280.0
	_upgrade_result_panel.offset_bottom = 288.0
	_upgrade_result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.04, 0.96)
	style.border_color = Color(1.0, 0.78, 0.28, 0.96)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 20.0
	style.content_margin_top = 12.0
	style.content_margin_right = 20.0
	style.content_margin_bottom = 12.0
	_upgrade_result_panel.add_theme_stylebox_override("panel", style)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 5)
	_upgrade_result_title = Label.new()
	_upgrade_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_result_title.add_theme_font_size_override("font_size", 21)
	_upgrade_result_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	contents.add_child(_upgrade_result_title)
	_upgrade_result_detail = Label.new()
	_upgrade_result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_result_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_upgrade_result_detail.add_theme_font_size_override("font_size", 17)
	_upgrade_result_detail.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	contents.add_child(_upgrade_result_detail)
	_upgrade_result_panel.add_child(contents)
	_upgrade_result_panel.visible = false
	layer.add_child(_upgrade_result_panel)


func _create_combat_hint_ui(layer: CanvasLayer) -> void:
	_combat_hint_panel = PanelContainer.new()
	_combat_hint_panel.name = "CombatHintPanel"
	_combat_hint_panel.anchor_left = 0.0
	_combat_hint_panel.anchor_top = 1.0
	_combat_hint_panel.anchor_right = 0.0
	_combat_hint_panel.anchor_bottom = 1.0
	_combat_hint_panel.offset_left = 24.0
	_combat_hint_panel.offset_top = -234.0
	_combat_hint_panel.offset_right = 420.0
	_combat_hint_panel.offset_bottom = -110.0
	_combat_hint_panel.custom_minimum_size = Vector2(396.0, 124.0)
	_combat_hint_panel.add_theme_stylebox_override("panel", _make_pixel_panel_style(Color(0.035, 0.1, 0.14, 0.96), Color(0.36, 0.86, 0.94, 0.96), 2))
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 4)
	_combat_hint_label = Label.new()
	_combat_hint_label.name = "HintLabel"
	_apply_ui_theme(_combat_hint_label)
	_set_localized_text(_combat_hint_label, &"tutorial.hint_melee")
	_combat_hint_label.custom_minimum_size = Vector2(360.0, 42.0)
	_combat_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_combat_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combat_hint_label.add_theme_font_size_override("font_size", 15)
	_combat_hint_label.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0))
	_combat_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(_combat_hint_label)
	_combat_hint_skip_button = Button.new()
	_combat_hint_skip_button.name = "SkipButton"
	_apply_ui_theme(_combat_hint_skip_button)
	_set_localized_text(_combat_hint_skip_button, &"tutorial.skip")
	_combat_hint_skip_button.custom_minimum_size = Vector2(0.0, 28.0)
	_combat_hint_skip_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_combat_hint_skip_button.add_theme_font_size_override("font_size", 12)
	_combat_hint_skip_button.pressed.connect(_skip_combat_hints)
	contents.add_child(_combat_hint_skip_button)
	_combat_hint_panel.add_child(contents)
	_combat_hint_panel.visible = false
	layer.add_child(_combat_hint_panel)


func _create_pause_ui(layer: CanvasLayer) -> void:
	_pause_button = Button.new()
	_apply_ui_theme(_pause_button)
	_pause_button.text = "Ⅱ"
	_set_localized_tooltip(_pause_button, &"pause.button_tooltip")
	_pause_button.anchor_left = 1.0
	_pause_button.anchor_right = 1.0
	_pause_button.offset_left = -76.0
	_pause_button.offset_top = 18.0
	_pause_button.offset_right = -22.0
	_pause_button.offset_bottom = 72.0
	_pause_button.add_theme_font_size_override("font_size", 25)
	_pause_button.pressed.connect(_toggle_manual_pause)
	layer.add_child(_pause_button)

	_pause_backdrop = ColorRect.new()
	_pause_backdrop.color = Color(0.01, 0.025, 0.07, 0.76)
	_pause_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_backdrop.visible = false
	layer.add_child(_pause_backdrop)

	_pause_panel = _make_modal_panel(Vector2(460.0, 600.0), Color(0.74, 0.64, 0.36, 0.96))
	var pause_contents := VBoxContainer.new()
	pause_contents.add_theme_constant_override("separation", 14)
	var pause_title := Label.new()
	_set_localized_text(pause_title, &"pause.title")
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_font_size_override("font_size", 28)
	pause_contents.add_child(pause_title)
	var pause_hint := Label.new()
	_set_localized_text(pause_hint, &"pause.hint")
	pause_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_hint.add_theme_font_size_override("font_size", 15)
	pause_contents.add_child(pause_hint)
	_pause_challenge_label = Label.new()
	_pause_challenge_label.name = "ChallengeDebuffLabel"
	_pause_challenge_label.text = _tr(&"pause.challenge", [_localized_data_text(_challenge_debuff, &"title_key", &"hud.challenge_ready")]) if _mode == &"challenge" else ""
	_pause_challenge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_challenge_label.add_theme_font_size_override("font_size", 15)
	_pause_challenge_label.add_theme_color_override("font_color", Color(0.92, 0.58, 1.0))
	_pause_challenge_label.visible = _mode == &"challenge"
	pause_contents.add_child(_pause_challenge_label)
	_pause_resume_button = Button.new()
	_set_localized_text(_pause_resume_button, &"pause.resume")
	_pause_resume_button.custom_minimum_size = Vector2(0.0, 50.0)
	_pause_resume_button.pressed.connect(_resume_manual_pause)
	pause_contents.add_child(_pause_resume_button)
	_pause_guide_button = Button.new()
	_pause_guide_button.name = "GuideButton"
	_set_localized_text(_pause_guide_button, &"title.guide")
	_pause_guide_button.custom_minimum_size = Vector2(0.0, 50.0)
	_pause_guide_button.pressed.connect(_show_pause_guide)
	pause_contents.add_child(_pause_guide_button)
	var restart := Button.new()
	_set_localized_text(restart, &"pause.restart")
	restart.custom_minimum_size = Vector2(0.0, 50.0)
	restart.pressed.connect(_restart)
	pause_contents.add_child(restart)
	_pause_bgm_button = Button.new()
	_pause_bgm_button.name = "BgmToggleButton"
	_pause_bgm_button.custom_minimum_size = Vector2(0.0, 50.0)
	_pause_bgm_button.pressed.connect(_toggle_bgm_from_user_input)
	pause_contents.add_child(_pause_bgm_button)
	_pause_sfx_button = Button.new()
	_pause_sfx_button.name = "SfxToggleButton"
	_pause_sfx_button.custom_minimum_size = Vector2(0.0, 50.0)
	_pause_sfx_button.pressed.connect(_toggle_sfx_from_user_input)
	pause_contents.add_child(_pause_sfx_button)
	var language_row := HBoxContainer.new()
	language_row.add_theme_constant_override("separation", 8)
	var language_label := Label.new()
	_set_localized_text(language_label, &"title.language")
	language_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	language_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_row.add_child(language_label)
	_pause_language_option = _make_language_option(&"LanguageOption")
	language_row.add_child(_pause_language_option)
	pause_contents.add_child(language_row)
	_pause_main_button = Button.new()
	_pause_main_button.name = "ReturnToTitleButton"
	_set_localized_text(_pause_main_button, &"pause.main")
	_pause_main_button.custom_minimum_size = Vector2(0.0, 50.0)
	_pause_main_button.pressed.connect(_return_to_title)
	pause_contents.add_child(_pause_main_button)
	_refresh_audio_buttons()
	_add_scrollable_contents(_pause_panel, pause_contents, 24, 22, 24, 22, &"PauseScroll")
	_set_focus_chain([
		_pause_resume_button,
		_pause_guide_button,
		restart,
		_pause_bgm_button,
		_pause_sfx_button,
		_pause_language_option,
		_pause_main_button,
	])
	_pause_panel.visible = false
	layer.add_child(_pause_panel)

	_upgrade_panel = _make_modal_panel(Vector2(1160.0, 500.0), Color(1.0, 0.7, 0.24, 0.95))
	var upgrade_contents := VBoxContainer.new()
	upgrade_contents.add_theme_constant_override("separation", 12)
	_upgrade_title = Label.new()
	_upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_title.add_theme_font_size_override("font_size", 26)
	upgrade_contents.add_child(_upgrade_title)
	var upgrade_hint := Label.new()
	_set_localized_text(upgrade_hint, &"upgrade.hint")
	upgrade_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_hint.add_theme_font_size_override("font_size", 15)
	upgrade_contents.add_child(upgrade_hint)
	_upgrade_card_grid = GridContainer.new()
	_upgrade_card_grid.name = "UpgradeCardGrid"
	_upgrade_card_grid.columns = _get_responsive_card_columns()
	_upgrade_card_grid.custom_minimum_size = Vector2(0.0, 320.0)
	_upgrade_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_card_grid.add_theme_constant_override("h_separation", 14)
	_upgrade_card_grid.add_theme_constant_override("v_separation", 14)
	for card_index: int in 3:
		var card: Button = _make_upgrade_card()
		card.custom_minimum_size = Vector2(0.0, 320.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.pressed.connect(_on_upgrade_card_pressed.bind(card_index))
		_upgrade_card_grid.add_child(card)
		_upgrade_cards.append(card)
	upgrade_contents.add_child(_upgrade_card_grid)
	_add_scrollable_contents(_upgrade_panel, upgrade_contents, 24, 22, 24, 22, &"UpgradeScroll")
	_upgrade_panel.visible = false
	layer.add_child(_upgrade_panel)
	layer.move_child(_pause_button, layer.get_child_count() - 1)


func _make_upgrade_card() -> Button:
	var card := Button.new()
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.text = ""
	card.add_theme_stylebox_override("normal", _make_pixel_panel_style(Color(0.12, 0.1, 0.06, 0.98), Color(0.58, 0.48, 0.28), 3))
	card.add_theme_stylebox_override("hover", _make_pixel_panel_style(Color(0.24, 0.19, 0.08, 1.0), Color(1.0, 0.8, 0.34), 4))
	card.add_theme_stylebox_override("pressed", _make_pixel_panel_style(Color(0.34, 0.22, 0.06, 1.0), Color(1.0, 0.9, 0.54), 4))
	card.add_theme_stylebox_override("focus", _make_ui_focus_style())
	card.add_theme_stylebox_override("disabled", _make_pixel_panel_style(Color(0.07, 0.06, 0.05, 0.92), Color(0.3, 0.26, 0.18), 3))
	var upgrade_icon := _make_semantic_icon(&"attack", Vector2(50.0, 50.0), Color(1.0, 0.82, 0.36))
	upgrade_icon.name = "CardIcon"
	upgrade_icon.position = Vector2(18.0, 16.0)
	card.add_child(upgrade_icon)
	var card_contents := VBoxContainer.new()
	card_contents.name = "CardContents"
	card_contents.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_contents.offset_left = 82.0
	card_contents.offset_top = 14.0
	card_contents.offset_right = -14.0
	card_contents.offset_bottom = -14.0
	card_contents.add_theme_constant_override("separation", 3)
	card_contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var role_label := Label.new()
	role_label.name = "RoleLabel"
	_set_localized_text(role_label, &"upgrade.role")
	role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role_label.add_theme_font_size_override("font_size", 13)
	role_label.add_theme_color_override("font_color", Color(0.54, 0.86, 0.96))
	card_contents.add_child(role_label)
	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.62))
	card_contents.add_child(title_label)
	var description_label := Label.new()
	description_label.name = "DescriptionLabel"
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(0.0, 42.0)
	description_label.add_theme_font_size_override("font_size", 16)
	description_label.add_theme_color_override("font_color", Color(0.88, 0.94, 0.98))
	card_contents.add_child(description_label)
	var effect_label := Label.new()
	effect_label.name = "EffectLabel"
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_font_size_override("font_size", 14)
	effect_label.add_theme_color_override("font_color", Color(0.76, 0.94, 0.82))
	card_contents.add_child(effect_label)
	var weakness_label := Label.new()
	weakness_label.name = "WeaknessLabel"
	weakness_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weakness_label.add_theme_font_size_override("font_size", 14)
	weakness_label.add_theme_color_override("font_color", Color(1.0, 0.68, 0.54))
	card_contents.add_child(weakness_label)
	card.add_child(card_contents)
	return card


func _on_upgrade_card_pressed(card_index: int) -> void:
	if card_index < 0 or card_index >= _upgrade_options.size():
		return
	_select_upgrade(str(_upgrade_options[card_index].get("option_id", "")))


func _get_responsive_card_columns(viewport_width: float = -1.0) -> int:
	var width: float = viewport_width if viewport_width > 0.0 else get_viewport_rect().size.x
	if width >= UI_CARD_THREE_COLUMN_BREAKPOINT:
		return 3
	if width >= UI_CARD_TWO_COLUMN_BREAKPOINT:
		return 2
	return 1


func _get_training_form_columns(viewport_width: float = -1.0) -> int:
	var width: float = viewport_width if viewport_width > 0.0 else get_viewport_rect().size.x
	return 2 if width >= UI_CARD_TWO_COLUMN_BREAKPOINT else 1


func _get_training_level_columns(viewport_width: float = -1.0) -> int:
	var width: float = viewport_width if viewport_width > 0.0 else get_viewport_rect().size.x
	if width >= UI_CARD_THREE_COLUMN_BREAKPOINT:
		return 4
	if width >= UI_CARD_TWO_COLUMN_BREAKPOINT:
		return 2
	return 1


func _get_training_enemy_columns(viewport_width: float = -1.0) -> int:
	return _get_training_form_columns(viewport_width)


func _configure_responsive_panel(panel: PanelContainer, preferred_size: Vector2) -> void:
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.set_meta(&"responsive_preferred_size", preferred_size)
	if not _responsive_modal_panels.has(panel):
		_responsive_modal_panels.append(panel)
	var viewport := get_viewport()
	if not viewport.size_changed.is_connected(_on_responsive_ui_viewport_size_changed):
		viewport.size_changed.connect(_on_responsive_ui_viewport_size_changed)
	_fit_responsive_panel(panel)


func _fit_responsive_panel(panel: PanelContainer, viewport_size_override: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(panel):
		return
	var viewport_size: Vector2 = get_viewport_rect().size if viewport_size_override == Vector2.ZERO else viewport_size_override
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var preferred_size: Vector2 = panel.get_meta(&"responsive_preferred_size", Vector2.ZERO)
	var available_size := Vector2(
		maxf(1.0, viewport_size.x - UI_MODAL_SAFE_MARGIN * 2.0),
		maxf(1.0, viewport_size.y - UI_MODAL_SAFE_MARGIN * 2.0)
	)
	var panel_size := Vector2(
		minf(preferred_size.x, available_size.x),
		minf(preferred_size.y, available_size.y)
	)
	panel.offset_left = -panel_size.x * 0.5
	panel.offset_top = -panel_size.y * 0.5
	panel.offset_right = panel_size.x * 0.5
	panel.offset_bottom = panel_size.y * 0.5


func _fit_training_controls_panel(viewport_size_override: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(_training_controls_panel):
		return
	var viewport_size: Vector2 = get_viewport_rect().size if viewport_size_override == Vector2.ZERO else viewport_size_override
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var available_width: float = maxf(1.0, viewport_size.x - UI_MODAL_SAFE_MARGIN * 2.0)
	var available_height: float = maxf(1.0, viewport_size.y - 112.0 - UI_MODAL_SAFE_MARGIN)
	var panel_width: float = minf(360.0, available_width)
	var panel_height: float = minf(520.0, available_height)
	_training_controls_panel.offset_left = UI_MODAL_SAFE_MARGIN
	_training_controls_panel.offset_top = 112.0
	_training_controls_panel.offset_right = UI_MODAL_SAFE_MARGIN + panel_width
	_training_controls_panel.offset_bottom = 112.0 + panel_height


func _add_scrollable_contents(
	parent: Control,
	contents: Control,
	margin_left: int,
	margin_top: int,
	margin_right: int,
	margin_bottom: int,
	scroll_name: StringName
) -> void:
	var margin := MarginContainer.new()
	margin.name = str(scroll_name).replace("Scroll", "Margin")
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", margin_left)
	margin.add_theme_constant_override("margin_top", margin_top)
	margin.add_theme_constant_override("margin_right", margin_right)
	margin.add_theme_constant_override("margin_bottom", margin_bottom)
	var scroll := ScrollContainer.new()
	scroll.name = str(scroll_name)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.add_child(contents)
	margin.add_child(scroll)
	parent.add_child(margin)


func _on_responsive_ui_viewport_size_changed(viewport_size_override: Vector2 = Vector2.ZERO) -> void:
	for index: int in range(_responsive_modal_panels.size() - 1, -1, -1):
		if not is_instance_valid(_responsive_modal_panels[index]):
			_responsive_modal_panels.remove_at(index)
			continue
		_fit_responsive_panel(_responsive_modal_panels[index], viewport_size_override)
	if is_instance_valid(_training_controls_panel):
		_fit_training_controls_panel(viewport_size_override)
	var viewport_width: float = get_viewport_rect().size.x if viewport_size_override == Vector2.ZERO else viewport_size_override.x
	if is_instance_valid(_guide_card_grid):
		_guide_card_grid.columns = _get_responsive_card_columns(viewport_width)
		_guide_card_grid.queue_sort()
	if is_instance_valid(_challenge_card_grid):
		_challenge_card_grid.columns = _get_responsive_card_columns(viewport_width)
		_challenge_card_grid.queue_sort()
	if is_instance_valid(_upgrade_card_grid):
		_upgrade_card_grid.columns = _get_responsive_card_columns(viewport_width)
		_upgrade_card_grid.queue_sort()
	if is_instance_valid(_training_form):
		_training_form.columns = _get_training_form_columns(viewport_width)
		_training_form.queue_sort()
	if is_instance_valid(_training_weapon_grid):
		_training_weapon_grid.columns = _get_responsive_card_columns(viewport_width)
		_training_weapon_grid.queue_sort()
	if is_instance_valid(_training_level_grid):
		_training_level_grid.columns = _get_training_level_columns(viewport_width)
		_training_level_grid.queue_sort()
	if is_instance_valid(_training_technique_grid):
		_training_technique_grid.columns = _get_responsive_card_columns(viewport_width)
		_training_technique_grid.queue_sort()
	if is_instance_valid(_training_ultimate_grid):
		_training_ultimate_grid.columns = _get_responsive_card_columns(viewport_width)
		_training_ultimate_grid.queue_sort()
	if is_instance_valid(_training_enemy_grid):
		_training_enemy_grid.columns = _get_training_enemy_columns(viewport_width)
		_training_enemy_grid.queue_sort()


func _make_modal_panel(size_value: Vector2, border_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	_apply_ui_theme(panel)
	_configure_responsive_panel(panel, size_value)
	var style := _make_pixel_panel_style(Color(0.085, 0.07, 0.04, 0.98), border_color, 4)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_label(position_value: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	_apply_ui_theme(label)
	label.position = position_value
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _create_action_bar(layer: CanvasLayer) -> void:
	var action_bar := PanelContainer.new()
	action_bar.name = "ActionBar"
	_apply_ui_theme(action_bar)
	action_bar.anchor_left = 0.5
	action_bar.anchor_top = 1.0
	action_bar.anchor_right = 0.5
	action_bar.anchor_bottom = 1.0
	action_bar.offset_left = -260.0
	action_bar.offset_top = -126.0
	action_bar.offset_right = 260.0
	action_bar.offset_bottom = -18.0
	var action_bar_style := _make_pixel_panel_style(Color(0.075, 0.06, 0.035, 0.78), Color(0.52, 0.44, 0.26, 0.86), 3)
	action_bar.add_theme_stylebox_override("panel", action_bar_style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var player_state_panel := PanelContainer.new()
	player_state_panel.custom_minimum_size = Vector2(104.0, 66.0)
	player_state_panel.add_theme_stylebox_override("panel", _make_pixel_panel_style(Color(0.11, 0.07, 0.05, 0.96), Color(0.72, 0.32, 0.22, 0.9), 2))
	var player_state_contents := HBoxContainer.new()
	player_state_contents.alignment = BoxContainer.ALIGNMENT_CENTER
	player_state_contents.add_theme_constant_override("separation", 0)
	var player_icon := _make_semantic_icon(&"player", Vector2(28.0, 28.0), Color(0.76, 0.94, 0.72))
	player_state_contents.add_child(player_icon)
	_player_state_label = Label.new()
	_player_state_label.name = "PlayerStateLabel"
	_player_state_label.custom_minimum_size = Vector2(58.0, 28.0)
	_player_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_player_state_label.add_theme_font_size_override("font_size", 20)
	_player_state_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.54))
	_player_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_state_contents.add_child(_player_state_label)
	player_state_panel.add_child(player_state_contents)
	row.add_child(player_state_panel)
	_attack_button = _make_action_button(Color(1.0, 0.67, 0.2), &"action.attack", "Q")
	_dodge_button = _make_action_button(Color(0.3, 0.75, 1.0), &"action.dodge", "W")
	_negate_button = _make_action_button(Color(0.28, 0.9, 0.9), &"action.negate", "E")
	_ultimate_button = _make_action_button(Color(0.92, 0.36, 0.85), &"action.ultimate", "R")
	_negate_button.pressed.connect(_input_source.request_ui_negate)
	_ultimate_button.pressed.connect(_input_source.request_ui_ultimate)
	_negate_button.pressed.connect(_play_ui_sfx)
	_ultimate_button.pressed.connect(_play_ui_sfx)
	for button: Button in [_attack_button, _dodge_button, _negate_button, _ultimate_button]:
		button.mouse_entered.connect(_show_action_tooltip.bind(button))
		button.mouse_exited.connect(_hide_action_tooltip.bind(button))
		button.focus_entered.connect(_show_action_tooltip.bind(button))
		button.focus_exited.connect(_hide_action_tooltip.bind(button))
		row.add_child(button)
	_set_focus_chain([_attack_button, _dodge_button, _negate_button, _ultimate_button])
	margin.add_child(row)
	action_bar.add_child(margin)
	layer.add_child(action_bar)


func _make_action_button(color: Color, action_key: StringName, shortcut: String) -> Button:
	var button := Button.new()
	_apply_ui_theme(button)
	button.custom_minimum_size = Vector2(92.0, 88.0)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(color, 0.2)
	normal.border_color = Color(color, 0.9)
	normal.set_border_width_all(3)
	normal.corner_radius_top_left = 0
	normal.corner_radius_top_right = 0
	normal.corner_radius_bottom_left = 0
	normal.corner_radius_bottom_right = 0
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(color, 0.42)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(color, 0.6)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.05, 0.07, 0.12, 0.88)
	disabled.border_color = Color(color, 0.3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	var overlay: Control = ACTION_PROGRESS_OVERLAY_SCRIPT.new()
	overlay.name = "ProgressOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.call("configure", color)
	button.add_child(overlay)
	var action_name := Label.new()
	action_name.name = "ActionNameLabel"
	_set_localized_text(action_name, action_key)
	action_name.position = Vector2(4.0, 44.0)
	action_name.size = Vector2(84.0, 19.0)
	action_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_name.clip_text = false
	action_name.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	action_name.add_theme_font_size_override("font_size", 13)
	action_name.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
	action_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(action_name)
	var action_label := Label.new()
	action_label.name = "ActionLabel"
	action_label.position = Vector2(4.0, 64.0)
	action_label.size = Vector2(84.0, 20.0)
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_label.clip_text = false
	action_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	action_label.add_theme_font_size_override("font_size", 10)
	action_label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))
	action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_label.text = ""
	button.add_child(action_label)
	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.position = Vector2(64.0, 4.0)
	cost_label.size = Vector2(24.0, 16.0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 10)
	cost_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.text = ""
	button.add_child(cost_label)
	var action_id: StringName = &"attack" if shortcut == "Q" else &"dodge" if shortcut == "W" else &"negate" if shortcut == "E" else &"ultimate"
	var action_icon := _make_semantic_icon(action_id, Vector2(36.0, 36.0), color)
	action_icon.position = Vector2(28.0, 7.0)
	button.add_child(action_icon)
	var ready_marker := ColorRect.new()
	ready_marker.name = "ReadyMarker"
	ready_marker.position = Vector2(6.0, 84.0)
	ready_marker.size = Vector2(80.0, 3.0)
	ready_marker.color = color
	ready_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(ready_marker)
	var keycap := Label.new()
	keycap.name = "KeyCap"
	keycap.position = Vector2(34.0, -14.0)
	keycap.size = Vector2(24.0, 19.0)
	keycap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keycap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	keycap.add_theme_font_size_override("font_size", 12)
	keycap.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	keycap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keycap.text = shortcut
	var keycap_style := StyleBoxFlat.new()
	keycap_style.bg_color = Color(0.09, 0.07, 0.04, 0.98)
	keycap_style.border_color = Color(color, 0.84)
	keycap_style.set_border_width_all(2)
	keycap_style.corner_radius_top_left = 0
	keycap_style.corner_radius_top_right = 0
	keycap_style.corner_radius_bottom_left = 0
	keycap_style.corner_radius_bottom_right = 0
	keycap.add_theme_stylebox_override("normal", keycap_style)
	button.add_child(keycap)
	return button


func _create_action_tooltip(layer: CanvasLayer) -> void:
	_action_tooltip = PanelContainer.new()
	_apply_ui_theme(_action_tooltip)
	_action_tooltip.size = Vector2(300.0, 82.0)
	_action_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tooltip_style := StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.09, 0.07, 0.04, 0.98)
	tooltip_style.border_color = Color(0.72, 0.62, 0.34, 0.9)
	tooltip_style.set_border_width_all(3)
	tooltip_style.corner_radius_top_left = 0
	tooltip_style.corner_radius_top_right = 0
	tooltip_style.corner_radius_bottom_left = 0
	tooltip_style.corner_radius_bottom_right = 0
	_action_tooltip.add_theme_stylebox_override("panel", tooltip_style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	_action_tooltip_label = Label.new()
	_action_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_tooltip_label.add_theme_font_size_override("font_size", 14)
	_action_tooltip_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	margin.add_child(_action_tooltip_label)
	_action_tooltip.add_child(margin)
	_action_tooltip.visible = false
	layer.add_child(_action_tooltip)


func _apply_ui_theme(control: Control) -> void:
	control.theme = _ui_theme


func _set_action_tooltip(button: Button, text_value: String) -> void:
	if str(button.get_meta(&"action_tooltip", "")) == text_value:
		return
	button.set_meta(&"action_tooltip", text_value)
	if _tooltip_source == button and _action_tooltip.visible:
		_action_tooltip_label.text = text_value


func _show_action_tooltip(button: Button) -> void:
	if not is_instance_valid(_action_tooltip) or not is_instance_valid(button) or not button.visible:
		return
	var tooltip_text: String = str(button.get_meta(&"action_tooltip", ""))
	if tooltip_text.is_empty():
		return
	var button_rect: Rect2 = button.get_global_rect()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var tooltip_position := Vector2(
		clampf(button_rect.get_center().x - _action_tooltip.size.x * 0.5, 12.0, viewport_size.x - _action_tooltip.size.x - 12.0),
		maxf(12.0, button_rect.position.y - _action_tooltip.size.y - 10.0)
	)
	_action_tooltip.position = tooltip_position
	_action_tooltip_label.text = tooltip_text
	_action_tooltip.visible = true
	_tooltip_source = button


func _hide_action_tooltip(button: Button = null) -> void:
	if button != null:
		if _tooltip_source != button:
			return
		if button.has_focus():
			return
		if button.get_global_rect().has_point(get_viewport().get_mouse_position()):
			return
	if is_instance_valid(_action_tooltip):
		_action_tooltip.visible = false
	_tooltip_source = null


func _set_action_label(button: Button, text_value: String) -> void:
	var action_label := button.get_node("ActionLabel") as Label
	if action_label.text == text_value:
		return
	action_label.set_meta(&"localization_text_key", &"")
	action_label.set_meta(&"localization_text_arguments", [])
	action_label.text = text_value


func _set_action_label_key(button: Button, key: StringName, arguments: Array = []) -> void:
	var action_label := button.get_node("ActionLabel") as Label
	_set_localized_text(action_label, key, arguments)


func _set_action_cost(button: Button, text_value: String) -> void:
	var cost_label := button.get_node("CostLabel") as Label
	if cost_label.text == text_value:
		return
	cost_label.text = text_value


func _set_action_visual_state(button: Button, state: StringName) -> void:
	button.set_meta(&"action_visual_state", state)
	match state:
		&"available":
			button.self_modulate = Color.WHITE
		&"ready":
			button.self_modulate = Color(1.0, 0.84, 1.0, 1.0)
		&"cooldown":
			button.self_modulate = Color(0.72, 0.78, 0.84, 1.0)
		&"empty":
			button.self_modulate = Color(0.62, 0.7, 0.78, 1.0)
		&"locked":
			button.self_modulate = Color(0.48, 0.54, 0.62, 1.0)


func _set_action_ready_marker(button: Button, is_visible: bool) -> void:
	var marker := button.get_node_or_null("ReadyMarker") as ColorRect
	if marker != null:
		marker.visible = is_visible


func _get_action_overlay(button: Button) -> Control:
	return button.get_node("ProgressOverlay") as Control


func _refresh_upgrade_cards() -> void:
	for index: int in _upgrade_cards.size():
		var card: Button = _upgrade_cards[index]
		if index >= _upgrade_options.size():
			card.visible = false
			card.focus_mode = Control.FOCUS_NONE
			card.disabled = true
			continue
		var option: Dictionary = _upgrade_options[index]
		card.visible = true
		card.focus_mode = Control.FOCUS_ALL
		var color: Color = option.get("color", Color(1.0, 0.82, 0.36))
		var icon_id: StringName = StringName(str(option.get("icon_id", "attack")))
		var icon := card.get_node_or_null("CardIcon") as Control
		if icon != null:
			icon.call("configure", icon_id, color)
		var role_label := card.get_node_or_null("CardContents/RoleLabel") as Label
		var title_label := card.get_node_or_null("CardContents/TitleLabel") as Label
		var description_label := card.get_node_or_null("CardContents/DescriptionLabel") as Label
		var effect_label := card.get_node_or_null("CardContents/EffectLabel") as Label
		var weakness_label := card.get_node_or_null("CardContents/WeaknessLabel") as Label
		if role_label != null:
			var role_key: StringName = StringName(str(option.get("subtitle_key", option.get("icon_label_key", "upgrade.role"))))
			role_label.text = _tr(role_key)
		if title_label != null:
			title_label.text = _localized_data_text(option, &"title_key", &"upgrade.fallback")
		if description_label != null:
			description_label.text = _localized_data_text(option, &"description_key", &"upgrade.immediate")
		var semantic_icon := card.get_child(0) as Control
		if semantic_icon != null:
			semantic_icon.call("configure", icon_id, color)
		var rule_text: String = _localized_data_text(option, &"rule_text_key", &"") if option.has("rule_text_key") else ""
		var weakness_text: String = _localized_data_text(option, &"weakness_text_key", &"") if option.has("weakness_text_key") else ""
		if effect_label != null:
			var detail_text: String = _localized_data_text(option, &"detail_key", &"") if option.has("detail_key") else ""
			if detail_text.is_empty():
				detail_text = _tr(&"upgrade.immediate")
			var rule_suffix: String = _tr(&"upgrade.rule", [rule_text]) if not rule_text.is_empty() else ""
			effect_label.text = _tr(&"upgrade.effect", [detail_text, rule_suffix])
		if weakness_label != null:
			weakness_label.text = _tr(&"upgrade.weakness", [weakness_text]) if not weakness_text.is_empty() else _tr(&"upgrade.condition")
		card.tooltip_text = "%s\n%s\n%s" % [
			_localized_data_text(option, &"title_key", &"upgrade.fallback"),
			_localized_data_text(option, &"description_key", &"upgrade.immediate"),
			_localized_data_text(option, &"detail_key", &"upgrade.immediate"),
		]
		card.disabled = false
	var focusables: Array = []
	for card: Button in _upgrade_cards:
		if card.visible and not card.disabled:
			focusables.append(card)
	_set_focus_chain(focusables)


func _show_upgrade_result(option: Dictionary) -> void:
	_upgrade_result_option = option.duplicate(true)
	_refresh_upgrade_result()
	_upgrade_result_panel.visible = true
	_upgrade_result_remaining = DontDodgeTuning.UPGRADE_RESULT_DURATION


func _refresh_upgrade_result() -> void:
	if not is_instance_valid(_upgrade_result_title) or _upgrade_result_option.is_empty():
		return
	_upgrade_result_title.text = _tr(&"upgrade.applied", [_localized_data_text(_upgrade_result_option, &"title_key", &"upgrade.fallback")])
	_upgrade_result_detail.text = _localized_data_text(_upgrade_result_option, &"detail_key", &"upgrade.applied_detail")


func _update_upgrade_result(delta: float) -> void:
	if _upgrade_result_remaining <= 0.0:
		return
	_upgrade_result_remaining = maxf(0.0, _upgrade_result_remaining - delta)
	if _upgrade_result_remaining <= 0.0:
		_upgrade_result_panel.visible = false


func _request_hud_refresh() -> void:
	_hud_refresh_requested = true


func _update_hud(delta: float = 0.0, force_refresh: bool = true) -> void:
	_update_action_controls()
	_hud_refresh_elapsed += delta
	if not force_refresh and not _hud_refresh_requested and _hud_refresh_elapsed < HUD_REFRESH_INTERVAL:
		return
	_hud_refresh_elapsed = 0.0
	_hud_refresh_requested = false
	_refresh_survival_hud()


func _refresh_survival_hud() -> void:
	if not is_instance_valid(_hud):
		return
	var seconds_remaining: int = maxi(0, ceili(DontDodgeTuning.SESSION_DURATION - _elapsed))
	var minutes_remaining: int = seconds_remaining / 60
	var display_seconds: int = seconds_remaining % 60
	var current_wave: int = int(_timeline[_active_slot_index]["wave_id"]) if _active_slot_index >= 0 and _active_slot_index < _timeline.size() else DontDodgeTuning.WAVE_COUNT
	var next_experience_threshold: int = int(DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS[_experience_level]) if _experience_level < DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS.size() else DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS.back()
	var wave_text: String = _tr(&"hud.training") if _mode == &"training" else _tr(&"hud.wave", [current_wave, DontDodgeTuning.WAVE_COUNT])
	var timer_text := "∞" if _mode == &"training" else "%02d:%02d" % [minutes_remaining, display_seconds]
	var status_text: String = _tr(&"hud.unlimited") if _mode == &"training" else _tr(&"hud.in_progress")
	if _pause_mode == PauseMode.MANUAL:
		status_text = _tr(&"hud.paused")
	elif _pause_mode == PauseMode.UPGRADE:
		status_text = _tr(&"hud.upgrade_select")
	elif _state == GameState.THREAT_GATE:
		status_text = _tr(&"hud.cleanup_wait")
	elif _state == GameState.FINAL_CLEANUP:
		status_text = _tr(&"hud.clearing")
	elif _state == GameState.PLAYER_DEAD:
		status_text = _tr(&"hud.player_dead")
	elif _state == GameState.RESULT:
		status_text = _tr(&"hud.result")
	elif _state == GameState.CHALLENGE_REVEAL:
		status_text = _tr(&"hud.challenge_reveal")
	var build_text: String = _tr(&"hud.base_build")
	if not _weapon_id.is_empty():
		build_text = _get_weapon_title()
		if not _technique_id.is_empty():
			build_text += " · %s" % _get_technique_title()
		if not _ultimate_id.is_empty():
			build_text += " · %s" % _get_ultimate_title()
	var hud_text := "%s|%s|%s|%d|%s" % [wave_text, timer_text, status_text, _waves_cleared, build_text]
	if hud_text == _last_hud_text:
		if is_instance_valid(_player_state_label) and is_instance_valid(_xp_bar) and is_instance_valid(_xp_label):
			_update_compact_player_hud(next_experience_threshold)
		return
	_last_hud_text = hud_text
	_hud.text = wave_text
	if is_instance_valid(_timer_label):
		_timer_label.text = timer_text
	if is_instance_valid(_wave_status_label):
		_wave_status_label.text = status_text
	if is_instance_valid(_build_hud_label):
		_build_hud_label.text = build_text
	if is_instance_valid(_challenge_hud_label):
		_challenge_hud_label.visible = _mode == &"challenge"
		_challenge_hud_label.text = _tr(&"hud.challenge", [_localized_data_text(_challenge_debuff, &"title_key", &"hud.challenge_ready")]) if _mode == &"challenge" else ""
	_update_wave_segments(current_wave)
	_update_compact_player_hud(next_experience_threshold)


func _update_wave_segments(current_wave: int) -> void:
	if _wave_segments.is_empty():
		return
	var completed_wave: int = clampi(_waves_cleared, 0, DontDodgeTuning.WAVE_COUNT)
	for index: int in _wave_segments.size():
		var wave_number: int = index + 1
		var segment_style: StyleBoxFlat = _wave_segment_future_style
		if wave_number < current_wave or wave_number <= completed_wave:
			segment_style = _wave_segment_completed_style
		if wave_number == current_wave:
			segment_style = _wave_segment_active_style
		_wave_segments[index].add_theme_stylebox_override("panel", segment_style)


func _update_compact_player_hud(next_experience_threshold: int) -> void:
	if is_instance_valid(_player_state_label):
		var health_text: String = "♥".repeat(_player.get_health()) + "♡".repeat(maxi(0, _player.get_max_health() - _player.get_health()))
		_player_state_label.text = health_text
	if is_instance_valid(_xp_bar) and is_instance_valid(_xp_label):
		var is_max_level: bool = _experience_level >= DontDodgeTuning.EXPERIENCE_LEVEL_THRESHOLDS.size()
		_xp_bar.max_value = float(next_experience_threshold)
		_xp_bar.value = float(next_experience_threshold if is_max_level else mini(_experience, next_experience_threshold))
		_xp_label.text = _tr(&"hud.level_max", [_experience_level]) if is_max_level else _tr(&"hud.level_xp", [_experience_level, _experience, next_experience_threshold])


func _update_action_controls() -> void:
	if not is_instance_valid(_attack_button):
		return
	var defense_charges: int = _defense.get_charges()
	var defense_state_changed: bool = defense_charges != _last_action_defense_charges
	var controls_locked: bool = _pause_mode != PauseMode.NONE or not _is_gameplay_state()
	var attack_overlay: Control = _get_action_overlay(_attack_button)
	if _attack_recovery_remaining > 0.0:
		_set_action_label_key(_attack_button, &"action.attack_cooldown_display", [_attack_recovery_remaining])
		_attack_button.disabled = true
		attack_overlay.call("set_cooldown_ratio", _attack_recovery_remaining / _get_focus_recovery())
		_set_action_tooltip(_attack_button, _tr(&"action.attack_tooltip_cooldown", [_get_focus_damage(), get_attack_profile()["attack_speed_percent"], _attack_recovery_remaining]))
		_set_action_visual_state(_attack_button, &"cooldown")
	else:
		_set_action_label(_attack_button, "")
		_attack_button.disabled = controls_locked
		attack_overlay.call("set_cooldown_ratio", 0.0)
		_set_action_tooltip(_attack_button, _tr(&"action.attack_tooltip_ready", [_get_focus_damage(), get_attack_profile()["attack_speed_percent"], roundi(_get_focus_range()), roundi(rad_to_deg(_get_focus_arc_angle())), _get_focus_recovery()]))
		_set_action_visual_state(_attack_button, &"locked" if controls_locked else &"available")
	_set_action_ready_marker(_attack_button, _attack_recovery_remaining <= 0.0 and not controls_locked)
	if controls_locked:
		_attack_button.disabled = true
	var defense_available: bool = defense_charges > 0
	var dodge_overlay: Control = _get_action_overlay(_dodge_button)
	var negate_overlay: Control = _get_action_overlay(_negate_button)
	var defense_max_charges: int = _defense.get_max_charges()
	if defense_state_changed or defense_charges < defense_max_charges:
		var defense_recovery: Array[float] = _defense.get_recovery_progresses()
		dodge_overlay.call("set_stack_state", defense_charges, defense_max_charges, defense_recovery)
		negate_overlay.call("set_stack_state", defense_charges, defense_max_charges, defense_recovery)
		_last_action_defense_charges = defense_charges
	dodge_overlay.call("set_cooldown_ratio", 0.0)
	var dodge_cost: int = _get_dodge_cost()
	_set_action_label_key(_dodge_button, &"action.defense_display", [defense_charges, defense_max_charges])
	_set_action_cost(_dodge_button, "×%d" % dodge_cost if dodge_cost > 1 and defense_charges >= dodge_cost else "")
	var dodge_available: bool = defense_charges >= dodge_cost
	_dodge_button.disabled = controls_locked or not dodge_available
	_set_action_ready_marker(_dodge_button, dodge_available and not controls_locked)
	_set_action_visual_state(_dodge_button, &"locked" if controls_locked else &"available" if dodge_available else &"empty")
	if defense_state_changed:
		var dodge_suffix: String = _tr(&"action.dodge_twice_suffix") if dodge_cost == 1 and defense_charges == defense_max_charges else ""
		_set_action_tooltip(_dodge_button, _tr(&"action.dodge_tooltip", [defense_charges, defense_max_charges, dodge_cost, dodge_suffix]))
	negate_overlay.call("set_cooldown_ratio", 0.0)
	_set_action_label_key(_negate_button, &"action.defense_locked_display" if not _is_negate_enabled() else &"action.defense_display", [defense_charges, defense_max_charges])
	_set_action_cost(_negate_button, "")
	var negate_available: bool = defense_available and _is_negate_enabled()
	_negate_button.disabled = controls_locked or not negate_available
	_set_action_ready_marker(_negate_button, negate_available and not controls_locked)
	_set_action_visual_state(_negate_button, &"locked" if controls_locked or not _is_negate_enabled() else &"available" if negate_available else &"empty")
	if defense_state_changed:
		var negate_state: String = _tr(&"action.negate_disabled") if not _is_negate_enabled() else _tr(&"action.defense_state", [defense_charges, defense_max_charges])
		_set_action_tooltip(_negate_button, _tr(&"action.negate_tooltip", [negate_state]))
	var ultimate_unlocked: bool = not _ultimate_id.is_empty()
	var ultimate_percent: int = _get_ultimate_percent() if ultimate_unlocked else 0
	var ultimate_ready: bool = ultimate_unlocked and _ultimate_charge >= DontDodgeTuning.ULTIMATE_MAX
	var ultimate_overlay: Control = _get_action_overlay(_ultimate_button)
	ultimate_overlay.call("set_charge_ring", float(_ultimate_charge) / float(DontDodgeTuning.ULTIMATE_MAX) if ultimate_unlocked else 0.0, true)
	ultimate_overlay.call("set_cooldown_ratio", 0.0)
	if ultimate_ready:
		_set_action_label_key(_ultimate_button, &"action.ultimate_ready")
	else:
		_set_action_label_key(_ultimate_button, &"action.ultimate_charge", [ultimate_percent]) if ultimate_unlocked else _set_action_label_key(_ultimate_button, &"action.locked")
	_ultimate_button.disabled = controls_locked or not ultimate_ready
	_set_action_ready_marker(_ultimate_button, ultimate_ready and not controls_locked)
	_set_action_cost(_ultimate_button, "")
	_set_action_visual_state(_ultimate_button, &"locked" if controls_locked or not ultimate_unlocked else &"ready" if ultimate_ready else &"empty")
	var ultimate_title: String = _get_ultimate_title() if ultimate_unlocked else _tr(&"action.locked")
	var ultimate_detail: String = _localized_data_text(_get_ultimate_data(), &"detail_key", &"action.ultimate_select_detail") if ultimate_unlocked else _tr(&"action.ultimate_locked_detail")
	var ultimate_state: String = _tr(&"action.ultimate_ready") if ultimate_ready else (_tr(&"action.ultimate_charge", [ultimate_percent]) if ultimate_unlocked else _tr(&"action.locked"))
	_set_action_tooltip(_ultimate_button, "%s\nR · %s\n%s" % [ultimate_title, ultimate_state, ultimate_detail])
	_refresh_feedback_text()


func _refresh_feedback_text() -> void:
	if not is_instance_valid(_feedback_label):
		return
	var feedback_text: String = _tr(_feedback_key, _resolve_localized_arguments(_feedback_arguments)) if _feedback_remaining > 0.0 and not _feedback_key.is_empty() else ""
	if _feedback_label.text != feedback_text:
		_feedback_label.text = feedback_text


func _show_feedback_key(key: StringName, arguments: Array, duration: float) -> void:
	_feedback_key = key
	_feedback_arguments = arguments.duplicate()
	_feedback_remaining = duration
	_refresh_feedback_text()


func _finish_run(reason_key: StringName, reason_arguments: Array = [], outcome: String = "clear") -> void:
	if _ended:
		return
	_outcome = outcome
	_record_state(GameState.RESULT, outcome)
	_ended = true
	_input_source.clear_requests()
	_hide_action_tooltip()
	_end_reason_key = reason_key
	_end_reason_arguments = reason_arguments.duplicate()
	_emit_sound_event(SOUND_EVENT_GAME_CLEAR if outcome == "clear" else SOUND_EVENT_GAME_OVER, _player.global_position)
	_write_run_log()
	_refresh_end_panel()
	_end_panel.visible = true
	_sync_combat_visuals()


func _refresh_end_panel() -> void:
	if not is_instance_valid(_end_panel) or _end_reason_key.is_empty():
		return
	var reason: String = _tr(_end_reason_key, _end_reason_arguments)
	var mode_text: String = _tr(&"result.challenge_mode", [_localized_data_text(_challenge_debuff, &"title_key", &"hud.challenge_ready")]) if _mode == &"challenge" else _tr(&"result.normal_mode")
	_end_panel.get_node("ResultMargin/ResultScroll/Contents/Title").text = _tr(&"result.summary", [
		reason,
		mode_text,
		int(_stats["kills"]),
		int(_stats["hits_taken"]),
		int(_stats["dodges"]),
		int(_stats["negates"]),
		int(_stats["perfect_dodges"]),
		int(_stats["interrupts"]),
		int(_stats["projectiles_erased"]),
		int(_stats["ultimates"]),
	])


func _write_run_log() -> void:
	var record: Dictionary = {
		"outcome": _outcome,
		"reason": _tr(_end_reason_key, _end_reason_arguments),
		"reason_key": str(_end_reason_key),
		"mode": _mode,
		"challenge_debuff_id": _challenge_debuff_id,
		"challenge_roll_seed": _challenge_roll_seed,
		"scheduled_combat_seconds": DontDodgeTuning.SESSION_DURATION,
		"active_combat_seconds": snappedf(_elapsed, 0.001),
		"threat_gate_seconds": snappedf(float(_time_metrics["threat_gate_seconds"]), 0.001),
		"cleanup_seconds": snappedf(float(_time_metrics["cleanup_seconds"]), 0.001),
		"upgrade_seconds": snappedf(float(_time_metrics["upgrade_seconds"]), 0.001),
		"unpaused_session_seconds": snappedf(float(_time_metrics["unpaused_session_seconds"]), 0.001),
		"manual_pause_seconds": snappedf(float(_time_metrics["manual_pause_seconds"]), 0.001),
		"total_wall_seconds": snappedf(float(_time_metrics["total_wall_seconds"]), 0.001),
		"app_inactive_seconds": 0.0,
		"death_wave_id": _death_record.get("death_wave_id", null),
		"death_pattern_id": _death_record.get("death_pattern_id", null),
		"death_active_time": _death_record.get("death_active_time", null),
		"death_hazard_id": _death_record.get("death_hazard_id", null),
		"run_seed": _run_seed,
		"pattern_seed": _pattern_seed,
		"stats": _stats,
		"ultimate_charge_sources": _ultimate_sources,
		"defense_charges_remaining": _defense.get_charges(),
		"waves_reached": _waves_reached,
		"waves_cleared": _waves_cleared,
		"experience": _experience,
		"experience_level": _experience_level,
		"loadout": get_loadout(),
		"attack_profile": get_attack_profile(),
		"upgrade_history": _upgrade_history,
		"pattern_events": _pattern_events,
		"actual_spawn_events": _actual_spawn_events,
		"input_events": _input_events,
		"state_events": _state_events,
	}
	var path: String = "user://dont_dodge_runs.jsonl"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save DON’T DODGE playtest log.")
		return
	file.seek_end()
	file.store_line(JSON.stringify(record))
	file.close()
	print("[DontDodge] %s" % JSON.stringify(record))


func _restart() -> void:
	if _is_scene_transitioning():
		return
	_start_game_after_reload = true
	_start_challenge_after_reload = _mode == &"challenge"
	_request_scene_reload()


func _return_to_title() -> void:
	if _is_scene_transitioning():
		return
	_start_game_after_reload = false
	_start_challenge_after_reload = false
	if launch_mode == &"training" or _mode == &"training":
		_request_scene_transition(MAIN_SCENE_PATH)
	else:
		_request_scene_reload()


func _sync_combat_visuals() -> void:
	if not is_instance_valid(_combat_visuals):
		return
	_combat_visuals.call("set_simulation_paused", _ended or _state == GameState.MANUAL_PAUSE or _state == GameState.UPGRADE or _state == GameState.CHALLENGE_REVEAL)
	_combat_visuals.call("set_spawn_warnings", _spawn_warnings)
	var target: DontDodgeEnemy = _find_priority_enemy(INF)
	if is_instance_valid(target) and target.get_threat_time() < INF:
		_combat_visuals.call("set_priority_target_line", _player.global_position, target.global_position)
	else:
		_combat_visuals.call("clear_priority_target_line")
	var focus_target: DontDodgeEnemy = _find_priority_enemy(_get_focus_range())
	if not is_instance_valid(focus_target):
		_combat_visuals.call("clear_focus_preview")
		return
	var focus_direction: Vector2 = (focus_target.global_position - _player.global_position).normalized()
	var target_radius: float = 34.0 if focus_target.get_enemy_type() == DontDodgeEnemy.EnemyType.ELITE else 22.0 if focus_target.get_enemy_type() == DontDodgeEnemy.EnemyType.VOLLEY else 18.0
	_combat_visuals.call("set_focus_preview", _player.global_position, focus_target.global_position, target_radius, focus_direction, _get_focus_range(), _get_focus_arc_angle())


func _call_combat_visual(method: StringName, arguments: Array) -> void:
	if is_instance_valid(_combat_visuals):
		_combat_visuals.callv(method, arguments)


func _call_screen_feedback(method: StringName, arguments: Array) -> void:
	if is_instance_valid(_screen_feedback):
		_screen_feedback.callv(method, arguments)


func _request_hit_stop(duration: float) -> void:
	_hit_stop_remaining = maxf(_hit_stop_remaining, duration)


func _emit_sound_event(event_id: StringName, world_position: Vector2) -> void:
	sound_event_requested.emit(event_id, world_position)


func _on_sound_event_requested(event_id: StringName, world_position: Vector2) -> void:
	_get_sfx_controller().call("play_event", event_id, world_position)
