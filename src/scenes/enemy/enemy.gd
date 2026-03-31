extends CharacterBody2D
## Enemy: walks toward player, deals contact damage, drops XP on death.
## Supports speed modifiers (slow), stun, DoT, and knockback from skills.

@export var max_hp: int = 30
@export var move_speed: float = 80.0
@export var contact_damage: int = 10
@export var xp_drop: int = 5

var current_hp: int
var player_ref: Node2D = null
var damage_cooldown: float = 0.0

# Status effects
var speed_mult: float = 1.0
var is_stunned: bool = false
var stun_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 800.0

# DoT tracking: array of { damage_per_tick, tick_interval, remaining_time, tick_timer }
var dot_effects: Array = []

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
	_update_stun(delta)
	_update_dot(delta)
	_update_knockback(delta)

	if is_stunned:
		velocity = knockback_velocity
		move_and_slide()
		return

	if is_instance_valid(player_ref):
		var dir := (player_ref.global_position - global_position).normalized()
		velocity = dir * move_speed * speed_mult + knockback_velocity
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

## Apply a speed multiplier (lower = slower). Stacks by using the minimum.
func apply_slow(mult: float, duration: float) -> void:
	speed_mult = minf(speed_mult, mult)
	var tween := create_tween()
	tween.tween_callback(_reset_speed).set_delay(duration)

func _reset_speed() -> void:
	speed_mult = 1.0

## Stun the enemy for a duration. Longer stun overwrites shorter.
func apply_stun(duration: float) -> void:
	is_stunned = true
	stun_timer = maxf(stun_timer, duration)
	modulate = Color(0.5, 0.5, 1.0, 1)

func _update_stun(delta: float) -> void:
	if not is_stunned:
		return
	stun_timer -= delta
	if stun_timer <= 0.0:
		is_stunned = false
		stun_timer = 0.0
		modulate = Color.WHITE

## Apply knockback force.
func apply_knockback(force: Vector2) -> void:
	knockback_velocity += force

func _update_knockback(delta: float) -> void:
	if knockback_velocity.length() > 1.0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	else:
		knockback_velocity = Vector2.ZERO

## Add a damage-over-time effect.
func apply_dot(damage_per_tick: int, tick_interval: float, total_duration: float) -> void:
	dot_effects.append({
		"damage_per_tick": damage_per_tick,
		"tick_interval": tick_interval,
		"remaining_time": total_duration,
		"tick_timer": tick_interval,
	})

func _update_dot(delta: float) -> void:
	var i: int = dot_effects.size() - 1
	while i >= 0:
		var dot: Dictionary = dot_effects[i]
		dot.remaining_time -= delta
		dot.tick_timer -= delta
		if dot.tick_timer <= 0.0:
			take_damage(dot.damage_per_tick)
			dot.tick_timer += dot.tick_interval
		if dot.remaining_time <= 0.0:
			dot_effects.remove_at(i)
		i -= 1

func _die() -> void:
	GameManager.enemies_killed += 1
	# Spawn XP gem
	var gem := xp_gem_scene.instantiate()
	gem.global_position = global_position
	gem.xp_value = xp_drop
	get_tree().current_scene.add_child(gem)
	queue_free()
