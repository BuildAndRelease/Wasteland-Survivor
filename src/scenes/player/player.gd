extends CharacterBody2D
## Player character: moves with WASD, auto-attacks nearest enemy, dodge rolls.
## Skill effects are managed by SkillManager; player exposes modifier vars.

signal health_changed(current_hp: int, max_hp: int)
signal died

@export var max_hp: int = BalanceConfig.PLAYER_BASE_HP
@export var move_speed: float = BalanceConfig.PLAYER_BASE_SPEED
@export var attack_range: float = BalanceConfig.PLAYER_BASE_ATTACK_RANGE
@export var attack_interval: float = BalanceConfig.PLAYER_BASE_ATTACK_INTERVAL
@export var attack_damage: int = BalanceConfig.PLAYER_BASE_ATTACK
@export var xp_pickup_range: float = BalanceConfig.PLAYER_BASE_XP_RANGE
@export var dodge_speed_mult: float = BalanceConfig.PLAYER_DODGE_SPEED_MULT
@export var dodge_duration: float = BalanceConfig.PLAYER_DODGE_DURATION
@export var dodge_cooldown: float = BalanceConfig.PLAYER_DODGE_COOLDOWN

var current_hp: int
var attack_timer: float = 0.0
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var is_dodging: bool = false
var dodge_direction: Vector2 = Vector2.ZERO

# Skill modifiers (set by SkillManager)
var xp_range_mult: float = 1.0
var damage_reduction: float = 0.0
var reflect_melee: bool = false
var double_shot: bool = false
var regen_percent: float = 0.0
var low_hp_multiplier: float = 1.0
var low_hp_threshold: float = 0.0
var rage_attack_mult: float = 1.0
var rage_timer: float = 0.0
var rage_cc_immune: bool = false

# Berserker Blood combo modifiers (set by SkillManager)
var berserker_attack_bonus: float = 0.0
var berserker_lifesteal: float = 0.0

# Heal accumulator for sub-integer regen
var _heal_accumulator: float = 0.0

var projectile_scene: PackedScene
var skill_manager: SkillManager = null

func _ready() -> void:
	current_hp = max_hp
	add_to_group("player")
	projectile_scene = preload("res://src/scenes/projectile/projectile.tscn")
	health_changed.emit(current_hp, max_hp)

func _physics_process(delta: float) -> void:
	if not GameManager.is_game_active:
		return
	if GameManager.current_state == GameManager.State.LEVEL_UP:
		return

	_handle_dodge(delta)
	_handle_movement(delta)
	_handle_attack(delta)
	_handle_rage(delta)
	_collect_xp_gems()
	_collect_drops()
	move_and_slide()

func _handle_movement(delta: float) -> void:
	if is_dodging:
		velocity = dodge_direction * move_speed * dodge_speed_mult
		return

	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")

	if input_dir.length() > 0:
		input_dir = input_dir.normalized()

	velocity = input_dir * move_speed

func _handle_dodge(delta: float) -> void:
	dodge_cooldown_timer -= delta

	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false
		return

	if Input.is_action_just_pressed("dodge") and dodge_cooldown_timer <= 0:
		var dir := Vector2.ZERO
		dir.x = Input.get_axis("move_left", "move_right")
		dir.y = Input.get_axis("move_up", "move_down")
		if dir.length() > 0:
			dodge_direction = dir.normalized()
		else:
			dodge_direction = Vector2.RIGHT
		is_dodging = true
		dodge_timer = dodge_duration
		dodge_cooldown_timer = dodge_cooldown
		AudioManager.play_sfx("dodge")

func _handle_attack(delta: float) -> void:
	attack_timer -= delta
	if attack_timer > 0:
		return

	var nearest := _find_nearest_enemy()
	if nearest and global_position.distance_to(nearest.global_position) <= attack_range:
		_fire_projectile(nearest.global_position)
		AudioManager.play_sfx_at("player_attack", global_position)
		if double_shot:
			# Fire a second projectile with slight offset
			var offset := (nearest.global_position - global_position).normalized().rotated(0.15) * 10.0
			_fire_projectile(nearest.global_position + offset)
		attack_timer = attack_interval * (1.0 / rage_attack_mult)

func _handle_rage(delta: float) -> void:
	if rage_timer > 0.0:
		rage_timer -= delta
		if rage_timer <= 0.0:
			rage_attack_mult = 1.0
			rage_cc_immune = false

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

func _fire_projectile(target_pos: Vector2) -> void:
	var proj := projectile_scene.instantiate()
	proj.global_position = global_position
	proj.direction = (target_pos - global_position).normalized()
	var bonus_damage: int = int(attack_damage * berserker_attack_bonus)
	proj.damage = attack_damage + bonus_damage
	if berserker_lifesteal > 0.0:
		proj.lifesteal_percent = berserker_lifesteal
		proj.lifesteal_target = self
	get_tree().current_scene.add_child(proj)

func _collect_xp_gems() -> void:
	var gems := get_tree().get_nodes_in_group("xp_gems")
	var effective_range: float = xp_pickup_range * xp_range_mult
	for gem in gems:
		if not is_instance_valid(gem):
			continue
		if global_position.distance_to(gem.global_position) <= effective_range:
			GameManager.add_xp(gem.xp_value)
			AudioManager.play_sfx("xp_pickup", -5.0)
			gem.collect()

func _collect_drops() -> void:
	var drops := get_tree().get_nodes_in_group("drops")
	var effective_range: float = xp_pickup_range * xp_range_mult
	for drop in drops:
		if not is_instance_valid(drop):
			continue
		if global_position.distance_to(drop.global_position) <= effective_range:
			if drop.has_method("pickup"):
				drop.pickup(self)

func take_damage(amount: int, source: Node2D = null) -> void:
	if is_dodging:
		return
	var actual := int(amount * (1.0 - damage_reduction))
	current_hp -= actual
	health_changed.emit(current_hp, max_hp)

	AudioManager.play_sfx("player_hit")
	VfxManager.spawn_damage_number(global_position, actual, Color(1.0, 0.3, 0.3))
	_request_screen_shake(BalanceConfig.SHAKE_PLAYER_HIT_INTENSITY, BalanceConfig.SHAKE_PLAYER_HIT_DURATION)

	# Scrap Shield Lv3: reflect melee damage back to attacker
	if reflect_melee and source and source.has_method("take_damage"):
		source.take_damage(int(actual * 0.5))

	if current_hp <= 0:
		current_hp = 0
		AudioManager.play_sfx("player_death")
		died.emit()
		GameManager.trigger_game_over()

## Heal the player by an amount (supports fractional via accumulator).
func heal(amount: float) -> void:
	if current_hp >= max_hp:
		return
	_heal_accumulator += amount
	if _heal_accumulator >= 1.0:
		var heal_int: int = int(_heal_accumulator)
		_heal_accumulator -= heal_int
		current_hp = mini(current_hp + heal_int, max_hp)
		health_changed.emit(current_hp, max_hp)

## Apply rage buff from Rage Injection skill.
func apply_rage(attack_mult: float, duration: float, cc_immune: bool) -> void:
	rage_attack_mult = attack_mult
	rage_timer = duration
	rage_cc_immune = cc_immune


## Request screen shake from game_world.
func _request_screen_shake(intensity: float, duration: float) -> void:
	var game_world := get_tree().current_scene
	if game_world and game_world.has_method("screen_shake"):
		game_world.screen_shake(intensity, duration)
