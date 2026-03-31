extends Node
## Global game state manager (autoload singleton).
## Flow: Main Menu -> Camp -> Game -> Settlement -> Camp

signal game_state_changed(new_state: String)
signal player_leveled_up(new_level: int)
signal wave_changed(wave_number: int)
signal game_over_triggered(survived_time: float)

enum State { MAIN_MENU, CAMP, GAMEPLAY, PAUSED, LEVEL_UP, GAME_OVER, SETTLEMENT }

var current_state: State = State.MAIN_MENU
var player_level: int = 1
var player_xp: int = 0
var current_wave: int = 1
var elapsed_time: float = 0.0
var enemies_killed: int = 0
var is_game_active: bool = false

## Whether boss was defeated this run (used by settlement screen).
var boss_defeated: bool = false

## XP required per level: base 20, grows by 15 per level.
func xp_for_level(level: int) -> int:
	return 20 + (level - 1) * 15

func xp_to_next_level() -> int:
	return xp_for_level(player_level)

func add_xp(amount: int) -> void:
	if current_state != State.GAMEPLAY:
		return
	player_xp += amount
	while player_xp >= xp_to_next_level():
		player_xp -= xp_to_next_level()
		player_level += 1
		player_leveled_up.emit(player_level)
		set_state(State.LEVEL_UP)

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
	reset_stats()
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

func reset_stats() -> void:
	player_level = 1
	player_xp = 0
	current_wave = 1
	elapsed_time = 0.0
	enemies_killed = 0
	is_game_active = false
	boss_defeated = false

func trigger_game_over() -> void:
	set_state(State.GAME_OVER)
