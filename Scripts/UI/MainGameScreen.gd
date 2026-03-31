@tool
extends Control

const GameThemeScript := preload("res://Scripts/UI/GameTheme.gd")
const UiAtlasWidgetsScript := preload("res://Scripts/UI/UiAtlasWidgets.gd")
const GameWorldScene := preload("res://Scenes/Battle/GameWorld.tscn")
const UpgradePanelScene := preload("res://Scenes/UI/UpgradePanel.tscn")

const GROUND_TEXTURE_PATH := "res://Assets/Art/Castle/ground.png"
const TITLE_TEXT := "IDLE KING: GROUND ZERO"
const VIEWPORT_SIZE := Vector2i(896, 448)
const STAGE_RECT := Rect2(92.0, 276.0, 896.0, 448.0)

const COLOR_TEXT := Color("f4eedc")
const COLOR_MUTED := Color("d4c3a0")

@onready var ground_background: TextureRect = $GroundBackground
@onready var top_bar: Control = $TopBar
@onready var battle_frame: Control = $BattleFrame
@onready var battle_overlay: Control = $BattleOverlay
@onready var bottom_ui: Control = $BottomUI

var wave_label: Label
var enemy_label: Label
var left_hp_bar: TextureProgressBar
var right_hp_bar: TextureProgressBar
var mute_button: Button
var game_world: GameWorld
var _is_muted: bool = false


func _ready() -> void:
	GameThemeScript.apply_to(self)
	_apply_ground_texture()
	_layout_root_nodes()
	_build_top_bar()
	_build_battle_frame()
	_build_bottom_ui()
	_sync_mute_button()

	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_signal("mute_changed"):
		audio_manager.connect("mute_changed", Callable(self, "_on_mute_changed"))


func _layout_root_nodes() -> void:
	top_bar.anchor_left = 0.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_left = 20.0
	top_bar.offset_top = 14.0
	top_bar.offset_right = -20.0
	top_bar.offset_bottom = 148.0

	battle_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	battle_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	bottom_ui.anchor_left = 0.0
	bottom_ui.anchor_top = 1.0
	bottom_ui.anchor_right = 1.0
	bottom_ui.anchor_bottom = 1.0
	bottom_ui.offset_left = 20.0
	bottom_ui.offset_top = -188.0
	bottom_ui.offset_right = -20.0
	bottom_ui.offset_bottom = -16.0


func _apply_ground_texture() -> void:
	var texture: Texture2D = _load_texture_from_image_file(GROUND_TEXTURE_PATH)
	ground_background.texture = texture
	ground_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	ground_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground_background.stretch_mode = TextureRect.STRETCH_SCALE
	ground_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _build_top_bar() -> void:
	_clear_children(top_bar)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 10)
	top_bar.add_child(column)

	var title_panel := UiAtlasWidgetsScript.make_panel("dark", Vector2(0, 76))
	column.add_child(title_panel)

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 10)
	title_panel.add_child(title_row)

	title_row.add_child(UiAtlasWidgetsScript.make_icon("sprite165", 1.5))

	var title := Label.new()
	title.text = TITLE_TEXT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameThemeScript.apply_display_font(title, 28)
	title.add_theme_color_override("font_color", Color("d4a74d"))
	title.add_theme_color_override("font_outline_color", Color("1a0f0f"))
	title.add_theme_constant_override("outline_size", 2)
	title_row.add_child(title)

	var right_icon := UiAtlasWidgetsScript.make_icon("sprite165", 1.5)
	title_row.add_child(right_icon)

	var resource_panel := UiAtlasWidgetsScript.make_panel("hud", Vector2(0, 62))
	column.add_child(resource_panel)

	var resource_row := HBoxContainer.new()
	resource_row.add_theme_constant_override("separation", 18)
	resource_panel.add_child(resource_row)
	resource_row.add_child(_build_stat_chip("Gold", "38,268", "sprite164"))
	resource_row.add_child(_build_stat_chip("Gems", "100", "sprite178"))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_row.add_child(spacer)

	mute_button = UiAtlasWidgetsScript.make_button("large", "MUTE")
	mute_button.custom_minimum_size = Vector2(176, 46)
	mute_button.pressed.connect(_toggle_mute)
	resource_row.add_child(mute_button)


