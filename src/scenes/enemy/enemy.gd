extends CharacterBody2D
## Enemy: configurable enemy that supports multiple behaviors.
## Behaviors: "chase" (walk toward player), "ranged" (keep distance + shoot),
## "explode" (rush player, explode on contact or proximity).
## Stats are set externally by the spawner from EnemyData.

@export var max_hp: int = 30
@export var move_speed: float = 80.0
@export var contact_damage: int = 10
@export var xp_drop: int = 5

## Enemy type metadata (set by spawner via configure()).
var enemy_type: int = EnemyData.EnemyType.WALKER
var behavior: String = "chase"
var enemy_id: String = "walker"
var facing_direction: String = "south"

# Walk frame animation
var _walk_frame_timer: float = 0.0
const WALK_FRAME_INTERVAL: float = 0.1
var _walk_sheets: Dictionary = {}  # direction -> Texture2D
var _walk_hframes: Dictionary = {}  # direction -> int
var _is_walk_playing: bool = false

## Ranged attack vars (used when behavior == "ranged").
var attack_range: float = 250.0
var attack_interval: float = 2.0
var attack_timer: float = 0.0
var projectile_speed: float = 200.0
var projectile_damage: int = 12

## Explode vars (used when behavior == "explode").
var explode_range: float = 60.0
var explode_damage: int = 35
var explode_fuse: float = 0.5
var _is_exploding: bool = false
var _explode_timer: float = 0.0

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
var _acid_projectile_scene: PackedScene
var _coin_drop_script: GDScript
var _xp_magnet_script: GDScript
var _health_pack_script: GDScript

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	xp_gem_scene = preload("res://src/scenes/xp_gem/xp_gem.tscn")
	_acid_projectile_scene = preload("res://src/scenes/enemy/acid_projectile.tscn")
	_coin_drop_script = preload("res://src/scenes/drops/coin_drop.gd")
	_xp_magnet_script = preload("res://src/scenes/drops/xp_magnet.gd")
	_health_pack_script = preload("res://src/scenes/drops/health_pack.gd")
	# Find player
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

## Configure this enemy from an EnemyData type dictionary.
## Call after instantiation, before adding to scene tree.
func configure(type_data: Dictionary) -> void:
	max_hp = type_data.get("max_hp", 30)
	move_speed = type_data.get("move_speed", 80.0)
	contact_damage = type_data.get("contact_damage", 10)
	xp_drop = type_data.get("xp_drop", 5)
	behavior = type_data.get("behavior", "chase")
	current_hp = max_hp

	# Visual setup
	var sprite: Sprite2D = $Sprite
	var col_shape: CollisionShape2D = $CollisionShape2D
	var esize: Vector2 = type_data.get("size", Vector2(20, 20))

	# Load pixel art texture
	enemy_id = type_data.get("id", "walker")
	var tex_path: String = "res://assets/sprites/enemies/%s.png" % enemy_id
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	var shape := RectangleShape2D.new()
	shape.size = esize
	col_shape.shape = shape

	# Load walk spritesheets
	_load_walk_sheets()

	# Behavior-specific setup
	if behavior == "ranged":
		attack_range = type_data.get("attack_range", 250.0)
		attack_interval = type_data.get("attack_interval", 2.0)
		projectile_speed = type_data.get("projectile_speed", 200.0)
		projectile_damage = type_data.get("projectile_damage", 12)
		attack_timer = attack_interval * randf()  # stagger first shot
	elif behavior == "explode":
		explode_range = type_data.get("explode_range", 60.0)
		explode_damage = type_data.get("explode_damage", 35)
		explode_fuse = type_data.get("explode_fuse", 0.5)

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
		_update_walk_animation()
		return

	if not is_instance_valid(player_ref):
		return

	match behavior:
		"chase":
			_behavior_chase(delta)
		"ranged":
			_behavior_ranged(delta)
		"explode":
			_behavior_explode(delta)

## Standard chase: run straight at the player.
func _behavior_chase(delta: float) -> void:
	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * move_speed * speed_mult + knockback_velocity
	_update_facing(dir)
	move_and_slide()
	_try_contact_damage()

## Ranged: approach to attack range, then strafe and shoot.
func _behavior_ranged(delta: float) -> void:
	var dist := global_position.distance_to(player_ref.global_position)
	var dir := (player_ref.global_position - global_position).normalized()

	# Move closer if too far, retreat if too close
	var preferred_range: float = attack_range * 0.8
	if dist > attack_range:
		velocity = dir * move_speed * speed_mult + knockback_velocity
	elif dist < preferred_range * 0.5:
		velocity = -dir * move_speed * speed_mult * 0.6 + knockback_velocity
	else:
		# Strafe perpendicular
		var strafe := dir.rotated(PI / 2.0)
		velocity = strafe * move_speed * speed_mult * 0.4 + knockback_velocity
	_update_facing(dir)
	move_and_slide()

	# Shoot
	attack_timer -= delta
	if attack_timer <= 0.0 and dist <= attack_range:
		_fire_acid_projectile()
		attack_timer = attack_interval

	_try_contact_damage()

## Explode: rush player, trigger explosion on proximity.
func _behavior_explode(delta: float) -> void:
	if _is_exploding:
		_explode_timer -= delta
		# Pulse visual
		modulate = Color(1.0, 0.5, 0.0, 1.0) if fmod(_explode_timer, 0.15) > 0.075 else Color(1.0, 1.0, 0.0, 1.0)
		velocity = knockback_velocity
		move_and_slide()
		if _explode_timer <= 0.0:
			_explode()
		return

	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * move_speed * speed_mult + knockback_velocity
	_update_facing(dir)
	move_and_slide()

	var dist := global_position.distance_to(player_ref.global_position)
	if dist < explode_range:
		_start_explode()

