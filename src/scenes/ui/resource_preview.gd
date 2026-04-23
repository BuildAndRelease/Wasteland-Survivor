extends Control
## Resource preview page: inspect design assets and enemy 4-direction walk animations.

const DIRECTIONS: Array[String] = ["south", "east", "north", "west"]
const ENEMY_IDS: Array[String] = ["walker", "mutant_dog", "acid_bug", "iron_giant", "exploder", "boss_ash_behemoth"]
const OBJECT_IDS: Array[String] = ["dead_tree", "large_rock", "metal_debris", "ruined_wall", "wrecked_car"]
const PICKUP_IDS: Array[String] = ["bullet", "health_pack", "scrap_coin", "xp_gem"]
const TILE_COUNT: int = 16
const WALK_FRAME_INTERVAL: float = 0.12

var _theme_id: String = ""
var _theme_selector: OptionButton
var _scroll_content: VBoxContainer
var _animated_previews: Array[Dictionary] = []


func _ready() -> void:
	GameManager.set_state(GameManager.State.MAIN_MENU)
	_build_ui()
	_rebuild_content()


func _process(delta: float) -> void:
	for i in range(_animated_previews.size()):
		var item: Dictionary = _animated_previews[i]
		var rect: TextureRect = item.get("rect")
		var texture: Texture2D = item.get("texture")
		var hframes: int = item.get("hframes", 1)
		var elapsed: float = item.get("elapsed", 0.0) + delta
		if not is_instance_valid(rect) or texture == null or hframes <= 0:
			continue
		if elapsed < WALK_FRAME_INTERVAL:
			item["elapsed"] = elapsed
			_animated_previews[i] = item
			continue
		elapsed -= WALK_FRAME_INTERVAL
		var frame: int = int(item.get("frame", 0)) + 1
		frame %= hframes
		item["frame"] = frame
		item["elapsed"] = elapsed
		rect.texture = _build_frame_texture(texture, hframes, frame)
		_animated_previews[i] = item


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.06, 0.08, 0.1, 1.0)
	add_child(bg)

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 24.0
	root.offset_top = 20.0
	root.offset_right = -24.0
	root.offset_bottom = -20.0
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	root.add_child(top_bar)

	var title := Label.new()
	title.text = _txt("资源预览 / 动画检视", "Asset Preview / Animation Inspector")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(title)

	var theme_label := Label.new()
	theme_label.text = _txt("主题", "Theme")
	top_bar.add_child(theme_label)

	_theme_selector = OptionButton.new()
	_theme_selector.custom_minimum_size = Vector2(240, 40)
	_theme_selector.add_item(_txt("默认废土", "Default Wasteland"))
	_theme_selector.set_item_metadata(0, "")
	_theme_selector.add_item(_txt("冰封废土", "Frozen Wasteland"))
	_theme_selector.set_item_metadata(1, GameManager.THEME_FROZEN_WASTELAND)
	_theme_selector.add_item(_txt("地狱熔炉", "Hell Furnace"))
	_theme_selector.set_item_metadata(2, GameManager.THEME_HELL_FURNACE)
	_theme_selector.item_selected.connect(_on_theme_selected)
	top_bar.add_child(_theme_selector)

	var camp_button := Button.new()
	camp_button.text = _txt("进入营地", "Camp")
	camp_button.custom_minimum_size = Vector2(120, 40)
	camp_button.pressed.connect(_on_camp_pressed)
	top_bar.add_child(camp_button)

	var menu_button := Button.new()
	menu_button.text = _txt("主菜单", "Menu")
	menu_button.custom_minimum_size = Vector2(120, 40)
	menu_button.pressed.connect(_on_menu_pressed)
	top_bar.add_child(menu_button)

	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = _txt(
		"这里会展示当前主题下的资源总览，并循环播放每个怪物四个方向的 walk 动画。若主题资源缺失，会自动回退到默认废土素材，并在卡片上标注来源。",
		"This page shows the current theme's asset coverage and loops each enemy's 4-direction walk animation. Missing themed resources automatically fall back to default wasteland sprites, and cards label the source."
	)
	root.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_scroll_content = VBoxContainer.new()
	_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_content.add_theme_constant_override("separation", 18)
	scroll.add_child(_scroll_content)


func _rebuild_content() -> void:
	_animated_previews.clear()
	for child in _scroll_content.get_children():
		child.queue_free()

	_add_theme_summary_section()
	_add_static_assets_section(_txt("角色资源", "Character Assets"), _build_character_entries(), 4)
	_add_static_assets_section(_txt("怪物立绘", "Enemy Sprites"), _build_enemy_entries(), 3)
	_add_enemy_walk_section()
	_add_static_assets_section(_txt("场景物件", "World Objects"), _build_object_entries(), 5)
	_add_static_assets_section(_txt("拾取物", "Pickups"), _build_pickup_entries(), 4)
	_add_static_assets_section(_txt("地块 Tiles", "Tileset"), _build_tile_entries(), 4)