func _build_battle_frame() -> void:
	_clear_children(battle_frame)
	_clear_children(battle_overlay)

	var viewport_container := SubViewportContainer.new()
	viewport_container.name = "SubViewportContainer"
	viewport_container.position = STAGE_RECT.position
	viewport_container.size = STAGE_RECT.size
	viewport_container.stretch = false
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_frame.add_child(viewport_container)

	var viewport := SubViewport.new()
	viewport.name = "SubViewport"
	viewport.size = VIEWPORT_SIZE
	viewport.transparent_bg = true
	viewport.handle_input_locally = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport_container.add_child(viewport)

	var world_instance := GameWorldScene.instantiate() as GameWorld
	world_instance.name = "GameWorld"
	viewport.add_child(world_instance)
	game_world = world_instance

	if game_world != null:
		game_world.wave_changed.connect(_on_wave_changed)
		game_world.hero_health_changed.connect(_on_hero_health_changed)
		game_world.enemy_health_changed.connect(_on_enemy_health_changed)

	wave_label = Label.new()
	wave_label.text = "Wave 1"
	wave_label.position = Vector2(STAGE_RECT.position.x, STAGE_RECT.position.y - 64.0)
	wave_label.size = Vector2(STAGE_RECT.size.x, 32.0)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameThemeScript.apply_display_font(wave_label, 30)
	wave_label.add_theme_color_override("font_color", COLOR_TEXT)
	wave_label.add_theme_color_override("font_outline_color", Color("1a0f0f"))
	wave_label.add_theme_constant_override("outline_size", 2)
	battle_overlay.add_child(wave_label)

	enemy_label = Label.new()
	enemy_label.text = "Bone Scout"
	enemy_label.position = Vector2(STAGE_RECT.position.x, STAGE_RECT.position.y - 34.0)
	enemy_label.size = Vector2(STAGE_RECT.size.x, 24.0)
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_label.add_theme_font_size_override("font_size", 18)
	enemy_label.add_theme_color_override("font_color", COLOR_MUTED)
	enemy_label.add_theme_color_override("font_outline_color", Color("1a0f0f"))
	enemy_label.add_theme_constant_override("outline_size", 2)
	battle_overlay.add_child(enemy_label)

	var left_block := _build_health_block("King HP")
	left_block.position = Vector2(STAGE_RECT.position.x + 6.0, STAGE_RECT.position.y - 6.0)
	battle_overlay.add_child(left_block)
	left_hp_bar = left_block.get_node("Bar") as TextureProgressBar

	var right_block := _build_health_block("Enemy HP")
	right_block.position = Vector2(STAGE_RECT.position.x + STAGE_RECT.size.x - 246.0, STAGE_RECT.position.y - 6.0)
	battle_overlay.add_child(right_block)
	right_hp_bar = right_block.get_node("Bar") as TextureProgressBar


func _build_bottom_ui() -> void:
	_clear_children(bottom_ui)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 6)
	bottom_ui.add_child(column)

	var upgrade_panel := UpgradePanelScene.instantiate()
	upgrade_panel.custom_minimum_size = Vector2(0.0, 92.0)
	upgrade_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(upgrade_panel)

	var nav_panel := UiAtlasWidgetsScript.make_panel("dark", Vector2(0, 74))
	column.add_child(nav_panel)

	var nav_row := HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 8)
	nav_panel.add_child(nav_row)

	var nav_defs: Array[Dictionary] = [
		{"label": "GACHA", "size": "medium"},
		{"label": "UPGRADES", "size": "large"},
		{"label": "TAP", "size": "medium"},
		{"label": "ROSTER", "size": "large"},
		{"label": "EVENTS", "size": "large"}
	]

	for nav_def in nav_defs:
		var button := UiAtlasWidgetsScript.make_button(String(nav_def["size"]), String(nav_def["label"]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav_row.add_child(button)


func _build_stat_chip(title_text: String, value_text: String, icon_sprite: String) -> Control:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 8)
	if not icon_sprite.is_empty():
		chip.add_child(UiAtlasWidgetsScript.make_icon(icon_sprite, 1.0))

	var label := Label.new()
	label.text = "%s  %s" % [title_text, value_text]
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_color_override("font_outline_color", Color("1a0f0f"))
	label.add_theme_constant_override("outline_size", 2)
	chip.add_child(label)
	return chip


func _build_health_block(title_text: String) -> Control:
	var block := VBoxContainer.new()
	block.custom_minimum_size = Vector2(240, 48)
	block.add_theme_constant_override("separation", 3)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title.add_theme_color_override("font_outline_color", Color("1a0f0f"))
	title.add_theme_constant_override("outline_size", 2)
	block.add_child(title)

	var bar := UiAtlasWidgetsScript.make_progress_bar(1.0, "hp_fill")
	bar.name = "Bar"
	block.add_child(bar)

	return block


func _toggle_mute() -> void:
	if mute_button == null:
		return
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("toggle_mute"):
		_is_muted = bool(audio_manager.call("toggle_mute"))
	else:
		_is_muted = not _is_muted
	_sync_mute_button()


func _on_mute_changed(is_muted: bool) -> void:
	_is_muted = is_muted
	_sync_mute_button()


func _sync_mute_button() -> void:
	if mute_button == null:
		return
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		_is_muted = bool(audio_manager.get("is_muted"))
	mute_button.text = "MUTED" if _is_muted else "MUTE"


func _on_wave_changed(wave: int, enemy_name_text: String) -> void:
	if wave_label != null:
		wave_label.text = "Wave %d" % wave
	if enemy_label != null:
		enemy_label.text = enemy_name_text


func _on_hero_health_changed(ratio: float) -> void:
	if left_hp_bar != null:
		left_hp_bar.value = ratio * 100.0


func _on_enemy_health_changed(ratio: float) -> void:
	if right_hp_bar != null:
		right_hp_bar.value = ratio * 100.0


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _load_texture_from_image_file(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported: Texture2D = load(path) as Texture2D
		if imported != null:
			return imported

	var image: Image = Image.load_from_file(path)
	if image == null or image.is_empty():
		push_warning("Unable to load main background image at %s." % path)
		return null

	return ImageTexture.create_from_image(image)
