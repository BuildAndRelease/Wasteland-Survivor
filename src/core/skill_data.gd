class_name SkillData
extends RefCounted
## Data-driven skill definitions for all base and combo skills.
## Reference: design/gdd/game-design-document.md - Section 3: Skill System

enum SkillType { ACTIVE_RANGED, ACTIVE_AOE, ACTIVE_CONTROL, ACTIVE_TRAP, ACTIVE_BUFF, ACTIVE_MELEE, PASSIVE_DEFENSE, PASSIVE_UTILITY, PASSIVE_SURVIVAL, COMBO }

const MAX_SKILL_LEVEL: int = 3

## All 10 base skills with full level progression data.
const BASE_SKILLS: Dictionary = {
	"rust_bullet": {
		"id": "rust_bullet",
		"name": "Rust Bullet",
		"name_cn": "锈弹射击",
		"type": SkillType.ACTIVE_RANGED,
		"description": "Fire corroded rounds at enemies.",
		"description_cn": "向敌人发射锈蚀弹丸。",
		"icon_color": Color(1.0, 0.85, 0.2, 1),
		"cooldown": 1.0,
		"levels": [
			{"desc": "Fire rust bullet every 1s", "desc_cn": "每秒发射锈弹", "attack_interval": 1.0},
			{"desc": "Fire rate +50%", "desc_cn": "射速+50%", "attack_interval": 0.5},
			{"desc": "Double shot", "desc_cn": "双发射击", "attack_interval": 0.5, "double_shot": true},
		],
	},
	"fire_bomb": {
		"id": "fire_bomb",
		"name": "Fire Bomb",
		"name_cn": "燃烧弹",
		"type": SkillType.ACTIVE_AOE,
		"description": "Throw a molotov that creates a burning area.",
		"description_cn": "投掷燃烧瓶，制造燃烧区域。",
		"icon_color": Color(1.0, 0.4, 0.1, 1),
		"cooldown": BalanceConfig.FIRE_BOMB_COOLDOWN,
		"levels": [
			{"desc": "Burns for 3s", "desc_cn": "燃烧3秒", "duration": 3.0, "radius": 60.0, "damage_per_tick": 5, "tick_interval": 0.5},
			{"desc": "Range +50%", "desc_cn": "范围+50%", "duration": 3.0, "radius": 90.0, "damage_per_tick": 5, "tick_interval": 0.5},
			{"desc": "Ground fire 5s", "desc_cn": "地面火焰持续5秒", "duration": 5.0, "radius": 90.0, "damage_per_tick": 5, "tick_interval": 0.5},
		],
	},
	"poison_gas": {
		"id": "poison_gas",
		"name": "Poison Gas",
		"name_cn": "毒雾罐",
		"type": SkillType.ACTIVE_CONTROL,
		"description": "Release poison fog that slows and damages enemies.",
		"description_cn": "释放毒雾，减速并持续伤害敌人。",
		"icon_color": Color(0.4, 0.9, 0.2, 1),
		"cooldown": BalanceConfig.POISON_GAS_COOLDOWN,
		"levels": [
			{"desc": "Slow enemies", "desc_cn": "减速敌人", "duration": 4.0, "radius": 70.0, "slow_amount": 0.5, "damage_per_tick": 3, "tick_interval": 0.5},
			{"desc": "Damage +100%", "desc_cn": "伤害+100%", "duration": 4.0, "radius": 70.0, "slow_amount": 0.5, "damage_per_tick": 6, "tick_interval": 0.5},
			{"desc": "Fog lasts 8s", "desc_cn": "毒雾持续8秒", "duration": 8.0, "radius": 70.0, "slow_amount": 0.5, "damage_per_tick": 6, "tick_interval": 0.5},
		],
	},
	"emp_pulse": {
		"id": "emp_pulse",
		"name": "EMP Pulse",
		"name_cn": "电磁脉冲",
		"type": SkillType.ACTIVE_AOE,
		"description": "Release a ring shock that stuns nearby enemies.",
		"description_cn": "释放环形电击，眩晕附近敌人。",
		"icon_color": Color(0.3, 0.6, 1.0, 1),
		"cooldown": BalanceConfig.EMP_PULSE_COOLDOWN,
		"levels": [
			{"desc": "Stun 1s", "desc_cn": "眩晕1秒", "radius": 100.0, "stun_duration": 1.0, "damage": 15},
			{"desc": "Range +50%", "desc_cn": "范围+50%", "radius": 150.0, "stun_duration": 1.0, "damage": 15},
			{"desc": "Stun 2s", "desc_cn": "眩晕2秒", "radius": 150.0, "stun_duration": 2.0, "damage": 15},
		],
	},
	"scrap_shield": {
		"id": "scrap_shield",
		"name": "Scrap Shield",
		"name_cn": "废铁护盾",
		"type": SkillType.PASSIVE_DEFENSE,
		"description": "Makeshift armor absorbs hits.",
		"description_cn": "临时拼装的护甲，吸收伤害。",
		"icon_color": Color(0.4, 0.6, 0.9, 1),
		"cooldown": 0.0,
		"levels": [
			{"desc": "-10% damage taken", "desc_cn": "受伤减少10%", "damage_reduction": 0.1},
			{"desc": "-20% damage taken", "desc_cn": "受伤减少20%", "damage_reduction": 0.2},
			{"desc": "Reflect melee damage", "desc_cn": "反弹近战伤害", "damage_reduction": 0.2, "reflect_melee": true},
		],
	},
	"scavenger_instinct": {
		"id": "scavenger_instinct",
		"name": "Scavenger Instinct",
		"name_cn": "拾荒本能",
		"type": SkillType.PASSIVE_UTILITY,
		"description": "Sense nearby loot with enhanced pickup range.",
		"description_cn": "增强拾取范围，感知附近掉落物。",
		"icon_color": Color(0.3, 0.9, 0.4, 1),
		"cooldown": 0.0,
		"levels": [
			{"desc": "XP range +30%", "desc_cn": "经验拾取范围+30%", "xp_range_mult": 1.3},
			{"desc": "XP range +50%", "desc_cn": "经验拾取范围+50%", "xp_range_mult": 1.5},
			{"desc": "Auto-collect all screen XP", "desc_cn": "自动拾取全屏经验", "xp_range_mult": 10.0},
		],
	},
	"spike_trap": {
		"id": "spike_trap",
		"name": "Spike Trap",
		"name_cn": "钢刺陷阱",
		"type": SkillType.ACTIVE_TRAP,
		"description": "Place a trap that damages and slows enemies.",
		"description_cn": "放置陷阱，伤害并减速敌人。",
		"icon_color": Color(0.7, 0.7, 0.7, 1),
		"cooldown": BalanceConfig.SPIKE_TRAP_COOLDOWN,
		"levels": [
			{"desc": "Damage + slow", "desc_cn": "造成伤害并减速", "damage": 20, "slow_amount": 0.5, "slow_duration": 2.0, "trap_count": 1, "duration": 6.0},
			{"desc": "Place 2 at once", "desc_cn": "同时放置2个", "damage": 20, "slow_amount": 0.5, "slow_duration": 2.0, "trap_count": 2, "duration": 6.0},
			{"desc": "Traps explode", "desc_cn": "陷阱会爆炸", "damage": 20, "slow_amount": 0.5, "slow_duration": 2.0, "trap_count": 2, "duration": 6.0, "explode": true},
		],
	},
	"mutant_regen": {
		"id": "mutant_regen",
		"name": "Mutant Regen",
		"name_cn": "变异再生",
		"type": SkillType.PASSIVE_SURVIVAL,
		"description": "Regenerate health over time.",
		"description_cn": "随时间恢复生命值。",
		"icon_color": Color(0.9, 0.3, 0.5, 1),
		"cooldown": 0.0,
		"levels": [
			{"desc": "Regen 1% HP/s", "desc_cn": "每秒回复1%生命", "regen_percent": 0.01},
			{"desc": "Regen 2% HP/s", "desc_cn": "每秒回复2%生命", "regen_percent": 0.02},
			{"desc": "Below 30% HP: regen x3", "desc_cn": "低于30%血量时回复×3", "regen_percent": 0.02, "low_hp_multiplier": 3.0, "low_hp_threshold": 0.3},
		],
	},
	"rage_injection": {
		"id": "rage_injection",
		"name": "Rage Injection",
		"name_cn": "狂暴注射",
		"type": SkillType.ACTIVE_BUFF,
		"description": "Boost attack speed temporarily.",
		"description_cn": "临时提升攻击速度。",
		"icon_color": Color(0.9, 0.2, 0.2, 1),
		"cooldown": BalanceConfig.RAGE_INJECTION_COOLDOWN,
		"levels": [
			{"desc": "Attack speed +30% for 5s", "desc_cn": "攻速+30%，持续5秒", "attack_speed_mult": 1.3, "duration": 5.0},
			{"desc": "Attack speed +50% for 5s", "desc_cn": "攻速+50%，持续5秒", "attack_speed_mult": 1.5, "duration": 5.0},
			{"desc": "Immune to CC during", "desc_cn": "期间免疫控制效果", "attack_speed_mult": 1.5, "duration": 5.0, "cc_immune": true},
		],
	},
	"iron_fist": {
		"id": "iron_fist",
		"name": "Iron Fist",
		"name_cn": "铁拳冲击",
		"type": SkillType.ACTIVE_MELEE,
		"description": "Heavy melee cone attack.",
		"description_cn": "扇形重击近战攻击。",
		"icon_color": Color(0.6, 0.4, 0.2, 1),
		"cooldown": BalanceConfig.IRON_FIST_COOLDOWN,
		"levels": [
			{"desc": "Cone heavy hit", "desc_cn": "扇形重击", "damage": 30, "range": 80.0, "cone_angle": 60.0, "knockback": 100.0},
			{"desc": "Knockback +100%", "desc_cn": "击退+100%", "damage": 30, "range": 80.0, "cone_angle": 60.0, "knockback": 200.0},
			{"desc": "Add stun", "desc_cn": "附加眩晕效果", "damage": 30, "range": 80.0, "cone_angle": 60.0, "knockback": 200.0, "stun_duration": 1.0},
		],
	},
}

