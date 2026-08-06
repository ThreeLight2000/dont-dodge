extends SceneTree

const CHALLENGE_DATA_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_challenge_data.gd")
const LOADOUT_DATA_SCRIPT: Script = preload("res://scripts/dont_dodge/dont_dodge_loadout_data.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var localization: Node = get_root().get_node("Localization")
	var catalog_keys: Array[StringName] = localization.call("get_catalog_keys")
	var errors: PackedStringArray = localization.call("validate_catalog", catalog_keys)
	assert(errors.is_empty(), "Localization catalog errors: %s" % ", ".join(errors))
	var keys: Array[StringName] = []
	_collect_keys(LOADOUT_DATA_SCRIPT.WEAPONS, keys)
	_collect_keys(CHALLENGE_DATA_SCRIPT.DEBUFFS, keys)
	for key: StringName in keys:
		assert(bool(localization.call("has_key", key, &"ko")), "Missing Korean key: %s" % key)
		assert(bool(localization.call("has_key", key, &"en")), "Missing English key: %s" % key)
	localization.call("set_locale", &"en", false)
	for key: StringName in catalog_keys:
		assert(not str(localization.call("translate", key)).is_empty())
		assert(str(localization.call("translate", key)) != str(key))
	localization.call("set_locale", &"ko", false)
	print("DON'T DODGE localization validation passed.")
	quit()


func _collect_keys(value: Variant, keys: Array[StringName]) -> void:
	if value is Dictionary:
		for key: Variant in value.keys():
			if str(key).ends_with("_key"):
				var translation_key := StringName(str(value[key]))
				if not keys.has(translation_key):
					keys.append(translation_key)
			_collect_keys(value[key], keys)
	elif value is Array:
		for item: Variant in value:
			_collect_keys(item, keys)
