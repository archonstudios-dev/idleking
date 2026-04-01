extends Control

const FONT_PATH := "res://Assets/Art/Fonts/yoster.ttf"
const GameThemeScript := preload("res://Scripts/UI/GameTheme.gd")
const UiAtlasWidgetsScript := preload("res://Scripts/UI/UiAtlasWidgets.gd")

const COLOR_TEXT := Color("f4eedc")
const COLOR_MUTED := Color("d4c3a0")
const COLOR_TITLE := Color("ffe089")
const COLOR_PANEL := Color("50352a", 0.92)
const COLOR_BORDER := Color("9c7440")
const TAP_GOLD_VALUE := 10
const DEV_CURRENCY_CAP := 999999999
const SUPPORT_PREVIEW_CONFIGS := [
	{
		"texture": "res://Assets/Art/GachaPool/Common/Hero Knight/Sprites/Idle.png",
		"frame_size": Vector2i(180, 180),
		"frame_count": 11,
	},
	{
		"texture": "res://Assets/Art/GachaPool/Rare/Huntress/Sprites/Idle.png",
		"frame_size": Vector2i(100, 150),
		"frame_count": 12,
	},
	{
		"texture": "res://Assets/Art/GachaPool/Rare/Martial Hero 2/Sprites/Idle.png",
		"frame_size": Vector2i(100, 200),
		"frame_count": 8,
	},
]
const DISPLAY_UPGRADES := ["damage", "max_hp", "attack_speed", "recovery", "gold_gain"]
const UPGRADE_SHORT_LABELS := {
	"damage": "DMG",
	"max_hp": "MAX HP",
	"attack_speed": "ATK SPD",
	"recovery": "REC",
	"gold_gain": "GOLD",
}

@onready var ground_background: TextureRect = $GroundBackground
@onready var header_title_label: Label = $TopTitlePanel/HeaderTitleLabel
@onready var gold_label: Label = $TopGoldPanel/GoldLabel
@onready var gps_label: Label = $TopGoldPanel/GpsLabel
@onready var level_label: Label = $TopLevelPanel/LevelLabel
@onready var rank_label: Label = $TopLevelPanel/RankLabel
@onready var gem_panel: Button = $GemPanel
@onready var gems_label: Label = $GemPanel/GemsLabel
@onready var enemy_hp_label: Label = $EnemyHpPanel/EnemyHpLabel
@onready var wave_label: Label = $WavePanel/WaveLabel

@onready var settings_button: Button = $SettingsButton
@onready var mute_button: Button = $MuteButton
@onready var developer_button: Button = $DeveloperButton
@onready var developer_panel: Panel = $DeveloperPanel
@onready var developer_title_label: Label = $DeveloperPanel/DeveloperTitleLabel
@onready var unlimited_gold_button: Button = $DeveloperPanel/UnlimitedGoldButton
@onready var unlimited_gems_button: Button = $DeveloperPanel/UnlimitedGemsButton
@onready var reset_progress_button: Button = $DeveloperPanel/ResetProgressButton
@onready var shop_button: Button = $ShopButton
@onready var power_up_button_1: Button = $"PowerUpButton1"
@onready var double_damage_button: Button = $"2XDamageButton"
@onready var power_up_button_2: Button = $PowerUpButton2
@onready var tap_button: Button = $TapPanel/TapButton

@onready var support_slot_1: Button = $LeftSupportRail/SupportSlot1
@onready var support_slot_2: Button = $LeftSupportRail/SupportSlot2
@onready var support_slot_3: Button = $LeftSupportRail/SupportSlot3
@onready var support_preview_1: AnimatedSprite2D = $LeftSupportRail/SupportPreview1
@onready var support_preview_2: AnimatedSprite2D = $LeftSupportRail/SupportPreview2
@onready var support_preview_3: AnimatedSprite2D = $LeftSupportRail/SupportPreview3

