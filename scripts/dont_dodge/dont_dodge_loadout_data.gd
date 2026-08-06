class_name DontDodgeLoadoutData
extends RefCounted

const WEAPON_IDS: Array[String] = ["dagger", "guardian_mace", "battle_spear"]

const WEAPONS: Dictionary = {
	"dagger": {
		"id": "dagger",
		"title_key": &"data.dagger.title",
		"subtitle_key": &"data.dagger.subtitle",
		"description_key": &"data.dagger.description",
		"detail_key": &"data.dagger.detail",
		"icon_id": "attack",
		"icon_label_key": &"data.dagger.icon_label",
		"color": Color(0.44, 0.86, 1.0),
		"attack_speed_bonus": 0.35,
		"move_speed_bonus": 0.08,
		"range_multiplier": 0.85,
		"range_bonus": 0.0,
		"arc_degrees_bonus": 0.0,
		"knockback_multiplier": 0.8,
		"dodge_cost": 1,
		"defense_max_charges": 3,
		"max_health": 2,
		"negate_enabled": false,
		"attack_target_limit": 1,
		"attack_pierces": false,
		"rule_text_key": &"data.dagger.rule",
		"weakness_text_key": &"data.dagger.weakness",
		"techniques": [
			{
				"id": "tech_dagger_draw",
				"title_key": &"data.tech_dagger_draw.title",
				"description_key": &"data.tech_dagger_draw.description",
				"detail_key": &"data.tech_dagger_draw.detail",
				"icon_id": "dodge",
				"icon_label_key": &"data.tech_dagger_draw.icon_label",
				"color": Color(0.4, 0.84, 1.0),
			},
			{
				"id": "tech_dagger_flurry",
				"title_key": &"data.tech_dagger_flurry.title",
				"description_key": &"data.tech_dagger_flurry.description",
				"detail_key": &"data.tech_dagger_flurry.detail",
				"icon_id": "attack",
				"icon_label_key": &"data.tech_dagger_flurry.icon_label",
				"color": Color(0.4, 0.84, 1.0),
			},
			{
				"id": "tech_dagger_ghost_step",
				"title_key": &"data.tech_dagger_ghost_step.title",
				"description_key": &"data.tech_dagger_ghost_step.description",
				"detail_key": &"data.tech_dagger_ghost_step.detail",
				"icon_id": "dodge",
				"icon_label_key": &"data.tech_dagger_ghost_step.icon_label",
				"color": Color(0.4, 0.84, 1.0),
			},
		],
		"ultimates": [
			{
				"id": "ult_dagger_shadow_frenzy",
				"title_key": &"data.ult_dagger_shadow_frenzy.title",
				"description_key": &"data.ult_dagger_shadow_frenzy.description",
				"detail_key": &"data.ult_dagger_shadow_frenzy.detail",
				"icon_id": "dodge",
				"icon_label_key": &"data.ult_dagger_shadow_frenzy.icon_label",
				"color": Color(0.4, 0.84, 1.0),
			},
			{
				"id": "ult_dagger_assassination_mark",
				"title_key": &"data.ult_dagger_assassination_mark.title",
				"description_key": &"data.ult_dagger_assassination_mark.description",
				"detail_key": &"data.ult_dagger_assassination_mark.detail",
				"icon_id": "damage",
				"icon_label_key": &"data.ult_dagger_assassination_mark.icon_label",
				"color": Color(0.4, 0.84, 1.0),
			},
		],
	},
	"guardian_mace": {
		"id": "guardian_mace",
		"title_key": &"data.guardian_mace.title",
		"subtitle_key": &"data.guardian_mace.subtitle",
		"description_key": &"data.guardian_mace.description",
		"detail_key": &"data.guardian_mace.detail",
		"icon_id": "negate",
		"icon_label_key": &"data.guardian_mace.icon_label",
		"color": Color(0.94, 0.7, 0.32),
		"attack_speed_bonus": -0.08,
		"move_speed_bonus": -0.08,
		"range_multiplier": 1.0,
		"range_bonus": 0.0,
		"arc_degrees_bonus": 8.0,
		"knockback_multiplier": 1.0,
		"dodge_cost": 2,
		"defense_max_charges": 3,
		"max_health": 3,
		"negate_enabled": true,
		"negate_mode": "guard",
		"attack_target_limit": 0,
		"attack_pierces": false,
		"rule_text_key": &"data.guardian_mace.rule",
		"weakness_text_key": &"data.guardian_mace.weakness",
		"techniques": [
			{
				"id": "tech_mace_counter",
				"title_key": &"data.tech_mace_counter.title",
				"description_key": &"data.tech_mace_counter.description",
				"detail_key": &"data.tech_mace_counter.detail",
				"icon_id": "attack",
				"icon_label_key": &"data.tech_mace_counter.icon_label",
				"color": Color(0.94, 0.7, 0.32),
			},
			{
				"id": "tech_mace_reflect_wave",
				"title_key": &"data.tech_mace_reflect_wave.title",
				"description_key": &"data.tech_mace_reflect_wave.description",
				"detail_key": &"data.tech_mace_reflect_wave.detail",
				"icon_id": "negate",
				"icon_label_key": &"data.tech_mace_reflect_wave.icon_label",
				"color": Color(0.94, 0.7, 0.32),
			},
			{
				"id": "tech_mace_suppress",
				"title_key": &"data.tech_mace_suppress.title",
				"description_key": &"data.tech_mace_suppress.description",
				"detail_key": &"data.tech_mace_suppress.detail",
				"icon_id": "attack",
				"icon_label_key": &"data.tech_mace_suppress.icon_label",
				"color": Color(0.94, 0.7, 0.32),
			},
		],
		"ultimates": [
			{
				"id": "ult_mace_ground_suppression",
				"title_key": &"data.ult_mace_ground_suppression.title",
				"description_key": &"data.ult_mace_ground_suppression.description",
				"detail_key": &"data.ult_mace_ground_suppression.detail",
				"icon_id": "attack",
				"icon_label_key": &"data.ult_mace_ground_suppression.icon_label",
				"color": Color(0.94, 0.7, 0.32),
			},
			{
				"id": "ult_mace_frontline_break",
				"title_key": &"data.ult_mace_frontline_break.title",
				"description_key": &"data.ult_mace_frontline_break.description",
				"detail_key": &"data.ult_mace_frontline_break.detail",
				"icon_id": "negate",
				"icon_label_key": &"data.ult_mace_frontline_break.icon_label",
				"color": Color(0.94, 0.7, 0.32),
			},
		],
	},
	"battle_spear": {
		"id": "battle_spear",
		"title_key": &"data.battle_spear.title",
		"subtitle_key": &"data.battle_spear.subtitle",
		"description_key": &"data.battle_spear.description",
		"detail_key": &"data.battle_spear.detail",
		"icon_id": "sweep",
		"icon_label_key": &"data.battle_spear.icon_label",
		"color": Color(0.72, 0.82, 0.94),
		"attack_speed_bonus": 0.0,
		"move_speed_bonus": 0.0,
		"range_multiplier": 1.0,
		"range_bonus": 60.0,
		"arc_degrees_bonus": -48.0,
		"knockback_multiplier": 0.85,
		"dodge_cost": 1,
		"defense_max_charges": 2,
		"max_health": 3,
		"negate_enabled": true,
		"negate_mode": "projectile_only",
		"attack_target_limit": 0,
		"attack_pierces": true,
		"rule_text_key": &"data.battle_spear.rule",
		"weakness_text_key": &"data.battle_spear.weakness",
		"techniques": [
			{
				"id": "tech_spear_breakthrough",
				"title_key": &"data.tech_spear_breakthrough.title",
				"description_key": &"data.tech_spear_breakthrough.description",
				"detail_key": &"data.tech_spear_breakthrough.detail",
				"icon_id": "dodge",
				"icon_label_key": &"data.tech_spear_breakthrough.icon_label",
				"color": Color(0.72, 0.82, 0.94),
			},
			{
				"id": "tech_spear_bullet_cut",
				"title_key": &"data.tech_spear_bullet_cut.title",
				"description_key": &"data.tech_spear_bullet_cut.description",
				"detail_key": &"data.tech_spear_bullet_cut.detail",
				"icon_id": "negate",
				"icon_label_key": &"data.tech_spear_bullet_cut.icon_label",
				"color": Color(0.72, 0.82, 0.94),
			},
			{
				"id": "tech_spear_edge_pressure",
				"title_key": &"data.tech_spear_edge_pressure.title",
				"description_key": &"data.tech_spear_edge_pressure.description",
				"detail_key": &"data.tech_spear_edge_pressure.detail",
				"icon_id": "sweep",
				"icon_label_key": &"data.tech_spear_edge_pressure.icon_label",
				"color": Color(0.72, 0.82, 0.94),
			},
		],
		"ultimates": [
			{
				"id": "ult_spear_sky_pierce",
				"title_key": &"data.ult_spear_sky_pierce.title",
				"description_key": &"data.ult_spear_sky_pierce.description",
				"detail_key": &"data.ult_spear_sky_pierce.detail",
				"icon_id": "sweep",
				"icon_label_key": &"data.ult_spear_sky_pierce.icon_label",
				"color": Color(0.72, 0.82, 0.94),
			},
			{
				"id": "ult_spear_formation",
				"title_key": &"data.ult_spear_formation.title",
				"description_key": &"data.ult_spear_formation.description",
				"detail_key": &"data.ult_spear_formation.detail",
				"icon_id": "sweep",
				"icon_label_key": &"data.ult_spear_formation.icon_label",
				"color": Color(0.72, 0.82, 0.94),
			},
		],
	},
}


