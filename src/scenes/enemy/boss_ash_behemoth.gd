extends CharacterBody2D
## Ash Behemoth: final boss at wave 5.
## Three attack patterns: ground slam (AoE), charge rush, and summon minions.
## Has a boss health bar (tracked via signal).

signal health_changed(current_hp: int, max_hp: int)
signal boss_died

var max_hp: int
var current_hp: int
var move_speed: float
var contact_damage: int
var xp_drop: int

# Attack pattern config (from EnemyData.BOSS_DATA)
var slam_damage: int = 40
var slam_radius: float = 120.0
var slam_cooldown: float = 5.0
var charge_damage: int = 50
var charge_speed: float = 300.0
var charge_cooldown: float = 8.0
var summon_count: int = 4
var summon_cooldown: float = 12.0

# Internal state
var player_ref: Node2D = null
var damage_cooldown: float = 0.0
var _slam_timer: float = 3.0
var _charge_timer: float = 6.0
var _summon_timer: float = 10.0
var _is_charging: bool = false
var _charge_direction: Vector2 = Vector2.ZERO
var _charge_duration: float = 0.0
var _charge_max_duration: float = 0.8

# Status effects (same interface as enemy.gd for skill compatibility)
var speed_mult: float = 1.0
var is_stunned: bool = false
var stun_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 400.0
var dot_effects: Array = []
var _facing_direction: String = "south"

# Walk frame animation
var _walk_frame_timer: float = 0.0
const WALK_FRAME_INTERVAL: float = 0.12
var _walk_sheets: Dictionary = {}
var _walk_hframes: Dictionary = {}
var _is_walk_playing: bool = false

var xp_gem_scene: PackedScene
var enemy_scene: PackedScene

func _ready() -> void:
	# Configure from boss data
	var data: Dictionary = EnemyData.BOSS_DATA
	max_hp = data.max_hp
	current_hp = max_hp
	move_speed = data.move_speed
	contact_damage = data.contact_damage
	xp_drop = data.xp_drop
	slam_damage = data.slam_damage
	slam_radius = data.slam_radius
	slam_cooldown = data.slam_cooldown
	charge_damage = data.charge_damage
	charge_speed = data.charge_speed
	charge_cooldown = data.charge_cooldown
	summon_count = data.summon_count
	summon_cooldown = data.summon_cooldown

	add_to_group("enemies")
	add_to_group("boss")
	xp_gem_scene = preload("res://src/scenes/xp_gem/xp_gem.tscn")
	enemy_scene = preload("res://src/scenes/enemy/enemy.tscn")

	# Build visual
	_build_visual(data)
	_load_walk_sheets()

	health_changed.emit(current_hp, max_hp)

	# Find player
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func _build_visual(data: Dictionary) -> void:
	var esize: Vector2 = data.get("size", Vector2(64, 64))

	# Use pixel art sprite
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex_path: String = "res://assets/sprites/enemies/boss_ash_behemoth.png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	add_child(sprite)

	# Collision shape
	var col_shape := CollisionShape2D.new()
	col_shape.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = esize
	col_shape.shape = shape
	add_child(col_shape)

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

	if not is_instance_valid(player_ref):
		return

	# Handle active charge
	if _is_charging:
		_process_charge(delta)
		return

	# Update attack timers
	_slam_timer -= delta
	_charge_timer -= delta
	_summon_timer -= delta

	# Priority: Summon > Charge > Slam > Chase
	if _summon_timer <= 0.0:
		_summon_minions()
		_summon_timer = summon_cooldown
	elif _charge_timer <= 0.0:
		_start_charge()
		_charge_timer = charge_cooldown
	elif _slam_timer <= 0.0:
		var dist := global_position.distance_to(player_ref.global_position)
		if dist <= slam_radius * 1.5:
			_ground_slam()
			_slam_timer = slam_cooldown
		else:
			# Too far for slam, just reset timer partially
			_slam_timer = 1.0
	else:
		# Chase player
		var dir := (player_ref.global_position - global_position).normalized()
		velocity = dir * move_speed * speed_mult + knockback_velocity
		_update_facing(dir)
		move_and_slide()

	_try_contact_damage()