func _start_explode() -> void:
	_is_exploding = true
	_explode_timer = explode_fuse
	# Stop chasing — stand and pulse
	move_speed = 0.0

func _explode() -> void:
	# Deal AoE damage to player if in range
	if is_instance_valid(player_ref):
		var dist := global_position.distance_to(player_ref.global_position)
		if dist <= explode_range * 1.5 and player_ref.has_method("take_damage"):
			player_ref.take_damage(explode_damage, self)

	# VFX/SFX: explosion + screen shake
	AudioManager.play_sfx_at("exploder_boom", global_position)
	VfxManager.spawn_explosion(global_position, explode_range)
	var game_world := get_tree().current_scene
	if game_world and game_world.has_method("screen_shake"):
		game_world.screen_shake(BalanceConfig.SHAKE_EXPLOSION_INTENSITY, BalanceConfig.SHAKE_EXPLOSION_DURATION)

	# Die without normal XP drop — exploder gives XP through the explosion itself
	GameManager.enemies_killed += 1
	var gem := xp_gem_scene.instantiate()
	gem.global_position = global_position
	gem.xp_value = xp_drop
	get_tree().current_scene.add_child(gem)
	_try_drop_items()
	call_deferred("queue_free")

func _fire_acid_projectile() -> void:
	if not is_instance_valid(player_ref):
		return
	var proj := _acid_projectile_scene.instantiate()
	proj.global_position = global_position
	proj.direction = (player_ref.global_position - global_position).normalized()
	proj.speed = projectile_speed
	proj.damage = projectile_damage
	get_tree().current_scene.add_child(proj)

func _update_facing(dir: Vector2) -> void:
	if dir.length() < 0.01:
		return
	var new_dir: String
	if absf(dir.x) > absf(dir.y):
		new_dir = "east" if dir.x > 0.0 else "west"
	else:
		new_dir = "south" if dir.y > 0.0 else "north"
	if new_dir != facing_direction:
		facing_direction = new_dir
		# Reset walk animation when direction changes
		_walk_frame_timer = 0.0

	# Update walk animation
	_update_walk_animation()

## Load walking spritesheet textures for each direction.
func _load_walk_sheets() -> void:
	for d in ["south", "east", "north", "west"]:
		var tex_path := "res://assets/sprites/enemies/walk/%s_walk_%s.png" % [enemy_id, d]
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
	if is_moving and _walk_sheets.has(facing_direction):
		var sheet: Texture2D = _walk_sheets[facing_direction]
		var hf: int = _walk_hframes.get(facing_direction, 6)
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
			var tex_path := "res://assets/sprites/enemies/directions/%s_%s.png" % [enemy_id, facing_direction]
			if ResourceLoader.exists(tex_path):
				sprite.texture = load(tex_path)
				sprite.hframes = 1
				sprite.frame = 0
		sprite.offset.y = 0.0
		sprite.rotation_degrees = 0.0
		sprite.scale = Vector2.ONE

func _try_contact_damage() -> void:
	if damage_cooldown > 0.0:
		return
	if not is_instance_valid(player_ref):
		return
	if global_position.distance_to(player_ref.global_position) < 20.0:
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(contact_damage, self)
			damage_cooldown = 1.0

var _is_dying := false

func take_damage(amount: int) -> void:
	if _is_dying:
		return
	current_hp -= amount
	# Flash red briefly
	modulate = Color(1, 0.3, 0.3, 1)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

	AudioManager.play_sfx_at("enemy_hit", global_position, -5.0)
	VfxManager.spawn_damage_number(global_position, amount, Color(1, 1, 1))

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
	if _is_dying:
		return
	_is_dying = true
	GameManager.enemies_killed += 1
	# Death VFX/SFX based on enemy type
	var death_color := Color(1, 0.3, 0.2)
	var sfx_name := "enemy_death"
	match enemy_type:
		EnemyData.EnemyType.MUTANT_DOG:
			death_color = Color(0.6, 0.4, 0.2)
			sfx_name = "enemy_death_dog"
		EnemyData.EnemyType.ACID_BUG:
			death_color = Color(0.3, 0.9, 0.1)
			sfx_name = "enemy_death_bug"
		EnemyData.EnemyType.IRON_GIANT:
			death_color = Color(0.5, 0.3, 0.2)
			sfx_name = "enemy_death_giant"
	AudioManager.play_sfx_at(sfx_name, global_position)
	VfxManager.spawn_death_burst(global_position, death_color)
	# Spawn XP gem
	var gem := xp_gem_scene.instantiate()
	gem.global_position = global_position
	gem.xp_value = xp_drop
	get_tree().current_scene.add_child(gem)
	_try_drop_items()
	call_deferred("queue_free")

## Roll random drops and spawn them at enemy position.
func _try_drop_items() -> void:
	var scene_root := get_tree().current_scene
	if not scene_root:
		return
	var pos := global_position
	if randf() < BalanceConfig.COIN_DROP_RATE:
		var drop := Area2D.new()
		drop.set_script(_coin_drop_script)
		drop.global_position = pos
		scene_root.add_child(drop)
	if randf() < BalanceConfig.XP_MAGNET_DROP_RATE:
		var drop := Area2D.new()
		drop.set_script(_xp_magnet_script)
		drop.global_position = pos + Vector2(8, 0)
		scene_root.add_child(drop)
	if randf() < BalanceConfig.HEALTH_PACK_DROP_RATE:
		var drop := Area2D.new()
		drop.set_script(_health_pack_script)
		drop.global_position = pos + Vector2(-8, 0)
		scene_root.add_child(drop)