static func get_weapon_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for weapon_id: String in WEAPON_IDS:
		var weapon: Dictionary = WEAPONS[weapon_id].duplicate(true)
		weapon["option_id"] = "weapon_%s" % weapon_id
		weapon["stage"] = 1
		options.append(weapon)
	return options


static func get_weapon(weapon_id: String) -> Dictionary:
	return WEAPONS.get(weapon_id, {}).duplicate(true)


static func get_technique_options(weapon_id: String) -> Array[Dictionary]:
	var weapon: Dictionary = WEAPONS.get(weapon_id, {})
	var options: Array[Dictionary] = []
	for technique: Dictionary in weapon.get("techniques", []):
		var option: Dictionary = technique.duplicate(true)
		option["option_id"] = technique["id"]
		option["stage"] = 2
		option["option_kind"] = "technique"
		options.append(option)
	return options


static func get_ultimate_options(weapon_id: String) -> Array[Dictionary]:
	var weapon: Dictionary = WEAPONS.get(weapon_id, {})
	var options: Array[Dictionary] = []
	for ultimate: Dictionary in weapon.get("ultimates", []):
		var option: Dictionary = ultimate.duplicate(true)
		option["option_id"] = ultimate["id"]
		option["stage"] = 3
		option["option_kind"] = "ultimate"
		options.append(option)
	return options


static func get_option(option_id: String) -> Dictionary:
	for weapon_id: String in WEAPON_IDS:
		var weapon: Dictionary = WEAPONS[weapon_id]
		if option_id == "weapon_%s" % weapon_id:
			return weapon.duplicate(true)
		for technique: Dictionary in weapon.get("techniques", []):
			if str(technique.get("id", "")) == option_id:
				return technique.duplicate(true)
		for ultimate: Dictionary in weapon.get("ultimates", []):
			if str(ultimate.get("id", "")) == option_id:
				return ultimate.duplicate(true)
	return {}
