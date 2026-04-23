class_name Locale
extends RefCounted
## Simple locale system for Chinese/English toggle.

enum Lang { EN, ZH }

## Current language. Default to Chinese.
static var current: Lang = Lang.ZH

## Get localized text by key.
static func t(key: String) -> String:
	if current == Lang.ZH and _ZH.has(key):
		return _ZH[key]
	if _EN.has(key):
		return _EN[key]
	return key

## Toggle between languages.
static func toggle() -> void:
	if current == Lang.EN:
		current = Lang.ZH
	else:
		current = Lang.EN

## Set language directly.
static func set_lang(lang: Lang) -> void:
	current = lang

## Check if current language is Chinese.
static func is_zh() -> bool:
	return current == Lang.ZH

# --- English strings ---
const _EN: Dictionary = {
	# Main Menu
	"title": "WASTELAND SURVIVOR",
	"subtitle": "Survive the wasteland. Collect scrap. Get stronger.",
	"play": "PLAY",
	"asset_preview": "ASSET PREVIEW",
	"language": "中文",

	# Camp
	"scrap_coins": "Scrap Coins: %d",
	"back_to_menu": "MENU",
	"start_game": "START",
	"locked": "[LOCKED: %d coins]",
	"upgrade_btn": "Upgrade (%d)",
	"upgrade_max": "MAX",
	"level_select_title": "— TEST LEVEL SELECT —",
	"level_default": "Level 1 · Wasteland",
	"level_frozen_test": "Level 2 · Frozen Wasteland (Test)",
	"level_hell_test": "Level 3 · Hell Furnace (Test)",

	# HUD
	"wave_format": "Wave %d/5",
	"level_format": "Lv.%d",
	"level_max_format": "Lv.%d MAX",
	"kills_format": "Kills: %d",
	"wave_announce": "— WAVE %d —",
	"final_wave": "FINAL WAVE — BOSS INCOMING!",
	"boss_defeated": "BOSS DEFEATED!",
	"boss_name": "Ash Behemoth",
	"boss_name_frozen": "Blizzard Behemoth",
	"boss_name_hell": "Inferno Titan",

	# Settlement
	"victory": "VICTORY!",
	"game_over": "GAME OVER",
	"survival_time": "Survival Time: %d:%02d",
	"enemies_killed": "Enemies Killed: %d",
	"level_reached": "Level Reached: %d",
	"wave_reached": "Wave Reached: %d / 5",
	"coins_earned": "Scrap Coins Earned: +%d",
	"return_to_camp": "RETURN TO CAMP",

	# Level Up
	"level_up_title": "LEVEL UP!",
	"level_up_choose": "Choose a skill:",
	"combo_label": "%s [COMBO]\n%s",
	"skill_label": "%s (Lv.%d)\n%s",
	"bonus_label": "★ %s\n%s",

	# Bonus picks
	"bonus_heal_name": "Emergency Repair",
	"bonus_heal_desc": "Restore 30% of max HP immediately.",
	"bonus_coins_name": "Scrap Salvage",
	"bonus_coins_desc": "Gain 50 bonus Scrap Coins at end of run.",
	"bonus_max_hp_name": "Reinforced Plating",
	"bonus_max_hp_desc": "Permanently increase max HP by 20 this run.",

	# Characters
	"char_survivor": "Survivor",
	"char_scavenger": "Scavenger",
	"char_demolisher": "Demolisher",
	"char_mutant": "Mutant",
	"char_survivor_desc": "Balanced stats. A tough all-rounder.",
	"char_scavenger_desc": "Starts with Scavenger Instinct. Larger pickup range.",
	"char_demolisher_desc": "Starts with Fire Bomb. Stronger AoE damage.",
	"char_mutant_desc": "Starts with Mutant Regen. Low HP, high attack.",

	# Upgrades
	"upgrade_health": "Health Boost",
	"upgrade_attack": "Attack Boost",
	"upgrade_speed": "Speed Boost",
}

# --- Chinese strings ---
const _ZH: Dictionary = {
	# Main Menu
	"title": "废土幸存者",
	"subtitle": "在废土中求生，收集废铁，变得更强。",
	"play": "开始游戏",
	"asset_preview": "资源预览",
	"language": "EN",

	# Camp
	"scrap_coins": "废铁币: %d",
	"back_to_menu": "返回",
	"start_game": "出发！",
	"locked": "[未解锁: %d 币]",
	"upgrade_btn": "升级 (%d)",
	"upgrade_max": "已满级",
	"level_select_title": "— 测试关卡入口 —",
	"level_default": "第 1 关 · 废土",
	"level_frozen_test": "第 2 关 · 冰封废土（测试）",
	"level_hell_test": "第 3 关 · 地狱熔炉（测试）",

	# HUD
	"wave_format": "第 %d/5 波",
	"level_format": "Lv.%d",
	"level_max_format": "Lv.%d 满级",
	"kills_format": "击杀: %d",
	"wave_announce": "— 第 %d 波 —",
	"final_wave": "最终波 — BOSS来袭！",
	"boss_defeated": "BOSS已击败！",
	"boss_name": "灰烬巨兽",
	"boss_name_frozen": "暴雪巨兽",
	"boss_name_hell": "熔炉泰坦",

	# Settlement
	"victory": "胜利！",
	"game_over": "游戏结束",
	"survival_time": "存活时间: %d:%02d",
	"enemies_killed": "消灭敌人: %d",
	"level_reached": "达到等级: %d",
	"wave_reached": "达到波次: %d / 5",
	"coins_earned": "获得废铁币: +%d",
	"return_to_camp": "返回营地",

	# Level Up
	"level_up_title": "升级!",
	"level_up_choose": "选择一个技能:",
	"combo_label": "%s [组合技]\n%s",
	"skill_label": "%s (Lv.%d)\n%s",
	"bonus_label": "★ %s\n%s",

	# Bonus picks
	"bonus_heal_name": "紧急维修",
	"bonus_heal_desc": "立即恢复30%最大生命值。",
	"bonus_coins_name": "废铁回收",
	"bonus_coins_desc": "本局结算额外获得50废铁币。",
	"bonus_max_hp_name": "强化装甲",
	"bonus_max_hp_desc": "本局永久增加20点最大生命值。",

	# Characters
	"char_survivor": "幸存者",
	"char_scavenger": "拾荒者",
	"char_demolisher": "爆破者",
	"char_mutant": "变异体",
	"char_survivor_desc": "均衡属性，全面发展。",
	"char_scavenger_desc": "自带拾荒本能，拾取范围更大。",
	"char_demolisher_desc": "自带燃烧弹，范围伤害更强。",
	"char_mutant_desc": "自带变异再生，低血高攻。",

	# Upgrades
	"upgrade_health": "生命强化",
	"upgrade_attack": "攻击强化",
	"upgrade_speed": "速度强化",
}
