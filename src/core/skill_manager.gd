class_name SkillManager
extends Node
## Manages player skills: tracking levels, cooldowns, auto-triggering actives,
## applying passives, spawning combo effects, and generating level-up choices.
## Reference: design/gdd/game-design-document.md - Section 3: Skill System

signal skill_activated(skill_id: String)
signal passive_updated(skill_id: String, level: int)
signal combo_unlocked(combo_id: String)

## Current skill levels: { skill_id: int }
var owned_skills: Dictionary = {}
## Active combo skills: { combo_id: true }
var active_combos: Dictionary = {}
## Cooldown timers for active skills: { skill_id: float }
var cooldown_timers: Dictionary = {}
## Skill scene cache to avoid repeated loading
var _scene_cache: Dictionary = {}

## Reference to the player node (set by player.gd)
var player_ref: CharacterBody2D = null

## Preloaded skill scenes — base skills
var _fire_bomb_scene: PackedScene = null
var _poison_gas_scene: PackedScene = null
var _emp_pulse_scene: PackedScene = null
var _spike_trap_scene: PackedScene = null
var _rage_injection_scene: PackedScene = null
var _iron_fist_scene: PackedScene = null

## Preloaded skill scenes — combo skills
var _firestorm_scene: PackedScene = null
var _electromagnetic_fortress_scene: PackedScene = null
var _death_trap_field_scene: PackedScene = null
var _iron_fist_barrage_explosion_scene: PackedScene = null

## Combo state tracking
var _fortress_instance: Node2D = null


func _ready() -> void:
	_fire_bomb_scene = preload("res://src/scenes/skills/fire_bomb.tscn")
	_poison_gas_scene = preload("res://src/scenes/skills/poison_gas.tscn")
	_emp_pulse_scene = preload("res://src/scenes/skills/emp_pulse.tscn")
	_spike_trap_scene = preload("res://src/scenes/skills/spike_trap.tscn")
	_rage_injection_scene = preload("res://src/scenes/skills/rage_injection.tscn")
	_iron_fist_scene = preload("res://src/scenes/skills/iron_fist.tscn")
	_firestorm_scene = preload("res://src/scenes/skills/firestorm.tscn")
	_electromagnetic_fortress_scene = preload("res://src/scenes/skills/electromagnetic_fortress.tscn")
	_death_trap_field_scene = preload("res://src/scenes/skills/death_trap_field.tscn")
	_iron_fist_barrage_explosion_scene = preload("res://src/scenes/skills/iron_fist_barrage_explosion.tscn")


func _process(delta: float) -> void:
	if not GameManager.is_game_active:
		return
	if GameManager.current_state == GameManager.State.LEVEL_UP:
		return
	_update_cooldowns(delta)
	_update_passive_effects(delta)
	_update_combo_effects(delta)


## Add or upgrade a skill. Returns the new level.
func add_skill(skill_id: String) -> int:
	# Handle combo skills — they are one-shot activations, not leveled
	if SkillData.COMBO_SKILLS.has(skill_id):
		if not active_combos.has(skill_id):
			active_combos[skill_id] = true
			_activate_combo(skill_id)
			combo_unlocked.emit(skill_id)
		return 1

	var current_level: int = owned_skills.get(skill_id, 0)
	if current_level >= SkillData.MAX_SKILL_LEVEL:
		return current_level

	var new_level: int = current_level + 1
	owned_skills[skill_id] = new_level

	if SkillData.is_passive(skill_id):
		_apply_passive(skill_id, new_level)
		passive_updated.emit(skill_id, new_level)
	elif SkillData.is_active(skill_id):
		if not cooldown_timers.has(skill_id):
			cooldown_timers[skill_id] = 0.0

	# Check for newly available combos (they'll appear in level-up choices)
	_check_combos()
	return new_level


## Get current level of a skill (0 if not owned).
func get_skill_level(skill_id: String) -> int:
	return owned_skills.get(skill_id, 0)