@onready var damage_upgrade_button: Button = $RightUpgradeRail/DamageUpgradeButton
@onready var health_upgrade_button: Button = $RightUpgradeRail/HealthUpgradeButton
@onready var speed_upgrade_button: Button = $RightUpgradeRail/SpeedUpgradeButton
@onready var recovery_upgrade_button: Button = $RightUpgradeRail/RecoveryUpgradeButton
@onready var gold_upgrade_button: Button = $RightUpgradeRail/GoldUpgradeButton

@onready var damage_upgrade_level_label: Label = $RightUpgradeRail/DamageUpgradeLevelLabel
@onready var health_upgrade_level_label: Label = $RightUpgradeRail/HealthUpgradeLevelLabel
@onready var speed_upgrade_level_label: Label = $RightUpgradeRail/SpeedUpgradeLevelLabel
@onready var recovery_upgrade_level_label: Label = $RightUpgradeRail/RecoveryUpgradeLevelLabel
@onready var gold_upgrade_level_label: Label = $RightUpgradeRail/GoldUpgradeLevelLabel

@onready var stats_title_label: Label = $StatsPanel/StatsTitleLabel
@onready var power_label: Label = $StatsPanel/PowerLabel
@onready var defense_label: Label = $StatsPanel/DefenseLabel
@onready var hearts_label: Label = $StatsPanel/HeartsLabel
@onready var population_label: Label = $StatsPanel/PopulationLabel

@onready var tap_glow_label: Label = $TapPanel/TapGlowLabel
@onready var tap_sub_label: Label = $TapPanel/TapSubLabel

@onready var bottom_nav_panel: Panel = $BottomNavPanel
@onready var quests_menu_button: Button = $BottomNavPanel/QuestsMenuButton
@onready var team_button: Button = $BottomNavPanel/TeamButton
@onready var achievements_menu_button: Button = $BottomNavPanel/AchievementsMenuButton
@onready var upgrades_menu_button: Button = $BottomNavPanel/UpgradesMenuButton
@onready var gacha_button: Button = $BottomNavPanel/GachaButton

@onready var game_world: GameWorld = $BattleFrame/SubViewportContainer/SubViewport/GameWorld

var _is_muted: bool = false
var _dev_unlimited_gold: bool = false
var _dev_unlimited_gems: bool = false
var _applying_dev_currency: bool = false
var _upgrade_buttons: Dictionary = {}
var _upgrade_level_labels: Dictionary = {}


func _ready() -> void:
	GameThemeScript.apply_to(self)
	_cache_upgrade_nodes()
	_style_shell()
	_align_bottom_nav_buttons()
	_connect_signals()
	_refresh_currency_labels()
	_refresh_upgrade_labels()
	_refresh_stats_preview()
	_seed_combat_hud()
	_sync_mute_button()


func _cache_upgrade_nodes() -> void:
	_upgrade_buttons = {
		"damage": damage_upgrade_button,
		"max_hp": health_upgrade_button,
		"attack_speed": speed_upgrade_button,
		"recovery": recovery_upgrade_button,
		"gold_gain": gold_upgrade_button,
	}
	_upgrade_level_labels = {
		"damage": damage_upgrade_level_label,
		"max_hp": health_upgrade_level_label,
		"attack_speed": speed_upgrade_level_label,
		"recovery": recovery_upgrade_level_label,
		"gold_gain": gold_upgrade_level_label,
	}


