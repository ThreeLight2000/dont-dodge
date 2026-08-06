class_name DontDodgeProjectileVisual
extends Node2D

const VISUAL_MAPPING_SCRIPT: Script = preload("res://scripts/dont_dodge/visuals/dont_dodge_visual_mapping.gd")

var _direction: Vector2 = Vector2.RIGHT
var _radius: float = 10.0
var _type_id: StringName = &"enemy_projectile"
var _state_id: StringName = &"flying"
var _variant_id: StringName = DontDodgeVisualMapping.FALLBACK_VARIANT
var _mapping: DontDodgeVisualMapping = VISUAL_MAPPING_SCRIPT.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_presentation(type_id: StringName, state_id: StringName, direction: Vector2, radius: float) -> void:
	_type_id = type_id
	_state_id = state_id
	_direction = direction if direction != Vector2.ZERO else Vector2.RIGHT
	_radius = radius
	_variant_id = _mapping.resolve(_type_id, _state_id)
	queue_redraw()


func set_visual_mapping(variants_by_type: Dictionary) -> void:
	_mapping.set_variants(variants_by_type)
	_variant_id = _mapping.resolve(_type_id, _state_id)
	queue_redraw()


func get_visual_variant() -> StringName:
	return _variant_id


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, _direction.angle(), Vector2.ONE)
	var is_reflected: bool = _state_id == &"reflected"
	var body_color: Color = Color(0.28, 0.9, 1.0) if is_reflected else Color(1.0, 0.54, 0.18)
	var tip_color: Color = Color(0.8, 1.0, 1.0) if is_reflected else Color(1.0, 0.86, 0.34)
	draw_rect(Rect2(-13.0, -7.0, 26.0, 14.0), Color(0.07, 0.05, 0.03, 0.9))
	draw_rect(Rect2(-10.0, -4.0, 18.0, 8.0), body_color)
	draw_rect(Rect2(8.0, -9.0, 7.0, 18.0), Color(0.07, 0.05, 0.03, 0.9))
	draw_rect(Rect2(9.0, -6.0, 5.0, 12.0), tip_color)
	draw_rect(Rect2(-20.0, -2.0, 9.0, 4.0), Color(tip_color, 0.72))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
