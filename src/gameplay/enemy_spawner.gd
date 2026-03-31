extends Node2D
## Spawns enemies from screen edges with wave-based progression.
## Uses EnemyData for enemy type selection and stat scaling per wave.
## Spawns boss on the final wave.

signal wave_started(wave_number: int)
signal boss_spawned

@export var wave_duration: float = 180.0  # 3 minutes per wave
@export var max_waves: int = 5
@export var spawn_margin: float = 50.0

var spawn_timer: float = 0.0
var wave_timer: float = 0.0
var current_wave: int = 1
var player_ref: Node2D = null
var viewport_size: Vector2
var _boss_spawned: bool = false

var _enemy_scene: PackedScene
var _boss_scene: PackedScene

func _ready() -> void:
	_enemy_scene = preload("res://src/scenes/enemy/enemy.tscn")
	_boss_scene = preload("res://src/scenes/enemy/boss_ash_behemoth.tscn")
	viewport_size = get_viewport_rect().size

func set_player(player: Node2D) -> void:
	player_ref = player

func _process(delta: float) -> void:
	if not GameManager.is_game_active:
		return
	if GameManager.current_state == GameManager.State.LEVEL_UP:
		return

	GameManager.elapsed_time += delta
	wave_timer += delta
	spawn_timer -= delta

	# Wave progression
	if wave_timer >= wave_duration and current_wave < max_waves:
		current_wave += 1
		wave_timer = 0.0
		GameManager.current_wave = current_wave
		GameManager.wave_changed.emit(current_wave)
		wave_started.emit(current_wave)

		# Spawn boss on final wave
		if current_wave == max_waves and not _boss_spawned:
			_spawn_boss()

	# Spawn regular enemies
	if spawn_timer <= 0.0 and is_instance_valid(player_ref):
		_spawn_enemy()
		var wave_config: Dictionary = EnemyData.get_wave_config(current_wave)
		spawn_timer = wave_config.get("spawn_interval", 1.5)

func _spawn_enemy() -> void:
	var enemy := _enemy_scene.instantiate()
	var wave_config: Dictionary = EnemyData.get_wave_config(current_wave)

	# Pick a random enemy type for this wave
	var wave_idx: int = current_wave - 1
	var enemy_type: int = EnemyData.pick_enemy_type(wave_idx)
	var type_data: Dictionary = EnemyData.get_type_data(enemy_type)

	# Apply wave scaling multipliers to the type's base stats
	var scaled_data: Dictionary = type_data.duplicate()
	scaled_data["max_hp"] = int(type_data.get("max_hp", 30) * wave_config.get("hp_mult", 1.0))
	scaled_data["move_speed"] = type_data.get("move_speed", 80.0) * wave_config.get("speed_mult", 1.0)
	scaled_data["contact_damage"] = int(type_data.get("contact_damage", 10) * wave_config.get("damage_mult", 1.0))

	# Scale ranged damage too
	if type_data.get("behavior", "chase") == "ranged":
		scaled_data["projectile_damage"] = int(type_data.get("projectile_damage", 12) * wave_config.get("damage_mult", 1.0))

	# Scale explode damage
	if type_data.get("behavior", "chase") == "explode":
		scaled_data["explode_damage"] = int(type_data.get("explode_damage", 35) * wave_config.get("damage_mult", 1.0))

	enemy.configure(scaled_data)
	enemy.global_position = _random_edge_position()
	get_tree().current_scene.add_child(enemy)

func _spawn_boss() -> void:
	_boss_spawned = true
	var boss := _boss_scene.instantiate()
	boss.global_position = _random_edge_position()

	# Connect boss death to victory
	boss.boss_died.connect(_on_boss_died)

	get_tree().current_scene.add_child(boss)
	boss_spawned.emit()

func _on_boss_died() -> void:
	# Boss defeated = game won. Trigger game over (victory) after a short delay.
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(func(): GameManager.trigger_game_over())

func _random_edge_position() -> Vector2:
	var cam_pos := player_ref.global_position if is_instance_valid(player_ref) else Vector2.ZERO
	var half_w: float = viewport_size.x / 2.0 + spawn_margin
	var half_h: float = viewport_size.y / 2.0 + spawn_margin

	var side := randi() % 4
	var pos := Vector2.ZERO
	match side:
		0:  # Top
			pos = Vector2(randf_range(-half_w, half_w), -half_h)
		1:  # Bottom
			pos = Vector2(randf_range(-half_w, half_w), half_h)
		2:  # Left
			pos = Vector2(-half_w, randf_range(-half_h, half_h))
		3:  # Right
			pos = Vector2(half_w, randf_range(-half_h, half_h))

	return cam_pos + pos
