class_name DontDodgeVisualMapping
extends RefCounted

const FALLBACK_VARIANT: StringName = &"fallback"

var _variants_by_type: Dictionary = {}


func set_variants(variants_by_type: Dictionary) -> void:
	_variants_by_type = variants_by_type.duplicate(true)


func resolve(entity_type_id: StringName, state_id: StringName) -> StringName:
	var variants_by_state: Variant = _variants_by_type.get(entity_type_id, null)
	if not variants_by_state is Dictionary:
		return FALLBACK_VARIANT
	var variant: Variant = variants_by_state.get(state_id, variants_by_state.get(&"default", FALLBACK_VARIANT))
	if variant is StringName:
		return variant
	if variant is String:
		return StringName(variant)
	return FALLBACK_VARIANT
