extends Control
## Main menu: title screen with start button. Navigates to Camp screen.

@onready var title_label: Label = $VBoxContainer/Title
@onready var subtitle_label: Label = $VBoxContainer/Subtitle
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var preview_button: Button = $VBoxContainer/PreviewButton
@onready var lang_button: Button = $VBoxContainer/LangButton


func _ready() -> void:
	GameManager.set_state(GameManager.State.MAIN_MENU)
	if not preview_button.pressed.is_connected(_on_preview_pressed):
		preview_button.pressed.connect(_on_preview_pressed)
	if not lang_button.pressed.is_connected(_on_lang_pressed):
		lang_button.pressed.connect(_on_lang_pressed)
	_update_texts()


func _update_texts() -> void:
	title_label.text = Locale.t("title")
	subtitle_label.text = Locale.t("subtitle")
	start_button.text = Locale.t("play")
	preview_button.text = Locale.t("asset_preview")
	lang_button.text = Locale.t("language")


func _on_start_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.go_to_camp()


func _on_preview_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.go_to_resource_preview()


func _on_lang_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	Locale.toggle()
	_update_texts()