func _add_theme_summary_section() -> void:
	var panel := _make_section_panel(_txt("主题信息", "Theme Info"))
	var body: VBoxContainer = panel.get_meta("body")

	var theme_name := _get_theme_display_name(_theme_id)
	var status := Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = _txt("当前主题：%s" % theme_name, "Current theme: %s" % theme_name)
	body.add_child(status)

	if _theme_id == "":
		var default_note := Label.new()
		default_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		default_note.text = _txt(
			"默认废土会直接读取基础 sprites。",
			"Default wasteland reads the base sprite set directly."
		)
		body.add_child(default_note)
		return

	var manifest_path := "res://assets/sprites/themes/%s/theme_manifest.json" % _theme_id
	var manifest_label := Label.new()
	manifest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	manifest_label.text = _txt("Manifest：%s" % manifest_path, "Manifest: %s" % manifest_path)
	body.add_child(manifest_label)

	var manifest := _load_theme_manifest(manifest_path)
	if manifest.is_empty():
		var missing := Label.new()
		missing.text = _txt("未找到 theme manifest。", "Theme manifest not found.")
		body.add_child(missing)
		return

	var notes: Array = manifest.get("notes", [])
	if not notes.is_empty():
		var notes_title := Label.new()
		notes_title.text = _txt("备注", "Notes")
		body.add_child(notes_title)
		for note in notes:
			var note_label := Label.new()
			note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			note_label.text = "• %s" % str(note)
			body.add_child(note_label)


func _add_static_assets_section(title: String, entries: Array[Dictionary], columns: int) -> void:
	var panel := _make_section_panel(title)
	var body: VBoxContainer = panel.get_meta("body")
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	body.add_child(grid)

	for entry in entries:
		grid.add_child(_create_static_card(entry))


func _add_enemy_walk_section() -> void:
	var panel := _make_section_panel(_txt("怪物四方向 Walk 动画", "Enemy 4-Direction Walks"))
	var body: VBoxContainer = panel.get_meta("body")

	for enemy_id in ENEMY_IDS:
		var row_panel := PanelContainer.new()
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(row_panel)

		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row_panel.add_child(row)

		var title := Label.new()
		title.text = _get_enemy_display_name(enemy_id)
		row.add_child(title)

		var dir_grid := GridContainer.new()
		dir_grid.columns = 4
		dir_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dir_grid.add_theme_constant_override("h_separation", 10)
		dir_grid.add_theme_constant_override("v_separation", 10)
		row.add_child(dir_grid)

		for direction in DIRECTIONS:
			var card := PanelContainer.new()
			card.custom_minimum_size = Vector2(200, 170)
			dir_grid.add_child(card)

			var vbox := VBoxContainer.new()
			vbox.add_theme_constant_override("separation", 6)
			card.add_child(vbox)

			var dir_label := Label.new()
			dir_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dir_label.text = _get_direction_label(direction)
			vbox.add_child(dir_label)

			var center := CenterContainer.new()
			center.custom_minimum_size = Vector2(0, 110)
			vbox.add_child(center)

			var tex_rect := TextureRect.new()
			tex_rect.custom_minimum_size = Vector2(96, 96)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			center.add_child(tex_rect)

			var resolved := _resolve_theme_asset(
				"enemies/walk/%s_walk_%s.png" % [enemy_id, direction],
				"enemies/walk/%s_walk_%s.png" % [enemy_id, direction]
			)
			_register_walk_preview(tex_rect, resolved)

			var source_label := Label.new()
			source_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			source_label.text = _format_source_text(resolved)
			vbox.add_child(source_label)


func _build_character_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for char_id in CampData.get_all_character_ids():
		var data: Dictionary = CampData.get_character(char_id)
		entries.append({
			"name": _get_localized_name(data, "name", "name_cn"),
			"path": "res://assets/sprites/player/%s.png" % char_id,
			"status": "default",
		})
	return entries


func _build_enemy_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for enemy_id in ENEMY_IDS:
		var resolved := _resolve_theme_asset("enemies/%s.png" % enemy_id, "enemies/%s.png" % enemy_id)
		entries.append({
			"name": _get_enemy_display_name(enemy_id),
			"path": resolved.get("path", ""),
			"status": resolved.get("status", "missing"),
		})
	return entries


func _build_object_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for object_id in OBJECT_IDS:
		var resolved := _resolve_theme_asset("objects/%s.png" % object_id, "objects/%s.png" % object_id)
		entries.append({
			"name": object_id,
			"path": resolved.get("path", ""),
			"status": resolved.get("status", "missing"),
		})
	return entries


func _build_pickup_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for pickup_id in PICKUP_IDS:
		entries.append({
			"name": pickup_id,
			"path": "res://assets/sprites/pickups/%s.png" % pickup_id,
			"status": "default",
		})
	return entries


