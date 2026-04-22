extends Control
## Camp screen: character selection, permanent upgrades, and game start.
## Hub between runs. Flow: Main Menu -> Camp -> Game -> Settlement -> Camp.

@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var char_container: HBoxContainer = $Content/CharacterSection/CharContainer
@onready var char_info_label: Label = $Content/CharacterSection/CharInfoLabel
@onready var upgrade_container: VBoxContainer = $Content/UpgradeSection/UpgradeList
@onready var level_title_label: Label = $Content/LevelSection/LevelTitle
@onready var level_selector: OptionButton = $Content/LevelSection/LevelSelector
@onready var start_button: Button = $Content/StartButton
@onready var menu_button: Button = $TopBar/MenuButton

var _char_buttons: Dictionary = {}
var _upgrade_buttons: Dictionary = {}
var _selected_character: String = "survivor"
var _selected_theme_id: String = ""

const LEVEL_OPTIONS: Array[Dictionary] = [
	{"id": "", "label_key": "level_default"},
	{"id": "level2_frozen_wasteland", "label_key": "level_frozen_test"},
]


func _ready() -> void:
	GameManager.set_state(GameManager.State.CAMP)
	_selected_character = SaveManager.selected_character
	_selected_theme_id = SaveManager.selected_theme_id
	_build_character_buttons()
	_build_upgrade_buttons()
	_build_level_selector()
	_update_coins_display()
	_update_character_selection()
	_update_upgrade_display()
	_update_level_selector()
	if not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if not menu_button.pressed.is_connected(_on_menu_pressed):
		menu_button.pressed.connect(_on_menu_pressed)
	if not level_selector.item_selected.is_connected(_on_level_selected):
		level_selector.item_selected.connect(_on_level_selected)
	if not SaveManager.data_changed.is_connected(_on_data_changed):
		SaveManager.data_changed.connect(_on_data_changed)
	start_button.text = Locale.t("start_game")
	menu_button.text = Locale.t("back_to_menu")
	level_title_label.text = Locale.t("level_select_title")


func _build_character_buttons() -> void:
	for child in char_container.get_children():
		child.queue_free()
	_char_buttons.clear()

	for char_id: String in CampData.get_all_character_ids():
		var data: Dictionary = CampData.get_character(char_id)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(140, 120)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		var unlocked: bool = SaveManager.is_character_unlocked(char_id)
		if unlocked:
			var display_name: String = data.get("name_cn", "") if Locale.is_zh() else data.get("name", "")
			btn.text = display_name
		else:
			var display_name: String = data.get("name_cn", "") if Locale.is_zh() else data.get("name", "")
			btn.text = "%s\n%s" % [display_name, Locale.t("locked") % data.get("cost", 0)]

		# Apply character color as modulate hint
		var style := StyleBoxFlat.new()
		var base_color: Color = data.get("color", Color.WHITE)
		if not unlocked:
			base_color = Color(0.3, 0.3, 0.3, 1)
		style.bg_color = base_color.darkened(0.6)
		style.border_width_bottom = 3
		style.border_width_top = 3
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_color = base_color
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", style)

		var hover_style := style.duplicate()
		hover_style.bg_color = base_color.darkened(0.4)
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style := style.duplicate()
		pressed_style.bg_color = base_color.darkened(0.3)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		btn.pressed.connect(_on_character_pressed.bind(char_id))
		char_container.add_child(btn)
		_char_buttons[char_id] = btn


func _build_level_selector() -> void:
	level_selector.clear()
	for option in LEVEL_OPTIONS:
		level_selector.add_item(Locale.t(option["label_key"]))
		var idx := level_selector.item_count - 1
		level_selector.set_item_metadata(idx, option["id"])


func _build_upgrade_buttons() -> void:
	for child in upgrade_container.get_children():
		child.queue_free()
	_upgrade_buttons.clear()

	for upgrade_id: String in CampData.get_all_upgrade_ids():
		var data: Dictionary = CampData.get_upgrade(upgrade_id)
		var hbox := HBoxContainer.new()

		var info_label := Label.new()
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_label.text = _format_upgrade_text(upgrade_id, data)
		hbox.add_child(info_label)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(120, 40)
		btn.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
		hbox.add_child(btn)

		upgrade_container.add_child(hbox)
		_upgrade_buttons[upgrade_id] = {"label": info_label, "button": btn, "container": hbox}

	_update_upgrade_display()


func _format_upgrade_text(upgrade_id: String, data: Dictionary) -> String:
	var current_level: int = SaveManager.get_upgrade_level(upgrade_id)
	var max_level: int = data.get("max_level", 0)
	var name_key: String = "upgrade_%s" % upgrade_id.replace("_boost", "")
	var name_str: String = Locale.t(name_key) if Locale.t(name_key) != name_key else data.get("name", "")

	if current_level >= max_level:
		return "%s  Lv.%d/%d  %s" % [name_str, current_level, max_level, Locale.t("upgrade_max")]

	var effect_desc: String = ""
	var levels: Array = data.get("levels", [])
	if current_level > 0 and current_level <= levels.size():
		effect_desc = levels[current_level - 1].get("desc_cn", levels[current_level - 1].get("desc", "")) if Locale.is_zh() else levels[current_level - 1].get("desc", "")
	return "%s  Lv.%d/%d  %s" % [name_str, current_level, max_level, effect_desc]


