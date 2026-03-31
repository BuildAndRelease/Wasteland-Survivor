extends CharacterBody2D
## Player character: moves with WASD, auto-attacks nearest enemy, dodge rolls.

signal health_changed(current_hp: int, max_hp: int)
signal died

@export var max_hp: int = 100
@export var move_speed: float = 200.0
@export var attack_range: float = 150.0
@export var attack_interval: float = 1.0
@export var attack_damage: int = 10
@export var xp_pickup_range: float = 50.0
@export var dodge_speed_mult: float = 3.0
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 2.0

var current_hp: int
var attack_timer: float = 0.0
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var is_dodging: bool = false
var dodge_direction: Vector2 = Vector2.ZERO
var skills: Array[String] = []

# Skill modifiers
var xp_range_mult: float = 1.0
var damage_reduction: float = 0.0

var projectile_scene: PackedScene

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
	_collect_xp_gems()
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

func _handle_attack(delta: float) -> void:
	attack_timer -= delta
	if attack_timer > 0:
		return

	var nearest := _find_nearest_enemy()
	if nearest and global_position.distance_to(nearest.global_position) <= attack_range:
		_fire_projectile(nearest.global_position)
		attack_timer = attack_interval

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
	proj.damage = attack_damage
	get_tree().current_scene.add_child(proj)

func _collect_xp_gems() -> void:
	var gems := get_tree().get_nodes_in_group("xp_gems")
	var effective_range: float = xp_pickup_range * xp_range_mult
	for gem in gems:
		if not is_instance_valid(gem):
			continue
		if global_position.distance_to(gem.global_position) <= effective_range:
			GameManager.add_xp(gem.xp_value)
			gem.collect()

func take_damage(amount: int) -> void:
	if is_dodging:
		return
	var actual := int(amount * (1.0 - damage_reduction))
	current_hp -= actual
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		current_hp = 0
		died.emit()
		GameManager.trigger_game_over()

func add_skill(skill_name: String) -> void:
	skills.append(skill_name)
	match skill_name:
		"Scavenger Instinct":
			xp_range_mult += 0.3
		"Scrap Shield":
			damage_reduction = min(damage_reduction + 0.1, 0.5)
		"Rust Bullet":
			attack_interval = max(attack_interval * 0.7, 0.3)
