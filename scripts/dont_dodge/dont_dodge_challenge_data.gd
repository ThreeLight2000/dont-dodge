class_name DontDodgeChallengeData
extends RefCounted

const DEBUFFS: Array[Dictionary] = [
	{
		"id": &"slow_defense",
		"title_key": &"challenge.slow_defense.title",
		"description_key": &"challenge.slow_defense.description",
		"icon_id": &"dodge",
		"color": Color(0.3, 0.75, 1.0),
		"defense_recovery_seconds": 7.0,
	},
	{
		"id": &"ultimate_famine",
		"title_key": &"challenge.ultimate_famine.title",
		"description_key": &"challenge.ultimate_famine.description",
		"icon_id": &"ultimate",
		"color": Color(0.92, 0.36, 0.85),
		"ultimate_gain_multiplier": 0.75,
	},
	{
		"id": &"dry_dungeon",
		"title_key": &"challenge.dry_dungeon.title",
		"description_key": &"challenge.dry_dungeon.description",
		"icon_id": &"player",
		"color": Color(1.0, 0.36, 0.3),
		"disable_hearts": true,
	},
	{
		"id": &"bullet_overload",
		"title_key": &"challenge.bullet_overload.title",
		"description_key": &"challenge.bullet_overload.description",
		"icon_id": &"negate",
		"color": Color(0.28, 0.9, 0.9),
		"volley_projectile_bonus": 1,
	},
]


static func get_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for debuff: Dictionary in DEBUFFS:
		pool.append(debuff.duplicate(true))
	return pool


static func get_debuff(debuff_id: StringName) -> Dictionary:
	for debuff: Dictionary in DEBUFFS:
		if debuff["id"] == debuff_id:
			return debuff.duplicate(true)
	return {}
