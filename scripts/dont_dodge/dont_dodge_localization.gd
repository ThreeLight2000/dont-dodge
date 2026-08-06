class_name DontDodgeLocalization
extends Node

signal locale_changed(locale: StringName)

const SETTINGS_PATH: String = "user://dont_dodge_settings.cfg"
const SETTINGS_SECTION: String = "localization"
const SETTINGS_KEY: String = "locale"
const CATALOG_PATH: String = "res://localization/dont_dodge.csv"
const DEFAULT_LOCALE: StringName = &"ko"
const SUPPORTED_LOCALES: Array[StringName] = [&"ko", &"en"]

var _locale: StringName = DEFAULT_LOCALE
var _catalog: Dictionary = {}


func _ready() -> void:
	_load_catalog()
	_locale = _load_saved_locale()
	TranslationServer.set_locale(str(_locale))


func current_locale() -> StringName:
	return _locale


func set_locale(locale: StringName, persist: bool = true) -> void:
	var next_locale: StringName = locale if SUPPORTED_LOCALES.has(locale) else DEFAULT_LOCALE
	var changed: bool = _locale != next_locale
	_locale = next_locale
	TranslationServer.set_locale(str(_locale))
	if persist:
		_save_locale()
	if changed:
		locale_changed.emit(_locale)


func translate(key: StringName, arguments: Array = []) -> String:
	var message_key: String = str(key)
	var text: String = TranslationServer.translate(message_key)
	var locale_catalog: Dictionary = _catalog.get(str(_locale), {})
	if locale_catalog.has(message_key):
		var catalog_text: String = str(locale_catalog[message_key])
		if text == message_key or _normalize_text(text) != _normalize_text(catalog_text):
			text = catalog_text
	text = _normalize_text(text)
	if arguments.is_empty():
		return text
	return text % arguments


func _normalize_text(text: String) -> String:
	return text.replace("\\n", "\n")


func has_key(key: StringName, locale: StringName = &"") -> bool:
	var target_locale: StringName = _locale if locale.is_empty() else locale
	var locale_catalog: Dictionary = _catalog.get(str(target_locale), {})
	return locale_catalog.has(str(key)) and not str(locale_catalog[str(key)]).strip_edges().is_empty()


func validate_catalog(required_keys: Array[StringName] = []) -> PackedStringArray:
	var errors := PackedStringArray()
	for locale: StringName in SUPPORTED_LOCALES:
		if not _catalog.has(str(locale)):
			errors.append("missing locale column: %s" % locale)
	for locale: StringName in SUPPORTED_LOCALES:
		var locale_catalog: Dictionary = _catalog.get(str(locale), {})
		for key: StringName in required_keys:
			if not locale_catalog.has(str(key)):
				errors.append("missing %s translation: %s" % [locale, key])
			elif str(locale_catalog[str(key)]).strip_edges().is_empty():
				errors.append("empty %s translation: %s" % [locale, key])
	return errors


func get_supported_locales() -> Array[StringName]:
	return SUPPORTED_LOCALES.duplicate()


func get_catalog_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for locale: StringName in SUPPORTED_LOCALES:
		for key: String in _catalog.get(str(locale), {}).keys():
			if not keys.has(StringName(key)):
				keys.append(StringName(key))
	return keys


func _load_saved_locale() -> StringName:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return DEFAULT_LOCALE
	var saved_locale: StringName = StringName(str(settings.get_value(SETTINGS_SECTION, SETTINGS_KEY, str(DEFAULT_LOCALE))))
	return saved_locale if SUPPORTED_LOCALES.has(saved_locale) else DEFAULT_LOCALE


func _save_locale() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		settings = ConfigFile.new()
	settings.set_value(SETTINGS_SECTION, SETTINGS_KEY, str(_locale))
	if settings.save(SETTINGS_PATH) != OK:
		push_warning("Could not save DON’T DODGE locale setting.")


func _load_catalog() -> void:
	_catalog.clear()
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return
	var header: PackedStringArray = file.get_csv_line()
	if header.is_empty() or header[0] != "keys":
		push_error("DON’T DODGE translation catalog must start with a keys column.")
		return
	var locale_columns: Dictionary = {}
	for column_index: int in range(1, header.size()):
		locale_columns[column_index] = str(header[column_index])
		_catalog[str(header[column_index])] = {}
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.is_empty() or str(row[0]).strip_edges().is_empty():
			continue
		var key: String = str(row[0]).strip_edges()
		for column_index: int in locale_columns:
			var locale: String = locale_columns[column_index]
			var value: String = str(row[column_index]) if column_index < row.size() else ""
			_catalog[locale][key] = value
