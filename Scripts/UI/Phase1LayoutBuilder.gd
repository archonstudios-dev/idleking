# Builds the Phase 1 main screen scaffold so it can be reused in runtime and editor tooling.
extends RefCounted
class_name Phase1LayoutBuilder

const GameThemeScript := preload("res://Scripts/UI/GameTheme.gd")
const UiAtlasScript := preload("res://Scripts/UI/UiAtlas.gd")

const TITLE_TEXT := "IDLE KING: GROUND ZERO"

const COLOR_BG := Color("0b1222")
const COLOR_BG_SECONDARY := Color("18233b")
const COLOR_PANEL := Color("1f1820")
const COLOR_PANEL_ALT := Color("2d2216")
const COLOR_ACCENT := Color("d7a94b")
const COLOR_TEXT := Color("f4eedc")
const COLOR_MUTED := Color("c8bc9b")
const COLOR_HP_BG := Color("3c1d22")
const COLOR_HP_FILL := Color("c84f59")
const COLOR_TAP := Color("f0bf57")

const KING_TEXTURE := "res://Assets/Art/King/Medieval King Pack 2/Sprites/Idle.png"
const ENEMY_TEXTURE := "res://Assets/Art/Enemies/Evil Wizard/Sprites/Idle.png"
const KING_ATTACK_TEXTURE := "res://Assets/Art/King/Medieval King Pack 2/Sprites/Attack1.png"
const ENEMY_ATTACK_TEXTURE := "res://Assets/Art/Enemies/Evil Wizard/Sprites/Attack.png"
const STAGE_TEXTURE := "res://Assets/Art/Castle/ground.png"
const PANEL_SLICE := 8
const BUTTON_SLICE := 8


static func build(root: Control, owner: Node = null) -> void:
	# Recreates the generated UI tree with stable node names for scripts.
	var existing := root.get_node_or_null("GeneratedUI")
	if existing != null:
		root.remove_child(existing)
		existing.free()

	root.mouse_filter = Control.MOUSE_FILTER_PASS

	var generated := Control.new()
	generated.name = "GeneratedUI"
	_full_rect(generated)
	_attach(root, generated, owner)

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = COLOR_BG
	_full_rect(backdrop)
	_attach(generated, backdrop, owner)

	var combat_background := TextureRect.new()
	combat_background.name = "BackdropTexture"
	combat_background.texture = _load_texture_or_null(STAGE_TEXTURE)
	combat_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	combat_background.modulate = Color(1, 1, 1, 0.36)
	combat_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	combat_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_full_rect(combat_background)
	_attach(generated, combat_background, owner)

	var overlay := ColorRect.new()
	overlay.name = "BackdropOverlay"
	overlay.color = Color(0.05, 0.07, 0.12, 0.5)
	_full_rect(overlay)
	_attach(generated, overlay, owner)

	var safe_area := MarginContainer.new()
	safe_area.name = "SafeArea"
	_full_rect(safe_area)
	safe_area.add_theme_constant_override("margin_left", 24)
	safe_area.add_theme_constant_override("margin_top", 22)
	safe_area.add_theme_constant_override("margin_right", 24)
	safe_area.add_theme_constant_override("margin_bottom", 22)
	_attach(generated, safe_area, owner)

	var column := VBoxContainer.new()
	column.name = "MainColumn"
	column.add_theme_constant_override("separation", 16)
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_attach(safe_area, column, owner)

	_attach(column, _build_title_bar(owner), owner)
	_attach(column, _build_resource_bar(owner), owner)

	var combat_panel := _build_combat_panel(owner)
	combat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat_panel.size_flags_stretch_ratio = 1.65
	_attach(column, combat_panel, owner)

	_attach(column, _build_hero_slots(owner), owner)
	_attach(column, _build_selected_unit_panel(owner), owner)
	_attach(column, _build_status_label(owner), owner)
	_attach(column, _build_bottom_bar(owner), owner)
	_attach(generated, _build_upgrade_overlay(owner), owner)


