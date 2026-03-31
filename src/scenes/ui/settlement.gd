extends CanvasLayer
## Settlement screen shown after game over or victory.
## Displays run stats and scrap coins earned, then returns to camp.

@onready var title_label: Label = $Content/TitleLabel
@onready var time_label: Label = $Content/StatsContainer/TimeLabel
@onready var kills_label: Label = $Content/StatsContainer/KillsLabel
@onready var level_label: Label = $Content/StatsContainer/LevelLabel
@onready var wave_label: Label = $Content/StatsContainer/WaveLabel
@onready var separator: HSeparator = $Content/Separator2
@onready var coins_label: Label = $Content/CoinsLabel
@onready var return_button: Button = $Content/ReturnButton

var _scrap_earned: int = 0


func _ready() -> void:
	visible = false
	return_button.pressed.connect(_on_return_pressed)


## Show settlement results and award scrap coins.
func show_panel(survived_time: float, kills: int, level: int, wave: int, boss_defeated: bool) -> void:
	var mins: int = int(survived_time) / 60
	var secs: int = int(survived_time) % 60
	time_label.text = "Survival Time: %d:%02d" % [mins, secs]
	kills_label.text = "Enemies Killed: %d" % kills
	level_label.text = "Level Reached: %d" % level
	wave_label.text = "Wave Reached: %d / 5" % wave

	if boss_defeated:
		title_label.text = "VICTORY!"
	else:
		title_label.text = "GAME OVER"

	# Calculate and award scrap coins
	_scrap_earned = CampData.calculate_scrap_coins(wave, kills, boss_defeated)
	coins_label.text = "Scrap Coins Earned: +%d" % _scrap_earned
	SaveManager.add_scrap_coins(_scrap_earned)

	visible = true


func _on_return_pressed() -> void:
	visible = false
	GameManager.go_to_camp()
