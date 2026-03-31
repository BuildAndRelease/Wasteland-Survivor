extends CanvasLayer
## In-game HUD: HP bar, XP bar, level display, wave timer, kill count.

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HPBar
@onready var xp_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/XPBar
@onready var level_label: Label = $MarginContainer/VBoxContainer/TopBar/LevelLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/BottomBar/WaveLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/BottomBar/TimerLabel
@onready var kill_label: Label = $MarginContainer/VBoxContainer/BottomBar/KillLabel

var player_ref: Node2D = null

func _ready() -> void:
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.player_leveled_up.connect(_on_level_up)
	_update_wave(1)
	_update_level(1)

func set_player(player: Node2D) -> void:
	player_ref = player
	if player_ref.has_signal("health_changed"):
		player_ref.health_changed.connect(_on_health_changed)
	_on_health_changed(player_ref.current_hp, player_ref.max_hp)

func _process(_delta: float) -> void:
	if not GameManager.is_game_active:
		return
	# Update XP bar
	xp_bar.max_value = GameManager.xp_to_next_level()
	xp_bar.value = GameManager.player_xp
	# Update timer
	var total_sec: int = int(GameManager.elapsed_time)
	var mins: int = total_sec / 60
	var secs: int = total_sec % 60
	timer_label.text = "%d:%02d" % [mins, secs]
	# Update kills
	kill_label.text = "Kills: %d" % GameManager.enemies_killed

func _on_health_changed(current: int, max_val: int) -> void:
	hp_bar.max_value = max_val
	hp_bar.value = current

func _on_wave_changed(wave: int) -> void:
	_update_wave(wave)

func _on_level_up(level: int) -> void:
	_update_level(level)

func _update_wave(wave: int) -> void:
	wave_label.text = "Wave %d/5" % wave

func _update_level(level: int) -> void:
	level_label.text = "Lv.%d" % level