static func _build_title_bar(owner: Node) -> Control:
	var panel := _make_panel("TitleBar", Vector2(0, 144), COLOR_BG_SECONDARY)
	var margin := _make_margin(14, 10, 14, 10)
	_attach(panel, margin, owner)

	var row := HBoxContainer.new()
	row.name = "TitleBarRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	_attach(margin, row, owner)

	_attach(row, _make_texture_icon("LeftSword", UiAtlasScript.icon_region(4, 5), Vector2(50, 50), false), owner)
	_attach(row, _make_texture_icon("TitleEmblem", UiAtlasScript.icon_region(1, 6), Vector2(58, 58), false), owner)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameThemeScript.apply_display_font(title, 44)
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attach(row, title, owner)

	attach(row, _make_texture_icon("RightSword", UiAtlasScript.icon_region(4, 5), Vector2(50, 50), true), owner)
	return panel


static func _build_resource_bar(owner: Node) -> Control:
	var panel := _make_panel("ResourceBar", Vector2(0, 126), COLOR_PANEL_ALT)
	var margin := _make_margin(16, 10, 16, 10)
	_attach(panel, margin, owner)

	var row := HBoxContainer.new()
	row.name = "ResourceRow"
	row.add_theme_constant_override("separation", 28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_attach(margin, row, owner)

	_attach(row, _make_resource_item("GoldDisplay", "GoldValueLabel", UiAtlasScript.icon_region(7, 10), "0", owner), owner)
	_attach(row, _make_resource_item("GemDisplay", "GemValueLabel", UiAtlasScript.icon_region(9, 11), "100", owner), owner)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attach(row, spacer, owner)

	var settings_button := Button.new()
	settings_button.name = "SettingsButton"
	settings_button.custom_minimum_size = Vector2(168, 74)
	settings_button.text = "SOUND"
	settings_button.icon = UiAtlasScript.ui_region(16, 1)
	settings_button.expand_icon = false
	settings_button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_button.focus_mode = Control.FOCUS_NONE
	settings_button.add_theme_font_size_override("font_size", 24)
	settings_button.add_theme_color_override("font_color", COLOR_TEXT)
	settings_button.clip_text = true
	_style_button(settings_button, false)
	_attach(row, settings_button, owner)

	return panel


static func _build_combat_panel(owner: Node) -> Control:
	var panel := _make_panel("CombatPanel", Vector2(0, 980), Color("18161d"))
	var margin := _make_margin(14, 16, 14, 12)
	_attach(panel, margin, owner)

	var arena := Control.new()
	arena.name = "CombatArena"
	arena.custom_minimum_size = Vector2(0, 870)
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_attach(margin, arena, owner)

	var stage_frame := PanelContainer.new()
	stage_frame.name = "CombatStageFrame"
	# Make the combat view read more like a centered "TV frame".
	stage_frame.anchor_left = 0.03
	stage_frame.anchor_top = 0.10
	stage_frame.anchor_right = 0.97
	stage_frame.anchor_bottom = 0.86
	stage_frame.clip_contents = true
	stage_frame.add_theme_stylebox_override("panel", UiAtlasScript.stylebox_from_ui(6, 0, 2, 2, 8, Color("6d412d"), Vector4(8, 8, 8, 8)))
	_attach(arena, stage_frame, owner)

	var stage_area := Control.new()
	stage_area.name = "CombatStageArea"
	_full_rect(stage_area)
	stage_area.clip_contents = true
	_attach(stage_frame, stage_area, owner)

	var castle_bg := TextureRect.new()
	castle_bg.name = "CastleBackgroundSprite"
	castle_bg.texture = _load_texture_or_null(STAGE_TEXTURE)
	castle_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	castle_bg.anchor_top = 0.42
	castle_bg.anchor_right = 1.0
	castle_bg.anchor_bottom = 1.46
	castle_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	castle_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	castle_bg.modulate = Color(1, 1, 1, 1)
	_attach(stage_area, castle_bg, owner)

	var depth_overlay := ColorRect.new()
	depth_overlay.name = "CombatDepthOverlay"
	depth_overlay.anchor_left = 0.0
	depth_overlay.anchor_top = 0.60
	depth_overlay.anchor_right = 1.0
	depth_overlay.anchor_bottom = 0.92
	depth_overlay.color = Color(0.08, 0.06, 0.08, 0.18)
	_attach(stage_area, depth_overlay, owner)

	var battle_lane := ColorRect.new()
	battle_lane.name = "CombatBattleLane"
	battle_lane.anchor_left = 0.02
	battle_lane.anchor_top = 0.77
	battle_lane.anchor_right = 0.98
	battle_lane.anchor_bottom = 0.93
	battle_lane.color = Color(0.28, 0.23, 0.12, 0.42)
	_attach(stage_area, battle_lane, owner)

	var battle_lane_edge := ColorRect.new()
	battle_lane_edge.name = "CombatBattleLaneEdge"
	battle_lane_edge.anchor_left = 0.02
	battle_lane_edge.anchor_top = 0.765
	battle_lane_edge.anchor_right = 0.98
	battle_lane_edge.anchor_bottom = 0.778
	battle_lane_edge.color = Color(0.86, 0.78, 0.52, 0.40)
	_attach(stage_area, battle_lane_edge, owner)

	var floor := ColorRect.new()
	floor.name = "CombatFloor"
	floor.anchor_left = 0.0
	floor.anchor_top = 0.87
	floor.anchor_right = 1.0
	floor.anchor_bottom = 1.0
	floor.color = Color("69712d")
	_attach(arena, floor, owner)

	var floor_highlight := ColorRect.new()
	floor_highlight.name = "CombatFloorHighlight"
	floor_highlight.anchor_left = 0.0
	floor_highlight.anchor_top = 0.865
	floor_highlight.anchor_right = 1.0
	floor_highlight.anchor_bottom = 0.878
	floor_highlight.color = Color(0.84, 0.79, 0.52, 0.55)
	_attach(arena, floor_highlight, owner)

	var info_column := VBoxContainer.new()
	info_column.name = "CombatInfoColumn"
	info_column.anchor_left = 0.12
	info_column.anchor_top = 0.00
	info_column.anchor_right = 0.88
	info_column.anchor_bottom = 0.14
	info_column.alignment = BoxContainer.ALIGNMENT_CENTER
	info_column.add_theme_constant_override("separation", 4)
	_attach(arena, info_column, owner)

	var wave_label := Label.new()
	wave_label.name = "WaveLabel"
	wave_label.text = "Wave 1"
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameThemeScript.apply_display_font(wave_label, 52)
	wave_label.add_theme_color_override("font_color", COLOR_TEXT)
	_attach(info_column, wave_label, owner)

	var enemy_name_label := Label.new()
	enemy_name_label.name = "EnemyNameLabel"
	enemy_name_label.text = "Goblin Raider"
	enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_name_label.add_theme_font_size_override("font_size", 34)
	enemy_name_label.add_theme_color_override("font_color", COLOR_MUTED)
	_attach(info_column, enemy_name_label, owner)

	var combat_sprite_layer := Control.new()
	combat_sprite_layer.name = "CombatSpriteLayer"
	combat_sprite_layer.anchor_right = 1.0
	combat_sprite_layer.anchor_bottom = 1.0
	_attach(stage_area, combat_sprite_layer, owner)

	var king_actor := Control.new()
	king_actor.name = "KingActor"
	king_actor.position = Vector2(440, 520)
	_attach(combat_sprite_layer, king_actor, owner)

	var king_shadow := ColorRect.new()
	king_shadow.name = "KingShadow"
	king_shadow.position = Vector2(-48, 42)
	king_shadow.size = Vector2(96, 12)
	king_shadow.color = Color(0, 0, 0, 0.28)
	_attach(king_actor, king_shadow, owner)

	var king_outline := Sprite2D.new()
	king_outline.name = "KingOutlineSprite"
	king_outline.scale = Vector2(1.42, 1.42)
	king_outline.modulate = Color(0.02, 0.02, 0.03, 0.72)
	king_outline.z_index = 1
	_attach(king_actor, king_outline, owner)

	var king_sprite := Sprite2D.new()
	king_sprite.name = "KingAnimatedSprite"
	king_sprite.scale = Vector2(1.24, 1.24)
	king_sprite.z_index = 2
	_attach(king_actor, king_sprite, owner)

	var king_hit_effect := ColorRect.new()
	king_hit_effect.name = "KingHitEffect"
	king_hit_effect.position = Vector2(-10, -30)
	king_hit_effect.size = Vector2(42, 42)
	king_hit_effect.color = Color(1.0, 0.88, 0.34, 0.0)
	king_hit_effect.visible = false
	_attach(king_actor, king_hit_effect, owner)

	var enemy_actor := Control.new()
	enemy_actor.name = "EnemyActor"
	enemy_actor.position = Vector2(650, 520)
	_attach(combat_sprite_layer, enemy_actor, owner)

	var enemy_shadow := ColorRect.new()
	enemy_shadow.name = "EnemyShadow"
	enemy_shadow.position = Vector2(-48, 42)
	enemy_shadow.size = Vector2(96, 12)
	enemy_shadow.color = Color(0, 0, 0, 0.28)
	_attach(enemy_actor, enemy_shadow, owner)

	var enemy_outline := Sprite2D.new()
	enemy_outline.name = "EnemyOutlineSprite"
	enemy_outline.scale = Vector2(1.38, 1.38)
	enemy_outline.modulate = Color(0.02, 0.02, 0.03, 0.72)
	enemy_outline.z_index = 1
	_attach(enemy_actor, enemy_outline, owner)

	var enemy_sprite := Sprite2D.new()
	enemy_sprite.name = "EnemyAnimatedSprite"
	enemy_sprite.scale = Vector2(1.18, 1.18)
	enemy_sprite.z_index = 2
	_attach(enemy_actor, enemy_sprite, owner)

	var enemy_hit_effect := ColorRect.new()
	enemy_hit_effect.name = "EnemyHitEffect"
	enemy_hit_effect.position = Vector2(-10, -30)
	enemy_hit_effect.size = Vector2(46, 46)
	enemy_hit_effect.color = Color(1.0, 0.35, 0.20, 0.0)
	enemy_hit_effect.visible = false
	_attach(enemy_actor, enemy_hit_effect, owner)

	var hp_row := HBoxContainer.new()
	hp_row.name = "CombatHpRow"
	hp_row.anchor_left = 0.0
	# Starts below the header labels so it doesn't visually collide at large font sizes.
	hp_row.anchor_top = 0.16
	hp_row.anchor_right = 1.0
	hp_row.anchor_bottom = 0.25
	hp_row.add_theme_constant_override("separation", 64)
	hp_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_attach(arena, hp_row, owner)

	var king_side := _build_unit_side("KingSide", "King HP", "KingHpBar", owner)
	king_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attach(hp_row, king_side, owner)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(120, 0)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attach(hp_row, spacer, owner)

	var enemy_side := _build_unit_side("EnemySide", "Enemy HP", "EnemyHpBar", owner)
	enemy_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attach(hp_row, enemy_side, owner)

	var tap_prompt_panel := _make_panel("TapPromptPanel", Vector2(0, 112), Color(0.19, 0.12, 0.06, 0.94))
	tap_prompt_panel.anchor_left = 0.28
	tap_prompt_panel.anchor_top = 0.90
	tap_prompt_panel.anchor_right = 0.72
	tap_prompt_panel.anchor_bottom = 0.985
	_attach(arena, tap_prompt_panel, owner)

	var prompt_margin := _make_margin(14, 10, 14, 10)
	_attach(tap_prompt_panel, prompt_margin, owner)

	var prompt_column := VBoxContainer.new()
	prompt_column.name = "CombatCenterColumn"
	prompt_column.alignment = BoxContainer.ALIGNMENT_CENTER
	prompt_column.add_theme_constant_override("separation", 2)
	_attach(prompt_margin, prompt_column, owner)

	var tap_indicator := Label.new()
	tap_indicator.name = "TapIndicatorLabel"
	tap_indicator.text = "Tap for Gold"
	tap_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameThemeScript.apply_display_font(tap_indicator, 36)
	tap_indicator.add_theme_color_override("font_color", COLOR_TAP)
	attach(prompt_column, tap_indicator, owner)

	var combat_hint := Label.new()
	combat_hint.name = "CombatHintLabel"
	combat_hint.text = "Tap to support the defense."
	combat_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_hint.add_theme_font_size_override("font_size", 22)
	combat_hint.add_theme_color_override("font_color", COLOR_MUTED)
	attach(prompt_column, combat_hint, owner)

	return panel


static func _build_unit_side(node_name: String, hp_label_text: String, hp_bar_name: String, owner: Node) -> Control:
	var side := VBoxContainer.new()
	side.name = node_name
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	side.add_theme_constant_override("separation", 6)

	var hp_label := Label.new()
	hp_label.text = hp_label_text
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 26)
	hp_label.add_theme_color_override("font_color", COLOR_MUTED)
	_attach(side, hp_label, owner)

	var hp_bar := ProgressBar.new()
	hp_bar.name = hp_bar_name
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(290, 30)
	hp_bar.add_theme_stylebox_override("background", UiAtlasScript.stylebox_from_ui(0, 7, 3, 1, 4, Color(0.62, 0.21, 0.24, 1.0), Vector4(4, 2, 4, 2)))
	hp_bar.add_theme_stylebox_override("fill", UiAtlasScript.stylebox_from_ui(0, 5, 3, 1, 4, Color(0.92, 0.23, 0.32, 1.0), Vector4(4, 2, 4, 2)))
	_attach(side, hp_bar, owner)

	return side


