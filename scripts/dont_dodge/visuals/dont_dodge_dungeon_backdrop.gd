class_name DontDodgeDungeonBackdrop
extends Node2D

const ASSET_CATALOG: Script = preload("res://scripts/dont_dodge/dont_dodge_asset_catalog.gd")

const TILE_DRAW_SIZE: float = 48.0
const BORDER_TILES: int = 1
const FLOOR_DECORATION_INTERVAL: int = 11
const TRAINING_GUIDE_MARGIN: float = 96.0
const TRAINING_TARGET_RADIUS: float = 30.0
const TRAINING_DANGER_SIZE := Vector2(128.0, 72.0)

var _arena_size: Vector2 = DontDodgeTuning.ARENA_SIZE
var _is_training_mode: bool = false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func set_arena_size(arena_size: Vector2) -> void:
	_arena_size = arena_size
	queue_redraw()


func set_training_mode(is_training: bool) -> void:
	_is_training_mode = is_training
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _arena_size), Color("17140f"))
	var columns: int = ceili(_arena_size.x / TILE_DRAW_SIZE)
	var rows: int = ceili(_arena_size.y / TILE_DRAW_SIZE)
	for row: int in rows:
		for column: int in columns:
			var is_border: bool = column < BORDER_TILES or row < BORDER_TILES or column >= columns - BORDER_TILES or row >= rows - BORDER_TILES
			var cell_rect := Rect2(Vector2(column, row) * TILE_DRAW_SIZE, Vector2.ONE * TILE_DRAW_SIZE)
			if is_border:
				draw_texture_rect_region(ASSET_CATALOG.ATLAS, cell_rect, ASSET_CATALOG.tile_region(ASSET_CATALOG.TILE_WALL), Color(0.34, 0.38, 0.35, 0.84))
				continue
			var floor_color: Color = Color("15130f") if (column + row) % 2 else Color("17150f")
			draw_rect(cell_rect, floor_color)
			if (column * 3 + row * 5) % FLOOR_DECORATION_INTERVAL == 0:
				draw_texture_rect_region(ASSET_CATALOG.ATLAS, cell_rect, ASSET_CATALOG.tile_region(ASSET_CATALOG.TILE_FLOOR_DARK), Color(0.22, 0.24, 0.22, 0.16))
	if _is_training_mode:
		_draw_training_guides()


func _draw_training_guides() -> void:
	var center: Vector2 = _arena_size * 0.5
	var guide_color := Color(0.3, 0.78, 0.68, 0.26)
	var danger_color := Color(0.84, 0.24, 0.18, 0.18)
	var danger_border := Color(0.96, 0.42, 0.24, 0.34)
	var horizontal_start: float = TRAINING_GUIDE_MARGIN
	var horizontal_end: float = _arena_size.x - TRAINING_GUIDE_MARGIN
	while horizontal_start < horizontal_end:
		draw_rect(Rect2(horizontal_start, center.y - 1.0, 24.0, 2.0), guide_color)
		horizontal_start += 48.0
	var vertical_start: float = TRAINING_GUIDE_MARGIN
	var vertical_end: float = _arena_size.y - TRAINING_GUIDE_MARGIN
	while vertical_start < vertical_end:
		draw_rect(Rect2(center.x - 1.0, vertical_start, 2.0, 24.0), guide_color)
		vertical_start += 48.0

	_draw_training_target(center + Vector2(-_arena_size.x * 0.22, 0.0), guide_color)
	_draw_training_target(center + Vector2(_arena_size.x * 0.22, 0.0), guide_color)
	_draw_training_target(center + Vector2(0.0, -_arena_size.y * 0.22), guide_color)

	_draw_training_danger_zone(Rect2(Vector2(TRAINING_GUIDE_MARGIN, TRAINING_GUIDE_MARGIN), TRAINING_DANGER_SIZE), danger_color, danger_border)
	_draw_training_danger_zone(Rect2(Vector2(_arena_size.x - TRAINING_GUIDE_MARGIN - TRAINING_DANGER_SIZE.x, TRAINING_GUIDE_MARGIN), TRAINING_DANGER_SIZE), danger_color, danger_border)
	_draw_training_danger_zone(Rect2(Vector2(TRAINING_GUIDE_MARGIN, _arena_size.y - TRAINING_GUIDE_MARGIN - TRAINING_DANGER_SIZE.y), TRAINING_DANGER_SIZE), danger_color, danger_border)
	_draw_training_danger_zone(Rect2(Vector2(_arena_size.x - TRAINING_GUIDE_MARGIN - TRAINING_DANGER_SIZE.x, _arena_size.y - TRAINING_GUIDE_MARGIN - TRAINING_DANGER_SIZE.y), TRAINING_DANGER_SIZE), danger_color, danger_border)


func _draw_training_target(position: Vector2, color: Color) -> void:
	draw_rect(Rect2(position - Vector2.ONE * TRAINING_TARGET_RADIUS, Vector2.ONE * TRAINING_TARGET_RADIUS * 2.0), Color(color, color.a * 0.12))
	draw_rect(Rect2(position - Vector2.ONE * TRAINING_TARGET_RADIUS, Vector2.ONE * TRAINING_TARGET_RADIUS * 2.0), color, false, 2.0)
	draw_rect(Rect2(position - Vector2.ONE * (TRAINING_TARGET_RADIUS * 0.58), Vector2.ONE * TRAINING_TARGET_RADIUS * 1.16), Color(color, color.a * 0.7), false, 2.0)
	draw_rect(Rect2(position - Vector2(2.0, TRAINING_TARGET_RADIUS + 8.0), Vector2(4.0, (TRAINING_TARGET_RADIUS + 8.0) * 2.0)), color)
	draw_rect(Rect2(position - Vector2(TRAINING_TARGET_RADIUS + 8.0, 2.0), Vector2((TRAINING_TARGET_RADIUS + 8.0) * 2.0, 4.0)), color)


func _draw_training_danger_zone(rect: Rect2, fill_color: Color, border_color: Color) -> void:
	draw_rect(rect, fill_color)
	draw_rect(rect, border_color, false, 2.0)
	var stripe_x: float = rect.position.x + 10.0
	while stripe_x < rect.end.x - 8.0:
		draw_rect(Rect2(stripe_x, rect.position.y + 10.0, 9.0, 3.0), border_color)
		draw_rect(Rect2(stripe_x + 5.0, rect.end.y - 13.0, 9.0, 3.0), border_color)
		stripe_x += 24.0
