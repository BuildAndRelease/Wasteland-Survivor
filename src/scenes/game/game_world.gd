extends Node2D
## Main game scene: ties together player, enemy spawner, HUD, UI panels,
## SkillManager, and map decoration. Wires boss health bar to HUD.

@onready var player: CharacterBody2D = $Player
@onready var enemy_spawner: Node2D = $EnemySpawner
@onready var hud: CanvasLayer = $HUD
@onready var level_up_panel: CanvasLayer = $LevelUpPanel
@onready var game_over_panel: CanvasLayer = $GameOverPanel
@onready var camera: Camera2D = $Camera2D
@onready var map_decoration: Node2D = $MapDecoration

var skill_manager: SkillManager = null


func _ready() -> void:
	# Create and wire SkillManager
	skill_manager = SkillManager.new()
	skill_manager.name = "SkillManager"
	add_child(skill_manager)
	skill_manager.player_ref = player
	player.skill_manager = skill_manager

	enemy_spawner.set_player(player)
	hud.set_player(player)
	level_up_panel.set_skill_manager(skill_manager)
	map_decoration.set_player(player)

	# Connect spawner signals for boss tracking
	enemy_spawner.boss_spawned.connect(_on_boss_spawned)

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


func _on_boss_spawned() -> void:
	# Find the boss node and connect it to HUD
	await get_tree().process_frame
	var bosses := get_tree().get_nodes_in_group("boss")
	if bosses.size() > 0:
		hud.set_boss(bosses[0])