static func _build_hero_slots(owner: Node) -> Control:
	var panel := _make_panel("HeroSlotsPanel", Vector2(0, 188), COLOR_PANEL)
	var margin := _make_margin(14, 12, 14, 12)
	_attach(panel, margin, owner)

	var row := HBoxContainer.new()
	row.name = "HeroSlotRow"
	row.add_theme_constant_override("separation", 12)
	attach(margin, row, owner)

	for index in 3:
		var card := _make_panel("HeroSlotCard%d" % (index + 1), Vector2(0, 128), COLOR_BG_SECONDARY)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_margin := _make_margin(10, 10, 10, 10)
		_attach(card, card_margin, owner)

		var card_column := VBoxContainer.new()
		card_column.alignment = BoxContainer.ALIGNMENT_CENTER
		card_column.add_theme_constant_override("separation", 8)
		_attach(card_margin, card_column, owner)

		_attach(card_column, _make_texture_icon("HeroSlotIcon", UiAtlasScript.icon_region(15, 5), Vector2(44, 44), false), owner)

		var label := Label.new()
		label.text = "Hero Slot %d" % (index + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", COLOR_TEXT)
		_attach(card_column, label, owner)

		var state_label := Label.new()
		state_label.text = "Locked to gacha\nPhase 4"
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		state_label.add_theme_font_size_override("font_size", 18)
		state_label.add_theme_color_override("font_color", COLOR_MUTED)
		_attach(card_column, state_label, owner)

		_attach(row, card, owner)

	return panel


static func _build_selected_unit_panel(owner: Node) -> Control:
	var panel := _make_panel("SelectedUnitPanel", Vector2(0, 138), COLOR_PANEL_ALT)
	var margin := _make_margin(14, 10, 14, 10)
	_attach(panel, margin, owner)

	var row := HBoxContainer.new()
	row.name = "SelectedUnitRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	_attach(margin, row, owner)

	_attach(row, _make_texture_icon("SelectedUnitIcon", UiAtlasScript.icon_region(4, 5), Vector2(58, 58), false), owner)

	var details := VBoxContainer.new()
	details.name = "SelectedUnitDetails"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	_attach(row, details, owner)

	var name_label := Label.new()
	name_label.name = "SelectedUnitNameLabel"
	name_label.text = "King"
	GameThemeScript.apply_display_font(name_label, 30)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	attach(details, name_label, owner)

	var level_label := Label.new()
	level_label.name = "SelectedUnitLevelLabel"
	level_label.text = "Level 1 Guardian"
	level_label.add_theme_font_size_override("font_size", 22)
	level_label.add_theme_color_override("font_color", COLOR_MUTED)
	attach(details, level_label, owner)

	var upgrade_button := Button.new()
	upgrade_button.name = "UpgradeButton"
	upgrade_button.custom_minimum_size = Vector2(224, 76)
	upgrade_button.text = "Upgrade"
	upgrade_button.icon = UiAtlasScript.icon_region(4, 9)
	upgrade_button.expand_icon = false
	upgrade_button.add_theme_font_size_override("font_size", 24)
	upgrade_button.add_theme_constant_override("h_separation", 8)
	upgrade_button.add_theme_color_override("font_color", COLOR_TEXT)
	upgrade_button.clip_text = true
	_style_button(upgrade_button, false)
	_attach(row, upgrade_button, owner)

	return panel


static func _build_upgrade_overlay(owner: Node) -> Control:
	var overlay := ColorRect.new()
	overlay.name = "UpgradeOverlay"
	_full_rect(overlay)
	overlay.visible = false
	overlay.color = Color(0.02, 0.03, 0.05, 0.82)
	_attach(overlay, _build_upgrade_modal(owner), owner)
	return overlay


static func _build_upgrade_modal(owner: Node) -> Control:
	var panel := _make_panel("UpgradePanel", Vector2(0, 560), COLOR_PANEL_ALT)
	panel.anchor_left = 0.08
	panel.anchor_top = 0.19
	panel.anchor_right = 0.92
	panel.anchor_bottom = 0.65
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0

	var margin := _make_margin(18, 18, 18, 18)
	_attach(panel, margin, owner)

	var column := VBoxContainer.new()
	column.name = "UpgradePanelColumn"
	column.add_theme_constant_override("separation", 14)
	_attach(margin, column, owner)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	_attach(column, header, owner)

	var title := Label.new()
	title.name = "UpgradePanelTitle"
	title.text = "Royal Upgrades"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameThemeScript.apply_display_font(title, 30)
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	_attach(header, title, owner)

	var close_button := Button.new()
	close_button.name = "CloseUpgradePanelButton"
	close_button.text = "Close"
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.add_theme_color_override("font_color", COLOR_TEXT)
	_style_button(close_button, false)
	_attach(header, close_button, owner)

	var summary := Label.new()
	summary.name = "UpgradeSummaryLabel"
	summary.text = "Spend gold to improve damage, attack speed, and gold gains."
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 22)
	summary.add_theme_color_override("font_color", COLOR_MUTED)
	_attach(column, summary, owner)

	_attach(column, _build_upgrade_entry("DamageUpgradeCard", "DamageUpgradeLevelLabel", "DamageUpgradeEffectLabel", "DamageUpgradeCostLabel", "DamageUpgradeButton", "Damage", UiAtlasScript.icon_region(4, 9), owner), owner)
	_attach(column, _build_upgrade_entry("SpeedUpgradeCard", "SpeedUpgradeLevelLabel", "SpeedUpgradeEffectLabel", "SpeedUpgradeCostLabel", "SpeedUpgradeButton", "Speed", UiAtlasScript.icon_region(4, 5), owner), owner)
	_attach(column, _build_upgrade_entry("GoldUpgradeCard", "GoldUpgradeLevelLabel", "GoldUpgradeEffectLabel", "GoldUpgradeCostLabel", "GoldUpgradeButton", "Gold", UiAtlasScript.icon_region(7, 10), owner), owner)

	return panel