## Generate level-up choices: mix of existing skill upgrades and new skills.
func generate_level_up_choices(count: int) -> Array:
	var choices: Array = []

	# Gather upgradeable skills (owned but not maxed)
	var upgradeable: Array = []
	for skill_id: String in owned_skills:
		if owned_skills[skill_id] < SkillData.MAX_SKILL_LEVEL:
			upgradeable.append(skill_id)

	# Gather new skills (not yet owned)
	var new_skills: Array = []
	for skill_id: String in SkillData.get_all_base_skill_ids():
		if not owned_skills.has(skill_id):
			new_skills.append(skill_id)

	# Check for available combos — these get priority slots
	var available_combos: Array = SkillData.get_available_combos(owned_skills)
	for combo_id: String in available_combos:
		if not active_combos.has(combo_id):
			var combo_data: Dictionary = SkillData.get_skill(combo_id)
			choices.append({
				"skill_id": combo_id,
				"is_combo": true,
				"level": 1,
				"data": combo_data,
			})

	# Shuffle pools
	upgradeable.shuffle()
	new_skills.shuffle()

	# Fill remaining slots: alternate between upgrades and new
	var upgrade_idx: int = 0
	var new_idx: int = 0
	var pick_upgrade: bool = true

	while choices.size() < count:
		if pick_upgrade and upgrade_idx < upgradeable.size():
			var sid: String = upgradeable[upgrade_idx]
			var next_lv: int = owned_skills[sid] + 1
			var skill_data: Dictionary = SkillData.get_skill(sid)
			choices.append({
				"skill_id": sid,
				"is_combo": false,
				"level": next_lv,
				"data": skill_data,
			})
			upgrade_idx += 1
		elif new_idx < new_skills.size():
			var sid: String = new_skills[new_idx]
			var skill_data: Dictionary = SkillData.get_skill(sid)
			choices.append({
				"skill_id": sid,
				"is_combo": false,
				"level": 1,
				"data": skill_data,
			})
			new_idx += 1
		elif upgrade_idx < upgradeable.size():
			var sid: String = upgradeable[upgrade_idx]
			var next_lv: int = owned_skills[sid] + 1
			var skill_data: Dictionary = SkillData.get_skill(sid)
			choices.append({
				"skill_id": sid,
				"is_combo": false,
				"level": next_lv,
				"data": skill_data,
			})
			upgrade_idx += 1
		else:
			break
		pick_upgrade = not pick_upgrade

	return choices.slice(0, mini(count, choices.size()))


## Update cooldowns and auto-trigger active skills.
func _update_cooldowns(delta: float) -> void:
	for skill_id: String in cooldown_timers:
		cooldown_timers[skill_id] -= delta
		if cooldown_timers[skill_id] <= 0.0:
			_trigger_active_skill(skill_id)
			var skill_data: Dictionary = SkillData.get_skill(skill_id)
			cooldown_timers[skill_id] = skill_data.cooldown


## Trigger an active skill effect.
func _trigger_active_skill(skill_id: String) -> void:
	if not is_instance_valid(player_ref):
		return

	var level: int = owned_skills.get(skill_id, 0)
	if level <= 0:
		return

	var level_data: Dictionary = SkillData.get_level_data(skill_id, level)

	match skill_id:
		"rust_bullet":
			_trigger_rust_bullet(level_data)
		"fire_bomb":
			_trigger_fire_bomb(level_data)
		"poison_gas":
			_trigger_poison_gas(level_data)
		"emp_pulse":
			_trigger_emp_pulse(level_data)
		"spike_trap":
			_trigger_spike_trap(level_data)
		"rage_injection":
			_trigger_rage_injection(level_data)
		"iron_fist":
			_trigger_iron_fist(level_data)

	skill_activated.emit(skill_id)


func _trigger_rust_bullet(level_data: Dictionary) -> void:
	if is_instance_valid(player_ref):
		player_ref.attack_interval = level_data.attack_interval
		player_ref.double_shot = level_data.get("double_shot", false)


func _trigger_fire_bomb(level_data: Dictionary) -> void:
	var nearest: Node2D = _find_nearest_enemy()
	if not nearest:
		cooldown_timers["fire_bomb"] = 0.5
		return

	# Firestorm combo: burning fog replaces normal fire bomb
	if active_combos.has("firestorm"):
		_spawn_firestorm(nearest)
		return

	var bomb: Node2D = _fire_bomb_scene.instantiate()
	bomb.global_position = player_ref.global_position
	bomb.target_position = nearest.global_position
	bomb.duration = level_data.duration
	bomb.radius = level_data.radius
	bomb.damage_per_tick = level_data.damage_per_tick
	bomb.tick_interval = level_data.tick_interval
	get_tree().current_scene.add_child(bomb)


func _trigger_poison_gas(level_data: Dictionary) -> void:
	var nearest: Node2D = _find_nearest_enemy()
	if not nearest:
		cooldown_timers["poison_gas"] = 0.5
		return

	# Firestorm combo: burning fog replaces normal poison gas
	if active_combos.has("firestorm"):
		_spawn_firestorm(nearest)
		return

	var gas: Node2D = _poison_gas_scene.instantiate()
	gas.global_position = nearest.global_position
	gas.duration = level_data.duration
	gas.radius = level_data.radius
	gas.slow_amount = level_data.slow_amount
	gas.damage_per_tick = level_data.damage_per_tick
	gas.tick_interval = level_data.tick_interval
	get_tree().current_scene.add_child(gas)


