# Atlas helpers for the replacement UI.2 and Icons.2 sheets.
extends RefCounted

# Updated folder layout: use the shared UI atlas directly.
const UI_ATLAS_PATH := "res://Assets/Art/UI/UIAtlas.png"
const UI_ATLAS_REGIONS_PATH := "res://Assets/Art/UI/UIAtlasRegions.txt"
# The P2 "#2" sheet isn't a strict 32x32 grid (height is not divisible by 32),
# so `icon_region(col,row)` sampling will be misaligned. Use the grid sheet.
const ICON_ATLAS_PATH := "res://Assets/Art/Icons/P1/#1 - Transparent Icons.png"
const UI_CELL := 16
const ICON_CELL := 32

static var _ui_texture: Texture2D
static var _icon_texture: Texture2D
static var _ui_regions: Dictionary = {}


static func ui_region(col: int, row: int, width_cells: int = 1, height_cells: int = 1) -> Texture2D:
	var texture := _get_ui_texture()
	if texture == null:
		return null

	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * UI_CELL, row * UI_CELL, width_cells * UI_CELL, height_cells * UI_CELL)
	return atlas


static func ui_sprite(sprite_name: String) -> Texture2D:
	var texture: Texture2D = _get_ui_texture()
	var region: Rect2 = _get_ui_region_rect(sprite_name)
	if texture == null or region.size == Vector2.ZERO:
		return null

	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas


static func ui_sprite_size(sprite_name: String) -> Vector2:
	var region: Rect2 = _get_ui_region_rect(sprite_name)
	return region.size


static func icon_region(col: int, row: int, width_cells: int = 1, height_cells: int = 1) -> Texture2D:
	var texture := _get_icon_texture()
	if texture == null:
		return null

	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * ICON_CELL, row * ICON_CELL, width_cells * ICON_CELL, height_cells * ICON_CELL)
	return atlas


static func stylebox_from_ui(col: int, row: int, width_cells: int = 1, height_cells: int = 1, slice_margin: int = 8, tint: Color = Color.WHITE, content_margins: Vector4 = Vector4(16, 10, 16, 10)) -> StyleBox:
	var texture := ui_region(col, row, width_cells, height_cells)
	return _stylebox_from_texture(texture, slice_margin, tint, content_margins)


static func stylebox_from_sprite(sprite_name: String, slice_margin: int = 8, tint: Color = Color.WHITE, content_margins: Vector4 = Vector4(16, 10, 16, 10)) -> StyleBox:
	var texture := ui_sprite(sprite_name)
	return _stylebox_from_texture(texture, slice_margin, tint, content_margins)


static func ui_button_set(size_key: String) -> Dictionary:
	match size_key:
		"small":
			return {"normal": "sprite60", "hover": "sprite77", "pressed": "sprite95"}
		"medium":
			return {"normal": "sprite213", "hover": "sprite229", "pressed": "sprite241"}
		"large":
			return {"normal": "sprite90", "hover": "sprite108", "pressed": "sprite126"}
		"wide":
			return {"normal": "sprite152", "hover": "sprite191", "pressed": "sprite226"}
		"xwide":
			return {"normal": "sprite250", "hover": "sprite251", "pressed": "sprite252"}
		_:
			return {"normal": "sprite213", "hover": "sprite229", "pressed": "sprite241"}


static func ui_button_tile_size(size_key: String) -> Vector2i:
	match size_key:
		"small":
			return Vector2i(2, 2)
		"medium":
			return Vector2i(4, 2)
		"large":
			return Vector2i(6, 2)
		"wide":
			return Vector2i(7, 2)
		"xwide":
			return Vector2i(8, 2)
		_:
			return Vector2i(4, 2)


static func ui_button_pixel_size(size_key: String, scale_multiplier: int = 2) -> Vector2:
	var tile_size: Vector2i = ui_button_tile_size(size_key)
	return Vector2(tile_size.x * UI_CELL * scale_multiplier, tile_size.y * UI_CELL * scale_multiplier)