static func _build_upgrade_entry(card_name: String, level_name: String, effect_name: String, cost_name: String, button_name: String, title_text: String, icon_texture: Texture2D, owner: Node) -> Control:
	var card := _make_panel(card_name, Vector2(0, 118), COLOR_PANEL)
	var margin := _make_margin(14, 12, 14, 12)
	_attach(card, margin, owner)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_attach(margin, row, owner)

	_attach(row, _make_texture_icon("%sIcon" % title_text, icon_texture, Vector2(42, 42), false), owner)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	_attach(row, details, owner)

	var level_label := Label.new()
	level_label.name = level_name
	level_label.text = "%s Lv. 0" % title_text
	level_label.add_theme_font_size_override("font_size", 24)
	level_label.add_theme_color_override("font_color", COLOR_TEXT)
	_attach(details, level_label, owner)

	var effect_label := Label.new()
	effect_label.name = effect_name
	effect_label.text = "Value"
	effect_label.add_theme_font_size_override("font_size", 20)
	effect_label.add_theme_color_override("font_color", COLOR_MUTED)
	_attach(details, effect_label, owner)

	var cost_label := Label.new()
	cost_label.name = cost_name
	cost_label.text = "Cost: 0 gold"
	cost_label.add_theme_font_size_override("font_size", 18)
	cost_label.add_theme_color_override("font_color", COLOR_ACCENT)
	_attach(details, cost_label, owner)

	var buy_button := Button.new()
	buy_button.name = button_name
	buy_button.text = "Buy"
	buy_button.custom_minimum_size = Vector2(132, 68)
	buy_button.add_theme_font_size_override("font_size", 22)
	buy_button.add_theme_color_override("font_color", COLOR_TEXT)
	_style_button(buy_button, false)
	_attach(row, buy_button, owner)

	return card


