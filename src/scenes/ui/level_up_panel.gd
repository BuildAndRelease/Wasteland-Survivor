extends CanvasLayer
## Level-up skill selection: pauses game, shows 3 skill choices.

@onready var skill_btn_1: Button = $Content/SkillContainer/SkillButton1
@onready var skill_btn_2: Button = $Content/SkillContainer/SkillButton2
@onready var skill_btn_3: Button = $Content/SkillContainer/SkillButton3

var player_ref: Node2D = null
var current_choices: Array = []


func _ready() -> void:
	visible = false
	skill_btn_1.pressed.connect(_on_skill_pressed.bind(0))
	skill_btn_2.pressed.connect(_on_skill_pressed.bind(1))
	skill_btn_3.pressed.connect(_on_skill_pressed.bind(2))


func set_player(player: Node2D) -> void:
	player_ref = player


func show_panel() -> void:
	current_choices = SkillData.get_random_choices(3)
	_update_buttons()
	visible = true


func _update_buttons() -> void:
	var buttons: Array = [skill_btn_1, skill_btn_2, skill_btn_3]
	for i in current_choices.size():
		buttons[i].text = "%s\n%s" % [current_choices[i].name, current_choices[i].description]


func _on_skill_pressed(index: int) -> void:
	if index >= current_choices.size():
		return
	var skill_name: String = current_choices[index].name
	if is_instance_valid(player_ref) and player_ref.has_method("add_skill"):
		player_ref.add_skill(skill_name)
	visible = false
	GameManager.set_state(GameManager.State.GAMEPLAY)
