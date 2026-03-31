extends CanvasLayer
## In-game HUD: HP bar, XP bar, level display, wave timer, kill count,
## wave announcements, and boss health bar.

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HPBar
@onready var xp_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/XPBar
@onready var level_label: Label = $MarginContainer/VBoxContainer/TopBar/LevelLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/BottomBar/WaveLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/BottomBar/TimerLabel
@onready var kill_label: Label = $MarginContainer/VBoxContainer/BottomBar/KillLabel

var player_ref: Node2D = null
var _boss_ref: Node2D = null

# Wave announcement
var _wave_announce_label: Label = null
# Boss HP bar
var _boss_hp_container: VBoxContainer = null
var _boss_name_label: Label = null
var _boss_hp_bar: ProgressBar = null

func _ready() -> void:
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.player_leveled_up.connect(_on_level_up)
	_update_wave(1)
	_update_level(1)
	_build_wave_announce()
	_build_boss_hp_bar()

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
	# Update boss HP bar
	_update_boss_hp()

func _on_health_changed(current: int, max_val: int) -> void:
	hp_bar.max_value = max_val
	hp_bar.value = current

func _on_wave_changed(wave: int) -> void:
	_update_wave(wave)
	_show_wave_announcement(wave)

func _on_level_up(level: int) -> void:
	_update_level(level)

func _update_wave(wave: int) -> void:
	wave_label.text = "Wave %d/5" % wave

func _update_level(level: int) -> void:
	level_label.text = "Lv.%d" % level

# --- Wave Announcement ---

func _build_wave_announce() -> void:
	_wave_announce_label = Label.new()
	_wave_announce_label.name = "WaveAnnounce"
	_wave_announce_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_announce_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wave_announce_label.anchors_preset = Control.PRESET_CENTER
	_wave_announce_label.anchor_left = 0.5
	_wave_announce_label.anchor_top = 0.35
	_wave_announce_label.anchor_right = 0.5
	_wave_announce_label.anchor_bottom = 0.35
	_wave_announce_label.offset_left = -200.0
	_wave_announce_label.offset_right = 200.0
	_wave_announce_label.offset_top = -30.0
	_wave_announce_label.offset_bottom = 30.0
	_wave_announce_label.add_theme_font_size_override("font_size", 32)
	_wave_announce_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	_wave_announce_label.modulate.a = 0.0
	add_child(_wave_announce_label)

func _show_wave_announcement(wave: int) -> void:
	var text: String
	if wave == 5:
		text = "FINAL WAVE — BOSS INCOMING!"
	else:
		text = "— WAVE %d —" % wave
	_wave_announce_label.text = text
	# Fade in, hold, fade out
	var tween := create_tween()
	tween.tween_property(_wave_announce_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(_wave_announce_label, "modulate:a", 0.0, 0.5)

# --- Boss HP Bar ---

func _build_boss_hp_bar() -> void:
	_boss_hp_container = VBoxContainer.new()
	_boss_hp_container.name = "BossHPContainer"
	_boss_hp_container.anchors_preset = Control.PRESET_CENTER_TOP
	_boss_hp_container.anchor_left = 0.5
	_boss_hp_container.anchor_right = 0.5
	_boss_hp_container.anchor_top = 0.0
	_boss_hp_container.anchor_bottom = 0.0
	_boss_hp_container.offset_left = -200.0
	_boss_hp_container.offset_right = 200.0
	_boss_hp_container.offset_top = 50.0
	_boss_hp_container.offset_bottom = 100.0
	_boss_hp_container.visible = false

	_boss_name_label = Label.new()
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name_label.text = "Ash Behemoth"
	_boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1, 1.0))
	_boss_name_label.add_theme_font_size_override("font_size", 18)
	_boss_hp_container.add_child(_boss_name_label)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.custom_minimum_size = Vector2(400, 16)
	_boss_hp_bar.max_value = 100
	_boss_hp_bar.value = 100
	_boss_hp_bar.show_percentage = false
	_boss_hp_container.add_child(_boss_hp_bar)

	add_child(_boss_hp_container)

## Call this from game_world when boss spawns.
func set_boss(boss: Node2D) -> void:
	_boss_ref = boss
	_boss_hp_container.visible = true
	if boss.has_signal("health_changed"):
		boss.health_changed.connect(_on_boss_health_changed)
	if boss.has_signal("boss_died"):
		boss.boss_died.connect(_on_boss_died)
	_on_boss_health_changed(boss.current_hp, boss.max_hp)

func _on_boss_health_changed(current: int, max_val: int) -> void:
	_boss_hp_bar.max_value = max_val
	_boss_hp_bar.value = current

func _on_boss_died() -> void:
	_boss_hp_container.visible = false
	_boss_ref = null
	# Show victory text
	_wave_announce_label.text = "BOSS DEFEATED!"
	var tween := create_tween()
	tween.tween_property(_wave_announce_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(3.0)
	tween.tween_property(_wave_announce_label, "modulate:a", 0.0, 0.5)

func _update_boss_hp() -> void:
	if _boss_ref and is_instance_valid(_boss_ref):
		_boss_hp_bar.value = _boss_ref.current_hp
