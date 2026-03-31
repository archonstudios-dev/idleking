extends Control

const UiAtlasScript := preload("res://Scripts/UI/UiAtlas.gd")

@export var cell_size: int = 32

@onready var ui_texture_rect: TextureRect = $Margin/Content/UITexture
@onready var icon_texture_rect: TextureRect = $Margin/Content/IconTexture
@onready var info_label: Label = $Margin/Content/InfoLabel

var _showing_ui: bool = true


func _ready() -> void:
	ui_texture_rect.texture = _get_texture(true)
	icon_texture_rect.texture = _get_texture(false)
	_update_visibility()
	_update_info()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		# Tab switches which atlas is active for hover readout.
		if (event as InputEventKey).keycode == KEY_TAB:
			_showing_ui = not _showing_ui
			_update_visibility()
			_update_info()

	if event is InputEventMouseMotion:
		_update_info((event as InputEventMouseMotion).position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_copy_current_cell_to_clipboard(mb.position)


func _get_texture(is_ui: bool) -> Texture2D:
	return UiAtlasScript._get_ui_texture() if is_ui else UiAtlasScript._get_icon_texture()


func _update_visibility() -> void:
	ui_texture_rect.visible = _showing_ui
	icon_texture_rect.visible = not _showing_ui


func _update_info(mouse_pos: Vector2 = Vector2(-1, -1)) -> void:
	var active := ui_texture_rect if _showing_ui else icon_texture_rect
	var texture := active.texture
	if texture == null:
		info_label.text = "No atlas texture loaded. Check `UiAtlas.gd` paths.\n(Tab toggles UI/Icon atlas)"
		return

	var local := active.get_global_transform().affine_inverse() * get_global_transform() * mouse_pos
	if mouse_pos == Vector2(-1, -1):
		local = active.size * 0.5

	var col := int(floor(local.x / float(cell_size)))
	var row := int(floor(local.y / float(cell_size)))

	info_label.text = "%s atlas | cell=%d | hover col=%d row=%d\nClick to copy: UiAtlasScript.%s_region(%d, %d)\n(Tab toggles UI/Icon atlas)" % [
		"UI" if _showing_ui else "ICON",
		cell_size,
		col,
		row,
		"ui" if _showing_ui else "icon",
		col,
		row,
	]


func _copy_current_cell_to_clipboard(mouse_pos: Vector2) -> void:
	var active := ui_texture_rect if _showing_ui else icon_texture_rect
	if active.texture == null:
		return
	var local := active.get_global_transform().affine_inverse() * get_global_transform() * mouse_pos
	var col := int(floor(local.x / float(cell_size)))
	var row := int(floor(local.y / float(cell_size)))
	var text := "UiAtlasScript.%s_region(%d, %d)" % ["ui" if _showing_ui else "icon", col, row]
	DisplayServer.clipboard_set(text)
	_update_info(mouse_pos)

