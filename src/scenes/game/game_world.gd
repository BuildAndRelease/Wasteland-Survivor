extends Node2D
## Main game scene: ties together player, enemy spawner, HUD, UI panels,
## SkillManager, and map decoration. Applies permanent upgrades and character
## stats at game start. Shows settlement screen on game over.

@onready var player: CharacterBody2D = $Player
@onready var enemy_spawner: Node2D = $EnemySpawner
@onready var hud: CanvasLayer = $HUD
@onready var level_up_panel: CanvasLayer = $LevelUpPanel
@onready var settlement_panel: CanvasLayer = $SettlementPanel
@onready var camera: Camera2D = $Camera2D
@onready var map_decoration: Node2D = $MapDecoration

var skill_manager: SkillManager = null


func _ready() -> void:
	# Apply character stats before anything else
	_apply_character_stats()
	_apply_permanent_upgrades()

	# Create and wire SkillManager
	skill_manager = SkillManager.new()
	skill_manager.name = "SkillManager"
	add_child(skill_manager)
	skill_manager.player_ref = player
	player.skill_manager = skill_manager

	# Grant character's starting skill
	_grant_starting_skill()

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


func _apply_character_stats() -> void:
	var char_data: Dictionary = CampData.get_character(SaveManager.selected_character)
	if char_data.is_empty():
		return
	var mods: Dictionary = char_data.get("stat_mods", {})
	player.max_hp = mods.get("max_hp", player.max_hp)
	player.move_speed = mods.get("move_speed", player.move_speed)
	player.attack_damage = mods.get("attack_damage", player.attack_damage)
	player.xp_pickup_range = mods.get("xp_pickup_range", player.xp_pickup_range)
	# Update the player sprite color to match character
	var sprite: ColorRect = player.get_node_or_null("Sprite")
	if sprite:
		sprite.color = char_data.get("color", Color(0.2, 0.7, 0.3, 1))
	# Re-initialize HP after changing max
	player.current_hp = player.max_hp
	player.health_changed.emit(player.current_hp, player.max_hp)


func _apply_permanent_upgrades() -> void:
	var hp_level: int = SaveManager.get_upgrade_level("health_boost")
	var atk_level: int = SaveManager.get_upgrade_level("attack_boost")
	var spd_level: int = SaveManager.get_upgrade_level("speed_boost")

	if hp_level > 0:
		var hp_mult: float = 1.0 + CampData.get_upgrade_effect("health_boost", hp_level)
		player.max_hp = int(player.max_hp * hp_mult)
		player.current_hp = player.max_hp
		player.health_changed.emit(player.current_hp, player.max_hp)

	if atk_level > 0:
		var atk_mult: float = 1.0 + CampData.get_upgrade_effect("attack_boost", atk_level)
		player.attack_damage = int(player.attack_damage * atk_mult)

	if spd_level > 0:
		var spd_mult: float = 1.0 + CampData.get_upgrade_effect("speed_boost", spd_level)
		player.move_speed = player.move_speed * spd_mult


func _grant_starting_skill() -> void:
	var char_data: Dictionary = CampData.get_character(SaveManager.selected_character)
	var starting_skill: String = char_data.get("starting_skill", "")
	if starting_skill != "":
		skill_manager.add_skill(starting_skill)


func _on_player_leveled_up(_level: int) -> void:
	level_up_panel.show_panel()


func _on_game_over(survived_time: float) -> void:
	# Check if boss was defeated
	var bosses := get_tree().get_nodes_in_group("boss")
	var boss_defeated: bool = bosses.size() == 0 and GameManager.current_wave >= 5
	GameManager.boss_defeated = boss_defeated

	settlement_panel.show_panel(
		survived_time,
		GameManager.enemies_killed,
		GameManager.player_level,
		GameManager.current_wave,
		boss_defeated
	)


func _on_boss_spawned() -> void:
	# Find the boss node and connect it to HUD
	await get_tree().process_frame
	var bosses := get_tree().get_nodes_in_group("boss")
	if bosses.size() > 0:
		hud.set_boss(bosses[0])