func _style_shell() -> void:
	ground_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	for panel_path in [
		$TopTitlePanel,
		$TopGoldPanel,
		$TopLevelPanel,
		$EnemyHpPanel,
		$WavePanel,
		$StatsPanel,
		developer_panel
	]:
		panel_path.add_theme_stylebox_override("panel", _make_shell_panel())

	gem_panel.text = ""
	gem_panel.icon = null
	_apply_button_style(gem_panel)

	for panel_path in [
		$LeftSupportRail,
		$RightUpgradeRail,
		$TapPanel,
		bottom_nav_panel
	]:
		panel_path.add_theme_stylebox_override("panel", _make_invisible_panel())

	_apply_header_text(header_title_label, 42, COLOR_TITLE)

	for label in [
		gold_label,
		gps_label,
		level_label,
		rank_label,
		gems_label,
		enemy_hp_label,
		wave_label,
		stats_title_label,
		power_label,
		defense_label,
		hearts_label,
		population_label,
		tap_glow_label,
		tap_sub_label,
		damage_upgrade_level_label,
		health_upgrade_level_label,
		speed_upgrade_level_label,
		recovery_upgrade_level_label,
		gold_upgrade_level_label,
		$TopTitlePanel/TitleIconLabel,
		$LeftSupportRail/SupportHeaderLabel,
		$LeftSupportRail/SupportLabel1,
		$LeftSupportRail/SupportLabel2,
		$LeftSupportRail/SupportLabel3,
		$RightUpgradeRail/UpgradeHeaderLabel,
		developer_title_label
	]:
		_apply_header_text(label, 20)

	_apply_header_text(gold_label, 36, COLOR_TITLE)
	_apply_header_text(level_label, 26)
	_apply_header_text(tap_glow_label, 58, COLOR_TITLE)
	_apply_header_text(stats_title_label, 28, COLOR_TITLE)
	_apply_header_text(gems_label, 26, COLOR_TITLE)
	_apply_header_text(damage_upgrade_level_label, 22, COLOR_TITLE)
	_apply_header_text(health_upgrade_level_label, 22, COLOR_TITLE)
	_apply_header_text(speed_upgrade_level_label, 22, COLOR_TITLE)
	_apply_header_text(recovery_upgrade_level_label, 20, COLOR_TITLE)
	_apply_header_text(gold_upgrade_level_label, 22, COLOR_TITLE)

	for button in [
		gem_panel,
		developer_button,
		unlimited_gold_button,
		unlimited_gems_button,
		reset_progress_button,
		settings_button,
		mute_button,
		shop_button,
		power_up_button_1,
		double_damage_button,
		power_up_button_2,
		tap_button,
		support_slot_1,
		support_slot_2,
		support_slot_3,
		damage_upgrade_button,
		health_upgrade_button,
		speed_upgrade_button,
		recovery_upgrade_button,
		gold_upgrade_button,
		quests_menu_button,
		team_button,
		achievements_menu_button,
		upgrades_menu_button,
		gacha_button
	]:
		_apply_button_style(button)

	tap_button.add_theme_font_size_override("font_size", 60)
	tap_button.add_theme_color_override("font_color", COLOR_TITLE)

	for support_button in [support_slot_1, support_slot_2, support_slot_3]:
		support_button.add_theme_font_size_override("font_size", 36)

	for icon_button in [
		settings_button,
		mute_button,
		damage_upgrade_button,
		health_upgrade_button,
		speed_upgrade_button,
		recovery_upgrade_button,
		gold_upgrade_button
	]:
		icon_button.expand_icon = true
		icon_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER

	support_slot_1.visible = false
	support_slot_2.visible = false
	support_slot_3.visible = false
	support_preview_1.visible = false
	support_preview_2.visible = false
	support_preview_3.visible = false

	for utility_button in [settings_button, mute_button, shop_button, power_up_button_1, double_damage_button, power_up_button_2]:
		utility_button.add_theme_font_size_override("font_size", 24)


func _make_shell_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.border_color = COLOR_BORDER
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.shadow_color = Color(0, 0, 0, 0.2)
	style.shadow_size = 2
	return style


func _make_invisible_panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.shadow_size = 0
	return style


func _apply_header_text(control: Control, font_size: int, color: Color = COLOR_TEXT) -> void:
	if control == null:
		return
	var font := _make_display_font()
	if font != null:
		control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", font_size)
	control.add_theme_color_override("font_color", color)
	control.add_theme_color_override("font_outline_color", Color("120d0d"))
	control.add_theme_constant_override("outline_size", 3)
	control.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.01, 0.84))
	control.add_theme_constant_override("shadow_offset_x", 0)
	control.add_theme_constant_override("shadow_offset_y", 2)