## Attack pattern 1: Ground Slam — AoE damage around boss.
func _ground_slam() -> void:
	# VFX/SFX: shockwave + explosion + screen shake
	AudioManager.play_sfx_at("boss_slam", global_position)
	VfxManager.spawn_shockwave(global_position, slam_radius)
	VfxManager.spawn_explosion(global_position, slam_radius * 0.5, Color(0.8, 0.1, 0.0))
	var game_world := get_tree().current_scene
	if game_world and game_world.has_method("screen_shake"):
		game_world.screen_shake(BalanceConfig.SHAKE_BOSS_SLAM_INTENSITY, BalanceConfig.SHAKE_BOSS_SLAM_DURATION)

	# Damage player if in range
	if is_instance_valid(player_ref):
		var dist := global_position.distance_to(player_ref.global_position)
		if dist <= slam_radius and player_ref.has_method("take_damage"):
			player_ref.take_damage(slam_damage, self)

## Attack pattern 2: Charge Rush — dash toward player position.
func _start_charge() -> void:
	if not is_instance_valid(player_ref):
		return
	_is_charging = true
	_charge_direction = (player_ref.global_position - global_position).normalized()
	_charge_duration = 0.0
	AudioManager.play_sfx_at("boss_charge", global_position)
	# Visual: turn orange during charge
	modulate = Color(1.0, 0.5, 0.0, 1.0)

func _process_charge(delta: float) -> void:
	velocity = _charge_direction * charge_speed + knockback_velocity
	move_and_slide()
	_charge_duration += delta
	# Trail particles during charge
	VfxManager.spawn_trail(global_position, Color(1.0, 0.4, 0.0))

	# Check if hit player during charge
	if is_instance_valid(player_ref):
		var dist := global_position.distance_to(player_ref.global_position)
		if dist < 40.0 and damage_cooldown <= 0.0:
			if player_ref.has_method("take_damage"):
				player_ref.take_damage(charge_damage, self)
				damage_cooldown = 1.0

	if _charge_duration >= _charge_max_duration:
		_is_charging = false
		modulate = Color.WHITE
		velocity = Vector2.ZERO

