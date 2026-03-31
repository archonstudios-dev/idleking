# Applies the bundled project font across the UI with larger sizing for readability.
extends RefCounted

const GAME_FONT_PATH := "res://Assets/Art/Fonts/gameFont.ttf"


static func apply_to(control: Control) -> void:
	# Uses the bundled font project-wide with smoother raster settings and stronger readability defaults.
	var font := _make_font()
	if font == null:
		push_warning("Unable to load UI font at %s." % GAME_FONT_PATH)
		return

	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 34
	theme.set_color("font_shadow_color", "Label", Color(0.02, 0.01, 0.01, 0.82))
	theme.set_constant("shadow_offset_x", "Label", 0)
	theme.set_constant("shadow_offset_y", "Label", 2)
	theme.set_color("font_color", "Label", Color("f4eedc"))
	theme.set_color("font_outline_color", "Label", Color("120d0d"))
	theme.set_constant("outline_size", "Label", 3)
	theme.set_color("font_shadow_color", "Button", Color(0.02, 0.01, 0.01, 0.82))
	theme.set_constant("shadow_offset_x", "Button", 0)
	theme.set_constant("shadow_offset_y", "Button", 2)
	theme.set_color("font_color", "Button", Color("f4eedc"))
	theme.set_color("font_outline_color", "Button", Color("120d0d"))
	theme.set_constant("outline_size", "Button", 3)
	theme.set_color("font_shadow_color", "LineEdit", Color(0.02, 0.01, 0.01, 0.80))
	theme.set_constant("shadow_offset_x", "LineEdit", 0)
	theme.set_constant("shadow_offset_y", "LineEdit", 2)
	theme.set_color("font_color", "LineEdit", Color("f4eedc"))
	theme.set_color("font_outline_color", "LineEdit", Color("120d0d"))
	theme.set_constant("outline_size", "LineEdit", 3)
	control.theme = theme


static func apply_display_font(control: Control, font_size: int) -> void:
	# Applies the same bundled font at a larger display size for key headings.
	var font := _make_font()
	if font == null:
		push_warning("Unable to load UI font at %s." % GAME_FONT_PATH)
		return

	control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", max(font_size, 36))
	control.add_theme_color_override("font_outline_color", Color("120d0d"))
	control.add_theme_constant_override("outline_size", 4)
	control.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.01, 0.84))
	control.add_theme_constant_override("shadow_offset_x", 0)
	control.add_theme_constant_override("shadow_offset_y", 2)


static func _make_font() -> FontFile:
	var loaded_font := load(GAME_FONT_PATH) as FontFile
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
