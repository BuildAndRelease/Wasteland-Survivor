extends CanvasLayer
## Level-up skill selection: pauses game, shows 3 skill choices.
## Uses SkillManager for choice generation and skill application.

@onready var skill_btn_1: Button = $Content/SkillContainer/SkillButton1
@onready var skill_btn_2: Button = $Content/SkillContainer/SkillButton2
@onready var skill_btn_3: Button = $Content/SkillContainer/SkillButton3
@onready var title_label: Label = $Content/TitleLabel
@onready var choose_label: Label = $Content/ChooseLabel

var skill_manager: SkillManager = null
var current_choices: Array = []


func _ready() -> void:
	_set_panel_visible(false)
	skill_btn_1.pressed.connect(_on_skill_pressed.bind(0))
	skill_btn_2.pressed.connect(_on_skill_pressed.bind(1))
	skill_btn_3.pressed.connect(_on_skill_pressed.bind(2))


## CanvasLayer has no "visible" property — toggle child nodes instead.
func _set_panel_visible(show: bool) -> void:
	for child in get_children():
		if child is Node:
			child.visible = show


func set_skill_manager(manager: SkillManager) -> void:
	skill_manager = manager


func show_panel() -> void:
	if skill_manager:
		current_choices = skill_manager.generate_level_up_choices(3)
	# Update localized static labels
	title_label.text = Locale.t("level_up_title")
	choose_label.text = Locale.t("level_up_choose")
	_update_buttons()
	_set_panel_visible(true)


func _update_buttons() -> void:
	var buttons: Array = [skill_btn_1, skill_btn_2, skill_btn_3]
	for i: int in buttons.size():
		if i < current_choices.size():
			var choice: Dictionary = current_choices[i]
			var data: Dictionary = choice.data
			var level: int = choice.level

			var label: String = ""
			if choice.get("is_bonus", false):
				# Generic bonus pick (all skills maxed)
				var bname: String = data.get("name_cn", data.get("name", "")) if Locale.is_zh() else data.get("name", "")
				var bdesc: String = data.get("description_cn", data.get("description", "")) if Locale.is_zh() else data.get("description", "")
				# Use locale keys for bonus names/descs
				var bonus_key: String = choice.skill_id.replace("_bonus_", "bonus_")
				var loc_name: String = Locale.t(bonus_key + "_name")
				var loc_desc: String = Locale.t(bonus_key + "_desc")
				if loc_name != bonus_key + "_name":
					bname = loc_name
				if loc_desc != bonus_key + "_desc":
					bdesc = loc_desc
				label = Locale.t("bonus_label") % [bname, bdesc]
			elif choice.is_combo:
				var cname: String = data.get("name_cn", data.name) if Locale.is_zh() else data.name
				var cdesc: String = data.get("description_cn", data.description) if Locale.is_zh() else data.description
				label = Locale.t("combo_label") % [cname, cdesc]
			else:
				var level_data: Dictionary = SkillData.get_level_data(choice.skill_id, level)
				var sname: String = data.get("name_cn", data.name) if Locale.is_zh() else data.name
				var desc: String = ""
				if not level_data.is_empty():
					desc = level_data.get("desc_cn", level_data.get("desc", data.description)) if Locale.is_zh() else level_data.get("desc", data.description)
				else:
					desc = data.get("description_cn", data.description) if Locale.is_zh() else data.description
				label = Locale.t("skill_label") % [sname, level, desc]
			buttons[i].text = label
			buttons[i].visible = true
		else:
			buttons[i].visible = false


func _on_skill_pressed(index: int) -> void:
	if index >= current_choices.size():
		return
	AudioManager.play_sfx("skill_pickup")
	var choice: Dictionary = current_choices[index]
	if skill_manager:
		skill_manager.add_skill(choice.skill_id)
	_set_panel_visible(false)
	GameManager.set_state(GameManager.State.GAMEPLAY)