static func _build_status_label(owner: Node) -> Control:
	var label := Label.new()
	label.name = "StatusLabel"
	label.custom_minimum_size = Vector2(0, 54)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", COLOR_MUTED)
	label.text = "Phase 1 online. Tap to generate gold."
	return label


static func _build_bottom_bar(owner: Node) -> Control:
	var panel := _make_panel("BottomBarPanel", Vector2(0, 156), COLOR_PANEL_ALT)
	var margin := _make_margin(12, 12, 12, 12)
	_attach(panel, margin, owner)

	var row := HBoxContainer.new()
	row.name = "BottomBarRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	attach(margin, row, owner)

	var gacha_button := _make_nav_button("GachaButton", "Gacha", UiAtlasScript.icon_region(10, 9), false)
	var upgrades_button := _make_nav_button("UpgradesButton", "Upgrades", UiAtlasScript.icon_region(4, 9), false)
	var tap_button := _make_nav_button("TapButton", "TAP", UiAtlasScript.icon_region(4, 5), true)
	var roster_button := _make_nav_button("RosterButton", "Roster", UiAtlasScript.icon_region(1, 6), false)
	var events_button := _make_nav_button("EventsButton", "Events", UiAtlasScript.icon_region(7, 10), false)

	for button in [gacha_button, upgrades_button, tap_button, roster_button, events_button]:
		_attach(row, button, owner)

	return panel