## Attack pattern 3: Summon Minions — spawn walkers around the boss.
func _summon_minions() -> void:
	AudioManager.play_sfx_at("boss_summon", global_position)
	VfxManager.spawn_skill_flash(global_position, Color(0.8, 0.0, 0.8))
	for i in range(summon_count):
		var minion := enemy_scene.instantiate()
		var walker_data: Dictionary = EnemyData.get_type_data(EnemyData.EnemyType.WALKER)
		minion.configure(walker_data)
		var angle: float = (TAU / summon_count) * i
		minion.global_position = global_position + Vector2.from_angle(angle) * 80.0
		get_tree().current_scene.add_child(minion)

	# Visual: brief flash
	modulate = Color(0.8, 0.0, 0.8, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func _try_contact_damage() -> void:
	if damage_cooldown > 0.0:
		return
	if not is_instance_valid(player_ref):
		return
	if global_position.distance_to(player_ref.global_position) < 40.0:
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(contact_damage, self)
			damage_cooldown = 1.0

func _update_facing(dir: Vector2) -> void:
	if dir.length() < 0.01:
		return
	var new_dir: String
	if absf(dir.x) > absf(dir.y):
		new_dir = "east" if dir.x > 0.0 else "west"
	else:
		new_dir = "south" if dir.y > 0.0 else "north"
	if new_dir != _facing_direction:
		_facing_direction = new_dir
		_walk_frame_timer = 0.0
	_update_walk_animation()

## Load walking spritesheets for each direction.
func _load_walk_sheets() -> void:
	for d in ["south", "east", "north", "west"]:
		var tex_path := "res://assets/sprites/enemies/walk/boss_ash_behemoth_walk_%s.png" % d
		if ResourceLoader.exists(tex_path):
			var tex: Texture2D = load(tex_path)
			_walk_sheets[d] = tex
			var img_w: int = tex.get_width()
			var img_h: int = tex.get_height()
			_walk_hframes[d] = img_w / img_h if img_h > 0 else 1

## Play walk spritesheet frames or show idle direction.
func _update_walk_animation() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite")
	if not sprite:
		return
	var is_moving := velocity.length() > 5.0
	var dt := get_physics_process_delta_time()
	if is_moving and _walk_sheets.has(_facing_direction):
		var sheet: Texture2D = _walk_sheets[_facing_direction]
		var hf: int = _walk_hframes.get(_facing_direction, 6)
		if sprite.texture != sheet:
			sprite.texture = sheet
			sprite.hframes = hf
			sprite.frame = 0
			_walk_frame_timer = 0.0
			_is_walk_playing = true
		_walk_frame_timer += dt
		if _walk_frame_timer >= WALK_FRAME_INTERVAL:
			_walk_frame_timer -= WALK_FRAME_INTERVAL
			sprite.frame = (sprite.frame + 1) % hf
		sprite.offset.y = 0.0
		sprite.rotation_degrees = 0.0
		sprite.scale = Vector2.ONE
	else:
		if _is_walk_playing:
			_is_walk_playing = false
			var tex_path := "res://assets/sprites/enemies/directions/boss_ash_behemoth_%s.png" % _facing_direction
			if ResourceLoader.exists(tex_path):
				sprite.texture = load(tex_path)
				sprite.hframes = 1
				sprite.frame = 0

func take_damage(amount: int) -> void:
	current_hp -= amount
	modulate = Color(1, 0.3, 0.3, 1)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	health_changed.emit(current_hp, max_hp)
	AudioManager.play_sfx_at("enemy_hit", global_position, -5.0)
	VfxManager.spawn_damage_number(global_position, amount, Color(1, 0.8, 0.2))

	if current_hp <= 0:
		_die()

## Apply a speed multiplier.
func apply_slow(mult: float, duration: float) -> void:
	speed_mult = minf(speed_mult, mult)
	var tween := create_tween()
	tween.tween_callback(_reset_speed).set_delay(duration)

func _reset_speed() -> void:
	speed_mult = 1.0

## Stun the boss (shorter effective stun for boss resistance).
func apply_stun(duration: float) -> void:
	is_stunned = true
	stun_timer = maxf(stun_timer, duration * 0.5)  # Boss has 50% stun resistance
	modulate = Color(0.5, 0.5, 1.0, 1)

func _update_stun(delta: float) -> void:
	if not is_stunned:
		return
	stun_timer -= delta
	if stun_timer <= 0.0:
		is_stunned = false
		stun_timer = 0.0
		modulate = Color.WHITE

func apply_knockback(force: Vector2) -> void:
	knockback_velocity += force * 0.3  # Boss has knockback resistance

func _update_knockback(delta: float) -> void:
	if knockback_velocity.length() > 1.0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	else:
		knockback_velocity = Vector2.ZERO

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
	# Boss death: dramatic VFX/SFX + screen shake
	AudioManager.play_sfx_at("boss_death", global_position)
	VfxManager.spawn_explosion(global_position, 80.0, Color(1.0, 0.3, 0.0))
	VfxManager.spawn_explosion(global_position, 50.0, Color(1.0, 0.6, 0.0))
	VfxManager.spawn_shockwave(global_position, 150.0)
	var game_world := get_tree().current_scene
	if game_world and game_world.has_method("screen_shake"):
		game_world.screen_shake(BalanceConfig.SHAKE_BOSS_SLAM_INTENSITY * 1.5, BalanceConfig.SHAKE_BOSS_SLAM_DURATION * 2.0)
	# Boss drops many XP gems in a spread
	for i in range(10):
		var gem := xp_gem_scene.instantiate()
		gem.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		gem.xp_value = xp_drop / 10
		get_tree().current_scene.add_child(gem)
	boss_died.emit()
	queue_free()
