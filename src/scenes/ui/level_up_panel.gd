extends CanvasLayer
## Level-up skill selection: pauses game, shows 3 skill choices.
## Uses SkillManager for choice generation and skill application.

@onready var skill_btn_1: Button = $Content/SkillContainer/SkillButton1
@onready var skill_btn_2: Button = $Content/SkillContainer/SkillButton2
@onready var skill_btn_3: Button = $Content/SkillContainer/SkillButton3

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
				label = "★ %s\n%s" % [data.get("name", ""), data.get("description", "")]
			elif choice.is_combo:
				label = "%s [COMBO]\n%s" % [data.name, data.description]
			else:
				var level_data: Dictionary = SkillData.get_level_data(choice.skill_id, level)
				var lv_text: String = "Lv.%d" % level
				var desc: String = level_data.get("desc", data.description) if not level_data.is_empty() else data.description
				label = "%s (%s)\n%s" % [data.name, lv_text, desc]
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