func _make_display_font() -> FontFile:
	var loaded_font := load(FONT_PATH) as FontFile
	if loaded_font == null:
		return null
	var font := loaded_font.duplicate() as FontFile
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	font.hinting = TextServer.HINTING_LIGHT
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_ONE_HALF
	font.oversampling = 4.0
	font.multichannel_signed_distance_field = true
	font.msdf_pixel_range = 24
	font.msdf_size = 96
	return font


func _apply_button_style(button: Button) -> void:
	if button == null:
		return
	button.focus_mode = Control.FOCUS_NONE
	_apply_header_text(button, 20)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	button.add_theme_stylebox_override("normal", UiAtlasWidgetsScript._make_button_style(Color("8f6840"), Color("4d301d")))
	button.add_theme_stylebox_override("hover", UiAtlasWidgetsScript._make_button_style(Color("987349"), Color("5d3e25")))
	button.add_theme_stylebox_override("pressed", UiAtlasWidgetsScript._make_button_style(Color("6e4e2f"), Color("332014")))
	button.add_theme_stylebox_override("disabled", UiAtlasWidgetsScript._make_button_style(Color("4b4038"), Color("2d241d")))


func _setup_support_preview() -> void:
	_setup_single_support_preview(support_preview_1, SUPPORT_PREVIEW_CONFIGS[0])
	_setup_single_support_preview(support_preview_2, SUPPORT_PREVIEW_CONFIGS[1])
	_setup_single_support_preview(support_preview_3, SUPPORT_PREVIEW_CONFIGS[2])


func _setup_single_support_preview(preview: AnimatedSprite2D, config: Dictionary) -> void:
	if preview == null:
		return
	var texture := load(String(config.get("texture", ""))) as Texture2D
	if texture == null:
		return

	var frame_size: Vector2i = config.get("frame_size", Vector2i.ZERO)
	var frame_count: int = int(config.get("frame_count", 0))
	var frames := SpriteFrames.new()
	if not frames.has_animation("default"):
		frames.add_animation("default")
	frames.set_animation_loop("default", true)
	frames.set_animation_speed("default", 8.0)

	var image := texture.get_image()
	if image == null or image.is_empty():
		return

	for frame_texture in _build_stabilized_support_frames(image, frame_size, frame_count):
		frames.add_frame("default", frame_texture)

	preview.sprite_frames = frames
	preview.centered = true
	preview.scale = Vector2(absf(preview.scale.x), preview.scale.y)
	preview.play("default")


func _build_stabilized_support_frames(sheet_image: Image, frame_size: Vector2i, frame_count: int) -> Array[Texture2D]:
	var output: Array[Texture2D] = []
	if frame_size.x <= 0 or frame_size.y <= 0 or frame_count <= 0:
		return output

	var shared_bounds := _find_shared_opaque_bounds(sheet_image, frame_size, frame_count)
	var target_origin := Vector2i(
		int(round((frame_size.x - shared_bounds.size.x) * 0.5)),
		maxi(0, frame_size.y - shared_bounds.size.y)
	)

	for frame_index in range(frame_count):
		var source_rect := Rect2i(frame_index * frame_size.x, 0, frame_size.x, frame_size.y)
		var cropped_rect := _find_opaque_bounds(sheet_image, source_rect)
		var canvas := Image.create(frame_size.x, frame_size.y, false, Image.FORMAT_RGBA8)
		canvas.fill(Color(0, 0, 0, 0))

		if cropped_rect.size.x > 0 and cropped_rect.size.y > 0:
			var local_rect := Rect2i(
				cropped_rect.position.x - source_rect.position.x,
				cropped_rect.position.y - source_rect.position.y,
				cropped_rect.size.x,
				cropped_rect.size.y
			)
			var destination := target_origin + (local_rect.position - shared_bounds.position)
			canvas.blit_rect(sheet_image, cropped_rect, destination)

		output.append(ImageTexture.create_from_image(canvas))

	return output