func _update_coins_display() -> void:
	coins_label.text = Locale.t("scrap_coins") % SaveManager.scrap_coins


func _update_character_selection() -> void:
	for char_id: String in _char_buttons:
		var btn: Button = _char_buttons[char_id]
		var data: Dictionary = CampData.get_character(char_id)
		var unlocked: bool = SaveManager.is_character_unlocked(char_id)
		var base_color: Color = data.get("color", Color.WHITE)

		# Highlight selected character
		var style: StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate()
		if char_id == _selected_character and unlocked:
			style.border_color = Color.WHITE
			style.border_width_bottom = 4
			style.border_width_top = 4
			style.border_width_left = 4
			style.border_width_right = 4
		elif unlocked:
			style.border_color = base_color
			style.border_width_bottom = 3
			style.border_width_top = 3
			style.border_width_left = 3
			style.border_width_right = 3
		btn.add_theme_stylebox_override("normal", style)

	# Update info label
	var sel_data: Dictionary = CampData.get_character(_selected_character)
	var char_name: String = sel_data.get("name_cn", "") if Locale.is_zh() else sel_data.get("name", "")
	var char_desc_key: String = "char_%s_desc" % _selected_character
	var char_desc: String = Locale.t(char_desc_key)
	# If locale key not found, fallback to data
	if char_desc == char_desc_key:
		char_desc = sel_data.get("description_cn", sel_data.get("description", "")) if Locale.is_zh() else sel_data.get("description", "")
	char_info_label.text = "%s — %s" % [char_name, char_desc]


func _update_level_selector() -> void:
	for i in range(level_selector.item_count):
		var option: Dictionary = LEVEL_OPTIONS[i]
		level_selector.set_item_text(i, Locale.t(option["label_key"]))
		if str(level_selector.get_item_metadata(i)) == _selected_theme_id:
			level_selector.select(i)


func _update_upgrade_display() -> void:
	for upgrade_id: String in _upgrade_buttons:
		var data: Dictionary = CampData.get_upgrade(upgrade_id)
		var widgets: Dictionary = _upgrade_buttons[upgrade_id]
		var label: Label = widgets["label"]
		var btn: Button = widgets["button"]

		var current_level: int = SaveManager.get_upgrade_level(upgrade_id)
		var max_level: int = data.get("max_level", 0)

		label.text = _format_upgrade_text(upgrade_id, data)

		if current_level >= max_level:
			btn.text = Locale.t("upgrade_max")
			btn.disabled = true
		else:
			var cost: int = CampData.get_next_upgrade_cost(upgrade_id, current_level)
			btn.text = Locale.t("upgrade_btn") % cost
			btn.disabled = SaveManager.scrap_coins < cost


func _on_character_pressed(char_id: String) -> void:
	AudioManager.play_sfx("ui_click")
	var unlocked: bool = SaveManager.is_character_unlocked(char_id)
	if unlocked:
		_selected_character = char_id
		SaveManager.select_character(char_id)
		_update_character_selection()
	else:
		# Try to unlock
		var data: Dictionary = CampData.get_character(char_id)
		var cost: int = data.get("cost", 0)
		if SaveManager.spend_scrap_coins(cost):
			AudioManager.play_sfx("coin_earned")
			SaveManager.unlock_character(char_id)
			_selected_character = char_id
			SaveManager.select_character(char_id)
			_build_character_buttons()
			_update_character_selection()
			_update_coins_display()
			_update_upgrade_display()


func _on_upgrade_pressed(upgrade_id: String) -> void:
	AudioManager.play_sfx("ui_click")
	var current_level: int = SaveManager.get_upgrade_level(upgrade_id)
	var cost: int = CampData.get_next_upgrade_cost(upgrade_id, current_level)
	if cost < 0:
		return
	if SaveManager.spend_scrap_coins(cost):
		AudioManager.play_sfx("coin_earned")
		SaveManager.set_upgrade_level(upgrade_id, current_level + 1)
		_update_coins_display()
		_update_upgrade_display()


func _on_level_selected(index: int) -> void:
	AudioManager.play_sfx("ui_click")
	_selected_theme_id = str(level_selector.get_item_metadata(index))
	SaveManager.selected_theme_id = _selected_theme_id
	SaveManager.save_data()


func _on_start_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.start_game()


func _on_menu_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.go_to_menu()


func _on_data_changed() -> void:
	_update_coins_display()
	_selected_theme_id = SaveManager.selected_theme_id
	_update_level_selector()
