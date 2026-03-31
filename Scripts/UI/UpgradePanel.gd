extends Control

const UiAtlasWidgetsScript := preload("res://Scripts/UI/UiAtlasWidgets.gd")

const AFFORDABLE_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const UNAFFORDABLE_MODULATE := Color(0.72, 0.72, 0.72, 1.0)
const COLOR_TEXT := Color("f4eedc")
const COLOR_MUTED := Color("d4c3a0")

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var card_list: VBoxContainer = $ScrollContainer/VBoxContainer

var _upgrade_cards: Dictionary = {}


func _ready() -> void:
	_build_cards()

	if CurrencyManager != null and not CurrencyManager.currencies_changed.is_connected(_on_currencies_changed):
		CurrencyManager.currencies_changed.connect(_on_currencies_changed)
	if UpgradeManager != null and not UpgradeManager.upgrades_changed.is_connected(_on_upgrades_changed):
		UpgradeManager.upgrades_changed.connect(_on_upgrades_changed)

	refresh_upgrade_panel()


func refresh_upgrade_panel() -> void:
	for upgrade_id in UpgradeManager.UPGRADE_ORDER:
		var card: Control = _upgrade_cards.get(upgrade_id)
		if card == null:
			continue

		var data: Dictionary = UpgradeManager.get_upgrade_ui_data(upgrade_id)
		(card.get_node("CardRow/TextColumn/NameLabel") as Label).text = String(data.get("name", "Upgrade"))
		(card.get_node("CardRow/TextColumn/LevelLabel") as Label).text = "Lv. %d" % int(data.get("level", 0))
		(card.get_node("CardRow/TextColumn/EffectLabel") as Label).text = "%s\n%s" % [
			String(data.get("current_value_text", "")),
			String(data.get("next_value_text", "")),
		]
		(card.get_node("CardRow/TextColumn/CostLabel") as Label).text = "Cost: %d" % int(data.get("cost", 0))

		var affordable: bool = bool(data.get("affordable", false))
		var buy_button := card.get_node("CardRow/BuyButton") as Button
		buy_button.disabled = not affordable
		card.modulate = AFFORDABLE_MODULATE if affordable else UNAFFORDABLE_MODULATE


func _build_cards() -> void:
	for child in card_list.get_children():
		child.queue_free()
	_upgrade_cards.clear()

	for upgrade_id in UpgradeManager.UPGRADE_ORDER:
		var card := _create_upgrade_card(upgrade_id)
		card_list.add_child(card)
		_upgrade_cards[upgrade_id] = card


func _create_upgrade_card(upgrade_id: String) -> Control:
	var card := UiAtlasWidgetsScript.make_panel("hud", Vector2(0.0, 112.0))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_row := HBoxContainer.new()
	card_row.name = "CardRow"
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 12)
	card.add_child(card_row)

	var text_column := VBoxContainer.new()
	text_column.name = "TextColumn"
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 4)
	card_row.add_child(text_column)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	name_label.add_theme_color_override("font_outline_color", Color("1a0f0f"))
	name_label.add_theme_constant_override("outline_size", 2)
	text_column.add_child(name_label)

	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.add_theme_font_size_override("font_size", 13)
	level_label.add_theme_color_override("font_color", COLOR_MUTED)
	text_column.add_child(level_label)

	var effect_label := Label.new()
	effect_label.name = "EffectLabel"
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_font_size_override("font_size", 12)
	effect_label.add_theme_color_override("font_color", COLOR_TEXT)
	text_column.add_child(effect_label)

	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.add_theme_font_size_override("font_size", 13)
	cost_label.add_theme_color_override("font_color", Color("d4a74d"))
	text_column.add_child(cost_label)

	var buy_button := UiAtlasWidgetsScript.make_button("medium", "Upgrade")
	buy_button.name = "BuyButton"
	buy_button.custom_minimum_size = Vector2(148.0, 44.0)
	buy_button.pressed.connect(func() -> void:
		_on_buy_pressed(upgrade_id)
	)
	card_row.add_child(buy_button)

	return card


func _on_buy_pressed(upgrade_id: String) -> void:
	if UpgradeManager.try_purchase_upgrade(upgrade_id):
		refresh_upgrade_panel()


func _on_currencies_changed(_gold: int, _gems: int) -> void:
	refresh_upgrade_panel()


func _on_upgrades_changed(_state: Dictionary) -> void:
	refresh_upgrade_panel()