func _find_shared_opaque_bounds(image: Image, frame_size: Vector2i, frame_count: int) -> Rect2i:
	var min_x := frame_size.x
	var min_y := frame_size.y
	var max_x := -1
	var max_y := -1

	for frame_index in range(frame_count):
		var source_rect := Rect2i(frame_index * frame_size.x, 0, frame_size.x, frame_size.y)
		var rect := _find_opaque_bounds(image, source_rect)
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		var local_x := rect.position.x - source_rect.position.x
		var local_y := rect.position.y - source_rect.position.y
		min_x = mini(min_x, local_x)
		min_y = mini(min_y, local_y)
		max_x = maxi(max_x, local_x + rect.size.x - 1)
		max_y = maxi(max_y, local_y + rect.size.y - 1)

	if max_x < min_x or max_y < min_y:
		return Rect2i(Vector2i.ZERO, frame_size)

	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _find_opaque_bounds(image: Image, source_rect: Rect2i) -> Rect2i:
	var min_x := source_rect.position.x + source_rect.size.x
	var min_y := source_rect.position.y + source_rect.size.y
	var max_x := source_rect.position.x - 1
	var max_y := source_rect.position.y - 1

	for y in range(source_rect.position.y, source_rect.position.y + source_rect.size.y):
		for x in range(source_rect.position.x, source_rect.position.x + source_rect.size.x):
			if image.get_pixel(x, y).a > 0.01:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)

	if max_x < min_x or max_y < min_y:
		return Rect2i(source_rect.position, Vector2i.ZERO)

	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _normalize_layout() -> void:
	_normalize_support_and_upgrade_rails()
	_normalize_support_slot_alignment()
	_normalize_upgrade_button_alignment()
	_normalize_bottom_button_row()
	_normalize_lower_center_cluster()


func _normalize_support_and_upgrade_rails() -> void:
	var shared_top := minf($LeftSupportRail.position.y, $RightUpgradeRail.position.y)
	$LeftSupportRail.position.y = shared_top
	$RightUpgradeRail.position.y = shared_top

	var shared_bottom := maxf(
		$LeftSupportRail.position.y + $LeftSupportRail.size.y,
		$RightUpgradeRail.position.y + $RightUpgradeRail.size.y
	)
	$LeftSupportRail.size.y = shared_bottom - $LeftSupportRail.position.y
	$RightUpgradeRail.size.y = shared_bottom - $RightUpgradeRail.position.y


func _normalize_support_slot_alignment() -> void:
	var slots := [support_slot_1, support_slot_2, support_slot_3]
	var labels := [$LeftSupportRail/SupportLabel1, $LeftSupportRail/SupportLabel2, $LeftSupportRail/SupportLabel3]
	var left_margin: float = support_slot_1.position.x
	var button_width := maxf(support_slot_1.size.x, maxf(support_slot_2.size.x, support_slot_3.size.x))
	var button_height := maxf(support_slot_1.size.y, maxf(support_slot_2.size.y, support_slot_3.size.y))
	var gap := 56.0
	var start_y: float = support_slot_1.position.y

	for i in range(slots.size()):
		var slot: Button = slots[i]
		var label: Label = labels[i]
		slot.position.x = left_margin
		slot.size = Vector2(button_width, button_height)
		slot.position.y = start_y + i * (button_height + gap)
		label.position.x = 14.0
		label.size.x = maxf(label.size.x, 128.0)
		label.position.y = slot.position.y + button_height + 12.0


