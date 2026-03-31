class_name SkillData
extends RefCounted
## Static data definitions for all P1 skills.

const SKILLS: Array = [
	{
		"name": "Rust Bullet",
		"description": "Corroded rounds fire faster.\n-30% attack interval",
		"icon_color": Color(1.0, 0.85, 0.2, 1),
	},
	{
		"name": "Scrap Shield",
		"description": "Makeshift armor absorbs hits.\n-10% damage taken",
		"icon_color": Color(0.4, 0.6, 0.9, 1),
	},
	{
		"name": "Scavenger Instinct",
		"description": "Sense nearby loot.\n+30% XP pickup range",
		"icon_color": Color(0.3, 0.9, 0.4, 1),
	},
]


## Returns [count] random skill choices (shuffled order).
static func get_random_choices(count: int) -> Array:
	var pool: Array = SKILLS.duplicate()
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))
