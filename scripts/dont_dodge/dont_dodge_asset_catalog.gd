class_name DontDodgeAssetCatalog
extends RefCounted

## Kenney Roguelike/RPG Pack uses 16px tiles separated by one transparent pixel.
const ATLAS: Texture2D = preload("res://assets/third_party/kenney/roguelike_rpg/roguelikeSheet_transparent.png")
const TILE_SIZE: int = 16
const TILE_STEP: int = 17

const TILE_FLOOR_DARK: int = 0
const TILE_FLOOR_ALT: int = 1
const TILE_WALL: int = 2
const TILE_TRIM: int = 3
const TILE_TORCH: int = 4

const _COORDINATES: Dictionary = {
	TILE_FLOOR_DARK: Vector2i(10, 12),
	TILE_FLOOR_ALT: Vector2i(11, 12),
	TILE_WALL: Vector2i(27, 12),
	TILE_TRIM: Vector2i(30, 12),
	TILE_TORCH: Vector2i(46, 15),
}

static func tile_region(tile_id: int) -> Rect2:
	var coord: Vector2i = _COORDINATES.get(tile_id, Vector2i.ZERO)
	return Rect2(Vector2(coord * TILE_STEP), Vector2(TILE_SIZE, TILE_SIZE))

static func has_tile(tile_id: int) -> bool:
	return _COORDINATES.has(tile_id)


static func required_tile_ids() -> PackedInt32Array:
	return PackedInt32Array([
		TILE_FLOOR_DARK,
		TILE_FLOOR_ALT,
		TILE_WALL,
		TILE_TRIM,
		TILE_TORCH,
	])


static func make_tile_texture(tile_id: int) -> AtlasTexture:
	var tile := AtlasTexture.new()
	tile.atlas = ATLAS
	tile.region = tile_region(tile_id)
	return tile
