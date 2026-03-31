extends CanvasLayer
## Settlement screen shown after game over or victory.
## Displays run stats and scrap coins earned with counting animation, then returns to camp.

@onready var title_label: Label = $Content/TitleLabel
@onready var time_label: Label = $Content/StatsContainer/TimeLabel
@onready var kills_label: Label = $Content/StatsContainer/KillsLabel
@onready var level_label: Label = $Content/StatsContainer/LevelLabel
@onready var wave_label: Label = $Content/StatsContainer/WaveLabel
@onready var separator: HSeparator = $Content/Separator2
@onready var coins_label: Label = $Content/CoinsLabel
@onready var return_button: Button = $Content/ReturnButton

var _scrap_earned: int = 0
var _coin_display: int = 0
var _coin_counting: bool = false


func _ready() -> void:
	_set_panel_visible(false)
	return_button.pressed.connect(_on_return_pressed)


## CanvasLayer has no "visible" property — toggle child nodes instead.
func _set_panel_visible(show: bool) -> void:
	for child in get_children():
		if child is Node:
			child.visible = show


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
	SaveManager.add_scrap_coins(_scrap_earned)

	# Animate coin counter from 0 to earned amount
	_coin_display = 0
	coins_label.text = "Scrap Coins Earned: +0"
	_set_panel_visible(true)

	# Fade in stats (modulate children since CanvasLayer has no modulate)
	var overlay: ColorRect = $Overlay
	var content: VBoxContainer = $Content
	overlay.modulate.a = 0.0
	content.modulate.a = 0.0
	var fade_tween := create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(overlay, "modulate:a", 1.0, 0.3)
	fade_tween.tween_property(content, "modulate:a", 1.0, 0.3)
	fade_tween.set_parallel(false)
	fade_tween.tween_interval(0.5)
	fade_tween.tween_callback(_start_coin_count)


func _start_coin_count() -> void:
	if _scrap_earned <= 0:
		coins_label.text = "Scrap Coins Earned: +0"
		return
	_coin_counting = true
	var duration: float = clampf(float(_scrap_earned) / 200.0, 0.5, 2.0)
	var tween := create_tween()
	tween.tween_method(_update_coin_display, 0, _scrap_earned, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(_on_coin_count_done)


func _update_coin_display(value: int) -> void:
	if value != _coin_display:
		_coin_display = value
		coins_label.text = "Scrap Coins Earned: +%d" % _coin_display
		# Play coin tick SFX at intervals
		if _coin_display % maxi(int(_scrap_earned / 10.0), 1) == 0:
			AudioManager.play_sfx("coin_earned", -8.0)


func _on_coin_count_done() -> void:
	_coin_counting = false
	coins_label.text = "Scrap Coins Earned: +%d" % _scrap_earned
	AudioManager.play_sfx("coin_earned")
	# Pop effect on final number
	var tween := create_tween()
	tween.tween_property(coins_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(coins_label, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)


func _on_return_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	_set_panel_visible(false)
	GameManager.go_to_camp()
