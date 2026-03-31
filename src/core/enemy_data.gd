extends RefCounted
class_name EnemyData
## Data-driven enemy type definitions.
## All gameplay values for enemy types are defined here.

enum EnemyType { WALKER, MUTANT_DOG, ACID_BUG, IRON_GIANT, EXPLODER, BOSS_ASH_BEHEMOTH }

## Per-type base stats. Wave scaling is applied on top of these in the spawner.
const ENEMY_TYPES: Dictionary = {
	EnemyType.WALKER: {
		"id": "walker",
		"name": "Wasteland Walker",
		"name_cn": "废土行尸",
		"max_hp": 30,
		"move_speed": 80.0,
		"contact_damage": 10,
		"xp_drop": 5,
		"color": Color(0.8, 0.2, 0.2, 1.0),    # Red
		"size": Vector2(20, 20),
		"behavior": "chase",
	},
	EnemyType.MUTANT_DOG: {
		"id": "mutant_dog",
		"name": "Mutant Dog",
		"name_cn": "变异犬",
		"max_hp": 20,
		"move_speed": 160.0,
		"contact_damage": 15,
		"xp_drop": 8,
		"color": Color(0.9, 0.6, 0.1, 1.0),    # Orange
		"size": Vector2(18, 14),
		"behavior": "chase",
	},
	EnemyType.ACID_BUG: {
		"id": "acid_bug",
		"name": "Acid Bug",
		"name_cn": "酸液虫",
		"max_hp": 25,
		"move_speed": 100.0,
		"contact_damage": 8,
		"xp_drop": 10,
		"color": Color(0.3, 0.9, 0.1, 1.0),    # Green
		"size": Vector2(16, 16),
		"behavior": "ranged",
		"attack_range": 250.0,
		"attack_interval": 2.0,
		"projectile_speed": 200.0,
		"projectile_damage": 12,
	},
	EnemyType.IRON_GIANT: {
		"id": "iron_giant",
		"name": "Iron Giant",
		"name_cn": "铁甲巨人",
		"max_hp": 120,
		"move_speed": 45.0,
		"contact_damage": 25,
		"xp_drop": 20,
		"color": Color(0.5, 0.5, 0.6, 1.0),    # Steel grey
		"size": Vector2(32, 32),
		"behavior": "chase",
	},
	EnemyType.EXPLODER: {
		"id": "exploder",
		"name": "Exploder",
		"name_cn": "爆炸虫",
		"max_hp": 15,
		"move_speed": 140.0,
		"contact_damage": 5,
		"xp_drop": 12,
		"color": Color(1.0, 0.3, 0.0, 1.0),    # Bright orange-red
		"size": Vector2(14, 14),
		"behavior": "explode",
		"explode_range": 60.0,
		"explode_damage": 35,
		"explode_fuse": 0.5,
	},
}

const BOSS_DATA: Dictionary = {
	"id": "ash_behemoth",
	"name": "Ash Behemoth",
	"name_cn": "灰烬巨兽",
	"max_hp": BalanceConfig.BOSS_HP,
	"move_speed": BalanceConfig.BOSS_SPEED,
	"contact_damage": BalanceConfig.BOSS_CONTACT_DAMAGE,
	"xp_drop": 200,
	"color": Color(0.4, 0.1, 0.1, 1.0),    # Dark crimson
	"size": Vector2(64, 64),
	"behavior": "boss",
	"slam_damage": BalanceConfig.BOSS_SLAM_DAMAGE,
	"slam_radius": BalanceConfig.BOSS_SLAM_RADIUS,
	"slam_cooldown": BalanceConfig.BOSS_SLAM_COOLDOWN,
	"charge_damage": BalanceConfig.BOSS_CHARGE_DAMAGE,
	"charge_speed": BalanceConfig.BOSS_CHARGE_SPEED,
	"charge_cooldown": BalanceConfig.BOSS_CHARGE_COOLDOWN,
	"summon_count": BalanceConfig.BOSS_SUMMON_COUNT,
	"summon_cooldown": BalanceConfig.BOSS_SUMMON_COOLDOWN,
}

