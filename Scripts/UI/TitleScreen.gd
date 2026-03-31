# Handles the opening flow before the player reaches gameplay.
extends Control

const GameThemeScript := preload("res://Scripts/UI/GameTheme.gd")
const UiAtlasScript := preload("res://Scripts/UI/UiAtlas.gd")
const NAME_INPUT_SCENE := "res://Scenes/Bootstrap/NameInputScreen.tscn"
const MAIN_GAME_SCENE := "res://Scenes/Main/MainGameScreen.tscn"
const PRIMARY_TITLE_TEXTURE := "res://Assets/TitleScreen/titleScreen-idleking.png"
const BRAND_COVER_TEXTURE := "res://Assets/studioBranding/logo-white-square.png"

@onready var background_image: TextureRect = $BackgroundImage
@onready var brand_watermark_cover: TextureRect = $BrandWatermarkCover
@onready var title_label: Label = $MarginContainer/Content/TitleLabel
@onready var start_button: Button = $MarginContainer/Content/StartButton
@onready var save_hint_label: Label = $MarginContainer/Content/SaveHintLabel


func _ready() -> void:
	# Reflects save state so returning players understand the next step.
	GameThemeScript.apply_to(self)
	AudioManager.play_main_music()
	_apply_title_texture()
	_apply_brand_cover()
	GameThemeScript.apply_display_font(title_label, 32)
	start_button.pressed.connect(_on_start_button_pressed)
	_style_button()
	_refresh_copy()


func _refresh_copy() -> void:
	if GameState.has_king_name():
		start_button.text = "Continue"
		save_hint_label.text = "King %s is ready to defend the castle." % GameState.king_name
	else:
		start_button.text = "Start"
		save_hint_label.text = "New kingdom"


func _on_start_button_pressed() -> void:
	# New players are routed through naming, saved players go straight in.
	if GameState.has_king_name():
		SceneRouter.go_to(MAIN_GAME_SCENE)
	else:
		SceneRouter.go_to(NAME_INPUT_SCENE)


func _apply_title_texture() -> void:
	# Loads title art directly from the file so the screen does not depend on imported texture metadata.
	background_image.texture = _load_texture_from_image_file(PRIMARY_TITLE_TEXTURE)


func _apply_brand_cover() -> void:
	# Covers the bottom-right watermark area on the title art.
	brand_watermark_cover.texture = _load_texture_from_image_file(BRAND_COVER_TEXTURE)


func _style_button() -> void:
	# Applies the medieval button treatment to the title CTA.
	var normal_style := UiAtlasScript.stylebox_from_ui(1, 0, 2, 2, 8, Color("6c3d13"), Vector4(18, 12, 18, 12))
	var pressed_style := UiAtlasScript.stylebox_from_ui(1, 0, 2, 2, 8, Color("91531b"), Vector4(18, 12, 18, 12))

	start_button.icon = null
	start_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_button.add_theme_stylebox_override("normal", normal_style)
	start_button.add_theme_stylebox_override("hover", normal_style)
	start_button.add_theme_stylebox_override("pressed", pressed_style)


func _load_texture_from_image_file(path: String) -> Texture2D:
	# Prefers imported textures for export safety and only falls back to raw image loading if needed.
	if ResourceLoader.exists(path):
		var imported := load(path) as Texture2D
		if imported != null:
			return imported

	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_warning("Unable to load image at %s." % path)
		return null

	return ImageTexture.create_from_image(image)