## 5 combo skills with prerequisite conditions.
const COMBO_SKILLS: Dictionary = {
	"firestorm": {
		"id": "firestorm",
		"name": "Firestorm",
		"name_cn": "烈焰风暴",
		"type": SkillType.COMBO,
		"description": "Poison fog becomes burning fog, range + damage doubled.",
		"description_cn": "毒雾变为燃烧雾，范围和伤害翻倍。",
		"icon_color": Color(1.0, 0.3, 0.0, 1),
		"requirements": {"fire_bomb": 3, "poison_gas": 3},
		"effect": {"range_mult": BalanceConfig.FIRESTORM_RANGE_MULT, "damage_mult": BalanceConfig.FIRESTORM_DAMAGE_MULT},
	},
	"electromagnetic_fortress": {
		"id": "electromagnetic_fortress",
		"name": "Electromagnetic Fortress",
		"name_cn": "电磁铁壁",
		"type": SkillType.COMBO,
		"description": "Shield electrified, knockback + stun enemies on contact.",
		"description_cn": "护盾通电，接触敌人时击退并眩晕。",
		"icon_color": Color(0.2, 0.4, 1.0, 1),
		"requirements": {"emp_pulse": 3, "scrap_shield": 3},
		"effect": {"contact_stun": 0.5, "contact_knockback": 150.0},
	},
	"death_trap_field": {
		"id": "death_trap_field",
		"name": "Death Trap Field",
		"name_cn": "死亡陷阵",
		"type": SkillType.COMBO,
		"description": "Traps auto-fire rust bullets at nearby enemies.",
		"description_cn": "陷阱自动向附近敌人发射锈弹。",
		"icon_color": Color(0.8, 0.5, 0.1, 1),
		"requirements": {"spike_trap": 3, "rust_bullet": 3},
		"effect": {"trap_auto_fire": true, "trap_fire_interval": 0.8},
	},
	"berserker_blood": {
		"id": "berserker_blood",
		"name": "Berserker Blood",
		"name_cn": "狂战之血",
		"type": SkillType.COMBO,
		"description": "Lower HP = higher attack + lifesteal.",
		"description_cn": "血量越低攻击越高，附带吸血效果。",
		"icon_color": Color(0.8, 0.1, 0.1, 1),
		"requirements": {"rage_injection": 3, "mutant_regen": 3},
		"effect": {"max_attack_bonus": BalanceConfig.BERSERKER_MAX_ATTACK_BONUS, "lifesteal_percent": BalanceConfig.BERSERKER_LIFESTEAL_PERCENT},
	},
	"iron_fist_barrage": {
		"id": "iron_fist_barrage",
		"name": "Iron Fist Barrage",
		"name_cn": "铁拳轰炸",
		"type": SkillType.COMBO,
		"description": "Punches cause explosions on hit.",
		"description_cn": "拳击命中时引发爆炸。",
		"icon_color": Color(1.0, 0.5, 0.0, 1),
		"requirements": {"iron_fist": 3, "fire_bomb": 3},
		"effect": {"punch_explode": true, "explosion_radius": 60.0, "explosion_damage": 15},
	},
}