## Wave definitions: which enemy types can appear per wave, with spawn weights.
## Weight determines relative probability of each type spawning.
const WAVE_CONFIG: Array = [
	{  # Wave 1: 0-3 min — Walkers only
		"enemies": [
			{ "type": EnemyType.WALKER, "weight": 1.0 },
		],
		"spawn_interval": BalanceConfig.WAVE_SPAWN_INTERVALS[0],
		"hp_mult": BalanceConfig.WAVE_HP_MULTS[0],
		"speed_mult": BalanceConfig.WAVE_SPEED_MULTS[0],
		"damage_mult": BalanceConfig.WAVE_DAMAGE_MULTS[0],
	},
	{  # Wave 2: 3-6 min — + Mutant Dogs, Acid Bugs
		"enemies": [
			{ "type": EnemyType.WALKER, "weight": 0.5 },
			{ "type": EnemyType.MUTANT_DOG, "weight": 0.3 },
			{ "type": EnemyType.ACID_BUG, "weight": 0.2 },
		],
		"spawn_interval": BalanceConfig.WAVE_SPAWN_INTERVALS[1],
		"hp_mult": BalanceConfig.WAVE_HP_MULTS[1],
		"speed_mult": BalanceConfig.WAVE_SPEED_MULTS[1],
		"damage_mult": BalanceConfig.WAVE_DAMAGE_MULTS[1],
	},
	{  # Wave 3: 6-9 min — + Iron Giants, Exploders
		"enemies": [
			{ "type": EnemyType.WALKER, "weight": 0.3 },
			{ "type": EnemyType.MUTANT_DOG, "weight": 0.2 },
			{ "type": EnemyType.ACID_BUG, "weight": 0.2 },
			{ "type": EnemyType.IRON_GIANT, "weight": 0.15 },
			{ "type": EnemyType.EXPLODER, "weight": 0.15 },
		],
		"spawn_interval": BalanceConfig.WAVE_SPAWN_INTERVALS[2],
		"hp_mult": BalanceConfig.WAVE_HP_MULTS[2],
		"speed_mult": BalanceConfig.WAVE_SPEED_MULTS[2],
		"damage_mult": BalanceConfig.WAVE_DAMAGE_MULTS[2],
	},
	{  # Wave 4: 9-12 min — All types, density doubled
		"enemies": [
			{ "type": EnemyType.WALKER, "weight": 0.25 },
			{ "type": EnemyType.MUTANT_DOG, "weight": 0.2 },
			{ "type": EnemyType.ACID_BUG, "weight": 0.2 },
			{ "type": EnemyType.IRON_GIANT, "weight": 0.2 },
			{ "type": EnemyType.EXPLODER, "weight": 0.15 },
		],
		"spawn_interval": BalanceConfig.WAVE_SPAWN_INTERVALS[3],
		"hp_mult": BalanceConfig.WAVE_HP_MULTS[3],
		"speed_mult": BalanceConfig.WAVE_SPEED_MULTS[3],
		"damage_mult": BalanceConfig.WAVE_DAMAGE_MULTS[3],
	},
	{  # Wave 5 (Final): 12-15 min — Boss + full screen swarm
		"enemies": [
			{ "type": EnemyType.WALKER, "weight": 0.3 },
			{ "type": EnemyType.MUTANT_DOG, "weight": 0.2 },
			{ "type": EnemyType.ACID_BUG, "weight": 0.15 },
			{ "type": EnemyType.IRON_GIANT, "weight": 0.15 },
			{ "type": EnemyType.EXPLODER, "weight": 0.2 },
		],
		"spawn_interval": BalanceConfig.WAVE_SPAWN_INTERVALS[4],
		"hp_mult": BalanceConfig.WAVE_HP_MULTS[4],
		"speed_mult": BalanceConfig.WAVE_SPEED_MULTS[4],
		"damage_mult": BalanceConfig.WAVE_DAMAGE_MULTS[4],
		"spawn_boss": true,
	},
]

## Pick a random enemy type from a wave config based on weights.
static func pick_enemy_type(wave_index: int) -> EnemyType:
	var config: Dictionary = WAVE_CONFIG[clampi(wave_index, 0, WAVE_CONFIG.size() - 1)]
	var entries: Array = config.enemies
	var total_weight: float = 0.0
	for entry in entries:
		total_weight += entry.weight
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for entry in entries:
		cumulative += entry.weight
		if roll <= cumulative:
			return entry.type as EnemyType
	return entries[-1].type as EnemyType

## Get the stat dictionary for an enemy type.
static func get_type_data(enemy_type: EnemyType) -> Dictionary:
	if ENEMY_TYPES.has(enemy_type):
		return ENEMY_TYPES[enemy_type]
	return {}

## Get the wave config for a given wave number (1-indexed).
static func get_wave_config(wave_number: int) -> Dictionary:
	var idx: int = clampi(wave_number - 1, 0, WAVE_CONFIG.size() - 1)
	return WAVE_CONFIG[idx]
