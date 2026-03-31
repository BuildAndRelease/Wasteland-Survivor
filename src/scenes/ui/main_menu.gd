extends Control
## Main menu: title screen with start button.


func _ready() -> void:
	GameManager.set_state(GameManager.State.MAIN_MENU)


func _on_start_pressed() -> void:
	GameManager.start_game()
