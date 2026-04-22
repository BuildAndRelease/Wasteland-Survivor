class_name CampData
extends RefCounted
## Data definitions for the camp/metagame system.
## Permanent upgrades, character stats, and scrap coin formulas.

## Permanent upgrade definitions.
## Each upgrade has 3-5 tiers with increasing cost and effect.
const UPGRADES: Dictionary = {
	"health_boost": {
		"id": "health_boost",
		"name": "Health Boost",
		"name_cn": "生命强化",
		"description": "Permanently increase max HP.",
		"description_cn": "永久提升最大生命值。",
		"icon_color": Color(0.2, 0.8, 0.2, 1),
		"max_level": 5,
		"levels": [
			{"cost": 100, "effect": 0.10, "desc": "+10% Max HP", "desc_cn": "最大生命+10%"},
			{"cost": 150, "effect": 0.20, "desc": "+20% Max HP", "desc_cn": "最大生命+20%"},
			{"cost": 250, "effect": 0.30, "desc": "+30% Max HP", "desc_cn": "最大生命+30%"},
			{"cost": 400, "effect": 0.40, "desc": "+40% Max HP", "desc_cn": "最大生命+40%"},
			{"cost": 500, "effect": 0.50, "desc": "+50% Max HP", "desc_cn": "最大生命+50%"},
		],
	},
	"attack_boost": {
		"id": "attack_boost",
		"name": "Attack Boost",
		"name_cn": "攻击强化",
		"description": "Permanently increase attack damage.",
		"description_cn": "永久提升攻击伤害。",
		"icon_color": Color(0.9, 0.3, 0.2, 1),
		"max_level": 5,
		"levels": [
			{"cost": 100, "effect": 0.10, "desc": "+10% Attack", "desc_cn": "攻击+10%"},
			{"cost": 150, "effect": 0.20, "desc": "+20% Attack", "desc_cn": "攻击+20%"},
			{"cost": 250, "effect": 0.30, "desc": "+30% Attack", "desc_cn": "攻击+30%"},
			{"cost": 400, "effect": 0.40, "desc": "+40% Attack", "desc_cn": "攻击+40%"},
			{"cost": 500, "effect": 0.50, "desc": "+50% Attack", "desc_cn": "攻击+50%"},
		],
	},
	"speed_boost": {
		"id": "speed_boost",
		"name": "Speed Boost",
		"name_cn": "速度强化",
		"description": "Permanently increase move speed.",
		"description_cn": "永久提升移动速度。",
		"icon_color": Color(0.3, 0.6, 1.0, 1),
		"max_level": 3,
		"levels": [
			{"cost": 200, "effect": 0.05, "desc": "+5% Move Speed", "desc_cn": "移速+5%"},
			{"cost": 400, "effect": 0.10, "desc": "+10% Move Speed", "desc_cn": "移速+10%"},
			{"cost": 600, "effect": 0.15, "desc": "+15% Move Speed", "desc_cn": "移速+15%"},
		],
	},
}

## Character definitions with starting stats and traits.
const CHARACTERS: Dictionary = {
	"survivor": {
		"id": "survivor",
		"name": "Survivor",
		"name_cn": "幸存者",
		"description": "Balanced stats. A tough all-rounder.",
		"description_cn": "属性均衡的全能型角色。",
		"cost": 0,
		"color": Color(0.2, 0.7, 0.3, 1),
		"starting_skill": "",
		"stat_mods": {
			"max_hp": 100,
			"move_speed": 200.0,
			"attack_damage": 15,
			"xp_pickup_range": 50.0,
		},
	},
	"scavenger": {
		"id": "scavenger",
		"name": "Scavenger",
		"name_cn": "拾荒者",
		"description": "Starts with Scavenger Instinct. Larger pickup range.",
		"description_cn": "自带拾荒本能，拾取范围更大。",
		"cost": 1000,
		"color": Color(0.3, 0.9, 0.4, 1),
		"starting_skill": "scavenger_instinct",
		"stat_mods": {
			"max_hp": 90,
			"move_speed": 210.0,
			"attack_damage": 13,
			"xp_pickup_range": 80.0,
		},
	},
	"demolisher": {
		"id": "demolisher",
		"name": "Demolisher",
		"name_cn": "爆破者",
		"description": "Starts with Fire Bomb. Stronger AoE damage.",
		"description_cn": "自带燃烧弹，范围伤害更强。",
		"cost": 1500,
		"color": Color(1.0, 0.4, 0.1, 1),
		"starting_skill": "fire_bomb",
		"stat_mods": {
			"max_hp": 110,
			"move_speed": 180.0,
			"attack_damage": 18,
			"xp_pickup_range": 50.0,
		},
	},
	"mutant": {
		"id": "mutant",
		"name": "Mutant",
		"name_cn": "变异体",
		"description": "Starts with Mutant Regen. Low HP, high attack.",
		"description_cn": "自带变异再生，低血量高攻击。",
		"cost": 2000,
		"color": Color(0.9, 0.3, 0.5, 1),
		"starting_skill": "mutant_regen",
		"stat_mods": {
			"max_hp": 70,
			"move_speed": 200.0,
			"attack_damage": 22,
			"xp_pickup_range": 50.0,
		},
	},
}


## Calculate scrap coins earned from a run.
static func calculate_scrap_coins(wave_reached: int, enemies_killed: int, boss_defeated: bool) -> int:
	var coins: int = 0
	coins += wave_reached * BalanceConfig.SCRAP_PER_WAVE
	coins += int(enemies_killed * BalanceConfig.SCRAP_PER_KILL)
	if boss_defeated:
		coins += BalanceConfig.SCRAP_BOSS_BONUS
		coins += BalanceConfig.SCRAP_VICTORY_BONUS
	return coins


## Get character data by id.
static func get_character(character_id: String) -> Dictionary:
	return CHARACTERS.get(character_id, {})


## Get all character ids.
static func get_all_character_ids() -> Array:
	return CHARACTERS.keys()


## Get upgrade data by id.
static func get_upgrade(upgrade_id: String) -> Dictionary:
	return UPGRADES.get(upgrade_id, {})


## Get all upgrade ids.
static func get_all_upgrade_ids() -> Array:
	return UPGRADES.keys()


## Get the cost for the next level of an upgrade (0-indexed current level).
## Returns -1 if already at max level.
static func get_next_upgrade_cost(upgrade_id: String, current_level: int) -> int:
	var upgrade: Dictionary = UPGRADES.get(upgrade_id, {})
	if upgrade.is_empty():
		return -1
	var levels: Array = upgrade.get("levels", [])
	if current_level >= levels.size():
		return -1
	return levels[current_level].get("cost", 0)


## Get the effect value at a given level (1-indexed).
## Returns 0.0 if level is 0 (not purchased) or invalid.
static func get_upgrade_effect(upgrade_id: String, level: int) -> float:
	if level <= 0:
		return 0.0
	var upgrade: Dictionary = UPGRADES.get(upgrade_id, {})
	if upgrade.is_empty():
		return 0.0
	var levels: Array = upgrade.get("levels", [])
	var idx: int = clampi(level - 1, 0, levels.size() - 1)
	return levels[idx].get("effect", 0.0)
