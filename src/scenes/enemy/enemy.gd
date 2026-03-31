extends CharacterBody2D
## Basic enemy: walks toward player, deals contact damage, drops XP on death.

@export var max_hp: int = 30
@export var move_speed: float = 80.0
@export var contact_damage: int = 10
@export var xp_drop: int = 5

var current_hp: int
var player_ref: Node2D = null
var damage_cooldown: float = 0.0

var xp_gem_scene: PackedScene

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	xp_gem_scene = preload("res://src/scenes/xp_gem/xp_gem.tscn")
	# Find player
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _physics_process(delta: float) -> void:
	if not GameManager.is_game_active:
		return
	if GameManager.current_state == GameManager.State.LEVEL_UP:
		return

	damage_cooldown -= delta

	if is_instance_valid(player_ref):
		var dir := (player_ref.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()

		# Contact damage
		if damage_cooldown <= 0 and global_position.distance_to(player_ref.global_position) < 20.0:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(contact_damage)
				damage_cooldown = 1.0

func take_damage(amount: int) -> void:
	current_hp -= amount
	# Flash red briefly
	modulate = Color(1, 0.3, 0.3, 1)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

	if current_hp <= 0:
		_die()

func _die() -> void:
	GameManager.enemies_killed += 1
	# Spawn XP gem
	var gem := xp_gem_scene.instantiate()
	gem.global_position = global_position
	gem.xp_value = xp_drop
	get_tree().current_scene.add_child(gem)
	queue_free()