static func _stylebox_from_texture(texture: Texture2D, slice_margin: int, tint: Color, content_margins: Vector4) -> StyleBox:
	if texture == null:
		# When the atlas sheets are missing from the workspace, keep the UI usable by
		# falling back to a bordered flat stylebox instead of a flat solid.
		var fallback := StyleBoxFlat.new()
		fallback.bg_color = tint
		fallback.set_corner_radius_all(10)
		fallback.content_margin_left = int(content_margins.x)
		fallback.content_margin_top = int(content_margins.y)
		fallback.content_margin_right = int(content_margins.z)
		fallback.content_margin_bottom = int(content_margins.w)
		# Slightly darker edge to mimic the atlas slice look.
		var edge := Color(max(0.0, tint.r - 0.12), max(0.0, tint.g - 0.12), max(0.0, tint.b - 0.12), tint.a)
		fallback.border_color = edge
		fallback.border_width_left = 2
		fallback.border_width_top = 2
		fallback.border_width_right = 2
		fallback.border_width_bottom = 2
		return fallback

	var box := StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = slice_margin
	box.texture_margin_top = slice_margin
	box.texture_margin_right = slice_margin
	box.texture_margin_bottom = slice_margin
	box.modulate_color = tint
	box.content_margin_left = content_margins.x
	box.content_margin_top = content_margins.y
	box.content_margin_right = content_margins.z
	box.content_margin_bottom = content_margins.w
	return box


static func _get_ui_texture() -> Texture2D:
	if _ui_texture != null:
		return _ui_texture

	# Preferred hard-coded atlas path.
	if ResourceLoader.exists(UI_ATLAS_PATH):
		_ui_texture = load(UI_ATLAS_PATH) as Texture2D
		return _ui_texture

	# Fallback: if the UI atlas was renamed/replaced, try to find any PNG under `Assets/Art/UI`.
	_ui_texture = _load_first_png_under_dir("res://Assets/Art/UI")
	return _ui_texture


static func _get_ui_region_rect(sprite_name: String) -> Rect2:
	if _ui_regions.is_empty():
		_load_ui_regions()
	if _ui_regions.has(sprite_name):
		return _ui_regions[sprite_name] as Rect2
	return Rect2()


static func _get_icon_texture() -> Texture2D:
	if _icon_texture != null:
		return _icon_texture

	# Preferred hard-coded icon atlas path.
	if ResourceLoader.exists(ICON_ATLAS_PATH):
		_icon_texture = load(ICON_ATLAS_PATH) as Texture2D
		return _icon_texture

	# Fallback: if the icon atlas was renamed/replaced, try to find a PNG under `Assets/Art/Icons`.
	_icon_texture = _load_first_png_under_dir("res://Assets/Art/Icons")
	return _icon_texture


static func _load_first_png_under_dir(root_dir: String) -> Texture2D:
	var dir := DirAccess.open(root_dir)
	if dir == null:
		return null

	# Two-level scan: `root_dir/*` and `root_dir/*/*` (matches common atlas pack layouts).
	dir.list_dir_begin()
	var entry_name := dir.get_next()
	while entry_name != "":
		if entry_name.begins_with("."):
			entry_name = dir.get_next()
			continue
		var level1_path := root_dir + "/" + entry_name
		if dir.current_is_dir():
			var dir2 := DirAccess.open(level1_path)
			if dir2 != null:
				dir2.list_dir_begin()
				var name2 := dir2.get_next()
				while name2 != "":
					if name2.begins_with("."):
						name2 = dir2.get_next()
						continue
					if not dir2.current_is_dir() and name2.to_lower().ends_with(".png"):
						var candidate := level1_path + "/" + name2
						if ResourceLoader.exists(candidate):
							return load(candidate) as Texture2D
					name2 = dir2.get_next()
				dir2.list_dir_end()
		else:
			if entry_name.to_lower().ends_with(".png") and ResourceLoader.exists(level1_path):
				return load(level1_path) as Texture2D
		entry_name = dir.get_next()
	dir.list_dir_end()

	return null


static func _load_ui_regions() -> void:
	_ui_regions.clear()
	if not FileAccess.file_exists(UI_ATLAS_REGIONS_PATH):
		return

	var file := FileAccess.open(UI_ATLAS_REGIONS_PATH, FileAccess.READ)
	if file == null:
		return

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts: PackedStringArray = line.split(",")
		if parts.size() != 5:
			continue

		var sprite_name: String = parts[0]
		var x: int = int(parts[1])
		var y: int = int(parts[2])
		var width: int = int(parts[3])
		var height: int = int(parts[4])
		_ui_regions[sprite_name] = Rect2(x, y, width, height)