func _normalize_upgrade_button_alignment() -> void:
	var buttons := [damage_upgrade_button, health_upgrade_button, speed_upgrade_button, recovery_upgrade_button, gold_upgrade_button]
	var labels := [
		damage_upgrade_level_label,
		health_upgrade_level_label,
		speed_upgrade_level_label,
		recovery_upgrade_level_label,
		gold_upgrade_level_label
	]
	var button_width := 0.0
	var button_height := 0.0
	for button in buttons:
		button_width = maxf(button_width, button.size.x)
		button_height = maxf(button_height, button.size.y)
	var left_margin: float = ($RightUpgradeRail.size.x - button_width) * 0.5
	var start_y: float = buttons[0].position.y
	var gap := 58.0

	for i in range(buttons.size()):
		var button: Button = buttons[i]
		var label: Label = labels[i]
		button.position.x = left_margin
		button.size = Vector2(button_width, button_height)
		button.position.y = start_y + i * (button_height + gap)
		label.position.x = ($RightUpgradeRail.size.x - label.size.x) * 0.5
		label.position.y = button.position.y + button_height + 10.0


func _normalize_bottom_button_row() -> void:
	var buttons := [quests_menu_button, team_button, achievements_menu_button, upgrades_menu_button, gacha_button]
	var max_height := 0.0
	for button in buttons:
		max_height = maxf(max_height, button.size.y)
	for button in buttons:
		button.size.y = max_height
	var shared_top: float = quests_menu_button.position.y
	for button in buttons:
		shared_top = minf(shared_top, button.position.y)
	for button in buttons:
		button.position.y = shared_top


func _normalize_lower_center_cluster() -> void:
	var utility_buttons := [power_up_button_1, double_damage_button, power_up_button_2]
	var max_height := 0.0
	for button in utility_buttons:
		max_height = maxf(max_height, button.size.y)
	for button in utility_buttons:
		button.size.y = max_height
		button.position.y = power_up_button_1.position.y

	shop_button.position.y = power_up_button_1.position.y
	var minimum_shop_gap: float = 18.0
	var desired_shop_right: float = stats_title_label.get_parent().position.x - minimum_shop_gap
	if shop_button.position.x + shop_button.size.x > desired_shop_right:
		shop_button.position.x = maxf(12.0, desired_shop_right - shop_button.size.x)

	var nav_gap: float = 14.0
	team_button.position.x = quests_menu_button.position.x + quests_menu_button.size.x + nav_gap


func _uniformize_group_sizes() -> void:
	_uniformize_controls([settings_button, mute_button])
	_uniformize_controls([support_slot_1, support_slot_2, support_slot_3])
	_uniformize_controls([damage_upgrade_button, health_upgrade_button, speed_upgrade_button, recovery_upgrade_button, gold_upgrade_button])
	_uniformize_controls([damage_upgrade_level_label, health_upgrade_level_label, speed_upgrade_level_label, recovery_upgrade_level_label, gold_upgrade_level_label])
	_uniformize_controls([power_up_button_1, double_damage_button, power_up_button_2])
	_uniformize_controls([quests_menu_button, team_button, achievements_menu_button, upgrades_menu_button, gacha_button])
	_uniformize_controls([$EnemyHpPanel, $WavePanel])


func _uniformize_controls(controls: Array) -> void:
	if controls.is_empty():
		return
	var max_width := 0.0
	var max_height := 0.0
	for control in controls:
		if control == null:
			continue
		max_width = maxf(max_width, control.size.x)
		max_height = maxf(max_height, control.size.y)
	for control in controls:
		if control == null:
			continue
		control.size = Vector2(max_width, max_height)


