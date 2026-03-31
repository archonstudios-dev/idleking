extends RefCounted
class_name UiAtlasWidgets

const COLOR_TEXT := Color("f4eedc")
const COLOR_MUTED := Color("d4c3a0")
const COLOR_OUTLINE := Color("1a0f0f")

const PANEL_STYLES := {
	"light": {"bg": Color("d5c7a4"), "border": Color("5b3d26")},
	"card": {"bg": Color("a57846"), "border": Color("5d3e25")},
	"window": {"bg": Color("5f472d"), "border": Color("261711")},
	"hud": {"bg": Color("956b3d"), "border": Color("4d301d")},
	"dark": {"bg": Color("4e3421"), "border": Color("22150f")}
}

const BAR_COLORS := {
	"hp_under": Color("4b2424"),
	"hp_fill": Color("7ae070"),
	"mana_fill": Color("58a6ff"),
	"gold_fill": Color("d4a74d")
}

const BUTTON_SIZES := {
	"small": Vector2(80, 40),
	"medium": Vector2(124, 44),
	"large": Vector2(176, 48),
	"wide": Vector2(220, 52),
	"xwide": Vector2(280, 56)
}

static var _texture_cache: Dictionary = {}


static func make_panel(style_key: String, min_size: Vector2 = Vector2.ZERO) -> PanelContainer:
	var style: Dictionary = PANEL_STYLES.get(style_key, PANEL_STYLES["hud"])
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", _make_panel_style(style["bg"], style["border"]))
	return panel


static func make_icon(_sprite_name: String, scale_factor: float = 2.0) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = _make_solid_texture(Vector2i(16, 16), Color("d4a74d"))
	icon.custom_minimum_size = Vector2(16, 16) * scale_factor
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return icon


static func make_button(size_key: String, label_text: String, _icon_sprite: String = "") -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = BUTTON_SIZES.get(size_key, BUTTON_SIZES["medium"])
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", maxi(16, int(button.custom_minimum_size.y * 0.34)))
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	button.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("normal", _make_button_style(Color("8f6840"), Color("4d301d")))
	button.add_theme_stylebox_override("hover", _make_button_style(Color("a57846"), Color("5d3e25")))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color("75522f"), Color("332014")))
	button.add_theme_stylebox_override("disabled", _make_button_style(Color("5c4d40"), Color("2d241d")))
	return button


static func make_progress_bar(fill_ratio: float, fill_style: String = "hp_fill") -> TextureProgressBar:
	var bar := TextureProgressBar.new()
	bar.texture_under = _make_solid_texture(Vector2i(16, 16), BAR_COLORS["hp_under"])
	bar.texture_progress = _make_solid_texture(Vector2i(16, 16), BAR_COLORS.get(fill_style, BAR_COLORS["hp_fill"]))
	bar.texture_over = _make_solid_texture(Vector2i(16, 16), Color(1, 1, 1, 0))
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = clampf(fill_ratio * 100.0, 0.0, 100.0)
	bar.custom_minimum_size = Vector2(240, 18)
	bar.nine_patch_stretch = true
	bar.stretch_margin_left = 4
	bar.stretch_margin_top = 4
	bar.stretch_margin_right = 4
	bar.stretch_margin_bottom = 4
	return bar


static func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style


static func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	return style


static func _make_solid_texture(size: Vector2i, color: Color) -> Texture2D:
	var cache_key := "%d:%d:%s" % [size.x, size.y, color.to_html()]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture := ImageTexture.create_from_image(image)
	_texture_cache[cache_key] = texture
	return texture
