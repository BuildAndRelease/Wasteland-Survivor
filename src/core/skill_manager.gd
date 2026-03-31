class_name SkillManager
extends Node
## Manages player skills: tracking levels, cooldowns, auto-triggering actives,
## applying passives, and generating level-up choices.
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

## Preloaded skill scenes
var _fire_bomb_scene: PackedScene = null
var _poison_gas_scene: PackedScene = null
var _emp_pulse_scene: PackedScene = null
var _spike_trap_scene: PackedScene = null


func _ready() -> void:
	_fire_bomb_scene = preload("res://src/scenes/skills/fire_bomb.tscn")
	_poison_gas_scene = preload("res://src/scenes/skills/poison_gas.tscn")
	_emp_pulse_scene = preload("res://src/scenes/skills/emp_pulse.tscn")
	_spike_trap_scene = preload("res://src/scenes/skills/spike_trap.tscn")


func _process(delta: float) -> void:
	if not GameManager.is_game_active:
		return
	if GameManager.current_state == GameManager.State.LEVEL_UP:
		return
	_update_cooldowns(delta)
	_update_passive_effects(delta)


## Add or upgrade a skill. Returns the new level.
func add_skill(skill_id: String) -> int:
	var current_level: int = owned_skills.get(skill_id, 0)
	if current_level >= SkillData.MAX_SKILL_LEVEL:
		return current_level

	var new_level: int = current_level + 1
	owned_skills[skill_id] = new_level

	if SkillData.is_passive(skill_id):
		_apply_passive(skill_id, new_level)
		passive_updated.emit(skill_id, new_level)
	elif SkillData.is_active(skill_id):
		# Initialize cooldown if first time acquiring
		if not cooldown_timers.has(skill_id):
			cooldown_timers[skill_id] = 0.0

	# Check for newly available combos
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

	# Check for available combos
	var available_combos: Array = SkillData.get_available_combos(owned_skills)
	for combo_id: String in available_combos:
		if not active_combos.has(combo_id):
			# Combos get priority slot
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
	var remaining: int = count - choices.size()
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
			break  # No more skills available
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
	# Rust bullet is handled by player's attack system via modifiers
	# Update player attack interval from skill data
	if is_instance_valid(player_ref):
		player_ref.attack_interval = level_data.attack_interval
		player_ref.double_shot = level_data.get("double_shot", false)


func _trigger_fire_bomb(level_data: Dictionary) -> void:
	var nearest: Node2D = _find_nearest_enemy()
	if not nearest:
		cooldown_timers["fire_bomb"] = 0.5  # Retry soon
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


func _trigger_iron_fist(level_data: Dictionary) -> void:
	if not is_instance_valid(player_ref):
		return
	# Find enemies in cone in front of player
	var enemies := get_tree().get_nodes_in_group("enemies")
	var player_dir: Vector2 = player_ref.velocity.normalized()
	if player_dir.length() < 0.1:
		player_dir = Vector2.RIGHT
	var half_angle: float = deg_to_rad(level_data.cone_angle / 2.0)

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


## Check if any new combos are unlocked.
func _check_combos() -> void:
	var available: Array = SkillData.get_available_combos(owned_skills)
	for combo_id: String in available:
		if not active_combos.has(combo_id):
			active_combos[combo_id] = true
			combo_unlocked.emit(combo_id)


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
