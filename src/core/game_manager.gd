extends Node
## Global game state manager (autoload singleton).
## Flow: Main Menu -> Camp -> Game -> Settlement -> Camp

signal game_state_changed(new_state: String)
signal player_leveled_up(new_level: int)
signal wave_changed(wave_number: int)
signal game_over_triggered(survived_time: float)
signal xp_changed(current_xp: int, xp_needed: int)

enum State { MAIN_MENU, CAMP, GAMEPLAY, PAUSED, LEVEL_UP, GAME_OVER, SETTLEMENT }

var current_state: State = State.MAIN_MENU
var player_level: int = 1
var player_xp: int = 0
var current_wave: int = 1
var elapsed_time: float = 0.0
var enemies_killed: int = 0
var is_game_active: bool = false
var run_coins: int = 0
var current_theme_id: String = ""

const THEME_DEFAULT: String = ""
const THEME_FROZEN_WASTELAND: String = "level2_frozen_wasteland"
const THEME_HELL_FURNACE: String = "level3_hell_furnace"

## Whether boss was defeated this run (used by settlement screen).
var boss_defeated: bool = false

## XP required per level: base * level ^ exponent (power curve).
func xp_for_level(level: int) -> int:
	return int(BalanceConfig.XP_BASE * pow(level, BalanceConfig.XP_EXPONENT))

func xp_to_next_level() -> int:
	return xp_for_level(player_level)

func add_xp(amount: int) -> void:
	if current_state != State.GAMEPLAY:
		return
	if player_level >= BalanceConfig.PLAYER_MAX_LEVEL:
		return
	player_xp += amount
	xp_changed.emit(player_xp, xp_to_next_level())
	while player_xp >= xp_to_next_level() and player_level < BalanceConfig.PLAYER_MAX_LEVEL:
		player_xp -= xp_to_next_level()
		player_level += 1
		player_leveled_up.emit(player_level)
		set_state(State.LEVEL_UP)
	# Emit final XP state after any level-ups
	xp_changed.emit(player_xp, xp_to_next_level())
	# Clamp xp if at max level
	if player_level >= BalanceConfig.PLAYER_MAX_LEVEL:
		player_xp = 0

func set_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.GAMEPLAY:
			get_tree().paused = false
			is_game_active = true
		State.LEVEL_UP:
			get_tree().paused = true
		State.PAUSED:
			get_tree().paused = true
		State.GAME_OVER:
			get_tree().paused = true
			is_game_active = false
			game_over_triggered.emit(elapsed_time)
		State.SETTLEMENT:
			get_tree().paused = true
			is_game_active = false
		State.MAIN_MENU, State.CAMP:
			get_tree().paused = false
			is_game_active = false
	game_state_changed.emit(State.keys()[new_state])

func start_game() -> void:
	current_theme_id = SaveManager.selected_theme_id.strip_edges()
	reset_stats(false)
	get_tree().change_scene_to_file("res://src/scenes/game/game_world.tscn")
	# State set after scene loads via game_world.gd _ready

func go_to_camp() -> void:
	reset_stats()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/scenes/ui/camp.tscn")
	set_state(State.CAMP)

func go_to_menu() -> void:
	reset_stats()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/scenes/ui/main_menu.tscn")
	set_state(State.MAIN_MENU)

func go_to_resource_preview() -> void:
	reset_stats(false)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/scenes/ui/resource_preview.tscn")
	set_state(State.MAIN_MENU)

func set_theme(theme_id: String) -> void:
	current_theme_id = theme_id.strip_edges()

func is_theme_active(theme_id: String) -> bool:
	return current_theme_id.strip_edges() == theme_id.strip_edges()

func get_boss_locale_key() -> String:
	match current_theme_id:
		THEME_FROZEN_WASTELAND:
			return "boss_name_frozen"
		THEME_HELL_FURNACE:
			return "boss_name_hell"
		_:
			return "boss_name"

func get_boss_display_name() -> String:
	return Locale.t(get_boss_locale_key())

func get_themed_sprite_path(relative_path: String, fallback_path: String = "") -> String:
	if current_theme_id != "":
		var themed_path := "res://assets/sprites/themes/%s/%s" % [current_theme_id, relative_path]
		if ResourceLoader.exists(themed_path):
			return themed_path
	if fallback_path != "":
		return fallback_path
	return "res://assets/sprites/%s" % relative_path

func reset_stats(reset_theme: bool = true) -> void:
	player_level = 1
	player_xp = 0
	current_wave = 1
	elapsed_time = 0.0
	enemies_killed = 0
	is_game_active = false
	boss_defeated = false
	run_coins = 0
	if reset_theme:
		current_theme_id = ""

func trigger_game_over() -> void:
	set_state(State.GAME_OVER)
