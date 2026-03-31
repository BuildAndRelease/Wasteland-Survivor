extends CanvasLayer
## Game over panel: shows final stats with restart and menu buttons.
## Shows "VICTORY" if boss was defeated, "GAME OVER" otherwise.

@onready var title_label: Label = $Content/GameOverLabel
@onready var time_label: Label = $Content/TimeLabel
@onready var kills_label: Label = $Content/KillsLabel
@onready var level_label: Label = $Content/LevelLabel


func _ready() -> void:
	_set_panel_visible(false)


## CanvasLayer has no "visible" property — toggle child nodes instead.
func _set_panel_visible(show: bool) -> void:
	for child in get_children():
		if child is Node:
			child.visible = show


func show_panel(survived_time: float, kills: int, level: int) -> void:
	var mins: int = int(survived_time) / 60
	var secs: int = int(survived_time) % 60
	time_label.text = "Survived: %d:%02d" % [mins, secs]
	kills_label.text = "Enemies Killed: %d" % kills
	level_label.text = "Level Reached: %d" % level

	# Check if boss was defeated (no boss nodes alive = victory)
	var bosses := get_tree().get_nodes_in_group("boss")
	if bosses.size() == 0 and GameManager.current_wave >= 5:
		title_label.text = "VICTORY!"
	else:
		title_label.text = "GAME OVER"

	_set_panel_visible(true)


func _on_restart_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	_set_panel_visible(false)
	GameManager.start_game()


func _on_menu_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	_set_panel_visible(false)
	GameManager.go_to_menu()