func _trigger_emp_pulse(level_data: Dictionary) -> void:
	var pulse: Node2D = _emp_pulse_scene.instantiate()
	pulse.global_position = player_ref.global_position
	pulse.radius = level_data.radius
	pulse.stun_duration = level_data.stun_duration
	pulse.damage = level_data.damage
	get_tree().current_scene.add_child(pulse)


func _trigger_spike_trap(level_data: Dictionary) -> void:
	var count: int = level_data.trap_count

	# Death Trap Field combo: auto-firing traps replace normal traps
	if active_combos.has("death_trap_field"):
		_spawn_death_trap(level_data)
		return

	for i: int in count:
		var trap: Node2D = _spike_trap_scene.instantiate()
		var offset := Vector2(randf_range(-40, 40), randf_range(-40, 40)) if i > 0 else Vector2.ZERO
		trap.global_position = player_ref.global_position + offset
		trap.damage = level_data.damage
		trap.slow_amount = level_data.slow_amount
		trap.slow_duration = level_data.slow_duration
		trap.duration = level_data.duration
		trap.should_explode = level_data.get("explode", false)
		get_tree().current_scene.add_child(trap)


func _trigger_rage_injection(level_data: Dictionary) -> void:
	if is_instance_valid(player_ref):
		player_ref.apply_rage(level_data.attack_speed_mult, level_data.duration, level_data.get("cc_immune", false))
		# Spawn visual effect on player
		var vfx: Node2D = _rage_injection_scene.instantiate()
		vfx.duration = level_data.duration
		player_ref.add_child(vfx)


func _trigger_iron_fist(level_data: Dictionary) -> void:
	if not is_instance_valid(player_ref):
		return

	var player_dir: Vector2 = player_ref.velocity.normalized()
	if player_dir.length() < 0.1:
		player_dir = Vector2.RIGHT
	var half_angle: float = deg_to_rad(level_data.cone_angle / 2.0)

	# Spawn visual effect
	var vfx: Node2D = _iron_fist_scene.instantiate()
	vfx.global_position = player_ref.global_position
	vfx.direction = player_dir
	vfx.attack_range = level_data.range
	vfx.cone_angle = level_data.cone_angle
	get_tree().current_scene.add_child(vfx)

	# Find enemies in cone in front of player
	var enemies := get_tree().get_nodes_in_group("enemies")
	var has_barrage: bool = active_combos.has("iron_fist_barrage")

	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector2 = enemy.global_position - player_ref.global_position
		var dist: float = to_enemy.length()
		if dist > level_data.range:
			continue
		var angle: float = player_dir.angle_to(to_enemy.normalized())
		if absf(angle) > half_angle:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(level_data.damage)
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(to_enemy.normalized() * level_data.knockback)
		if level_data.has("stun_duration") and enemy.has_method("apply_stun"):
			enemy.apply_stun(level_data.stun_duration)

		# Iron Fist Barrage combo: spawn explosion on each hit
		if has_barrage:
			var combo_effect: Dictionary = SkillData.COMBO_SKILLS["iron_fist_barrage"].effect
			var explosion: Node2D = _iron_fist_barrage_explosion_scene.instantiate()
			explosion.global_position = enemy.global_position
			explosion.explosion_radius = combo_effect.explosion_radius
			explosion.explosion_damage = combo_effect.explosion_damage
			get_tree().current_scene.add_child(explosion)


## Apply passive skill effects to player.
func _apply_passive(skill_id: String, level: int) -> void:
	if not is_instance_valid(player_ref):
		return
	var level_data: Dictionary = SkillData.get_level_data(skill_id, level)

	match skill_id:
		"scrap_shield":
			player_ref.damage_reduction = level_data.damage_reduction
			player_ref.reflect_melee = level_data.get("reflect_melee", false)
		"scavenger_instinct":
			player_ref.xp_range_mult = level_data.xp_range_mult
		"mutant_regen":
			player_ref.regen_percent = level_data.regen_percent
			player_ref.low_hp_multiplier = level_data.get("low_hp_multiplier", 1.0)
			player_ref.low_hp_threshold = level_data.get("low_hp_threshold", 0.0)