static func _make_resource_item(node_name: String, value_name: String, icon_texture: Texture2D, value_text: String, owner: Node) -> Control:
	var row := HBoxContainer.new()
	row.name = node_name
	row.add_theme_constant_override("separation", 8)

	_attach(row, _make_texture_icon("Icon", icon_texture, Vector2(34, 34), false), owner)

	var label := Label.new()
	label.name = value_name
	label.text = value_text
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	_attach(row, label, owner)

	return row


static func _make_nav_button(node_name: String, button_text: String, icon_texture: Texture2D, emphasized: bool) -> Button:
	var button := Button.new()
	var button_height := 104
	var font_size := 21
	if emphasized:
		button_height = 118
		font_size = 24

	button.name = node_name
	button.text = button_text
	button.icon = icon_texture
	button.expand_icon = true
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size = Vector2(0, button_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_constant_override("h_separation", 10)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.clip_text = true
	_style_button(button, emphasized)
	return button


static func _make_panel(node_name: String, minimum_size: Vector2, fallback_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.custom_minimum_size = minimum_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UiAtlasScript.stylebox_from_ui(1, 0, 2, 2, PANEL_SLICE, fallback_color))
	return panel


static func _make_margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


static func _make_texture_icon(node_name: String, texture: Texture2D, size: Vector2, flip_h: bool) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = node_name
	icon.texture = texture
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.flip_h = flip_h
	return icon


static func _style_button(button: Button, emphasized: bool) -> void:
	button.add_theme_stylebox_override("normal", UiAtlasScript.stylebox_from_ui(1, 0, 2, 2, BUTTON_SLICE, COLOR_PANEL_ALT if not emphasized else Color("6c3d13"), Vector4(16, 10, 16, 10)))
	button.add_theme_stylebox_override("hover", UiAtlasScript.stylebox_from_ui(1, 0, 2, 2, BUTTON_SLICE, COLOR_ACCENT if emphasized else Color("8a5a2d"), Vector4(16, 10, 16, 10)))
	button.add_theme_stylebox_override("pressed", UiAtlasScript.stylebox_from_ui(1, 0, 2, 2, BUTTON_SLICE, Color("b98232"), Vector4(16, 10, 16, 10)))
	button.add_theme_stylebox_override("disabled", UiAtlasScript.stylebox_from_ui(1, 0, 2, 2, BUTTON_SLICE, Color("53483d"), Vector4(16, 10, 16, 10)))


static func _make_texture_stylebox(texture_path: String, fallback_color: Color, slice_margin: int = PANEL_SLICE, content_margins: Vector4 = Vector4(16, 10, 16, 10)) -> StyleBox:
	var texture: Texture2D = _load_texture_or_null(texture_path)
	if texture is Texture2D:
		var box := StyleBoxTexture.new()
		box.texture = texture
		box.texture_margin_left = slice_margin
		box.texture_margin_top = slice_margin
		box.texture_margin_right = slice_margin
		box.texture_margin_bottom = slice_margin
		box.modulate_color = fallback_color
		box.content_margin_left = content_margins.x
		box.content_margin_top = content_margins.y
		box.content_margin_right = content_margins.z
		box.content_margin_bottom = content_margins.w
		return box

	return _make_stylebox(fallback_color, 14)


static func _load_texture_or_null(texture_path: String) -> Texture2D:
	if not ResourceLoader.exists(texture_path):
		return null
	return load(texture_path) as Texture2D


static func _make_stylebox(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box


static func _full_rect(control: Control) -> void:
	control.layout_mode = 1
	control.anchors_preset = Control.PRESET_FULL_RECT
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.grow_horizontal = Control.GROW_DIRECTION_BOTH
	control.grow_vertical = Control.GROW_DIRECTION_BOTH


static func _attach(parent: Node, child: Node, owner: Node) -> void:
	parent.add_child(child)
	if owner != null and (parent == owner or owner.is_ancestor_of(parent)):
		child.owner = owner


static func attach(parent: Node, child: Node, owner: Node) -> void:
	# Small alias used to keep call sites readable in long builder sections.
	_attach(parent, child, owner)