## Returns skill data by id, or null if not found.
static func get_skill(skill_id: String) -> Dictionary:
	if BASE_SKILLS.has(skill_id):
		return BASE_SKILLS[skill_id]
	if COMBO_SKILLS.has(skill_id):
		return COMBO_SKILLS[skill_id]
	return {}


## Returns all base skill ids.
static func get_all_base_skill_ids() -> Array:
	return BASE_SKILLS.keys()


## Returns level data for a skill at a given level (1-indexed).
static func get_level_data(skill_id: String, level: int) -> Dictionary:
	var skill: Dictionary = get_skill(skill_id)
	if skill.is_empty() or not skill.has("levels"):
		return {}
	var idx: int = clampi(level - 1, 0, skill.levels.size() - 1)
	return skill.levels[idx]


## Returns true if the skill is a passive type.
static func is_passive(skill_id: String) -> bool:
	var skill: Dictionary = get_skill(skill_id)
	if skill.is_empty():
		return false
	var t: int = skill.type
	return t == SkillType.PASSIVE_DEFENSE or t == SkillType.PASSIVE_UTILITY or t == SkillType.PASSIVE_SURVIVAL


## Returns true if the skill is an active type (needs auto-trigger + cooldown).
static func is_active(skill_id: String) -> bool:
	var skill: Dictionary = get_skill(skill_id)
	if skill.is_empty():
		return false
	var t: int = skill.type
	return t in [SkillType.ACTIVE_RANGED, SkillType.ACTIVE_AOE, SkillType.ACTIVE_CONTROL,
		SkillType.ACTIVE_TRAP, SkillType.ACTIVE_BUFF, SkillType.ACTIVE_MELEE]


## Check if combo skill requirements are met given current skill levels.
static func check_combo_requirements(combo_id: String, owned_skills: Dictionary) -> bool:
	if not COMBO_SKILLS.has(combo_id):
		return false
	var reqs: Dictionary = COMBO_SKILLS[combo_id].requirements
	for req_id: String in reqs:
		if not owned_skills.has(req_id) or owned_skills[req_id] < reqs[req_id]:
			return false
	return true


## Returns available combo skills based on current skill levels.
static func get_available_combos(owned_skills: Dictionary) -> Array:
	var available: Array = []
	for combo_id: String in COMBO_SKILLS:
		if check_combo_requirements(combo_id, owned_skills):
			available.append(combo_id)
	return available
