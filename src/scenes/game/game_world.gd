extends Node2D
## Main game scene: ties together player, enemy spawner, HUD, and UI panels.

@onready var player: CharacterBody2D = $Player
@onready var enemy_spawner: Node2D = $EnemySpawner
@onready var hud: CanvasLayer = $HUD
@onready var level_up_panel: CanvasLayer = $LevelUpPanel
@onready var game_over_panel: CanvasLayer = $GameOverPanel
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	enemy_spawner.set_player(player)
	hud.set_player(player)
	level_up_panel.set_player(player)

	GameManager.player_leveled_up.connect(_on_player_leveled_up)
	GameManager.game_over_triggered.connect(_on_game_over)

	GameManager.set_state(GameManager.State.GAMEPLAY)


func _process(_delta: float) -> void:
	if is_instance_valid(player):
		camera.global_position = player.global_position


func _on_player_leveled_up(_level: int) -> void:
	level_up_panel.show_panel()


func _on_game_over(survived_time: float) -> void:
	game_over_panel.show_panel(
		survived_time, GameManager.enemies_killed, GameManager.player_level
	)
