extends CanvasLayer
## In-game HUD: HP bar, XP bar, level display, wave timer, kill count,
## wave announcements, and boss health bar. Animated bars and polish effects.

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HPBar
@onready var xp_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/XPBar
@onready var level_label: Label = $MarginContainer/VBoxContainer/TopBar/LevelLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/BottomBar/WaveLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/BottomBar/TimerLabel
@onready var kill_label: Label = $MarginContainer/VBoxContainer/BottomBar/KillLabel

var player_ref: Node2D = null
var _boss_ref: Node2D = null

# Animated bar targets
var _hp_target: float = 100.0
var _hp_max_target: float = 100.0
var _xp_target: float = 0.0
var _xp_max_target: float = 20.0

# Wave announcement
var _wave_announce_label: Label = null
# Boss HP bar
var _boss_hp_container: VBoxContainer = null
var _boss_name_label: Label = null
var _boss_hp_bar: ProgressBar = null
var _boss_hp_target: float = 100.0

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

func _process(delta: float) -> void:
	# Update timer before game-active check so it shows correct time during level-up
	var total_sec: int = int(GameManager.elapsed_time)
	var mins: int = total_sec / 60
	var secs: int = total_sec % 60
	timer_label.text = "%d:%02d" % [mins, secs]

	if not GameManager.is_game_active:
		return
	# Animate HP bar smoothly toward target
	hp_bar.max_value = _hp_max_target
	hp_bar.value = lerpf(hp_bar.value, _hp_target, delta * 10.0)
	# Animate XP bar smoothly toward target
	_xp_max_target = GameManager.xp_to_next_level()
	_xp_target = GameManager.player_xp
	xp_bar.max_value = _xp_max_target
	xp_bar.value = lerpf(xp_bar.value, _xp_target, delta * 8.0)
	# Update kills
	kill_label.text = Locale.t("kills_format") % GameManager.enemies_killed
	# Update boss HP bar
	_update_boss_hp(delta)

func _on_health_changed(current: int, max_val: int) -> void:
	_hp_max_target = max_val
	_hp_target = current

func _on_wave_changed(wave: int) -> void:
	_update_wave(wave)
	_show_wave_announcement(wave)

func _on_level_up(level: int) -> void:
	_update_level(level)
	# Level up pop effect on level label
	var tween := create_tween()
	tween.tween_property(level_label, "scale", Vector2(1.4, 1.4), 0.1)
	tween.tween_property(level_label, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

func _update_wave(wave: int) -> void:
	wave_label.text = Locale.t("wave_format") % wave

func _update_level(level: int) -> void:
	if level >= BalanceConfig.PLAYER_MAX_LEVEL:
		level_label.text = Locale.t("level_max_format") % level
	else:
		level_label.text = Locale.t("level_format") % level

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
	_wave_announce_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_wave_announce_label.add_theme_constant_override("outline_size", 3)
	_wave_announce_label.modulate.a = 0.0
	_wave_announce_label.pivot_offset = Vector2(200, 30)
	add_child(_wave_announce_label)

func _show_wave_announcement(wave: int) -> void:
	var text: String
	var color := Color(1.0, 0.8, 0.2, 1.0)
	if wave == 5:
		text = Locale.t("final_wave")
		color = Color(1.0, 0.2, 0.1, 1.0)
	else:
		text = Locale.t("wave_announce") % wave
	_wave_announce_label.text = text
	_wave_announce_label.add_theme_color_override("font_color", color)
	# Scale up + fade in, hold, scale down + fade out
	_wave_announce_label.scale = Vector2(0.5, 0.5)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_wave_announce_label, "modulate:a", 1.0, 0.2)
	tween.tween_property(_wave_announce_label, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(false)
	tween.tween_interval(2.0)
	tween.set_parallel(true)
	tween.tween_property(_wave_announce_label, "modulate:a", 0.0, 0.5)
	tween.tween_property(_wave_announce_label, "scale", Vector2(1.2, 1.2), 0.5)

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
	_boss_name_label.text = Locale.t("boss_name")
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
	# Slide in boss HP bar
	_boss_hp_container.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_boss_hp_container, "modulate:a", 1.0, 0.5)

func _on_boss_health_changed(current: int, max_val: int) -> void:
	_boss_hp_bar.max_value = max_val
	_boss_hp_target = current

func _on_boss_died() -> void:
	_boss_ref = null
	# Fade out boss HP bar
	var fade_tween := create_tween()
	fade_tween.tween_property(_boss_hp_container, "modulate:a", 0.0, 0.3)
	fade_tween.tween_callback(func(): _boss_hp_container.visible = false)
	# Show victory text
	_wave_announce_label.text = Locale.t("boss_defeated")
	_wave_announce_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	_wave_announce_label.scale = Vector2(0.5, 0.5)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_wave_announce_label, "modulate:a", 1.0, 0.2)
	tween.tween_property(_wave_announce_label, "scale", Vector2(1.3, 1.3), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(false)
	tween.tween_property(_wave_announce_label, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_interval(3.0)
	tween.tween_property(_wave_announce_label, "modulate:a", 0.0, 0.5)

func _update_boss_hp(delta: float) -> void:
	if _boss_ref and is_instance_valid(_boss_ref):
		_boss_hp_bar.value = lerpf(_boss_hp_bar.value, _boss_hp_target, delta * 8.0)
