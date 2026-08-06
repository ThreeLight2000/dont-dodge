class_name DontDodgePixelIcon
extends Control

var _icon_id: StringName = &"attack"
var _tint: Color = Color.WHITE


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(icon_id: StringName, tint: Color) -> void:
	_icon_id = icon_id
	_tint = tint
	queue_redraw()


func _draw() -> void:
	var pixel_size: float = maxf(2.0, floorf(minf(size.x, size.y) / 16.0))
	var origin := (size - Vector2.ONE * pixel_size * 16.0) * 0.5
	match _icon_id:
		&"attack", &"damage":
			_draw_blade(origin, pixel_size)
		&"player":
			_draw_player(origin, pixel_size)
		&"dodge":
			_draw_dash(origin, pixel_size)
		&"negate":
			_draw_shield(origin, pixel_size)
		&"ultimate":
			_draw_star(origin, pixel_size)
		&"sweep":
			_draw_sweep(origin, pixel_size)
		&"tempo":
			_draw_bolt(origin, pixel_size)
		_:
			_draw_star(origin, pixel_size)


func _pixel_rect(origin: Vector2, pixel_size: float, grid_position: Vector2i, grid_size: Vector2i, color: Color) -> void:
	draw_rect(Rect2(origin + Vector2(grid_position) * pixel_size, Vector2(grid_size) * pixel_size), color)


func _draw_blade(origin: Vector2, pixel_size: float) -> void:
	var edge := Color(0.12, 0.1, 0.06, 0.96)
	_pixel_rect(origin, pixel_size, Vector2i(6, 1), Vector2i(4, 2), edge)
	_pixel_rect(origin, pixel_size, Vector2i(5, 3), Vector2i(6, 8), edge)
	_pixel_rect(origin, pixel_size, Vector2i(3, 10), Vector2i(10, 3), edge)
	_pixel_rect(origin, pixel_size, Vector2i(6, 12), Vector2i(4, 3), edge)
	_pixel_rect(origin, pixel_size, Vector2i(7, 2), Vector2i(2, 8), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(4, 11), Vector2i(8, 1), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(7, 13), Vector2i(2, 2), Color(0.62, 0.38, 0.16))


func _draw_player(origin: Vector2, pixel_size: float) -> void:
	var edge := Color(0.08, 0.065, 0.04, 0.98)
	var armor := _tint
	var skin := Color(1.0, 0.72, 0.48)
	_pixel_rect(origin, pixel_size, Vector2i(5, 1), Vector2i(6, 2), edge)
	_pixel_rect(origin, pixel_size, Vector2i(4, 3), Vector2i(8, 6), edge)
	_pixel_rect(origin, pixel_size, Vector2i(5, 4), Vector2i(6, 4), skin)
	_pixel_rect(origin, pixel_size, Vector2i(3, 9), Vector2i(10, 5), edge)
	_pixel_rect(origin, pixel_size, Vector2i(4, 9), Vector2i(8, 4), armor)
	_pixel_rect(origin, pixel_size, Vector2i(2, 14), Vector2i(4, 1), edge)
	_pixel_rect(origin, pixel_size, Vector2i(10, 14), Vector2i(4, 1), edge)


func _draw_dash(origin: Vector2, pixel_size: float) -> void:
	var edge := Color(0.12, 0.1, 0.06, 0.96)
	_pixel_rect(origin, pixel_size, Vector2i(1, 7), Vector2i(9, 3), edge)
	_pixel_rect(origin, pixel_size, Vector2i(8, 4), Vector2i(3, 9), edge)
	_pixel_rect(origin, pixel_size, Vector2i(10, 6), Vector2i(4, 5), edge)
	_pixel_rect(origin, pixel_size, Vector2i(2, 8), Vector2i(8, 1), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(9, 5), Vector2i(1, 7), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(11, 7), Vector2i(2, 3), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(0, 4), Vector2i(3, 1), Color(_tint, 0.6))
	_pixel_rect(origin, pixel_size, Vector2i(2, 12), Vector2i(4, 1), Color(_tint, 0.38))


func _draw_shield(origin: Vector2, pixel_size: float) -> void:
	var edge := Color(0.12, 0.1, 0.06, 0.96)
	_pixel_rect(origin, pixel_size, Vector2i(4, 1), Vector2i(8, 2), edge)
	_pixel_rect(origin, pixel_size, Vector2i(2, 3), Vector2i(12, 8), edge)
	_pixel_rect(origin, pixel_size, Vector2i(4, 11), Vector2i(8, 3), edge)
	_pixel_rect(origin, pixel_size, Vector2i(5, 3), Vector2i(6, 8), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(6, 11), Vector2i(4, 1), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(7, 4), Vector2i(2, 6), Color(1.0, 0.96, 0.72))


func _draw_star(origin: Vector2, pixel_size: float) -> void:
	var edge := Color(0.12, 0.1, 0.06, 0.96)
	_pixel_rect(origin, pixel_size, Vector2i(6, 0), Vector2i(4, 16), edge)
	_pixel_rect(origin, pixel_size, Vector2i(0, 6), Vector2i(16, 4), edge)
	_pixel_rect(origin, pixel_size, Vector2i(4, 4), Vector2i(8, 8), edge)
	_pixel_rect(origin, pixel_size, Vector2i(7, 1), Vector2i(2, 14), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(1, 7), Vector2i(14, 2), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(5, 5), Vector2i(6, 6), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(7, 7), Vector2i(2, 2), Color(1.0, 0.96, 0.7))


func _draw_sweep(origin: Vector2, pixel_size: float) -> void:
	var edge := Color(0.12, 0.1, 0.06, 0.96)
	for radius: int in 3:
		var y: int = 4 + radius * 3
		_pixel_rect(origin, pixel_size, Vector2i(3 - radius, y), Vector2i(10 + radius * 2, 2), edge)
		_pixel_rect(origin, pixel_size, Vector2i(4 - radius, y), Vector2i(8 + radius * 2, 1), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(7, 2), Vector2i(2, 12), Color(1.0, 0.96, 0.7))


func _draw_bolt(origin: Vector2, pixel_size: float) -> void:
	var edge := Color(0.12, 0.1, 0.06, 0.96)
	_pixel_rect(origin, pixel_size, Vector2i(8, 1), Vector2i(5, 2), edge)
	_pixel_rect(origin, pixel_size, Vector2i(5, 3), Vector2i(7, 5), edge)
	_pixel_rect(origin, pixel_size, Vector2i(7, 8), Vector2i(4, 2), edge)
	_pixel_rect(origin, pixel_size, Vector2i(4, 10), Vector2i(6, 5), edge)
	_pixel_rect(origin, pixel_size, Vector2i(9, 2), Vector2i(2, 3), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(7, 4), Vector2i(3, 4), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(8, 9), Vector2i(1, 4), _tint)
	_pixel_rect(origin, pixel_size, Vector2i(5, 11), Vector2i(3, 2), _tint)