func _connect_signals() -> void:
	if not tap_button.pressed.is_connected(_on_tap_pressed):
		tap_button.pressed.connect(_on_tap_pressed)
	if not mute_button.pressed.is_connected(_toggle_mute):
		mute_button.pressed.connect(_toggle_mute)
	if not developer_button.pressed.is_connected(_toggle_developer_panel):
		developer_button.pressed.connect(_toggle_developer_panel)
	if not unlimited_gold_button.pressed.is_connected(_toggle_unlimited_gold):
		unlimited_gold_button.pressed.connect(_toggle_unlimited_gold)
	if not unlimited_gems_button.pressed.is_connected(_toggle_unlimited_gems):
		unlimited_gems_button.pressed.connect(_toggle_unlimited_gems)
	if not reset_progress_button.pressed.is_connected(_reset_progress):
		reset_progress_button.pressed.connect(_reset_progress)

	for upgrade_id in DISPLAY_UPGRADES:
		var button: Button = _upgrade_buttons.get(upgrade_id)
		if button != null and not button.pressed.is_connected(_on_upgrade_button_pressed.bind(upgrade_id)):
			button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade_id))

	if CurrencyManager != null and not CurrencyManager.currencies_changed.is_connected(_on_currencies_changed):
		CurrencyManager.currencies_changed.connect(_on_currencies_changed)

	if UpgradeManager != null and not UpgradeManager.upgrades_changed.is_connected(_on_upgrades_changed):
		UpgradeManager.upgrades_changed.connect(_on_upgrades_changed)

	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_signal("mute_changed") and not audio_manager.is_connected("mute_changed", Callable(self, "_on_mute_changed")):
		audio_manager.connect("mute_changed", Callable(self, "_on_mute_changed"))

	if game_world != null:
		if not game_world.wave_changed.is_connected(_on_wave_changed):
			game_world.wave_changed.connect(_on_wave_changed)
		if not game_world.enemy_health_changed.is_connected(_on_enemy_health_changed):
			game_world.enemy_health_changed.connect(_on_enemy_health_changed)


func _on_tap_pressed() -> void:
	if CurrencyManager == null:
		return
	var gold_amount := TAP_GOLD_VALUE
	if UpgradeManager != null:
		gold_amount = int(round(TAP_GOLD_VALUE * UpgradeManager.get_gold_multiplier()))
	CurrencyManager.add_gold(gold_amount)


func _on_upgrade_button_pressed(upgrade_id: String) -> void:
	if UpgradeManager == null:
		return
	UpgradeManager.try_purchase_upgrade(upgrade_id)
	_refresh_upgrade_labels()
	_refresh_stats_preview()


func _refresh_currency_labels() -> void:
	if CurrencyManager == null:
		return
	var currencies: Dictionary = CurrencyManager.get_currencies()
	var gold_value: int = int(currencies.get("gold", 0))
	var gems_value: int = int(currencies.get("gems", 0))
	gold_label.text = String.num_int64(gold_value)
	gps_label.text = "GPS: %s" % String.num_int64(_estimate_gold_per_second())
	gems_label.text = "%s" % String.num_int64(gems_value)
	_refresh_developer_button_labels()


func _refresh_upgrade_labels() -> void:
	if UpgradeManager == null:
		return
	for upgrade_id in DISPLAY_UPGRADES:
		var data: Dictionary = UpgradeManager.get_upgrade_ui_data(upgrade_id)
		var button: Button = _upgrade_buttons.get(upgrade_id)
		if button != null:
			button.text = ""
			button.tooltip_text = "%s - %s gold" % [String(data.get("name", "Upgrade")), String.num_int64(int(data.get("cost", 0)))]
			button.disabled = false
			var affordable: bool = bool(data.get("affordable", false))
			button.self_modulate = Color(1, 1, 1, 1) if affordable else Color(0.82, 0.78, 0.72, 1)


func _align_bottom_nav_buttons() -> void:
	var buttons := [
		quests_menu_button,
		team_button,
		achievements_menu_button,
		upgrades_menu_button,
		gacha_button
	]
	var max_height := 0.0
	for button in buttons:
		max_height = maxf(max_height, button.size.y)
	var centered_top := maxf(0.0, floor((bottom_nav_panel.size.y - max_height) * 0.5))
	for button in buttons:
		button.size.y = max_height
		button.position.y = centered_top


func _refresh_stats_preview() -> void:
	if UpgradeManager == null:
		return
	power_label.text = "Power: %d" % UpgradeManager.get_combat_damage()
	defense_label.text = "Defense: %d" % UpgradeManager.get_effective_max_hp()
	hearts_label.text = "Recovery: %.3fs" % UpgradeManager.get_effective_recovery_bonus()
	population_label.text = "Gold x%.2f" % UpgradeManager.get_gold_multiplier()
	tap_glow_label.text = "TAP"
	tap_sub_label.text = "+%d gold per tap" % int(round(TAP_GOLD_VALUE * UpgradeManager.get_gold_multiplier()))