## Update passive effects that tick over time (regen).
func _update_passive_effects(delta: float) -> void:
	if not is_instance_valid(player_ref):
		return

	# Mutant Regen
	if owned_skills.has("mutant_regen"):
		var regen: float = player_ref.regen_percent
		var hp_ratio: float = float(player_ref.current_hp) / float(player_ref.max_hp)
		if player_ref.low_hp_threshold > 0.0 and hp_ratio < player_ref.low_hp_threshold:
			regen *= player_ref.low_hp_multiplier
		var heal_amount: float = player_ref.max_hp * regen * delta
		player_ref.heal(heal_amount)


## Update combo-specific effects each frame.
func _update_combo_effects(_delta: float) -> void:
	if not is_instance_valid(player_ref):
		return

	# Electromagnetic Fortress: keep shield following player
	if active_combos.has("electromagnetic_fortress"):
		if is_instance_valid(_fortress_instance):
			_fortress_instance.global_position = player_ref.global_position

	# Berserker Blood: scale attack bonus with missing HP
	if active_combos.has("berserker_blood"):
		var combo_effect: Dictionary = SkillData.COMBO_SKILLS["berserker_blood"].effect
		var hp_ratio: float = float(player_ref.current_hp) / float(player_ref.max_hp)
		var missing_hp_ratio: float = 1.0 - hp_ratio
		player_ref.berserker_attack_bonus = missing_hp_ratio * combo_effect.max_attack_bonus
		player_ref.berserker_lifesteal = combo_effect.lifesteal_percent


## Activate a combo skill's persistent effect.
func _activate_combo(combo_id: String) -> void:
	match combo_id:
		"firestorm":
			pass  # Modifies fire_bomb and poison_gas triggers
		"electromagnetic_fortress":
			_spawn_fortress()
		"death_trap_field":
			pass  # Modifies spike_trap trigger
		"berserker_blood":
			pass  # Updated each frame in _update_combo_effects
		"iron_fist_barrage":
			pass  # Modifies iron_fist trigger


## Spawn the electromagnetic fortress shield around player.
func _spawn_fortress() -> void:
	if not is_instance_valid(player_ref):
		return
	var combo_effect: Dictionary = SkillData.COMBO_SKILLS["electromagnetic_fortress"].effect
	var fortress: Node2D = _electromagnetic_fortress_scene.instantiate()
	fortress.global_position = player_ref.global_position
	fortress.stun_duration = combo_effect.contact_stun
	fortress.knockback_force = combo_effect.contact_knockback
	fortress.duration = 999.0  # Permanent until game ends
	get_tree().current_scene.add_child(fortress)
	_fortress_instance = fortress


## Spawn a firestorm (combo: fire bomb + poison gas).
func _spawn_firestorm(target: Node2D) -> void:
	var combo_effect: Dictionary = SkillData.COMBO_SKILLS["firestorm"].effect
	var storm: Node2D = _firestorm_scene.instantiate()
	storm.global_position = target.global_position
	# Base poison gas Lv3: radius 70, damage 6 — doubled by combo multipliers
	storm.radius = 70.0 * combo_effect.range_mult
	storm.damage_per_tick = int(6 * combo_effect.damage_mult)
	storm.duration = 8.0
	storm.slow_amount = 0.5
	get_tree().current_scene.add_child(storm)


## Spawn death trap field (combo: spike trap + rust bullet).
func _spawn_death_trap(level_data: Dictionary) -> void:
	var combo_effect: Dictionary = SkillData.COMBO_SKILLS["death_trap_field"].effect
	var count: int = level_data.trap_count
	for i: int in count:
		var trap: Node2D = _death_trap_field_scene.instantiate()
		var offset := Vector2(randf_range(-40, 40), randf_range(-40, 40)) if i > 0 else Vector2.ZERO
		trap.global_position = player_ref.global_position + offset
		trap.damage = level_data.damage
		trap.slow_amount = level_data.slow_amount
		trap.slow_duration = level_data.slow_duration
		trap.duration = 10.0
		trap.fire_interval = combo_effect.trap_fire_interval
		trap.bullet_damage = player_ref.attack_damage
		get_tree().current_scene.add_child(trap)


## Check if any new combos are unlocked (they appear in level-up choices).
func _check_combos() -> void:
	# Combos are offered through the level-up panel, not auto-activated.
	pass


## Find nearest enemy to player.
func _find_nearest_enemy() -> Node2D:
	if not is_instance_valid(player_ref):
		return null
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for enemy: Node2D in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = player_ref.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest


## Reset all skills (for new game).
func reset() -> void:
	owned_skills.clear()
	active_combos.clear()
	cooldown_timers.clear()
	_fortress_instance = null
	if is_instance_valid(player_ref):
		player_ref.berserker_attack_bonus = 0.0
		player_ref.berserker_lifesteal = 0.0
