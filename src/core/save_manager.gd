extends Node
## Persistent save data manager (autoload singleton).
## Uses ConfigFile for native builds and JavaScriptBridge for Web exports.
## Stores scrap coins, permanent upgrade levels, and unlocked characters.

signal data_changed

const SAVE_PATH: String = "user://save_data.cfg"
const SAVE_SECTION: String = "save"

## Current scrap coin balance (persistent currency).
var scrap_coins: int = 0

## Permanent upgrade levels: { upgrade_id: int level (0 = not purchased) }.
var upgrade_levels: Dictionary = {}

## Unlocked character ids: { character_id: bool }.
var unlocked_characters: Dictionary = {}

## Currently selected character id.
var selected_character: String = "survivor"

## Currently selected theme/level id for next run.
var selected_theme_id: String = ""

var _is_web: bool = false


func _ready() -> void:
	_is_web = OS.has_feature("web")
	load_data()


## Save all persistent data to disk or localStorage.
func save_data() -> void:
	if _is_web:
		_save_web()
	else:
		_save_native()
	data_changed.emit()


## Load all persistent data from disk or localStorage.
func load_data() -> void:
	if _is_web:
		_load_web()
	else:
		_load_native()


## Add scrap coins and save immediately.
func add_scrap_coins(amount: int) -> void:
	scrap_coins += amount
	save_data()


## Spend scrap coins. Returns true if successful, false if insufficient funds.
func spend_scrap_coins(amount: int) -> bool:
	if scrap_coins < amount:
		return false
	scrap_coins -= amount
	save_data()
	return true


## Get upgrade level for a given upgrade id (0 = not purchased).
func get_upgrade_level(upgrade_id: String) -> int:
	return upgrade_levels.get(upgrade_id, 0)


## Set upgrade level and save.
func set_upgrade_level(upgrade_id: String, level: int) -> void:
	upgrade_levels[upgrade_id] = level
	save_data()


## Check if a character is unlocked.
func is_character_unlocked(character_id: String) -> bool:
	if character_id == "survivor":
		return true
	return unlocked_characters.get(character_id, false)


## Unlock a character and save.
func unlock_character(character_id: String) -> void:
	unlocked_characters[character_id] = true
	save_data()


## Select a character for the next run.
func select_character(character_id: String) -> void:
	selected_character = character_id
	save_data()


## Reset all save data (for testing / new game).
func reset_all() -> void:
	scrap_coins = 0
	upgrade_levels.clear()
	unlocked_characters.clear()
	selected_character = "survivor"
	selected_theme_id = ""
	save_data()


# --- Native save (ConfigFile) ---

func _save_native() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SAVE_SECTION, "scrap_coins", scrap_coins)
	cfg.set_value(SAVE_SECTION, "upgrade_levels", upgrade_levels)
	cfg.set_value(SAVE_SECTION, "unlocked_characters", unlocked_characters)
	cfg.set_value(SAVE_SECTION, "selected_character", selected_character)
	cfg.set_value(SAVE_SECTION, "selected_theme_id", selected_theme_id)
	cfg.save(SAVE_PATH)


func _load_native() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	scrap_coins = cfg.get_value(SAVE_SECTION, "scrap_coins", 0)
	upgrade_levels = cfg.get_value(SAVE_SECTION, "upgrade_levels", {})
	unlocked_characters = cfg.get_value(SAVE_SECTION, "unlocked_characters", {})
	selected_character = cfg.get_value(SAVE_SECTION, "selected_character", "survivor")
	selected_theme_id = cfg.get_value(SAVE_SECTION, "selected_theme_id", "")


# --- Web save (JavaScriptBridge + localStorage) ---

func _save_web() -> void:
	var data := {
		"scrap_coins": scrap_coins,
		"upgrade_levels": upgrade_levels,
		"unlocked_characters": unlocked_characters,
		"selected_character": selected_character,
		"selected_theme_id": selected_theme_id,
	}
	var json_str: String = JSON.stringify(data)
	JavaScriptBridge.eval("localStorage.setItem('wasteland_survivor_save', '%s')" % json_str.c_escape())


func _load_web() -> void:
	var result = JavaScriptBridge.eval("localStorage.getItem('wasteland_survivor_save')")
	if result == null or result == "":
		return
	var json := JSON.new()
	if json.parse(result) != OK:
		return
	var data: Dictionary = json.data
	scrap_coins = int(data.get("scrap_coins", 0))
	# Restore dictionaries from JSON (keys come back as strings)
	var raw_upgrades = data.get("upgrade_levels", {})
	upgrade_levels.clear()
	for key in raw_upgrades:
		upgrade_levels[str(key)] = int(raw_upgrades[key])
	var raw_chars = data.get("unlocked_characters", {})
	unlocked_characters.clear()
	for key in raw_chars:
		unlocked_characters[str(key)] = bool(raw_chars[key])
	selected_character = str(data.get("selected_character", "survivor"))
	selected_theme_id = str(data.get("selected_theme_id", ""))