func _build_tile_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for i in range(TILE_COUNT):
		var resolved := _resolve_theme_asset("tileset/tile_%d.png" % i, "tileset/tile_%d.png" % i)
		entries.append({
			"name": "tile_%d" % i,
			"path": resolved.get("path", ""),
			"status": resolved.get("status", "missing"),
		})
	return entries


func _create_static_card(entry: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 220)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.text = str(entry.get("name", "Unknown"))
	vbox.add_child(title)

	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(0, 130)
	vbox.add_child(center)

	var path := str(entry.get("path", ""))
	if path != "" and ResourceLoader.exists(path):
		var rect := TextureRect.new()
		rect.custom_minimum_size = Vector2(96, 96)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.texture = load(path)
		center.add_child(rect)
	else:
		var missing := Label.new()
		missing.text = _txt("缺失", "Missing")
		center.add_child(missing)

	var source := Label.new()
	source.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	source.text = _format_source_text(entry)
	vbox.add_child(source)

	return card


func _register_walk_preview(rect: TextureRect, resolved: Dictionary) -> void:
	var path := str(resolved.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	var texture: Texture2D = load(path)
	if texture == null:
		return
	var frame_size: int = texture.get_height()
	var hframes: int = 1
	if frame_size > 0:
		hframes = maxi(1, texture.get_width() / frame_size)
	rect.texture = _build_frame_texture(texture, hframes, 0)
	_animated_previews.append({
		"rect": rect,
		"texture": texture,
		"hframes": hframes,
		"frame": 0,
		"elapsed": 0.0,
	})


func _build_frame_texture(sheet: Texture2D, hframes: int, frame: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var frame_width: int = sheet.get_width() / maxi(1, hframes)
	var frame_height: int = sheet.get_height()
	atlas.region = Rect2(frame_width * frame, 0, frame_width, frame_height)
	return atlas


func _resolve_theme_asset(theme_relative: String, fallback_relative: String) -> Dictionary:
	if _theme_id != "":
		var themed_path := "res://assets/sprites/themes/%s/%s" % [_theme_id, theme_relative]
		if ResourceLoader.exists(themed_path):
			return {"path": themed_path, "status": "themed"}
	var fallback_path := "res://assets/sprites/%s" % fallback_relative
	if ResourceLoader.exists(fallback_path):
		return {"path": fallback_path, "status": "default"}
	return {"path": "", "status": "missing"}


func _load_theme_manifest(manifest_path: String) -> Dictionary:
	if not FileAccess.file_exists(manifest_path):
		return {}
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return {}
	var raw := file.get_as_text()
	var parsed = JSON.parse_string(raw)
	return parsed if parsed is Dictionary else {}


func _make_section_panel(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_content.add_child(panel)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	panel.add_child(body)
	panel.set_meta("body", body)

	var title_label := Label.new()
	title_label.text = title
	body.add_child(title_label)

	return panel


func _get_enemy_display_name(enemy_id: String) -> String:
	if enemy_id == "boss_ash_behemoth":
		match _theme_id:
			GameManager.THEME_FROZEN_WASTELAND:
				return Locale.t("boss_name_frozen")
			GameManager.THEME_HELL_FURNACE:
				return Locale.t("boss_name_hell")
			_:
				return Locale.t("boss_name")

	for enemy_type in EnemyData.ENEMY_TYPES.keys():
		var data: Dictionary = EnemyData.ENEMY_TYPES[enemy_type]
		if data.get("id", "") == enemy_id:
			return _get_localized_name(data, "name", "name_cn")
	return enemy_id


func _get_localized_name(data: Dictionary, en_key: String, zh_key: String) -> String:
	if Locale.is_zh():
		return str(data.get(zh_key, data.get(en_key, "")))
	return str(data.get(en_key, data.get(zh_key, "")))


func _get_theme_display_name(theme_id: String) -> String:
	match theme_id:
		GameManager.THEME_FROZEN_WASTELAND:
			return _txt("冰封废土", "Frozen Wasteland")
		GameManager.THEME_HELL_FURNACE:
			return _txt("地狱熔炉", "Hell Furnace")
		_:
			return _txt("默认废土", "Default Wasteland")


func _get_direction_label(direction: String) -> String:
	match direction:
		"south":
			return _txt("南 / South", "South")
		"east":
			return _txt("东 / East", "East")
		"north":
			return _txt("北 / North", "North")
		"west":
			return _txt("西 / West", "West")
		_:
			return direction


func _format_source_text(entry: Dictionary) -> String:
	var status := str(entry.get("status", "missing"))
	match status:
		"themed":
			return _txt("来源：主题资源", "Source: themed")
		"default":
			return _txt("来源：默认资源", "Source: default")
		_:
			return _txt("来源：缺失", "Source: missing")


func _txt(zh: String, en: String) -> String:
	return zh if Locale.is_zh() else en


func _on_theme_selected(index: int) -> void:
	AudioManager.play_sfx("ui_click")
	_theme_id = str(_theme_selector.get_item_metadata(index))
	_rebuild_content()


func _on_menu_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.go_to_menu()


func _on_camp_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	GameManager.go_to_camp()
