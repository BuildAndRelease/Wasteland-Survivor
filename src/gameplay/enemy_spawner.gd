extends Node2D
## Spawns enemies from screen edges with increasing density per wave.

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.5
@export var wave_duration: float = 180.0  # 3 minutes
@export var max_waves: int = 5
@export var spawn_margin: float = 50.0

var spawn_timer: float = 0.0
var wave_timer: float = 0.0
var current_wave: int = 1
var player_ref: Node2D = null
var viewport_size: Vector2

func _ready() -> void:
	enemy_scene = preload("res://src/scenes/enemy/enemy.tscn")
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

	# Spawn enemies
	if spawn_timer <= 0 and is_instance_valid(player_ref):
		_spawn_enemy()
		# Decrease interval as waves progress
		var effective_interval: float = spawn_interval / (1.0 + (current_wave - 1) * 0.4)
		spawn_timer = effective_interval

func _spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate()

	# Scale enemy stats by wave
	enemy.max_hp = 30 + (current_wave - 1) * 10
	enemy.move_speed = 80.0 + (current_wave - 1) * 10.0
	enemy.xp_drop = 5 + (current_wave - 1) * 2

	enemy.global_position = _random_edge_position()
	get_tree().current_scene.add_child(enemy)

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