func _estimate_gold_per_second() -> int:
	if UpgradeManager == null:
		return 0
	return int(round(UpgradeManager.get_combat_damage() * 8 * UpgradeManager.get_gold_multiplier()))


func _seed_combat_hud() -> void:
	var combat_manager: Node = get_node_or_null("/root/CombatManager")
	if combat_manager == null or not combat_manager.has_method("get_state"):
		return
	var state: Dictionary = combat_manager.call("get_state")
	wave_label.text = "Wave %d" % int(state.get("wave", 1))
	level_label.text = "LEVEL %d" % int(state.get("wave", 1))
	rank_label.text = String(state.get("enemy_name", "BARONY")).to_upper()
	enemy_hp_label.text = "Enemy HP: %d%%" % int(round((float(state.get("enemy_current_hp", 1)) / float(max(1, int(state.get("enemy_max_hp", 1))))) * 100.0))


func _toggle_mute() -> void:
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
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		var muted_value = audio_manager.get("is_muted")
		if muted_value != null:
			_is_muted = bool(muted_value)
	mute_button.text = ""
	mute_button.tooltip_text = "Unmute" if _is_muted else "Mute"


func _toggle_developer_panel() -> void:
	developer_panel.visible = not developer_panel.visible


func _toggle_unlimited_gold() -> void:
	_dev_unlimited_gold = not _dev_unlimited_gold
	_apply_dev_currency_cheats()
	_refresh_developer_button_labels()


func _toggle_unlimited_gems() -> void:
	_dev_unlimited_gems = not _dev_unlimited_gems
	_apply_dev_currency_cheats()
	_refresh_developer_button_labels()


func _reset_progress() -> void:
	_dev_unlimited_gold = false
	_dev_unlimited_gems = false
	if CurrencyManager != null:
		CurrencyManager.initialize_new_profile()
	if UpgradeManager != null:
		UpgradeManager.reset_progress()
	var combat_manager: Node = get_node_or_null("/root/CombatManager")
	if combat_manager != null and combat_manager.has_method("reset_progress"):
		combat_manager.call("reset_progress")
	_seed_combat_hud()
	_refresh_stats_preview()
	_refresh_developer_button_labels()


func _apply_dev_currency_cheats() -> void:
	if _applying_dev_currency:
		return
	_applying_dev_currency = true
	if CurrencyManager != null:
		if _dev_unlimited_gold:
			CurrencyManager.set_gold(DEV_CURRENCY_CAP)
		if _dev_unlimited_gems:
			CurrencyManager.set_gems(DEV_CURRENCY_CAP)
	_applying_dev_currency = false


func _refresh_developer_button_labels() -> void:
	unlimited_gold_button.text = "Unli Gold: %s" % ("ON" if _dev_unlimited_gold else "OFF")
	unlimited_gems_button.text = "Unli Gems: %s" % ("ON" if _dev_unlimited_gems else "OFF")


func _on_currencies_changed(_gold: int, _gems: int) -> void:
	if not _applying_dev_currency and (_dev_unlimited_gold or _dev_unlimited_gems):
		_apply_dev_currency_cheats()
	_refresh_currency_labels()
	_refresh_upgrade_labels()


func _on_upgrades_changed(_state: Dictionary) -> void:
	_refresh_upgrade_labels()
	_refresh_stats_preview()
	_refresh_currency_labels()


func _on_wave_changed(wave: int, enemy_name_text: String) -> void:
	wave_label.text = "Wave %d" % wave
	level_label.text = "LEVEL %d" % wave
	rank_label.text = enemy_name_text.to_upper()


func _on_enemy_health_changed(ratio: float) -> void:
	enemy_hp_label.text = "Enemy HP: %d%%" % int(round(clampf(ratio, 0.0, 1.0) * 100.0))
